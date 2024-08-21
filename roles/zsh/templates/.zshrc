export ZSH="{{ ansible_user_dir }}/.oh-my-zsh"
plugins=(git docker tmux zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf fzf-tab helm kubectl aws)
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
source $ZSH/oh-my-zsh.sh
export GPG_TTY=$(tty)
export GNUPGHOME=$HOME/.gnupg
eval "$(starship init zsh)"
