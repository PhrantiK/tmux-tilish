#!/bin/bash

# shellcheck disable=SC2016
# shellcheck disable=SC2086
# shellcheck disable=SC3057

bind='bind -n'
mod='M-'
layout_keys='sSvVtz'
rename="n"
default="tiled"
refresh="r"
new_pane="enter"
closew='Q'
closec='E'
reload='C'
fzf='C'

bind_switch() {
	# Bind keys to switch between workspaces.
	tmux $bind "$1" \
		if-shell "tmux select-window -t :$2" "" "new-window -t :$2"
}

# Switch to workspace via Alt + #.
bind_switch "${mod}1" 1
bind_switch "${mod}2" 2
bind_switch "${mod}3" 3
bind_switch "${mod}4" 4
bind_switch "${mod}5" 5
bind_switch "${mod}6" 6
bind_switch "${mod}7" 7
bind_switch "${mod}8" 8
bind_switch "${mod}9" 9

bind_move() {
	# Bind keys to move panes between workspaces.
		tmux $bind "$1" \
			if-shell "tmux join-pane -t :$2" \
			"" \
			"new-window -dt :$2; join-pane -t :$2; select-pane -t top-left; kill-pane" \\\; select-layout \\\; select-layout -E
}

# Move pane to workspace via Alt + Shift + #.
bind_move "${mod}!" 1
bind_move "${mod}@" 2
bind_move "${mod}#" 3
bind_move "${mod}$" 4
bind_move "${mod}%" 5
bind_move "${mod}^" 6
bind_move "${mod}&" 7
bind_move "${mod}*" 8
bind_move "${mod}(" 9
bind_move "${mod})" 10

char_at() { echo "${1:$(($2-1)):1}"; }

# Bind keys to switch or refresh layouts.
bind_layout() {
	if [ "$2" = "zoom" ]; then
		tmux $bind "$1" \
			resize-pane -Z
	else
			tmux $bind "$1" \
				select-layout "$2" \\\; select-layout -E
	fi
}

bind_layout "${mod}$(char_at $layout_keys 1)" 'main-horizontal'
bind_layout "${mod}$(char_at $layout_keys 2)" 'even-vertical'
bind_layout "${mod}$(char_at $layout_keys 3)" 'main-vertical'
bind_layout "${mod}$(char_at $layout_keys 4)" 'even-horizontal'
bind_layout "${mod}$(char_at $layout_keys 5)" 'tiled'
bind_layout "${mod}$(char_at $layout_keys 6)" 'zoom'

# Refresh the current layout (e.g. after deleting a pane).
tmux $bind "${mod}${refresh}" select-layout -E

# Open a terminal with Alt + enter
tmux $bind "${mod}${new_pane}" \
  run-shell 'cwd="`tmux display -p \"#{pane_current_path}\"`"; tmux select-pane -t "bottom-right"; tmux split-pane -c "$cwd"'

# Name a window with Alt + n
tmux $bind "${mod}${rename}" \
  command-prompt -p 'Window name:' 'rename-window "%%"'

# Close a window with Alt + Shift + q.
tmux $bind "${mod}${closew}" \
  if-shell \
  '[ "$(tmux display-message -p "#{window_panes}")" -gt 1 ]' \
  'kill-pane; select-layout; select-layout -E' \
  'kill-pane'
# Close a connection with Alt + Shift + e.
tmux $bind "${mod}${closec}" \
	confirm-before -p "Detach from #H:#S? (y/n)" detach-client

# Reload configuration with Alt + Shift + c.
tmux $bind "${mod}${reload}" \
	source-file ~/.config/tmux/tmux.conf \\\; display "Reloaded config"

# Autorefresh layout after deleting a pane.
tmux set-hook -g after-split-window "select-layout; select-layout -E"
tmux set-hook -g pane-exited "select-layout; select-layout -E"

# Autoselect layout after creating new window.
if [ -n "${default:-}" ]; then
  tmux set-hook -g window-linked "select-layout \"$default\"; select-layout -E"
  tmux select-layout "$default"
  tmux select-layout -E
fi

# Integrate with `fzf` to approximate `dmenu`
tmux $bind "${mod}${fzf}" \
  select-pane -t '{bottom-right}' \\\; split-pane 'sh -c "exec \$(echo \"\$PATH\" | tr \":\" \"\n\" | xargs -I{} -- find {} -maxdepth 1 -mindepth 1 -executable 2>/dev/null | sort -u | fzf)"'
