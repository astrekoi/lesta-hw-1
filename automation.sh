#!/bin/bash
set -eo pipefail

# Конфигурация пользователя
git config --local user.name "Andrey Zinchenko"
git config --local user.email "astrokoit@gmail.com"

[ -d .git ] || { git init; echo "Git repository initialized"; }

# Структура проекта
mkdir -p src/{api,ui,models} tests/{unit,integration} config
for file in src/api/main.go src/ui/index.html src/models/user.go \
            tests/unit/api_test.go tests/integration/ui_test.py \
            config/{dev.yaml,prod.yaml}; do
    [ -f "$file" ] || { touch "$file"; echo "Created $file"; }
done

# .gitignore
[ -f .gitignore ] || {
    cat > .gitignore <<'EOF'
logs/
*.log
*.tmp
.env
EOF
    echo ".gitignore created"
}

# Фиксация базовой структуры
git add . && git commit -m "chore: initial project structure [ci skip]" --allow-empty

# Очистка веток
for branch in feature/api feature/ui error-branch; do
    git branch -D "$branch" 2>/dev/null || true
done

# Основной workflow
git checkout -B main

# Разработка API
git checkout -b feature/api
echo "// API v1" > src/api/main.go
git add . && git commit -m "feat: initialize API module"
echo "// Add routes" >> src/api/main.go
git add . && git commit -m "feat: add base routes"

# Разработка UI
git checkout main
git checkout -b feature/ui
echo "<!-- Main layout -->" > src/ui/index.html
git add . && git commit -m "feat: create base UI"
echo "<!-- Navigation -->" >> src/ui/index.html
git add . && git commit -m "feat: implement navigation"

# Слияние API
git checkout main
git merge --no-ff -m "chore: merge API features [ci skip]" feature/api

# Ребейз UI
git checkout feature/ui
git rebase main || {
    git mergetool -y
    git rebase --continue
}

# Тегирование с автоинкрементом
git checkout main
LAST_TAG=$(git describe --abbrev=0 --tags 2>/dev/null || echo "v0.0.0")
IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
NEW_TAG="v$MAJOR.$MINOR.$((PATCH+1))"
git tag -s $NEW_TAG -m "Release $NEW_TAG"

# Имитация ошибки
git checkout -b error-branch
echo "BUG" >> src/api/main.go
git add . && git commit -m "feat: broken changes"
git revert HEAD --no-edit
git reset HEAD~1 --hard

# Работа с stash
echo "temp" > tmp.file
git stash push -m "WIP: temporary changes"
git stash apply

# Публикация
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:astrekoi/lesta-hw-1.git
git push -u origin --all --force
git push --tags --force

echo "[SUCCESS] All operations completed"