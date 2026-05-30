
# iperf3 Profile Configurator — Руководство пользователя

## Обзор

**iperf3 Profile Configurator** — графический инструмент на PowerShell/WinForms для создания и управления профилями тестирования iperf3. Все профили хранятся в текстовом INI-файле. Сопутствующий CMD-скрипт читает этот файл и запускает тесты автоматически.

![](https://github.com/Varsett/pictures/blob/a034faf732db0af9a5a0588d7fe13609631eca1e/iPerfConfigurator_v1.25mail.jpg)
---

## Файлы

| Файл | Описание |
|------|----------|
| `iperf-configurator.ps1` | Основной скрипт конфигуратора |
| `iperf_profiles.ini` | Хранилище профилей (создаётся автоматически) |
| `iperf_parse.cmd` | CMD-сниппет для парсинга INI и запуска тестов |
| `runtest.flag` | Создаётся кнопкой **Run** — сигнал для CMD запустить очередь тестов |
| `runlive.flag` | Создаётся кнопкой **Run Live** — сигнал для CMD запустить живой тест |

Все файлы должны находиться в одной папке.

---

## Запуск

```bat
powershell -ExecutionPolicy Bypass -File "iperf-configurator.ps1"
```

Или из основного CMD-скрипта (ждёт закрытия конфигуратора, затем проверяет флаги):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1"

if exist "%~dp0runtest.flag"  del "%~dp0runtest.flag"  & call :_iPerfTest
if exist "%~dp0runlive.flag"  del "%~dp0runlive.flag"  & call :_iPerfLive
```

---

## Интерфейс

### Левая панель — Список профилей

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

---

## Кнопки

| Кнопка | Действие |
|--------|----------|
| **New** | Создаёт новый пустой профиль с именем по времени. |
| **Delete** | Удаляет выбранный профиль (с подтверждением). |
| **Save Profile** | Сохраняет текущий профиль в память (не на диск). |
| **Reload INI** | Перечитывает все профили из INI-файла. Несохранённые изменения теряются. |
| **Save INI** | Вызывает Save Profile, затем записывает все профили на диск. |
| **Run** | Сохраняет INI (спрашивает если есть несохранённые изменения), создаёт `runtest.flag`, закрывает окно. |
| **Run Live** | То же самое, но создаёт `runlive.flag`. |
| **?** | Открывает встроенную справку. |

**Предупреждение о несохранённых изменениях** — при закрытии окна или нажатии Run/Run Live с несохранёнными данными появится диалог с предложением сохранить.

---

## Создание профиля

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

---

## Формат INI-файла

```ini
[ProfileName]
host=192.168.1.1
port=
protocol=TCP
direction=Normal
bitrate=100
duration=10
interval=1
buflen=131072
streams=1
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

---

## Интеграция с CMD

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

---

## Механизм флаг-файлов

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
---
# iperf3 Profile Configurator — User Guide

## Overview

**iperf3 Profile Configurator** is a graphical PowerShell/WinForms tool for creating and managing iperf3 test profiles. All profiles are stored in a human-readable INI file. A companion CMD script reads this file and runs tests automatically.

---

## Files

| File | Description |
|------|-------------|
| `iperf-configurator.ps1` | Main configurator script |
| `iperf_profiles.ini` | Profile storage (created automatically) |
| `iperf_parse.cmd` | CMD snippet for parsing INI and running tests |
| `runtest.flag` | Created by **Run** — signals CMD to run queued tests |
| `runlive.flag` | Created by **Run Live** — signals CMD to run a live test |

All files must be in the same folder.

---

## Launching

```bat
powershell -ExecutionPolicy Bypass -File "iperf-configurator.ps1"
```

Or from your main CMD script (waits for configurator to close, then checks flags):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1"

if exist "%~dp0runtest.flag"  del "%~dp0runtest.flag"  & call :_iPerfTest
if exist "%~dp0runlive.flag"  del "%~dp0runlive.flag"  & call :_iPerfLive
```

---

## Interface

### Left Panel — Profile List

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

---

## Buttons

| Button | Action |
|--------|--------|
| **New** | Creates a new empty profile with a timestamped name. |
| **Delete** | Deletes the selected profile (with confirmation). |
| **Save Profile** | Saves current editor state to memory (not to disk yet). |
| **Reload INI** | Reloads all profiles from INI file. Discards unsaved changes. |
| **Save INI** | Calls Save Profile, then writes all profiles to disk. |
| **Run** | Saves INI (prompts if unsaved changes), creates `runtest.flag`, closes window. |
| **Run Live** | Same as Run, but creates `runlive.flag` instead. |
| **?** | Opens the built-in help dialog. |

**Unsaved changes warning** — closing the window or pressing Run/Run Live with unsaved changes triggers a save prompt.

---

## Creating a Profile

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

---

## INI File Format

```ini
[ProfileName]
host=192.168.1.1
port=
protocol=TCP
direction=Normal
bitrate=100
duration=10
interval=1
buflen=131072
streams=1
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

---

## CMD Integration

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

---

## Flag File Mechanism

A child PowerShell process cannot modify environment variables of the parent CMD — this is a fundamental Windows limitation. Communication between the configurator and CMD is therefore done via flag files:

```
CMD launches PS and waits for it to close
    --> user clicks Run --> runtest.flag is created --> PS closes
CMD checks: if exist runtest.flag --> deletes flag --> runs tests
```

- **Run** → `runtest.flag` → run full test suite across all active profiles
- **Run Live** → `runlive.flag` → run a live/immediate test (logic defined in your CMD)
- **Just closing the window** → no flags created → CMD continues without running tests

 
