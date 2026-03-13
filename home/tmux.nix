{ config, pkgs, ... }:

let
  scriptsDir = "${config.home.homeDirectory}/nix/scripts";
  tmuxClipboardCommand = pkgs.writeShellScript "tmux-clipboard" ''
    exec "${scriptsDir}/yank"
  '';
in
{
  programs.tmux = {
    enable = true;

    # Plugins via Nix (no TPM)
    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-colors "custom_bg #AFCCAF"
          set -g @dracula-show-flags true
          set -g @dracula-plugins "cpu-usage ram-usage"
          set -g @dracula-cpu-usage-colors "custom_bg"
          set -g @dracula-ram-usage-colors "custom_bg"
        '';
      }
    ];

    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -as terminal-features ',*:cstyle'
      set -ag terminal-overrides ",xterm-256color:RGB,*:Ss=\\E[%p1%d q:Se=\\E[2 q,*:Smulx=\\E[4::%p1%dm,*:Setulc=\\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m"

      # Better split shortcuts
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Start windows/panes at 1
      set -g base-index 1
      setw -g pane-base-index 1

      # Prefix
      unbind C-b
      set -g prefix M-a
      bind M-a send-prefix

      bind s choose-tree -Zs -K '#{e|+|:#{line},1}'
      bind -n M-t new-window
      bind -n M-T new-session
      bind -n M-s choose-tree -Zs -K '#{e|+|:#{line},1}'

      set-option -g status-position top

      setw -g mode-keys vi
      bind -n M-w copy-mode

      bind v copy-mode

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${tmuxClipboardCommand}"

      bind-key -T copy-mode-vi C-u send-keys -X halfpage-up
      bind-key -T copy-mode-vi C-d send-keys -X halfpage-down

      bind-key -T copy-mode-vi Escape if-shell -F '#{selection_present}' \
        'send-keys -X clear-selection' \
        'send-keys -X cancel'

      bind-key -T copy-mode-vi 'V' send-keys -X select-line
      bind-key -T copy-mode-vi 'C-v' \
        if-shell -F '#{selection_present}' \
        'send-keys -X rectangle-toggle' \
        'send-keys -X begin-selection; send-keys -X rectangle-toggle'

      bind-key -T copy-mode-vi '§' send-keys -X back-to-indentation
      bind-key -T copy-mode-vi ';' send-keys -X jump-reverse
      bind-key -T copy-mode-vi ',' send-keys -X jump-again

      bind-key -T copy-mode-vi C-Left  send-keys -X previous-word
      bind-key -T copy-mode-vi C-Right send-keys -X next-word-end
      bind-key -T copy-mode-vi C-Up    send-keys -X -N 3 cursor-up
      bind-key -T copy-mode-vi C-Down  send-keys -X -N 3 cursor-down
      bind-key -T copy-mode-vi S-Up    send-keys -X -N 10 cursor-up
      bind-key -T copy-mode-vi S-Down  send-keys -X -N 10 cursor-down

      bind-key -n M-1 select-window -t 1
      bind-key -n M-2 select-window -t 2
      bind-key -n M-3 select-window -t 3
      bind-key -n M-4 select-window -t 4
      bind-key -n M-5 select-window -t 5
      bind-key -n M-6 select-window -t 6
      bind-key -n M-7 select-window -t 7
      bind-key -n M-8 select-window -t 8
      bind-key -n M-9 select-window -t 9
      bind-key -n M-h switch-client -p
      bind-key -n M-l switch-client -n

      set -g window-status-separator ""
      set -g status-bg "#009393"
      setw -g mode-style "bg=#C4FFFF,fg=#000000"
      set -g window-status-current-style "bg=#004f4f,fg=#ffffff"
      set -g window-status-style "bg=#007f7f,fg=#cccccc"
      set -g window-status-current-format " #I:#W "
      set -g window-status-format " #I:#W "

      set -g status-left " #S "
    '';
  };
}
