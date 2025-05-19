#!/bin/bash
set -eo pipefail

# Основные настройки пользователя
git config --local user.name "Andrey Zinchenko"
git config --local user.email "astrokoit@gmail.com"

[ -d .git ] || { git init; echo "Git repository initialized"; }

# Создание структуры проекта
mkdir -p src/{api,ui,models} tests/{unit,integration} config
touch src/api/main.go src/ui/index.html src/models/user.go \
     tests/unit/api_test.go tests/integration/ui_test.py \
     config/{dev.yaml,prod.yaml}

# Настройка .gitignore (без логирования)
[ -f .gitignore ] || cat > .gitignore <<'EOF'
logs/
*.log
*.tmp
.env
EOF

# Очистка временных веток
git branch -D feature/api feature/ui error-branch 2>/dev/null || true

# Инициализация основной ветки
git checkout -B main

# Создание feature-веток
git checkout -b feature/api
echo "// API entrypoint" > src/api/main.go
git add . && git commit -m "Initialize API module"

git checkout main
git checkout -b feature/ui
echo "<!-- Base layout -->" > src/ui/index.html
git add . && git commit -m "Create UI structure"

# Слияние изменений
git checkout main
git merge --no-ff -m "Integrate API features" feature/api

# Ребейз UI ветки
git checkout feature/ui
git rebase main || {
    git mergetool
    git rebase --continue
}

# Создание релизного тега
git tag -a v1.0.0 -m "Initial production release"

# Публикация изменений
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:astrekoi/lesta-hw-1.git
git push -u origin --all --force
git push --tags --force
