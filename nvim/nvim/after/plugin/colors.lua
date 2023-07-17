function SetColorScheme(color)
	color = color or "marmot"
	vim.o.termguicolors = true
	vim.cmd.colorscheme(color)
end

SetColorScheme()
