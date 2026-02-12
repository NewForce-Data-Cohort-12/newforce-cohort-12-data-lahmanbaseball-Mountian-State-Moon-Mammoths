-- Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
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

-- Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
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
