#! /bin/zsh


dotfiles=(".wezterm.lua" ".zshrc")
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
        for file in "${files[@]}"; do
            cp ~/"$file" .
        done
        git status
        ;;
esac