#!/bin/bash

# Measure script execution time
START_TOTAL=$(date +%s)

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Create reports directory if it doesn't exist
REVIEW_DIR="$PROJECT_DIR/src_Review"
mkdir -p "$REVIEW_DIR"

# === CLEANING OLD REPORTS ===
echo "=== Cleaning old reports in: $REVIEW_DIR ==="
rm -f "$REVIEW_DIR"/review_Architecture.md
rm -f "$REVIEW_DIR"/review_Code_Style.md
rm -f "$REVIEW_DIR"/review_QA.md
rm -f "$REVIEW_DIR"/review_Final.md
rm -f "$REVIEW_DIR"/_temp_*.txt
echo "  Old reports removed"
echo ""

# Paths to specification files
SPEC_FILE_RAILWAY="$PROJECT_DIR/skills/railway-fsm-programming-style/SKILL.md"
SPEC_FILE_TOKEN="$PROJECT_DIR/skills/token-economy-hierarchical-context/SKILL.md"

# Check existence of specification files
if [ ! -f "$SPEC_FILE_RAILWAY" ]; then
    echo "Error: Railway FSM specification file not found"
    echo "Looking for: $SPEC_FILE_RAILWAY"
    exit 1
fi

if [ ! -f "$SPEC_FILE_TOKEN" ]; then
    echo "Error: Token Economy specification file not found"
    echo "Looking for: $SPEC_FILE_TOKEN"
    exit 1
fi

# Check for opencode availability
if ! command -v opencode &> /dev/null; then
    echo "Error: opencode not installed"
    echo "Install: npm install -g opencode"
    exit 1
fi

echo "=== Analyzing project: $PROJECT_DIR ==="
echo "=== Reports will be saved to: $REVIEW_DIR ==="

# Collect key project files (only src, not vendor)
PHP_FILES=$(find "$PROJECT_DIR/src" -name "*.php" -type f 2>/dev/null | head -10)

if [ -z "$PHP_FILES" ]; then
    echo "Warning: No PHP files found in src/"
    PHP_FILES=$(find "$PROJECT_DIR" -name "*.php" -not -path "$PROJECT_DIR/vendor/*" \
               -not -path "$PROJECT_DIR/src_Review/*" -type f | head -10)
fi

# Save file contents to temporary file
TEMP_FILES_CONTENT="$REVIEW_DIR/_temp_files_content.txt"
echo "=== Project Files Content ===" > "$TEMP_FILES_CONTENT"
for f in $PHP_FILES; do
    echo "" >> "$TEMP_FILES_CONTENT"
    echo "--- $(basename "$f") ---" >> "$TEMP_FILES_CONTENT"
    head -300 "$f" 2>/dev/null >> "$TEMP_FILES_CONTENT"
done

# Function for safe opencode call with model specification and time measurement
run_opencode() {
    local model="$1"
    local prompt="$2"
    local output_file="$3"
    local role_name="$4"
    
    local start_time=$(date +%s)
    echo "  [$(date '+%H:%M:%S')] Starting: $role_name on model $model"
    
    echo "$prompt" | opencode run --model "$model" > "$output_file" 2>&1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "  [$(date '+%H:%M:%S')] Completed: $role_name (${minutes}m ${seconds}s)"
    
    # Save execution time to separate file for final report
    echo "$role_name: ${minutes}m ${seconds}s ($duration sec)" >> "$REVIEW_DIR/_timing_results.txt"
    
    if [ $? -ne 0 ]; then
        echo "  ⚠️ Warning: error during $role_name execution"
        echo "$role_name: ERROR" >> "$REVIEW_DIR/_timing_results.txt"
    fi
}

# Clear timing results file
rm -f "$REVIEW_DIR/_timing_results.txt"

echo ""
echo "=== LAUNCHING AGENTS IN PARALLEL ==="
echo ""

PARALLEL_START=$(date +%s)

# 1. Launch Architect, Programmer and QA in parallel
run_opencode "opencode/nemotron-3-super-free" "
You are an architect. The project follows Railway FSM style.

Railway FSM Specification:
$(head -80 "$SPEC_FILE_RAILWAY")

Token Economy Specification (hierarchical context):
$(head -80 "$SPEC_FILE_TOKEN")

Project Files:
$(cat "$TEMP_FILES_CONTENT")

Evaluate:
1. Does the file structure comply with Railway FSM specification?
2. Is NS_Container used correctly?
3. Are Token Economy principles followed (context hierarchy, token savings)?
4. Are there any architectural violations?
Provide report in Markdown format.
" "$REVIEW_DIR/review_Architecture.md" "Architect" &

run_opencode "opencode/minimax-m2.5-free" "
You are a programmer. Check code for compliance with Railway FSM style.

Railway FSM Specification:
$(head -50 "$SPEC_FILE_RAILWAY")

Main Railway FSM Rules:
- match(true) instead of if
- mirror symmetry for binary conditions
- no null (use '')
- no throw (use \$ns->s_Error)
- prefixes: \$s_, \$i_, \$b_, \$a_
- functions: {object}_{action}

Files:
$(cat "$TEMP_FILES_CONTENT")

Provide list of violations with file names and line numbers (if possible).
" "$REVIEW_DIR/review_Code_Style.md" "Programmer" &

run_opencode "opencode/nemotron-3-super-free" "
You are a QA engineer. Check the project.

Specifications:
$(head -60 "$SPEC_FILE_RAILWAY")
$(head -40 "$SPEC_FILE_TOKEN")

Check:
1. Error handling:
    - Is \$ns->s_Error checked?
    - Is rwd() used?
    - Is 'no throw' principle followed?

2. Tests:
    - Are there tests in tests/ ?
    - Are edge cases covered?

3. Potential code issues

Project Files:
$(cat "$TEMP_FILES_CONTENT")

Provide list of issues in Markdown format.
" "$REVIEW_DIR/review_QA.md" "QA" &

# 2. Wait for all three to complete
echo ""
echo "Waiting for Architect, Programmer and QA to complete..."
echo ""
wait

PARALLEL_END=$(date +%s)
PARALLEL_DURATION=$((PARALLEL_END - PARALLEL_START))
PARALLEL_MINUTES=$((PARALLEL_DURATION / 60))
PARALLEL_SECONDS=$((PARALLEL_DURATION % 60))

echo ""
echo "=== ALL AGENTS HAVE COMPLETED WORK ==="
echo "  Parallel phase execution time: ${PARALLEL_MINUTES}m ${PARALLEL_SECONDS}s"
echo ""

# 3. Integrator - only after everything is ready
echo "=== LAUNCHING INTEGRATOR ==="

INTEGRATOR_START=$(date +%s)
run_opencode "opencode/nemotron-3-super-free" "
You are an integrator. Combine three reports into one final report.

ARCHITECT'S REPORT:
$(cat "$REVIEW_DIR/review_Architecture.md" 2>/dev/null | tail -500)

PROGRAMMER'S REPORT:
$(cat "$REVIEW_DIR/review_Code_Style.md" 2>/dev/null | tail -500)

QA REPORT:
$(cat "$REVIEW_DIR/review_QA.md" 2>/dev/null | tail -500)

Provide final report in format:

## Summary (3-5 main issues)

## What's already good

## What needs to be fixed first

## Action Plan
" "$REVIEW_DIR/review_Final.md" "Integrator"

INTEGRATOR_END=$(date +%s)
INTEGRATOR_DURATION=$((INTEGRATOR_END - INTEGRATOR_START))
INTEGRATOR_MINUTES=$((INTEGRATOR_DURATION / 60))
INTEGRATOR_SECONDS=$((INTEGRATOR_DURATION % 60))

# Remove temporary files
rm -f "$TEMP_FILES_CONTENT"
rm -f "$REVIEW_DIR/_temp_prompt.txt" 2>/dev/null

# FINAL TIME REPORT
TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - START_TOTAL))
TOTAL_MINUTES=$((TOTAL_DURATION / 60))
TOTAL_SECONDS=$((TOTAL_DURATION % 60))

echo ""
echo "=== ⏱️ FINAL TIME STATISTICS ==="
echo ""
echo "📊 Execution time by role:"
echo "$(cat "$REVIEW_DIR/_timing_results.txt" 2>/dev/null)"
echo ""
echo "📈 Summary:"
echo "  ⚡ Parallel phase (Architect + Programmer + QA): ${PARALLEL_MINUTES}m ${PARALLEL_SECONDS}s"
echo "  🔗 Integrator phase: ${INTEGRATOR_MINUTES}m ${INTEGRATOR_SECONDS}s"
echo "  🎯 TOTAL TIME: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s"
echo ""
echo "💡 If agents worked sequentially:"
echo "   ~$(($(cat "$REVIEW_DIR/_timing_results.txt" 2>/dev/null | grep -v ERROR | awk '{sum+=$NF} END {print sum}' || echo 0))) sec"
echo ""

# Remove timing results file
rm -f "$REVIEW_DIR/_timing_results.txt"

echo "=== DONE ==="
echo "Reports saved to: $REVIEW_DIR"
echo "  - $REVIEW_DIR/review_Architecture.md (Nemotron)"
echo "  - $REVIEW_DIR/review_Code_Style.md (MiniMax)"
echo "  - $REVIEW_DIR/review_QA.md (Nemotron)"
echo "  - $REVIEW_DIR/review_Final.md (Nemotron)"

# Show file sizes
echo ""
echo "Report sizes:"
ls -lh "$REVIEW_DIR"/review_*.md 2>/dev/null | awk '{print "  " $9 ": " $5}'