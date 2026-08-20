select * from players;

select * from salaries;

select * from schools;

select * from school_details;

/*In each decade, how many schools were there that produced MLB players?*/

SELECT 
    ROUND(yearID, -1) AS decade,
    COUNT(DISTINCT schoolID) AS school_num
FROM schools
GROUP BY ROUND(yearID, -1)
ORDER BY decade;


/*What are the names of the top 5 schools that produced the most players?*/

SELECT 
	sd.name_full, 
    COUNT(DISTINCT pl.playerID) AS player_num 
FROM schools sc
INNER JOIN school_details sd
	ON sc.schoolID = sd.schoolID
LEFT JOIN players pl
	ON sc.playerID = pl.playerID
GROUP BY sd.name_full
ORDER BY player_num DESC
LIMIT 5;


/*For each decade, what were the names of the top 3 schools that produced the most players?*/

WITH grouped_year AS (
    SELECT 
        ROUND(sc.yearID, -1) AS decade,
        sd.name_full,
        COUNT(DISTINCT sc.playerID) AS player_num
    FROM schools sc
    LEFT JOIN school_details sd
        ON sc.schoolID = sd.schoolID
    GROUP BY 
        ROUND(sc.yearID, -1),
        sd.name_full
),

top_school AS (
    SELECT 
        decade,
        name_full,
        player_num,
        ROW_NUMBER() OVER (
            PARTITION BY decade 
            ORDER BY player_num DESC
        ) AS row_num
    FROM grouped_year
)

SELECT *
FROM top_school
WHERE row_num <= 3
ORDER BY decade, row_num;



/*Return the top 20% of teams in terms of average annual spending*/
WITH ts AS (
    SELECT 
        teamID,
        yearID,
        SUM(salary) AS total_spend
    FROM salaries
    GROUP BY teamID, yearID
),

ps AS (
    SELECT 
        teamID,
        AVG(total_spend) AS avg_salary,
        NTILE(5) OVER (
            ORDER BY AVG(total_spend) DESC
        ) AS percent_salary
    FROM ts
    GROUP BY teamID
)

SELECT 
    teamID,
    ROUND(avg_salary / 1000000, 2) AS avg_salary_millions
FROM ps
WHERE percent_salary = 1;


/*For each team, show the cumulative sum of spending over the years*/

WITH sp AS (
    SELECT 
        yearID,
        teamID,
        SUM(salary) AS salary_sum
    FROM salaries
    GROUP BY yearID, teamID
)

SELECT 
    teamID,
    yearID,
    ROUND(
        SUM(salary_sum) OVER (
            PARTITION BY teamID 
            ORDER BY yearID
        ) / 1000000, 
        2
    ) AS cum_sum
FROM sp
ORDER BY teamID, yearID;



/*Return the first year that each team’s cumulative spending surpassed 1 billion*/

WITH sp AS (
    SELECT 
        yearID,
        teamID,
        SUM(salary) AS salary_sum
    FROM salaries
    GROUP BY yearID, teamID
),

cs AS (
    SELECT 
        teamID,
        yearID,
        SUM(salary_sum) OVER (
            PARTITION BY teamID 
            ORDER BY yearID
        ) AS cum_sum
    FROM sp
),

ms AS (
    SELECT 
        teamID,
        yearID,
        cum_sum,
        ROW_NUMBER() OVER (
            PARTITION BY teamID 
            ORDER BY yearID
        ) AS rn
    FROM cs
    WHERE cum_sum > 1000000000
)

SELECT 
    teamID,
    yearID,
    ROUND(cum_sum / 1000000000, 2) AS cumulative_salary_billions
FROM ms
WHERE rn = 1
ORDER BY yearID;




/*For each player, calculate their age at their first (debut) game, their last game, and their career length (all in years). 
Sort from longest career to shortest career.*/


SELECT 
    nameGiven,
    TIMESTAMPDIFF(YEAR, DATE(CONCAT(birthYear, '-', birthMonth, '-', birthDay)), debut) as debut_age,
    TIMESTAMPDIFF(YEAR, DATE(CONCAT(birthYear, '-', birthMonth, '-', birthDay)), finalGame) as final_age,
    TIMESTAMPDIFF(YEAR, debut, finalGame) as careerlength
FROM players
ORDER BY careerlength DESC;


/*What team did each player play on for their starting and ending years?*/


SELECT 
    nameGiven,
	sa.yearID as debut_year,
    sa.teamID as debut_team,
	sal.yearID as final_year,
    sal.teamID as final_team
FROM players pl
INNER JOIN salaries sa
ON pl.playerID = sa.playerID and YEAR(pl.debut) = sa.yearID
INNER JOIN salaries sal
ON pl.playerID = sal.playerID and YEAR(pl.finalGame) = sal.yearID;



/*How many players started and ended on the same team and also played for over a decade?*/


SELECT 
    pl.nameGiven,
    sa.yearID AS debut_year,
    sa.teamID AS debut_team,
    sal.yearID AS final_year,
    sal.teamID AS final_team
FROM players pl
INNER JOIN salaries sa
    ON pl.playerID = sa.playerID
    AND YEAR(pl.debut) = sa.yearID
INNER JOIN salaries sal
    ON pl.playerID = sal.playerID
    AND YEAR(pl.finalGame) = sal.yearID
WHERE sa.teamID = sal.teamID
  AND (sal.yearID - sa.yearID) > 10;


/*Which players have the same birthday?*/

WITH bd AS (SELECT 
    nameGiven,
    DATE(CONCAT(birthYear, '-', birthMonth, '-', birthDay)) as birthdate
FROM players)

select birthdate, GROUP_CONCAT(nameGiven separator ', ') as players from bd
where birthdate is not null and year(birthdate) between 1980 and 1990
group by birthdate;


/*Create a summary table that shows for each team, what percent of players bat right, left and both.*/

WITH team_players AS (
    SELECT DISTINCT
        sa.teamID,
        pl.playerID,
        pl.bats
    FROM salaries sa
    INNER JOIN players pl
        ON pl.playerID = sa.playerID
)

SELECT 
    teamID,
    ROUND(SUM(CASE WHEN bats = 'R' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS bats_right,
    ROUND(SUM(CASE WHEN bats = 'L' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS bats_left,
	ROUND(SUM(CASE WHEN bats = 'B' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS bats_both
FROM team_players
GROUP BY teamID;


/*How have average height and weight at debut game changed over the years, and what’s the decade-over-decade difference?*/

WITH hw AS (
    SELECT 
        ROUND(YEAR(debut), -1) AS decade,
        AVG(height) AS avg_height,
        AVG(weight) AS avg_weight
    FROM players
    WHERE debut IS NOT NULL
    GROUP BY decade
)

SELECT 
    decade,
    ROUND(avg_height - LAG(avg_height) OVER (ORDER BY decade), 2) AS height_diff,
    ROUND(avg_weight - LAG(avg_weight) OVER (ORDER BY decade), 2) AS weight_diff
FROM hw
WHERE decade IS NOT NULL
ORDER BY decade;


