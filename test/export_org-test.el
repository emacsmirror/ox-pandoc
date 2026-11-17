;;; export_org-test.el --- Test org→org transcoding   -*- lexical-binding: t; -*-

;; Authors: Alex Fenton <a-fent@github>
;; URL: https://github.com/emacsorphanage/ox-pandoc

;; Description: Test the custom org exporter. No pandoc required.

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

;;; Code:----------------------------------------------------------------------

(load-file "test_lib.el")
(require 'ox-pandoc)

(ert-deftest test-org-output-headings ()
  "Headings pass through to the intermediate Org file unchanged."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "* Header-1\n** Header-2\n")))
    (should (string-match-p "\\* Header-1" output))
    (should (string-match-p "\\*\\* Header-2" output))))

(ert-deftest test-org-output-paragraph ()
  "Paragraph text passes through unchanged."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "Some paragraph text.\n")))
    (should (string-match-p "Some paragraph text" output))))

(ert-deftest test-org-output-src-block ()
  "Source blocks preserve language and content."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "#+begin_src emacs-lisp\n(+ 1 2)\n#+end_src\n")))
    (should (string-match-p "#\\+begin_src emacs-lisp" output))
    (should (string-match-p "(\\+ 1 2)" output))
    (should (string-match-p "#\\+end_src" output))))

(ert-deftest test-org-output-entity ()
  "Entities are expanded to UTF-8 for non-TeX formats (default: org)."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "\\alpha \\beta\n")))
    ;; org-pandoc-entity outputs :utf-8 for non-TeX formats
    (should (string-match-p "α" output))
    (should (string-match-p "β" output))))

(ert-deftest test-org-output-export-block-pandoc ()
  "BEGIN_EXPORT pandoc blocks pass their content directly to output."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "#+begin_export pandoc\n--pandoc-option\n#+end_export\n")))
    (should (string-match-p "--pandoc-option" output))))

(ert-deftest test-org-output-export-snippet-pandoc ()
  "Pandoc export snippets pass their content directly to output."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "@@pandoc:raw-pandoc-content@@\n")))
    (should (string-match-p "raw-pandoc-content" output))))

(ert-deftest test-org-output-latex-environ ()
  "AMSMath latex environments get $$ delimiters for non-TeX output."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "\\begin{equation}\nE = mc^2\n\\end{equation}\n")))
    (should (string-match-p "\\$\\$\\\\begin{equation}" output))
    (should (string-match-p "\\\\end{equation}\\$\\$" output))))

(ert-deftest test-org-output-link-fuzzy ()
  "Fuzzy links are preserved in the intermediate output."
  (let ((output (ox-pandoc-test--export-to-org-string
                 "[[#some-target][Some Target]]\n")))
    (should (string-match-p "\\[\\[#some-target\\]" output))))

