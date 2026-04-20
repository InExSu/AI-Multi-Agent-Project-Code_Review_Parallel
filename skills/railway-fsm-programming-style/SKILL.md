---
name: railway-fsm-programming-style
description: Enforces Railway FSM programming style with NS_Container, no exceptions, no null, Hungarian notation, and mirror symmetry for binary conditions. All errors as values, all state in NS_Container.
---

# Railway FSM Programming Style

## When to Apply

Apply this skill when writing or reviewing PHP code that follows the Railway Finite State Machine pattern. Use for:
- Price imports, API integrations, data processing pipelines
- Any code where errors should be values, not exceptions
- Functions that pass state via `NS_Container`

## Core Rules

### 1. No Exceptions
Errors are **values** in the `NS_Container`. Never use `throw`. Use `$ns->s_Error`.

### 2. No Null
Use `''` (empty string) as the monoid identity. Check existence with property access.

### 3. Railway Pattern with `rwd()`
```php
function rwd(callable $fn, NS_Container $ns): void {
    match(true) {
        $ns->s_Error === '' => $fn($ns),
        $ns->s_Error !== '' => null,
    };
}
```

### 4. Mirror Symmetry for Binary Conditions
**Every binary condition must show both branches explicitly.**

```php
// ✅ Good
match(true) {
    $b_Condition === true  => do_True($ns),
    $b_Condition === false => do_False($ns),
};

// ❌ Bad - default hides intent
match(true) {
    $b_Condition === true => do_True($ns),
    default => do_False($ns),
};
```

### 5. Primary Control Structure: `match(true)`
One match = one decision point. Act immediately, don't store results.

### 6. SRP (Single Responsibility)
One function = one match OR one loop OR one simple operation. One-line functions are justified.

### 7. NS_Container
Single class passed by reference everywhere. Use `#[AllowDynamicProperties]`.

## Hungarian Notation

### Variable Prefixes

| Prefix | Type | Example |
|--------|------|---------|
| `$s_` | string | `$s_WebHook`, `$s_Sku` |
| `$i_` | integer | `$i_ProductId` |
| `$f_` | float | `$f_Price` |
| `$b_` | boolean | `$b_HasError`, `$b_ApiError` |
| `$a_` | array | `$a_Row`, `$a_Parsed` |
| `$m_` | mixed | `$m_Value` |
| `$ns` | NS_Container | `$ns` (main state container) |

### Property Naming in NS_Container

| Prefix | Type | Example |
|--------|------|---------|
| `s_` | string | `$ns->s_Data_Get`, `$ns->s_Error` |
| `i_` | integer | `$ns->i_ProductId` |
| `f_` | float | `$ns->f_Price` |
| `b_` | boolean | `$ns->b_B24_Update`, `$ns->b_Data_Set` |
| `a_` | array | `$ns->a_Row`, `$ns->a_Parsed` |
| `m_` | mixed | `$ns->m_Value` |

### Function Naming: `{object}_{Action}`
- `prices_Import`, `sku_Validate`, `error_Set`, `row_Parse`
- Loop functions: `{object}_{Action}Loop` (e.g., `mapping_BuildLoop`)

### Temporary Properties in NS_Container
- `_s_` prefix: temp string (`$ns->_s_PriceId`)
- `_a_` prefix: temp array (`$ns->_a_PriceFields`)

## Code Structure Order

```php
// 1. Constants loading
// 2. Error helpers (error_Set, error_Has, error_Clear)
// 3. Simple builders (one-line functions)
// 4. SRP primitives (prepare, execute, cleanup)
// 5. Validators (match with mirror symmetry)
// 6. Extractors (match with mirror symmetry)
// 7. Composite railways
// 8. API calls
// 9. Loops (*Loop functions)
// 10. Business logic chains
// 11. Main function
// 12. Helpers
// 13. Output functions
// 14. Entry point
```

## NS_Container Template

```php
#[\AllowDynamicProperties]
class NS_Container
{
    public bool $b_B24_Update = false;
    public const DATA_SOURCE_EXTERNAL = 'external';
    
    public string $s_Data_Get = self::DATA_SOURCE_EXTERNAL;
    public bool $b_Data_Set = true;
    public string $s_Error = '';
    
    /** @var array<mixed> */
    public array $report = [];
    
    /** @var array<mixed> */
    public array $logs = [];
    
    public function __construct(array $values = [])
    {
        foreach ($values as $key => $value) {
            $this->{$key} = $value;
        }
    }
}
```

## Match Patterns

### Pattern 1: Mirror Symmetry (2 branches)
```php
match(true) {
    $b_Condition === true  => do_True($ns),
    $b_Condition === false => do_False($ns),
};
```

### Pattern 2: Multi-branch (3+ branches, default allowed)
```php
match(true) {
    $s_Value === ''        => error_Set($ns, 'Empty'),
    !is_string($s_Value)   => error_Set($ns, 'Invalid'),
    trim($s_Value) === ''  => error_Set($ns, 'Whitespace'),
    default                => $ns->s_Sku = trim($s_Value),
};
```

### Pattern 3: Value matching
```php
match($s_Color) {
    'red'   => handle_Red($ns),
    'blue'  => handle_Blue($ns),
    'green' => handle_Green($ns),
    default => handle_Unknown($ns),
};
```

## Forbidden Patterns

| Avoid | Use Instead |
|-------|-------------|
| `if` without `else` | `match(true)` with mirror symmetry |
| `if-elseif` chains | `match(true)` |
| `default` for binary conditions | Explicit `=== true` and `=== false` |
| `null` | `''` or property absence |
| `throw` | `$ns->s_Error = 'message'` |
| `??` operator | Property access with default |
| Nested `match` | Separate functions |
| Inline loops | Extracted `*Loop` functions |
| Classes with state | `NS_Container` + pure functions |

## When `default` is Allowed

| Scenario | Use `default`? |
|----------|----------------|
| 2 branches (binary) | ❌ No |
| 3+ branches | ✅ Yes |
| Default handler for unknown values | ✅ Yes |
| Fallback after specific cases | ✅ Yes |

## Golden Rules Summary

1. One function = one match OR one loop OR one simple operation
2. Binary conditions = mirror symmetry (both `=== true` and `=== false`)
3. Never use `default` for 2 branches
4. Never write `if` without `else`
5. Never write `null` or `throw`
6. Don't store match results — act immediately
7. Every loop → `{object}_ActionLoop` function
8. Even one-line operations get named functions
9. Constants = `NS_*` prefix in container
10. Temporary keys = `_s_` or `_a_` prefix in properties
11. Hungarian notation for all variables
12. Functions = `{object}_{Action}`

## Entry Point Template

```php
$ns = new NS_Container([...]);
constants_Load($ns);
rwd('prices_Import', $ns);
```