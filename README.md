# MLB Players & Salaries SQL Analysis
 
A collection of SQL queries analyzing MLB player, salary, and college/school data. The queries progress from simple aggregations to window functions and multi-step CTEs, covering school pipelines, team spending trends, and player career/biographical patterns.
 
## Dataset
 
The queries run against four tables (a shape consistent with the Lahman Baseball Database)
 
| Table | Description |
|---|---|
| `players` | Biographical data per player — name, birth date, height/weight, batting hand, debut and final game dates |
| `salaries` | Player salary by team and year |
| `schools` | Links players to the schools/colleges they attended, by year |
| `school_details` | Reference data for each school (full name, location, etc.) |
 
## Requirements
 
- MySQL 8.0+ (queries use `TIMESTAMPDIFF`, `NTILE`, `ROW_NUMBER`, `LAG`, and other window functions / MySQL-specific syntax)
- The four tables above loaded with compatible schemas
## Contents
 
All queries live in [`major_league_football.sql`](./major_league_football.sql).
 
### Schools & player pipeline
 
- **Schools producing MLB players per decade** — counts distinct schools by decade to show how the college talent pipeline has grown over time.
- **Top 5 schools by player count** — the all-time schools that have sent the most players to MLB.
- **Top 3 schools per decade** — same ranking, broken out decade by decade using `ROW_NUMBER()` over a `PARTITION BY decade`.
### Team spending
 
- **Top 20% of teams by average annual spending** — buckets teams into quintiles with `NTILE(5)` and returns the top bucket.
- **Cumulative spending by team over time** — a running total of payroll per team using a windowed `SUM() OVER (PARTITION BY teamID ORDER BY yearID)`.
- **First year each team's cumulative spending passed $1B** — filters the running total down to each team's earliest qualifying year.
### Player careers
 
- **Age at debut, age at final game, and career length** — computed from birth date vs. `debut`/`finalGame`, sorted longest career first.
- **Team at debut vs. team at retirement** — joins `players` to `salaries` twice (once on debut year, once on final year) to see where careers started and ended.
- **Players who started and ended on the same team with a 10+ year career** — filters the above to one-team careers of meaningful length.
- **Players sharing a birthday** — groups players born 1980–1990 by birth date and concatenates the names that match.
### Demographics & physical trends
 
- **Batting-hand distribution by team** — the percent of each team's roster that bats right, left, or switch (`bats = 'B'`).
- **Decade-over-decade change in height and weight at debut** — averages height/weight by debut decade, then uses `LAG()` to show the change from the prior decade.
## Notes
 
- Decades are derived with `ROUND(yearID, -1)`, which rounds to the nearest 10 rather than the start of the decade (e.g., 1985 → 1990, not 1980). Keep this in mind when reading decade labels.
- Career-length and age calculations assume `birthYear`, `birthMonth`, and `birthDay` are all populated; rows with any of these missing will not produce a valid date.
- Salary figures in the spending queries are converted to millions (or billions) for readability.
## Usage
 
Individual queries can also be copied out and run independently — each is self-contained.
