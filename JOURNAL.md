## Planner Introduction

The planner was introduced as a pure transformation layer between
SQL parsing and execution.

Its role is to:
- formalize execution intent
- separate decision-making from side effects
- enable future optimization without rewriting executors

At this stage, plans are minimal and map closely to parsed ASTs.
This is intentional.
