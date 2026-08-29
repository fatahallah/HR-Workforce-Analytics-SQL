# HR Workforce Analytics — SQL & Power BI Project (Al Noor HR Data, Phase 2)

## Overview
This project extends the earlier **Al Noor HR Operations & Payroll Analytics System** (Excel/Power Query) into SQL, using a relational Human Resources Data Set to practice querying, joining, and analyzing multi-table employee data. It focuses on headcount composition, attrition, undocumented action codes, and performance ranking.

## Data Source
A synthetic Human Resources Data Set consisting of three related tables, linked by `EmpID`:

| Table | Rows | Description |
|---|---|---|
| `tbl_Employee` | 1,562 | Employee demographics, department, manager, hire/termination dates |
| `tbl_Action` | 2,586 | Logged employment events (hire, promotion, termination, etc.) per employee |
| `tbl_Perf` | 9,605 | Periodic performance ratings per employee |

**Known data limitation:** The `PayRate` column in `tbl_Employee` is fully NULL in the source data. Compensation analysis was intentionally left out of scope rather than filled with synthetic values, to keep every figure in this project traceable to real source data.

## Tools
- **DB Browser for SQLite** — database creation, CSV import, and query execution
- **SQL** — data validation, joins, self-joins, CTEs, window functions
- **Power BI Desktop** — connected to the SQLite database via an ODBC driver, DAX measures, and interactive dashboard design

## Methodology
1. **Data Validation** — checked for duplicate keys, missing values, and verified categorical value ranges across all three tables.
2. **Descriptive Analysis** — calculated headcount, active/terminated split, and department-level attrition rates.
3. **Relational Analysis** — joined tables to measure action frequency per employee and resolved manager hierarchies via a self-join.
4. **Code Decoding** — since no data dictionary was provided for `ActionID`, codes were decoded by analyzing their frequency and relationship to known fields (e.g. hire date, termination status) rather than assumed.
5. **Advanced Querying** — used CTEs to break down termination reasons, and window functions (`RANK()`, `AVG() OVER`) to rank and benchmark employee performance within departments without collapsing row-level detail.

## Key Insights
- **Headcount:** 1,562 total employees — 1,118 active (71.6%), 444 terminated (28.4%).
- **Attrition by department:** ranges from 24.1% to 33.1% across the 10 departments, with DepID 3 showing the highest turnover.
- **Decoded action codes** (inferred from data patterns, not a supplied dictionary):
  - `ActionID = 10` → **Hire** (occurs exactly once per employee, in the same year as their hire date).
  - `ActionID = 30, 90, 91` → **Termination-related actions.** Together they account for exactly all 444 terminated employees; each code's employees are all confirmed terminated, and the fact their individual counts overlap (sum > 444) suggests some employees carry more than one termination-related code — likely a preliminary action ahead of final termination.
- **Manager span of control:** 266 managers across the company, with team sizes tightly clustered (many at exactly 6 direct reports), suggesting a deliberately balanced synthetic dataset rather than an organic org structure.
- **Performance ranking:** using `RANK() OVER (PARTITION BY DepID ORDER BY Rating DESC)`, employees were ranked within their department based on their most recent rating, correctly handling ties (e.g. 8 employees tied for rank 1 in Department 1).

## Dashboard (Power BI)
The SQL analysis above was brought into an interactive two-page Power BI dashboard, connected live to the SQLite database through an ODBC driver rather than a static data export.

**Page 1 — Workforce Overview**
- KPI cards: Total Employees, Active Employees, Attrition Rate %
- Attrition Rate % by Department (bar chart, sorted highest to lowest)
- Employee performance ranking table, ranked within department using a DAX-based RANK measure
- Department slicer to filter the whole page interactively

**Page 2 — HR Performance & Termination Details**
- KPI cards: Total Staff, Total Managers
- Termination Reasons Breakdown (donut chart of the three decoded termination action codes)
- Average Performance Rating by Department (bar chart)
- Synced department slicer, consistent with Page 1

See `HR_Workforce_Analytics_Dashboard.pdf` for a static export of both pages.

## Files
- `HR_Data_Validation_Queries.sql` — full annotated query log, in chronological order, covering every step above.
- `HR_Workforce_Analytics_Dashboard.pdf` — exported preview of the Power BI dashboard (both pages).

## Author
Fathallah Saied Abou Eid
