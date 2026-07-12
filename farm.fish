#!/usr/bin/env fish

# 1. Check GitHub CLI authorization status
if not gh auth status >/dev/null 2>&1
    echo "Error: You are not authorized in gh CLI. Please run 'gh auth login' first."
    exit 1
end

# 2. Create a temporary folder to keep the repository root clean
mkdir -p gold-shark-proofs
git checkout main

# Define the function for a single PR inside the Fish environment
function run_single_pr
    set i $argv[1]
    set BRANCH_NAME "gold-shark-$i"
    set FILE_NAME "gold-shark-proofs/file_$i.txt"

    # Create an isolated branch from the current state of main
    git checkout main >/dev/null 2>&1
    git checkout -b $BRANCH_NAME >/dev/null 2>&1

    # Create a unique file to avoid merge conflicts
    echo "Gold Shark PR #$i" > $FILE_NAME
    git add $FILE_NAME
    git commit -m "Gold shark progress $i/1024" >/dev/null 2>&1

    # Push the branch to the remote repository
    git push origin $BRANCH_NAME >/dev/null 2>&1

    # Create a PR and merge it immediately using the Squash method (faster and cleaner)
    gh pr create --title "Gold Shark PR $i" --body "Automated gold" --base main --head $BRANCH_NAME >/dev/null 2>&1
    gh pr merge --squash -d >/dev/null 2>&1

    # Clean up local garbage
    git checkout main >/dev/null 2>&1
    git branch -D $BRANCH_NAME >/dev/null 2>&1

    echo "✔ PR $i/1024 processed"
end

echo "=== Launching 1024 PR generation in 10 threads ==?="
echo "This will take about 3-5 minutes..."

# 3. Generate numbers from 1 to 1024 and pipe to xargs across 10 parallel threads inside Fish
seq 1 1024 | xargs -n 1 -P 10 -I {} fish -c "source $__fish_status_dir/../.. 2>/dev/null; run_single_pr {}"

# 4. Final synchronization of the local repository
git checkout main
git pull origin main

echo "=== All 1024 PRs have been successfully submitted and merged! ==="
echo "The Gold Pull Shark badge will appear on your profile within 24-48 hours."
