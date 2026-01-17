This file records manual interaction with the MiniRDBMS system using `iex -S mix`.

Everything here is executed by hand.  
Nothing here is mocked.  
Nothing here assumes future features.

The goal is to confirm what the system *actually does today*.

---

iex -S mix

MiniRDBMS.start()

The system should start without errors. If this fails, nothing else is meaningful.

---

Create tables using a small business / payments domain.

MiniRDBMS.create_table(
  :customers,
  %{id: :int, name: :text, active: :bool},
  primary_key: :id,
  unique: [:name]
)

This should succeed exactly once.  
Running it again should fail with `:table_already_exists`.

MiniRDBMS.create_table(
  :orders,
  %{id: :int, customer_id: :int, amount: :int},
  primary_key: :id
)

No foreign keys are enforced.  
Relationships are modeled by convention only.

MiniRDBMS.list_tables()

Expected:

[:customers, :orders]

This confirms catalog state, not data.

---

Insert customer data.

MiniRDBMS.execute(
  "INSERT INTO customers (id, name, active) VALUES (1, \"Alice\", true)"
)

MiniRDBMS.execute(
  "INSERT INTO customers (id, name, active) VALUES (2, \"Bob\", false)"
)

Attempt an invalid insert.

MiniRDBMS.execute(
  "INSERT INTO customers (id, name, active) VALUES (3, \"Charlie\", \"not_bool\")"
)

This should fail with a type error.  
If it succeeds, type casting is broken.

---

Insert order data.

MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (10, 1, 500)"
)

MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (11, 1, 300)"
)

MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (12, 2, 700)"
)

This establishes a one-to-many relationship by shared values only.

---

Basic SELECT.

MiniRDBMS.execute("SELECT * FROM customers")

Expected two rows.  
Row order is not guaranteed.

MiniRDBMS.execute("SELECT * FROM orders")

Expected three rows.

No projection. No ordering. Full rows only.

---

SELECT with WHERE (equality only).

MiniRDBMS.execute("SELECT * FROM orders WHERE customer_id = 1")

Expected:

[
  %{id: 10, customer_id: 1, amount: 500},
  %{id: 11, customer_id: 1, amount: 300}
]

No OR conditions.  
No ranges.  
Equality only.

---

INNER JOIN on equality.

MiniRDBMS.execute(
"""
SELECT * FROM orders
INNER JOIN customers
ON orders.customer_id = customers.id
"""
)

Expected shape:

[
  %{id: 1, name: "Alice", active: true, customer_id: 1, amount: 500},
  %{id: 1, name: "Alice", active: true, customer_id: 1, amount: 300},
  %{id: 2, name: "Bob", active: false, customer_id: 2, amount: 700}
]

Known and accepted behavior:

- maps are merged naïvely
- column names are not qualified
- customers.id overwrites orders.id
- this is documented and intentional

---

Confirm this is not a cartesian product.

MiniRDBMS.execute(
  "INSERT INTO orders (id, customer_id, amount) VALUES (13, 999, 1000)"
)

Re-run the JOIN.

MiniRDBMS.execute(
"""
SELECT * FROM orders
INNER JOIN customers
ON orders.customer_id = customers.id
"""
)

The order with customer_id = 999 must not appear.  
If it does, JOIN semantics are incorrect.

---

Parsing versus execution boundary.

MiniRDBMS.SQL.Parser.parse(
"""
SELECT * FROM orders
INNER JOIN customers
ON orders.customer_id = customers.id
WHERE active = true
"""
)

The parsed AST should retain the WHERE clause.

Executing the same query:

MiniRDBMS.execute(
"""
SELECT * FROM orders
INNER JOIN customers
ON orders.customer_id = customers.id
WHERE active = true
"""
)

Current behavior:

- JOIN executes
- WHERE is ignored for JOINs

This is intentional.  
Planning and parsing are ahead of execution by design.

---

Explicitly not tested here:

- disk persistence
- transactions
- rollbacks
- projections
- qualified column names
- JOIN + WHERE correctness
- performance characteristics

Those are future milestones, not regressions.

---

If all behavior above matches expectations, the system is behaving exactly as implemented — no more, no less.
