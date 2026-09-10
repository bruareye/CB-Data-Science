/*
1. Los primeros cinco partidos, ordenados por `event_date` y `event_id`.
2. Total de filas,total de  `event_id` y total de `event_id` distintos.
3. Selecciones locales distintas.
4. Selecciones visitantes distintas.
5. Fecha mínima y fecha máxima del conjunto.
*/

-- Consulta 1 
SELECT TOP 5
    event_date,
    event_id
FROM Partidos

ORDER BY event_date, event_id;

-- Consulta 2 
SELECT COUNT(*) AS Total_Filas,
    COUNT(event_id) AS Total_event_id,
    COUNT(DISTINCT event_id) AS Total_event_id_distintos
FROM Partidos;

-- Consulta 3
SELECT DISTINCT(home_team)
FROM Partidos

-- Consulta 4
SELECT DISTINCT(away_team)
FROM Partidos

-- Consulta 5
SELECT
    MIN(event_date) as fecha_minima,
    MAX(event_date) as fecha_maxima
FROM Partidos

