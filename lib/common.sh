#!/bin/bash

# ============================================
# ОБЩИЕ ФУНКЦИИ ДЛЯ CODE REVIEW
# ============================================

load_config() {
    if [ -f "$PROJECT_DIR/config.env" ]; then
        set -a
        source "$PROJECT_DIR/config.env"
        set +a
    else
        echo "Ошибка: config.env не найден"
        exit 1
    fi
}

check_dependencies() {
    if ! command -v opencode &> /dev/null; then
        echo "Ошибка: opencode не установлен"
        echo "Установите: npm install -g opencode"
        exit 1
    fi

    if [ ! -f "$SPEC_RAILWAY" ]; then
        echo "Ошибка: спецификация Railway FSM не найдена: $SPEC_RAILWAY"
        exit 1
    fi

    if [ ! -f "$SPEC_TOKEN" ]; then
        echo "Ошибка: спецификация Token Economy не найдена: $SPEC_TOKEN"
        exit 1
    fi
}

init_review_dir() {
    mkdir -p "$REVIEW_DIR"
}

clean_old_reports() {
    echo "=== Очистка старых отчётов ==="
    rm -f "$REVIEW_DIR"/review_*.md
    rm -f "$REVIEW_DIR"/_temp_*.txt
    rm -f "$REVIEW_DIR"/_timing_*.txt
    echo "  Старые отчёты удалены"
}

get_project_files() {
    local max_files="${MAX_FILES_TO_SCAN:-10}"
    local max_lines="${MAX_LINES_PER_FILE:-300}"

    PHP_FILES=$(find "$PROJECT_DIR/src" -name "*.php" -type f 2>/dev/null | head -"$max_files")

    if [ -z "$PHP_FILES" ]; then
        PHP_FILES=$(find "$PROJECT_DIR" -name "*.php" \
            -not -path "$PROJECT_DIR/vendor/*" \
            -not -path "$PROJECT_DIR/src_Review/*" \
            -type f | head -"$max_files")
    fi

    TEMP_FILES_CONTENT="$REVIEW_DIR/_temp_files_content.txt"
    echo "=== Файлы проекта ===" > "$TEMP_FILES_CONTENT"

    for f in $PHP_FILES; do
        echo "" >> "$TEMP_FILES_CONTENT"
        echo "--- $(basename "$f") ---" >> "$TEMP_FILES_CONTENT"
        head -"$max_lines" "$f" 2>/dev/null >> "$TEMP_FILES_CONTENT"
    done

    echo "$TEMP_FILES_CONTENT"
}

run_opencode() {
    local model="$1"
    local prompt="$2"
    local output_file="$3"
    local role_name="${4:-Agent}"

    local start_time=$(date +%s)
    echo "  [$(date '+%H:%M:%S')] Запуск: $role_name ($model)"

    echo "$prompt" | opencode run --model "$model" > "$output_file" 2>&1
    local exit_code=$?

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo "  [$(date '+%H:%M:%S')] Завершён: $role_name (${minutes}м ${seconds}с)"

    if [ -f "$REVIEW_DIR/_timing_results.txt" ]; then
        if [ $exit_code -eq 0 ]; then
            echo "$role_name: ${minutes}м ${seconds}с" >> "$REVIEW_DIR/_timing_results.txt"
        else
            echo "$role_name: ОШИБКА ($exit_code)" >> "$REVIEW_DIR/_timing_results.txt"
        fi
    fi

    return $exit_code
}

run_stage_if_enabled() {
    local stage_name="$1"
    local enabled_var="STAGE_${stage_name^^}"

    if [ "${!enabled_var:-false}" = "true" ]; then
        return 0
    else
        echo "  Пропуск: $stage_name (отключено в config.env)"
        return 1
    fi
}

print_report_sizes() {
    echo ""
    echo "Размеры отчётов:"
    ls -lh "$REVIEW_DIR"/review_*.md 2>/dev/null | awk '{print "  " $9 ": " $5}'
}

print_timing_summary() {
    if [ -f "$REVIEW_DIR/_timing_results.txt" ]; then
        echo ""
        echo "=== Время выполнения ==="
        cat "$REVIEW_DIR/_timing_results.txt"
    fi
}

is_stage_enabled() {
    local stage="$1"
    local var_name="STAGE_$(echo "$stage" | tr '[:lower:]' '[:upper:]')"
    [ "${!var_name:-true}" = "true" ]
}

get_model_for_stage() {
    local stage="$1"
    case "$stage" in
        architect) echo "${MODEL_ARCHITECT:-opencode/nemotron-3-super-free}" ;;
        programmer) echo "${MODEL_PROGRAMMER:-opencode/minimax-m2.5-free}" ;;
        qa) echo "${MODEL_QA:-opencode/nemotron-3-super-free}" ;;
        integrator) echo "${MODEL_INTEGRATOR:-opencode/nemotron-3-super-free}" ;;
        *) echo "opencode/nemotron-3-super-free" ;;
    esac
}

get_report_for_stage() {
    local stage="$1"
    local var_name="REPORT_$stage"
    echo "${!var_name:-review_${stage}.md}"
}