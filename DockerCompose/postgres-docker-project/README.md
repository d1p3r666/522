# Лабораторная работа «Docker Compose — PostgreSQL»

## Цель и исходная инструкция

Развернуть PostgreSQL 15 через Docker Compose, автоматически создать базы,
пользователей и тестовую таблицу, проверить подключение и сохранение данных,
освоить управление контейнером.

Работа выполнена по [инструкции преподавателя](https://github.com/rurewa/imfua/blob/main/content/Docker/DockerCompose/PostgresSQL.md).
Проект расположен отдельно от PostgreSQL + pgAdmin, HomeHub и LibreDB Studio.

**PostgreSQL** — свободная объектно-реляционная СУБД с поддержкой SQL,
транзакций и ограничений целостности. **Docker Compose** описывает сервисы,
сети, переменные окружения и монтирования в YAML и позволяет управлять ими
командами `docker compose` из каталога проекта.

## Структура

```text
postgres-docker-project/
├── data/
│   └── .gitkeep
├── scripts/
│   └── init.sql
├── backups/
│   └── .gitkeep
├── docker-compose.yml
├── .env.example
├── .gitignore
└── README.md
```

`data` хранит кластер PostgreSQL, `scripts/init.sql` — начальные SQL-команды,
`backups` предназначен для резервных копий. Само монтирование `backups` не
создаёт резервные копии автоматически. `.gitkeep` сохраняют пустые каталоги
в Git. `.gitignore` исключает `.env`, реальные данные и резервные копии;
в Git остаются только заглушки и демонстрационный `.env.example`.

## Конфигурация Docker Compose

Содержимое `docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:15
    container_name: my-postgres
    environment:
      POSTGRES_DB: mydatabase
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?Copy .env.example to .env and set POSTGRES_PASSWORD}
      # Keep the cluster separate from the tracked data/.gitkeep placeholder.
      PGDATA: /var/lib/postgresql/data/pgdata
    ports:
      - "5432:5432"
    volumes:
      - ./data:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./backups:/backups
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myuser -d mydatabase"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Образ и основные настройки соответствуют примеру преподавателя:

- `postgres:15` — PostgreSQL версии 15; `postgres` — имя сервиса,
  `my-postgres` — фиксированное имя контейнера.
- `POSTGRES_DB` и `POSTGRES_USER` создают основную базу `mydatabase` и
  пользователя `myuser` с правами суперпользователя при первом запуске.
- Пароль берётся из локального `.env`. В `.env.example` находится учебное
  значение `mypassword`. Если переменная отсутствует или пуста, Compose
  выдаёт понятную ошибку до запуска. Учебные пароли не подходят для реальных данных.
- `5432:5432` публикует порт PostgreSQL на хосте; другие проекты с этим портом
  нельзя запускать одновременно с данным проектом.
- Три bind mount связывают каталоги/файл компьютера с контейнером.
  Для PostgreSQL 15 сохранён путь `/var/lib/postgresql/data`.
- Единственное дополнительное окружение — `PGDATA`: кластер создаётся во
  вложенном каталоге `data/pgdata`. Это необходимо, потому что `data/.gitkeep`
  делает родительский каталог непустым, а `initdb` требует пустой каталог
  кластера. Удалять заглушку из Git или менять версию PostgreSQL не требуется.
- `unless-stopped` перезапускает контейнер после сбоя, пока он не остановлен
  вручную. Healthcheck запускает `pg_isready` каждые 30 секунд с таймаутом
  10 секунд и порогом в 3 неудачные проверки. Он проверяет готовность сервера;
  наличие таблиц, права и пароль проверяются отдельно через `psql`.

## SQL-инициализация

Файл [scripts/init.sql](scripts/init.sql) выполняет:

1. `CREATE DATABASE app_db` — создаёт дополнительную базу.
2. `CREATE USER app_user WITH PASSWORD 'app_password'` — создаёт учебную роль
   с возможностью входа.
3. `GRANT ALL PRIVILEGES ON DATABASE app_db TO app_user` — выдаёт права на базу.
   Права на базу не означают автоматическую выдачу всех прав на схемы и таблицы;
   создание таблиц в `app_db` этой лабораторной не требуется.
4. `\c mydatabase` — переключает соединение `psql` на основную базу.
   Это метакоманда, поэтому после имени базы нет SQL-точки с запятой.
5. Создаёт `users`: `id SERIAL PRIMARY KEY`, обязательные `name VARCHAR(100)`
   и уникальный `email VARCHAR(100)`, `created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`.
6. Вставляет Ивана Иванова (`ivan@example.com`) и Марию Петрову
   (`maria@example.com`). `ON CONFLICT (email) DO NOTHING` пропускает уже
   существующий email.

Официальный образ запускает `init.sql` через `psql` **только при первоначальной
инициализации пустого каталога кластера** (здесь `data/pgdata`). При последующих
запусках данные сохраняются, скрипт повторно не выполняется. Изменение `.env`
также не меняет пароль уже созданной роли. Весь скрипт не является повторно
исполняемым: `CREATE DATABASE` и `CREATE USER` завершатся ошибкой при наличии
одноимённых объектов. Не запускайте его заново поверх существующей базы.

## Запуск на Windows: VS Code и Docker Desktop

1. Установите Docker Desktop с поддержкой Linux containers/WSL 2 и VS Code.
   Запустите Docker Desktop и дождитесь готовности движка.
2. Откройте репозиторий `522` в VS Code, выберите **Terminal → New Terminal**
   и PowerShell. Все следующие команды выполняются из каталога лабораторной.

```powershell
cd DockerCompose/postgres-docker-project
Copy-Item .env.example .env
docker compose ls
docker ps -a
Get-NetTCPConnection -LocalPort 5432 -State Listen -ErrorAction SilentlyContinue
```

`cd` переходит в проект; `Copy-Item` создаёт локальный `.env` (выполните один
раз, не перезаписывайте свои настройки). `docker compose ls` показывает другие
Compose-проекты, `docker ps -a` — все контейнеры, включая остановленные:
проверьте отсутствие чужого контейнера `my-postgres`. `Get-NetTCPConnection`
показывает слушателей порта 5432; пустой вывод означает отсутствие найденных
слушателей. При конфликте сначала самостоятельно решите, какой проект нужен;
эта работа не останавливает другие контейнеры автоматически.

```powershell
docker compose config
docker compose up -d
docker compose ps
docker compose logs postgres
docker ps -a
docker inspect --format '{{.State.Health.Status}}' my-postgres
```

`config` проверяет и выводит итоговую конфигурацию с подставленным паролем
(не публикуйте её с реальными секретами). `up -d` загружает образ при необходимости,
создаёт и запускает контейнер в фоне. `ps` показывает состояние текущего проекта,
`logs postgres` — журнал запуска и SQL-инициализации. `docker ps -a` позволяет
сопоставить контейнер со всеми остальными. `inspect` выводит состояние
healthcheck: дождитесь `healthy`, при необходимости повторите команду через
30 секунд. Ожидаемый статус — `Up` и `healthy`; это критерий проверки, а не
заявление о фактически выполненном запуске.

Если движок недоступен, сначала исправьте запуск Docker Desktop. При ошибке
инициализации изучите логи; не удаляйте существующий `data` ради повторного запуска.

## Проверка PostgreSQL и демонстрация преподавателю

```powershell
docker exec -it my-postgres psql -U myuser -d mydatabase
```

`docker exec -it` открывает интерактивный терминал внутри работающего контейнера;
`psql -U myuser -d mydatabase` подключается к основной базе от имени `myuser`.
В открывшемся `psql` выполните:

```sql
SELECT version();
SELECT * FROM users ORDER BY id;
\l
\du
\dt
SELECT datname FROM pg_database WHERE datname IN ('mydatabase', 'app_db') ORDER BY datname;
SELECT rolname FROM pg_roles WHERE rolname IN ('myuser', 'app_user') ORDER BY rolname;
SELECT has_database_privilege('app_user', 'app_db', 'CONNECT') AS can_connect,
       has_database_privilege('app_user', 'app_db', 'CREATE') AS can_create,
       has_database_privilege('app_user', 'app_db', 'TEMPORARY') AS can_temp;
\q
```

`version()` должен показать PostgreSQL 15. Запрос `users` должен вернуть две
учебные записи с непустыми датами создания. `\l` перечисляет базы, `\du` — роли,
`\dt` — таблицы текущей базы. Два запроса к системным каталогам отдельно
проверяют обе базы и обе роли; `has_database_privilege` проверяет выданные права
(ожидается `t` во всех трёх столбцах). `\q` завершает `psql`.

Для проверки пароля через TCP (в отличие от локального сокета внутри контейнера):

```powershell
docker exec -it my-postgres psql -h 127.0.0.1 -U myuser -d mydatabase -W -c "SELECT current_user, current_database();"
docker exec -it my-postgres psql -h 127.0.0.1 -U app_user -d app_db -W -c "SELECT current_user, current_database();"
```

`-h` выбирает TCP, `-W` запрашивает пароль интерактивно, `-c` выполняет запрос
и завершает клиент. Введите соответственно `mypassword` (или значение своего
`.env`) и `app_password`. Убедитесь, что показаны нужные пользователь и база,
а ошибок подключения нет.

PostgreSQL использует собственный сетевой протокол. Открытие
`http://localhost:5432` в браузере не является проверкой базы данных.

## Сохранность данных после перезапуска

До перезапуска сохраните вывод таблицы (включая `id` и `created_at`):

```powershell
docker exec my-postgres psql -U myuser -d mydatabase -c "SELECT * FROM users ORDER BY id;"
docker compose stop
docker compose start
docker compose ps
docker inspect --format '{{.State.Health.Status}}' my-postgres
docker exec my-postgres psql -U myuser -d mydatabase -c "SELECT * FROM users ORDER BY id;"
```

Первый и последний запросы должны вернуть одинаковые две строки, идентификаторы
и даты. `stop` корректно останавливает контейнер, `start` запускает тот же
контейнер; перед последним запросом дождитесь `healthy`. Совпадение результатов
демонстрирует сохранение кластера в `./data/pgdata`. Каталог `data` после проверки
не удаляйте. Здесь `exec` без `-it`, поскольку выполняется один запрос.

## Управление контейнером

| Команда | Действие и назначение |
| --- | --- |
| `docker compose stop` | Останавливает сервис, сохраняя контейнер, сеть и данные. |
| `docker compose start` | Запускает ранее остановленный контейнер, не создаёт новый. |
| `docker compose down` | Останавливает и удаляет контейнер и сеть этого проекта. Данные bind mount остаются. |
| `docker compose up -d` | Создаёт недостающие ресурсы и запускает сервис в фоне; при изменении конфигурации может пересоздать контейнер. |
| `docker compose ps` | Показывает состояние сервисов текущего проекта. |
| `docker compose logs postgres` | Показывает журнал PostgreSQL для проверки запуска и поиска ошибок. |
| `docker compose config` | Проверяет YAML, переменные и пути; выводит итоговую конфигурацию. |

После `down` нужен `up -d`, потому что `start` не создаёт удалённый контейнер.

## Остановка и безопасное удаление

Следующие команды описаны для самостоятельного управления; удаление образов
и очистка Docker при подготовке этой работы не выполнялись.

| Команда | Действие и ограничения |
| --- | --- |
| `docker compose down` | Удаляет контейнер и сеть только текущего проекта; подходит для завершения демонстрации. |
| `docker compose down -v` | Дополнительно удаляет объявленные именованные и присоединённые анонимные volumes; внешние volumes не удаляет. |
| `docker ps -a` | Проверяет, что контейнер `my-postgres` удалён. Контейнеры других проектов могут остаться. |
| `docker volume ls` | Показывает Docker volumes; каталоги bind mount в этом списке не отображаются. |
| `docker network ls` | Позволяет проверить отсутствие сети `postgres-docker-project_default`; системные и чужие сети остаются. |
| `docker images` | Показывает локальные образы, в том числе оставшийся `postgres:15`. |
| `docker rmi postgres:15` | Необязательно удаляет образ, когда использующие его контейнеры удалены; не применяйте принудительное удаление. |
| `docker image prune -a` | Удаляет все образы, не используемые контейнерами, во всём Docker, включая образы других проектов. Это общая очистка, для лабораторной не нужна; здесь только описана. |

**`docker compose down -v` не удаляет содержимое `./data` и `./backups` на
компьютере.** В этом проекте используются bind mount, а не именованные Docker
volumes. Поэтому повторный `up -d` использует прежние данные и не запускает
`init.sql` заново. Удаление образа также не удаляет каталог данных. Не удаляйте
реальные данные без отдельной резервной копии; эта работа не требует их удаления.

## Результаты реально проведённых проверок

Проверки при подготовке работы 18 ноября 2026 года:

- Полностью прочитана исходная инструкция преподавателя, изучена структура
  `main` репозитория `d1p3r666/522`; прежние лабораторные не изменены.
- Установлен Docker Compose v5.5.1. С локальным `.env` команда
  `docker compose config --quiet` завершилась с кодом 0; конфигурация также
  успешно разобрана командой `docker compose config --format json`.
- Подтверждены образ `postgres:15`, имя `my-postgres`, порт 5432,
  три bind mount, переменные, политика перезапуска и параметры healthcheck.
- На момент проверки слушатели TCP-порта 5432 не найдены.
- `docker compose ls`, `docker ps -a` и `docker info` не смогли обратиться
  к Docker Engine: отсутствовал канал `dockerDesktopLinuxEngine`.
  Выполнена попытка запуска Docker Desktop, но доступность движка не подтверждена.
- Поэтому запуск контейнера, статус `healthy`, выполнение `init.sql`, SQL-запросы,
  проверка паролей и сохранности данных после перезапуска **не подтверждены**.
  Их необходимо выполнить локально по разделам выше при работающем Docker Engine.
- SQL проверен чтением: метакоманда `\c` оформлена отдельно, определения таблицы
  и вставка соответствуют заданию. Это не заменяет выполнение на PostgreSQL.
- В Git включены только файлы лабораторной и `.gitkeep`; `.env`, данные
  и резервные копии исключены правилами `.gitignore`.

## Вывод и план защиты

Подготовлен отдельный проект PostgreSQL 15 с автоматической инициализацией,
постоянным хранением данных и healthcheck. Статическая проверка Compose прошла.
Для завершения практической проверки требуется работающий Docker Engine.

Преподавателю следует показать конфигурацию и `init.sql`, состояние `healthy`,
версию PostgreSQL, обе базы и роли, таблицу с двумя строками, подключение по TCP
с паролями и неизменность данных после `stop` / `start`. Объясните различия
между `stop`, `start`, `down`, `up` и сохранение bind mount после `down -v`.
