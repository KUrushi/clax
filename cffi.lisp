(ql:quickload :cffi)

;; 共有ライブラリの定義
(cffi:define-foreign-library libxla-wrapper
  (:darwin "/Users/urushiyama.k/quicklisp/local-projects/clax/xla/bazel-bin/xla/lisp_bridge/libxla_wrapper.so")
  (:unix "/Users/urushiyama.k/quicklisp/local-projects/clax/xla/bazel-bin/xla/lisp_bridge/libxla_wrapper.so")
  (:t (:default "libxla_wrapper")))

(cffi:use-foreign-library libxla-wrapper)

(cffi:defcfun ("hello_xla_pjrt" hello-xla-pjrt) :void)
(cffi:defcfun ("initialize_client" initialize-client) :pointer)
(cffi:defcfun ("get_device" get-device) :pointer
  (client :pointer)
  (device-index :size))
(cffi:defcfun ("destroy_client" destroy-client) :void
  (client :pointer))



(defmacro with-pjrt-client ((client-var) &body body)
  "PJRTクライアントを初期化し、BODYを実行した後、確実にクライアントを破棄するマクロ。"
  `(let ((,client-var (initialize-client)))
     (unwind-protect
          (progn ,@body)
       (format t "~&Cleaning up PJRT Client...~%")
       (destroy-client ,client-var))))

(cffi:defcenum pjrt-buffer-type
  (:f32 10)
  (:f64 11)
  (:s32 4)
  (:s64 5)
  (:i64 3))


(cffi:defcfun ("create_buffer_from_host" create-buffer-from-host) :pointer
  (client :pointer)
  (device :pointer)
  (data-ptr :pointer)
  (dims-ptr :pointer)
  (num-dims :size)
  (type pjrt-buffer-type))

(defun tensor-from-host (client device vector)
  "Lispの1次元配列 `vector` からPJRT_Bufferを作成する高レベル関数。"
  (let* ((dims (list (length vector)))
         (num-dims (length dims))
         ;; 型判定部分を cond と equal を使った形に変更
         (array-type (array-element-type vector))
         (cffi-type (cond
                      ((equal array-type 'single-float) :float)
                      ((equal array-type 'double-float) :double)
                      ((equal array-type '(signed-byte 32)) :int32)
                      ((equal array-type '(signed-byte 64)) :int64)
                      (t (error "Unsupported array element type: ~A" array-type)))))

    (cffi:with-foreign-object (dims-ptr :int64 num-dims)
    (cffi:with-foreign-object (data-ptr cffi-type (length vector))

      (loop for i from 0 for dim in dims
            do (setf (cffi:mem-aref dims-ptr :int64 i) dim))

      (loop for i from 0 below (length vector)
            do (setf (cffi:mem-aref data-ptr cffi-type i) (aref vector i)))

      (let ((pjrt-type (ecase cffi-type
                         (:float :f32)
                         (:double :f64)
                         (:int32 :s32)
                         (:int64 :s64))))
        (create-buffer-from-host client device data-ptr dims-ptr num-dims pjrt-type))))))

(cffi:defcfun ("execute_add" execute-add) :pointer
  (client :pointer)
  (buffer-a :pointer)
  (buffer-b :pointer))

(cffi:defcfun ("buffer_to_host" buffer-to-host) :void
  (buffer :pointer)
  (data-ptr :pointer)
  (byte-size :size))

;; 高レベルなテスト実行
(defun test-run ()
(with-pjrt-client (client)
  (let ((device (get-device client 0)))
    (format t "--- Preparing Tensors ---~%")
    ;; 1. 入力となる2つのLisp配列を作成
    (let* ((vec-a (make-array 2 :element-type 'single-float :initial-contents '(10.0 20.0)))
           (vec-b (make-array 2 :element-type 'single-float :initial-contents '(1.5 2.5)))

           ;; 2. Lisp配列からデバイス上のバッファを作成
           (buf-a (tensor-from-host client device vec-a))
           (buf-b (tensor-from-host client device vec-b)))

      (format t "Input Buffer A: ~A~%" buf-a)
      (format t "Input Buffer B: ~A~%" buf-b)

      (format t "~%--- Executing Add Operation ---~%")
      ;; 3. 足し算を実行し、結果のバッファを取得
      (let ((result-buf (execute-add client buf-a buf-b)))
        (format t "Result Buffer: ~A~%" result-buf)

        (format t "~%--- Copying Result to Lisp ---~%")
        ;; 4. 結果をLispにコピーしてくる
        ;;    結果を格納するためのCのメモリ領域を確保
        (cffi:with-foreign-object (result-ptr :float 2)
          ;; Cの関数を呼び出してデータをコピー
          (buffer-to-host result-buf result-ptr (* 2 (cffi:foreign-type-size :float)))

          ;; CのメモリからLispのベクターに値を変換
          (let ((result-vec (make-array 2 :element-type 'single-float)))
            (loop for i from 0 below 2
                  do (setf (aref result-vec i) (cffi:mem-aref result-ptr :float i)))

            ;; 5. 最終結果を表示！
            (format t "Result values: ~A~%" result-vec))))))))
