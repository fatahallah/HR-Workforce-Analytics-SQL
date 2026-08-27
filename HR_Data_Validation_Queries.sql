/* ============================================================
   Project: HR Data Set - SQL Analysis (Al Noor HR System, Phase 2)
   Database: Human Resources Data set.db (SQLite)
   Tables: tbl_Employee, tbl_Action, tbl_Perf
   Author: Fathallah Saied Abou Eid
   Section: Data Validation & Descriptive Analysis
   ============================================================ */


/* ------------------------------------------------------------
   1. Check for duplicate EmpID values in tbl_Employee
   Goal: Confirm EmpID is a valid unique identifier before
         using it as a join key across tables.
   Result: 0 rows returned -> no duplicates found.
------------------------------------------------------------ */
SELECT EmpID, COUNT(*)
FROM tbl_Employee
GROUP BY EmpID
HAVING COUNT(*) > 1;


/* ------------------------------------------------------------
   2. Check for missing hire dates (EngDt) in tbl_Employee
   Goal: Ensure every employee record has a valid hire date,
         since EngDt is critical for tenure and attrition analysis.
   Result: 0 -> no missing hire dates.
------------------------------------------------------------ */
SELECT COUNT(*)
FROM tbl_Employee
WHERE EngDt IS NULL;


/* ------------------------------------------------------------
   3. Review value distribution of categorical columns
   Goal: Inspect DepID, GenderID, and RaceID to confirm the
         values are consistent and within an expected range
         before using them for grouping/segmentation.
------------------------------------------------------------ */
SELECT DepID, COUNT(*)
FROM tbl_Employee
GROUP BY DepID
ORDER BY DepID;

SELECT GenderID, COUNT(*)
FROM tbl_Employee
GROUP BY GenderID
ORDER BY GenderID;

SELECT RaceID, COUNT(*)
FROM tbl_Employee
GROUP BY RaceID
ORDER BY RaceID;


/* ------------------------------------------------------------
   4. Check for missing values in DepID, GenderID, RaceID
   Goal: Confirm no NULLs exist in the key categorical columns,
         validating the totals from the grouped counts above.
   Result: 0 for all three columns -> data is fully populated.
------------------------------------------------------------ */
SELECT COUNT(*) FROM tbl_Employee WHERE DepID IS NULL;
SELECT COUNT(*) FROM tbl_Employee WHERE GenderID IS NULL;
SELECT COUNT(*) FROM tbl_Employee WHERE RaceID IS NULL;


/* ------------------------------------------------------------
   5. Count Active vs. Terminated employees
   Goal: Establish a baseline headcount split using TermDt:
         NULL = still active, NOT NULL = left the company.
         Combined into a single query to cross-check totals
         against the overall employee count (1,562).
------------------------------------------------------------ */
SELECT
  (SELECT COUNT(*) FROM tbl_Employee WHERE TermDt IS NULL)     AS Active,
  (SELECT COUNT(*) FROM tbl_Employee WHERE TermDt IS NOT NULL) AS Terminated,
  (SELECT COUNT(*) FROM tbl_Employee)                          AS Total;


/* ============================================================
   Section: Descriptive Analysis
   ============================================================ */

/* ------------------------------------------------------------
   6. Attrition rate by department
   Goal: Identify which departments have the highest employee
         turnover, using CASE + SUM as a SQL equivalent of
         Excel's SUMIFS, and ROUND to present a clean percentage.
   Result: DepID 3 has the highest attrition rate (33.1%);
           DepID 6 has one of the lowest (24.1%).
------------------------------------------------------------ */
SELECT
  DepID,
  COUNT(*) AS TotalEmployees,
  SUM(CASE WHEN TermDt IS NOT NULL THEN 1 ELSE 0 END) AS Terminated,
  ROUND(100.0 * SUM(CASE WHEN TermDt IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS AttritionRatePct
FROM tbl_Employee
GROUP BY DepID
ORDER BY AttritionRatePct DESC;


/* ------------------------------------------------------------
   6. Attrition rate by department
   Goal: Identify which departments have the highest employee
         turnover, using CASE WHEN to flag terminated employees
         and ROUND to present the rate as a clean percentage.
   Result: DepID 3 has the highest attrition rate (33.1%).
------------------------------------------------------------ */
SELECT
  DepID,
  COUNT(*) AS TotalEmployees,
  SUM(CASE WHEN TermDt IS NOT NULL THEN 1 ELSE 0 END) AS Terminated,
  ROUND(100.0 * SUM(CASE WHEN TermDt IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS AttritionRatePct
FROM tbl_Employee
GROUP BY DepID
ORDER BY AttritionRatePct DESC;


/* ============================================================
   Section: Joins Across Tables
   ============================================================ */

/* ------------------------------------------------------------
   7. Number of actions per employee
   Goal: Join tbl_Employee with tbl_Action to count how many
         recorded actions (hire, promotion, etc.) each employee
         has, surfacing employees with the most job movement.
   Result: 1,562 rows returned - every employee has at least
           one recorded action. Top employee: Housley, Giulio X
           (8 actions).
------------------------------------------------------------ */
SELECT e.EmpID, e.EmpName, COUNT(a.ActID) AS NumberOfActions
FROM tbl_Employee AS e
INNER JOIN tbl_Action AS a ON e.EmpID = a.EmpID
GROUP BY e.EmpID, e.EmpName
ORDER BY NumberOfActions DESC;


/* ------------------------------------------------------------
   8. Team size per manager (self-join)
   Goal: Join tbl_Employee to itself to resolve MgrID into the
         manager's actual name, and count how many employees
         report to each manager.
   Result: 266 rows returned (266 distinct managers). Team
           sizes are unusually even (many managers tied at 6
           direct reports), suggesting a deliberately balanced
           synthetic dataset rather than an organic org chart.
------------------------------------------------------------ */
SELECT
  mgr.EmpID   AS ManagerID,
  mgr.EmpName AS ManagerName,
  COUNT(emp.EmpID) AS TeamSize
FROM tbl_Employee AS emp
INNER JOIN tbl_Employee AS mgr ON emp.MgrID = mgr.EmpID
GROUP BY mgr.EmpID, mgr.EmpName
ORDER BY TeamSize DESC;


/* ============================================================
   Section: Decoding Undocumented Codes (ActionID)
   ============================================================ */

/* ------------------------------------------------------------
   9. Frequency of each ActionID
   Goal: No data dictionary was provided for ActionID, so infer
         its meaning from how often each code appears.
   Result: ActionID 10 appears exactly 1,562 times - matching
           the total employee count exactly, suggesting it
           represents a one-time event common to every employee
           (a strong candidate for "Hire").
------------------------------------------------------------ */
SELECT ActionID, COUNT(*) AS Frequency
FROM tbl_Action
GROUP BY ActionID
ORDER BY ActionID;

/* ------------------------------------------------------------
   10. Validate the "ActionID 10 = Hire" hypothesis
   Goal: If ActionID 10 represents Hire, its EffectiveDt should
         align with the employee's EngDt. Dates are stored in
         different text formats (DD/MM/YYYY vs DD/Mon/YYYY), so
         SUBSTR is used to compare just the year portion.
   Result: 1,562 out of 1,562 matches - confirms ActionID 10
           consistently occurs in the same year as EngDt,
           supporting the "Hire" hypothesis.
------------------------------------------------------------ */
SELECT COUNT(*)
FROM tbl_Employee AS e
INNER JOIN tbl_Action AS a
  ON e.EmpID = a.EmpID
  AND a.ActionID = 10
WHERE SUBSTR(e.EngDt, -4) = SUBSTR(a.EffectiveDt, -4);

/* ------------------------------------------------------------
   11. Investigate ActionID 30, 90, and 91 against termination
   Goal: Test whether the remaining action codes relate to
         employees leaving the company, by counting how many
         distinct employees per code are also Terminated
         (TermDt IS NOT NULL).
   Result: All employees with ActionID 30 (257), 90 (239), and
           91 (242) are Terminated - each code maps 100% onto
           the terminated population, not just partially.
------------------------------------------------------------ */
SELECT COUNT(DISTINCT a.EmpID)
FROM tbl_Action AS a
INNER JOIN tbl_Employee AS e ON a.EmpID = e.EmpID
WHERE a.ActionID = 30 AND e.TermDt IS NOT NULL;

SELECT COUNT(DISTINCT a.EmpID)
FROM tbl_Action AS a
INNER JOIN tbl_Employee AS e ON a.EmpID = e.EmpID
WHERE a.ActionID = 90 AND e.TermDt IS NOT NULL;

SELECT COUNT(DISTINCT a.EmpID)
FROM tbl_Action AS a
INNER JOIN tbl_Employee AS e ON a.EmpID = e.EmpID
WHERE a.ActionID = 91 AND e.TermDt IS NOT NULL;

/* ------------------------------------------------------------
   12. Confirm ActionID 30/90/91 collectively account for all
       terminations
   Goal: Verify that the three codes together, counted without
         double-counting employees who may carry more than one
         code, equal the total terminated headcount (444).
   Result: 444 out of 444 - confirms ActionID 30, 90, and 91
           are the three termination-related codes and fully
           explain every termination in the dataset. Likely
           represent distinct termination reasons (e.g.
           voluntary resignation, performance-related,
           conduct-related).
------------------------------------------------------------ */
SELECT COUNT(DISTINCT a.EmpID)
FROM tbl_Action AS a
INNER JOIN tbl_Employee AS e ON a.EmpID = e.EmpID
WHERE a.ActionID IN (30, 90, 91) AND e.TermDt IS NOT NULL;


/* ============================================================
   Section: CTEs / Advanced Queries
   ============================================================ */

/* ------------------------------------------------------------
   13. Breakdown of termination reasons (ActionID 30/90/91)
   Goal: Use a CTE to isolate termination-related actions, then
         calculate each reason's share of the 444 total
         terminations.
   Result: ActionID 30 = 257 employees (57.9%), 91 = 242 (54.5%),
           90 = 239 (53.8%). Percentages sum to over 100%,
           confirming some employees carry more than one
           termination-related code (e.g. a preliminary action
           before final termination), consistent with earlier
           findings.
------------------------------------------------------------ */
WITH TerminationReasons AS (
  SELECT a.EmpID, a.ActionID
  FROM tbl_Action AS a
  WHERE a.ActionID IN (30, 90, 91)
)
SELECT
  ActionID,
  COUNT(DISTINCT EmpID) AS EmployeeCount,
  ROUND(100.0 * COUNT(DISTINCT EmpID) / 444, 1) AS PctOfTerminations
FROM TerminationReasons
GROUP BY ActionID
ORDER BY EmployeeCount DESC;


/* ============================================================
   Section: Window Functions
   ============================================================ */

/* ------------------------------------------------------------
   14. Rank employees by performance within their department
   Goal: Use a window function to rank each employee's latest
         performance rating against peers in the same
         department, without collapsing rows like GROUP BY
         would. A subquery isolates the most recent PerfDate
         so each employee appears only once (their latest score).
   Result: RANK() correctly ties employees with equal ratings
           at the same rank and skips subsequent rank numbers
           (e.g. 8 employees tied at rank 1 in DepID 1, next
           rank is 9, not 2) - the expected behavior of RANK()
           as opposed to DENSE_RANK(), which would continue
           sequentially without gaps.
------------------------------------------------------------ */
SELECT
  e.EmpID,
  e.EmpName,
  e.DepID,
  p.Rating,
  p.PerfDate,
  RANK() OVER (PARTITION BY e.DepID ORDER BY p.Rating DESC) AS RankInDept
FROM tbl_Employee AS e
INNER JOIN tbl_Perf AS p ON e.EmpID = p.EmpID
WHERE p.PerfDate = (SELECT MAX(PerfDate) FROM tbl_Perf)
ORDER BY e.DepID, RankInDept;

/* ------------------------------------------------------------
   15. Department average rating alongside individual scores
   Goal: Show each employee's latest rating next to their
         department's average, without collapsing rows -
         demonstrating the key difference between a window
         function and GROUP BY (detail is preserved, not lost).
   Result: Every employee row in DepID 1 shows the same
           DeptAvgRating (2.93) alongside their own individual
           Rating, confirming the window function correctly
           applies the aggregate per partition while keeping
           row-level detail intact.
------------------------------------------------------------ */
SELECT
  e.EmpID,
  e.EmpName,
  e.DepID,
  p.Rating,
  ROUND(AVG(p.Rating) OVER (PARTITION BY e.DepID), 2) AS DeptAvgRating
FROM tbl_Employee AS e
INNER JOIN tbl_Perf AS p ON e.EmpID = p.EmpID
WHERE p.PerfDate = (SELECT MAX(PerfDate) FROM tbl_Perf)
ORDER BY e.DepID;
