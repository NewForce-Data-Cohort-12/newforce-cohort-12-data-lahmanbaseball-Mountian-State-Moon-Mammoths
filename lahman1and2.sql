-- 1. What range of years for baseball games played does the provided database cover?

SELECT MIN(span_first), MAX(span_last) 
FROM homegames;

SELECT MIN(year), MAX(year)
FROM homegames;


-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT p.namefirst, p.namelast, p.height, a.g_all, t.name
FROM people p
JOIN appearances a ON p.playerID = a.playerID
JOIN teams t ON t.yearid = a.yearid
AND t.yearid  = a.yearid
WHERE height = (SELECT MIN(height) FROM people)
GROUP BY p.playerid, p.namefirst, p.namelast, p.height, a.g_all, t.name
ORDER BY height;

SELECT p.namefirst, p.namelast, p.height,
SUM(a.g_all) AS games_played,
t.name AS team_name
FROM people p
JOIN appearances a
ON a.playerid = p.playerid
JOIN teams t
ON t.yearid = a.yearid
AND t.teamid = a.teamid
WHERE p.height = (SELECT MIN(height) FROM people)
GROUP BY p.playerid, p.namefirst, p.namelast, p.height, t.name
ORDER BY games_played DESC;
