select count(group_name), count(*), count(round_name), count(event_id)
from Partidos
where group_name IS NOT NULL

select group_name, count(*)
from Partidos;

-- Podemos usar un varchar para poder reemplazar la nueva columna con un nuevo texto o valor
select COALESCE(group_name, 'Fase Eliminatoria')
from Partidos

-- De igual manera para poder reemplazar con el valor/texto de otra columna
select COALESCE(group_name, round_name)
from Partidos

-- Podemos asignar nombres con AS para que la nueva columna pueda ser identificada más fácilmente
SELECT COALESCE(group_name, NULL, 'Rondas Eliminatorias') as 'Nombre de ronda'
from Partidos

SELECT COALESCE(group_name, round_name, 'Rondas Eliminatorias') as 'Nombre de ronda'
from Partidos


-- CASE
select event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name,
    CASE
        WHEN home_score > away_score THEN 'Local'
        WHEN away_score = home_score THEN 'Empate'
        ELSE 'Visitante'
    END AS Resultado,

    CASE 
        WHEN group_name like 'Group%' THEN 'Grupo'
        WHEN group_name is NULL THEN 'Eliminatorias'
    END AS Ronda

FROM Partidos 
WHERE home_team = 'Ecuador' or away_team = 'Ecuador'


-- Crear rangos de GOLES TOTALES por partido
-- entre 0 y 3 'Menos 3'
-- 3 y 5 'Entre 3 y 5'
-- 5 'Mas de 5'

select event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name,

    CASE
        WHEN home_score > away_score THEN 'Local'
        WHEN away_score = home_score THEN 'Empate'
        ELSE 'Visitante'
    END AS Resultado,

    CASE
        WHEN home_score + away_score <= 3 THEN 'Rango (0,3)'
        WHEN home_score + away_score <= 5 THEN 'Rango (3,5)'
        ELSE 'Rango (>5)'
    END AS RangoGoles,

    CASE 
        WHEN group_name like 'Group%' THEN 'Grupo'
        WHEN group_name is NULL THEN 'Eliminatorias'
    END AS Ronda

FROM Partidos 


-- 1h10 revisar grabación
select 
    CASE
        WHEN home_score + away_score <= 3 THEN 'Rango (0,3)'
        WHEN home_score + away_score <= 5 THEN 'Rango (3,5)'
        ELSE 'Rango (>5)'
    END AS RangoGoles,

    CASE 
        WHEN group_name like 'Group%' THEN 'Grupo'
        WHEN group_name is NULL THEN 'Eliminatorias'
    END AS Ronda,

    count(*)

FROM Partidos
GROUP BY
    CASE
        WHEN home_score + away_score <= 3 THEN 'Rango (0,3)'
        WHEN home_score + away_score <= 5 THEN 'Rango (3,5)'
        ELSE 'Rango (>5)'
    END,
    CASE
        WHEN group_name like 'Group%' THEN 'Grupo'
        WHEN group_name is NULL THEN 'Eliminatorias'
    END;


select event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name,
    CASE
        WHEN home_score + away_score <= 3 THEN 'Rango (0,3)'
        WHEN home_score + away_score <= 5 THEN 'Rango (3,5)'
        ELSE 'Rango (>5)'
    END AS RangoGoles,

    CASE 
        WHEN group_name like 'Group%' THEN 'Grupo'
        WHEN group_name is NULL THEN 'Eliminatorias'
    END AS Ronda

FROM Partidos

-- Partido Ganador
SELECT group_name,
    CASE 
        WHEN home_score > away_score THEN 1
        ELSE 0
    END AS Ganador
FROM Partidos
WHERE group_name IS NOT NULL

-- SUM()
SELECT group_name,
    SUM(CASE 
        WHEN home_score > away_score THEN 1
        ELSE 0
    END) Total
FROM Partidos
WHERE group_name IS NOT NULL
GROUP BY group_name