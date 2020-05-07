function tree -d "Default flags for tree"
	set ignored_files "svn|.git"
	command tree -Ca -I "$ignored_files" --matchdirs --prune --dirsfirst $argv
end
