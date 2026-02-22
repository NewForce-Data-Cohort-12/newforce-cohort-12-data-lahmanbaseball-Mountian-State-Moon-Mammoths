-- Exercises (7-8) --

-- 7.
-- 	a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
SELECT MAX(w) AS most_wins_season_by_non_ws_winning_team_between_1970_and_2016
FROM teams
WHERE wswin = 'N'
	AND yearid BETWEEN 1970 AND 2016; -- Answer: 116

-- 	b. What is the smallest number of wins for a team that did win the world series?
SELECT MIN(w) AS least_wins_season_by_ws_winning_team_between_1970_and_2016
FROM teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016; -- Answer: 63
--		i. Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case.
--			Answer: the unusually small number of wins was most likely related to the 1-time "split season" structure implemented due to a player strike that year (1981).
-- 		ii. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
--			Answer: a top winning team won the world series during 12 years out of a possible 46 years leaving 36 years where this was not the case.
-- 		iii. What percentage of the time?
--			Answer: a top winning team won the world series 26% of the time between 1970 and 2016.
-- Setting up some CTEs to stay organized...
WITH
	-- Get all of the team world series and win data between 1970 and 2016 excluding 1981 due to the player strike.
	wins_by_team_year_and_wswin AS (
		SELECT yearid, teamid, COALESCE(wswin, 'N') AS wswin, w -- Replace any [null] wswin with 'N'.
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016 AND yearid <> 1981
		ORDER BY yearid, w
	)
	-- Get all the win/loss data while adding an additional column containing the `wins` value of the team(s) with the most wins corresponding to the year in that row.
	, wins_vs_most_wins_team_by_year AS (
		SELECT yearid AS year, teamid AS team, wswin, w AS wins, MAX(w) OVER(PARTITION BY yearid) AS max_wins -- Partition by year so we get the uncollapsed `max_wins` from that year only.
		FROM wins_by_team_year_and_wswin
	)
	-- Get the win/loss data only from the rows representing teams which acheived the `max_wins` value for that year (duplicate years possible if more than 1 team acheived the `max_wins` score).
	, most_wins_team_by_year AS (
		SELECT year, team, wswin, wins
		FROM wins_vs_most_wins_team_by_year
		WHERE wins = max_wins
	)
	-- Consolidate the win/loss data so that each year is represented once, teams which acheived the max `wins` are combined into a single category and any group of teams including a world series win maps to a 'Y' and any number of 'N' maps to a single 'N'.
	, top_team_wins_with_wswin_by_year AS (
		SELECT DISTINCT * FROM (
			SELECT year
				,  team
				,  CASE WHEN wswin LIKE '%Y%' THEN 'Y' ELSE 'N' END AS wswin
				,  wins
			FROM (
				SELECT year
					,  STRING_AGG(team, ',') OVER(PARTITION BY year) AS team
					,  STRING_AGG(wswin, ',') OVER(PARTITION BY year) AS wswin
					,  wins
				FROM most_wins_team_by_year
			)
		)
	)
	, count_years_when_top_winning_team_won_world_series AS (
		SELECT COUNT(*) AS count_years_top_team_won_ws FROM top_team_wins_with_wswin_by_year WHERE wswin = 'Y'
	)
	, count_years_when_top_winning_team_lost_world_series AS (
		SELECT COUNT(*) AS count_years_top_team_lost_ws FROM top_team_wins_with_wswin_by_year WHERE wswin = 'N'
	)
	, count_years_when_top_winning_team_won_vs_lost_world_series AS (
		SELECT *
		FROM count_years_when_top_winning_team_won_world_series
		CROSS JOIN count_years_when_top_winning_team_lost_world_series
	)
-- SELECT * FROM wins_by_team_year_and_wswin;
-- SELECT * FROM wins_vs_most_wins_team_by_year;
-- SELECT * FROM most_wins_team_by_year;
-- SELECT * FROM top_team_wins_with_wswin_by_year ORDER BY year, wins DESC;
-- SELECT * FROM count_years_when_top_winning_team_won_world_series;
-- SELECT * FROM count_years_when_top_winning_team_lost_world_series;
-- SELECT * FROM count_years_when_top_winning_team_won_vs_lost_world_series;
SELECT *
	,  ROUND(100.0 * count_years_top_team_won_ws / (count_years_top_team_won_ws + count_years_top_team_lost_ws), 0)::varchar || '%'
		AS percent_top_winning_team_won_world_series
FROM count_years_when_top_winning_team_won_vs_lost_world_series
;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
WITH
	-- Including all columns, get all rows from homegames where there were at least 10 wins during the 2016 season.
	avg_homegames_attendance AS (
		SELECT *
			,  attendance / games AS avg_attendance
		FROM homegames
		WHERE year = 2016 AND games >= 10
	),
	-- Replace the "park" id with its corresponding name from the parks table (using the park id to match) and the "team" id with its corresponding name from the teams table matched on the team id itself as well as the year id of interest (2016) and the league id carried over from the original homegames table.
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
	-- Get the Top 5 greatest average attendance records while including an extra column containing the row number (1 = greatest).
	top_5_max_avg_attendance AS (
		SELECT ROW_NUMBER() OVER(ORDER BY avg_attendance DESC) AS attendance_rank
			,  * FROM avg_named_homegames_attendance ORDER BY avg_attendance DESC LIMIT 5
	),
	-- Get the Top 5 least average attendance records while including an extra column containing the row number (1 = least).
	top_5_min_avg_attendance AS (
		SELECT ROW_NUMBER() OVER(ORDER BY avg_attendance) AS attendance_rank
			,  * FROM avg_named_homegames_attendance ORDER BY avg_attendance LIMIT 5
	)
-- Rename top 5 max/min to top/bottom 5 for clarity and join on the row number so that we can get all the info within the same 5 row summary.
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