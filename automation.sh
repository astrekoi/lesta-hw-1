#!/bin/bash
set -eo pipefail

# Инициализация репозитория с проверкой существования
if [ ! -d .git ]; then
    git init
    echo "Initialized new Git repository"
fi

git config --local user.name "Andrey Zinchenko"
git config --local user.email "astrokoit@gmail.com"

# Создание базовой структуры проекта
mkdir -p src/{api,ui,models} tests/{unit,integration} config logs
touch src/api/main.go src/ui/index.html src/models/user.go \
     tests/unit/api_test.go tests/integration/ui_test.py \
     config/{dev.yaml,prod.yaml} logs/app.log

# Генерация .gitignore для исключения временных файлов
if [ ! -f .gitignore ]; then
    cat > .gitignore <<EOF
logs/
*.log
*.tmp
.env
EOF
fi

# Подготовка веток разработки
git checkout -B main &>/dev/null
git branch -D feature/api feature/ui &>/dev/null || true
git checkout -b feature/api
git checkout main
git checkout -b feature/ui

commit_changes() {
    branch=$1
    file=$2
    message=$3
    git checkout $branch
    echo "$message" >> $file
    git add $file
    git commit -m "$message"
}

# Разработка API
commit_changes feature/api src/api/main.go "Initialize API module"
commit_changes feature/api src/api/main.go "Add base routes"

# Разработка UI
commit_changes feature/ui src/ui/index.html "Create basic layout"
commit_changes feature/ui src/ui/index.html "Implement navigation"

# Слияние изменений с сохранением истории
git checkout main
git merge --no-ff -m "Merge feature/api branch" feature/api

# Обновление UI ветки через ребейз
git checkout feature/ui
git rebase main || {
    echo "Resolving merge conflicts..."
    git mergetool
    git rebase --continue
}

# Создание версионного тега
git checkout main
git tag -s v1.0.0 -m "Release version 1.0.0"

# Демонстрация отката изменений
git checkout -b error-branch
echo "Broken changes" >> src/api/main.go
git add . && git commit -m "Invalid commit"
git revert HEAD --no-edit
git reset HEAD~1 --hard

# Работа с временными изменениями
echo "Temporary changes" >> temp.file
git stash push -m "WIP: Experimental changes"
git stash apply

# Публикация изменений
git remote remove origin &>/dev/null || true
git remote add origin git@github.com:astrekoi/lesta-hw-1.git
git push -u origin --all --force
git push --tags --force
