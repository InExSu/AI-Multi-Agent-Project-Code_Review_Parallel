#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_DIR/lib/common.sh"
load_config

echo "=== ЭТАП: COLLECTOR - Сбор файлов проекта ==="

init_review_dir
clean_old_reports

FILES_LIST=$(get_project_files)
echo "  Собрано: $FILES_LIST"

echo "  Готово"