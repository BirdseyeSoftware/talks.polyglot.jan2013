
(defun ringmaster-prepare-slides ()
  (interactive)
  (save-window-excursion
    (find-file "~/src/talks.polyglot.jan2013/slides.org")
    (org-export-as-html 3)))
