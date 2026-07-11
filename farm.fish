for i in (seq 1 128)
    set BRANCH_NAME "shark-branch-$i"
    git checkout -b $BRANCH_NAME
    
    echo "Shark level $i" >> README.md
    git add README.md
    git commit -m "Fix for shark achievement part $i"
    
    git push origin $BRANCH_NAME
    
    gh pr create --title "Shark PR $i" --body "Automated" --base main --head $BRANCH_NAME
    gh pr merge --merge -d
    
    git checkout main
    git pull origin main
    
    echo "=== Отправлен PR: $i / 128 ==="
end
