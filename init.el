;;; init.el --- Bootstrap the terminal Emacs config -*- lexical-binding: t; -*-

(when (< emacs-major-version 30)
  (error "This configuration requires Emacs 30 or newer"))

;; Elpaca bootstrap.  Git is the only system dependency needed to install the
;; Emacs packages used by this configuration.
(defvar elpaca-core-date
  (list (string-to-number
         (format-time-string "%Y%m%d"
                             (or emacs-build-time (current-time))))))
(defvar elpaca-queue-limit 4)
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order
  '(elpaca :repo "https://github.com/progfolio/elpaca.git"
           :ref nil :depth 1 :inherit ignore
           :files (:defaults "elpaca-test.el" (:exclude "extensions"))
           :build (:not elpaca-activate)))

(let* ((repo (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when-let* ((buffer (get-buffer-create "*elpaca-bootstrap*"))
                ((zerop (apply #'call-process
                               `("git" nil ,buffer t "clone"
                                 ,@(when-let* ((depth (plist-get order :depth)))
                                     (list (format "--depth=%d" depth)
                                           "--no-single-branch"))
                                 ,(plist-get order :repo) ,repo))))
                ((zerop (call-process "git" nil buffer t "checkout"
                                      (or (plist-get order :ref) "--"))))
                (emacs (concat invocation-directory invocation-name))
                ((zerop (call-process emacs nil buffer nil "-Q" "-L" "."
                                      "--batch" "--eval"
                                      "(byte-recompile-directory \".\" 0 'force)")))
                ((require 'elpaca))
                ((elpaca-generate-autoloads "elpaca" repo)))
      (kill-buffer buffer)))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil))
      (load "./elpaca-autoloads"))))

(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca (elpaca-use-package :wait t)
  (elpaca-use-package-mode)
  (setq elpaca-use-package-by-default t))

;; Install Org before reading the literate configuration.  This avoids using a
;; potentially older Org bundled with the host operating system.
(elpaca (org :ref "release_9.8.5" :depth nil :wait t))
(elpaca (transient :wait t))

(let* ((org-file (expand-file-name "config.org" user-emacs-directory))
       (el-file (expand-file-name "config.el" user-emacs-directory)))
  (when (or (not (file-exists-p el-file))
            (file-newer-than-file-p org-file el-file))
    (require 'org)
    (require 'ob-tangle)
    (org-babel-tangle-file org-file el-file "emacs-lisp"))
  (load el-file nil 'nomessage))

;;; init.el ends here
