# Farm Time Management System: Database (Sprint 2)

This branch holds the final database design for the Farm Time Management System, Group 4. It replaces the Sprint 1 schema with the updated ERD, and the test data now matches that design. The Sprint 1 version is kept under the `v2.0-sprint1` tag if you need to compare.

The database is PostgreSQL, and we test it on Supabase.

## What's in here

| File | What it does |

| `01_create_tables.sql` | Creates all 18 tables, with timestamps, identity IDs, checks and indexes. This is the master. |
| `02_seed_data.sql` | Fills the tables with test data and ends with row count checks |
| `03_exceptions_view.sql` | Creates the three reporting views |
| `Farm-Time-Management-ERD.jpg` | The ERD the schema was built from |

If the ERD image and the SQL ever disagree, trust the SQL. It has checks and indexes that the diagram doesn't show.

## The tables

There are 18 tables.

- **Staff and setup:** `staff`, `stations`, `compliance_rules`, `break_reasons`, `public_holidays`
- **Day to day:** `roster`, `time_events`, `breaks`, `leave_requests`
- **Problems and fixes:** `exceptions`, `time_adjustments`, `audit_logs`
- **Pay:** `payroll_runs`, `payroll_summary`
- **Logins and access:** `users`, `user_roles`, `sessions`, `login_attempts`

Every clock in, clock out, break start and break end is a row in `time_events`. Breaks link to a reason in `break_reasons`. When a manager fixes a time, the change goes in `time_adjustments` and, once approved, gets an `audit_logs` row.

## The views

- `v_daily_exceptions`: today's problems for each staff member (missing clock-out, break overdue, unrostered attempt, wrong station). It lists everyone, so filter on `exception_type <> 'OK'` to see only the problems.
- `v_attendance`: rostered hours against actual hours for each day, with a status of Complete, Incomplete or Absent.
- `v_cost_analysis`: ordinary, overtime and penalty cost for each staff member in each pay period.

The views use Adelaide time, because Supabase sessions default to UTC and that would otherwise split shifts across two days.

## Running it

1. Create an empty PostgreSQL database (a fresh Supabase project works well).
2. Run `01_create_tables.sql`.
3. Run `02_seed_data.sql`.
4. Run `03_exceptions_view.sql`.
5. Run the verification queries at the end of the seed, one at a time, and compare the results with the expected numbers written next to them.

The seed starts with `TRUNCATE ... RESTART IDENTITY CASCADE`, so it clears every table each time, including `users`, `user_roles` and `sessions`. Test logins have to be added again afterwards. You can re-run the seed as often as you like, but don't point it at a database with data you want to keep.

If the schema fails with `relation "staff" already exists`, the database still has tables from an earlier run. Use a new project, or clear the old tables first.

## About the test data

The seed has 20 staff across the contract types (full time, part time, casual), a few system roles (worker, supervisor/manager, office admin, roster admin) and three stations using QR, PIN and face ID.

Rosters and clock events cover two fortnights, 31 Aug to 13 Sep and 14 to 27 Sep 2026, plus some shifts for today. Some are deliberately wrong so the exception features have something to find:

- Missing clock-outs
- Breaks started after the 4 hour limit
- Clocking in with no rostered shift
- Clocking in at the wrong station
- Events that haven't synced (pending or failed)

There are also approved, pending and rejected amendments (ADD, EDIT and DELETE), audit rows, and pay summaries for both fortnights.

Things to know:
- Today's rows use the current date, so they change each time you run the seed.
- `payroll_summary` has 36 rows (18 staff over two fortnights). The two office admins have no pay rows.
- Pay is a proof-of-concept calculation. Ordinary hours are capped at 76 per fortnight (38 hours x 2); anything above that counts as overtime. Weekend and public holiday hours are paid at the overtime rate. The real award rates are a later phase.
- The 8 hours a day limit is a proof-of-concept setting, not an award rule. The 5 hour break rule follows the Horticulture Award, and the 4 hour rule follows the project brief.

## Branches and tags

- `sprint2/erdfinal` is this branch, the final ERD version.
- `v2.0-sprint1` marks the end of Sprint 1.

## Team

Group 4, Farm Time Management Group. Chris Francis
