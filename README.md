# iperf3 Profile Configurator — Руководство пользователя
### (English manual below)

## Обзор

**iperf3 Profile Configurator** — графический инструмент на PowerShell/WinForms для создания и управления профилями тестирования iperf3. Профили хранятся в текстовом INI-файле. Сопутствующий CMD-сниппет читает файл и запускает тесты автоматически.

![](https://github.com/Varsett/pictures/blob/8211c004986e1895f7745ded55029b6352164702/iPerfConfigurator_v1.52.jpg)

---

## Файлы

| Файл | Описание |
|------|----------|
| `iperf-configurator.ps1` | Основной скрипт конфигуратора |
| `iperf_profiles.ini` | Хранилище профилей (создаётся автоматически) |
| `iperf_parse.cmd` | CMD-сниппет для парсинга INI и запуска тестов |
| `runtest.flag` | Создаётся кнопкой **Run** — сигнал запустить очередь тестов |
| `runlive.flag` | Создаётся кнопкой **Run Live** — сигнал запустить живой тест |

Все файлы должны находиться в одной папке.

---

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
```

---

## Интерфейс

### Левая панель — Список профилей

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
| Standard 0 | TEST_UDP_STD0 | UDP | 1460 | 0M | 1MB | 180s | 0.1 |
| Standard 600 | TEST_UDP_STD_600 | UDP | 1460 | 600M | 1MB | 180s | 0.1 |



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

---

## Кнопки

| Кнопка | Действие |
|--------|----------|
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

---

## Создание профиля

**Вариант А:** `New` → отредактировать имя → настроить параметры → `Save Profile` → `Save INI`.

**Вариант Б:** ввести имя вручную → настроить параметры → `Save Profile` (профиль создаётся автоматически) → `Save INI`.

**С шаблоном:** выбрать шаблон в Template → при необходимости отредактировать → `Save Profile` → `Save INI`.

**Переименование:** загрузить профиль → изменить имя → `Save Profile` → старый профиль остаётся, создаётся новый.

---

## Формат INI-файла

```ini
===Test_TCP
host=192.168.1.1
port=
protocol=
direction=
bitrate=100
duration=10
interval=1
buflen=131072
streams=1
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

---

## Интеграция с CMD

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

---

## Механизм флаг-файлов

PowerShell не может изменить переменные родительского CMD. Флаг-файлы — единственный надёжный способ:

```
CMD запускает PS и ждёт
  Run нажата -> runtest.flag создан -> PS закрывается
CMD: if exist runtest.flag -> удалить -> запустить тесты
```

- **Run** → `runtest.flag` → `:_RunTest` для каждого активного профиля
- **Run Live** → `runlive.flag` → `:_RunLive` для каждого активного профиля
- **Закрыть без Run** → флаги не создаются

- ---

---
# iperf3 Profile Configurator — User Guide

## Overview

**iperf3 Profile Configurator** is a graphical PowerShell/WinForms tool for creating and managing iperf3 test profiles. Profiles are stored in a plain-text INI file. A companion CMD snippet reads the file and runs tests automatically.

---

## Files

| File | Description |
|------|-------------|
| `iperf-configurator.ps1` | Main configurator script |
| `iperf_profiles.ini` | Profile storage (created automatically) |
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

---

## Launching

```bat
powershell -ExecutionPolicy Bypass -File "iperf-configurator.ps1" -WorkDir "%~dp0"
```

From your main CMD script (always pass `-WorkDir` for reliable file placement):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0iperf-configurator.ps1" -WorkDir "%~dp0"

if exist "%~dp0runtest.flag"  del "%~dp0runtest.flag"  & call :_RunTest
if exist "%~dp0runlive.flag"  del "%~dp0runlive.flag"  & call :_RunLive
```

---

## Interface

### Left Panel — Profile List

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

---

## Buttons

| Button | Action |
|--------|--------|
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

---

## Creating a Profile

**Option A:** `New` → edit name → set params → `Save Profile` → `Save INI`.

**Option B:** type name → set params → `Save Profile` (auto-creates) → `Save INI`.

**With template:** choose template → optionally edit → `Save Profile` → `Save INI`.

**Renaming:** load profile → change name → `Save Profile` → original kept, new one created.

---

## INI File Format

```ini
===Test_TCP
host=192.168.1.1
port=
protocol=
direction=
bitrate=100
duration=10
interval=1
buflen=131072
streams=1
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

---

## CMD Integration

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

---

## Flag File Mechanism

PowerShell cannot modify parent CMD environment variables — Windows OS limitation. Flag files are the only reliable cross-process signal:

```
CMD launches PS and waits
  Run clicked -> runtest.flag created -> PS closes
CMD: if exist runtest.flag -> delete -> run tests
```

- **Run** → `runtest.flag` → `:_RunTest` per active profile
- **Run Live** → `runlive.flag` → `:_RunLive` per active profile
- **Just close** → no flags created
