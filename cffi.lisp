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
(defun tensor-from-host (client device array)
  (let* ((num-dims (array-rank array))
         (dims (array-dimensions array))
         (array-type (array-element-type array))
         (cffi-type (cond
                      ((equal array-type 'single-float) :float)
                      ((equal array-type 'double-float) :double)
                      (t (error "Unsupported array element type: ~A" array-type)))))
    (cffi:with-foreign-objects ((dims-ptr :int64 num-dims)
                                (data-ptr cffi-type (array-total-size array)))
      (loop for i from 0 for dim in dims
            do (setf (cffi:mem-aref dims-ptr :int64 i) dim))
      (loop for i from 0 below (array-total-size array)
            do (setf (cffi:mem-aref data-ptr cffi-type i)
                     (row-major-aref array i)))
      (let ((pjrt-type (ecase cffi-type
                         (:float :f32)
                         (:double :f64))))
        (create-buffer-from-host client device data-ptr dims-ptr num-dims pjrt-type)))))

;; --- Main Test Execution (Corrected) ---
(defun test-run ()
  (with-pjrt-api ()
    (with-pjrt-client (client)
      (let ((add-executable (compile-add-program client)))
        (unwind-protect
             (if (cffi:null-pointer-p add-executable)
                 (format t "~&Error: Failed to compile the program.~%")
                 (progn
                   (format t "Compilation successful. Executable: ~A~%" add-executable)
                   (let ((device (get-device client 0)))
                     (format t "~&--- Preparing Tensors (2x3 Matrices) ---~%")
                     (let* ((mat-a (make-array '(2 3) :element-type 'single-float
                                                     :initial-contents '((1.0 2.0 3.0) (4.0 5.0 6.0))))
                            (mat-b (make-array '(2 3) :element-type 'single-float
                                                     :initial-contents '((10.0 20.0 30.0) (40.0 50.0 60.0))))
                            (buf-a (tensor-from-host client device mat-a))
                            (buf-b (tensor-from-host client device mat-b)))

                       (format t "Input Buffer A: ~A~%" buf-a)
                       (format t "Input Buffer B: ~A~%" buf-b)
                       (format t "~%--- Executing Add Operation ---~%")

                       (let ((result-buf (execute-add add-executable buf-a buf-b)))
                         (format t "Result Buffer: ~A~%" result-buf)

                         (if (cffi:null-pointer-p result-buf)
                             (format t "~&Execution failed.~%")
                             (progn
                               (format t "~%--- Copying Result to Lisp ---~%")
                               ;; 6要素分 (2x3) のメモリを確保
                               (cffi:with-foreign-object (result-ptr :float 6)
                                 ;; 6要素分のデータをコピー
                                 (buffer-to-host result-buf result-ptr (* 6 (cffi:foreign-type-size :float)))

                                 ;; 結果を格納するための2x3の行列を作成
                                 (let ((result-arr (make-array '(2 3) :element-type 'single-float)))
                                   ;; 6回ループして、平坦化したインデックスで値をコピー
                                   (loop for i from 0 below 6
                                         do (setf (row-major-aref result-arr i)
                                                  (cffi:mem-aref result-ptr :float i)))

                                   (format t "Result values:~%~A~%" result-arr))))))))))
          ;; Cleanup
          (when (and add-executable (not (cffi:null-pointer-p add-executable)))
            (format t "~&Cleaning up compiled executable...~%")
            (destroy-executable add-executable)))))))
