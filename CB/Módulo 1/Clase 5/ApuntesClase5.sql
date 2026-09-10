SELECT TOP 10 *
FROM Partidos 
WHERE home_team = 'Ecuador' or away_team = 'Ecuador'

SELECT *
FROM Tiros
Where event_id = 8342

SELECT *
FROM Partidos AS p
INNER JOIN Tiros AS t
ON p.event_id = t. event_id
where p.event_id = 8342

SELECT *
FROM Partidos AS p
INNER JOIN EstadisticasPartido AS t
ON p.event_id = t.event_id 

-- INNER JOIN
SELECT p.event_date, p.home_team, p.away_team, p.home_score, p.away_score, e.home_ball_possession, e.away_ball_possession
FROM Partidos AS p
INNER JOIN EstadisticasPartido AS e
ON p.event_id = e.event_id 

-- LEFT JOIN
SELECT P.event_id, p.home_team, p.away_team, e.home_ball_possession
FROM Partidos AS p
LEFT JOIN EstadisticasPartido AS e
ON p.event_id = e.event_id and e.home_ball_possession >= 55


-- 1:N LEFT JOIN 
SELECT p.event_id, COUNT(t.[sequence]) as tiros, SUM(COALESCE(t.xg, 0)) as xg
FROM Partidos as p
LEFT JOIN Tiros as t
ON p.event_id = t.event_id
GROUP BY p.event_id, t.type
ORDER BY 1