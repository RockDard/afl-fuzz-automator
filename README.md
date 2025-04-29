# run_afl.sh

<p align="center">🚀 **Автоматизация фазинг-тестирования (AFL++)** / **Fuzz Testing Automation (AFL++)** 🚀</p>

---

## 🌐 Overview / Обзор

**run_afl.sh** — интерактивный Bash-скрипт для упрощения запуска **AFL++**, автоматизирующий установку инструментов, сборку, подготовку seed-файлов и выбор бинарей.

run_afl.sh is an interactive Bash script that streamlines running **AFL++**, automating tool installation, build instrumentation, seed file preparation, and binary selection.

---

## 🚀 Features / Возможности

| English                                           | Русский                                                  |
|---------------------------------------------------|----------------------------------------------------------|
| Linux-only check                                  | Проверка запуска только на Linux                         |
| Single ASCII header                               | Единичный вывод ASCII-шапки                             |
| Interactive prompts (with `read -e`)              | Интерактивные подсказки с автодополнением                |
| Language selection: EN / RU                       | Выбор языка интерфейса: EN / RU                          |
| Auto-install: `afl-fuzz`, `afl-grammar`, `cmake`  | Автоустановка: `afl-fuzz`, `afl-grammar`, `cmake`        |
| Core dumps handling fix (`core_pattern`)          | Исправление `core_pattern` (AFL_I_DONT_CARE...)          |
| CMake build with AFL instrumentation              | Сборка через CMake с инструментированием AFL            |
| Grammar-based seed generation (BNF, ANTLR, YACC)  | Генеративный режим seed на основе грамматик             |
| Real/example seeds fallback or dummy seed         | Использование `examples/`, `tests/`, `sample/` или dummy |
| Auto-detect binaries in `build/` and project root | Автообнаружение бинарей в `build/` и корне проекта      |
| Customizable timeouts, memory limits, args        | Настраиваемые таймаут, лимит памяти и аргументы         |
| Final `afl-fuzz` exec via `exec`                  | Финальный запуск `afl-fuzz` через `exec`                |

---

## 📋 Requirements / Требования

**Linux** (Ubuntu/Debian/Fedora и аналогичные)  
**Bash 4+** с поддержкой `read -e`, `mapfile`  
`sudo` (для автоустановки через `apt-get`) или `brew` (Mac)

---

## 🛠 Installation / Установка

1. **Download** / **Скачать**:
   ```bash
   wget https://example.com/run_afl.sh -O run_afl.sh
   chmod +x run_afl.sh
   ```
2. **Ensure permissions** / **Права**:
   ```bash
   sudo apt-get update && sudo apt-get install -y afl++ cmake
   ```

---

## ⚙️ Usage / Использование

1. **Start script** / **Запустить**:
   ```bash
   ./run_afl.sh
   ```
2. **Follow steps** / **Шаги**:
   - Select language (`en`/`ru`). / Выбрать язык (`en`/`ru`).
   - Specify project directory (default current). / Указать директорию проекта.
   - Script auto-installs dependencies. / Скрипт автоустанавливает зависимости.
   - Fixes core dumps. / Исправляет core_pattern.
   - Builds via CMake (if present). / Сборка через CMake.
   - Finds grammar files for seed generation. / Генерация seed по грамматикам.
   - Copies real seeds or creates dummy. / Копирование/создание seed.
   - Detects binaries for fuzzing. / Обнаружение бинарей.
   - Ask output dir, timeout, memory limit, args. / Ввод результата, таймаута, памяти, аргументов.
   - Launches `afl-fuzz`. / Запускает `afl-fuzz`.

**Example:**
```
Found binaries:
[0] build/my_app
[1] ./my_app
Select binary by number (Enter to skip): 0
Running: afl-fuzz -i ./seeds -o findings/ -t 1000 -m 100 -- build/my_app
```

---

## 🔧 Configuration / Настройка

- **Dictionary**: add `-x path/to/dict` to `CMD` array. / Добавить `-x path/to/dict`.
- **AFL flags**: edit `CMD` in the script. / Править массив `CMD`.
- **Paths**: change defaults (`seeds`, `findings`). / Изменить пути по умолчанию.

---

## 🆘 Troubleshooting / Ошибки

| Issue                                           | Solution                                                        |
|-------------------------------------------------|-----------------------------------------------------------------|
| `QJsonObject file not found`                    | Install Qt dev (`qtbase5-dev`). / Установить `qtbase5-dev`.    |
| Core dumps delay / missing crashes              | Script sets `AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1`. / Скрипт устанавливает переменную. |
| No binaries found                               | Use QEMU mode or add test harness. / Использовать QEMU или добавить test harness. |

---

## ❤️ Acknowledgments / Благодарности

Created by **RockDar**. Inspired by **AFL++** & **honggfuzz**.

---

<sub>Version 2.0.2 • 2025‑04‑23</sub>
