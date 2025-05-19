#!/bin/bash
set -eo pipefail

# Конфиг пользователя
git config --local user.name "Andrey Zinchenko"
git config --local user.email "astrokoit@gmail.com"

# Инициализация репозитория
if [ ! -d .git ]; then
    git init
    echo "Git repository initialized successfully"
fi

# Базовая структура
mkdir -p src/{api,ui,models} tests/{unit,integration} config logs
touch src/api/main.go src/ui/index.html src/models/user.go \
     tests/unit/api_test.go tests/integration/ui_test.py \
     config/{dev.yaml,prod.yaml} logs/app.log

# .gitignore
if [ ! -f .gitignore ]; then
    cat > .gitignore <<EOF
logs/
*.log
*.tmp
.env
EOF
    echo "Created .gitignore file"
fi

# Очистка ненужных веток
for branch in feature/api feature/ui error-branch; do
    git branch -D $branch 2>/dev/null || true
done

# Создание и подготовка веток
git checkout -B main

git checkout -b feature/api
echo "// API entry" > src/api/main.go
git add src/api/main.go
git commit -m "Initialize API module"

echo "// Base routes" >> src/api/main.go
git add src/api/main.go
git commit -m "Add base routes"

git checkout main
git checkout -b feature/ui
echo "<!-- UI layout -->" > src/ui/index.html
git add src/ui/index.html
git commit -m "Create basic layout"

echo "<!-- Navigation -->" >> src/ui/index.html
git add src/ui/index.html
git commit -m "Implement navigation"

# Слияние API в main
git checkout main
git merge --no-ff -m "Merge feature/api branch" feature/api

# Перед rebase убеждаемся, что рабочее дерево чистое
git checkout feature/ui
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Uncommitted changes detected, stashing before rebase..."
    git stash push -m "Auto-stash before rebase"
fi

git rebase main || {
    echo "Resolving merge conflicts..."
    git mergetool || true
    git rebase --continue || true
}

# Восстановление stash если был
if git stash list | grep "Auto-stash before rebase" >/dev/null; then
    echo "Restoring stashed changes..."
    git stash pop
fi

# Тегирование
git checkout main
git tag -s v1.0.0 -m "Release version 1.0.0" || git tag -f -s v1.0.0 -m "Release version 1.0.0"
echo "Created signed tag v1.0.0"

# Демонстрация отката
git checkout -b error-branch
echo "Broken changes" >> src/api/main.go
git add src/api/main.go
git commit -m "Invalid commit"
git revert HEAD --no-edit
git reset --hard HEAD~1
echo "Error simulation and recovery completed"

# Работа со stash
echo "Temporary changes" >> temp.file
git add temp.file
git stash push -m "WIP: Experimental changes"
git stash pop || true
echo "Stash operations completed"

# Публикация
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:astrekoi/lesta-hw-1.git
git push -u origin --all --force
git push --tags --force

echo "All operations completed successfully"
