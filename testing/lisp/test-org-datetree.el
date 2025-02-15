;;; test-org-datetree.el --- Tests for Org Datetree  -*- lexical-binding: t; -*-

;; Copyright (C) 2015, 2019  Nicolas Goaziou

;; Author: Nicolas Goaziou <mail@nicolasgoaziou.fr>

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

(require 'org-datetree)

(ert-deftest test-org-datetree/find-date-create ()
  "Test `org-datetree-find-date-create' specifications."
  ;; When date is missing, create it.
  (let ((org-blank-before-new-entry '((heading . t))))
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* 2012-03-29 .*\\'"
      (org-test-with-temp-text ""
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Do not create new year node when one exists.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* 2012-03-29 .*\\'"
      (org-test-with-temp-text "* 2012\n"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Do not create new month node when one exists.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* 2012-03-29 .*\\'"
      (org-test-with-temp-text "* 2012\n\n** 2012-03 month"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Do not create new day node when one exists.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* 2012-03-29 .*\\'"
      (org-test-with-temp-text "* 2012\n\n** 2012-03 month\n\n*** 2012-03-29 day"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Do not create new day node when one exists.
    (should
     (string-match
      "\\`\\* DONE 2012 :tag1:tag2:\n\n\\*\\* TODO 2012-03 .*\n\n\\*\\*\\* \\[#A\\] 2012-03-29 .*\\'"
      (org-test-with-temp-text "* DONE 2012 :tag1:tag2:\n\n** TODO 2012-03 month\n\n*** [#A] 2012-03-29 day :tag3:"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Sort new entry in right place.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-02 .*\n\n\\*\\*\\* 2012-02-01 .*\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* 2012-03-29 .*\\'"
      (org-test-with-temp-text "* 2012\n\n** 2012-03 month\n\n*** 2012-03-29 day"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012))
	  (org-datetree-find-date-create '(2 1 2012)))
        (org-trim (buffer-string)))))
    ;; When `org-datetree-add-timestamp' is non-nil, insert a timestamp
    ;; in entry.  When set to `inactive', insert an inactive one.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* \\(2012-03-29\\) .*\n[ \t]*<\\1.*?>\\'"
      (org-test-with-temp-text "* 2012\n"
        (let ((org-datetree-add-timestamp t))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* \\(2012-03-29\\) .*\n[ \t]*\\[\\1.*?\\]\\'"
      (org-test-with-temp-text "* 2012\n"
        (let ((org-datetree-add-timestamp 'inactive))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; don't add the timestamp twice
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\n\n\\*\\*\\* \\(2012-03-29\\) .*\n[ \t]*<\\1.*?>\\'"
      (org-test-with-temp-text "* 2012\n"
        (let ((org-datetree-add-timestamp t))
	  (org-datetree-find-date-create '(3 29 2012))
          (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Insert at top level, unless some node has DATE_TREE property.  In
    ;; this case, date tree becomes one of its sub-trees.
    (should
     (string-match
      "\\* 2012"
      (org-test-with-temp-text "* Top"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    (should
     (string-match
      "\\*\\* H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n\\*\\*\\* 2012"
      (org-test-with-temp-text
	  "* H1\n\n** H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n* H2"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Do not create new year/month node in DATE_TREE when it already exists
    (should
     (string-match
      "\\`\\* H1\n\n\\*\\* H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n\\*\\*\\* 2012\n\n\\*\\*\\*\\* 2012-03 month\n\n\\*\\*\\*\\*\\* 2012-03-29 .*\n\n\\* H2\\'"
      (org-test-with-temp-text
	  "* H1\n\n** H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n*** 2012\n\n**** 2012-03 month\n\n* H2"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (org-trim (buffer-string)))))
    ;; Insert at correct location, even if some other heading has a
    ;; subtree that looks like a datetree
    (should
     (string-match
      "\\`\\* Dummy heading

\\*\\* 2012

\\* 2012

\\*\\* 2012-03 March

\\*\\*\\* 2012-03-29 .*\\'"
      (org-test-with-temp-text "\
* Dummy heading

** 2012

* 2012

** 2012-03 March"
                               (let ((org-datetree-add-timestamp nil))
	                         (org-datetree-find-date-create '(3 29 2012)))
                               (org-trim (buffer-string)))))
    ;; Always leave point at beginning of day entry.
    (should
     (string-match
      "\\*\\*\\* 2012-03-29"
      (org-test-with-temp-text "* 2012\n\n** 2012-03 month\n\n*** 2012-03-29 day"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-date-create '(3 29 2012)))
        (buffer-substring (point) (line-end-position)))))
    (should
     (string-match
      "\\*\\*\\* 2012-03-29"
      (org-test-with-temp-text "* 2012\n\n** 2012-03 month\n\n*** 2012-03-29 day"
        (let ((org-datetree-add-timestamp t))
	  (org-datetree-find-date-create '(3 29 2012)))
        (buffer-substring (point) (line-end-position)))))))

(ert-deftest test-org-datetree/find-month-create ()
  "Test `org-datetree-find-month-create' specifications."
  (let ((org-blank-before-new-entry '((heading . t))))
    ;; When date is missing, create it with the entry under month.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-03 .*\\'"
      (org-test-with-temp-text ""
                               (let ((org-datetree-add-timestamp nil))
	                         (org-datetree-find-month-create '(3 29 2012)))
                               (org-trim (buffer-string)))))
    ;; Insert at top level, unless some node has DATE_TREE property.  In
    ;; this case, date tree becomes one of its sub-trees.
    (should
     (string-match
      "\\* 2012"
      (org-test-with-temp-text "* Top"
                               (let ((org-datetree-add-timestamp nil))
	                         (org-datetree-find-month-create '(3 29 2012)))
                               (org-trim (buffer-string)))))
    (should
     (string-match
      "\\*\\* H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n\\*\\*\\* 2012"
      (org-test-with-temp-text
       "* H1\n\n** H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n* H2"
       (let ((org-datetree-add-timestamp nil))
	 (org-datetree-find-month-create '(3 29 2012)))
       (org-trim (buffer-string)))))
    ;; Do not create new year/month node in DATE_TREE when it already exists
    (should
     (string-match
      "\\`\\* H1\n\n\\*\\* H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n\\*\\*\\* 2012\n\n\\*\\*\\*\\* 2012-03 month\n\n\\* H2\\'"
      (org-test-with-temp-text
       "* H1\n\n** H1.1\n:PROPERTIES:\n:DATE_TREE: t\n:END:\n\n*** 2012\n\n**** 2012-03 month\n\n* H2"
       (let ((org-datetree-add-timestamp nil))
	 (org-datetree-find-month-create '(3 29 2012)))
       (org-trim (buffer-string)))))))

(ert-deftest test-org-datetree/find-quarter-month-create ()
  "Test `org-datetree-find-quarter-month-create' specifications."
  (let ((org-blank-before-new-entry '((heading . t))))
    ;; When date is missing, create it with the entry under month.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-Q1\n\n\\*\\*\\* 2012-03 .*\\'"
      (org-test-with-temp-text ""
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-create-entry '(year quarter month) '(3 29 2012)))
        (org-trim (buffer-string)))))))

(ert-deftest test-org-datetree/find-quarter-month-day-create ()
  "Test `org-datetree-find-quarter-month-day-create' specifications."
  (let ((org-blank-before-new-entry '((heading . t))))
    ;; When date is missing, create it with the entry under month.
    (should
     (string-match
      "\\`\\* 2012\n\n\\*\\* 2012-Q1\n\n\\*\\*\\* 2012-03 .*\n\n\\*\\*\\*\\* 2012-03-29 .*\\'"
      (org-test-with-temp-text ""
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-create-entry '(year quarter month day) '(3 29 2012)))
        (org-trim (buffer-string)))))))

(ert-deftest test-org-datetree/find-quarter-week-create ()
  "Test `org-datetree-find-quarter-week-create' specifications."
  (let ((org-blank-before-new-entry '((heading . t))))
    ;; When date is missing, create it with the entry under month.
    (should
     (string-match
      "\\`\\* 2024\n\n\\*\\* 2024-Q4\n\n\\*\\*\\* 2024-W52\\'"
      (org-test-with-temp-text ""
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-create-entry '(year quarter week) '(12 27 2024)))
        (org-trim (buffer-string)))))))

(ert-deftest test-org-datetree/find-month-week-create ()
  "Test `org-datetree-find-month-week-create' specifications."
  (let ((org-blank-before-new-entry '((heading . t))))
    ;; When date is missing, create it with the entry under month.
    (should
     (string-match
      "\\`\\* 2024\n\n\\*\\* 2024-12 .*\n\n\\*\\*\\* 2024-W52\\'"
      (org-test-with-temp-text ""
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-create-entry '(year month week) '(12 27 2024)))
        (org-trim (buffer-string)))))))

(ert-deftest test-org-datetree/find-iso-week-create ()
  "Test `org-datetree-find-iso-date-create' specification."
  (let ((org-blank-before-new-entry '((heading . t))))
    ;; When date is missing, create it.
    (should
     (string-match
      "\\`\\* 2015\n\n\\*\\* 2015-W01\n\n\\*\\*\\* 2014-12-31 .*\\'"
      (org-test-with-temp-text ""
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Do not create new year node when one exists.
    (should
     (string-match
      "\\`\\* 2015\n\n\\*\\* 2015-W01\n\n\\*\\*\\* 2014-12-31 .*\\'"
      (org-test-with-temp-text "* 2015\n"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Do not create new month node when one exists.
    (should
     (string-match
      "\\`\\* 2015\n\n\\*\\* 2015-W01\n\n\\*\\*\\* 2014-12-31 .*\\'"
      (org-test-with-temp-text "* 2015\n\n** 2015-W01"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Do not create new day node when one exists.
    (should
     (string-match
      "\\`\\* 2015\n\n\\*\\* 2015-W01\n\n\\*\\*\\* 2014-12-31 .*\\'"
      (org-test-with-temp-text "* 2015\n\n** 2015-W01\n\n*** 2014-12-31 day"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Do not create new day node when one exists.
    (should
     (string-match
      "\\`\\* TODO \\[#B\\] 2015\n\n\\*\\* 2015-W01 :tag1:\n\n\\*\\*\\* 2014-12-31 .*\\'"
      (org-test-with-temp-text "* TODO [#B] 2015\n\n** 2015-W01 :tag1:\n\n*** 2014-12-31 day"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Sort new entry in right place.
    (should
     (string-match
      "\\`\\* 2015\n\n\\*\\* 2015-W01\n\n\\*\\*\\* 2014-12-31 .*\n\n\\*\\* 2015-W36\n\n\\*\\*\\* 2015-09-01 .*\\'"
      (org-test-with-temp-text "* 2015"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(9 1 2015))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Sort new entry in correct order within its week when
    ;; iso-week-year is not calendar year
    (should
     (string-match
      "\\`\\* 2015

\\*\\* 2015-W01

\\*\\*\\* 2014-12-31 .*
\\*\\*\\* 2015-01-01 .*"
      (org-test-with-temp-text "* 2015"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(1 1 2015))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; When `org-datetree-add-timestamp' is non-nil, insert a timestamp
    ;; in entry.  When set to `inactive', insert an inactive one.
    (should
     (string-match
      "\\`\\* 2015\n\n\\*\\* 2015-W01\n\n\\*\\*\\* \\(2014-12-31\\) .*\n[ \t]*<\\1.*?>\\'"
      (org-test-with-temp-text "* 2015\n"
        (let ((org-datetree-add-timestamp t))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    (should
     (string-match
      "\\`\\* 2015\n\n\\*\\* 2015-W01\n\n\\*\\*\\* \\(2014-12-31\\) .*\n[ \t]*\\[\\1.*?\\]\\'"
      (org-test-with-temp-text "* 2015\n"
        (let ((org-datetree-add-timestamp 'inactive))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Insert at top level, unless some node has WEEK_TREE property.  In
    ;; this case, date tree becomes one of its sub-trees.
    (should
     (string-match
      "\\* 2015"
      (org-test-with-temp-text "* Top"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    (should
     (string-match
      "\\*\\* H1.1\n:PROPERTIES:\n:WEEK_TREE: t\n:END:\n\n\\*\\*\\* 2015"
      (org-test-with-temp-text
	  "* H1\n** H1.1\n:PROPERTIES:\n:WEEK_TREE: t\n:END:\n\n* H2"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Do not create new year/week node when it exists in WEEK_TREE
    (should
     (string-match
      "\\`\\* H1\n\\*\\* H1.1\n:PROPERTIES:\n:WEEK_TREE: t\n:END:\n\n\\*\\*\\* 2015\n\n\\*\\*\\*\\* 2015-W01\n\n\\*\\*\\*\\*\\* 2014-12-31 .*\n\n\\* H2\\'"
      (org-test-with-temp-text
	  "* H1\n** H1.1\n:PROPERTIES:\n:WEEK_TREE: t\n:END:\n\n*** 2015\n\n**** 2015-W01\n\n* H2"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (org-trim (buffer-string)))))
    ;; Always leave point at beginning of day entry.
    (should
     (string-match
      "\\*\\*\\* 2014-12-31"
      (org-test-with-temp-text "* 2015\n\n** 2015-W01\n\n*** 2014-12-31 day"
        (let ((org-datetree-add-timestamp nil))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (buffer-substring (point) (line-end-position)))))
    (should
     (string-match
      "\\*\\*\\* 2014-12-31"
      (org-test-with-temp-text "* 2015\n\n** 2015-W01\n\n*** 2014-12-31 day"
        (let ((org-datetree-add-timestamp t))
	  (org-datetree-find-iso-week-create '(12 31 2014)))
        (buffer-substring (point) (line-end-position)))))))

(provide 'test-org-datetree)
;;; test-org-datetree.el ends here
