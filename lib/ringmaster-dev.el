(require 'dss-browser-integration)

(setq ringmaster-dev-directory  "~/src/talks.polyglot.jan2013/")

(setq ringmaster-dev-coffee-files
      '("lib/model.coffee"
        "test/browser_test.coffee"
        ))

(setq ringmaster-dev-browser-test-command
      (format "cd %s; bin/run-buster-tests.sh browser" ringmaster-dev-directory))

(setq ringmaster-dev-node-test-command
      (format "cd %s; bin/run-buster-tests.sh node" ringmaster-dev-directory))

(setq ringmaster-dev-test-command
      (format "cd %s; bin/run-buster-tests.sh" ringmaster-dev-directory))


(defun ringmaster-dev/buster-after-save-hook ()
  (interactive)
  ;; (dss/autotest-run-tests)
  )

(defun ringmaster-dev/enable-tests (&optional test-command)
  (interactive)
  (proctor/on)
  (proctor/set-command (or test-command ringmaster-dev-test-command)))

(defun ringmaster-dev/enable-buster-node-tests ()
  (interactive)
  (ringmaster-dev/enable-tests ringmaster-dev-node-test-command))

(defun ringmaster-dev/enable-buster-tests ()
  (interactive)
  (ringmaster-dev/enable-tests))

(defun ringmaster-dev/enable-buster-browser-tests ()
  (interactive)
  (ringmaster-dev/enable-tests ringmaster-dev-browser-test-command))

(defun ringmaster-dev/daemon (&optional switch)
  (interactive)
  (dss/persistent-command-buffer
   ringmaster-dev-directory
   (concat
    (format "cd %s; " ringmaster-dev-directory)
    "./bin/daemons.sh start\n")
   "*ringmaster-daemons*"
   (dss/_invert-switch-argument switch)))

(defun ringmaster-dev/buster-static-daemon (&optional switch)
  (interactive)
  (dss/persistent-command-buffer
   ringmaster-dev-directory
   (concat
    (format "cd %s; " ringmaster-dev-directory)
    "bin/buster-static ;exit\n")
   "*buster-static*"
   (dss/_invert-switch-argument switch))
  (sit-for 2)
  (browse-url "http://test.dent.vm1:8282/"))

(defun ringmaster-dev/our-coffee? (buffer)
  (let ((file-name (buffer-file-name buffer)))
    (and file-name
         (string-match "\\.coffee$" file-name)
         (string-match-p (expand-file-name ringmaster-dev-directory)
                         (expand-file-name file-name)))))

(defun ringmaster-dev/configure-buster-tests ()
  (interactive)
  (save-window-excursion
    (ringmaster-dev/daemon)
    (dolist (buf (buffer-list))
      (when (ringmaster-dev/our-coffee? buf)
        (with-current-buffer buf
          (ringmaster-dev/enable-buster-tests))))

    (dolist (f ringmaster-dev-coffee-files)
      (let* ((source-file (format "%s/%s" ringmaster-dev-directory f))
                   (buf (find-file source-file)))
              (with-current-buffer buf
                (ringmaster-dev/enable-buster-tests))))))

(defun ringmaster-dev/buster-set-selector (selector)
  (interactive (list
                (read-string (format "selector (%s): "
                                     (thing-at-point 'word))
                             nil 'buster-selector (thing-at-point 'word))))
  (let ((file  "~/.buster_selector"))
    (with-temp-buffer
      (insert selector)
      (when (file-writable-p file))
      (write-region (point-min)
                    (point-max)
                    file))))

(defun ringmaster-dev/export-slides ()
  (interactive)
  (message (dss/local-shell-command-to-string
            (format "cd %s; bin/export_slides.sh" ringmaster-dev-directory))))
;; (defun ringmaster-dev/buster-refresh-static  ()
;;   (interactive)
;;   (run-with-timer 2 nil
;;                   (lambda ()
;;                     (dss/moz-reload))))


(provide 'ringmaster-dev)
