# Farm Time Management System: Database (Sprint 2)

This branch holds the final database design for the Farm Time Management System, Group 4. It replaces the Sprint 1 schema with the updated ERD, and the test data now matches that design. The Sprint 1 version is kept under the `v2.0-sprint1` tag if you need to compare.

The database is PostgreSQL.

## What's in here

| File | What it does |

| 01_create_tables.sql.sql | Creates all tables, with timestamps and identity IDs |
| 02_seed_data.sql | Fills the tables with test data |
| verify.sql | Row count check to run after seeding |
| Farm-Time-Management-ERD.jpg | The ERD the schema was built from |

## The tables

There are 12 tables.

- **Staff and setup:** `staff`, `stations`, `compliancerules`, `breakreasons`, `publicholidays`
- **Day to day:** `roster`, `timeevents`, `breaks`
- **Problems and fixes:** `exceptions`, `timeadjustments`, `auditlogs`
- **Pay:** `payrollsummary`

Every clock in, clock out, break start and break end is a row in `timeevents`. Breaks link to a reason in `breakreasons`. When a manager fixes a time, the change goes in `timeadjustments` and, once approved, gets an `auditlogs` row.

## Running it

1. Create an empty PostgreSQL database.
2. Run the schema file.
3. Run the seed file.
4. Run the verification file and compare the counts with the expected numbers in it.

The seed starts with `TRUNCATE ... RESTART IDENTITY CASCADE`, so it clears all the tables each time. You can re-run it as often as you like, but don't point it at a database with data you want to keep.

## About the test data

The seed has 20 staff across the contract types (full time, part time, casual), a few system roles (worker, supervisor/manager, office admin, roster admin) and three stations using QR, PIN and face ID.

Rosters and clock events cover two fortnights, 31 Aug to 13 Sep and 14 to 27 Sep 2026, plus some shifts for today. Some are deliberately wrong so the exception features have something to find:

- Missing clock-outs
- Breaks started after the 4 hour limit
- Clocking in with no rostered shift
- Clocking in at the wrong station
- Events that haven't synced (pending or failed)

There are also approved, pending and rejected amendments (ADD, EDIT and DELETE), audit rows, and pay summaries for both fortnights.

Two things to know:
- Today's rows use the current date, so they change each time you run the seed.
- The pay totals are a proof-of-concept calculation. Weekend and public holiday hours are paid at the overtime rate, and the real award rates are left for a later phase.

## Branches and tags

- sprint2/erdfinal is this branch, the final ERD version.
- v2.0-sprint1 marks the end of Sprint 1.

## Team

Group 4, Farm Time Management Group. Chris Francis
