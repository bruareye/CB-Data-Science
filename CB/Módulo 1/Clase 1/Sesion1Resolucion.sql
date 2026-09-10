/* SESION 1 - TO-DO: Primeras consultas sobre partidos del Mundial 2026

   Tabla principal:
   - dbo.Partidos, cargada desde archive/post_match_details.csv

   Objetivo:
   Explorar la tabla, reconocer su granularidad y escribir consultas SELECT basicas.
*/

-- TAREA 1. Muestra todas las columnas de dbo.Partidos.
SELECT * FROM PARTIDOS

-- TAREA 2. Muestra solo 10 filas para revisar una muestra inicial.

SELECT TOP 10 * FROM PARTIDOS

-- TAREA 3. Selecciona las columnas clave:
-- event_id, event_date, home_team, away_team, home_score, away_score.
SELECT event_id, event_date, home_team, away_team, home_score, away_score 
FROM PARTIDOS

-- TAREA 4. Usa alias en espanol:
-- equipo_local, equipo_visitante, goles_local, goles_visitante.
SELECT  event_id, 
		event_date, 
		home_team AS EQUIPO_LOCAL, 
		away_team AS EQUIPO_VISITANTE, 
		home_score AS GOLES_LOCAL, 
		away_score AS GOLES_VISITANTE 
FROM PARTIDOS


-- TAREA 5. Lista los grupos disponibles sin repetir valores.
SELECT DISTINCT GROUP_NAME 
FROM PARTIDOS

-- TAREA 6. Lista las fases disponibles sin repetir valores.
SELECT DISTINCT ROUND_NAME 
FROM PARTIDOS


-- TAREA 7. Muestra una consulta que permita responder:
-- que representa cada fila de dbo.Partidos?




-- RETO. Escribe como comentario una pregunta analitica que quieras seguir
-- durante el curso usando este dataset.
