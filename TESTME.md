# Manual Test Walkthrough (Interactive REPL)

This document records **manual, step-by-step tests** for the educational Elixir RDBMS.

These tests are intentionally *hands-on* and *explicit*. They are designed to:

* Demonstrate how the system behaves from the outside
* Validate correctness of implemented features
* Expose limitations honestly
* Serve as a learning and review artifact

This is **not** a production test suite. It is a *thinking tool*.

---

## 0. Scope and Assumptions

These tests validate the following implemented features:

* Table creation with schemas
* INSERT
* SELECT
* SELECT with WHERE (equality)
* Basic indexing (where applicable)
* INNER JOIN on equality
* SQL parsing and execution pipeline

What we are **not** testing yet:

* Disk persistence
* Transactions
* Query optimization
* Qualified column names (`table.column`)
* JOIN + WHERE filtering (parsed but not executed)
* Projection (`SELECT col1, col2`)

All behavior shown here reflects **current system capabilities**, not future intent.

---

## 1. Starting the System

From the project root:

```bash
iex -S mix
```

This starts:

* The Elixir VM
* The application supervision tree
* The MiniRDBMS processes (catalog, tables, etc.)

Inside `iex`:

```elixir
MiniRDBMS.start()
```

### Why this matters

The database is implemented as a set of supervised processes.
Calling `start/0` ensures:

* The catalog GenServer is running
* Table processes can be created dynamically
* The public API is ready to accept SQL commands

---

## 2. Creating Tables (Catalog + Table Processes)

We use a **payments / business domain** for realism.

### Create `customers`

```elixir
MiniRDBMS.create_table(
  :customers,
  %{id: :int, name: :text, active: :bool},
  primary_key: :id,
  unique: [:name]
)
```

**What happens internally:**

* The catalog registers the table schema
* A table GenServer is started
* Primary key and unique constraint metadata is stored

---

### Create `orders`

```elixir
MiniRDBMS.create_table(
  :orders,
  %{id: :int, customer_id: :int, amount: :int},
  primary_key: :id
)
```

This models a simple order / ticket system linked to customers.

---

### Verify tables exist

```elixir
MiniRDBMS.list_tables()
```

Expected result:

```elixir
[:customers, :orders]
```

This confirms the **catalog state**, not the data.

---

## 3. Inserting Data (INSERT)

### Insert customers

```elixir
MiniRDBMS.execute(
  "INSERT INTO customers (id, name, active) VALUES (1, \"Alice\", true)"
)

MiniRDBMS.execute(
  "INSERT INTO customers (id, name, active) VALUES (2, \"Bob\", false)"
)
```

**What happens:**

* SQL is parsed into an AST
* The executor routes to the `customers` table process
* Primary key and unique constraints are checked
* Rows are stored as Elixir maps

---

### Insert orders

```elixir
MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (10, 1, 500)"
)

MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (11, 1, 300)"
)

MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (12, 2, 700)"
)
```

This creates a **one-to-many relationship** (customers → orders).

---

## 4. Basic SELECT

### Select all customers

```elixir
MiniRDBMS.execute("SELECT * FROM customers")
```

Expected result:

```elixir
[
  %{id: 1, name: "Alice", active: true},
  %{id: 2, name: "Bob", active: false}
]
```

**Why it looks like this:**

* Rows are stored as maps
* No ordering guarantees are enforced
* No projection is applied (`*` returns full rows)

---

## 5. SELECT with WHERE

### Filter orders by customer

```elixir
MiniRDBMS.execute("SELECT * FROM orders WHERE customer_id = 1")
```

Expected result:

```elixir
[
  %{id: 10, customer_id: 1, amount: 500},
  %{id: 11, customer_id: 1, amount: 300}
]
```

**Why this works:**

* WHERE is parsed as a simple equality map
* Filtering happens inside the table process
* If an index exists, it may be used

---

## 6. INNER JOIN (Core Feature)

### Execute JOIN

```elixir
MiniRDBMS.execute(
"""
SELECT * FROM orders
INNER JOIN customers ON orders.customer_id = customers.id
"""
)
```

Expected result:

```elixir
[
  %{id: 1, name: "Alice", active: true, customer_id: 1, amount: 500},
  %{id: 1, name: "Alice", active: true, customer_id: 1, amount: 300},
  %{id: 2, name: "Bob", active: false, customer_id: 2, amount: 700}
]
```

### Why the result looks like this

* JOIN matches `orders.customer_id == customers.id`
* Each matching pair produces **one merged row**
* Maps are merged naively (no column namespacing)
* `customers.id` overwrites `orders.id`

This is **intentional** and documented as a limitation.

---

## 7. JOIN Cardinality Test (No Cartesian Product)

### Insert a non-matching order

```elixir
MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (13, 999, 1000)"
)
```

### Re-run JOIN

```elixir
MiniRDBMS.execute(
"""
SELECT * FROM orders
INNER JOIN customers ON orders.customer_id = customers.id
"""
)
```

Expected behavior:

* The order with `customer_id = 999` is excluded
* Only equality matches produce rows

This confirms the JOIN is **not** a cartesian product.

---

## 8. JOIN + WHERE (Parsing vs Execution)

### Parse JOIN + WHERE

```elixir
MiniRDBMS.SQL.Parser.parse(
"""
SELECT * FROM orders
INNER JOIN customers ON orders.customer_id = customers.id
WHERE active = true
"""
)
```

Expected AST (simplified):

```elixir
%{
  type: :select,
  join: %{left: :orders, right: :customers, on: {:customer_id, :id}},
  where: %{active: true}
}
```

### Important clarification

* The parser **preserves WHERE**
* The executor currently **ignores WHERE for JOINs**

This is a known limitation and an intentional staging decision.

---

## 9. What This Test Suite Proves

These manual tests demonstrate:

* Clear separation of parsing and execution
* Correct JOIN semantics for equality
* Honest limitations in feature support
* A usable SQL-like interface
* A realistic business-domain data model

They also create a **baseline** for future automated tests.

---

## 10. Why Manual Tests Matter Here

This project prioritizes:

* Understanding over abstraction
* Correctness over cleverness
* Transparency over feature count

These tests are meant to be read, reasoned about, and challenged — not just run.
