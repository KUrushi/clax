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

(hello-xla-pjrt)
