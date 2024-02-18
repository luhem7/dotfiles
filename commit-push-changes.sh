#! /bin/sh

if [ -d .git ] || git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git status
    git add .
    git commit -a --allow-empty-message -m ''
    git push
else
    echo "You are not in a Git repository."
fi

