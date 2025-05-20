#!/bin/bash
set -eo pipefail
trap 'echo "[ERROR] Script failed at line $LINENO"; exit 1' ERR

echo "== [START] Git automation script =="

echo "== [CONFIG] Setting user name and email =="
git config --local user.name "Andrey Zinchenko"
git config --local user.email "astrokoit@gmail.com"

if [ ! -d .git ]; then
    git init
    echo "== [INIT] Git repository initialized =="
else
    echo "== [INIT] Git repository already exists =="
fi

echo "== [STRUCTURE] Creating project directories and files =="
mkdir -p src/{api,ui,models} tests/{unit,integration} config
for file in src/api/main.go src/ui/index.html src/models/user.go \
            tests/unit/api_test.go tests/integration/ui_test.py \
            config/dev.yaml config/prod.yaml; do
    [ -f "$file" ] || { touch "$file"; echo "Created $file"; }
done

if [ ! -f .gitignore ]; then
    cat > .gitignore <<'EOF'
logs/
*.log
*.tmp
.env
EOF
    echo ".gitignore created"
else
    echo ".gitignore already exists"
fi

echo "== [COMMIT] Committing initial project structure =="
git add . && git commit -m "chore: initial project structure [ci skip]" --allow-empty

echo "== [CLEANUP] Deleting old branches (local and remote) =="
for branch in feature/api feature/ui error-branch; do
    git branch -D "$branch" 2>/dev/null || true
    git push origin --delete "$branch" 2>/dev/null || true
done

echo "== [BRANCH] Switching to main =="
git checkout -B main

echo "== [API] Creating feature/api branch and commits =="
git checkout -b feature/api
echo "// API v1" > src/api/main.go
git add . && git commit -m "feat: initialize API module"
echo "// Add routes" >> src/api/main.go
git add . && git commit -m "feat: add base routes"

echo "== [UI] Creating feature/ui branch and commits =="
git checkout main
git checkout -b feature/ui
echo "<!-- Main layout -->" > src/ui/index.html
git add . && git commit -m "feat: create base UI"
echo "<!-- Navigation -->" >> src/ui/index.html
git add . && git commit -m "feat: implement navigation"

echo "== [MERGE] Merging feature/api into main =="
git checkout main
git merge --no-ff -m "chore: merge API features [ci skip]" feature/api

echo "== [REBASE] Rebasing feature/ui onto main =="
git checkout feature/ui
git rebase main || {
    echo "[CONFLICT] Launching mergetool"
    git mergetool -y
    git rebase --continue
}

echo "== [TAGGING] Checking and creating new tag =="
git checkout main
LAST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 || true)
if [ -z "$LAST_TAG" ]; then
    NEW_TAG="v1.0.0"
    echo "No tags found, creating $NEW_TAG"
else
    IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
    NEW_TAG="v$MAJOR.$MINOR.$((PATCH+1))"
    echo "Last tag: $LAST_TAG, new tag: $NEW_TAG"
fi

if git tag -s "$NEW_TAG" -m "Release $NEW_TAG" 2>/dev/null; then
    echo "Signed tag $NEW_TAG created"
else
    git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
    echo "Fallback to unsigned tag $NEW_TAG"
fi

echo "== [ERROR-BRANCH] Simulating error and recovery =="
git checkout -B error-branch main
echo "BUG" >> src/api/main.go
git add . && git commit -m "feat: broken changes"
git revert HEAD --no-edit
git reset HEAD~1 --hard

echo "== [STASH] Creating and applying stash =="
echo "temp" > tmp.file
git stash push -u -m "WIP: temporary changes"
echo "=== STASH LIST BEFORE APPLY ==="
git stash list
git stash apply
echo "=== STASH LIST AFTER APPLY ==="
git stash list

echo "== [PUSH] Publishing all branches and tags =="
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:astrekoi/lesta-hw-1.git
git push -u origin main
for branch in feature/api feature/ui error-branch; do
  git push origin "$branch" --force
done
git push --tags --force

echo "[SUCCESS] All operations completed"
