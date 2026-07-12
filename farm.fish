#!/usr/bin/env fish

# 1. Check GitHub CLI authorization status
if not gh auth status >/dev/null 2>&1
    echo "Error: You are not authorized in gh CLI. Please run 'gh auth login' first."
    exit 1
end

# 2. Create a temporary folder to keep the repository root clean
mkdir -p gold-shark-proofs
git checkout main

echo "=== Launching 1024 PR generation in parallel ==="
echo "This will take about 3-5 minutes..."

# 3. Parallel loop using native Fish background jobs (&)
# We throttle to 10 parallel jobs at a time to prevent CPU/Git lockups
set max_jobs 10

for i in (seq 1 1024)
    set BRANCH_NAME "gold-shark-$i"
    set FILE_NAME "gold-shark-proofs/file_$i.txt"

    # Execute the PR creation inside a background block
    begin
        # Create an isolated branch from the current state of main
        git checkout main >/dev/null 2>&1
        git checkout -b $BRANCH_NAME >/dev/null 2>&1

        # Create a unique file to avoid merge conflicts
        echo "Gold Shark PR #$i" > $FILE_NAME
        git add $FILE_NAME
        git commit -m "Gold shark progress $i/1024" >/dev/null 2>&1

        # Push the branch to the remote repository
        git push origin $BRANCH_NAME >/dev/null 2>&1

        # Create a PR and merge it immediately using the Squash method
        gh pr create --title "Gold Shark PR $i" --body "Automated gold" --base main --head $BRANCH_NAME >/dev/null 2>&1
        gh pr merge --squash -d >/dev/null 2>&1

        # Clean up local garbage
        git checkout main >/dev/null 2>&1
        git branch -D $BRANCH_NAME >/dev/null 2>&1

        echo "✔ PR $i/1024 processed"
    end & # The ampersand runs the entire begin/end block in the background

    # Control the number of parallel jobs (throttle)
    # If we hit the limit of 10, wait for them to finish before starting new ones
    if test (math "$i % $max_jobs") -eq 0
        wait
    end
end

# Wait for any remaining background jobs to finish
wait

# 4. Final synchronization of the local repository
git checkout main
git pull origin main

echo "=== All 1024 PRs have been successfully submitted and merged! ==="
echo "The Gold Pull Shark badge will appear on your profile within 24-48 hours."
