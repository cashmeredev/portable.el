;;; config.el --- Terminal-first Emacs configuration -*- lexical-binding: t; -*-

(setq inhibit-startup-message t
      initial-scratch-message ""
      use-short-answers t
      create-lockfiles nil
      make-backup-files nil
      auto-save-default nil
      delete-by-moving-to-trash t
      ring-bell-function #'ignore
      visible-bell nil
      column-number-mode t
      scroll-conservatively 101
      mouse-wheel-progressive-speed nil
      switch-to-buffer-obey-display-actions t
      tab-always-indent 'complete
      completion-cycle-threshold 3
      history-length 1000
      custom-file (locate-user-emacs-file "custom-vars.el"))

(load custom-file 'noerror 'nomessage)

(setq-default indent-tabs-mode nil
              tab-width 4
              truncate-lines t)

(prefer-coding-system 'utf-8)
(global-auto-revert-mode 1)
(recentf-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(winner-mode 1)
(repeat-mode 1)
(file-name-shadow-mode 1)
(xterm-mouse-mode 1)

(dolist (hook '(prog-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))
(add-hook 'text-mode-hook #'visual-line-mode)

(unless standard-display-table
  (setq standard-display-table (make-display-table)))
(set-display-table-slot standard-display-table 'vertical-border
                        (make-glyph-code ?│))

;; The same config remains pleasant in a graphical frame, but no workflow
;; depends on these settings.
(when (display-graphic-p)
  (set-face-attribute 'default nil :family "Maple Mono NF" :height 160))

(load-theme 'modus-vivendi-tinted t)

(defun my/reload-config ()
  "Re-tangle and reload this literate configuration."
  (interactive)
  (let ((org-file (locate-user-emacs-file "config.org"))
        (el-file (locate-user-emacs-file "config.el")))
    (org-babel-tangle-file org-file el-file "emacs-lisp")
    (load el-file nil 'nomessage)
    (message "Terminal Emacs configuration reloaded")))

(defun my/executable-p (program)
  "Return non-nil when PROGRAM is available."
  (and (executable-find program) t))

(defun my/gnu-ls-p (program)
  "Return non-nil when PROGRAM behaves like GNU ls."
  (and program
       (eq 0 (call-process program nil nil nil "--version"))))

(use-package async :ensure t)

(use-package general
  :ensure (:wait t)
  :demand t
  :config
  (general-evil-setup))

(eval-and-compile
  (require 'general)
  (general-create-definer my-leader
    :states '(normal visual insert)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")
  (general-create-definer my-local-leader
    :states '(normal visual)
    :keymaps 'override
    :prefix ","))

(setq evil-want-keybinding nil
      evil-want-C-u-scroll t
      evil-want-C-i-jump nil
      evil-undo-system 'undo-redo)

(use-package evil
  :ensure (:wait t)
  :demand t
  :config
  (evil-mode 1))

(use-package evil-collection
  :ensure (:wait t)
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :ensure t
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-matchit
  :ensure t
  :after evil
  :config
  (global-evil-matchit-mode 1))

(use-package evil-mc
  :ensure t
  :after evil
  :config
  (global-evil-mc-mode 1))

(use-package smartparens
  :ensure t
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config))

(use-package evil-smartparens
  :ensure t
  :after (evil smartparens)
  :hook (smartparens-enabled . evil-smartparens-mode))

(use-package flash
  :ensure (:host github :repo "Prgebish/flash")
  :after evil
  :config
  (require 'flash-evil))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package pulsar
  :ensure t
  :custom
  (pulsar-pulse t)
  (pulsar-delay 0.025)
  (pulsar-iterations 10)
  (pulsar-face 'evil-ex-lazy-highlight)
  (pulsar-tty-color "white")
  :config
  (dolist (command '(evil-yank evil-yank-line evil-delete evil-delete-line
                     diff-hl-next-hunk diff-hl-previous-hunk
                     flymake-goto-next-error flymake-goto-prev-error))
    (add-to-list 'pulsar-pulse-functions command))
  (pulsar-global-mode 1))

(use-package clipetty
  :ensure t
  :after evil
  :config
  (global-clipetty-mode 1)
  (setq interprogram-cut-function nil)

  (defun my/send-to-clipboard (text)
    "Copy TEXT through the GUI clipboard or OSC 52."
    (when (stringp text)
      (if (display-graphic-p)
          (gui-select-text text)
        (clipetty-cut #'ignore text))))

  (defun my/evil-yank-to-clipboard
      (_beg _end &optional _type register _yank-handler)
    (when (and (not register)
               (memq this-command '(evil-yank evil-yank-line)))
      (my/send-to-clipboard (car kill-ring))))

  (advice-add 'evil-yank :after #'my/evil-yank-to-clipboard))

(use-package company
  :ensure t
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay nil)
  (company-require-match nil)
  (company-tooltip-limit 6)
  (company-backends '(company-capf)))

(use-package cape
  :ensure (:wait t)
  :init
  (add-hook 'completion-at-point-functions #'cape-file))

(use-package which-key
  :ensure t
  :hook (after-init . which-key-mode)
  :custom
  (which-key-idle-delay 0.3))

(use-package helm
  :ensure (:wait t)
  :hook (after-init . helm-mode)
  :custom
  (helm-M-x-fuzzy-match t)
  (helm-buffers-fuzzy-matching t)
  (helm-recentf-fuzzy-match t)
  (helm-split-window-inside-p t)
  :config
  (helm-autoresize-mode 1))

(use-package helm-xref
  :ensure t
  :after helm)

(use-package dired
  :ensure nil
  :init
  (let ((gnu-ls (or (executable-find "gls")
                    (and (my/gnu-ls-p (executable-find "ls"))
                         (executable-find "ls")))))
    (when gnu-ls
      (setq insert-directory-program gnu-ls))
    (setq dired-listing-switches
          (if gnu-ls
              "-lah --group-directories-first --no-group"
            "-lah")))
  :custom
  (dired-dwim-target t)
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-create-destination-dirs 'always)
  :config
  (with-eval-after-load 'async
    (dired-async-mode 1)))

(use-package dirvish
  :ensure (:host github :repo "latiagertrutis/dirvish" :branch "main")
  :init
  (dirvish-override-dired-mode)
  :custom
  (dirvish-quick-access-entries
   '(("h" "~/" "home")
     ("d" "~/Downloads/" "downloads")
     ("c" "~/.config/" "config")))
  (dirvish-attributes '(file-size))
  (dirvish-hide-details '(dirvish dirvish-side))
  (dirvish-hide-cursor '(dirvish dirvish-side))
  :config
  ;; GUI media dispatchers are irrelevant and sometimes broken in a TTY.
  (define-advice dirvish--preview-dps-validate
      (:around (fn &optional dps) terminal-media-filter)
    (let ((dps (if (display-graphic-p)
                   dps
                 (cl-remove-if
                  (lambda (dispatcher)
                    (memq dispatcher '(image gif video video-mtn)))
                  (or dps dirvish-preview-dispatchers)))))
      (funcall fn dps))))

(use-package diredfl
  :ensure t
  :hook (dired-mode . diredfl-mode))

(use-package zoxide
  :ensure t
  :if (my/executable-p "zoxide"))

(use-package nerd-icons
  :ensure t)

(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(use-package project :ensure nil)

(use-package projectile
  :ensure (:wait t)
  :init
  (projectile-mode 1)
  :custom
  (projectile-completion-system 'helm)
  (projectile-switch-project-action #'projectile-dired))

(use-package helm-projectile
  :ensure t
  :after (helm projectile)
  :config
  (helm-projectile-on))

(use-package wgrep
  :ensure t)

(use-package wgrep-helm
  :ensure t
  :after (wgrep helm)
  :config
  (add-hook 'helm-grep-mode-hook #'wgrep-change-to-wgrep-mode))

(use-package persp-mode
  :ensure t
  :init
  ;; Workspaces are useful everywhere; automatic frame-state persistence is
  ;; intentionally left to the full personal configuration.
  (setq persp-keymap-prefix (kbd "C-c w")
        persp-auto-save-opt 0)
  :config
  (persp-mode 1))

(use-package citre
  :ensure t
  :commands (citre-mode citre-jump citre-peek citre-jump-to-reference)
  :init
  (setq citre-default-create-tags-file-location 'in-dir
        citre-edit-ctags-options-manually nil))

(setq org-directory (expand-file-name "~/org/"))
(make-directory org-directory t)

(use-package org
  :ensure nil
  :mode ("\\.org\\'" . org-mode)
  :hook ((org-mode . visual-line-mode)
         (org-mode . (lambda () (electric-indent-local-mode -1))))
  :custom
  (org-startup-folded 'overview)
  (org-return-follows-link t)
  (org-hide-leading-stars t)
  (org-pretty-entities t)
  (org-startup-truncated t)
  (org-ellipsis "  ")
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  (org-log-done t)
  (org-tags-column -80)
  (org-fold-catch-invisible-edits 'show-and-error)
  (org-special-ctrl-a/e t)
  (org-insert-heading-respect-content t)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "ACTIVE(a)" "WAIT(w@/!)"
               "|" "DONE(d!)" "CANCELLED(c@)")))
  :config
  (require 'org-tempo)
  (setq org-agenda-files (list org-directory)
        org-default-notes-file (expand-file-name "inbox.org" org-directory)
        org-capture-templates
        `(("t" "Task" entry
           (file ,org-default-notes-file)
           "* TODO %?\n  %U\n  %a")
          ("n" "Note" entry
           (file ,org-default-notes-file)
           "* %?\n  %U\n  %a"))))

(use-package org-appear
  :ensure t
  :hook (org-mode . org-appear-mode))

(use-package org-ql
  :ensure t
  :after org)

(use-package org-cliplink
  :ensure t
  :commands org-cliplink)

(use-package denote
  :ensure (:wait t)
  :custom
  (denote-directory org-directory)
  (denote-known-keywords '("agenda" "emacs" "journal" "linux" "project"))
  (denote-infer-keywords t)
  (denote-sort-keywords t)
  :config
  (denote-rename-buffer-mode 1))

(use-package denote-org
  :ensure t
  :after (denote org))

(use-package denote-journal
  :ensure t
  :after denote
  :custom
  (denote-journal-keyword "journal"))

(use-package ox-pandoc
  :ensure (:wait t)
  :if (my/executable-p "pandoc")
  :after org)

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure))

(use-package yasnippet
  :ensure (:wait t)
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure (:wait t)
  :after yasnippet)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode))

(use-package nix-ts-mode
  :ensure t
  :mode "\\.nix\\'")

(use-package typst-ts-mode
  :ensure t
  :mode "\\.typ\\'")

(use-package xonsh-mode
  :ensure (:host github :repo "seanfarley/xonsh-mode")
  :mode ("\\.xsh\\'" "\\.xonshrc\\'"))

(use-package just-mode
  :ensure t
  :mode ("[Jj]ustfile\\'" "\\.just\\'"))

(use-package hl-todo
  :ensure (:host github :repo "tarsius/hl-todo")
  :hook (prog-mode . hl-todo-mode))

(use-package vc
  :ensure nil
  :commands (vc-dir vc-diff vc-root-diff vc-next-action))

(use-package magit
  :ensure (:wait t)
  :commands (magit-status magit-clone magit-log-current))

(use-package diff-hl
  :ensure t
  :hook ((prog-mode . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode))
  :config
  (diff-hl-flydiff-mode 1))

(use-package magit-delta
  :ensure t
  :after magit
  :init
  (when (my/executable-p "delta")
    (add-hook 'magit-mode-hook #'magit-delta-mode)))

(use-package ghostel
  :ensure t
  :commands (ghostel ghostel-project ghostel-list-buffers ghostel-compile)
  :custom
  (ghostel-shell (if (my/executable-p "xonsh") "xonsh" shell-file-name))
  (ghostel-ssh-install-terminfo t)
  :config
  (require 'ghostel-compile)
  (ghostel-compile-global-mode 1))

(use-package evil-ghostel
  :ensure (:host github :repo "dakra/ghostel"
           :files ("extensions/evil-ghostel/*.el"))
  :after (ghostel evil)
  :custom
  (evil-ghostel-escape 'evil)
  :hook (ghostel-mode . evil-ghostel-mode))

(use-package inheritenv
  :ensure t
  :after ghostel
  :config
  (inheritenv-add-advice 'ghostel-compile)
  (inheritenv-add-advice 'ghostel-recompile))

(use-package envrc
  :ensure t
  :if (my/executable-p "direnv")
  :hook ((prog-mode . envrc-mode)
         (conf-mode . envrc-mode)))

(setq browse-url-browser-function #'eww-browse-url
      browse-url-secondary-browser-function #'browse-url-default-browser)

(use-package eww
  :ensure nil
  :commands (eww eww-search-words)
  :custom
  (eww-search-prefix "https://duckduckgo.com/html/?q=")
  (eww-auto-rename-buffer 'title)
  (eww-history-limit 100)
  (shr-use-fonts t)
  (shr-use-colors t)
  (shr-width nil))

(use-package shrface
  :ensure t
  :hook (eww-after-render . shrface-mode)
  :config
  (shrface-basic))

(use-package link-hint
  :ensure t
  :commands (link-hint-open-link link-hint-copy-link))

(use-package elfeed
  :ensure (:host github :repo "emacs-elfeed/elfeed" :branch "main")
  :commands elfeed
  :custom
  (elfeed-db-directory (locate-user-emacs-file "elfeed/"))
  (elfeed-search-filter "@2-weeks-ago +unread"))

(my-leader
  "SPC" '(helm-mini :wk "buffers")
  "."   '(helm-find-files :wk "find file")
  "/"   '(helm-projectile-rg :wk "search project")
  "P"   '(helm-show-kill-ring :wk "paste history")

  "a" '(:ignore t :wk "apps")
  "aa" '(elfeed :wk "feeds")
  "ae" '(eww :wk "web")
  "at" '(ghostel :wk "terminal")
  "aT" '(ghostel-project :wk "project terminal")

  "b" '(:ignore t :wk "buffers")
  "bb" '(helm-mini :wk "switch")
  "bi" '(ibuffer :wk "ibuffer")
  "bk" '(kill-current-buffer :wk "kill")
  "br" '(rename-buffer :wk "rename")

  "c" '(:ignore t :wk "code")
  "cc" '(compile :wk "compile")
  "cC" '(recompile :wk "recompile")
  "ce" '(flymake-show-buffer-diagnostics :wk "errors")
  "cg" '(eglot :wk "start language server")
  "cs" '(yas-insert-snippet :wk "snippet")

  "d" '(:ignore t :wk "denote")
  "dd" '(denote :wk "new note")
  "dj" '(denote-journal-new-entry :wk "journal")
  "dl" '(denote-link-or-create :wk "link note")
  "dr" '(denote-rename-file :wk "rename note")

  "f" '(:ignore t :wk "files")
  "fd" '(dired-jump :wk "dired")
  "ff" '(helm-find-files :wk "find")
  "fr" '(helm-recentf :wk "recent")
  "fs" '(save-buffer :wk "save")

  "g" '(:ignore t :wk "git/code navigation")
  "gg" '(magit-status :wk "status")
  "gc" '(magit-clone :wk "clone")
  "gl" '(magit-log-current :wk "log")
  "gd" '(xref-find-definitions :wk "definition")
  "gr" '(xref-find-references :wk "references")
  "gt" '(citre-peek :wk "peek")
  "gb" '(vc-annotate :wk "blame")

  "h" '(:ignore t :wk "help")
  "hf" '(describe-function :wk "function")
  "hk" '(describe-key :wk "key")
  "hm" '(describe-mode :wk "mode")
  "hv" '(describe-variable :wk "variable")
  "hr" '(my/reload-config :wk "reload config")

  "p" '(:ignore t :wk "projects")
  "pp" '(helm-projectile-switch-project :wk "switch")
  "pf" '(helm-projectile-find-file :wk "find file")
  "ps" '(helm-projectile-rg :wk "search")
  "pb" '(helm-projectile-switch-to-buffer :wk "buffers")
  "pk" '(projectile-kill-buffers :wk "kill buffers")

  "q" '(:ignore t :wk "quit")
  "qq" '(save-buffers-kill-terminal :wk "quit")

  "w" '(:ignore t :wk "windows")
  "wh" '(evil-window-left :wk "left")
  "wj" '(evil-window-down :wk "down")
  "wk" '(evil-window-up :wk "up")
  "wl" '(evil-window-right :wk "right")
  "ws" '(evil-window-split :wk "split")
  "wv" '(evil-window-vsplit :wk "vsplit")
  "wc" '(evil-window-delete :wk "close")
  "wo" '(delete-other-windows :wk "only")

  "x" '(org-capture :wk "capture"))

(my-local-leader
  :keymaps 'org-mode-map
  "t" '(org-todo :wk "todo")
  "d" '(org-deadline :wk "deadline")
  "s" '(org-schedule :wk "schedule")
  "l" '(org-insert-link :wk "link")
  "c" '(org-cliplink :wk "clipboard link")
  "n" '(org-toggle-narrow-to-subtree :wk "narrow"))

(general-def 'normal 'override
  "s" #'flash-evil-jump
  "]b" #'switch-to-next-buffer
  "[b" #'switch-to-prev-buffer
  "]d" #'flymake-goto-next-error
  "[d" #'flymake-goto-prev-error
  "]c" #'diff-hl-next-hunk
  "[c" #'diff-hl-previous-hunk)

(general-def 'normal dired-mode-map
  "h" #'dired-up-directory
  "l" #'dired-find-file)

(with-eval-after-load 'org
  (evil-define-key 'normal org-mode-map (kbd "RET") #'org-open-at-point))

(provide 'terminal-emacs-config)
;;; config.el ends here
