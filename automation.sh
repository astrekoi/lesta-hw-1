#!/bin/bash
set -eo pipefail

# Конфигурация пользователя
git config --local user.name "Andrey Zinchenko"
git config --local user.email "astrokoit@gmail.com"

# Инициализация репозитория
[ -d .git ] || { git init; echo "Git repository initialized"; }

# Создание структуры проекта с проверкой директорий
mkdir -p src/{api,ui,models} tests/{unit,integration} config
for file in src/api/main.go src/ui/index.html src/models/user.go \
            tests/unit/api_test.go tests/integration/ui_test.py \
            config/{dev.yaml,prod.yaml}; do
    [ -f "$file" ] || touch "$file"
done

# Идемпотентное создание .gitignore
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
git add . && git commit -m "Initialize project structure" --allow-empty || true

# Очистка временных веток
for branch in feature/api feature/ui error-branch; do
    git branch -D "$branch" 2>/dev/null || true
done

# Основной workflow
git checkout -B main

# Разработка API
git checkout -b feature/api
echo "// API entrypoint" > src/api/main.go
git add src/api/main.go
git commit -m "Initialize API module"

echo "// Base routes" >> src/api/main.go
git add src/api/main.go
git commit -m "Add base routes"

# Разработка UI
git checkout main
git checkout -b feature/ui
mkdir -p src/ui  # Гарантированное создание директории
echo "<!-- Base layout -->" > src/ui/index.html
git add src/ui/index.html
git commit -m "Create UI structure"

echo "<!-- Navigation -->" >> src/ui/index.html
git add src/ui/index.html
git commit -m "Implement navigation"

# Слияние изменений
git checkout main
git merge --no-ff -m "Integrate API features" feature/api

# Обновление UI ветки
git checkout feature/ui
git rebase main || {
    git mergetool
    git rebase --continue
}

# Тегирование релиза
git checkout main
git tag -a v1.0.0 -m "Initial release"

# Публикация
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:astrekoi/lesta-hw-1.git
git push -u origin --all --force
git push --tags --force

echo "All operations completed successfully"
