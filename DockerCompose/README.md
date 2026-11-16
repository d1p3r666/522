# Лабораторная работа: Docker Compose

## Цель

Научиться описывать, запускать и проверять многоконтейнерное приложение: веб-интерфейс заметок на Python и базу PostgreSQL с постоянным хранением данных.

Работа выполнена по [материалу преподавателя](https://github.com/rurewa/imfua/blob/main/content/Docker/DockerCompose/DockerCompose.md). В нём приведены альтернативные учебные примеры, а не требование одновременно разворачивать WordPress, кэш и несколько приложений. Здесь выбран минимальный вариант «веб-приложение + БД», использующий основные директивы и рекомендации материала.

## Что такое Compose

Docker Compose управляет несколькими контейнерами как единым проектом: читает YAML, собирает образ приложения, создаёт сеть и volume, запускает сервисы. Используется современная команда `docker compose` и файл `compose.yaml` без устаревшего поля `version` (синтаксис Compose V2; более новые версии плагина также подходят).

## Структура

```text
DockerCompose/
├── compose.yaml
├── .env.example
├── .gitignore
├── README.md
└── app/
    ├── Dockerfile
    ├── .dockerignore
    ├── requirements.txt
    ├── app.py
    └── templates/
        └── index.html
```

| Файл или сервис | Назначение |
| --- | --- |
| `compose.yaml` | Сервисы, порты, переменные, зависимости, healthcheck, сеть и volume |
| `web` | Flask под Gunicorn, доступен на `http://localhost:8080`; добавляет и показывает заметки |
| `db` | Официальный образ `postgres:17-alpine`, порт 5432 доступен внутри сети проекта |
| `app-net` | Bridge-сеть; приложение обращается к БД по DNS-имени `db` |
| `postgres_data` | Именованный volume, подключён к `/var/lib/postgresql/data` |
| `.env.example` | Пример необязательной локальной настройки |
| `.gitignore` | Исключает `.env`, окружения Python, логи и временные файлы |
| `app/Dockerfile` | Собирает образ Python, устанавливает зависимости, запускает Gunicorn от непривилегированного пользователя |
| `app/.dockerignore` | Исключает локальные секреты и временные файлы из контекста сборки |
| `app/requirements.txt` | Зафиксированные версии Flask, Psycopg и Gunicorn |
| `app/app.py` | Создание таблицы, SQL-запросы с параметрами, обработка формы и проверка БД |
| `app/templates/index.html` | Русский интерфейс; HTML из заметок автоматически экранируется Jinja |

`depends_on: condition: service_healthy` задерживает старт приложения до готовности PostgreSQL. Healthcheck базы использует `pg_isready`; `$$` перед переменными откладывает подстановку до выполнения команды внутри контейнера. Healthcheck приложения выполняет HTTP-запрос к `/health`, который обращается к таблице. Политика `unless-stopped` перезапускает завершившиеся контейнеры; сама отметка unhealthy контейнер не перезапускает.

## Запуск на Windows через VS Code

1. Установите Git, VS Code и Docker Desktop. В Docker Desktop включите движок WSL 2 и режим Linux containers; дождитесь запуска Engine. Python и PostgreSQL на Windows устанавливать не нужно.
2. Откройте PowerShell и получите репозиторий (если он уже клонирован, перейдите в его папку):

   ```powershell
   git clone https://github.com/d1p3r666/522.git
   cd 522
   git fetch origin
   git switch lab/docker-compose
   code .
   ```

   После слияния Pull Request лабораторная будет доступна в `main`: `git switch main`, затем `git pull --ff-only`.

3. В VS Code откройте Terminal → New Terminal, выберите PowerShell и перейдите в лабораторную:

   ```powershell
   cd DockerCompose
   docker version
   docker compose version
   ```

   Первая команда проверяет клиент и сервер Docker, вторая — наличие Compose. Ошибка соединения с Engine означает, что нужно запустить Docker Desktop.

4. Необязательно скопируйте пример настроек и отредактируйте `.env` в VS Code:

   ```powershell
   Copy-Item .env.example .env
   ```

   Без `.env` работают учебные значения по умолчанию: порт `8080`, база и пользователь `lab`, пароль `local_lab_password`. Они предназначены для локальной лабораторной. В `.env` можно изменить `APP_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`. Не публикуйте `.env`. Переменные PowerShell с теми же именами имеют приоритет над `.env`.

5. Проверьте итоговую конфигурацию и запустите проект:

   ```powershell
   docker compose config
   docker compose up -d --build
   docker compose ps
   ```

   `config` проверяет YAML и подставляет переменные (в том числе пароль — не публикуйте его вывод). `up` собирает приложение, скачивает PostgreSQL и запускает контейнеры в фоне. Для первого запуска нужен интернет. `ps` показывает состояние; дождитесь `healthy` у обоих сервисов. При необходимости дождаться автоматически: `docker compose up -d --build --wait`.

6. Откройте `http://localhost:8080`, добавьте заметку и обновите страницу. При смене `APP_PORT` используйте новый порт.

## Проверка работоспособности

Все команды далее выполняются из `DockerCompose`. Примеры предполагают порт 8080.

```powershell
Invoke-RestMethod http://localhost:8080/health
Invoke-WebRequest -UseBasicParsing -Method Post -Uri http://localhost:8080/notes -Body @{text='Проверка Docker Compose'}
(Invoke-WebRequest -UseBasicParsing http://localhost:8080/).Content
'TABLE notes;' | docker compose exec -T db sh -c 'exec psql -U $POSTGRES_USER -d $POSTGRES_DB'
```

Ожидается ответ health `status: ok`, `database: connected`; запись видна в браузере и в SQL-выводе. Для интерактивной работы с БД:

```powershell
docker compose exec db sh -c 'exec psql -U $POSTGRES_USER -d $POSTGRES_DB'
```

Внутри psql выполните `SELECT * FROM notes;`, выход — `\q`. Приложение показывает последние 100 заметок, каждая длиной 1–500 символов. Пустая или слишком длинная запись получает HTTP 400. Если работающая база временно недоступна, HTTP-запрос получает 503.

### Сохранение данных

1. Создайте заметку с уникальным текстом, запомните её номер.
2. Пересоздайте контейнеры, сохранив volume:

   ```powershell
   docker compose down
   docker compose up -d --build --wait
   docker compose volumes
   ```

3. Проверьте страницу и `TABLE notes;` повторно: та же запись должна сохраниться. Volume обычно называется `dockercompose_postgres_data`; Compose добавляет имя проекта. Запускайте команды из одной папки с тем же именем проекта.

`down` удаляет контейнеры и сеть, но сохраняет именованный volume. Команда `docker compose down -v` **удаляет данные базы**; используйте её только для намеренного полного сброса. Изменение пользователя, базы или пароля в `.env` не перенастраивает уже инициализированный volume: верните исходные значения либо отдельно измените настройки в PostgreSQL. Для пустой учебной базы допустим осознанный сброс volume.

## Управление и отладка

| Команда | Зачем нужна |
| --- | --- |
| `docker compose ls -a` | Показать Compose-проекты |
| `docker compose ps -a` | Показать контейнеры, включая остановленные |
| `docker compose logs --tail 100` | Последние сообщения всех сервисов |
| `docker compose logs -f web` | Следить за запросами и ошибками приложения; Ctrl+C завершает просмотр |
| `docker compose logs -f db` | Диагностика PostgreSQL |
| `docker compose restart` | Перезапустить существующие контейнеры |
| `docker compose stop` | Остановить с сохранением контейнеров |
| `docker compose start` | Запустить остановленные контейнеры |
| `docker compose build` | Только собрать образ приложения |
| `docker compose up -d --build` | Применить изменения кода или конфигурации |
| `docker compose down` | Остановить проект, удалить контейнеры и сеть, сохранить данные |

Если порт занят, задайте другой `APP_PORT` в `.env` и повторите `up`. Если база unhealthy, посмотрите логи `db`; если unhealthy приложение — логи `web`. После изменения окружения нужен `up -d`, обычный `restart` новые переменные не применяет.

## Фактические проверки

Проверено 16 ноября 2026 года на Windows с Docker Desktop (Linux Engine), Docker CLI 29.7.2 и Compose 5.5.1:

- `docker compose config` — конфигурация корректна.
- `docker compose up -d --build --wait` — образ собран, оба сервиса healthy.
- `GET /health` — HTTP 200, `database=connected`, `status=ok`.
- `POST /notes` — заметка сохранена и отображается на странице; пустая заметка отклонена с HTTP 400.
- `TABLE notes;` через psql — сохранённая запись присутствует в PostgreSQL.
- После `docker compose down` и повторного `up -d --build --wait` запись с тем же номером и текстом осталась в базе и на странице; volume `dockercompose_postgres_data` сохранён.

## Ожидаемый результат и вывод

Два контейнера имеют статус healthy, веб-форма записывает данные в PostgreSQL по внутренней сети, а заметки переживают удаление и создание контейнеров. Доступ к веб-приложению опубликован только на локальном интерфейсе Windows, база наружу не публикуется.

В работе освоены декларативная конфигурация Compose, сборка собственного образа, переменные окружения, зависимости по готовности, bridge-сеть, именованные volumes и команды диагностики. Один файл описывает всё окружение, а команда `docker compose up -d --build` запускает проект.
