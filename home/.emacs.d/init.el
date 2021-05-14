;;; init.el --- Emacs init -*- lexical-binding:t -*-
;;;
;;; Commentary:
;;; init.el written by nftug
;;;
;;; Code:
;;;

(setq gc-cons-threshold (* 256 1024 1024))
(setq debug-on-error t)
(defvar my-saved-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(setq byte-compile-warnings '(not cl-functions obsolete))

(eval-and-compile
  (load (expand-file-name "macro" user-emacs-directory) t t))

;; 以下からよく使うエイリアスを使用
;; ! = eval-when-compile
;; !! = eval-and-compile

(!!
  (if (and (executable-find "watchexec")
	   (executable-find "python3"))
      (setq straight-check-for-modifications '(watch-files find-when-checking))
    (setq straight-check-for-modifications '(check-on-save find-when-checking)))
  (defvar bootstrap-version)
  (let ((bootstrap-file
	 (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
	(bootstrap-version 5))
    (unless (file-exists-p bootstrap-file)
      (with-current-buffer
	  (url-retrieve-synchronously
	   "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
	   'silent 'inhibit-cookies)
	(goto-char (point-max))
	(eval-print-last-sexp)))
    (load bootstrap-file nil 'nomessage))
  (require 'straight-x))

(!!
  (straight-use-package 'leaf)
  (straight-use-package 'leaf-keywords)
  (leaf-keywords-init))

(straight-use-package 'blackout)

(!
  (leaf *macro-libraries
    :config
    (leaf cl-lib
      :require t)
    (leaf s
      :straight t
      :require t)
    (leaf dash
      :straight t
      :require t)))



(leaf *init
  :config
  (leaf *basic-conf
    :leaf-autoload nil
    :bind
    ("C-x C-u" . undo)
    ("<delete>" . delete-forward-char)
    ("<mouse-3>" . menu-bar-open)
    :hook
    (server-after-make-frame-hook . my/inhibit-server-message)
    :custom
    (auto-save-timeout . 30)
    (auto-save-interval . 180)
    (delete-auto-save-files . t)
    (version-control . t)
    (delete-old-versions . t)
    (mouse-wheel-progressive-speed . nil)
    (focus-follows-mouse . t)
    (scroll-conservatively . 101)
    (mouse-wheel-scroll-amount . '(2 ((shift) . 4 ) ((control) . nil)))
    (x-selection-timeout . 500)
    (idle-update-delay . 1.0)
    (vc-follow-symlinks . t)
    (auto-revert-check-vc-info . t)
    (auto-save-file-name-transforms . `((".*" ,(concat user-emacs-directory "backup/") t)))
    (backup-directory-alist . `((".*" . ,(concat user-emacs-directory "backup/"))
				(,tramp-file-name-regexp . nil)))
    (text-scale-mode-step . 1.05)
    (inhibit-compacting-font-caches . t)
    
    :preface
    (defun my/inhibit-server-message ()
      (setq inhibit-message t)
      (run-with-idle-timer 0 nil (lambda () (setq inhibit-message nil))))

    :init
    (fset 'yes-or-no-p 'y-or-n-p)
    (set-language-environment "Japanese")
    (set-file-name-coding-system 'utf-8)
    (prefer-coding-system 'utf-8)
    (blink-cursor-mode t)
    (xterm-mouse-mode)
    (delete-selection-mode)
    (with-current-buffer "*Messages*"
      (emacs-lock-mode 'kill)))

  (leaf server
    :preface
    (defun server-running-p nil)
    :unless (or (daemonp) (>= (length command-line-args) 2))
    :require t
    :config
    (unless (server-running-p)
      (server-start)))

  (leaf doom-themes
    :straight t
    :defer-config
    (doom-themes-visual-bell-config)
    (doom-themes-neotree-config)
    (doom-themes-org-config))
  
  (leaf *theme-conf
    :leaf-autoload nil
    :hook
    ((server-after-make-frame-hook tty-setup-hook) . my/terminal-init)
    :preface
    (defconst my/theme 'doom-material-adapta)
    (defun my/terminal-init (&rest _)
      "Terminal initialization function"
      (when-let ((env-term (getenv "TERM")))
	(when (and (string-match ".*-256color$" env-term)
		   (not (featurep 'xterm)))
	  (load "term/xterm")
	  (xterm-register-default-colors xterm-standard-colors)))
      (let ((frame (selected-frame)))
      	(with-selected-frame frame
      	  (unless (or (window-system) (getenv "DISPLAY"))
      	    (set-terminal-parameter nil 'background-mode 'dark)
      	    (set-face-background 'default "unspecified-bg" frame)))))

    (defun my/unload-current-themes (&rest _)
      (mapc #'disable-theme (remove 'use-package custom-enabled-themes)))

    :init
    (push (expand-file-name "theme/" user-emacs-directory) custom-theme-load-path)
    (load-theme my/theme t)
    ;; (advice-add 'load-theme :after
    ;; 		(lambda ()
    ;; 		  (set-face-background 'fringe (face-background 'default))))
    (advice-add 'load-theme :before 'my/unload-current-themes)
    (advice-add 'load-theme :after 'my/terminal-init)
    
    :defun xterm-register-default-colors
    :defvar xterm-standard-colors)

  (leaf fontset
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :custom
    (use-default-font-for-symbols . nil)
    :hook
    ((after-init-hook server-after-make-frame-hook) . my/fonts-init)
    :preface
    (defface my/serif '((t :family "Source Serif Pro"))
      "My Serif face"
      :group 'my/fontset)
    (defcustom buffer-face-mode-face 'my/serif
      "Used in Serif mode"
      :type '(choice (face)
		     (repeat :tag "List of faces" face)
		     (plist :tag "Face property list"))
      :group :my/fontset)
    :config
    (defun my/fonts-init ()
      (when window-system
	(unless (fontset-name-p "fontset-variable")
	  (let* ((asciifont "Source Han Sans JP-11.5:weight=light:slant=normal")
		 (jpfont "Source Han Sans JP")
		 (fontset)
		 (fontspec)
		 (jp-fontspec))
	    (setq fontset (create-fontset-from-ascii-font asciifont nil "variable"))
	    (setq fontspec (font-spec :family asciifont))
	    (setq jp-fontspec (font-spec :family jpfont))
	    (set-fontset-font fontset 'unicode jp-fontspec nil 'append)
	    (set-fontset-font fontset 'ascii fontspec nil 'append) ;;対処済み
	    ;;(set-face-attribute 'my/serif nil :font fontset) ;;英語のみ
	    (set-face-attribute 'variable-pitch nil :fontset fontset)))
	
	(unless (fontset-name-p "fontset-myserif")
	  (let* ((asciifont "Source Serif Pro-11.5:weight=normal:slant=normal")
		 (jpfont "Source Han Serif JP")
		 (fontset)
		 (fontspec)
		 (jp-fontspec))
	    (setq fontset (create-fontset-from-ascii-font asciifont nil "myserif"))
	    (setq fontspec (font-spec :family asciifont))
	    (setq jp-fontspec (font-spec :family jpfont))
	    (set-fontset-font fontset 'unicode jp-fontspec nil 'append)
	    (set-fontset-font fontset 'ascii fontspec nil 'append) ;;対処済み
	    ;;(set-face-attribute 'my/serif nil :font fontset) ;;英語のみ
	    (set-face-attribute 'my/serif nil :fontset fontset)))
	(setq face-font-rescale-alist '(("Source .* Pro.*" . 1.05)))))

    (defun my/serif-mode (&optional arg)
      (interactive (list (or current-prefix-arg 'toggle)))
      (when window-system
	(buffer-face-mode-invoke 'my/serif (or arg t)
				 (called-interactively-p 'interactive)))))

  (leaf *buffer-and-window
    :leaf-autoload nil
    :bind
    ("C-c <up>" . enlarge-window)
    ("C-c <down>" . shrink-window)
    ("C-c <left>" . enlarge-window-horizontally)
    ("C-c <right>" . shrink-window-horizontally)
    ("C-x x" . kill-this-buffer-and-window)
    ("C-x k" . kill-this-buffer)
    ("C-x C-k" . kill-this-buffer)
    ("<f2>" . my/switch-to-scratch)
    
    :preface
    (defvar my/scratch--prev-buf nil)
    
    (defun kill-this-buffer ()
      (interactive)
      (kill-buffer (current-buffer)))

    (defun kill-this-buffer-and-window ()
      (interactive)
      (let ((window (selected-window))
	    (buffer (current-buffer)))
	(if (window-parent window)
	    (let ((same-buf-p nil))
	      (dolist (w (window-list))
		(with-selected-window w
		  (if (and (not (eq w window)) (eq buffer (current-buffer)))
		      (setq same-buf-p t))))
	      (if same-buf-p
		  (delete-window window)
		(kill-buffer-and-window)))
	  (kill-buffer buffer))))

    (defun exit ()
      (interactive)
      (let ((last-nonmenu-event nil))(save-buffers-kill-emacs)))

    (defun my/switch-to-scratch ()
      (interactive)
      (cond
       ((eq (current-buffer) (get-buffer "*scratch*"))
	(if (and my/scratch--prev-buf (get-buffer my/scratch--prev-buf))
	    (switch-to-buffer my/scratch--prev-buf)
	  (error (concat "Not found previous buffer:" my/scratch--prev-buf))))
       (t (setq my/scratch--prev-buf (current-buffer))
	  (switch-to-buffer "*scratch*")))))

  (leaf imenu
    :leaf-autoload nil
    :hook
    (imenu-after-jump-hook . recenter-top-bottom)))



(leaf *must-ext
  :config
  (leaf leaf
    :bind
    (:emacs-lisp-mode-map
     ("<f10>" . leaf-expand))
    :advice
    (:after leaf-expand
	    (lambda ()
	      (with-current-buffer (get-buffer-create leaf-expand-buffer-name)
		(search-forward (concat ";; " (make-string 80 ?-)) nil t)
		(replace-match "\f")
		(recenter-top-bottom 1)))))
  
  (leaf recentf
    :straight t
    :custom
    (recentf-max-saved-items . 1000)
    (recentf-exclude . `(".recentf" ".orhc-bibtex-cache" ".pdf-view-restore" "\\.ics" ,tramp-file-name-regexp))
    (recentf-auto-cleanup . 'never)
    `(recentf-save-file . ,(expand-file-name ".recentf" user-emacs-directory))
    :config
    (run-with-idle-timer 30 t
			 '(lambda ()
			    (with-suppressed-message (recentf-save-list)))))

  (leaf recentf-ext
    :straight t
    :after recentf
    :require t)

  (leaf auto-async-byte-compile
    :straight t
    :hook
    (emacs-lisp-mode-hook . enable-auto-async-byte-compile-mode)
    (auto-async-byte-compile-hook . my/auto-async-byte-compile-hook)
    :custom
    (auto-async-byte-compile-exclude-files-regexp . "\\(/straight/\\|/junk/\\)")
    `(auto-async-byte-compile-init-file . ,(expand-file-name "init.el" user-emacs-directory))
    (auto-async-byte-compile-suppress-warnings . nil)
    :config
    (defconst dotfiles-src-dir "~/.dotfiles/home/.emacs.d/")
    (defun my/auto-async-byte-compile-hook (&rest _)
      ;; dotfiles-src-dirにコンパイル済みファイルがあれば移動させる
      (start-process-shell-command
       "mv" nil
       (format "cd %s; [ -f *.elc ] && mv *.elc %s" dotfiles-src-dir user-emacs-directory))
      (when-let ((buf (get-buffer aabc/result-buffer))
		 (win (get-buffer-window buf)))
	(with-current-buffer buf
	  (select-window win t)
	  (compilation-minor-mode))))
    
    ;; exitstatusの値の処理を修正
    (advice-add 'aabc/status :around
		(lambda (func exitstatus buffer)
		  (if (or (not (eq exitstatus 0))
			  (with-current-buffer buffer
			    (goto-char 1)
			    (search-forward "Error" nil t)))
		      'error)
		  (apply func exitstatus `(,buffer))))
    :defvar aabc/result-buffer)

  (leaf mozc
    :straight (mozc :type built-in)
    :bind
    ("M-`"  . toggle-input-method)
    ("<zenkaku-hankaku>" . toggle-input-method)
    :require t
    :custom
    (mozc-leim-title . "[あ]")
    (mozc-candidate-style . 'echo-area)
    (default-input-method . 'japanese-mozc)
    :custom-face
    (mozc-preedit-selected-face . '((nil (:inherit highlight))))
    (mozc-cand-echo-area-candidate-face . '((nil (:inherit default))))
    (mozc-cand-echo-area-focused-face . '((nil (:inherit highlight))))
    (mozc-cand-echo-area-stats-face . '((nil (:inherit minibuffer-prompt)))))
  
  (leaf mozc-posframe
    :if (and (or (window-system) (and (getenv "DISPLAY") (daemonp)))
     	     (not (string-match "^gpd.*" (system-name))))
    :straight (mozc-posframe :host github :repo "derui/mozc-posframe")
    :after mozc
    :custom
    (mozc-candidate-style . 'posframe)
    :custom-face
    (mozc-cand-overlay-even-face . '((nil (:inherit tooltip))))
    (mozc-cand-overlay-odd-face . '((nil (:inherit tooltip))))
    (mozc-cand-overlay-footer-face . '((nil (:inherit tooltip))))
    (mozc-cand-overlay-focused-face . '((nil (:inherit highlight))))
    :config
    (mozc-posframe-register)
    (add-function :after after-focus-change-function
    		  (lambda ()
    		    (if window-system
    			(setq mozc-candidate-style 'posframe)
    		      (setq mozc-candidate-style 'echo-area))))
    :defun mozc-posframe-register)

  (leaf magit
    :straight t
    :bind
    ("C-x g" . magit-status)
    ("C-x M-g" . magit-dispatch-popup))
  
  (leaf all-the-icons
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :custom
    (all-the-icons-scale-factor . 1.0)
    :preface
    (defun all-the-icons-faicon (&rest _))
    (defun my/all-the-icons-init ()
      (if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
	  (require 'all-the-icons)))
    :defer-config
    (when window-system
      (unless (member "all-the-icons" (font-family-list))
	(all-the-icons-install-fonts t))))

  (leaf posframe
    :straight t
    :after t
    :advice
    (:after load-theme (lambda (&rest _) (posframe-delete-all)))
    :custom
    (posframe-mouse-banish . t)))



(leaf *display
  :config
  (leaf display-line-numbers
    :hook
    ((prog-mode-hook fundamental-mode-hook conf-mode-hook) . display-line-numbers-mode)
    :custom
    (display-line-numbers-width-start . t))

  (leaf hl-line
    :require t
    :defer-config
    (defconst global-hl-line-timer-exclude-modes
      '(sdcv-mode undo-tree-visualizer-mode neotree-mode dashboard-mode pdf-view-mode doc-view-mode vterm-mode))
    (defun global-hl-line-timer-function ()
      (unless (memq major-mode global-hl-line-timer-exclude-modes)
	(global-hl-line-unhighlight-all)
	(let ((global-hl-line-mode t))
	  (global-hl-line-highlight))))
    (setq global-hl-line-timer
	  (run-with-idle-timer 0.03 t 'global-hl-line-timer-function)))

  (leaf elec-pair
    :hook
    ((prog-mode-hook text-mode-hook latex-mode-hook conf-mode-hook) . electric-pair-local-mode))

  (leaf paren
    :hook
    (after-init-hook . show-paren-mode)
    :advice
    (:after load-theme my/paren-setcolor)
    :custom
    (show-paren-style . 'mixed)
    (show-paren-when-point-inside-paren . t)
    (show-paren-when-point-in-periphery . t)
    :config
    (defvar my/paren--server-init-done nil)
    (defun my/paren-setcolor (&rest _)
      (let ((fg (or (when (featurep 'doom-themes) (doom-color 'yellow)) "yellow")))
	(set-face-attribute 'show-paren-match nil
			    :background (face-attribute 'region :background)
			    :foreground fg)))
    (defun my/paren--setcolor-init ()
      (unless my/paren--server-init-done
	(with-selected-frame (selected-frame) (my/paren-setcolor))
	(setq my/paren--server-init-done t)))
    (if (daemonp)
	(add-hook 'server-after-make-frame-hook 'my/paren--setcolor-init)
      (add-hook 'emacs-startup-hook 'my/paren-setcolor))
    :defun my/paren--server-init my/paren-setcolor)

  (leaf rainbow-delimiters
    :straight t
    :hook
    ((prog-mode-hook latex-mode-hook) . rainbow-delimiters-mode))

  (leaf highlight-indent-guides
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :hook
    (prog-mode-hook . highlight-indent-guides-mode)
    :custom
    (highlight-indent-guides-method . 'bitmap)
    (highlight-indent-guides-bitmap-function .'highlight-indent-guides--bitmap-line)
    (highlight-indent-guides-auto-character-face-perc . 10)
    (highlight-indent-guides-responsive . 'top))
  
  (leaf olivetti
    :straight t
    :defvar olivetti-body-width
    :hook
    ((org-mode-hook eww-mode-hook sdcv-mode-hook) . olivetti-mode)
    :bind
    (:olivetti-mode-map ("C-c \\" . nil))
    :setq-default
    (olivetti-body-width . 0.81))

  (leaf simple
    :hook
    (visual-line-mode-hook . (lambda () (setq word-wrap nil))))

  (leaf loaddefs
    :bind
    ("<C-escape>" . view-mode))
  
  (leaf page-break-lines
    :straight t
    :hook
    (after-init-hook . global-page-break-lines-mode)
    (page-break-lines-mode-hook . my/page-break-lines-modify-width)
    :blackout t
    :config
    (defun my/page-break-lines-modify-width ()
      (interactive)
      (let ((table (make-char-table nil)))
	(set-char-table-parent table char-width-table)
	(set-char-table-range table page-break-lines-char 1)
	(setq char-width-table table))
      (set-fontset-font "fontset-default"
			(cons page-break-lines-char page-break-lines-char)
			(face-attribute 'default :family)))
    :defvar page-break-lines-char))



(leaf *utils
  :config
  (leaf undo-tree
    :straight t
    :hook
    (after-init-hook . global-undo-tree-mode)
    :bind
    ("C-/" . undo-tree-undo)
    ("M-/" . undo-tree-redo)
    ("C-x C-u" . undo-tree-undo)
    ("C-x C-r" . undo-tree-redo)
    (:undo-tree-visualizer-mode-map
     ("RET" . undo-tree-visualizer-quit))
    :blackout t)

  (leaf undohist
    :straight t
    :hook
    (after-init-hook . undohist-initialize)
    :custom
    (undohist-ignored-files . '("/tmp" "COMMIT_EDITMSG")))

  (leaf popwin
    :straight t
    :hook
    (after-init-hook . popwin-mode)
    :preface
    (! (defconst my/popwin-vertical-height
	 (!if (string= (system-name) "gpd") 0.42 0.4))
       (defconst my/popwin:special-display-config
	 `((helpful-mode :position bottom :height ,my/popwin-vertical-height :stick t :dedicated t)
	   ("*SDCV*" :position bottom :height ,(- my/popwin-vertical-height 0.1))
	   ("*Python*" :position bottom :height ,my/popwin-vertical-height :stick t)
	   (vterm-mode :position bottom :height ,(- my/popwin-vertical-height 0.1) :stick t)
	   (" *undo-tree*" :width 0.2 :position right)
	   ("*Compile-Log*" :position bottom :height ,(- my/popwin-vertical-height 0.1) :noselect t)
	   (" *auto-async-byte-compile*" :position bottom :height ,(- my/popwin-vertical-height 0.1) :noselect t)
	   ("*Warnings*" :position bottom :height ,(- my/popwin-vertical-height 0.1))
	   ("*Leaf Expand*" :position right :width 0.5)
	   (magit-status-mode :position bottom :height ,my/popwin-vertical-height :stick t)
	   "*Backtrace*")))
    
    :config
    (global-set-key (kbd "C-z") popwin:keymap)
    (setq popwin:special-display-config-backup popwin:special-display-config)

    (!foreach my/popwin:special-display-config
      (push ,it popwin:special-display-config))

    (advice-add 'popwin:create-popup-window-1 :override
		(lambda (window size position)
		  (let ((width (frame-width))
			(height (window-height window)))
		    (cl-ecase position
		      ((left :left)
		       (list (split-window window size t)
			     window))
		      ((top :top)
		       (list (split-window window size nil)
			     window))
		      ((right :right)
		       (list window
			     (split-window window (- width size) t)))
		      ((bottom :bottom)
		       (list window
			     (split-window window (- height size) nil)))))))
    
    :defvar popwin:special-display-config-backup popwin:keymap popwin:special-display-config)

  (leaf edit-server
    :straight t
    :if (or (daemonp) (server-running-p))
    :defun edit-server-start
    :init
    (idle-require 'edit-server 5)
    :defer-config
    (edit-server-start))

  (leaf vterm
    :straight t
    :bind
    ("C-x t" . vterm))

  (leaf vterm-toggle
    :straight t
    :bind
    ("<C-f9>" . vterm-toggle-cd)
    ("<f33>" . vterm-toggle-cd))

  (leaf helpful
    :straight t
    :bind
    ("C-h k" . helpful-key)
    ("C-c C-d" . helpful-at-point)
    :custom
    (counsel-describe-function-function . #'helpful-callable)
    (counsel-describe-variable-function . #'helpful-variable)
    (helpful-max-buffers . 1))

  (leaf which-key
    :straight t
    :init
    (idle-require 'which-key 1.5)
    :blackout t
    :defer-config
    (which-key-mode 1))

  (leaf which-key-posframe
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :after which-key
    :custom
    (which-key-posframe-font . "HackgenNerd Console-10.5")
    :config
    (which-key-posframe-mode)
    :defun which-key-posframe-mode)

  (leaf neotree
    :straight t
    :bind
    ("<f8>" . neotree-toggle)
    :custom
    (neo-theme . 'icons)
    (neo-smart-open . t)
    (neo-show-hidden-files . t)
    :hook
    (neo-after-create-hook . neotree-text-scale)
    :config
    (defun neotree-text-scale (&rest _)
      "Text scale for neotree."
      (interactive)
      (with-suppressed-message
	(variable-pitch-mode)
	(text-scale-adjust 0)
	(text-scale-decrease 3.0))))

  (leaf ace-link
    :straight t
    :commands ace-link-org
    :hook
    (after-init-hook . ace-link-setup-default)
    :bind
    ("M-o" . ace-link))

  (leaf ace-window
    :straight t
    :bind
    ("M-p" . ace-window)
    :custom
    (aw-keys . '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
    :advice
    (:after load-theme my/ace-window-setcolor)
    :config
    (defun my/ace-window-setcolor (&rest _)
      (let ((fg (or (when (featurep 'doom-themes) (doom-color 'yellow)) "yellow")))
	(set-face-attribute 'aw-leading-char-face nil :foreground fg :height 4.0)))
    (my/ace-window-setcolor))

  (leaf sudo-edit
    :straight t)
  
  (leaf gcmh
    :straight t
    :blackout t
    :defvar gcmh-high-cons-threshold
    :init
    (idle-require 'gcmh 3)
    (setq gcmh-high-cons-threshold (* 16 1024 1024))
    :custom
    (gcmh-idle-delay . 5)
    :hook
    (org-mode-hook . (lambda () (setq-local gcmh-high-cons-threshold (* 2 gcmh-high-cons-threshold))))
    :defer-config
    (gcmh-mode 1))

  (leaf imenu-list
    :straight t
    :bind
    ("<f12>" . imenu-list-smart-toggle)
    (:imenu-list-major-mode-map
     ("<escape>" . imenu-list-quit-window))
    :custom
    (imenu-list-focus-after-activation . t)
    (imenu-list-size . 0.2)
    (imenu-list-position . 'right)
    (imenu-list-auto-resize . nil)
    :hook
    (imenu-list-major-mode-hook . (lambda ()
				    (variable-pitch-mode)
				    (text-scale-adjust 0)
				    (text-scale-decrease 3.0))))

  (leaf leaf-tree
    :straight t
    :custom
    (leaf-tree-click-group-to-hide . t)
    :hook
    (emacs-lisp-mode-hook . leaf-tree-auto-on)
    :config
    ;; leaf-tree-modeを自動的にオンにする
    (defun leaf-tree-auto-on ()
      (when (with-current-buffer (current-buffer)
	      (goto-char 1)
	      (search-forward "(leaf " nil t))
	(leaf-tree-mode)
	(goto-char 1)))
    
    ;; leaf-tree-modeをオンにしたときの挙動を変更。
    ;; (imenu-listを表示させずに有効化)
    (advice-add 'leaf-tree--setup :override
		(lambda ()
		  (setq leaf-tree--imenu-list-minor-mode-value (if imenu-list-minor-mode 1 -1))
		  (pcase-dolist (`(,sym . ,fn) leaf-tree-advice-alist)
		    (advice-add sym :around fn))))
    :defvar leaf-tree-advice-alist leaf-tree--imenu-list-minor-mode-value))



(leaf *ivy
  :config
  (leaf ivy
    :straight t
    :blackout t
    :commands ivy-mode
    :defun
    ivy-set-display-transformer ivy--format-function-generic ivy--add-face
    :defvar ivy-format-functions-alist
    :bind
    ("C-c C-r" . ivy-resume)
    ("C-x a" . ivy-switch-buffer)
    ("<menu>" . ivy-switch-buffer)
    ("C-s" . swiper)
    ("M-x" . counsel-M-x)
    ("C-x l" . counsel-locate)
    ("s-r" . counsel-recentf)
    ("M-y" . counsel-yank-pop)
    ("C-x C-f" . counsel-find-file)
    ("C-x C-i" . counsel-imenu)
    ("C-x i" . counsel-imenu)
    ("C-c c" . counsel-org-capture)
    ("C-h f" . counsel-describe-function)
    ("C-h v" . counsel-describe-variable)
    ("C-x C-x" . my-minibuffer-focus)
    (:ivy-minibuffer-map
     ("<escape>" . minibuffer-keyboard-quit)
     ("<C-return>" . ivy-immediate-done))

    :custom
    (ivy-truncate-lines . t)
    (ivy-count-format . "(%d/%d) ")
    (ivy-use-virtual-buffers . t)
    (ivy-virtual-abbreviate . 'full)
    (ivy-dynamic-exhibit-delay-ms . 250)
    (ivy-re-builders-alist . '((t . ivy--regex-plus)))

    :config
    (defun my-minibuffer-focus ()
      (interactive)
      (when-let ((minibuf (active-minibuffer-window)))
	(select-window minibuf)))

    (setq ivy-format-functions-alist
    	  '((t . ivy-format-function-arrow)))

    (ivy-mode))

  (leaf counsel
    :straight t
    :blackout t
    :hook
    (ivy-mode-hook . counsel-mode)
    :config
    ;; (setcdr (assoc 'counsel-M-x ivy-initial-inputs-alist) "")
    (advice-add 'counsel-load-theme-action :override
		(lambda (x)
		  (condition-case nil
		      (load-theme (intern x) t)
		    (error "Problem loading theme %s" x))))
    (defalias 'change-theme 'counsel-load-theme))
  
  (leaf ivy-rich
    :straight t
    :defun ivy-rich--ivy-switch-buffer-transformer my/ivy-rich-cache-reset
    :after ivy counsel
    :require t
    :config
    ;; 重くなるのでキャッシュリセットの処理を追加
    ;; https://github.com/Yevgnen/ivy-rich/issues/87
    (defvar my/ivy-rich-cache
      (make-hash-table :test 'equal))

    (defun my/ivy-rich-cache-lookup (delegate candidate)
      (let ((result (gethash candidate my/ivy-rich-cache)))
	(unless result
	  (setq result (funcall delegate candidate))
	  (puthash candidate result my/ivy-rich-cache))
	result))

    (defun my/ivy-rich-cache-reset ()
      (clrhash my/ivy-rich-cache))

    (defun my/ivy-rich-cache-rebuild ()
      (mapc (lambda (buffer)
	      (ivy-rich--ivy-switch-buffer-transformer (buffer-name buffer)))
	    (buffer-list)))

    (defun my/ivy-rich-cache-rebuild-trigger ()
      (my/ivy-rich-cache-reset)
      (run-with-idle-timer 1 nil 'my/ivy-rich-cache-rebuild))

    (advice-add 'ivy-rich--ivy-switch-buffer-transformer :around 'my/ivy-rich-cache-lookup)
    (advice-add 'ivy-switch-buffer :after 'my/ivy-rich-cache-rebuild-trigger)
    (ivy-rich-mode))

  (leaf all-the-icons-ivy-rich
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :after ivy counsel ivy-rich
    :require t
    :config
    (setq all-the-icons-ivy-rich-display-transformers-list
	  (plist-put all-the-icons-ivy-rich-display-transformers-list 'ivy-switch-buffer
		     '(:columns
		       ((all-the-icons-ivy-rich-buffer-icon)
			(ivy-rich-candidate (:width 30))
			(ivy-rich-switch-buffer-size (:width 7))
			(ivy-rich-switch-buffer-indicators (:width 4 :face error :align right))
			(ivy-rich-switch-buffer-project (:width 15 :face success)))
		       :predicate
		       (lambda (cand) (get-buffer cand))
		       :delimiter "\t")))
    (all-the-icons-ivy-rich-mode 1)
    :defun all-the-icons-ivy-rich-mode
    :defvar all-the-icons-ivy-rich-display-transformers-list)

  (leaf ivy-posframe
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :blackout t
    :hook
    (ivy-mode-hook . ivy-posframe-mode)
    :custom
    ;; (ivy-posframe-font . default-font)
    (ivy-posframe-width . 75)
    (ivy-posframe-min-width . 75)
    (ivy-posframe-height . 10)
    (ivy-posframe-border-width . 10)
    (ivy-posframe-hide-minibuffer . t)
    (ivy-posframe-display-functions-alist
     . '((swiper          . ivy-display-function-fallback)
	 (counsel-sdcv-prompt . ivy-display-function-fallback)
	 (complete-symbol . ivy-posframe-display-at-point)
	 (flyspell-correct-ivy . ivy-posframe-display-at-point)
	 (t               . ivy-posframe-display-at-frame-center)))
    (ivy-posframe-parameters
     . '((left-fringe . 10)
	 (right-fringe . 10))))

  (leaf prescient
    :straight t
    :after ivy
    :require t
    :custom
    (prescient-aggressive-file-save . t)
    :config
    (prescient-persist-mode)
    :defun prescient-persist-mode)
  
  (leaf ivy-prescient
    :straight t
    :after ivy
    :require t
    :custom
    (ivy-prescient-retain-classic-highlighting . t)
    :config
    (ivy-prescient-mode)
    (setf (alist-get t ivy-re-builders-alist) #'ivy--regex-ignore-order)
    :defun ivy-prescient-re-builder ivy--regex-ignore-order)

  (leaf migemo
    :if (executable-find "cmigemo")
    :after ivy
    :straight t
    :custom
    (migemo-command . "cmigemo")
    (migemo-options . '("-q" "--emacs" "-i" "\a"))
    (migemo-dictionary . "/usr/share/migemo/utf-8/migemo-dict")
    (migemo-user-dictionary . nil)
    (migemo-regex-dictionary . nil)
    (migemo-coding-system . 'utf-8-unix)
    
    :preface
    (!! (defconst my/ivy-migemo-target-alist
	  '(swiper counsel-find-file counsel-imenu counsel-sdcv-prompt)))

    :config
    (defun my/migemo-get-pattern-shyly (word)
      (replace-regexp-in-string "\\\\(" "\\\\(?:" (migemo-get-pattern word)))

    (defun my/ivy--regex-migemo-pattern (word)
      (cond
       ((string-match "\\(.*\\)\\(\\[[^\0]+\\]\\)"  word)
	(concat (my/migemo-get-pattern-shyly (match-string 1 word))
		(match-string 2 word)))
       ((string-match "\\`\\\\([^\0]*\\\\)\\'" word)
	(match-string 0 word))
       (t
	(my/migemo-get-pattern-shyly word))))

    (defun my/ivy--regex-migemo (str)
      (when (string-match-p "\\(?:[^\\]\\|^\\)\\\\\\'" str)
	(setq str (substring str 0 -1)))
      (setq str (ivy--trim-trailing-re str))
      (cdr (let ((subs (ivy--split str)))
	     (if (= (length subs) 1)
		 (cons
		  (setq ivy--subexps 0)
		  (if (string-match-p "\\`\\.[^.]" (car subs))
		      (concat "\\." (my/ivy--regex-migemo-pattern (substring (car subs) 1)))
		    (my/ivy--regex-migemo-pattern (car subs))))
	       (cons
		(setq ivy--subexps (length subs))
		(replace-regexp-in-string
		 "\\.\\*\\??\\\\( "
		 "\\( "
		 (mapconcat
		  (lambda (x)
		    (if (string-match-p "\\`\\\\([^?][^\0]*\\\\)\\'" x)
			x
		      (format "\\(%s\\)" (my/ivy--regex-migemo-pattern x))))
		  subs
		  ".*")
		 nil t))))))

    (defun my/ivy--regex-migemo-plus (str)
      (cl-letf (((symbol-function 'ivy--regex) #'my/ivy--regex-migemo))
	(ivy--regex-plus str)))

    (defun my/ivy-migemo-add-rebuilders ()
      (interactive)
      (!foreach my/ivy-migemo-target-alist
	(setf (alist-get ,it ivy-re-builders-alist) #'my/ivy--regex-migemo-plus)))
    
    (load-library "migemo")
    (migemo-init)

    (my/ivy-migemo-add-rebuilders)

    :defun
    (migemo-init migemo-get-pattern ivy--trim-trailing-re ivy--split ivy--regex-plus)
    (my/migemo-get-pattern-shyly my/ivy--regex-migemo-pattern my/ivy--regex-migemo my/ivy--regex-migemo-plus my/ivy-migemo-add-rebuilders)
    :defvar ivy--subexps))



(leaf *prog
  :config
  (leaf company
    :straight t
    :hook
    (prog-mode-hook . company-mode)
    :custom
    (company-idle-delay . 0.5)
    (company-minimum-prefix-length . 3)
    (company-selection-wrap-around . t))

  (leaf company-posframe
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :blackout t
    :after company
    :config
    (company-posframe-mode)
    :defun company-posframe-mode)
  
  (leaf jedi-core
    :straight t
    :hook
    (python-mode-hook . jedi:setup)
    :custom
    (jedi:complete-on-dot . t)
    (jedi:use-shortcuts . t))

  (leaf company-jedi
    :straight t
    :defvar company-backends
    :after jedi-core company-posframe
    :config
    (add-to-list 'company-backends 'company-jedi))
  
  (leaf flycheck
    :straight t
    :init
    (idle-require 'flycheck 3)
    :custom
    (flycheck-check-syntax-automatically . '(save mode-enabled))
    (flycheck-idle-change-delay . 1)
    (flycheck-emacs-lisp-load-path . 'inherit)
    :defer-config
    (global-flycheck-mode)))



(leaf *look-and-feel
  :config
  (leaf dashboard
    :straight t
    :if (< (length command-line-args) 2)
    :defun dashboard-setup-startup-hook
    :defvar dashboard-init-info org-agenda-files
    :hook
    (dashboard-after-initialize-hook . my/dashboard-after-initialize-hook)
    :custom
    (dashboard-set-heading-icons . t)
    (dashboard-set-file-icons . t)
    (dashboard-center-content . t)
    (dashboard-items . '((recents  . 5)
			 (bookmarks . 5)
			 (agenda . 5)))
    (dashboard-set-footer . nil)
    `(dashboard-startup-banner . ,(expand-file-name "emacs.png" user-emacs-directory))
    :custom-face
    (dashboard-text-banner . '((nil (:inherit default))))
    :blackout t
    :preface
    (defun kill-org-agenda-buffers ()
      (dolist (file org-agenda-files)
	(when (get-file-buffer file)
	  (kill-buffer (get-file-buffer file)))))

    (defun my/dashboard-after-initialize-hook ()
      (setq dashboard-init-info
	    (let ((package-count 0)
		  (time (float-time
			 (time-subtract (current-time) before-init-time))))
	      (setq package-count (length (hash-table-keys straight--success-cache)))
	      (if (zerop package-count)
		  (format "Emacs started in %s seconds" time)
		(format "%d packages loaded in %s seconds" package-count time))))
      (dashboard-refresh-buffer)
      ;; org-agendaのファイルでvariable-pitchの表示をするため、一旦対象のバッファーをkillする
      (kill-org-agenda-buffers)
      (setq initial-buffer-choice (lambda () (get-buffer "*dashboard*"))))

    :init
    (dashboard-setup-startup-hook)
    :defun dashboard-refresh-buffer)
  
  (leaf doom-modeline
    :straight t
    :defun doom-modeline-def-modeline
    :defvar doom-modeline-icon
    :hook
    (emacs-startup-hook . doom-modeline-mode)
    :custom
    (doom-modeline-buffer-file-name-style . 'truncate-with-project)
    (doom-modeline-major-mode-icon . nil)
    (doom-modeline-buffer-encoding . nil)
    (doom-modeline-minor-modes . nil)
    :defer-config
    (when (or (window-system) (and (getenv "DISPLAY") (daemonp)))
      (setq doom-modeline-icon t))
    
    (doom-modeline-def-modeline 'main
      '(bar matches buffer-info remote-host buffer-position)
      '(input-method major-mode " " battery misc-info " "))

    (leaf time
      :require t
      :custom
      (display-time-string-forms . '((format "%s:%s" 24-hours minutes)))
      (display-time-interval . 5)
      :config
      (display-time-mode))

    (leaf battery
      :preface
      (! (require 'battery))
      :config
      (!if (and battery-echo-area-format battery-status-function)
	  (display-battery-mode 1))))

  (leaf centaur-tabs
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :defun centaur-tabs-change-fonts centaur-tabs-mode centaur-tabs-headline-match centaur-tabs--make-xpm
    :defvar centaur-tabs-bar-height centaur-tabs-active-bar
    :preface
    (defconst centaur-tabs-font-size
      (!if (string= (system-name) "mainpc")
	  105
	(!if (string= (system-name) "lapbook")
	    100
	  (!if (string= (system-name) "gpd")
	      100))))
    
    :init
    (if (daemonp)
	(add-hook 'server-after-make-frame-hook 'centaur-tabs-mode)
      (add-hook 'emacs-startup-hook 'centaur-tabs-mode))

    :bind
    ("<M-tab>" . centaur-tabs-forward)
    :custom
    (centaur-tabs-set-icons . t)
    (centaur-tabs-icon-scale-factor . 0.8)
    (centaur-tabs-icon-v-adjust . 0.0)
    (centaur-tabs-style . 'bar)
    (centaur-tabs-close-button . "")
    (centaur-tabs-down-tab-text . "  ")
    (centaur-tabs-backward-tab-text . "  ")
    (centaur-tabs-forward-tab-text . "  ")
    (centaur-tabs-right-edge-margin .  "  ")
    (centaur-tabs-left-edge-margin . " ")
    (centaur-tabs-set-bar . 'left)
    (centaur-tabs-plain-icons . nil)
    (centaur-tabs-show-navigation-buttons . t)
    (centaur-tabs-gray-out-icons . 'buffer)

    :config
    (defun my/centaur-tabs-fix (&rest _)
      (interactive)
      (with-selected-frame (selected-frame)
	(when (and (window-system) (framep-on-display))
	  (centaur-tabs-mode -1)
	  (centaur-tabs-headline-match)
	  (setq centaur-tabs-active-bar
		(centaur-tabs--make-xpm 'centaur-tabs-active-bar-face
					2
					centaur-tabs-bar-height))
	  (centaur-tabs-mode 1)
	  (centaur-tabs-change-fonts "HackgenNerd Console" centaur-tabs-font-size))))
    
    (centaur-tabs-change-fonts "HackgenNerd Console" centaur-tabs-font-size)
    (advice-add 'centaur-tabs-hide-tab :around
		(lambda (oldfn buf &rest args)
		  (if (with-current-buffer buf
			(let ((name (buffer-name)))
			  (or
			   (string-equal "vterm" name)
			   (string-prefix-p "*Async" name)
			   (string-prefix-p "*Messages" name)
			   (string-prefix-p "*sdcv" name)
			   (string-prefix-p "*SDCV" name)
			   (string-prefix-p "CAPTURE" name)
			   (string-prefix-p "*Contents" name)
			   (string-prefix-p "*flycheck" name)
			   (string-prefix-p "*Org " name)
			   (string-prefix-p "*Warnings" name)
			   (string-prefix-p "*Python" name)
			   (string-prefix-p "*Backtrace" name)
			   ;; (string-prefix-p "*scratch" name)
			   (string-prefix-p " *undo-tree*" name)
			   (string-prefix-p "Notes of" name)
			   (string-suffix-p "annots*" name)
			   (string-prefix-p "*dashboard" name)
			   (eq major-mode 'imenu-list-major-mode)
			   (eq major-mode 'nov-mode))))
		      t
		    (apply oldfn buf args))))

    (advice-add 'load-theme :after 'my/centaur-tabs-fix))

  (leaf nyan-mode
    :straight t)

  (leaf hide-mode-line
    :straight t
    :hook
    ((neotree-mode-hook undo-tree-visualizer-mode-hook vterm-mode-hook imenu-list-major-mode-hook)
     . hide-mode-line-mode))

  (leaf powerline
    :straight t
    :after t
    :advice
    (:after load-theme (lambda (&rest _) (powerline-reset)))
    :defun powerline-reset))



(leaf *language
  :config
  (leaf sdcv
    :straight (sdcv :repo "manateelazycat/sdcv")
    :commands sdcv-popup counsel-sdcv sdcv-search-input
    :bind
    ("<f5>" . sdcv-search-input)
    ("<f6>" . sdcv-search-pointer)
    ("C-<f5>" . counsel-sdcv)
    :hook
    (sdcv-mode-hook . my-sdcv-mode-hook)
    
    :preface
    (eval-and-compile
      (defconst sdcv-font-magnification
	(!if (string= (system-name) "mainpc")
	    1.05
	  (!if (string= (system-name) "lapbook")
	      1.0
	    (!if (string= (system-name) "gpd")
		1.1)))))

    (defvar sdcv-history)
    (defmacro sdcv-make-history ()
      '(setq sdcv-history
	     (with-temp-buffer
	       (insert-file-contents "~/.sdcv_history")
	       (shell-command-on-region (point-min) (point-max) "tac" nil t)
	       (while (search-forward "nil\n" nil t)
		 (replace-match ""))
	       (shell-command-on-region (point-min) (point-max) "awk '!a[$0]++'" nil t)
	       (split-string (buffer-substring-no-properties (point-min) (point-max)) "[\f\t\n\r\v]+"))))
    
    :custom
    (sdcv-env-lang . "ja_JP.UTF-8")
    (sdcv-dictionary-data-dir . "$HOME/.stardict/dic")
    (sdcv-tooltip-timeout . 5)
    (sdcv-tooltip-font . "Source Han Sans JP-9")
    (sdcv-dictionary-complete-list . '("英辞郎 [英和]" "英辞郎 [和英]" "英辞郎 [例文]"))
    (sdcv-dictionary-simple-list . '("英辞郎 [英和]" "英辞郎 [和英]"))
    (sdcv-fail-notify-string . "検索結果が見つかりません！")

    :config
    (setq sdcv-filter-string-list
	  `(("^Found [0-9]* items, similar to .*\n" . "")
	    ("^Nothing similar to .*, sorry :(\n" . "")
	    ("^-->\\(.*\\)\n-->\\(.*\\)[ \t\n]*" . " \\1 \\2\n\n")
	    ("\n\n\n" . "\n\f\n")
	    ("英辞郎 .英和." . "[E2J]")
	    ("英辞郎 .和英." . "[J2E]")
	    ("英辞郎 .例文." . "[EX]")))
    (setq sdcv-mode-font-lock-keywords
	  '(;; Search word
	    ("^.*\\(E2J\\|J2E\\|EX\\). \\(.*\\)$" . (2 font-lock-function-name-face))
	    ("\\(\\[\\(E2J\\|J2E\\|EX\\)\\]\\)" . (1 font-lock-string-face))
	    ("\\(【.\\{1,4\\}】\\)" . (1 font-lock-constant-face))
	    ("\\([《〈].\\{1,5\\}[》〉]\\)" . (1 font-lock-comment-face))
	    ;; Type name
	    ("^<<\\([^>]*\\)>>$" . (1 font-lock-comment-face))
	    ;; Phonetic symbol
	    ("^\\/\\([^>]*\\)\\/$" . (1 font-lock-string-face))
	    ("^\\[\\([^]]*\\)\\]$" . (1 font-lock-string-face))
	    ;; Prompt
	    ("^\\(Emacs Dictionary\\)$" . (1 font-lock-keyword-face))))

    (defun counsel-sdcv-prompt (&optional word)
      (sdcv-make-history)
      (ivy-read "Word: "
		sdcv-history
		:initial-input (or word (sdcv-region-or-word))
		:preselect word
		:action #'message
		:sort nil
		:caller 'counsel-sdcv-prompt))

    (defun counsel-sdcv (&optional word)
      (interactive)
      (let* ((word (or word (counsel-sdcv-prompt))))
	(sdcv-search-detail word)))

    (defun sdcv-popup (&optional word)
      (require 'sdcv nil t)
      (let* ((popwin:special-display-config (or popwin:special-display-config-backup nil)))
	(if (not (eq word nil))
	    (sdcv-search-detail word))
	(sdcv-goto-sdcv)
	(with-current-buffer (sdcv-get-buffer)
	  (when (string= (buffer-substring-no-properties (point-min) (point-max)) "")
	    (setq buffer-read-only nil)
	    (insert "Emacs Dictionary\n")
	    (insert "\n")
	    (insert "Press [F5] or Ctrl+[F5] to look up a word in dictionaries.\n")
	    (insert "[F5] か Ctrl+[F5] キーを押すと、辞書の検索を開始します。\n")
	    (goto-char (point-max))))
	(delete-other-windows)
	(set-window-dedicated-p nil t)))
    
    (defun my-sdcv-mode-hook ()
      (variable-pitch-mode)
      (setq-local olivetti-body-width 0.98)
      (face-remap-add-relative 'default :height (round (! (* 95 sdcv-font-magnification))))
      (face-remap-set-base 'font-lock-keyword-face
			   :inherit 'font-lock-keyword-face :inherit 'variable-pitch
			   :height (round (! (* 130 sdcv-font-magnification))) :weight 'semibold)
      (face-remap-set-base 'font-lock-function-name-face
			   :inherit 'font-lock-function-name-face :inherit 'variable-pitch
			   :height (round (! (* 110  sdcv-font-magnification))) :weight 'semibold))

    
    (advice-add 'sdcv-filter :override
		(lambda (sdcv-string)
		  (dolist (item sdcv-filter-string-list)
		    (-let [(regexp . str) item]
		      (setq sdcv-string (replace-regexp-in-string regexp str sdcv-string))))
		  (if (equal sdcv-string "")
		      sdcv-fail-notify-string
		    (with-temp-buffer
		      (insert sdcv-string)
		      (goto-char (point-min))
		      (buffer-string)))))
    
    (advice-add 'sdcv-prompt-input :override
		(lambda ()
		  (sdcv-make-history)
		  (read-string (format "Word (%s): " (or (sdcv-region-or-word) ""))
			       nil 'sdcv-history
			       (sdcv-region-or-word))))
    
    (advice-add 'sdcv-goto-sdcv :after
		(lambda ()
		  (with-selected-window (get-buffer-window (sdcv-get-buffer))
		    (hide-mode-line-mode 1)
		    (page-break-lines-mode 1))))
    (advice-add 'sdcv-quit :after
		(lambda (&rest _)
		  (if (string-match "^emacs-sdcv\\(-popup\\)*$" (frame-parameter nil 'name))
		      (delete-frame nil t))))
    
    :defvar sdcv-filter-string-list sdcv-mode-font-lock-keywords
    :defun sdcv-region-or-word sdcv-search-detail sdcv-goto-sdcv sdcv-get-buffer counsel-sdcv-prompt)

  (leaf flyspell
    :straight t
    :init
    (eval-after-load "ispell"
      '(add-to-list 'ispell-skip-region-alist '("[^\000-\377]+")))
    :custom
    (ispell-program-name . "aspell"))

  (leaf flyspell-correct-ivy
    :straight t
    :commands flyspell-correct-ivy
    :bind
    ("s-f" . flyspell-correct-wrapper)))



(leaf *org
  :config
  (leaf org
    :straight (org :type built-in)
    :defun org-get-indirect-buffer org-sparse-tree my/serif-mode
    :defvar org-modules org-file-apps
    :hook
    (org-mode-hook . my/org-mode-hook)
    (imenu-after-jump-hook . (lambda () (when (eq major-mode 'org-mode) (org-show-entry))))
    :bind (:org-mode-map
	   ("<f9>" . org-toggle-narrow-to-subtree)
	   ("C-c \\" . org-sparse-tree-indirect-buffer)
	   ("C-c /" . org-match-sparse-tree-indirect-buffer)
	   ("M-o" . ace-link-org))
    :after t
    :custom
    (org-startup-truncated . nil)
    (org-startup-indented . nil)
    (org-indent-indentation-per-level . 1)
    (org-directory . "~/org/")
    (org-startup-with-inline-images . t)
    (org-image-actual-width . nil)
    (org-hide-emphasis-markers . t)
    (org-fontify-quote-and-verse-blocks . nil)
    (org-fontify-whole-heading-line . t)
    (org-src-tab-acts-natively . t)
    (org-src-preserve-indentation . t)
    (org-edit-src-content-indentation . 0)
    (org-src-fontify-natively . t)
    (org-src-tab-acts-natively . t)
    (org-confirm-babel-evaluate . nil)
    (org-src-window-setup . 'current-window)

    :custom-face
    (org-priority . '((nil (:inherit fixed-pitch :weight bold :foreground "#BF616A" ))))
    (org-block . '((nil (:inherit fixed-pitch ))))
    (org-code . '((nil (:inherit (shadow fixed-pitch)))))
    (org-document-info . '((nil (:foreground "dark orange"))))
    (org-document-info-keyword . '((nil (:inherit (shadow fixed-pitch)))))
    (org-indent . '((nil (:inherit (fixed-pitch org-hide)))))
    (org-meta-line . '((nil (:inherit (font-lock-comment-face fixed-pitch)))))
    (org-property-value . '((nil (:inherit fixed-pitch))))
    (org-special-keyword . '((nil (:inherit (font-lock-comment-face fixed-pitch)))))
    (org-table . '((nil (:inherit fixed-pitch :foreground "#83a598"))))
    (org-tag . '((nil (:inherit (shadow fixed-pitch) :height 0.85 :weight bold))))
    (org-verbatim . '((nil (:inherit (shadow fixed-pitch)))))
    (org-date . '((nil (:inherit fixed-pitch :color "#EBCB8B"))))
    
    :config
    (defun org-sparse-tree-indirect-buffer (arg)
      (interactive "P")
      (let ((origbuf (current-buffer))
	    (ibuf (switch-to-buffer (org-get-indirect-buffer))))
	(condition-case _
	    (org-sparse-tree arg)
	  (quit (kill-buffer ibuf)
		(switch-to-buffer origbuf)))))

    (defun org-match-sparse-tree-indirect-buffer (_)
      (interactive "P")
      (let ((origbuf (current-buffer))
	    (ibuf (switch-to-buffer (org-get-indirect-buffer))))
	(condition-case _
	    (call-interactively 'org-match-sparse-tree)
	  (quit (kill-buffer ibuf)
		(switch-to-buffer origbuf)))))
    
    (defun my/org-mode-hook ()
      (imenu-add-to-menubar "Imenu")

      (when window-system
	(face-remap-set-base 'org-block-begin-line
			     :inherit 'variable-pitch :inherit 'org-block-begin-line :height 90)
	(face-remap-set-base 'org-ref-cite-face
			     :inherit 'variable-pitch :inherit 'org-ref-cite-face :weight 'normal :height 90)
	(face-remap-set-base 'org-footnote
			     :inherit 'variable-pitch :inherit 'org-footnote :height 90)
	(face-remap-set-base 'org-code :inherit 'org-code)
	(face-remap-set-base 'org-checkbox :inherit 'org-checkbox :inherit 'fixed-pitch))

      ;; (if (string-match (format "%s.*/Documents/.*" (getenv "HOME")) (format "%s" buffer-file-name))
      ;; 	  (progn
      ;; 	    (setq olivetti-body-width 90)
      ;; 	    (when window-system
      ;; 	      (my/serif-mode 1)
      ;; 	      (setq line-spacing 2)
      ;; 	      (face-remap-set-base 'bold :inherit 'variable-pitch :weight 'semibold)
      ;; 	      (face-remap-add-relative 'org-document-title :height 160)
      ;; 	      (face-remap-add-relative 'org-level-1 :height 150)
      ;; 	      (face-remap-add-relative 'org-level-2 :height 140)
      ;; 	      (face-remap-add-relative 'org-level-3 :height 130)))

      (when window-system
	(variable-pitch-mode 1)
	(setq line-spacing 1)
	(face-remap-add-relative 'org-document-title :height 140)
	(dotimes (i 8)
	  (face-remap-add-relative (intern (format "org-level-%s" (1+ i)))
				   :weight 'semibold)))
      
    (setq org-modules (delete 'ol-gnus org-modules)
	  org-modules (delete 'ol-w3m org-modules)
	  org-modules (delete 'ol-irc org-modules))

    (setq org-file-apps (append '(("^calibre:" . "xdg-open %s"))
				org-file-apps))))

  (leaf org-tempo
    :after org
    :require t
    :defvar org-structure-template-alist
    :config
    (add-to-list 'org-structure-template-alist '("Q" . "quotation")))

  (leaf org-bullets
    :if (or (window-system) (and (getenv "DISPLAY") (daemonp)))
    :straight t
    :hook
    (org-mode-hook . org-bullets-mode))

  (leaf org-agenda
    :after org
    :bind
    ("C-c a" . org-agenda)
    :hook
    (org-agenda-mode-hook . page-break-lines-mode)
    :require page-break-lines
    :custom
    (org-agenda-files . '("~/org/todo_list.org" "~/org/daily.org"))
    (org-agenda-custom-commands . '(("a" "Agenda and all TODO's"
				     (;; 今日の予定・行動記録
				      (agenda "" ((org-agenda-span 1)
						  (org-agenda-show-log 'clockcheck)
						  (org-agenda-clockreport-mode t)))
				      ;; 2週間の予定
				      (agenda "" ((org-agenda-span 14)
						  (org-agenda-show-log nil)
						  (org-agenda-clockreport-mode nil)
						  (org-agenda-hide-tags-regexp "\\|habit")
						  (org-agenda-filter-by-tag t)))
				      (alltodo "")))))

    (org-todo-keywords . '((sequence "TODO" "NEXT" "|" "DONE")))
    (org-refile-targets . '((org-agenda-files :maxlevel . 1)))
    (org-agenda-block-separator . "\f")
    (org-agenda-todo-ignore-with-date . t)
    (org-agenda-start-on-weekday . nil)
    (org-clock-in-switch-to-state . nil))

  (leaf ox-icalendar
    :after org
    :defun org-icalendar-export-to-ics
    :custom
    (org-icalendar-combined-description . "Org-Modeのスケジュール出力")
    (org-icalendar-combined-agenda-file . "~/org/todo_list.ics")
    (org-icalendar-timezone . nil)
    (org-icalendar-include-todo . t)
    (org-icalendar-use-scheduled . '(event-if-todo))
    (org-agenda-default-appointment-duration . 60)
    (org-icalendar-use-deadline . '(event-if-todo))
    ;;  (org-icalendar-after-save-hook  . t)
    :config
    (add-hook 'after-save-hook
	      (lambda ()
		(if (string-match (format "%s.*/org/todo_list.org" (getenv "HOME")) (format "%s" buffer-file-name))
		    (org-icalendar-export-to-ics)))))

  (leaf org-capture
    :after org
    :require t
    :defvar org-directory org-capture-templates
    :defer-config
    (my/all-the-icons-init)
    (setq org-capture-templates
	  `(("n" , (concat (all-the-icons-faicon "pencil-square-o" :v-adjust 0.01) " Notes")
	     entry  (file+headline , (concat org-directory "notes.org") "Inbox")
	     "* %?\n  :CREATED: %U\n\n" :empty-lines 1 )
	    ("q" , (concat (all-the-icons-faicon "pencil-square-o" :v-adjust 0.01) " Notes with quotes")
	     entry  (file+headline , (concat org-directory "notes.org") "Inbox")
	     "* %?\n  :PROPERTIES:\n  :CREATED: %U\n  :SOURCE: [[file:%:link]]\n  :END:\n\n#+begin_quote\n%i\n#+end_quote\n\n" :empty-lines 1 )
	    ("t" , (concat (all-the-icons-faicon "calendar-plus-o" :v-adjust 0.01) " Todo")
	     entry (file , (concat org-directory "todo_list.org"))
	     "* TODO %?\n\n" :empty-lines 1 )
	    ("d" , (concat (all-the-icons-faicon "calendar-plus-o" :v-adjust 0.01) " Daily routines")
	     entry (file , (concat org-directory "daily.org"))
	     "%[~/org/daily_template.org]" :empty-lines 1 )
	    ("w" , (concat (all-the-icons-faicon "book" :v-adjust 0.01) " Words")
	     entry (file+headline , (concat org-directory "words.org") "Inbox")
	     "* TODO %(with-current-buffer (org-capture-get :original-buffer) (org-sdcv-clipper \"%i\"))\n  :CREATED: %U\n  :NOTE: %?\n\n%(message org-sdcv-content)" :empty-lines 1)
	    ;;	  ("p" , (concat (all-the-icons-faicon "link" :v-adjust 0.01) " Protocol"))
	    ("L" , (concat (all-the-icons-faicon "link" :v-adjust 0.01) " Protocol Link")
	     entry (file+headline , (concat org-directory "notes.org") "Inbox")
	     "* [[%:link][%:description]] \t:ril:\n  :CREATED: %U\n\n%?\n" :empty-lines 1)
	    ("p" , (concat (all-the-icons-faicon "link" :v-adjust 0.01) " Protocol link with quotes")
	     entry  (file+headline , (concat org-directory "notes.org") "Inbox")
	     "* [[%:link][%:description]] \t:ril:\n  :PROPERTIES:\n  :CREATED: %U\n  :SOURCE: [[%:link][%:description]]\n  :END:\n\n#+begin_quote\n%i\n#+end_quote\n\n" :empty-lines 1)))

    (defun org-sdcv-clipper (&optional str)
      (unless (string-equal (buffer-name) "*SDCV*")
	(if (eq str (or "" nil))
	    (sdcv-search-input)
	  (sdcv-search-input str)))

      (switch-to-buffer "*SDCV*")
      (unless (search-forward "[E2J]" nil t)
	(delete-window)
	(keyboard-quit))
      (setq org-sdcv-title (buffer-substring (point) (point-at-eol)))
      (search-forward "\n\n")
      (setq org-sdcv-content (buffer-substring (point) (point-max)))
      (kill-buffer-and-window)

      (switch-to-buffer "words.org")
      (goto-char (point-min))
      (when (search-forward-regexp (concat "^*? " org-sdcv-title) nil t)
	(outline-show-subtree)
	(if (not (y-or-n-p "Found an entry with the same title.  Do you add a new entry? "))
	    (keyboard-quit)))
      (goto-char (point-max))
      org-sdcv-title)

    :defvar org-sdcv-title org-sdcv-content
    :defun outline-show-subtree)

  (leaf org-protocol
    :if (or (daemonp) (server-running-p))
    :defun org-capture-kill
    :init
    (idle-require 'org-protocol 5)
    :defer-config
    (defadvice org-capture
	(after make-full-window-frame activate)
      "Advise capture to be the only window when used as a popup"
      (when (equal "emacs-capture" (frame-parameter nil 'name))
	(delete-other-windows)
	(hide-mode-line-mode)))
    (defadvice org-capture-finalize
	(after delete-capture-frame activate)
      "Advise capture-finalize to close the frame"
      (when (equal "emacs-capture" (frame-parameter nil 'name))
	(delete-frame)))

    (add-hook 'delete-frame-functions (lambda (_)
					(when (and (boundp 'org-capture-mode) org-capture-mode)
					  (org-capture-kill)))))

  (leaf ox-latex
    :after org
    :bind (:org-mode-map
	   ( "C-c C-e" . org-export-dispatch))
    :custom
    (org-latex-pdf-process . '("latexmk %f"))
    ;;  (org-export-in-background t)
    ;;  (org-export-async-init-file "~/.emacs.d/org-export-async-init.el")
    (org-latex-with-hyperref . nil)
    (org-latex-logfiles-extensions . '("lof" "lot" "tex~" "aux" "idx" "log" "out" "toc" "nav" "snm" "vrb" "dvi" "fdb_latexmk" "blg" "brf" "fls" "entoc" "ps" "spl" "bbl" "xml" "synctex.gz" "bcf" "run.xml"))
    :defer-config
    (unless org-export-in-background
      (load (! (expand-file-name "my-org-latex-classes" user-emacs-directory)))))
  
  (leaf org-noter
    :after org
    :straight t
    :defun org-noter--doc-location-change-handler
    :bind
    ("C-c n" . org-noter)
    :custom
    (org-noter-default-notes-file-names . '("notes_annots.org"))
    (org-noter-notes-search-path . '("~/org/"))
    (org-noter-separate-notes-from-heading . t)
    (org-noter-auto-save-last-location . t)
    (org-noter-notes-window-behavior . '(start))
    :config
    ;; セッションは全画面で開始。
    (advice-add 'org-noter--create-session :after
		(lambda (&rest _)
		  (set-frame-parameter (selected-frame) 'fullscreen 'fullboth)))
    ;; 自動セーブはkillのときに行う。
    (advice-add 'org-noter--nov-scroll-handler :override
		(lambda (&rest _)))
    (advice-add 'org-noter-kill-session :before
		(lambda (&rest _) (org-noter--doc-location-change-handler))))

  (leaf org-pomodoro
    :straight t
    :after org
    :require notifications
    :defun notifications-notify
    :bind
    (:org-agenda-mode-map
     ("p" . org-pomodoro))
    (:org-mode-map("C-x p" . org-pomodoro))
    :hook
    (org-pomodoro-started-hook . (lambda () (notifications-notify
					     :title "org-pomodoro"
					     :body "Let's focus for 25 minutes!")))
    (org-pomodoro-finished-hook . (lambda () (notifications-notify
					      :title "org-pomodoro"
					      :body "Well done! Take a break.")))
    :custom
    (org-pomodoro-play-sounds . nil)
    (org-pomodoro-ask-upon-killing . t)
    (org-pomodoro-format . "⌚%s")
    (org-pomodoro-short-break-format . "☕ %s")
    (org-pomodoro-long-break-format  . "☕☕ %s")
    :custom-face
    (org-pomodoro-mode-line . '((t (:foreground "#ff5555"))))
    (org-pomodoro-mode-line-break . '((t (:foreground "#50fa7b")))))

  (leaf *org-babel-imenu
    :leaf-autoload nil
    :bind
    ("<C-f12>" . my/org-src-imenu)
    :defun org-edit-special org-show-entry
    :after org
    :preface
    (defun my/org-src-imenu (&optional func srcmode srcedit)
      (interactive)
      (let ((func (or func #'counsel-imenu))
	    (srcmode (or srcmode #'emacs-lisp-mode))
	    (srcedit (or srcedit t)))
	(funcall srcmode)
	(condition-case _
	    (progn (funcall func)
		   (org-mode)
		   (if srcedit
		       (org-edit-special)
		     (org-show-entry)
		     (jit-lock-fontify-now)))
	  (quit (org-mode)
		(org-show-entry)
		(jit-lock-fontify-now)))))))



(leaf *documents
  :config
  (leaf doc-view
    :magic
    ("%DOCX" . doc-view-mode)
    :custom
    (doc-view-continuous . t))

  (leaf pdf-tools
    :straight t
    :magic
    ("%PDF" . pdf-view-mode)
    :hook
    (pdf-view-mode-hook . my/pdf-view-mode-hook)
    :bind
    (:pdf-view-mode-map
     ("TAB" . pdf-outline)
     ("<right>" . (lambda () (interactive)
		    (if (eq pdf-view-display-size 'fit-page)
			(pdf-view-next-page-command)
		      (image-forward-hscroll 2))))
     ("<left>" . (lambda () (interactive)
		   (if (eq pdf-view-display-size 'fit-page)
		       (pdf-view-previous-page-command)
		     (image-backward-hscroll 2)))))
    :custom
    (pdf-view-display-size . 'fit-page)
    (pdf-view-resize-factor . 1.1)
    (pdf-cache-prefetch-delay . 3)
    (pdf-view-midnight-colors . '("#FFFFFF" . "#2E3440"))
    
    :config
    (defun my/pdf-view-mode-hook ()
      (setq-local migemo-isearch-enable-p nil)
      (pdf-sync-minor-mode)
      (pdf-links-minor-mode)
      (pdf-isearch-minor-mode))

    (pdf-tools-install :no-query)
    (define-key pdf-view-mode-map (kbd "C-s") 'isearch-forward)

    :defvar migemo-isearch-enable-p)

  (leaf pdf-view-restore
    :straight t
    :after pdf-view
    :hook
    (pdf-view-mode-hook . (lambda()
			    (pdf-view-restore-mode)
			    (remove-hook 'pdf-view-after-change-page-hook 'pdf-view-restore-save t)
			    (add-hook 'kill-buffer-hook 'pdf-view-restore-save nil t))))
  
  (leaf nov
    :straight t
    :mode
    ("\\.epub\\'" . nov-mode)
    :custom
    (nov-variable-pitch . nil)
    :hook
    (nov-pre-html-render-hook . my/nov-pre-html-render)
    :defvar nov-metadata nov-text-width
    :config
    (defun my/nov-pre-html-render ()
      (olivetti-mode 1)
      (my/serif-mode 1)
      (face-remap-add-relative 'my/serif :height 120)
      (setq line-spacing 4)
      (let* ((nov-lang-en nil))
	(dolist (item nov-metadata)
	  (-let [(key . value) item]
	    (when (and (eq key 'language) (equal (format "%s" value) "en"))
	      (setq nov-lang-en t))))
	(cond (nov-lang-en
	       (setq word-wrap t)
	       (setq-local nov-text-width 76)
	       (setq olivetti-body-width 80))
	      (t
	       (setq-local nov-text-width 81)
	       (setq olivetti-body-width 94))))))

  (leaf eww
    :bind
    ("C-x w" . eww-search-words)
    :custom
    (url-user-agent . "User-Agent: w3m/0.5.3\r\n")
    (eww-search-prefix . "https://www.google.co.jp/search?q=")))




(leaf *my/scripts
  :config
  (leaf *wc
    ;; https://www.emacswiki.org/emacs/WordCount
    :leaf-autoload nil
    :bind
    ("<f7>" . wc)
    :preface
    (defun wc (&optional start end)
      "Prints number of lines, words and characters in region or whole buffer."
      (interactive)
      (let ((n 0)
	    (start (or start (if mark-active (region-beginning) (point-min))))
	    (end (or end (if mark-active (region-end) (point-max)))))
	(save-excursion
	  (goto-char start)
	  (while (< (point) end) (if (forward-word 1) (setq n (1+ n)))))
	(message "%d lines, %d words, %d chars" (count-lines start end) n (- end start)))))

  (leaf *concentrate-screen
    :leaf-autoload nil
    :defvar centaur-tabs-mode
    :bind
    ("<M-f11>" . my-toggle-concentrate-screen)
    :preface
    (defun my-toggle-concentrate-screen ()
      (interactive)
      (if centaur-tabs-mode
	  (centaur-tabs-mode 0)
	(centaur-tabs-mode 1))
      (if global-hide-mode-line-mode
	  (global-hide-mode-line-mode -1)
	(global-hide-mode-line-mode +1))
      (redraw-display)))

  (leaf *modified-buffer-exist-p
    :preface
    (defun my/modified-buffer-exist-p ()
      (let ((i 0))
	(dolist (buf (buffer-list))
	  (when (and (buffer-file-name buf)
		     (buffer-modified-p buf))
	    (setq i (1+ i))))
	i))))

(leaf *after-init
  :preface
  ;; 参考: https://takaxp.github.io/init.html
  (defun my/load-init-time ()
    "Loading time of user init files including time for `after-init-hook'."
    (let ((time1 (float-time
                  (time-subtract after-init-time my-before-load-init-time)))
          (time2 (float-time
                  (time-subtract (current-time) my-before-load-init-time))))
      (message (concat "Loading init files: %.0f [msec], "
		       "of which %.f [msec] for `after-init-hook'.")
	       (* 1000 time1) (* 1000 (- time2 time1)))))
  (defun my/after-startup-hook ()
    (setq file-name-handler-alist my-saved-file-name-handler-alist)
    (setq debug-on-error nil))
  :init
  (add-hook 'after-init-hook 'my/load-init-time t)
  (add-hook 'emacs-startup-hook 'my/after-startup-hook t)
  :defvar my-before-load-init-time)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files '("~/org/daily.org" "~/org/todo_list.org"))
 '(safe-local-variable-values
   '((eval hs-hide-all)
     (olivetti-mode . nil)
     (svg-tag-mode . t )
     (variable-pitch-mode)
     (org-checkbox-hierarchical-statistics))))

(provide 'init)
;;; init.el ends here
