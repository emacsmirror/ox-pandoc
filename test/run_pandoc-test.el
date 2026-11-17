;;; run_pandoc-test.el --- Test running pandoc -*- lexical-binding: t; -*-

;; Authors: Alex Fenton <a-fent@github>
;; URL: https://github.com/emacsorphanage/ox-pandoc

;; Description: Test running pandoc on the intermediate output to
;; produce text or PDF. A pandoc binary is required. For PDF output,
;; Typst is required.

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(load-file "test_lib.el")
(require 'ox-pandoc)

;;; Actually run pandoc to convert to HTML and see if it looks roughly
;;; correct.
(ert-deftest test-html-output-buffer ()
  :tags '(:requires-pandoc)
  (let* ((org-source-file (ert-resource-file "from.org")))
    (ert-with-test-buffer (:name "from.org" :selected true)
      (insert-file-contents org-source-file)
      (org-mode)
			;; Needed to prevent the exporter prompting for an output file
      (goto-char (point-min))
      (insert "#+EXPORT_FILE_NAME: from.html\n")
			;; Export to buffer
      (org-pandoc-export-as-html5)
      (let ((result-buffer (ox-pandoc-test--wait-for-pandoc-buffer)))
        (should result-buffer)
        (with-current-buffer result-buffer
          (should
           (string-match-p
            "<html" (buffer-string)))
          (should
           (string-match-p
            "<h1 class=\"title\">Ox-Pandoc-Test Title</h1>" (buffer-string)))
          (should
           (string-match-p
            "<h1 id=\"header-1\">Header-1</h1>" (buffer-string))))))))

;;; Using Typst, write a PDF to a temporary file and see if there's
;;; something in it.
(ert-deftest test-typst-pdf-file ()
	:tags '(:requires-pandoc :requires-typst)
  (let ((org-source-file (ert-resource-file "from.org")))
    (ert-with-temp-file pdf-file
      :suffix ".pdf"
      (ert-with-test-buffer (:name "from.org" :selected true)
        (insert-file-contents org-source-file)
        (org-mode)
        (goto-char (point-min))
        (insert (format "#+EXPORT_FILE_NAME: %s\n" pdf-file))
        (org-pandoc-export-to-typst-pdf)
        (should ;; wait for file exists and has size > 0
         (ox-pandoc-test--wait-for-pandoc-file pdf-file))))))
