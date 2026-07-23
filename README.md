<<<<<<< HEAD
# iperf3 Profile Configurator — Руководство пользователя
### (English manual below)

## Обзор

**iperf3 Profile Configurator** — графический инструмент на PowerShell/WinForms для создания и управления профилями тестирования iperf3. Профили хранятся в текстовом INI-файле. Сопутствующий CMD-сниппет читает файл и запускает тесты автоматически.

![](https://github.com/Varsett/pictures/blob/8211c004986e1895f7745ded55029b6352164702/iPerfConfigurator_v1.52.jpg)


=======

# iperf3 Profile Configurator
---
## Руководство пользователя/User manual  
### (The English version of the guide is below)
---
## Обзор

**iperf3 Profile Configurator** — графический инструмент на PowerShell/WinForms для создания и управления профилями тестирования iperf3. Все профили хранятся в текстовом INI-файле. Сопутствующий CMD-скрипт читает этот файл и запускает тесты автоматически.

![](https://github.com/Varsett/pictures/blob/a034faf732db0af9a5a0588d7fe13609631eca1e/iPerfConfigurator_v1.25mail.jpg)
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9
---

## Файлы

| Файл | Описание |
|------|----------|
| `iperf-configurator.ps1` | Основной скрипт конфигуратора |
| `iperf_profiles.ini` | Хранилище профилей (создаётся автоматически) |
| `iperf_parse.cmd` | CMD-сниппет для парсинга INI и запуска тестов |
<<<<<<< HEAD
| `runtest.flag` | Создаётся кнопкой **Run** — сигнал запустить очередь тестов |
| `runlive.flag` | Создаётся кнопкой **Run Live** — сигнал запустить живой тест |
=======
| `runtest.flag` | Создаётся кнопкой **Run** — сигнал для CMD запустить очередь тестов |
| `runlive.flag` | Создаётся кнопкой **Run Live** — сигнал для CMD запустить живой тест |
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

Все файлы должны находиться в одной папке.

---

<<<<<<< HEAD
## Параметр -WorkDir

Параметр `-WorkDir` задаёт папку, в которой создаются `iperf_profiles.ini` и флаг-файлы (`runtest.flag`, `runlive.flag`).

**Почему это важно:** если основной батник запакован в EXE (например через bat2exe), при запуске он распаковывается в `%TEMP%`. Переменная `$PSScriptRoot` в PowerShell будет указывать на `%TEMP%`, а не на папку с EXE. Передавая `-WorkDir "%~dp0"`, вы гарантируете, что INI и флаги создаются рядом с исходным CMD/EXE.

```bat
:: Правильный запуск — файлы создаются рядом с батником/EXE
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1" -WorkDir "%~dp0"

:: Без параметра — файлы создаются рядом с .ps1 скриптом (может быть в %TEMP%)
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1"
```

---

## Запуск

```bat
powershell -ExecutionPolicy Bypass -File "iperf-configurator.ps1" -WorkDir "%~dp0"
```

Из основного CMD-скрипта (рекомендуется всегда передавать `-WorkDir`):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1" -WorkDir "%~dp0"

if exist "%~dp0runtest.flag"  del "%~dp0runtest.flag"  & call :_RunTest
if exist "%~dp0runlive.flag"  del "%~dp0runlive.flag"  & call :_RunLive
=======
## Запуск

```bat
powershell -ExecutionPolicy Bypass -File "iperf-configurator.ps1"
```

Или из основного CMD-скрипта (ждёт закрытия конфигуратора, затем проверяет флаги):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1"

if exist "%~dp0runtest.flag"  del "%~dp0runtest.flag"  & call :_iPerfTest
if exist "%~dp0runlive.flag"  del "%~dp0runlive.flag"  & call :_iPerfLive
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9
```

---

## Интерфейс

### Левая панель — Список профилей

<<<<<<< HEAD
- Показывает все профили из INI-файла.
- **Чекбокс** рядом с именем — активность профиля:
  - Отмечен: активный, записывается как `===ProfileName` в INI.
  - Не отмечен: неактивный, записывается как `;===ProfileName`, весь блок закомментирован.
- Клик по имени загружает профиль в редактор.

### Правая панель — Редактор профиля

**Profile name** — имя профиля. Изменение имени и сохранение создаёт **новый** профиль, оригинал остаётся нетронутым.

**Template** — выпадающий список под полем имени. Выбор шаблона автоматически заполняет имя и параметры. После применения все поля остаются редактируемыми.

| Шаблон | Имя | Протокол | Buf len | Bitrate | Socket buf | Duration | Interval |
|--------|-----|----------|---------|---------|------------|----------|----------|
| Virtual Desktop | TEST_UDP_VD | UDP | 1450 | 300M | 2MB | 180s | 0.1 |
| Air Link | TEST_UDP_AirLink | UDP | 1440 | 200M | 4MB | 180s | 0.1 |
| Steam Link | TEST_UDP_SteamLink | UDP | 1400 | 300M | 1MB | 180s | 0.1 |
| ALVR | TEST_UDP_ALVR | UDP | 1440 | 400M | 1MB | 180s | 0.1 |

**Protocol / Direction** — всегда сохраняются, кнопка manual не нужна.

| Поле | Значение в INI |
|------|---------------|
| TCP | `protocol=` (пусто) |
| UDP | `protocol=-u` |
| Normal | `direction=` (пусто) |
| Reverse | `direction=-R` |

**Числовые параметры** — кнопка **manual**:
- **Серая** = дефолт, ключ пустой в INI.
- **Синяя** = ручной режим, значение сохраняется.
- Нажатие переводит фокус в поле автоматически.
- Серые числа — подсказки, не сохраняются.

| Поле | INI ключ | Флаг | Единица | Подсказка |
|------|----------|------|---------|-----------|
| Host / IP | `host` | `-c` | — | Авто-определение при нажатии **manual** (адаптер со шлюзом) |
| Port | `port` | `-p` | — | 5201 |
| Bitrate | `bitrate` | `-b` | Мбит/с | 100 |
| Duration | `duration` | `-t` | сек | 10 |
| Interval | `interval` | `-i` | сек | 1 |
| Buf len | `buflen` | `-l` | байты | 131072 (TCP) / 1460 (UDP) |
| Streams | `streams` | `-P` | — | 1 |
| Socket buf | `socketsize` | `-w` | МБ | 1 |
| TCP_NODELAY | `tcpnodelay` | `-N` | — | только TCP |
| Extra | `extra` | — | — | дописывается как есть |

**Host / IP** — при запуске IP определяется автоматически (адаптер со шлюзом, наименьшая метрика маршрута), кнопка **manual** включается сразу, IP виден в поле и в строке **Command preview** (`iperf3 -c 10.0.0.30`). Статус-бар показывает `Local IP: x.x.x.x`. При нажатии **manual** IP снова подставляется — можно отредактировать при необходимости.

**TCP_NODELAY** — тоггл без поля ввода. Синяя = `-N` в команде и INI. При UDP автоматически отключается.
=======
- Отображает все профили из INI-файла.
- **Чекбокс** рядом с именем управляет активностью профиля:
  - Отмечен = активный, записывается как `[ProfileName]` в INI.
  - Не отмечен = неактивный, записывается как `[;ProfileName]`, пропускается CMD-скриптом.
- Клик по имени профиля загружает его в редактор.

### Правая панель — Редактор профиля

**Имя профиля** — редактируемое поле вверху. Изменение имени и сохранение переименовывает профиль.

**Protocol / Direction** — всегда сохраняются, кнопка manual не нужна.

- Protocol: `TCP` или `UDP`
- Direction: `Normal` (клиент отправляет) или `Reverse` (сервер отправляет, флаг `-R`)

**Числовые параметры** — у каждого есть кнопка-переключатель **manual**:

- **Серая** = режим по умолчанию. Ключ записывается пустым в INI (например `bitrate=`), iperf3 использует свой дефолт.
- **Синяя** = ручной режим. Значение сохраняется и передаётся в iperf3.

Серые числа в пустых полях — это **только подсказки**, они не сохраняются пока не включён ручной режим.

| Поле | Флаг iperf3 | Единица | Примечание |
|------|-------------|---------|------------|
| Host / IP | `-c` | — | Адрес сервера. Обязателен для клиентского режима. |
| Port | `-p` | — | Порт сервера. По умолчанию: 5201. |
| Bitrate | `-b` | Мбит/с | UDP по умолчанию: 1M, TCP: без ограничений. |
| Duration | `-t` | сек | Длительность теста. По умолчанию: 10. |
| Interval | `-i` | сек | Интервал отчётов. По умолчанию: 1. |
| Block size | `-l` | байты | Подсказка для TCP: 131072, для UDP: 1460. Меняется автоматически при смене протокола. |
| Streams | `-P` | — | Параллельные потоки. По умолчанию: 1. |
| Buflen | `-w` | МБ | Размер сокетного буфера. По умолчанию: 1. |
| Extra params | — | — | Дополнительные флаги, добавляются в команду как есть. |

**Превью команды** — показывает собранную команду iperf3 в реальном времени.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Кнопки

| Кнопка | Действие |
|--------|----------|
<<<<<<< HEAD
| **New** | Новый пустой профиль (имя по времени). |
| **Delete** | Удалить выбранный профиль. |
| **Save Profile** | Сохранить в память (не на диск). |
| **Reload INI** | Перечитать с диска. Несохранённые изменения теряются. |
| **Save INI** | Записать все профили на диск (UTF-8, без BOM). |
| **Run** | Сохранить INI, создать `runtest.flag`, закрыть. |
| **Run Live** | Сохранить INI, создать `runlive.flag`, закрыть. |

> **Важно для Run Live:** Реалтайм-мониторинг работает **только** для протокола **UDP** (`-u`) и **только** в режиме **Reverse** (`-R`). Без этих параметров график будет пустым. Причина: в режиме Normal метрики (джиттер, потери, битрейт) выводятся на стороне сервера, а не клиента. В режиме Reverse сервер отправляет данные, клиент получает и измеряет все метрики локально. При нажатии **Run Live** конфигуратор проверяет активные профили и предупреждает если какой-то из них не имеет `-u` или `-R`.
| **?** | Встроенная справка. |

Статус-бар показывает время последней операции в формате `[HH:mm:ss]`.

При закрытии с несохранёнными изменениями — диалог Yes/No/Cancel.
=======
| **New** | Создаёт новый пустой профиль с именем по времени. |
| **Delete** | Удаляет выбранный профиль (с подтверждением). |
| **Save Profile** | Сохраняет текущий профиль в память (не на диск). |
| **Reload INI** | Перечитывает все профили из INI-файла. Несохранённые изменения теряются. |
| **Save INI** | Вызывает Save Profile, затем записывает все профили на диск. |
| **Run** | Сохраняет INI (спрашивает если есть несохранённые изменения), создаёт `runtest.flag`, закрывает окно. |
| **Run Live** | То же самое, но создаёт `runlive.flag`. |
| **?** | Открывает встроенную справку. |

**Предупреждение о несохранённых изменениях** — при закрытии окна или нажатии Run/Run Live с несохранёнными данными появится диалог с предложением сохранить.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Создание профиля

<<<<<<< HEAD
**Вариант А:** `New` → отредактировать имя → настроить параметры → `Save Profile` → `Save INI`.

**Вариант Б:** ввести имя вручную → настроить параметры → `Save Profile` (профиль создаётся автоматически) → `Save INI`.

**С шаблоном:** выбрать шаблон в Template → при необходимости отредактировать → `Save Profile` → `Save INI`.

**Переименование:** загрузить профиль → изменить имя → `Save Profile` → старый профиль остаётся, создаётся новый.
=======
**Вариант А — кнопка New:**
1. Нажать **New**.
2. Отредактировать имя в поле Profile name.
3. Настроить параметры, включить нужные переключатели manual.
4. Нажать **Save Profile**, затем **Save INI**.

**Вариант Б — ручной ввод имени:**
1. Ввести имя напрямую в поле Profile name.
2. Настроить параметры.
3. Нажать **Save Profile** — профиль создаётся автоматически.
4. Нажать **Save INI** для записи на диск.

**Переименование** — загрузить профиль, отредактировать поле имени, нажать **Save Profile**.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Формат INI-файла

```ini
<<<<<<< HEAD
===Test_TCP
host=192.168.1.1
port=
protocol=
direction=
=======
[ProfileName]
host=192.168.1.1
port=
protocol=TCP
direction=Normal
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9
bitrate=100
duration=10
interval=1
buflen=131072
streams=1
<<<<<<< HEAD
socketsize=1
tcpnodelay=
extra=

;===Test_UDP
;host=192.168.1.1
;port=
;protocol=-u
;direction=-R
;bitrate=300
;duration=180
;interval=0.1
;buflen=1460
;streams=1
;socketsize=2
;tcpnodelay=
;extra=
```

- `===ProfileName` — активный профиль.
- `;===ProfileName` — неактивный, весь блок с `;`.
- Пустая строка между блоками.
- Пустое значение = iperf3 дефолт.
- `protocol=-u`, `direction=-R`, `tcpnodelay=-N` — флаги хранятся напрямую.
=======
window=1
extra=

; ---
[;InactiveProfile]
host=
port=
protocol=UDP
direction=Reverse
bitrate=50
duration=30
interval=1
buflen=1460
streams=4
window=
extra=--get-server-output
```

- `[ProfileName]` — активный профиль.
- `[;ProfileName]` — неактивный (закомментированный), пропускается CMD.
- `; ---` — разделитель между профилями.
- Пустое значение (например `bitrate=`) означает использование дефолта iperf3.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Интеграция с CMD

<<<<<<< HEAD
Вставить содержимое `iperf_parse.cmd` в основной скрипт.

**Алгоритм парсера:**
- `===Name` → начало активного блока.
- `;` в начале строки → строка пропускается целиком.
- Каждый профиль записывается во временный файл `%TEMP%\ipc_*.tmp`, затем переменные экспортируются через `endlocal &` для избежания проблем с вложенными `setlocal`.

**Переменные в `:_RunTest` / `:_RunLive`:**

```
%host%  %port%  %protocol%  %direction%
%bitrate%  %duration%  %interval%
%buflen%  %streams%  %socketsize%
%tcpnodelay%  %extra%
```
=======
Вставьте содержимое `iperf_parse.cmd` в основной скрипт. Сниппет:

1. Проверяет наличие `runtest.flag` — если найден, удаляет его и перебирает все активные профили, вызывая `:_iPerfTest` для каждого.
2. Неактивные профили (секции `[;Name]`) автоматически пропускаются.
3. Все 11 параметров INI раскладываются в CMD-переменные для подстановки в команду запуска.

**Доступные переменные внутри `:_iPerfTest`:**

| Переменная | Ключ INI | Описание |
|------------|----------|----------|
| `%ipaddrtxt%` | host | IP/hostname сервера |
| `%itime%` | duration | Длительность теста |
| `%iinterval%` | interval | Интервал отчётов |
| `%bndwidth%` | bitrate | Битрейт в Мбит/с |
| `%qstreams%` | streams | Параллельные потоки |
| `!_udp!` | protocol | `-u` если UDP, пусто если TCP |
| `!_rev!` | direction | `-R` если Reverse, пусто если Normal |
| `!_port!` | port | `-p NNNN` или пусто |
| `!_buf!` | buflen | `-l NNNN` или пусто |
| `!_win!` | window | `-w NM` или пусто |
| `!P_EXTRA!` | extra | Дополнительные флаги как есть |

Отредактируйте секцию `:_iPerfTest` в файле `iperf_parse.cmd` — вставьте туда свою реальную команду запуска теста.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Механизм флаг-файлов

<<<<<<< HEAD
PowerShell не может изменить переменные родительского CMD. Флаг-файлы — единственный надёжный способ:

```
CMD запускает PS и ждёт
  Run нажата -> runtest.flag создан -> PS закрывается
CMD: if exist runtest.flag -> удалить -> запустить тесты
```

- **Run** → `runtest.flag` → `:_RunTest` для каждого активного профиля
- **Run Live** → `runlive.flag` → `:_RunLive` для каждого активного профиля
- **Закрыть без Run** → флаги не создаются

---

=======
Дочерний процесс PowerShell не может изменить переменные окружения родительского CMD — это фундаментальное ограничение Windows. Поэтому связь между конфигуратором и CMD реализована через файлы-флаги:

```
CMD запускает PS и ждёт закрытия
    --> пользователь нажимает Run --> создаётся runtest.flag --> PS закрывается
CMD проверяет: if exist runtest.flag --> удаляет флаг --> запускает тесты
```

- **Run** → `runtest.flag` → запуск серии тестов по всем активным профилям
- **Run Live** → `runlive.flag` → запуск живого теста (логику определяете сами в CMD)
- **Просто закрыть окно** → флаги не создаются → CMD продолжает без тестов
---
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9
---
# iperf3 Profile Configurator — User Guide

## Overview

<<<<<<< HEAD
**iperf3 Profile Configurator** is a graphical PowerShell/WinForms tool for creating and managing iperf3 test profiles. Profiles are stored in a plain-text INI file. A companion CMD snippet reads the file and runs tests automatically.
=======
**iperf3 Profile Configurator** is a graphical PowerShell/WinForms tool for creating and managing iperf3 test profiles. All profiles are stored in a human-readable INI file. A companion CMD script reads this file and runs tests automatically.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Files

| File | Description |
|------|-------------|
| `iperf-configurator.ps1` | Main configurator script |
| `iperf_profiles.ini` | Profile storage (created automatically) |
<<<<<<< HEAD
| `iperf_parse.cmd` | CMD snippet — parse INI and run tests |
| `runtest.flag` | Created by **Run** — signals CMD to run queued tests |
| `runlive.flag` | Created by **Run Live** — signals CMD to run live tests |

All files must reside in the same folder.

---

## The -WorkDir Parameter

`-WorkDir` specifies the folder where `iperf_profiles.ini` and flag files (`runtest.flag`, `runlive.flag`) are created.

**Why this matters:** if your main CMD script is packed into an EXE (e.g. via bat2exe), it unpacks to `%TEMP%` at runtime. PowerShell's `$PSScriptRoot` would then point to `%TEMP%`, not your EXE's folder. Passing `-WorkDir "%~dp0"` ensures INI and flag files are created next to your CMD/EXE.

```bat
:: Recommended — files are created next to the CMD/EXE
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1" -WorkDir "%~dp0"

:: Without parameter — files go next to the .ps1 script (may be %TEMP%)
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1"
```
=======
| `iperf_parse.cmd` | CMD snippet for parsing INI and running tests |
| `runtest.flag` | Created by **Run** — signals CMD to run queued tests |
| `runlive.flag` | Created by **Run Live** — signals CMD to run a live test |

All files must be in the same folder.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Launching

```bat
<<<<<<< HEAD
powershell -ExecutionPolicy Bypass -File "iperf-configurator.ps1" -WorkDir "%~dp0"
```

From your main CMD script (always pass `-WorkDir` for reliable file placement):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1" -WorkDir "%~dp0"

if exist "%~dp0runtest.flag"  del "%~dp0runtest.flag"  & call :_RunTest
if exist "%~dp0runlive.flag"  del "%~dp0runlive.flag"  & call :_RunLive
=======
powershell -ExecutionPolicy Bypass -File "iperf-configurator.ps1"
```

Or from your main CMD script (waits for configurator to close, then checks flags):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1"

if exist "%~dp0runtest.flag"  del "%~dp0runtest.flag"  & call :_iPerfTest
if exist "%~dp0runlive.flag"  del "%~dp0runlive.flag"  & call :_iPerfLive
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9
```

---

## Interface

### Left Panel — Profile List

<<<<<<< HEAD
- Lists all profiles from the INI file.
- **Checkbox** = active/inactive:
  - Checked: active, stored as `===ProfileName` in INI.
  - Unchecked: inactive, stored as `;===ProfileName`, entire block commented out.
- Click a name to load it into the editor.

### Right Panel — Profile Editor

**Profile name** — changing the name and saving creates a **new** profile; the original stays intact.

**Template** — dropdown below the name field. Selecting a preset auto-fills name and parameters. All fields remain editable after applying.

| Template | Name | Protocol | Buf len | Bitrate | Socket buf | Duration | Interval |
|----------|------|----------|---------|---------|------------|----------|----------|
| Virtual Desktop | TEST_UDP_VD | UDP | 1450 | 300M | 2MB | 180s | 0.1 |
| Air Link | TEST_UDP_AirLink | UDP | 1440 | 200M | 4MB | 180s | 0.1 |
| Steam Link | TEST_UDP_SteamLink | UDP | 1400 | 300M | 1MB | 180s | 0.1 |
| ALVR | TEST_UDP_ALVR | UDP | 1440 | 400M | 1MB | 180s | 0.1 |

**Protocol / Direction** — always saved, no manual toggle needed.

| Field | INI value |
|-------|-----------|
| TCP | `protocol=` (empty) |
| UDP | `protocol=-u` |
| Normal | `direction=` (empty) |
| Reverse | `direction=-R` |

**Numeric parameters** — **manual** toggle button:
- **Gray** = default mode, key written empty in INI.
- **Blue** = manual mode, value saved and passed to iperf3.
- Clicking moves focus to the field automatically.
- Gray numbers are hints only, not saved.

| Field | INI key | Flag | Unit | Hint |
|-------|---------|------|------|------|
| Host / IP | `host` | `-c` | — | Auto-detected on **manual** click (adapter with gateway) |
| Port | `port` | `-p` | — | 5201 |
| Bitrate | `bitrate` | `-b` | Mbps | 100 |
| Duration | `duration` | `-t` | sec | 10 |
| Interval | `interval` | `-i` | sec | 1 |
| Buf len | `buflen` | `-l` | bytes | 131072 (TCP) / 1460 (UDP) |
| Streams | `streams` | `-P` | — | 1 |
| Socket buf | `socketsize` | `-w` | MB | 1 |
| TCP_NODELAY | `tcpnodelay` | `-N` | — | TCP only |
| Extra | `extra` | — | — | verbatim append |

**Host / IP** — on startup the local IP is detected automatically (adapter with default gateway, lowest route metric), the **manual** toggle is enabled immediately, and the IP appears in the field and in the **Command preview** line (`iperf3 -c 10.0.0.30`). The status bar shows `Local IP: x.x.x.x`. Clicking **manual** re-fills the detected IP — editable if needed.

**TCP_NODELAY** — toggle only, no text entry. Blue = `-N` in command and INI. Auto-disabled when UDP selected.
=======
- Shows all profiles from the INI file.
- **Checkbox** next to each name controls active/inactive state:
  - Checked = active, written as `[ProfileName]` in INI.
  - Unchecked = inactive, written as `[;ProfileName]`, skipped by CMD.
- Click a profile name to load it into the editor.

### Right Panel — Profile Editor

**Profile name** — editable field at the top. Renaming and saving renames the profile.

**Protocol / Direction** — always saved, no manual toggle needed.

- Protocol: `TCP` or `UDP`
- Direction: `Normal` (client sends) or `Reverse` (server sends, `-R` flag)

**Numeric parameters** — each has a **manual** toggle button:

- **Gray** = default mode. Key written empty in INI (e.g. `bitrate=`), iperf3 uses its built-in default.
- **Blue** = manual mode. Value is saved and passed to iperf3.

Gray numbers in empty fields are **hints only** — not saved until manual mode is enabled.

| Field | iperf3 flag | Unit | Notes |
|-------|-------------|------|-------|
| Host / IP | `-c` | — | Server address. Required for client mode. |
| Port | `-p` | — | Server port. Default: 5201. |
| Bitrate | `-b` | Mbps | UDP default: 1M, TCP: unlimited. |
| Duration | `-t` | sec | Test duration. Default: 10. |
| Interval | `-i` | sec | Report interval. Default: 1. |
| Block size | `-l` | bytes | TCP hint: 131072. UDP hint: 1460. Updates automatically when Protocol is switched. |
| Streams | `-P` | — | Parallel streams. Default: 1. |
| Buflen | `-w` | MB | Socket buffer size. Default: 1. |
| Extra params | — | — | Appended verbatim to the command line. |

**Command preview** — shows the assembled iperf3 command in real time.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Buttons

| Button | Action |
|--------|--------|
<<<<<<< HEAD
| **New** | New empty profile (timestamped name). |
| **Delete** | Delete selected profile (with confirmation). |
| **Save Profile** | Save to memory (not to disk yet). |
| **Reload INI** | Reload from disk. Unsaved changes discarded. |
| **Save INI** | Write all profiles to disk (UTF-8, no BOM). |
| **Run** | Save INI, create `runtest.flag`, close window. |
| **Run Live** | Save INI, create `runlive.flag`, close window. |

> **Important for Run Live:** Real-time monitoring works **only** with **UDP** protocol (`-u`) and **only** in **Reverse** mode (`-R`). Without these, the graph will be empty. Reason: in Normal mode metrics (jitter, loss, bitrate) are reported server-side, not on the client. In Reverse mode the server sends data and the client measures all metrics locally. Clicking **Run Live** checks active profiles and warns if any lack `-u` or `-R`.
| **?** | Built-in help dialog. |

Status bar shows timestamp `[HH:mm:ss]` for each operation.
On close with unsaved changes: Yes/No/Cancel prompt.
=======
| **New** | Creates a new empty profile with a timestamped name. |
| **Delete** | Deletes the selected profile (with confirmation). |
| **Save Profile** | Saves current editor state to memory (not to disk yet). |
| **Reload INI** | Reloads all profiles from INI file. Discards unsaved changes. |
| **Save INI** | Calls Save Profile, then writes all profiles to disk. |
| **Run** | Saves INI (prompts if unsaved changes), creates `runtest.flag`, closes window. |
| **Run Live** | Same as Run, but creates `runlive.flag` instead. |
| **?** | Opens the built-in help dialog. |

**Unsaved changes warning** — closing the window or pressing Run/Run Live with unsaved changes triggers a save prompt.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Creating a Profile

<<<<<<< HEAD
**Option A:** `New` → edit name → set params → `Save Profile` → `Save INI`.

**Option B:** type name → set params → `Save Profile` (auto-creates) → `Save INI`.

**With template:** choose template → optionally edit → `Save Profile` → `Save INI`.

**Renaming:** load profile → change name → `Save Profile` → original kept, new one created.
=======
**Option A — New button:**
1. Click **New**.
2. Edit the name in the Profile name field.
3. Set parameters, enable manual toggles as needed.
4. Click **Save Profile**, then **Save INI**.

**Option B — Manual name entry:**
1. Type a name directly in the Profile name field.
2. Set parameters.
3. Click **Save Profile** — a new profile is created automatically.
4. Click **Save INI** to write to disk.

**Renaming** — load a profile, edit the name field, click **Save Profile**.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## INI File Format

```ini
<<<<<<< HEAD
===Test_TCP
host=192.168.1.1
port=
protocol=
direction=
=======
[ProfileName]
host=192.168.1.1
port=
protocol=TCP
direction=Normal
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9
bitrate=100
duration=10
interval=1
buflen=131072
streams=1
<<<<<<< HEAD
socketsize=1
tcpnodelay=
extra=

;===Test_UDP
;host=192.168.1.1
;port=
;protocol=-u
;direction=-R
;bitrate=300
;duration=180
;interval=0.1
;buflen=1460
;streams=1
;socketsize=2
;tcpnodelay=
;extra=
```

- `===ProfileName` — active profile.
- `;===ProfileName` — inactive; entire block prefixed with `;`.
- Empty line between profiles.
- Empty value = iperf3 default.
- `protocol=-u`, `direction=-R`, `tcpnodelay=-N` — flags stored directly.
=======
window=1
extra=

; ---
[;InactiveProfile]
host=
port=
protocol=UDP
direction=Reverse
bitrate=50
duration=30
interval=1
buflen=1460
streams=4
window=
extra=--get-server-output
```

- `[ProfileName]` — active profile.
- `[;ProfileName]` — inactive (commented out), skipped by CMD.
- `; ---` — separator between profiles.
- Empty value (e.g. `bitrate=`) means use iperf3 default.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## CMD Integration

<<<<<<< HEAD
Paste `iperf_parse.cmd` into your main script.

**Parser algorithm:**
- `===Name` → start of active block.
- Lines starting with `;` → skipped entirely.
- Each profile is written to `%TEMP%\ipc_*.tmp`, variables exported via `endlocal &` to avoid nested `setlocal` issues.

**Variables in `:_RunTest` / `:_RunLive`:**

```
%host%  %port%  %protocol%  %direction%
%bitrate%  %duration%  %interval%
%buflen%  %streams%  %socketsize%
%tcpnodelay%  %extra%
```
=======
Include the contents of `iperf_parse.cmd` in your main script. The snippet:

1. Checks for `runtest.flag` — if found, deletes it and iterates all active profiles, calling `:_iPerfTest` for each.
2. Skips inactive profiles (`[;Name]` sections) automatically.
3. Maps all 11 INI parameters to CMD variables for use in your launch command.

**Available variables inside `:_iPerfTest`:**

| Variable | INI key | Description |
|----------|---------|-------------|
| `%ipaddrtxt%` | host | Server IP/hostname |
| `%itime%` | duration | Test duration |
| `%iinterval%` | interval | Report interval |
| `%bndwidth%` | bitrate | Bitrate in Mbps |
| `%qstreams%` | streams | Parallel streams |
| `!_udp!` | protocol | `-u` if UDP, empty if TCP |
| `!_rev!` | direction | `-R` if Reverse, empty if Normal |
| `!_port!` | port | `-p NNNN` or empty |
| `!_buf!` | buflen | `-l NNNN` or empty |
| `!_win!` | window | `-w NM` or empty |
| `!P_EXTRA!` | extra | Extra flags verbatim |

Edit the `:_iPerfTest` section in `iperf_parse.cmd` with your actual launch command.
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9

---

## Flag File Mechanism

<<<<<<< HEAD
PowerShell cannot modify parent CMD environment variables — Windows OS limitation. Flag files are the only reliable cross-process signal:

```
CMD launches PS and waits
  Run clicked -> runtest.flag created -> PS closes
CMD: if exist runtest.flag -> delete -> run tests
```

- **Run** → `runtest.flag` → `:_RunTest` per active profile
- **Run Live** → `runlive.flag` → `:_RunLive` per active profile
- **Just close** → no flags created
=======
A child PowerShell process cannot modify environment variables of the parent CMD — this is a fundamental Windows limitation. Communication between the configurator and CMD is therefore done via flag files:

```
CMD launches PS and waits for it to close
    --> user clicks Run --> runtest.flag is created --> PS closes
CMD checks: if exist runtest.flag --> deletes flag --> runs tests
```

- **Run** → `runtest.flag` → run full test suite across all active profiles
- **Run Live** → `runlive.flag` → run a live/immediate test (logic defined in your CMD)
- **Just closing the window** → no flags created → CMD continues without running tests

 
>>>>>>> c0162fb336ae7c485f709949a8f46cf2711bffd9
