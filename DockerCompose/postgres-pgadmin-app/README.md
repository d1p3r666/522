# Docker Compose — PostgreSQL + pgAdmin

## Цель и задание

Развернуть PostgreSQL и pgAdmin в двух контейнерах Docker Compose, подключить веб-интерфейс к базе, выполнить SQL и проверить сохранение данных после перезапуска.

Работа следует [инструкции преподавателя](https://github.com/rurewa/imfua/blob/main/content/Docker/DockerCompose/PostgreSQL_pgAdmin.md), прочитанной полностью; SHA исходного файла: `02c6528a6166295a61b7f79d729d50be2d0da770`. PostgreSQL — свободная объектно-реляционная СУБД. pgAdmin — графический инструмент администрирования PostgreSQL через браузер. Опечатки исходной инструкции исправлены: здесь PostgreSQL и pgAdmin; для Alpine используется оболочка `sh`.

## Файлы и конфигурация

```text
DockerCompose/postgres-pgadmin-app/
├── compose.yaml    # два сервиса, порты, переменные и том
├── .env.example    # демонстрационные параметры преподавателя
├── .gitignore      # исключает .env, локальные данные и резервные копии
├── test.sql        # версия сервера, тестовая таблица, три записи и чтение
├── README.md       # настройка, проверка и демонстрация
└── .env            # только локально; в Git не публикуется
```

| Параметр | PostgreSQL | pgAdmin |
| --- | --- | --- |
| Сервис Compose | `postgres` | `pgadmin` |
| Образ | `postgres:17-alpine` | `dpage/pgadmin4:latest` |
| Контейнер | `postgres-db` | `pgadmin-web` |
| Порт ПК → контейнера | `5432:5432` | `5050:80` |
| Переменные из `.env` | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD` |

Том `postgres_data` подключён к `/var/lib/postgresql/data`. Compose создаёт его с префиксом имени проекта: обычно `postgres-pgadmin-app_postgres_data`. Контейнеры автоматически подключаются к общей сети Compose. Новые приложения и дополнительные базы не добавлены. Данные pgAdmin отдельным томом не сохраняются, как и в примере преподавателя: после пересоздания его контейнера регистрацию сервера может потребоваться повторить.

## Подготовка в Windows, VS Code и Docker Desktop

1. Запустите Docker Desktop с Linux containers и дождитесь готовности движка. Проверьте `docker info`: команда показывает сведения о клиенте и сервере Docker; ошибки подключения к движку сначала нужно устранить.
2. Откройте репозиторий `522` в VS Code через **File → Open Folder**, затем **Terminal → New Terminal**. Выберите PowerShell.
3. Из корня репозитория перейдите в каталог лабораторной:

```powershell
cd DockerCompose\postgres-pgadmin-app
```

4. Создайте локальный файл настроек, только если его ещё нет:

```powershell
if (-not (Test-Path -LiteralPath .env)) {
    Copy-Item -LiteralPath .env.example -Destination .env
}
```

`Copy-Item` копирует учебный пример. Условие сохраняет уже настроенный `.env`. Пример содержит:

```dotenv
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_DB=mydatabase
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin
```

Это демонстрационные учётные данные для лабораторной на локальном ПК. Реальные пароли задавайте только в `.env`: он исключён из Git. Все пять значений обязательны; при отсутствующих или пустых значениях Compose выдаст ошибку до запуска.

Переменные PowerShell с теми же именами могут переопределить `.env`. Если меняете пользователя, базу или пароли, используйте фактические значения в pgAdmin и командах ниже. `POSTGRES_*` инициализируют базу только при первом запуске на пустом томе: редактирование `.env` не меняет пароль уже созданного пользователя PostgreSQL.

## Проверка конфликтов и запуск

Все последующие команды Docker выполняются в каталоге с `compose.yaml`.

```powershell
docker compose ls
```

Показывает существующие проекты. Сначала убедитесь, что запуск не конфликтует с другими лабораторными. Проверьте занятость портов:

```powershell
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalPort -in 5432, 5050 } |
    Select-Object LocalAddress, LocalPort, OwningProcess
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Первая команда показывает слушающие процессы на портах 5432 и 5050; отсутствие строк означает, что слушателей не найдено. При ошибке доступа это не подтверждение свободных портов. Вторая показывает контейнеры, их имена и публикацию портов. Для найденного PID используйте `Get-Process -Id <PID>`, подставив его число. Если порты или имена `postgres-db`/`pgadmin-web` уже заняты, выясните владельца и причину конфликта. Чужие контейнеры автоматически не останавливайте; порты задания не меняйте.

```powershell
docker compose config --quiet
docker compose config
docker compose up -d
docker compose ps -a
```

`config --quiet` проверяет конфигурацию без её вывода; код завершения 0 означает успех. `config` показывает итоговую конфигурацию после подстановки переменных, включая пароли: не публикуйте такой вывод с реальными секретами. `up -d` скачивает образы при необходимости, создаёт сеть, том и контейнеры и запускает их в фоне. `ps -a` показывает также остановленные контейнеры. Оба контейнера должны иметь состояние **Up**; готовность PostgreSQL проверяется отдельно:

```powershell
docker compose exec -T postgres pg_isready -U myuser -d mydatabase
```

Ожидается `accepting connections`. Если сервер ещё инициализируется, подождите и повторите. Если контейнер завершился, посмотрите его логи по командам ниже.

## Подключение через pgAdmin

1. Откройте <http://localhost:5050> в браузере. Первичная загрузка может занять некоторое время.
2. Введите `admin@example.com` и пароль `admin` из учебного `.env`.
3. В дереве слева нажмите правой кнопкой **Servers → Register → Server**.
4. Во вкладке **General** задайте Name: `My Local PostgreSQL`.
5. Во вкладке **Connection** заполните:

| Поле | Учебное значение |
| --- | --- |
| Host name/address | `postgres-db` |
| Port | `5432` |
| Maintenance database | `mydatabase` |
| Username | `myuser` |
| Password | `mypassword` |

6. Нажмите **Save**. Раскройте **Databases → mydatabase** и откройте **Query Tool**.
7. Выполните содержимое `test.sql` и проверьте версию PostgreSQL и три строки результата.

`postgres-db` — имя контейнера; `postgres` — имя сервиса, его тоже можно использовать внутри сети. `localhost` в pgAdmin указывал бы на сам контейнер pgAdmin. Для подключения программы с Windows используются `localhost:5432` и те же параметры базы.

## SQL и сохранение данных

`test.sql` выполняет `SELECT version();`, создаёт таблицу `public.compose_lab_notes`, добавляет записи о Docker Compose, PostgreSQL и pgAdmin и читает их. `CREATE TABLE IF NOT EXISTS` и `ON CONFLICT (id) DO NOTHING` позволяют повторить демонстрацию без удаления таблицы или перезаписи существующих записей. Если одноимённая таблица уже имеет другую структуру, сначала изучите её; скрипт не исправляет её разрушительными операциями.

Запуск того же файла из PowerShell без браузера:

```powershell
Get-Content -Raw -Encoding UTF8 -LiteralPath test.sql |
    docker compose exec -T postgres psql -U myuser -d mydatabase -v ON_ERROR_STOP=1
```

`Get-Content` читает SQL, `exec -T` передаёт его в контейнер без интерактивного терминала, `psql` выполняет запросы; `ON_ERROR_STOP=1` останавливает обработку при SQL-ошибке. Успешный результат на новой базе: версия PostgreSQL 17, строки с id 1–3 и `row_count = 3`.

Проверьте сохранность отдельно, не повторяя вставку после перезапуска:

```powershell
docker compose exec -T postgres psql -U myuser -d mydatabase -v ON_ERROR_STOP=1 -c 'SELECT id, topic FROM public.compose_lab_notes ORDER BY id;'
docker compose restart
docker compose exec -T postgres pg_isready -U myuser -d mydatabase
docker compose exec -T postgres psql -U myuser -d mydatabase -v ON_ERROR_STOP=1 -c 'SELECT id, topic FROM public.compose_lab_notes ORDER BY id;'
```

После `restart` дождитесь готовности через `pg_isready`, при необходимости повторив его, и только затем выполняйте последнее чтение. Сравните строки до и после: они должны совпасть. Повторный запуск `test.sql` вместо последнего SELECT заново вставил бы отсутствующие записи и не доказал сохранность. Том при этой проверке не удаляется.

## Управление

| Команда | Что делает |
| --- | --- |
| `docker compose logs -f pgadmin` | Показывает логи pgAdmin и ждёт новых строк |
| `docker compose logs -f postgres` | Показывает логи PostgreSQL и ждёт новых строк |
| `docker compose stop` | Останавливает оба контейнера, сохраняя контейнеры и том |
| `docker compose start` | Запускает ранее остановленные контейнеры |
| `docker compose restart` | Перезапускает контейнеры, сохраняя том |
| `docker compose config` | Проверяет и печатает итоговую конфигурацию |
| `docker compose exec postgres sh` | Открывает оболочку внутри запущенного PostgreSQL |

Для выхода из просмотра логов нажмите **Ctrl+C**: контейнеры продолжат работать. Для выхода из оболочки введите `exit`. В образе Alpine `bash` может отсутствовать, поэтому используется `sh`. `restart` не применяет изменения конфигурации: после изменения Compose используйте `docker compose up -d`.

## Остановка и удаление

```powershell
docker compose down
```

Останавливает и удаляет контейнеры проекта и его сеть, но сохраняет именованный том PostgreSQL. Следующий `up -d` подключит его снова, если имя проекта и каталог остаются прежними. Регистрация сервера в pgAdmin при пересоздании его контейнера не сохраняется.

Только если данные PostgreSQL больше не нужны:

```powershell
docker compose down --volumes
# Равнозначная короткая форма:
docker compose down -v
```

Эти две формы дополнительно удаляют том проекта и все данные PostgreSQL в нём. Это альтернативы, выполнять обе не нужно. Они не удаляют каталог проекта или скачанные образы. При выполнении лабораторной удаление томов автоматически не производится.

Чтобы вручную удалить только каталог лабораторной в Windows, сначала выполните `docker compose down`, сохраните необходимые файлы и выйдите в родительский каталог. Пример для PowerShell:

```powershell
cd ..
$labParent = (Get-Location).Path
$labTarget = (Resolve-Path -LiteralPath .\postgres-pgadmin-app).Path
if ((Split-Path -Path $labTarget -Parent) -ne $labParent -or
    (Split-Path -Path $labTarget -Leaf) -ne 'postgres-pgadmin-app') {
    throw 'Путь не совпадает с каталогом лабораторной'
}
$labTarget
Remove-Item -LiteralPath $labTarget -Recurse -WhatIf
```

Проверьте выведенный абсолютный путь: это должен быть именно `522\DockerCompose\postgres-pgadmin-app`. `-WhatIf` лишь показывает предполагаемое удаление. После проверки вручную повторите последнюю команду без `-WhatIf`, добавив `-Confirm`. Не удаляйте весь `DockerCompose`, HomeHub или LibreDB Studio. Удаление папки не удаляет том Docker; для его удаления нужна отдельная осознанная команда выше. Общие образы удалять для завершения лабораторной не требуется.

## Фактические проверки

Проверки выполнены 18 ноября 2026 года в среде Codex на Windows:

- Инструкция преподавателя прочитана; образы, контейнеры, порты и путь тома сопоставлены с примером.
- Установлен Docker Compose `v5.5.1`.
- `docker compose config --quiet` завершился успешно. Конфигурация JSON содержит ровно `postgres` и `pgadmin`, заданные переменные и том `postgres_data`.
- Создан локальный `.env` с демонстрационными значениями; файл исключён из публикации.
- Проверка слушающих портов через `Get-NetTCPConnection` получила «Отказано в доступе»; она не подтверждает доступность портов. Перед запуском повторите проверку на своём ПК.
- `docker compose ls` и `docker info` не получили доступ к движку: отсутствует канал `//./pipe/dockerDesktopLinuxEngine`. Запуск процесса Docker Desktop не устранил ошибку во время проверки.
- Проверки контейнеров, SQL, готовности PostgreSQL, веб-интерфейса pgAdmin и сохранности данных после перезапуска **не выполнены** из-за недоступного движка. Команды `stop`, `start`, `restart`, просмотра логов и входа в контейнер документированы для ручной проверки.
- Тома и существующие пользовательские данные не удалялись. Изменения ограничены каталогом этой лабораторной.

Успешная проверка синтаксиса Compose не подтверждает запуск образов или выполнение SQL. Результаты запуска нужно дополнить после выполнения шагов на ПК с работающим Docker Desktop.

## Демонстрация преподавателю

1. Покажите `compose.yaml`, `.env.example`, исключение `.env` и назначение тома.
2. Выполните проверку конфликтов, `docker compose config --quiet`, `docker compose up -d`, `docker compose ps -a` и `pg_isready`.
3. Войдите в pgAdmin, зарегистрируйте `My Local PostgreSQL`, откройте Query Tool базы `mydatabase`.
4. Выполните `test.sql`: покажите версию сервера и три записи.
5. Выполните `docker compose restart`, дождитесь готовности, повторите только SELECT и покажите те же данные.
6. Продемонстрируйте логи и выход через Ctrl+C, затем `stop`, `start` и состояние контейнеров. При необходимости откройте `sh` и выйдите через `exit`.
7. Объясните разницу между `down` и `down -v`; удалять том для демонстрации не требуется.

Вручную остаётся обеспечить работу движка Docker Desktop, выполнить запуск и SQL, подключиться через браузер и подтвердить сохранность данных. При необходимости сделайте собственные скриншоты этих результатов.

## Вывод

Подготовлена конфигурация двух контейнеров PostgreSQL и pgAdmin с общей сетью, параметрами в окружении и постоянным томом базы. Синтаксис Compose проверен. Работа демонстрирует настройку взаимодействия контейнеров, проверку базы через SQL и управление жизненным циклом проекта; практический запуск и сохранность данных требуют подтверждения на работающем Docker.
