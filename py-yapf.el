;;; py-yapf.el --- Use yapf to beautify a Python buffer

;; Copyright (C) 2015, Friedrich Paetzke <paetzke@fastmail.fm>

;; Author: Friedrich Paetzke <paetzke@fastmail.fm>
;; URL: https://github.com/paetzke/py-yapf.el
;; Version: 0.1

;;; Commentary:

;; Provides commands, which use the external "yapf"
;; tool to tidy up the current buffer according to Python's PEP8.

;; To automatically apply when saving a python file, use the
;; following code:

;;   (add-hook 'python-mode-hook 'py-yapf-enable-on-save)

;;; Code:


(defgroup py-yapf nil
  "Use yapf to beautify a Python buffer."
  :group 'convenience
  :prefix "py-yapf-")


(defcustom py-yapf-options nil
  "Options used for yapf.

Note that `--in-place' is used by default."
  :group 'py-yapf
  :type '(repeat (string :tag "option")))


(defun py-yapf ()
  "Formats the current buffer according to the yapf tool."
  (when (not (executable-find "yapf"))
    (error "\"yapf\" command not found.  Install yapf with \"pip install yapf\""))
  (let ((tmpfile (make-temp-file "yapf" nil ".py"))
        (patchbuf (get-buffer-create "*yapf patch*"))
        (errbuf (get-buffer-create "*yapf Errors*"))
        (coding-system-for-read 'utf-8)
        (coding-system-for-write 'utf-8))
    (with-current-buffer errbuf
      (setq buffer-read-only nil)
      (erase-buffer))
    (with-current-buffer patchbuf
      (erase-buffer))
    (write-region nil nil tmpfile)
    (if (zerop (apply 'call-process "yapf" nil errbuf nil
                      (append py-yapf-options `("--in-place" ,tmpfile))))
        (if (zerop (call-process-region (point-min) (point-max) "diff" nil patchbuf nil "-n" "-" tmpfile))
            (progn
              (kill-buffer errbuf)
              (message "Buffer is already yapfed"))
          (py-yapf-bf--apply-rcs-patch patchbuf)
          (kill-buffer errbuf)
          (message "Applied yapf"))
      (error "Could not apply yapf. Check *yapf Errors* for details"))
    (kill-buffer patchbuf)
    (delete-file tmpfile)))


;;;###autoload
(defun py-yapf-buffer ()
  "Uses the \"yapf\" tool to reformat the current buffer."
  (interactive)
  (py-yapf))


;;;###autoload
(defun py-yapf-enable-on-save ()
  "Pre-save hooked to be used before running py-yapf."
  (interactive)
  (add-hook 'before-save-hook 'py-yapf-buffer nil t))


;; BEGIN GENERATED -----------------
;; !!! This file is generated !!!
;; buftra.el
;; Copyright (C) 2015, Friedrich Paetzke <paetzke@fastmail.fm>
;; Author: Friedrich Paetzke <paetzke@fastmail.fm>
;; URL: https://github.com/paetzke/buftra.el
;; Version: 0.3


(defun py-yapf-bf--apply-rcs-patch (patch-buffer)
  "Apply an RCS-formatted diff from PATCH-BUFFER to the current buffer."
  (let ((target-buffer (current-buffer))
        (line-offset 0))
    (save-excursion
      (with-current-buffer patch-buffer
        (goto-char (point-min))
        (while (not (eobp))
          (unless (looking-at "^\\([ad]\\)\\([0-9]+\\) \\([0-9]+\\)")
            (error "invalid rcs patch or internal error in py-yapf-bf--apply-rcs-patch"))
          (forward-line)
          (let ((action (match-string 1))
                (from (string-to-number (match-string 2)))
                (len  (string-to-number (match-string 3))))
            (cond
             ((equal action "a")
              (let ((start (point)))
                (forward-line len)
                (let ((text (buffer-substring start (point))))
                  (with-current-buffer target-buffer
                    (setq line-offset (- line-offset len))
                    (goto-char (point-min))
                    (forward-line (- from len line-offset))
                    (insert text)))))
             ((equal action "d")
              (with-current-buffer target-buffer
                (goto-char (point-min))
                (forward-line (- from line-offset 1))
                (setq line-offset (+ line-offset len))
                (kill-whole-line len)))
             (t
              (error "invalid rcs patch or internal error in py-yapf-bf-apply--rcs-patch")))))))))


(defun py-yapf-bf--replace-region (filename)
  (delete-region (region-beginning) (region-end))
  (insert-file-contents filename))


(defun py-yapf-bf--apply-executable-to-buffer (executable-name executable-call only-on-region)
  "Formats the current buffer according to the executable"
  (when (not (executable-find executable-name))
    (error (format "%s command not found." executable-name)))
  (let ((tmpfile (make-temp-file executable-name nil ".py"))
        (patchbuf (get-buffer-create (format "*%s patch*" executable-name)))
        (errbuf (get-buffer-create (format "*%s Errors*" executable-name)))
        (coding-system-for-read buffer-file-coding-system)
        (coding-system-for-write buffer-file-coding-system))
    (with-current-buffer errbuf
      (setq buffer-read-only nil)
      (erase-buffer))
    (with-current-buffer patchbuf
      (erase-buffer))

    (if (and only-on-region (use-region-p))
        (write-region (region-beginning) (region-end) tmpfile)
      (write-region nil nil tmpfile))

    (if (funcall executable-call errbuf tmpfile)
        (if (zerop (call-process-region (point-min) (point-max) "diff" nil
                                        patchbuf nil "-n" "-" tmpfile))
            (progn
              (kill-buffer errbuf)
              (message (format "Buffer is already %sed" executable-name)))

          (if only-on-region
              (py-yapf-bf--replace-region tmpfile)
            (py-yapf-bf--apply-rcs-patch patchbuf))

          (kill-buffer errbuf)
          (message (format "Applied %s" executable-name)))
      (error (format "Could not apply %s. Check *%s Errors* for details"
                     executable-name executable-name)))
    (kill-buffer patchbuf)
    (delete-file tmpfile)))


;; py-yapf-bf.el ends here
;; END GENERATED -------------------


(provide 'py-yapf)


;;; py-yapf.el ends here
