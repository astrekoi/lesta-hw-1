Выполнил Зинченко А.С. в рамках 2 домашней работы

## Описание задания
Проект демонстрирует автоматизацию Git-операций с использованием Bash-скрипта и GitHub Actions. Реализованы ключевые сценарии:
- Инициализация репозитория
- Управление ветками и тегами
- Имитация ошибок и восстановление
- Интеграция с CI/CD

## Запуск скрипта
```
chmod +x automation.sh
./automation.sh
```

## Структура проекта
```
├── .github/workflows
│   └── ci.yml          # Конфигурация CI/CD
├── src/
│   ├── api/            # Исходный код API
│   ├── ui/             # Пользовательский интерфейс
│   └── models/         # Модели данных
├── tests/
│   ├── unit/           # Модульные тесты
│   └── integration/    # Интеграционные тесты
├── config/             # Конфигурационные файлы
├── automation.sh       # Основной скрипт
└── .gitignore          # Исключаемые файлы
```

## Проделанная работа

Анализ проводиться на основе [лог файла](https://github.com/astrekoi/lesta-hw-1/actions/runs/15127039168)

![log.png](./img/log.png)

### 1. Основные операции Git
- Инициализация репозитория с пользовательскими настройками
  ```shell
  git config --local user.name "Andrey Zinchenko"
  git config --local user.email "astrokoit@gmail.com"

  if [ ! -d .git ]; then
      git init
  ```
- Создание структуры проекта (9 файлов в разных каталогах)
  ```shell
  mkdir -p src/{api,ui,models} tests/{unit,integration} config
  for file in src/api/main.go src/ui/index.html src/models/user.go \
              tests/unit/api_test.go tests/integration/ui_test.py \
              config/dev.yaml config/prod.yaml; do
      [ -f "$file" ] || { touch "$file"; echo "Created $file"; }
  done
  ```
- Настройка .gitignore для исключения временных файлов
  ```shell
  if [ ! -f .gitignore ]; then
      cat > .gitignore <<'EOF'
  logs/
  *.log
  *.tmp
  .env
  EOF
  ```
  ```
  [main d0cadc1] chore: initial project structure [ci skip]
  ```

### 2. Ветвление и слияние
- Создание feature-веток:
  ```
  Switched to a new branch 'feature/api'
  ```
- Слияние с опцией --no-ff:
  ```shell
  git checkout main
  git merge --no-ff -m "chore: merge API features [ci skip]" feature/api
  ```
  ```
  Merge made by the 'ort' strategy.
  ```

### 3. Работа с тегами
- Семантическое версионирование (v1.0.0 → v1.0.1)
- Подпись тегов GPG:
  ```
  Signed tag v1.0.1 created
  ```

### 4. Обработка ошибок
- Имитация ошибки в отдельной ветке:
  ```
  [error-branch 1d8d701] feat: broken changes
  ```
- Откат изменений через revert и reset

### 5. Временные изменения
- Использование git stash:
  ```
  === STASH LIST BEFORE APPLY ===
  stash@{0}: On error-branch: WIP: temporary changes
  ```

## GitHub Actions CI/CD
### Конфигурация
Смотреть файл [ci.yml](/.github/workflows/ci.yml)

### Как проверить
1. Перейдите в репозитории: **Actions** → **CI/CD Pipeline**
2. В логах ищите:
   - Создание тегов
   - Результаты слияния веток
   - Статус операций со stash

### Настройки
#### 1. Секреты (GitHub Secrets)

Для корректной работы автоматизации и CI/CD были добавлены следующие секреты в репозиторий:

- **SSH_PRIVATE_KEY**  
  Приватный SSH-ключ, сгенерированный специально для CI/CD.  
  Используется для аутентификации workflow и получения прав на push/pull в репозиторий через SSH.  
  **Где добавить:**  
  `Settings` → `Secrets and variables` → `Actions` → `New repository secret` →  
  **Name:** `SSH_PRIVATE_KEY`  
  **Value:** содержимое приватного ключа (включая строки `-----BEGIN OPENSSH PRIVATE KEY-----` и `-----END OPENSSH PRIVATE KEY-----`).

- **GPG_PRIVATE_KEY**  
  Приватный GPG-ключ, используемый для подписи тегов в автоматизации.  
  **Где добавить:**  
  `Settings` → `Secrets and variables` → `Actions` → `New repository secret` →  
  **Name:** `GPG_PRIVATE_KEY`  
  **Value:** содержимое приватного GPG-ключа (включая строки `-----BEGIN PGP PRIVATE KEY BLOCK-----` и `-----END PGP PRIVATE KEY BLOCK-----`).

> [!NOTE] 
> **Важно:** Приватные ключи должны быть сгенерированы специально для CI/CD и не использоваться для других целей.

#### 2. Deploy Keys

Для предоставления CI/CD доступa к репозиторию по SSH был добавлен публичный ключ в Deploy Keys:

- **Deploy Key (Public SSH Key)**  
  Публичная часть того же ключа, что и в `SSH_PRIVATE_KEY`.  
  **Где добавить:**  
  `Settings` → `Deploy keys` → `Add deploy key`  
  **Title:** Например, `CI/CD Key`  
  **Key:** содержимое публичного ключа (например, `id_ed25519.pub`)  
  **Access:** Включить опцию `Allow write access` (требуется для push).

#### 3. GPG-ключ для Verified Signatures

Публичный GPG-ключ был добавлен в профиль GitHub для отображения статуса "Verified" у подписанных тегов:

- **Где добавить:**  
  `Settings` → `SSH and GPG keys` → `New GPG key`  
  **Value:** содержимое публичного GPG-ключа (`gpg --armor --export <KEY_ID>`)

#### 4. Как это работает

- **SSH-ключ** позволяет workflow выполнять push/pull в репозиторий от имени CI.
- **GPG-ключ** позволяет подписывать теги, чтобы GitHub отображал статус "Verified".
- **Публичный SSH-ключ** в Deploy Keys обеспечивает безопасный доступ только к этому репозиторию.
- **Публичный GPG-ключ** в профиле GitHub позволяет верифицировать подписи.

> [!NOTE] 
> Без этих настроек автоматизация не корректно пушить изменения и создавать подписанные теги в репозитории!

## Обоснование технологий
1. **Bash** выбран как:
   - Стандартный инструмент для системных скриптов
   - Нативная поддержка Git-команд
   - Кроссплатформенная совместимость

2. **GitHub Actions** обеспечивает:
   - Автоматический запуск при пушах
   - Изолированное выполнение скрипта
   - Артефакты выполнения (логи)

## Результаты выполнения

![image.png](./img/branch.png)

Все операции завершаются выводом:
```
[SUCCESS] All operations completed
```