


(require 'ert)
(require 'ert-x)

;;; Export the pandoc backend to a string (no pandoc process)
(defun ox-pandoc-test--export-to-org-string (org-content)
  "Export ORG-CONTENT (a string) through the pandoc backend to an Org string.
This exercises all the ox-pandoc transcoders without running pandoc."
  (with-temp-buffer
    (insert org-content)
    (org-mode)
    (let ((org-pandoc-format 'org)            ; affects entity/latex-environ transcoders
          (org-pandoc-option-table (make-hash-table))
          (org-pandoc-format-extensions-str nil)
          (org-element-keyword-translation-alist
           org-pandoc-element-keyword-translation-alist))
      (org-export-as 'pandoc nil nil 'body-only nil))))

(defun ox-pandoc-test--find-pandoc-process ()
  "Return the pandoc process from any *Pandoc* buffer, or nil."
  (cl-loop for buf in (buffer-list)
           when (string-match-p "\\`\\*Pandoc\\*" (buffer-name buf))
           when (get-buffer-process buf)
           return (get-buffer-process buf)))

(defun ox-pandoc-test--wait-for-pandoc-buffer (&optional timeout)
  "Wait for the asynchronous pandoc process to finish.

Return the *Pandoc* buffer once the sentinel has completed and
populated it, or nil if TIMEOUT (in seconds) elapses first."
  (let* ((deadline (+ (float-time) (or timeout 10)))
         (proc (ox-pandoc-test--find-pandoc-process)))
    (cond
     ;; Process still running: wait for it.
     (proc
      (while (and (< (float-time) deadline)
                  (eq 'run (process-status proc)))
        (accept-process-output proc 0.1))
      (accept-process-output nil 0.1)
      (cl-loop for buf in (buffer-list)
               when (string-match-p "\\`\\*Pandoc\\*" (buffer-name buf))
               return buf))
     ;; Process already finished: look for the buffer directly.
     (t
      (accept-process-output nil 0.1)
      (cl-loop for buf in (buffer-list)
               when (string-match-p "\\`\\*Pandoc\\*" (buffer-name buf))
               return buf)))))

(defun ox-pandoc-test--wait-for-pandoc-file (output-file &optional timeout)
  "Wait for the asynchronous pandoc process to write OUTPUT-FILE.

Return non-nil if OUTPUT-FILE exists with non-zero size before
TIMEOUT (in seconds) elapses."
  (let* ((deadline (+ (float-time) (or timeout 10)))
         (proc (ox-pandoc-test--find-pandoc-process)))
    (cond
     ;; Process still running: wait for it to complete.
     (proc
      (while (and (< (float-time) deadline)
                  (eq 'run (process-status proc)))
        (accept-process-output proc 0.1)))
     ;; Process already finished (buffer killed by sentinel): just
     ;; give remaining output a moment to settle.
     (t
      (accept-process-output nil 0.1)))
    (and (file-exists-p output-file)
         (> (file-attribute-size (file-attributes output-file)) 0))))

