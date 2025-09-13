
(ql:quickload :cffi)

(defpackage #:clax-sample
  (:use #:cl #:cffi))
(in-package #:clax-sample)

;; --- 1. Library and Basic Type Definitions ---
(define-foreign-library pjrt-c-api
  (:darwin "pjrt_c_api_cpu_plugin.so")
  (t (:default "pjrt_c_api_cpu_plugin.so")))
(use-foreign-library pjrt-c-api)

(defctype pjrt-client :pointer)
(defctype pjrt-error :pointer)

;; --- 2. Structure Definitions ---
(defcstruct pjrt-api-version
  (struct-size :size)
  (extension-start :pointer)
  (major-version :int)
  (minor-version :int))

(defcstruct pjrt-api
  ;; Abridged for brevity in final output, but assuming all fields are here
  (struct-size :size) (extension-start :pointer) (pjrt-api-version (:struct pjrt-api-version))
  (pjrt-error-destroy :pointer) (pjrt-error-message :pointer) (pjrt-error-get-code :pointer)
  (pjrt-plugin-initialize :pointer) (pjrt-plugin-attributes :pointer)
  (pjrt-event-destroy :pointer) (pjrt-event-is-ready :pointer) (pjrt-event-error :pointer)
  (pjrt-event-await :pointer) (pjrt-event-on-ready :pointer) (pjrt-client-create :pointer)
  (pjrt-client-destroy :pointer) (pjrt-client-platform-name :pointer)
  (pjrt-client-process-index :pointer) (pjrt-client-platform-version :pointer)
  (pjrt-client-devices :pointer) (pjrt-client-addressable-devices :pointer)
  (pjrt-client-lookup-device :pointer) (pjrt-client-lookup-addressable-device :pointer)
  (pjrt-client-addressable-memories :pointer) (pjrt-client-compile :pointer)
  (pjrt-client-default-device-assignment :pointer) (pjrt-client-buffer-from-host-buffer :pointer)
  (pjrt-device-description-id :pointer) (pjrt-device-description-process-index :pointer)
  (pjrt-device-description-attributes :pointer) (pjrt-device-description-kind :pointer)
  (pjrt-device-description-debug-string :pointer) (pjrt-device-description-to-string :pointer)
  (pjrt-device-get-description :pointer) (pjrt-device-is-addressable :pointer)
  (pjrt-device-local-hardware-id :pointer) (pjrt-device-addressable-memories :pointer)
  (pjrt-device-default-memory :pointer) (pjrt-device-memory-stats :pointer)
  (pjrt-memory-id :pointer) (pjrt-memory-kind :pointer) (pjrt-memory-debug-string :pointer)
  (pjrt-memory-to-string :pointer) (pjrt-memory-addressable-by-devices :pointer)
  (pjrt-executable-destroy :pointer) (pjrt-executable-name :pointer)
  (pjrt-executable-num-replicas :pointer) (pjrt-executable-num-partitions :pointer)
  (pjrt-executable-num-outputs :pointer) (pjrt-executable-size-of-generated-code-in-bytes :pointer)
  (pjrt-executable-get-cost-analysis :pointer) (pjrt-executable-output-memory-kinds :pointer)
  (pjrt-executable-optimized-program :pointer) (pjrt-executable-serialize :pointer)
  (pjrt-loaded-executable-destroy :pointer) (pjrt-loaded-executable-get-executable :pointer)
  (pjrt-loaded-executable-addressable-devices :pointer) (pjrt-loaded-executable-delete :pointer)
  (pjrt-loaded-executable-is-deleted :pointer) (pjrt-loaded-executable-execute :pointer)
  (pjrt-executable-deserialize-and-load :pointer) (pjrt-loaded-executable-fingerprint :pointer)
  (pjrt-buffer-destroy :pointer) (pjrt-buffer-element-type :pointer) (pjrt-buffer-dimensions :pointer)
  (pjrt-buffer-unpadded-dimensions :pointer) (pjrt-buffer-dynamic-dimension-indices :pointer)
  (pjrt-buffer-get-memory-layout :pointer) (pjrt-buffer-on-device-size-in-bytes :pointer)
  (pjrt-buffer-device :pointer) (pjrt-buffer-memory :pointer) (pjrt-buffer-delete :pointer)
  (pjrt-buffer-is-deleted :pointer) (pjrt-buffer-copy-to-device :pointer)
  (pjrt-buffer-to-host-buffer :pointer) (pjrt-buffer-is-on-cpu :pointer)
  (pjrt-buffer-ready-event :pointer) (pjrt-buffer-unsafe-pointer :pointer)
  (pjrt-buffer-increase-external-reference-count :pointer) (pjrt-buffer-decrease-external-reference-count :pointer)
  (pjrt-buffer-opaque-device-memory-data-pointer :pointer)
  (pjrt-copy-to-device-stream-destroy :pointer) (pjrt-copy-to-device-stream-add-chunk :pointer)
  (pjrt-copy-to-device-stream-total-bytes :pointer) (pjrt-copy-to-device-stream-granule-size :pointer)
  (pjrt-copy-to-device-stream-current-bytes :pointer)
  (pjrt-topology-description-create :pointer) (pjrt-topology-description-destroy :pointer)
  (pjrt-topology-description-platform-name :pointer) (pjrt-topology-description-platform-version :pointer)
  (pjrt-topology-description-get-device-descriptions :pointer) (pjrt-topology-description-serialize :pointer)
  (pjrt-topology-description-attributes :pointer) (pjrt-compile :pointer)
  (pjrt-executable-output-element-types :pointer) (pjrt-executable-output-dimensions :pointer)
  (pjrt-buffer-copy-to-memory :pointer) (pjrt-client-create-view-of-device-buffer :pointer)
  (pjrt-executable-fingerprint :pointer) (pjrt-client-topology-description :pointer)
  (pjrt-executable-get-compiled-memory-stats :pointer) (pjrt-memory-kind-id :pointer)
  (pjrt-execute-context-create :pointer) (pjrt-execute-context-destroy :pointer)
  (pjrt-buffer-copy-raw-to-host :pointer)
  (pjrt-async-host-to-device-transfer-manager-destroy :pointer)
  (pjrt-async-host-to-device-transfer-manager-transfer-data :pointer)
  (pjrt-client-create-buffers-for-async-host-to-device :pointer)
  (pjrt-async-host-to-device-transfer-manager-retrieve-buffer :pointer)
  (pjrt-async-host-to-device-transfer-manager-device :pointer)
  (pjrt-async-host-to-device-transfer-manager-buffer-count :pointer)
  (pjrt-async-host-to-device-transfer-manager-buffer-size :pointer)
  (pjrt-async-host-to-device-transfer-manager-set-buffer-error :pointer)
  (pjrt-async-host-to-device-transfer-manager-add-metadata :pointer)
  (pjrt-client-dma-map :pointer) (pjrt-client-dma-unmap :pointer)
  (pjrt-client-create-uninitialized-buffer :pointer)
  (pjrt-client-update-global-process-info :pointer)
  (pjrt-topology-description-deserialize :pointer))

(defcstruct pjrt-client-create-args
  (struct-size :size) (extension-start :pointer) (create-options :pointer)
  (num-options :size) (kv-get-callback :pointer) (kv-get-user-arg :pointer)
  (kv-put-callback :pointer) (kv-put-user-arg :pointer) (client :pointer)
  (kv-try-get-callback :pointer) (kv-try-get-user-arg :pointer))

;; --- 3. Calling GetPjrtApi ---
(defcfun ("GetPjrtApi" get-pjrt-api) :pointer)
(defvar *pjrt-api* (get-pjrt-api))

;; --- 4. API Call Macro and Wrapper Definitions ---
(defun pjrt-client-create (args-ptr)
  "Calls the PJRT_Client_Create function pointer by looking it up inline."
  (foreign-funcall-pointer
    ;; Instead of using a LET variable, we get the pointer right here.
    (foreign-slot-value *pjrt-api* '(:struct pjrt-api) 'pjrt-client-create)
    ;; The rest of the arguments are the same.
    :pointer args-ptr
    :pointer))

;; --- 5. Client Creation Implementation ---
(defun initialize-pjrt-client ()
  ;; The variable name here is also changed for clarity and consistency.
  (with-foreign-objects ((args-ptr 'pjrt-client-create-args)
                         (client-out :pointer))
    (foreign-funcall "memset" :pointer args-ptr :int 0
                     :size (foreign-type-size 'pjrt-client-create-args) :void)

    (with-foreign-slots ((struct-size client) args-ptr pjrt-client-create-args)
      (setf struct-size (foreign-type-size 'pjrt-client-create-args))
      (setf client client-out))

    ;; Call the function with the non-conflicting variable.
    (let ((err (pjrt-client-create args-ptr)))
      (if (null-pointer-p err)
          (let ((client-ptr (mem-ref client-out :pointer)))
            (format t "✅ PJRT Client created successfully: ~a~%" client-ptr)
            client-ptr)
          (error "Failed to create PJRT Client: ~a" err)))))

;; --- 6. Main Processing ---
(defvar *pjrt-client* (initialize-pjrt-client))
