#!/bin/bash
set -eo pipefail

# Конфигурация пользователя
git config --local user.name "Andrey Zinchenko"
git config --local user.email "astrokoit@gmail.com"

[ -d .git ] || { git init; echo "Git repository initialized"; }

# Создание структуры проекта
mkdir -p src/{api,ui,models} tests/{unit,integration} config
for file in src/api/main.go src/ui/index.html src/models/user.go \
            tests/unit/api_test.go tests/integration/ui_test.py \
            config/{dev.yaml,prod.yaml}; do
    [ -f "$file" ] || { touch "$file"; echo "Created $file"; }
done

# Настройка .gitignore
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

# Полная очистка временных веток (локальных и удаленных)
for branch in feature/api feature/ui error-branch; do
    # Удаление локальной ветки
    git branch -D "$branch" 2>/dev/null || true
    
    # Удаление ветки на удаленном репозитории
    git push origin --delete "$branch" 2>/dev/null || true
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

# Слияние изменений
git checkout main
git merge --no-ff -m "chore: merge API features [ci skip]" feature/api

# Ребейз UI ветки
git checkout feature/ui
git rebase main || {
    git mergetool -y
    git rebase --continue
}

# Тегирование с автоинкрементом и GPG
git checkout main

# Определение последнего тега начиная с 1.0.0
LAST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)

# Если тегов нет - начинаем с 1.0.0
if [ -z "$LAST_TAG" ]; then
    NEW_TAG="v1.0.0"
else
    # Парсим компоненты версии
    IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
    NEW_TAG="v$MAJOR.$MINOR.$((PATCH+1))"
fi

# Создание тега
if git tag -s "$NEW_TAG" -m "Release $NEW_TAG" 2>/dev/null; then
    echo "Signed tag $NEW_TAG created"
else
    git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
    echo "Fallback to unsigned tag $NEW_TAG"
fi

# Имитация ошибки (с гарантированным созданием ветки)
git checkout -B error-branch main
echo "BUG" >> src/api/main.go
git add . && git commit -m "feat: broken changes"
git revert HEAD --no-edit
git reset HEAD~1 --hard

# Работа с stash
echo "temp" > tmp.file
git stash push -u -m "WIP: temporary changes"
echo "=== STASH LIST BEFORE APPLY ==="
git stash list
git stash apply
echo "=== STASH LIST AFTER APPLY ==="
git stash list

# Публикация
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:astrekoi/lesta-hw-1.git
git push -u origin main
for branch in feature/api feature/ui error-branch; do
  git push origin "$branch" --force
done
git push --tags --force

echo "[SUCCESS] All operations completed"
