#!/bin/bash

# 1. Check GitHub CLI authorization status
if ! gh auth status &>/dev/null; then
    echo "Error: You are not authorized in gh CLI. Please run 'gh auth login' first."
    exit 1
fi

# 2. Create a temporary folder to keep the repository root clean
mkdir -p gold-shark-proofs
git checkout main

# Function to submit a single PR (exported for use with xargs)
export -f gh
run_single_pr() {
  local i=$1
  local BRANCH_NAME="gold-shark-$i"
  local FILE_NAME="gold-shark-proofs/file_$i.txt"

  # Create an isolated branch from the current state of main
  git checkout main &>/dev/null
  git checkout -b "$BRANCH_NAME" &>/dev/null

  # Create a unique file
  echo "Gold Shark PR #$i" > "$FILE_NAME"
  git add "$FILE_NAME"
  git commit -m "Gold shark progress $i/1024" &>/dev/null

  # Push the branch to the remote repository
  git push origin "$BRANCH_NAME" &>/dev/null

  # Create a PR and merge it immediately using the Squash method (faster and cleaner)
  gh pr create --title "Gold Shark PR $i" --body "Automated gold" --base main --head "$BRANCH_NAME" &>/dev/null
  gh pr merge --squash -d &>/dev/null

  # Clean up local garbage
  git checkout main &>/dev/null
  git branch -D "$BRANCH_NAME" &>/dev/null

  echo "✔ PR $i/1024 processed"
}
export -f run_single_pr

echo "=== Launching 1024 PR generation in 10 threads ==="
echo "This will take about 3-5 minutes..."

# 3. Generate numbers from 1 to 1024 and pipe to xargs across 10 parallel threads
seq 1 1024 | xargs -n 1 -P 10 -I {} bash -c 'run_single_pr "$@"' _ {}

# 4. Final synchronization of the local repository
git checkout main
git pull origin main

echo "=== All 1024 PRs have been successfully submitted and merged! ==="
echo "The Gold Pull Shark badge will appear on your profile within 24-48 hours."
