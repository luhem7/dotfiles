#! /bin/zsh


dotfiles=(".wezterm.lua" ".zshrc" ".zsh_linux.zsh" ".zsh_macos.zsh" "commit-push-changes.sh")
help_msg='Usage: ./manage_dotfiles.sh [deploy|commit]'

# Check if the number of arguments is exactly 1
if [ "$#" -ne 1 ]; then
    echo $help_msg
    exit 1
fi

# Check if the argument is either "deploy" or "commit"
if [[ "$1" != "deploy" && "$1" != "commit" ]]; then
    echo $help_msg
    exit 1
fi

# If both conditions are met, perform actions based on the argument
case "$1" in
    deploy)
        echo "Deploying..."
        cp "${dotfiles[@]}" ~/
        source ~/.zshrc
        ;;
    commit)
        echo "Committing..."
        for file in "${dotfiles[@]}"; do
            echo "Copying file ${file}"
            cp ~/"$file" .
        done
        git status
        ;;
esac