Farm Time Management System: Database

Database for the Farm Time Management System, built by Group 4. It records staff rosters, clock-in and clock-out times, and breaks, then flags exceptions so a manager can review them quickly.

## What's in This Repo

 File - Purpose 
 `[01_schema.sql]` | Creates the tables, keys and constraints |
 `[02_seed_data.sql]` | Loads fake test data (staff, rosters, time entries). Safe to re-run, because it resets the data each time. |
 `[03_exception_views.sql]` | Creates the views that flag exceptions, including `v_daily_exceptions` |
 `[ERD image or docs folder]` | Entity relationship diagram |

Exceptions Detected

- Missing clock-out
- Break overdue
- Unrostered shift
- Wrong station

Test Data

The seed covers 31 Aug to 27 Sep 2026 with fixed dates, so results are repeatable. The "today" rows and `v_daily_exceptions` use the current date. All names and data are made up.

Known test cases in the seed:
- 5 missing clock-outs
- 6 overdue breaks
- 3 unrostered shifts
- 4 wrong-station entries

How to Run It

1. Create a new project in [Supabase](https://supabase.com) (or any PostgreSQL 15 database).
2. Open the SQL Editor.
3. Run the files in this order: schema, then seed data, then exception views.
4. Check the row counts printed at the end of the seed file.

Branches

- `[main / sprint2/schema-updates]`: say which is the default and what the other holds.

Project Links

- Azure DevOps (boards and repo): [Farm-Time-Management-System](https://dev.azure.com/FarmTimeManagementGroup4/Farm-Time-Management-System)
- This repo: [Chris2806/farmtime_database](https://github.com/Chris2806/farmtime_database)

Team

Group 4: [Chris (database)], [Xinyan (test analyst)], [Kai (DevOps)], [Abdulla (backend)], [other members]

Notes

No passwords or connection strings are stored in this repo. Credentials belong in a local `.env` file that is not committed.
