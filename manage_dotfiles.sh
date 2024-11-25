#! /bin/zsh

dotfiles=(".wezterm.lua" ".zshrc" ".zsh_linux.zsh" ".zsh_macos.zsh" "commit-push-changes.sh")
help_msg='Usage: ./manage_dotfiles.sh [deploy|commit]'

# Function to get VSCode settings path based on OS
get_vscode_settings_path() {
    case "$(uname)" in
        "Darwin")
            echo "$HOME/Library/Application Support/Code/User/settings.json"
            ;;
        "Linux")
            echo "$HOME/.config/Code/User/settings.json"
            ;;
        *)
            echo "Unsupported operating system"
            exit 1
            ;;
    esac
}

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

# Get the appropriate VSCode settings path
vscode_settings_path=$(get_vscode_settings_path)

# If both conditions are met, perform actions based on the argument
case "$1" in
    deploy)
        echo "Deploying..."
        cp "${dotfiles[@]}" ~/
        # Create VSCode settings directory if it doesn't exist
        mkdir -p "$(dirname "$vscode_settings_path")"
        # Copy VSCode settings
        cp "./vscode/settings.json" "$vscode_settings_path"
        echo "Deployed VSCode settings to $vscode_settings_path"
        source ~/.zshrc
        ;;
    commit)
        echo "Committing..."
        for file in "${dotfiles[@]}"; do
            echo "Copying file ${file}"
            cp ~/"$file" .
        done
        # Ensure vscode directory exists
        mkdir -p ./vscode
        # Copy VSCode settings back to repo
        if [ -f "$vscode_settings_path" ]; then
            cp "$vscode_settings_path" "./vscode/settings.json"
            echo "Copied VSCode settings from $vscode_settings_path"
        else
            echo "Warning: VSCode settings file not found at $vscode_settings_path"
        fi
        git status
        ;;
esac