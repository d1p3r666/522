# Лабораторная работа: Docker Compose проект с drawDB

Выполнено 20 ноября 2026 года по [инструкции преподавателя](https://github.com/rurewa/imfua/blob/main/content/Docker/DockerCompose/drawDB.md).

## Размещение и запуск

Официальный репозиторий: <https://github.com/drawdb-io/drawdb>.
Клон находится в корне домашнего каталога: `C:\Users\stillmvd\drawdb`.
Проверенная ревизия: `86e443fc17cc59d9ca36e02198d335fabfe9ec6f`.
Этот каталог содержит только материалы для сдачи; исходный проект находится в домашнем каталоге.

Выполнены команды:

```powershell
git --version
docker --version
docker compose version
docker compose ls
Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue
cd ~
git clone https://github.com/drawdb-io/drawdb
cd drawdb
git remote -v
git rev-parse HEAD
git status --short
Get-Content compose.yml
docker compose config --quiet
docker compose up -d
docker compose ls
docker compose ps -a
docker compose logs --tail=40
```

Для диагностики первого запуска также использованы `docker compose top`,
`docker compose exec -T drawdb` с просмотром журнала npm и `Invoke-WebRequest`.
Штатный `npm install` автоматически убрал платформенные метаданные из `package-lock.json`;
после завершения установки исходный lock-файл возвращён командой
`git restore --source=HEAD -- package-lock.json`. Исходный код и Compose-файл не изменялись.

## Compose-конфигурация

Использован оригинальный `compose.yml` из клона:

```yaml
services:
  drawdb:
    image: node:20-alpine
    container_name: drawdb
    ports:
      - 5173:5173
    working_dir: /var/www/html
    volumes:
      - ./:/var/www/html
    command: sh -c "npm install && npm run dev -- --host"
    networks:
      - default

networks:
  default:
    driver: bridge
```

Каталог репозитория подключён в контейнер через bind mount. Node устанавливает зависимости,
после чего запускает Vite на всех интерфейсах контейнера. Порт 5173 опубликован на компьютере.
Compose создал сеть `drawdb_default`; отдельные именованные тома конфигурация не объявляет.
В первый запуск загрузка зависимостей и подготовка Vite заняли несколько минут.

## Результаты проверок

- Git, Docker Engine и Docker Compose доступны.
- До запуска проверены существующие проекты и свободный порт 5173.
- Официальный репозиторий успешно клонирован, `origin` проверен.
- `docker compose config --quiet` и `docker compose up -d` завершились с кодом 0.
- Контейнер `drawdb` запущен, опубликован порт `5173:5173`.
- <http://localhost:5173/> и <http://localhost:5173/editor> проверены в настоящем Chrome.
- В браузере созданы две таблицы: `customers(id)` и `orders(id, customer_id)`.
- У ключевых полей выбран `INTEGER UNSIGNED`; `id` — первичный ключ с автоинкрементом.
- Перетаскиванием создана связь `orders.customer_id → customers.id`, многие к одному.
- Редактор показывает `Tables (2)`, `Relationships (1)` и `Problems 0`.
- Диаграмма сохраняется после перезагрузки страницы; JavaScript-ошибок в проверенных страницах нет.
- Через меню приложения скачаны SQL, JSON и Mermaid; содержимое экспортов проверено.
- SQL содержит обе таблицы и `FOREIGN KEY`; JSON содержит две таблицы и одну связь.
- Существующие проекты не останавливались. WordPress на порту 8081 продолжает работать.

В логах есть предупреждения об устаревших npm-пакетах и сообщение npm audit об одной
уязвимости уровня moderate. Фатальных ошибок запуска нет; журнал npm завершился кодом 0,
Vite сообщил о готовности. Автоматическое изменение зависимостей через `npm audit fix`
не выполнялось, чтобы сохранить исходный проект преподавательской работы.

## Экспорты и открытие диаграммы

- [customers-orders.sql](exports/customers-orders.sql) — SQL с внешним ключом.
- [customers-orders.json](exports/customers-orders.json) — переносимый файл drawDB.
- [customers-orders.md](exports/customers-orders.md) — ER-диаграмма Mermaid.

Тестовая диаграмма создана в отдельном профиле Chrome автоматизации.
drawDB хранит диаграммы в браузере, а не в контейнере.
Чтобы открыть результат в своём браузере, перейдите в редактор, выберите MySQL,
затем JSON и импортируйте `exports/customers-orders.json`.
Это восстановит уже подготовленные таблицы и связь без ручного создания схемы.

## Скриншоты для сдачи

Скриншоты уже сделаны; дополнительно снимать их вручную не требуется, если преподаватель
не требует именно снимок окна терминала или адресной строки браузера.

| Файл | Содержимое |
| --- | --- |
| [01-home.png](screenshots/01-home.png) | Главная страница drawDB |
| [02-diagram.png](screenshots/02-diagram.png) | Две таблицы, связь, счётчики и отсутствие проблем |
| [03-export-sql.png](screenshots/03-export-sql.png) | Окно экспорта SQL с внешним ключом |
| [04-export-json.png](screenshots/04-export-json.png) | Окно экспорта JSON |
| [05-export-mermaid.png](screenshots/05-export-mermaid.png) | Окно экспорта Mermaid |
| [06-reloaded-diagram.png](screenshots/06-reloaded-diagram.png) | Диаграмма после перезагрузки страницы |
| [07-docker-checks.png](screenshots/07-docker-checks.png) | Фактический вывод проверок Docker и HTTP |

`01`–`06` — снимки содержимого настоящих страниц Chrome. `07` — снимок фактического
вывода команд, отображённого в браузере; это не снимок окна терминала.
Если преподаватель требует терминал, покажите в нём `docker compose ls`,
`docker compose ps -a`, `docker compose config --quiet` и `docker compose logs --tail=25`
из `C:\Users\stillmvd\drawdb` и снимите это окно.

## Что осталось до полного завершения

Проект оставлен запущенным для просмотра и сдачи. Удаление из последнего раздела
инструкции преподавателя намеренно отложено до отдельного подтверждения пользователя.
До такого подтверждения контейнер, сеть, образ, данные и каталог проекта не удаляются.

После подтверждения необходимо проверить Compose-метки и принадлежность ресурсов
проекту `drawdb`, выполнить предусмотренную преподавателем очистку только этого проекта,
проверить отсутствие его контейнеров, определить образ и убедиться, что он не нужен
другим проектам, затем удалить только `C:\Users\stillmvd\drawdb`.
WordPress и материалы для сдачи в этом каталоге должны сохраниться.

## Фактический вывод итоговых проверок

Приведён ниже; дата и время указаны по Москве. HTTP-проверки включают drawDB и WordPress.

Проверено: 20.11.2026, 13:20:19 (Москва).

```text
> git remote -v
origin	https://github.com/drawdb-io/drawdb (fetch)
origin	https://github.com/drawdb-io/drawdb (push)
Код завершения: 0
```

```text
> git rev-parse HEAD
86e443fc17cc59d9ca36e02198d335fabfe9ec6f
Код завершения: 0
```

```text
> git status --short
(пустой вывод)
Код завершения: 0
```

```text
> docker compose config --quiet
(пустой вывод)
Код завершения: 0
```

```text
> docker compose ls
NAME                STATUS              CONFIG FILES
dockercompose       running(2)          C:\Users\stillmvd\work\522\DockerCompose\compose.yaml
drawdb              running(1)          C:\Users\stillmvd\drawdb\compose.yml
wordpress           running(2)          C:\Users\stillmvd\Desktop\uuu\522\DockerCompose\wordpress\compose.yaml
Код завершения: 0
```

```text
> docker compose ps -a
NAME      IMAGE            COMMAND                  SERVICE   CREATED          STATUS          PORTS
drawdb    node:20-alpine   "docker-entrypoint.s…"   drawdb    13 minutes ago   Up 13 minutes   0.0.0.0:5173->5173/tcp, [::]:5173->5173/tcp
Код завершения: 0
```

```text
> docker compose logs --tail=27
drawdb  | added 580 packages, and audited 581 packages in 2m
drawdb  |
drawdb  | 259 packages are looking for funding
drawdb  |   run `npm fund` for details
drawdb  |
drawdb  | 1 moderate severity vulnerability
drawdb  |
drawdb  | To address all issues, run:
drawdb  |   npm audit fix
drawdb  |
drawdb  | Run `npm audit` for details.
drawdb  | npm notice
drawdb  | npm notice New major version of npm available! 10.8.2 -> 12.2.3
drawdb  | npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.3
drawdb  | npm notice To update run: npm install -g npm@12.2.3
drawdb  | npm notice
drawdb  |
drawdb  | > drawdb@0.0.0 dev
drawdb  | > vite --host
drawdb  |
drawdb  |
drawdb  |   VITE v8.3.5  ready in 1101 ms
drawdb  |
drawdb  |   ➜  Local:   http://localhost:5173/
drawdb  |   ➜  Network: http://172.20.0.2:5173/  eth0
drawdb  | 10:08:18 AM [vite] (client) [optimizer] scanning dependencies...
drawdb  | 10:08:25 AM [vite] (client) [optimizer] bundling dependencies...
Код завершения: 0
```

```text
> docker inspect --format project={{index .Config.Labels "com.docker.compose.project"}} service={{index .Config.Labels "com.docker.compose.service"}} image={{.Config.Image}} drawdb
project=drawdb service=drawdb image=node:20-alpine
Код завершения: 0
```

```text
> docker ps --format table {{.Names}}	{{.Status}}	{{.Ports}}
NAMES                   STATUS                    PORTS
drawdb                  Up 13 minutes             0.0.0.0:5173->5173/tcp, [::]:5173->5173/tcp
wordpress-wordpress-1   Up 27 minutes             0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
wordpress-db-1          Up 27 minutes (healthy)   3306/tcp, 33060/tcp
dockercompose-web-1     Up 36 minutes (healthy)   127.0.0.1:8080->8000/tcp
dockercompose-db-1      Up 36 minutes (healthy)   5432/tcp
Код завершения: 0
```

```text
> HTTP GET http://localhost:5173/
HTTP 200
URL: http://localhost:5173/
HTML bytes: 2510
Код завершения: 0
```

```text
> HTTP GET http://localhost:5173/editor
HTTP 200
URL: http://localhost:5173/editor
HTML bytes: 2510
Код завершения: 0
```

```text
> HTTP GET http://localhost:8081/
HTTP 200
URL: http://localhost:8081/
HTML bytes: 69648
Код завершения: 0
```
