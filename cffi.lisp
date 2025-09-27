(ql:quickload :cffi)

;; --- Foreign Library Definition ---
(cffi:define-foreign-library libxla-wrapper
  (:darwin "/Users/urushiyama.k/quicklisp/local-projects/clax/xla/bazel-bin/xla/lisp_bridge/libxla_wrapper.so")
  (:unix "/Users/urushiyama.k/quicklisp/local-projects/clax/xla/bazel-bin/xla/lisp_bridge/libxla_wrapper.so")
  (:t (:default "libxla_wrapper")))

(cffi:use-foreign-library libxla-wrapper)
;; --- PJRT Data Types & Macros ---
(cffi:defcenum pjrt-buffer-type
  (:invalid 0)
  (:pred 1)
  (:s8 2)
  (:s16 3)
  (:s32 4)
  (:s64 5)
  (:u8 6)
  (:u16 7)
  (:u32 8)
  (:u64 9)
  (:f16 10)
  (:f32 11)
  (:f64 12)
  (:bf16 13)
  (:c64 14)
  (:c128 15)
  (:f8e5m2 16)
  (:f8e4m3fn 17)
  (:f8e4m3b11fnuz 18)
  (:f8e5m2fnuz 19)
  (:f8e4m3fnuz 20)
  (:s4 21)
  (:u4 22)
  (:token 23)
  (:s2 24)
  (:u2 25)
  (:f8e4m3 26)
  (:f8e3m4 27)
  (:f8e8m0fnu 28)
  (:f4e2m1fn 29))

;; --- C Function Definitions (FFI) ---
(cffi:defcfun ("initialize_pjrt_api" initialize-pjrt-api) :void)
(cffi:defcfun ("shutdown_pjrt_api" shutdown-pjrt-api) :void)
(cffi:defcfun ("create_client" create-client) :pointer)
(cffi:defcfun ("destroy_client" destroy-client) :void (client :pointer))
(cffi:defcfun ("get_device" get-device) :pointer (client :pointer) (device-index :size))

;; MODIFIED FUNCTION DEFINITION
(cffi:defcfun ("create_buffer_from_host" create-buffer-from-host) :pointer
  (client :pointer)
  (device :pointer)
  (data-ptr :pointer)
  (dims-ptr :pointer)
  (num-dims :size)
  (type pjrt-buffer-type))

(cffi:defcfun ("buffer_to_host" buffer-to-host) :void
  (buffer :pointer) (data-ptr :pointer) (byte-size :size))
(cffi:defcfun ("compile_add_program" compile-add-program) :pointer
  (client :pointer))
(cffi:defcfun ("destroy_executable" destroy-executable) :void
  (executable :pointer))
(cffi:defcfun ("execute_add" execute-add) :pointer
  (executable :pointer)
  (buffer-a :pointer)
  (buffer-b :pointer))


(defmacro with-pjrt-api (() &body body)
  `(progn
     (initialize-pjrt-api)
     (unwind-protect
          (progn ,@body)
       (shutdown-pjrt-api))))

(defmacro with-pjrt-client ((client-var) &body body)
  `(let ((,client-var (create-client)))
     (unless (cffi:null-pointer-p ,client-var)
       (unwind-protect
            (progn ,@body)
         (destroy-client ,client-var)))))

;; --- Helper Function ---
(defun tensor-from-host (client device vector)
  (let* (
         (num-dims (array-rank array))
         (dims (array-dimensions array))
         (array-type (array-element-type vector))
         (cffi-type (cond
                      ((equal array-type 'single-float) :float)
                      ((equal array-type 'double-float) :double)
                      (t (error "Unsupported array element type: ~A" array-type)))))
    (cffi:with-foreign-objects ((dims-ptr :int64 num-dims)
                                (data-ptr cffi-type (array-total-size vector)))
      (loop for i from 0 for dim in dims
            do (setf (cffi:mem-aref dims-ptr :int64 i) dim))

      (loop for i from 0 below (array-total-size array)
            do (setf (cffi:mem-aref data-ptr cffi-type i)
                     (row-major-aref array i)))

      (let ((pjrt-type (ecase cffi-type
                         (:float :f32)
                         (:double :f64))))
        ;; This call works correctly because CFFI translates the :f32 keyword
        ;; to its integer value (10) before passing it to the C function.
        (create-buffer-from-host client device data-ptr dims-ptr num-dims pjrt-type)))))

;; --- Main Test Execution ---
(defun test-run ()
  (with-pjrt-api ()
    (with-pjrt-client (client)
      (format t "~&--- Compiling the 'add' function once ---~%")
      (let ((add-executable (compile-add-program client)))
        ;; This 'unwind-protect' guarantees the executable is destroyed,
        ;; but only if it was successfully created.
        (unwind-protect
             (progn
               ;; First, check if compilation succeeded before trying to use the executable
               (if (cffi:null-pointer-p add-executable)
                   (format t "~&Error: Failed to compile the program.~%")
                   ;; This is the "ELSE" block: Compilation was successful
                   (progn
                     (format t "Compilation successful. Executable: ~A~%" add-executable)
                     (let ((device (get-device client 0)))
                       (format t "~&--- Preparing Tensors ---~%")
                       (let* ((vec-a (make-array 2 :element-type 'single-float :initial-contents '(10.0 20.0)))
                              (vec-b (make-array 2 :element-type 'single-float :initial-contents '(1.5 2.5)))
                              (buf-a (tensor-from-host client device vec-a))
                              (buf-b (tensor-from-host client device vec-b)))
                         (format t "Input Buffer A: ~A~%" buf-a)
                         (format t "Input Buffer B: ~A~%" buf-b)
                         (format t "~%--- Executing Add Operation ---~%")
                         (let ((result-buf (execute-add add-executable buf-a buf-b)))
                           (format t "Result Buffer: ~A~%" result-buf)
                           (if (cffi:null-pointer-p result-buf)
                               (format t "~&Execution failed.~%")
                               (progn
                                 (format t "~%--- Copying Result to Lisp ---~%")
                                 (cffi:with-foreign-object (result-ptr :float 2)
                                   (buffer-to-host result-buf result-ptr (* 2 (cffi:foreign-type-size :float)))
                                   (let ((result-vec (make-array 2 :element-type 'single-float)))
                                     (loop for i from 0 below 2
                                           do (setf (aref result-vec i) (cffi:mem-aref result-ptr :float i)))
                                     (format t "Result values: ~A~%" result-vec)))))))))))
          ;; Cleanup form for the unwind-protect
          (when add-executable
            (format t "~&Cleaning up compiled executable...~%")
            (destroy-executable add-executable)))))))
