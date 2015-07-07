function git_tree -d "Default flags for tree"
	set ignored_files "svn|.git"
	set gitignored_files (git check-ignore *)
	if test $status -eq 0
		for d in $gitignored_files;
			set ignored_files "$ignored_files|$d"
		end
	end

	command tree -Ca -I "$ignored_files" --matchdirs --prune --dirsfirst $argv
end
