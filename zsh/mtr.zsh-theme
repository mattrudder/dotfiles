# Matt Rudder's Prompt Theme
# based on Baylor Rae's Prompt Theme
# which was based on wunjo prompt theme and modified for oh-my-zsh

# shows me all files and folders when I change directories
#cd() { builtin cd "$@"; ls }

# uses ~ instead of /Users/rudder/
pwd() { print -D $PWD }

# I substituted my own so the commit times were live
my_git_info() {
  # Make sure we're in a git repo
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  
  # Get the times
  now=$(date +%s)
  last_commit=$(git log --pretty=format:'%at' -1)
  seconds_since_last_commit=$((now-last_commit))
  minutes_since_last_commit=$((seconds_since_last_commit/60))
  
  # Colorize the times
    # green = < 10min
    # yellow = < 60min
    # red = > 60min
    # Used 'spectrum_ls' command to get new colors.
  if [ "$minutes_since_last_commit" -gt 60 ]; then
    colored_time="%{$FG[009]%}"
  elif [ "$minutes_since_last_commit" -gt 30 ]; then
    colored_time="%{$FG[011]%}"
  else
    colored_time="%{$FG[010]%}"
  fi

  # Add the minutes and reset color
  colored_time+="%{$minutes_since_last_commit%}m"
  colored_time+="%{$reset_color%}"
  
  # Add the colored git branch
  colored_branch="%{$FG[117]%}${ref#refs/heads/}%{$reset_color%}"
  
  # Add it to the prompt
  echo " ($colored_branch|$colored_time)"
}

PROMPT='%{$FG[046]%}%m%{$reset_color%}:${PWD/#$HOME/~}$(my_git_info) %{$FG[011]%}$%{$reset_color%} '

