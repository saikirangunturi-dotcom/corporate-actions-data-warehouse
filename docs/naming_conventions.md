# Corporate Actions Data Warehouse - Naming Conventions

## Overview
This document defines the standard naming conventions for the Corporate Actions Data Warehouse Project built using SQL Server, Bronze-Silver-Gold architecture, and CSV-based source files.

---

# Table of Contents

1. General Principles
2. Table Naming Conventions
   - Bronze Rules
   - Silver Rules
   - Gold Rules
3. Column Naming Conventions
   - Surrogate Keys
   - Technical Columns
4. Stored Procedures

---

# 1. General Principles

- Use **snake_case** naming convention with lowercase letters and underscores (`_`) to separate words.
- Use **English language** for all database object names.
- Avoid using SQL reserved keywords as object names.

---

# 2. Table Naming Conventions

## Bronze Layer Rules

- All names must start with the source system name.
- Table names must match original source table names without renaming.

### Pattern

```text
<sourcesystem>_<entity>
```

### Definitions

- `<sourcesystem>` → Name of the source system  
  Example: `market_data_vendor (mdv)`

- `<entity>` → Exact table name from source system

### Example

```text
mdv_companies
```

Represents companies information from source system.

---

## Silver Layer Rules

- All names must start with the source system name.
- Table names must match original source table names without renaming.

### Pattern

```text
<sourcesystem>_<entity>
```

### Definitions

- `<sourcesystem>` → Name of source system  
  Example: `market_data_vendor (mdv)`

- `<entity>` → Exact table name from source system

### Example

```text
mdv_companies
```

Represents cleansed and standardized companies information.

---

## Gold Layer Rules

- All names must use meaningful business-aligned names.
- Tables must start with category prefix.

### Pattern

```text
<category>_<entity>
```

### Definitions

- `<category>` → Table role/category such as:
  - `dim` = Dimension table
  - `fact` = Fact table

- `<entity>` → Business entity name

### Examples

```text
dim_companies_tbl
fact_corporate_actions_tbl
```

---

## Glossary of Category Patterns

| Pattern | Meaning | Example |
|---|---|---|
| dim_ | Dimension Table | dim_companies_tbl, dim_securities_tbl, dim_event_types_tbl, dim_dates_tbl |
| fact_ | Fact Table | fact_corporate_actions_tbl |

---

# 3. Column Naming Conventions

## Surrogate Keys

- All primary keys in dimension tables must use suffix `_key`.

### Pattern

```text
<table_name>_key
```

### Example

```text
company_key
security_key
event_type_key
date_key
```

---

## Technical Columns

- All technical columns must start with prefix `dwh_`.

### Pattern

```text
dwh_<column_name>
```

### Example

```text
dwh_create_date
dwh_load_date
```

---

# 4. Stored Procedures

- All stored procedures used for loading data must follow:

### Pattern

```text
load_<layer>
```

### Examples

```text
load_bronze
load_silver
load_gold
```

---

## Purpose

| Procedure | Description |
|---|---|
| load_bronze | Loads raw source data into Bronze layer |
| load_silver | Loads cleansed and validated data into Silver layer |
| load_gold | Loads final business-ready data into Gold layer from Gold views |

