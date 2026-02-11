-- Exercises (7-8) --

-- 7. -- WIP: #7 answers and queries not final, just scratch.
-- 	a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
SELECT *, MAX(w) OVER() AS wins
FROM teams
WHERE wswin = 'N';
LIMIT 100;
SELECT * FROM teams ORDER BY teamid;
-- 	b. What is the smallest number of wins for a team that did win the world series? 		i. Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case.
-- 		ii. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
-- 		iii. What percentage of the time?

-- 8.
-- 	a. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance.
-- 	b. Repeat for the lowest 5 average attendance.
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