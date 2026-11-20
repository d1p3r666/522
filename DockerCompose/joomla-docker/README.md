# Joomla Lab — Docker Compose в WSL

Лабораторная работа выполнена 20 ноября 2026 года по [инструкции преподавателя](https://github.com/rurewa/imfua/blob/main/content/Docker/DockerCompose/joomla.md).

## Результат

- Сайт: <http://localhost:8082/>. Название в конфигурации — `Joomla Lab`.
- Админ-панель: <http://localhost:8082/administrator/>. Администратор: `labadmin`.
- Случайный пароль администратора сохранён в локальном `.env`, ключ `JOOMLA_ADMIN_PASSWORD`.
- Учебный email: `admin@example.test`; его можно заменить в профиле администратора.
- Использованы `joomla:latest` (при выполнении Joomla 6.2.0) и `mariadb:11.5.2`.
- База `joomla_db`, пользователь `joomla_user`, подключение MySQLi к `db`.
- Установка завершена в Chrome, вход администратора проверен. Каталог `installation`
  удалён штатной кнопкой завершения установщика; ручное удаление файлов не понадобилось.
- Сохранён стандартный шаблон Cassiopeia и его главная страница `Home`.
  Название сайта в настройках Joomla — `Joomla Lab`; надпись Cassiopeia в логотипе — имя шаблона.

## Окружение WSL

Создание проекта и команды Docker выполнялись из **Bash Ubuntu 26.04 LTS в WSL2**.
Это подтверждено `/etc/os-release` и `uname -a` (ядро `microsoft-standard-WSL2`).
Проект размещён в доступном из Linux каталоге:

```text
/mnt/c/Users/stillmvd/Desktop/uuu/522/DockerCompose/joomla-docker
```

Windows-путь: `C:\Users\stillmvd\Desktop\uuu\522\DockerCompose\joomla-docker`.

Интеграция Docker Desktop с Ubuntu на этом компьютере выключена. Поэтому команды
из Bash обращаются к установленному **Windows Docker CLI через WSL interop**.
Это не установка отдельного Docker Engine в Ubuntu. Работающие проекты Docker Desktop
не перезапускались; настройки его интеграции не менялись.

Для продолжения работы откройте Ubuntu из PowerShell:

```powershell
wsl -d Ubuntu
```

В Bash:

```bash
cd /mnt/c/Users/stillmvd/Desktop/uuu/522/DockerCompose/joomla-docker
docker() { command docker.exe "$@" </dev/null; }
docker compose config --quiet
docker compose up -d
docker compose ps -a
```

Функция `docker` нужна только при выключенной интеграции Ubuntu. Перенаправление
stdin не позволяет Windows CLI читать текст выполняемого Bash-сценария.
При включённой интеграции можно использовать Linux-команду `docker` без этой функции.
Проверка сайта и автоматизация Chrome выполнялись в Windows, где доступен `localhost:8082`.

## Файлы и данные

- `compose.yaml` — два сервиса, сеть и постоянные тома.
- `.env.example` — шаблон переменных без действующих паролей.
- `.gitignore` — исключает `.env` и другие локальные env-файлы.
- `.env` — согласованные локальные пароли MariaDB из задания и случайный пароль
  администратора; этот файл не должен попадать в Git и скриншоты.
- `screenshots/` — изображения для сдачи.
- `db_data:/var/lib/mysql` — данные MariaDB.
- `joomla_data:/var/www/html` — файлы установленной Joomla и `configuration.php`.

В текущем локальном `.env` установлены именно учебные пароли базы из задания.
На новом компьютере скопируйте `.env.example` в `.env` и задайте согласованные пароли.
Сервисы получают пароль пользователя БД из одной переменной `MYSQL_PASSWORD`.
Переменные `JOOMLA_ADMIN_*` в `.env` хранят доступ для пользователя; установка
администратора уже выполнена через браузер, эти переменные не выполняют автоустановку.
Изменение пароля в `.env` не меняет пароль уже созданного пользователя в постоянной базе.

## Проверенные команды

```bash
uname -a
cat /etc/os-release
docker --version
docker compose version
docker compose ls
mkdir joomla-docker
cd joomla-docker
docker compose config
docker compose up -d
docker compose ls
docker compose ps -a
docker compose logs joomla
docker compose logs db
docker network inspect joomla-docker_joomla-network
docker compose stop
docker compose ps -a
docker compose start
docker compose restart
docker compose config
docker compose ps -a
```

Каталог, `compose.yaml`, `.env.example`, `.env` и `.gitignore` созданы командами Bash.
На Windows перед запуском проверено отсутствие слушателя на порту 8082.
Полный вывод `docker compose config` при проверке направлялся в `/dev/null`,
чтобы не раскрывать подставленные пароли; код завершения — 0.
Для безопасного самостоятельного просмотра используйте `docker compose config --quiet`.

Проверена общая сеть `joomla-docker_joomla-network`: в ней только два контейнера
этого проекта. Из PHP-контейнера выполнен настоящий SQL-запрос с данными из
`configuration.php`: имя сайта `Joomla Lab`, сервер `db`, база `joomla_db`,
версия MariaDB `11.5.2`, 76 таблиц. После stop/start/restart установка сохранена.

## Исправления и предупреждения

1. В инструкции ошибочно сказано, что `-d` означает существование директории.
   У `docker compose up -d` этот параметр означает запуск в фоновом режиме.
2. В комментарии к пробросу порта указан 82, но Apache слушает 80.
   Сохранён правильный проброс `8082:80`.
3. Краткий `depends_on: [db]` гарантирует порядок запуска, а не готовность базы.
   Добавлены штатный `healthcheck.sh` MariaDB и `condition: service_healthy`.
4. Пароли вынесены из Compose в игнорируемый `.env`; имя базы и пользователя,
   версии образов, сеть, тома и `restart: unless-stopped` соответствуют заданию.
5. Docker недоступен как Linux CLI в Ubuntu из-за выключенной интеграции.
   Использован работающий Windows CLI из Bash WSL, без вмешательства в другие проекты.
6. Apache выводит предупреждение `AH00558` о ServerName. MariaDB сообщает о
   недоступности io_uring и автоматически использует резервный режим ввода-вывода.
   Эти предупреждения не мешают работе; фатальных ошибок PHP или подключения к БД нет.

## Скриншоты для сдачи

| Файл | Что подтверждает |
| --- | --- |
| [01-installer.png](screenshots/01-installer.png) | Веб-установщик Joomla |
| [02-admin-setup.png](screenshots/02-admin-setup.png) | Настройка тестового администратора; пароль скрыт |
| [03-database-setup.png](screenshots/03-database-setup.png) | MySQLi, сервер db, пользователь и база; пароль скрыт |
| [04-installation-result.png](screenshots/04-installation-result.png) | Успешная установка |
| [05-admin-login.png](screenshots/05-admin-login.png) | Форма входа администратора |
| [06-admin-dashboard.png](screenshots/06-admin-dashboard.png) | Админ-панель после входа |
| [07-site.png](screenshots/07-site.png) | Главная страница установленной Joomla |
| [08-wsl-checks.png](screenshots/08-wsl-checks.png) | WSL, Compose, команды управления, сеть, SQL и HTTP |

`01`–`07` — снимки содержимого реальных страниц Chrome. `08` — снимок фактического
вывода команд WSL, отображённого в браузере для отчёта, а не окно терминала.
Если преподавателю нужен именно терминал, покажите `uname -a`, `docker compose ps -a`,
`docker compose ls` и логи в Ubuntu и снимите это окно. `.env` и полный вывод config
с паролями в скриншоты включать нельзя.

## Завершение

Joomla и MariaDB оставлены запущенными. WordPress, drawDB и остальные проекты
сохранены; их доступность проверена после управления контейнерами Joomla.
Ручное завершение установщика или удаление `installation` не требуется.
Проект, образы и тома не удалялись; очистка допускается только после отдельного
подтверждения пользователя по завершении сдачи.

## Фактический вывод итоговых проверок

Проверено: 20.11.2026, 13:38:27 (Москва). Все команды завершились с кодом 0.

```text
$ uname -a
Linux DESKTOP-Q4FTS4V 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64 GNU/Linux

$ cat /etc/os-release
PRETTY_NAME="Ubuntu 26.04 LTS"
NAME="Ubuntu"
VERSION_ID="26.04"
VERSION="26.04 (Resolute Raccoon)"
VERSION_CODENAME=resolute
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=resolute
LOGO=ubuntu-logo

$ docker --version
Docker version 29.7.2, build a7dcaa6

$ docker compose version
Docker Compose version v5.5.1

$ docker compose stop

$ docker compose ps -a (after stop)
NAME                     IMAGE            COMMAND                  SERVICE   CREATED         STATUS                              PORTS
joomla-docker-db-1       mariadb:11.5.2   "docker-entrypoint.s…"   db        4 minutes ago   Exited (0) Less than a second ago
joomla-docker-joomla-1   joomla:latest    "/entrypoint.sh apac…"   joomla    4 minutes ago   Exited (0) 1 second ago

$ docker compose start

$ docker compose restart

$ docker compose config
Exit code: 0 (output hidden: passwords)

$ docker compose ps -a (final)
NAME                     IMAGE            COMMAND                  SERVICE   CREATED         STATUS                   PORTS
joomla-docker-db-1       mariadb:11.5.2   "docker-entrypoint.s…"   db        4 minutes ago   Up 5 seconds (healthy)   3306/tcp
joomla-docker-joomla-1   joomla:latest    "/entrypoint.sh apac…"   joomla    4 minutes ago   Up 5 seconds             0.0.0.0:8082->80/tcp, [::]:8082->80/tcp

$ docker compose ls
NAME                STATUS              CONFIG FILES
dockercompose       running(2)          C:\Users\stillmvd\work\522\DockerCompose\compose.yaml
drawdb              running(1)          C:\Users\stillmvd\drawdb\compose.yml
joomla-docker       running(2)          C:\Users\stillmvd\Desktop\uuu\522\DockerCompose\joomla-docker\compose.yaml
wordpress           running(2)          C:\Users\stillmvd\Desktop\uuu\522\DockerCompose\wordpress\compose.yaml

$ docker compose logs joomla
Exit code: 0; full log reviewed, tail below.
joomla-1  | [Fri Nov 20 10:36:38.444300 2026] [mpm_prefork:notice] [pid 1:tid 1] AH00170: caught SIGWINCH, shutting down gracefully
joomla-1  | ========================================================================
joomla-1  |
joomla-1  | [INFO] Existing Joomla installation found; skipping initialization.
joomla-1  |
joomla-1  | ========================================================================
joomla-1  | AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.21.0.3. Set the 'ServerName' directive globally to suppress this message
joomla-1  | AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.21.0.3. Set the 'ServerName' directive globally to suppress this message
joomla-1  | [Fri Nov 20 10:36:39.883619 2026] [mpm_prefork:notice] [pid 1:tid 1] AH00163: Apache/2.4.71 (Debian) configured -- resuming normal operations
joomla-1  | [Fri Nov 20 10:36:39.883675 2026] [core:notice] [pid 1:tid 1] AH00094: Command line: 'apache2 -D FOREGROUND'

$ docker compose logs db
Exit code: 0; full log reviewed, tail below.
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: File system buffers for log disabled (block size=4096 bytes)
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: End of log at LSN=1990038
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: Opened 3 undo tablespaces
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: 128 rollback segments in 3 undo tablespaces are active.
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: Setting file './ibtmp1' size to 12.000MiB. Physically writing the file full; Please wait ...
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: File './ibtmp1' size is now 12.000MiB.
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: log sequence number 1990038; transaction id 1392
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: Loading buffer pool(s) from /var/lib/mysql/ib_buffer_pool
db-1  | 2026-11-20 10:36:39 0 [Note] Plugin 'FEEDBACK' is disabled.
db-1  | 2026-11-20 10:36:39 0 [Note] Plugin 'wsrep-provider' is disabled.
db-1  | 2026-11-20 10:36:39 0 [Note] InnoDB: Buffer pool(s) load completed at 261120 10:36:39
db-1  | 2026-11-20 10:36:40 0 [Note] Server socket created on IP: '0.0.0.0'.
db-1  | 2026-11-20 10:36:40 0 [Note] Server socket created on IP: '::'.
db-1  | 2026-11-20 10:36:40 0 [Note] mariadbd: Event Scheduler: Loaded 0 events
db-1  | 2026-11-20 10:36:40 0 [Note] mariadbd: ready for connections.
db-1  | Version: '11.5.2-MariaDB-ubu2404'  socket: '/run/mysqld/mysqld.sock'  port: 3306  mariadb.org binary distribution

$ docker network inspect joomla-docker_joomla-network (container names)
joomla-docker-joomla-1
joomla-docker-db-1


$ docker compose exec -T joomla php -r (SQL check using configuration.php, no credentials printed)
Site: Joomla Lab
Database host: db
Database: joomla_db
MariaDB: 11.5.2-MariaDB-ubu2404
Tables: 76
Installation directory: removed

$ HTTP checks (Windows localhost via curl.exe from WSL)
http://localhost:8082/ 200
http://localhost:8082/administrator/ 200
http://localhost:8081/ 200
http://localhost:5173/ 200
```
