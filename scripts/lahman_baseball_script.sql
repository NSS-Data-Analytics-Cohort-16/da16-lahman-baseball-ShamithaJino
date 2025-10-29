SELECT * FROM people
SELECT * FROM batting
SELECT * FROM appearances

-- 1. What range of years for baseball games played does the provided database cover? 
	SELECT 
		MIN(yearid) AS first_year, 
		Max(yearid) AS end_year
	FROM batting
	
-- 2. Find the name and height of the shortest player in the database. How many games did he play in?
--What is the name of the team for which he played?

-- NAME, HEIGHT, GAME_COUNT, TEAM_NAME

	SELECT 
		namefirst, 
		namelast,
		height,
	
		-- TO FIND GAME COUNT
		(SELECT 
			count(*)
		FROM appearances AS a
		WHERE a.playerid=p.playerid) AS game_count,

		-- TO FIND TEAM NAME
		
		(SELECT 
			name AS team_name 
		FROM teams AS t
		WHERE t.teamid IN (
							SELECT 
								a.teamid 
							FROM APPEARANCES AS a
							WHERE a.playerid = p.playerid
							)
		LIMIT 1
		) AS team_name
	FROM people AS p
	WHERE height = (SELECT MIN(height) FROM people)




-- 3. Find all players in the database who played at Vanderbilt University.
--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

-- players at Vanderbilt University, players first and last name, total salary 

	SELECT	
		CONCAT(namefirst,' ', namelast) AS full_name,
		--total salary
		(
			SELECT 
				COALESCE (SUM(salary)::numeric::money,0::money) 
			FROM salaries AS s
			WHERE s.playerid = p.playerid
		) AS total_salary
		
	FROM people AS p
	WHERE p.playerid IN 
						(
						SELECT c.playerid FROM collegeplaying AS c
						WHERE c.schoolid IN (SELECT schoolid FROM schools WHERE schoolname = 'Vanderbilt University')
						)
	ORDER bY total_salary DESC
	LIMIT 5

-- 4. Using the fielding table, group players into three groups based on their position: 
--label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
--and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

-- 3 groups and putouts per each group

	SELECT 
		CASE 
			WHEN pos ='OF' THEN 'Outfield'
			WHEN pos='SS' OR pos='1B' OR pos='2B' OR pos='3B' THEN 'Infield'
			WHEN pos ='P' OR pos='C' THEN 'Battery'
		END AS groups,
		SUM(po) AS total_putouts
	FROM fielding
	GROUP BY groups
  
	   
-- 5. Find the average number of strikeouts per game by decade since 1920. 
--Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
  

	SELECT 
		
		FLOOR(yearid/10)*10 AS decades,
		ROUND(SUM(so):: NUMERIC/ SUM(g) :: NUMERIC,2 ) AS avg_strikeouts_per_game,
		ROUND(SUM(hr):: NUMERIC/ SUM(g) :: NUMERIC,2) AS avg_homeruns_per_game
	from teams 
	where yearid >=1920
	GROUP BY decades 
	ORDER BY decades ASC
	

-- 6. Find the player who had the most success stealing bases in 2016, 
--where __success__ is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) 
--Consider only players who attempted _at least_ 20 stolen bases.

		
	SELECT 
		CONCAT(namefirst,' ',namelast) AS fullname,
		SUM(s.sb) AS sb,
		SUM(s.attempts) AS attempts,
		(SUM(s.sb):: numeric/SUM(s.sb+s.cs))*100  AS percent
		
	FROM people AS p
	INNER JOIN (
				SELECT 
					playerid,
					yearid,
					sb,
					cs,
					sb+cs AS attempts										
				FROM batting
	
				) AS s
				
	ON p.playerid = s.playerid
	WHERE s.attempts>=20 AND s.yearid = 2016
	GROUP BY fullname
	ORDER BY percent DESC
	LIMIT 7
	

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--What is the smallest number of wins for a team that did win the world series? 
--Doing this will probably result in an unusually small number of wins for a world series champion – 
--determine why this is the case. Then redo your query, excluding the problem year. 
--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
	WITH most_wins AS (
		SELECT
			yearid,
			MAX(w) AS w
		FROM teams
		WHERE yearid >= 1970
		GROUP BY yearid
		ORDER BY yearid
		),
	most_win_teams AS (
		SELECT 
			yearid,
			name,
			wswin
		FROM teams
		INNER JOIN most_wins
		USING(yearid, w)
	)
	SELECT 
		(SELECT COUNT(*)
		 FROM most_win_teams
		 WHERE wswin = 'N'
		) * 100.0 /
		(SELECT COUNT(*)
		 FROM most_win_teams
		);
  
-- 8. Using the attendance figures from the homegames table, 
--find the teams and parks which had the top 5 average attendance per game in 2016 
--(where average attendance is defined as total attendance divided by number of games). 
--Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. 
--Repeat for the lowest 5 average attendance.
	-- TEAMS, PARKS, TOT_attendance/NO_OF_GAMES
	
	SELECT 
		park_name, 
		sum(attendance),
		state,
		sum(games),
		SUM(attendance)/sum(games) as avg_attendance 
	FROM homegames AS h
	INNER JOIN (
				SELECT 
					park,
					park_name, 
					state
				FROM parks
				) AS t

	ON h.park =t.park
	WHERE year =2016 AND games>=10
	GROUP BY park_name, state
	ORDER BY avg_attendance DESC
	LIMIT 5
	
select * from parks
-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)?
--Give their full name and the teams that they were managing when they won the award.
-- FULL_NAME, TEAM_NAME, YEARID, LEAGUES

		with cte1 AS(
				SELECT playerid FROM awardsmanagers
				WHERE awardid ='TSN Manager of the Year'
				AND  (lgid ='NL' OR lgid ='AL')
				group by playerid
				having count(distinct lgid)=2
		)
		
		SELECT 
			concat(namefirst,' ',namelast),
			m.yearid,
			t.name
		FROM people as p
		INNER JOIN cte1
		using(playerid)
		INNER JOIN awardsmanagers AS am
		using(playerid)
		INNER JOIN managers as m
		using(playerid, yearid, lgid)
		INNER JOIN teams AS t
		using(yearid, teamid,lgid)
		WHERE am.awardid ='TSN Manager of the Year'
		ORDER BY m.yearid


-- 10. Find all players who hit their career highest number of home runs in 2016.
--Consider only players who have played in the league for at least 10 years, 
--and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

 WITH career_highest_hr AS (
	  SELECT 
	  playerid, 
	  MAX(hr) AS highest_hr,
	  COUNT(DISTINCT yearid) AS total_years
	  FROM 
		  (
		  SELECT playerid, yearid,SUM(hr) AS hr
		  FROM batting
		  GROUP BY playerid, yearid
		  )
	  GROUP BY playerid
  ),

  homeruns_2016 AS (
	SELECT playerid, SUM(hr) AS hr_2016 FROM batting 
	WHERE yearid= 2016
	GROUP BY playerid
	HAVING SUM(hr)>0

  )

  SELECT concat(namefirst,' ',namelast) AS fullname,hr_2016
  FROM people AS p
  INNER JOIN career_highest_hr AS c
  USING(playerid)
  INNER JOIN homeruns_2016 AS h
  USING(playerid)
  WHERE c.total_years >=10 AND h.hr_2016 = c.highest_hr



-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary?
--Use data from 2000 and later to answer this question. As you do this analysis, 
--keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
	
	with games_won as (
				SELECT 
					yearid, 
					teamid, 
					SUM(w) AS total_wins
				FROM teams
				WHERE yearid>=2000
				GROUP BY yearid, teamid
						),
	team_salary as(
				SELECT 
					yearid, 
					teamid, 
					SUM(salary) AS total_salary
				FROM salaries
				WHERE yearid>=2000
				GROUP BY yearid, teamid
				)
		
	SELECT 	
		gw.yearid AS yearid,
		gw.teamid AS teamid,
		total_wins,
		total_salary
	FROM games_won AS gw
	INNER JOIN team_salary AS ts
	USING(yearid)
	WHERE yearid DESC
	
-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

