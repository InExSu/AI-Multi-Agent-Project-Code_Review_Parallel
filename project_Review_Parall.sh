#!/bin/bash

# Замер времени выполнения скрипта
START_TOTAL=$(date +%s)

# Определяем директорию скрипта и корень проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Создаём директорию для отчётов, если её нет
REVIEW_DIR="$PROJECT_DIR/src_Review"
mkdir -p "$REVIEW_DIR"

# === ОЧИСТКА СТАРЫХ ОТЧЁТОВ ===
echo "=== Очистка старых отчётов в: $REVIEW_DIR ==="
rm -f "$REVIEW_DIR"/review_Architecture.md
rm -f "$REVIEW_DIR"/review_Code_Style.md
rm -f "$REVIEW_DIR"/review_QA.md
rm -f "$REVIEW_DIR"/review_Final.md
rm -f "$REVIEW_DIR"/_temp_*.txt
echo "  Старые отчёты удалены"
echo ""

# Пути к файлам спецификаций
SPEC_FILE_RAILWAY="$PROJECT_DIR/skills/railway-fsm-programming-style/SKILL.md"
SPEC_FILE_TOKEN="$PROJECT_DIR/skills/token-economy-hierarchical-context/SKILL.md"

# Проверка существования файлов спецификации
if [ ! -f "$SPEC_FILE_RAILWAY" ]; then
    echo "Ошибка: не найден файл спецификации Railway FSM"
    echo "Искали: $SPEC_FILE_RAILWAY"
    exit 1
fi

if [ ! -f "$SPEC_FILE_TOKEN" ]; then
    echo "Ошибка: не найден файл спецификации Token Economy"
    echo "Искали: $SPEC_FILE_TOKEN"
    exit 1
fi

# Проверка наличия opencode
if ! command -v opencode &> /dev/null; then
    echo "Ошибка: opencode не установлен"
    echo "Установите: npm install -g opencode"
    exit 1
fi

echo "=== Анализ проекта: $PROJECT_DIR ==="
echo "=== Отчёты будут сохранены в: $REVIEW_DIR ==="

# Собираем ключевые файлы проекта (только src, не vendor)
PHP_FILES=$(find "$PROJECT_DIR/src" -name "*.php" -type f 2>/dev/null | head -10)

if [ -z "$PHP_FILES" ]; then
    echo "Предупреждение: не найдены PHP файлы в src/"
    PHP_FILES=$(find "$PROJECT_DIR" -name "*.php" -not -path "$PROJECT_DIR/vendor/*" \
               -not -path "$PROJECT_DIR/src_Review/*" -type f | head -10)
fi

# Сохраняем содержимое файлов во временный файл
TEMP_FILES_CONTENT="$REVIEW_DIR/_temp_files_content.txt"
echo "=== Содержимое файлов проекта ===" > "$TEMP_FILES_CONTENT"
for f in $PHP_FILES; do
    echo "" >> "$TEMP_FILES_CONTENT"
    echo "--- $(basename "$f") ---" >> "$TEMP_FILES_CONTENT"
    head -300 "$f" 2>/dev/null >> "$TEMP_FILES_CONTENT"
done

# Функция для безопасного вызова opencode с указанием модели и замером времени
run_opencode() {
    local model="$1"
    local prompt="$2"
    local output_file="$3"
    local role_name="$4"
    
    local start_time=$(date +%s)
    echo "  [$(date '+%H:%M:%S')] Запуск: $role_name на модели $model"
    
    echo "$prompt" | opencode run --model "$model" > "$output_file" 2>&1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "  [$(date '+%H:%M:%S')] Завершён: $role_name (${minutes}м ${seconds}с)"
    
    # Сохраняем время выполнения в отдельный файл для итогового отчёта
    echo "$role_name: ${minutes}м ${seconds}с ($duration сек)" >> "$REVIEW_DIR/_timing_results.txt"
    
    if [ $? -ne 0 ]; then
        echo "  ⚠️ Предупреждение: ошибка при выполнении $role_name"
        echo "$role_name: ОШИБКА" >> "$REVIEW_DIR/_timing_results.txt"
    fi
}

# Очищаем файл с замерами времени
rm -f "$REVIEW_DIR/_timing_results.txt"

echo ""
echo "=== ЗАПУСК АГЕНТОВ ПАРАЛЛЕЛЬНО ==="
echo ""

PARALLEL_START=$(date +%s)

# 1. Запускаем Архитектора, Программиста и QA параллельно
run_opencode "opencode/nemotron-3-super-free" "
Ты архитектор. Проект следует Railway FSM стилю.

Спецификация Railway FSM:
$(head -80 "$SPEC_FILE_RAILWAY")

Спецификация Token Economy (иерархический контекст):
$(head -80 "$SPEC_FILE_TOKEN")

Файлы проекта:
$(cat "$TEMP_FILES_CONTENT")

Оцени:
1. Соответствует ли структура файлов спецификации Railway FSM?
2. Правильно ли используется NS_Container?
3. Соблюдаются ли принципы Token Economy (иерархия контекстов, экономия токенов)?
4. Есть ли нарушения в архитектуре?
Выдай отчёт в формате Markdown.
" "$REVIEW_DIR/review_Architecture.md" "Архитектор" &

run_opencode "opencode/minimax-m2.5-free" "
Ты программист. Проверь код на соответствие Railway FSM стилю.

Спецификация Railway FSM:
$(head -50 "$SPEC_FILE_RAILWAY")

Основные правила Railway FSM:
- match(true) вместо if
- зеркальная симметрия для бинарных условий
- нет null (используй '')
- нет throw (используй \$ns->s_Error)
- префиксы: \$s_, \$i_, \$b_, \$a_
- функции: {объект}_{действие}

Файлы:
$(cat "$TEMP_FILES_CONTENT")

Выдай список нарушений с указанием файлов и строк (если возможно).
" "$REVIEW_DIR/review_Code_Style.md" "Программист" &

run_opencode "opencode/nemotron-3-super-free" "
Ты QA-инженер. Проверь проект.

Спецификации:
$(head -60 "$SPEC_FILE_RAILWAY")
$(head -40 "$SPEC_FILE_TOKEN")

Проверь:
1. Обработка ошибок:
   - Проверяется ли \$ns->s_Error?
   - Используется ли rwd()?
   - Соблюдается ли принцип 'нет throw'?

2. Тесты:
   - Есть ли тесты в tests/ ?
   - Покрыты ли краевые случаи?

3. Потенциальные проблемы в коде

Файлы проекта:
$(cat "$TEMP_FILES_CONTENT")

Выдай список проблем в формате Markdown.
" "$REVIEW_DIR/review_QA.md" "QA" &

# 2. Ждём завершения всех трёх
echo ""
echo "Ожидание завершения Архитектора, Программиста и QA..."
echo ""
wait

PARALLEL_END=$(date +%s)
PARALLEL_DURATION=$((PARALLEL_END - PARALLEL_START))
PARALLEL_MINUTES=$((PARALLEL_DURATION / 60))
PARALLEL_SECONDS=$((PARALLEL_DURATION % 60))

echo ""
echo "=== ВСЕ АГЕНТЫ ЗАВЕРШИЛИ РАБОТУ ==="
echo "  Время выполнения параллельной фазы: ${PARALLEL_MINUTES}м ${PARALLEL_SECONDS}с"
echo ""

# 3. Интегратор — только после того, как всё готово
echo "=== ЗАПУСК ИНТЕГРАТОРА ==="

INTEGRATOR_START=$(date +%s)
run_opencode "opencode/nemotron-3-super-free" "
Ты интегратор. Собери три отчёта в один итоговый.

ОТЧЁТ АРХИТЕКТОРА:
$(cat "$REVIEW_DIR/review_Architecture.md" 2>/dev/null | tail -500)

ОТЧЁТ ПРОГРАММИСТА:
$(cat "$REVIEW_DIR/review_Code_Style.md" 2>/dev/null | tail -500)

ОТЧЁТ QA:
$(cat "$REVIEW_DIR/review_QA.md" 2>/dev/null | tail -500)

Выдай итоговый отчёт в формате:

## Сводка (3-5 главных проблем)

## Что уже хорошо

## Что нужно исправить в первую очередь

## План действий
" "$REVIEW_DIR/review_Final.md" "Интегратор"

INTEGRATOR_END=$(date +%s)
INTEGRATOR_DURATION=$((INTEGRATOR_END - INTEGRATOR_START))
INTEGRATOR_MINUTES=$((INTEGRATOR_DURATION / 60))
INTEGRATOR_SECONDS=$((INTEGRATOR_DURATION % 60))

# Удаляем временные файлы
rm -f "$TEMP_FILES_CONTENT"
rm -f "$REVIEW_DIR/_temp_prompt.txt" 2>/dev/null

# ИТОГОВЫЙ ОТЧЁТ ПО ВРЕМЕНИ
TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - START_TOTAL))
TOTAL_MINUTES=$((TOTAL_DURATION / 60))
TOTAL_SECONDS=$((TOTAL_DURATION % 60))

echo ""
echo "=== ⏱️ ИТОГОВАЯ СТАТИСТИКА ВРЕМЕНИ ==="
echo ""
echo "📊 Время выполнения по ролям:"
echo "$(cat "$REVIEW_DIR/_timing_results.txt" 2>/dev/null)"
echo ""
echo "📈 Сводка:"
echo "  ⚡ Параллельная фаза (Архитектор + Программист + QA): ${PARALLEL_MINUTES}м ${PARALLEL_SECONDS}с"
echo "  🔗 Фаза интегратора: ${INTEGRATOR_MINUTES}м ${INTEGRATOR_SECONDS}с"
echo "  🎯 ОБЩЕЕ ВРЕМЯ: ${TOTAL_MINUTES}м ${TOTAL_SECONDS}с"
echo ""
echo "💡 Если бы агенты работали последовательно:"
echo "   ~$(($(cat "$REVIEW_DIR/_timing_results.txt" 2>/dev/null | grep -v ОШИБКА | awk '{sum+=$NF} END {print sum}' || echo 0))) сек"
echo ""

# Удаляем файл с замерами времени
rm -f "$REVIEW_DIR/_timing_results.txt"

echo "=== ГОТОВО ==="
echo "Отчёты сохранены в: $REVIEW_DIR"
echo "  - $REVIEW_DIR/review_Architecture.md (Nemotron)"
echo "  - $REVIEW_DIR/review_Code_Style.md (MiniMax)"
echo "  - $REVIEW_DIR/review_QA.md (Nemotron)"
echo "  - $REVIEW_DIR/review_Final.md (Nemotron)"

# Показываем размеры файлов
echo ""
echo "Размеры отчётов:"
ls -lh "$REVIEW_DIR"/review_*.md 2>/dev/null | awk '{print "  " $9 ": " $5}'