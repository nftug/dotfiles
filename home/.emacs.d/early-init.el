;; early-init.el --- Emacs early-init -*- lexical-binding:t -*-
;;; Commentary:
;;; early-init.el written by nftug
;;;
;;; This file is generated from init.org by org-babel.
;;;
;;; DO NOT EDIT THIS FILE!!
;;; If you want to edit this file, please edit from init.org.
;;; When you save the org file, both elisp and elc files are automatically generated.
;;;
;;; Code:
;;;

;; 起動時間の測定に使う
(defconst my-before-load-init-time (current-time))

(eval-when-compile
  (load (expand-file-name "macro" user-emacs-directory) t t))

(setq package-enable-at-startup nil)
(setq frame-inhibit-implied-resize t)
(setq inhibit-startup-message t)
(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message t)
(setq inhibit-default-init t)
(setq site-run-file nil)

;; バイトコンパイルでのエラー抑制
;;(deftheme use-package)
;;(enable-theme 'use-package)

(set-scroll-bar-mode nil)
(line-number-mode -1)
(column-number-mode -1)
(menu-bar-mode -1)
(tool-bar-mode -1)

(custom-set-variables '(custom-file (expand-file-name "custom.el" user-emacs-directory)))

(setq initial-scratch-message nil)

(defconst default-font
  (!if (string= (system-name) "MacBook-Air.local")
      "HackGen Console NF-13"
    (!if (string= (system-name) "lapbook")
	"HackGen Console NF-10"
      (!if (string= (system-name) "gpd")
	  "HackGen Console NF-11"
	"HackGen Console NF-11.5"))))

(setq initial-frame-alist
      (append `((width . 140)
                (height . 45)
		(vertical-scroll-bars . nil)
		(font . ,default-font)
		;; (alpha . (1.0 0.7))
                (cursor-type . bar))
	      initial-frame-alist))
(setq default-frame-alist initial-frame-alist)

(modify-frame-parameters nil '((sticky . t) (width . 135) (height . 42)))

(setq frame-title-format '((:eval (if (buffer-file-name) "%f" "%b")) " - Emacs"))

(setq byte-compile-warnings
      '(not free-vars unresolved callargs redefine obsolete noruntime
            cl-functions interactive-only make-local))
;; (setq byte-compile-warnings '(not obsolete))
(setq ad-redefinition-action 'accept)
(custom-set-variables '(warning-suppress-types '((comp))))


;; (require 'profiler)
;; (profiler-start 'cpu)
;; (add-hook 'after-init-hook
;; 	  (lambda ()
;; 	    (profiler-report)
;; 	    (profiler-stop)))

(provide 'early-init)
;;; early-init.el ends here
