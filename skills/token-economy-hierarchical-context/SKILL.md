---
name: token-economy-hierarchical-context
description: Hierarchical context navigation (project_Map.md → source code). Prevents blind grepping. Each level has one responsibility. No token waste.
---

# Token Economy: Hierarchical Context

## When to Apply

Apply this skill when:
- Navigating this project
- Answering questions about architecture, data flow, functions
- AI agent is wasting tokens on blind searches
- Need to understand how functions connect

## Core Rules

### 1. Three Levels, One Responsibility Each

```
Level 0: project_Map.md → answers "what calls what" (call graph)
Level 1: CLAUDE.md    → answers "how it works" (architecture)
Level 2: Source Code  → answers "what exactly" at line level
```

### 2. Top-Down Only

Agent navigates **from Level 0 downward**. Never start at Level 2.

### 3. Each Level Has One Job

| Level | Job | Token Cost |
|-------|-----|------------|
| 0 | Call graph, function flow | ~3KB |
| 1 | Architecture, key files | ~5KB |
| 2 | Line-level code details | varies |

### 4. Cache at Level 0

project_Map.md loads once per session. Never re-read.

## Level 0: Project Map (Global)

**Location:** `src/project_Map.md`

This project already has a call graph. Use it first.

**Template:**
```markdown
# Карта вызова функций проекта

| Файл     | Описание         |
|----------|------------------|
| a_Main   | Главная цепочка   |
| b_Agents | Агенты для GS/B24 |

### Rule
Before reading source code, read project_Map.md
```

## Level 1: CLAUDE.md (Optional)

**Location:** `src/CLAUDE.md` or project root

If exists, provides architecture context.

## Level 2: Source Code

**Only when Levels 0-1 cannot answer.**

### Key Files in This Project

| File                   | Responsibility            |
|-----------------------|--------------------------|
| a_Main.php            | RWD chain entry point     |
| a_Main_RUN.php        | CLI entry point         |
| b_Agents.php         | GS/B24 fetch agents    |
| c_Functions_Utils.php| Utilities              |
| NS_Container.php    | Data container        |
| Lib_PHP_Drakon.php   | PHP utilities         |
| Lib_Bitrix24_Drakon.php| B24 API              |
| google_Sheets.php     | Google Sheets API      |

## Workflow

### Pattern 1: Answer "What calls function X?"
```php
// Never: grep -r ~/src
// Always:
match(true) {
    file_Exists('src/project_Map.md') => read_ProjectMap_For($s_FunctionName),
    default                       => grep_In_Src($s_FunctionName),
};
```

### Pattern 2: Answer "How does data flow work?"
```php
match(true) {
    file_Exists('src/project_Map.md') => answer_FromProjectMap(),
    default                          => read_KeyFiles($a_Files),
};
```

### Pattern 3: Find function definition
```php
// Uses NS_Container naming convention
$s_FunctionName = 'B24_Fetch';
grep_In_Path("function $s_FunctionName", __DIR__ . '/../src');
```

## Forbidden Patterns

| Avoid | Use Instead |
|-------|-------------|
| `grep -r src/` | Check project_Map.md first |
| Read 5+ files randomly | Read project_Map.md first |
| Re-read project_Map.md each turn | Cache in session |
| Start search at Level 2 | Start at Level 0 |

## Expected Behavior

| Scenario | Without Hierarchy | With Hierarchy |
|----------|------------------|--------------|
| "How does B24_Fetch work?" | grep → read 4 files → guess | read project_Map.md → answer |
| "Which function updates prices?" | scan entire src → miss some | grep project_Map.md → find |
| "Where is data flow?" | read configs + grep | answer from project_Map.md |

## Token Budget Rules

| Action | Cost | When |
|--------|------|------|
| Load Level 0 | ~3KB | Once per session |
| Load Level 1 | ~5KB | Per project |
| Source file | varies | Only as last resort |
| Blind grep src/ | 20KB+ | NEVER |

## Golden Rules Summary

1. Level 0 first — always know the call graph
2. Level 1 second — understand architecture
3. Level 2 last — only when needed
4. Never grep from src/ without checking Level 0
5. Cache Level 0 for entire session
6. Architecture (3KB) over raw code (20KB+)
7. Top-down, never bottom-up

## Entry Point Template

When user asks about any function:

```php
$ns_State = [
    'user_question' => $s_Question,
    'project_map_path' => __DIR__ . '/../src/project_Map.md',
];

rwd('answer_AboutFunction', $ns_State);
```

## Summary for AI Agents

1. Check `src/project_Map.md` (Level 0) — find function calls
2. If architecture question → answer from Level 0
3. If code question → use Level 0's call graph to target exactly
4. Use function naming conventions: `rwd_*`, `gs_*`, `b24_*`, `B24_*`
5. Key pattern: `NS_Container &$ns` passed by reference
6. Never grep entire src directory
7. Never read random files to understand structure

**Token efficiency = hierarchy + responsibility.**