# MiniRDBMS — An Educational Relational Database in Elixir

## Overview

This project implements a **simple educational relational database management system (RDBMS)** from scratch, along with a small web application that uses it for CRUD operations.

The goal is **not** to build a production-grade database, but to demonstrate:

- clear systems thinking
- modular architecture
- explicit trade-offs
- correctness over cleverness
- the ability to design and finish a coherent system

The database is implemented in **Elixir** and is inspired by real-world payment and business platforms such as Pesapal.

---

## Motivation

Modern payment systems depend on correctness, isolation, and recoverability.  
This project explores how those ideas translate into a minimal RDBMS design using:

- actor-based concurrency (BEAM processes)
- message passing instead of shared mutable state
- explicit ownership of data
- clear responsibility boundaries

The result is a database that is small, understandable, and intentionally limited.

---

## Domain Context

The database is designed around a **payments / business tools domain**.

Example entities include:

- merchants
- customers
- transactions
- payments
- orders / tickets
- inventory items

The demo web application uses these entities to demonstrate real CRUD workflows.

---

## Architectural Overview

The system is structured into distinct layers:

- **Application & Supervision**
  - boots the system
  - supervises long-lived processes

- **Catalog (Metadata)**
  - table schemas
  - primary keys
  - unique constraints
  - index definitions

- **SQL Parsing**
  - converts SQL-like text into an abstract syntax tree (AST)

- **Query Planning**
  - determines execution strategy
  - selects indexes where applicable

- **Execution**
  - coordinates queries across table processes

- **Table Storage**
  - each table is owned by a single process
  - responsible for data and indexes

- **Indexing**
  - basic indexes for equality and uniqueness
  - intentionally simple and documented

- **Persistence**
  - disk-backed storage using simple file formats
  - favors clarity over performance

- **Public API**
  - a stable interface used by the REPL and web app

- **REPL**
  - interactive SQL-like shell

- **Web Interface**
  - HTTP endpoints performing CRUD via the custom database

No module has more than one primary responsibility.

---

## Supported Features (Planned)

- CREATE TABLE with schema definition
- Column types: INT, TEXT, BOOL
- PRIMARY KEY
- UNIQUE constraints
- INSERT, SELECT, UPDATE, DELETE
- WHERE clauses with basic operators
- INNER JOIN on equality
- Basic indexing
- Interactive REPL
- HTTP-based CRUD demo application

Unsupported features (by design):

- transactions
- foreign keys
- query optimization
- advanced SQL syntax

These limitations are intentional and documented.

---

## Development Approach

Development is incremental and commit-driven.

Each step:
- introduces a single architectural component
- explains why it exists
- documents trade-offs
- avoids premature optimization

Documentation is treated as a first-class artifact.

---

## AI Usage

AI tools may be used to assist with:
- code scaffolding
- documentation drafting
- design exploration

All AI assistance is explicitly acknowledged.  
The system design, trade-offs, and final structure are human-directed.

---

## Status

This repository is under active development.

The first milestone establishes:
- architectural boundaries
- domain context
- documentation standards

Subsequent commits build the system layer by layer.
