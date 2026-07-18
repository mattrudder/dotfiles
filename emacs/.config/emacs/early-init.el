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


;; GUI Emacs.app on macOS doesn't inherit the shell's environment, so
;; LIBRARY_PATH is unset and libgccjit's driver can't find Homebrew gcc's
;; runtime libs (e.g. libemutls_w.a) at link time -- native compilation then
;; fails with "error invoking gcc driver". Point it at gcc's lib dirs. The
;; wildcard picks up the arch/version subdir (.../gcc/<triple>/<ver>/), so this
;; keeps working across `brew upgrade gcc' version bumps.
(when (and (eq system-type 'darwin)
		   (fboundp 'native-comp-available-p)
		   (native-comp-available-p))
  (let* ((gcc-lib "/opt/homebrew/lib/gcc/current")
		 (nested (car (file-expand-wildcards (expand-file-name "gcc/*/*" gcc-lib))))
		 (dirs (delq nil (list gcc-lib nested (getenv "LIBRARY_PATH")))))
	(when (file-directory-p gcc-lib)
	  (setenv "LIBRARY_PATH" (mapconcat #'identity dirs ":")))))

;; Make Emacs self-sufficient for locating external tools, regardless of how it
;; was started. A shell-spawned daemon inherits the interactive shell's PATH,
;; but a launchd/Finder/service-launched Emacs gets only the bare path_helper
;; PATH (no mise, no Homebrew). Prepend known tool dirs so both cases work.
;;
;; Cross-platform (this config is shared with Windows and Linux):
;;   - Every entry is guarded by `file-directory-p', so absent dirs are no-ops.
;;   - mise's shims dir differs by OS (Unix: ~/.local/share/mise/shims;
;;     Windows: %LOCALAPPDATA%\\mise\\shims); both are listed and only the
;;     running platform's own path will exist.
;;   - `path-separator' is \";\" on Windows, \":\" elsewhere.
;;   - Homebrew is darwin-only.
;;
;; Precedence: entries are prepended, so the LAST one processed ends up first
;; on PATH. mise shims are processed last -> they win, giving the correct
;; per-project tool version (e.g. node 22.x pinned in a repo) over anything in
;; Homebrew or the inherited PATH. eglot-spawned servers (whose
;; `#!/usr/bin/env node' shebang needs node) then resolve correctly.
(defun mr/prepend-exec-path (dir)
  "If DIR exists, prepend it to `exec-path' and the PATH environment variable."
  (when (and dir (file-directory-p dir))
	(add-to-list 'exec-path dir)
	(setenv "PATH" (concat dir path-separator (getenv "PATH")))))

(dolist (dir (append
			  ;; Lowest precedence first (Homebrew, darwin only).
			  (when (eq system-type 'darwin)
				'("/opt/homebrew/sbin" "/opt/homebrew/bin"))
			  ;; Highest precedence last: mise shims (per-project tool versions).
			  ;; Unix/macOS layout:
			  (list (expand-file-name "~/.local/share/mise/shims"))
			  ;; Windows layout: %LOCALAPPDATA%\mise\shims (mise's default data dir).
			  (when (eq system-type 'windows-nt)
				(list (expand-file-name
					   "mise/shims"
					   (or (getenv "LOCALAPPDATA")
						   (expand-file-name "~/AppData/Local")))))))
  (mr/prepend-exec-path dir))

;; Emacs on Windows never inherits the MSVC "Developer Command Prompt"
;; environment (INCLUDE/LIB/LIBPATH, plus PATH entries for cl.exe/link.exe)
;; that `vcvarsall.bat' sets up, since nothing runs it before Emacs starts.
;; Capture it once per session so every subprocess (compile, eglot, etc.)
;; gets a working MSVC toolchain.
;;
;; vswhere.exe's location is stable across VS versions/editions/reinstalls
;; (it lives under the VS Installer, not inside any specific VS instance),
;; so this keeps working without hardcoding a versioned VS path.
(defun mr/msvc-dev-environment ()
  "Return the environment `vcvarsall.bat x64' produces, as an alist.
Returns nil if a Visual Studio C++ toolset isn't found."
  (let* ((vswhere "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe")
		 (install-path
		  (and (file-exists-p vswhere)
			   (with-temp-buffer
				 (when (zerop (call-process vswhere nil t nil
											 "-latest" "-prerelease" "-products" "*"
											 "-requires" "Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
											 "-property" "installationPath"))
				   (string-trim (buffer-string))))))
		 (vcvarsall (and install-path (not (string-empty-p install-path))
						 (expand-file-name "VC/Auxiliary/Build/vcvarsall.bat" install-path))))
	(when (and vcvarsall (file-exists-p vcvarsall))
	  ;; `cmd /c "call \"...\" && set"' hits cmd's undocumented quote-stripping
	  ;; rules for its trailing command-string argument and mangles the path.
	  ;; Writing the same two lines to a real .bat and running that directly
	  ;; sidesteps it entirely -- Emacs's w32 process code already knows how
	  ;; to invoke .bat/.cmd files via cmd.exe correctly.
	  (let ((script (make-temp-file "mr-vcvars" nil ".bat")))
		(unwind-protect
			(progn
			  (with-temp-file script
				(insert "@echo off\r\n"
						(format "call \"%s\" x64\r\n" vcvarsall)
						"set\r\n"))
			  (with-temp-buffer
				(call-process script nil t nil)
				(goto-char (point-min))
				(let (env)
				  (while (re-search-forward "^\\([A-Za-z_][^=\r\n]*\\)=\\(.*\\)$" nil t)
					(push (cons (match-string 1) (string-trim (match-string 2))) env))
				  env)))
		  (delete-file script))))))

(when (eq system-type 'windows-nt)
  (when-let* ((env (mr/msvc-dev-environment)))
	(dolist (pair env)
	  (setenv (car pair) (cdr pair)))
	(when-let* ((path (getenv "PATH")))
	  (setq exec-path (append (split-string path path-separator t) (list exec-directory))))))
