-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
--	Assumptions/requirements/definitions:
--		"played in the league" - any player appearance
--		~~"for~at~least~10~years"~-~cumulative~distinct~years~of~appearance~is~>=~10~~ // Nevermind...
--		"for at least 10 years" - range of years between debut and finalgame (career_length) >= 10 irrespective of year-to-year participation // Instructor-recommended approach.
WITH career_stats AS (
	SELECT *, final_year - debut_year AS career_length
	FROM (
		SELECT playerid
			,  yearid
			,  namefirst
			,  namelast
			,  hr
			,  EXTRACT(YEAR FROM debut::date) AS debut_year
			,  EXTRACT(YEAR FROM finalgame::date) AS final_year
		FROM batting
		JOIN people
		USING(playerid)
		WHERE debut IS NOT NULL AND finalgame IS NOT NULL -- FROM batting [LEFT|INNER] JOIN people USING playerid alone produces 102816 rows where 6 contain [null] for both debut and finalgame; removing [null] career records yields 102810 as expected.
	)
)
,	veteran_career_stats AS (
	SELECT * FROM career_stats WHERE career_length >= 10
)
,	deduped_veteran_career_stats AS (
	SELECT DISTINCT	-- The upcoming window function will generate exact identical rows for each hr value in separate rows sharing the same playerid and yearid so we must remove the duplicates. If a certain player during a certain year has more than 1 hr value we consolidate by summing them.
		   playerid
		,  yearid
		,  namefirst
		,  namelast
		,  SUM(hr) OVER(PARTITION BY playerid, yearid) AS hr -- For all rows which represent a different homerun count for the same player in the same year, replace the `hr` column value with the total sum across all `hr` values in the window creating duplicate hr-consolidated rows.
		,  debut_year
		,  final_year
		,  career_length
	FROM veteran_career_stats
)
-- Get playerid of only players who acheived at least 1 homerun during 2016.
,	year_2016_homerun_hitters AS (
	SELECT playerid FROM deduped_veteran_career_stats WHERE yearid = 2016 AND hr >= 1
)
-- Filter the deduped players based on 2016 homerun hitting status.
,	year_2016_hr_hitting_vet_career_stats AS (
	SELECT * FROM deduped_veteran_career_stats JOIN year_2016_homerun_hitters USING(playerid)
)
-- Get all time career best homeruns in a year.
,	career_bests AS (
	SELECT playerid, MAX(hr) AS career_best_hrs
	FROM year_2016_hr_hitting_vet_career_stats
	GROUP BY playerid
)
-- Get 2016 homeruns.
,	career_2016s AS (
	SELECT playerid, hr AS career_2016_hrs
	FROM year_2016_hr_hitting_vet_career_stats
	WHERE yearid = 2016
)
-- Get homerun counts for all time career best year as well as 2016 to compare.
,	career_best_vs_2016 AS (
	SELECT *, career_best_hrs = career_2016_hrs AS best_year_is_2016 FROM career_bests JOIN career_2016s USING(playerid)
)
-- Final results...
SELECT DISTINCT
	   namefirst AS first_name
	,  namelast AS last_name
	,  career_2016_hrs AS homeruns_2016
FROM career_best_vs_2016
JOIN year_2016_hr_hitting_vet_career_stats
USING(playerid)
WHERE best_year_is_2016
; /* Answer(8):	"first_name"	"last_name"		"homeruns_2016"
				"Adam"			"Wainwright"	2
				"Angel"			"Pagan"			12
				"Bartolo"		"Colon"			1
				"Edwin"			"Encarnacion"	42
				"Francisco"		"Liriano"		1
				"Mike"			"Napoli"		34
				"Rajai"			"Davis"			12
				"Robinson"		"Cano"			39 */