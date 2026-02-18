-- What range of years for baseball games played does the provided database cover?

SELECT MIN(year) as start_year, MAX(year) as last_year FROM homegames;

-- Answer 1871 - 2016

-- Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
 SELECT playerid, namefirst, namelast, height FROM people
 ORDER BY height
 LIMIT 1;

 WITH ( SELECT namefirst, namelast, height FROM people
 ORDER BY height
 LIMIT 1) AS shortest_player
 SELECT shortest_player.playerid, shortest_player.namefirst, shortest_player.namelast, 

-- 3.) Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT 
    p.namefirst,
    p.namelast,
    SUM(sal.salary) AS total_salary
FROM collegeplaying cp
INNER JOIN schools sch
ON cp.schoolid = sch.schoolid
INNER JOIN people p
ON cp.playerid = p.playerid
INNER JOIN salaries sal
ON cp.playerid = sal.playerid
WHERE sch.schoolname = 'Vanderbilt University'
GROUP BY p.playerid, p.namefirst, p.namelast
ORDER BY total_salary DESC;

--4.)  Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT 
CASE 
WHEN pos = 'OF' THEN 'Outfield'
WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
WHEN pos IN ('P', 'C') THEN 'Battery'
END AS position_group,
SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position_group
ORDER BY total_putouts DESC;


-- 5.)Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?




SELECT 
    (yearid / 10) * 10 AS decade, 
	 ROUND(SUM(SO::NUMERIC)  / SUM(g::NUMERIC) , 2) as so_per_game,
	 ROUND(SUM(hr::NUMERIC)  / SUM(g::NUMERIC) , 2) as hr_per_game
FROM pitching
WHERE yearID >= 1920
GROUP BY (yearid / 10) *10
ORDER BY decade ASC;


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT
	batting.playerid ,
	people.namefirst ,
	people.namelast ,
(sb + cs) AS steal_attempts
FROM batting
LEFT JOIN people ON batting.playerid = people.playerid
WHERE (sb + cs) >= 20 AND batting.yearid = 2016
ORDER BY steal_attempts DESC;


-- 7.) From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT *, MAX(w) OVER() AS wins
FROM teams
WHERE wswin = 'N';
LIMIT 100;
SELECT * FROM teams ORDER BY teamid;

-- 8.) Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

WITH
	avg_homegames_attendance AS (
		SELECT *
			,  attendance / games AS avg_attendance
		FROM homegames
		WHERE year = 2016 AND games >= 10
	),
	avg_named_homegames_attendance AS (
		SELECT parks.park_name AS park
			,  teams.name AS team
			,  avg_attendance
		FROM avg_homegames_attendance
		LEFT JOIN parks
		USING(park)
		LEFT JOIN teams
		ON avg_homegames_attendance.team = teams.teamid
			AND avg_homegames_attendance.league = teams.lgid
			AND avg_homegames_attendance.year = teams.yearid
	),
	top_5_max_avg_attendance AS (
		SELECT ROW_NUMBER() OVER(ORDER BY avg_attendance DESC) AS attendance_rank
			,  * FROM avg_named_homegames_attendance ORDER BY avg_attendance DESC LIMIT 5
	),
	top_5_min_avg_attendance AS (
		SELECT ROW_NUMBER() OVER(ORDER BY avg_attendance) AS attendance_rank
			,  * FROM avg_named_homegames_attendance ORDER BY avg_attendance LIMIT 5
	)
SELECT
	top_5_max_avg_attendance.park AS top_5_park,
	top_5_max_avg_attendance.team AS top_5_team,
	top_5_max_avg_attendance.avg_attendance AS top_5_avg_attendance,
	top_5_min_avg_attendance.park AS bottom_5_park,
	top_5_min_avg_attendance.team AS bottom_5_team,
	top_5_min_avg_attendance.avg_attendance AS bottom_5_avg_attendance
FROM top_5_max_avg_attendance
JOIN top_5_min_avg_attendance
USING(attendance_rank)
;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- solution 1

SELECT 
    people.nameFirst, 
    people.nameLast, 
    COUNT(DISTINCT AwardsManagers.lgID) AS leagues_won,
    STRING_AGG(DISTINCT AwardsManagers.lgID, ' ' ORDER BY AwardsManagers.lgID) AS league_list,
	STRING_AGG(DISTINCT teams.name, ' ' ORDER BY teams.name) AS team_list
FROM AwardsManagers
JOIN people ON AwardsManagers.playerID  = people.playerID
JOIN managers ON AwardsManagers.playerid = managers.playerid
JOIN teams ON managers.teamid = teams.teamid AND teams.yearid = managers.yearid
WHERE AwardsManagers.lgID IN ('AL', 'NL') 
	AND AwardsManagers.awardid LIKE 'TSN Manager of the Year'
GROUP BY AwardsManagers.playerID, people.nameFirst, people.nameLast
HAVING COUNT(DISTINCT AwardsManagers.lgID) >= 2
ORDER BY leagues_won DESC, people.nameLast ASC;

-- solution 2

SELECT 
    people.nameFirst, 
    people.nameLast, 
	teams.name
	AwardsManagers.yearid
	(SELECT playerid
FROM awardsmanagers am
INNER JOIN managers m
USING (playerid, yearid)
WHERE awardid = 'TSN Manager of the Year' AND am.lgid IN ('AL', 'NL')
GROUP BY playerid
HAVING COUNT(DISTINCT am.lgid) > 1;)




-- solution 3

WITH al_nl_tsn_winners AS (
	SELECT playerID
	FROM awardsmanagers 
	WHERE awardID = 'TSN Manager of the Year'
	    AND lgID IN ('AL')
	INTERSECT
	SELECT playerID
	FROM awardsmanagers
	WHERE awardID = 'TSN Manager of the Year'
	    AND lgID IN ('NL')
)

SELECT namefirst, namelast, awardsmanagers.yearid, awardsmanagers.lgid, awardid, teams.name
FROM people
INNER JOIN awardsmanagers
USING(playerid)
INNER JOIN managers
USING(playerid, yearid)
INNER JOIN teams
USING(teamid, yearid)
WHERE playerid IN (SELECT * FROM al_nl_tsn_winners)
	AND awardID = 'TSN Manager of the Year';

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


SELECT
p.namefirst,
p.namelast,
SUM(b.hr) AS hr_2016
FROM batting b
INNER JOIN people p
ON p.playerid = b.playerid
WHERE b.yearid = 2016
GROUP BY p.playerid, p.namefirst, p.namelast, p.debut, p.finalgame
HAVING SUM(b.hr) >= 1
AND (
EXTRACT(YEAR FROM COALESCE(p.finalgame::date, DATE '2016-12-31'))
- EXTRACT(YEAR FROM p.debut::date) + 1
) >= 10
AND SUM(b.hr) = (
SELECT MAX(hr_year)
FROM (
SELECT SUM(b2.hr) AS hr_year
FROM batting b2
WHERE b2.playerid = p.playerid
GROUP BY b2.yearid
) sub
)
ORDER BY hr_2016 DESC, p.namelast, p.namefirst;




