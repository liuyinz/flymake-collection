;;; flymake-rest-shellcheck.el --- Shellcheck diagnostic function -*- lexical-binding: t -*-

;; Copyright (c) 2021 Mohsin Kaleem

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:

(require 'flymake)
(require 'flymake-rest)

(eval-when-compile
  (require 'flymake-rest-define))

(defcustom flymake-rest-shellcheck-follow-sources t
  "Whether to follow sources in `flymake-rest-shellcheck'."
  :type '(choice (const :tag "Follow source files" t)
                 (const :tag "Follow source files and lint them" lint)
                 (const :tag "Do not follow source files" nil))
  :group 'flymake-rest)

;;;###autoload (autoload 'flymake-rest-shellcheck "flymake-rest-shellcheck")
(flymake-rest-define-enumerate flymake-rest-shellcheck
  "A shell script syntax and style checker using Shellcheck.

See URL `https://github.com/koalaman/shellcheck/'."
  :title "shellcheck"
  :pre-let ((sh-exec (executable-find "shellcheck")))
  :pre-check (unless sh-exec
               (error "Cannot find shellcheck executable"))
  :write-type 'pipe
  :command `(,sh-exec
             "--format" "json"
             ,@(when-let ((sh (bound-and-true-p sh-shell)))
                 `("--shell" ,(symbol-name sh)))
             ,@(when flymake-rest-shellcheck-follow-sources
                 `("--external-sources"
                   ,@(when (eq flymake-rest-shellcheck-follow-sources 'lint)
                       '("--check-sourced"))))
             "-")
  :generator
  (car
   (flymake-rest-parse-json
    (buffer-substring-no-properties
     (point-min) (point-max))))
  :enumerate-parser
  (let-alist it
    (let ((loc (cons (car (flymake-diag-region flymake-rest-source .line .column))
                     (cdr (flymake-diag-region flymake-rest-source .endLine .endColumn)))))
      (list flymake-rest-source
            (car loc)
            (cdr loc)
            (pcase .level
              ("error" :error)
              ("warning" :warning)
              ((or "info" "style" _) :note))
            (concat (propertize (format "SC%s" .code) 'face 'flymake-rest-diag-id) " " .message)))))

(provide 'flymake-rest-shellcheck)

;;; flymake-rest-shellcheck.el ends here
