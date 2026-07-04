;; default all buffers to utf-8, fixes some quirks in scratch buffers
;; on Windows
(set-language-environment "UTF-8")

;; Bundle all installed packages' autoloads into a single precompiled file
;; (package-quickstart.el) so startup activates them with one load instead
;; of scanning every package directory. Run `package-quickstart-refresh'
;; once to generate it; it's kept fresh automatically after install/remove.
(setq package-quickstart t)

;; Strip UI chrome before the first frame is drawn, avoiding a startup flash
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)

;; LSP JSON parsing generates a lot of garbage; the default 800kb GC
;; threshold causes frequent pauses under that load
(setq gc-cons-threshold (* 64 1024 1024))

;; LSP servers send large payloads; the default 4kb process read chunk
;; makes Emacs poll constantly instead of reading it in one go
(setq read-process-output-max (* 1024 1024))

;; Don't pop up *Warnings* for async native-comp noise mid-session
(setq native-comp-async-report-warnings nil)

