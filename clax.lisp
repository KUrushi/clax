(defpackage #:clax
  (:use #:cl #:cffi))
(in-package #:clax)

;; CライブラリをLispでロード
(define-foreign-library pjrt_c_api
  (:darwin "pjrt_c_api_cpu_plugin.so")
  (t (:default "pjrt_c_api_cpu_plugin")))


(use-foreign-library pjrt_c_api)
