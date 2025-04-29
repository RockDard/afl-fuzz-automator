#!/usr/bin/env bash

# --- Ensure running on Linux only ---
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Error: This script supports only Linux." >&2
  exit 1
fi

###############################################################################
#  ____            _       _   _____      _                                  #
# |  _ \ __ _  ___| | ____| | |  ___|   _(_) ___ ___  ___                   #
# | |_) / _` |/ __| |/ / _` | | |_ | | | | |/ __/ _ \/ __|                  #
# |  __/ (_| | (__|   < (_| | |  _|| |_| | | (_|  __/\__ \                  #
# |_|   \__,_|\___|_|\_\\__,_| |_|   \__,_|_|\___\___||___/                  #
#                                                                             #
# run_afl.sh — автоматизация фазинг-тестирования (AFL++)                       #
# Version: 2.0.2 | Author: RockDar 🫡 | Date: 2025-04-23                        #
###############################################################################

# Ensure interactive shell for read -e
if [[ $- != *i* ]]; then
  exec bash -i "$0" "$@"
fi

set -euo pipefail

# --- Display header once ---
display_header() {
  cat << 'EOF'
###############################################################################
#  ____            _       _   _____      _                                  #
# |  _ \ __ _  ___| | ____| | |  ___|   _(_) ___ ___  ___                   #
# | |_) / _` |/ __| |/ / _` | | |_ | | | | |/ __/ _ \/ __|                  #
# |  __/ (_| | (__|   < (_| | |  _|| |_| | | (_|  __/\__ \                  #
# |_|   \__,_|\___|_|\_\\__,_| |_|   \__,_|_|\___\___||___/                  #
#                                                                             #
# run_afl.sh — автоматизация фазинг-тестирования (AFL++)                       #
# Version: 2.0.2 | Author: RockDar 🫡 | Date: 2025-04-23                        #
###############################################################################
EOF
}
display_header

# --- Language selection ---
read -p "Select interface language (en/ru) [en]: " LANG
LANG=${LANG:-en}
case "$LANG" in
  ru)
    MSG_PROJ="Введите директорию проекта"
    MSG_SEED="Введите директорию seed-файлов"
    MSG_OUT="Введите директорию результатов"
    ;;
  *)
    MSG_PROJ="Enter project directory"
    MSG_SEED="Enter seed directory"
    MSG_OUT="Enter output directory"
    ;;
esac

# --- Project root selection ---
default_proj="$(pwd)"
read -e -i "$default_proj" -p "$MSG_PROJ [${default_proj}]: " PROJECT_ROOT
PROJECT_ROOT=${PROJECT_ROOT:-$default_proj}
cd "$PROJECT_ROOT"

# --- Ensure required tools are installed ---
install_tool() {
  local cmd="$1" pkg="$2"
  if ! command -v "$cmd" &>/dev/null; then
    echo "Installing $cmd..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y "$pkg"
    elif command -v brew &>/dev/null; then
      brew install "$pkg"
    else
      echo "Please install $cmd manually" >&2
      exit 1
    fi
  fi
}
install_tool afl-fuzz afl++
install_tool afl-grammar afl++
install_tool cmake cmake

# --- Core dump handling fix ---
if grep -q '^|' /proc/sys/kernel/core_pattern 2>/dev/null; then
  export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
  echo "Set AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1"
fi

# --- Build project with AFL instrumentation if CMakeLists.txt exists ---
if [[ -f "CMakeLists.txt" ]]; then
  mkdir -p build && cd build
  CC=afl-clang-fast CXX=afl-clang-fast++ cmake ..
  make -j"$(nproc)"
  cd "$PROJECT_ROOT"
fi

# --- Search for grammar files ---
mapfile -t GRAMMARS < <(find . -maxdepth 2 -type f \( -iname "*.bnf" -o -iname "*.g4" -o -iname "*.y" \))
if (( ${#GRAMMARS[@]} > 0 )); then
  echo "Found grammar files:"
  for i in "${!GRAMMARS[@]}"; do echo "[$i] ${GRAMMARS[$i]}"; done
  read -p "Select grammar by number (or Enter to skip): " sel
  if [[ "$sel" =~ ^[0-9]+$ && -n "${GRAMMARS[$sel]}" ]]; then
    GRAMMAR_FILE="${GRAMMARS[$sel]}"
  fi
fi

# --- Prepare seed directory ---
read -e -i "${PROJECT_ROOT}/seeds" -p "$MSG_SEED [${PROJECT_ROOT}/seeds]: " SEED_DIR
SEED_DIR=${SEED_DIR:-"${PROJECT_ROOT}/seeds"}

if [[ -n "${GRAMMAR_FILE:-}" ]]; then
  read -p "Use grammar-based generation? (y/N): " useg
  if [[ "$useg" =~ ^[Yy]$ ]]; then
    read -p "How many seeds to generate? [100]: " cnt
    cnt=${cnt:-100}
    mkdir -p "$SEED_DIR/grammar"
    afl-grammar -g "$GRAMMAR_FILE" -i "$cnt" -o "$SEED_DIR/grammar"
    SEED_DIR="$SEED_DIR/grammar"
  fi
else
  mapfile -t EXS < <(find examples tests sample -type f 2>/dev/null)
  mkdir -p "$SEED_DIR"
  if (( ${#EXS[@]} > 0 )); then
    cp -r "${EXS[@]}" "$SEED_DIR/"
  else
    echo "A" > "$SEED_DIR/seed1"
  fi
fi

# --- Auto-detect target binary ---
mapfile -t BINS < <(find build . -maxdepth 2 -type f -executable 2>/dev/null)
TARGET_BINARY=""
if (( ${#BINS[@]} > 0 )); then
  echo "Found binaries:"
  for i in "${!BINS[@]}"; do echo "[$i] ${BINS[$i]}"; done
  read -p "Select binary by number (or Enter to specify manually): " bin_sel
  if [[ "$bin_sel" =~ ^[0-9]+$ && -n "${BINS[$bin_sel]}" ]]; then
    TARGET_BINARY="${BINS[$bin_sel]}"
  fi
fi
if [[ -z "${TARGET_BINARY}" ]]; then
  read -e -i "./my_app" -p "Target binary [./my_app]: " TARGET_BINARY
  TARGET_BINARY=${TARGET_BINARY:-./my_app}
fi

# --- Other parameters ---
read -p "$MSG_OUT [findings/]: " OUTPUT_DIR
OUTPUT_DIR=${OUTPUT_DIR:-findings/}
read -p "Timeout (ms) [1000]: " TIMEOUT; TIMEOUT=${TIMEOUT:-1000}
read -p "Memory limit (MB) [100]: " MEM_LIMIT; MEM_LIMIT=${MEM_LIMIT:-100}
read -p "Target args (optional): " TARGET_ARGS

# --- Run AFL++ ---
CMD=(afl-fuzz -i "$SEED_DIR" -o "$OUTPUT_DIR" -t "$TIMEOUT" -m "$MEM_LIMIT" -- "$TARGET_BINARY")
if [[ -n "$TARGET_ARGS" ]]; then
  read -r -a ARGS <<< "$TARGET_ARGS"
  CMD+=("${ARGS[@]}")
fi

echo "Running: ${CMD[*]}"
exec "${CMD[@]}"
