-- TO-DO 1 — Tipos de datos y operadores
-- 1. Muestra 10 filas con event_id, event_date, equipos y marcador.
-- 2. Añade goles_totales mediante home_score + away_score.
-- 3. Ejecuta 10 + 5 y N'10' + N'5'; registra ambos resultados.

USE MundialDB;
SELECT TOP 10
    event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    home_score + away_score as goles_totales

FROM partidos


--  TO-DO 2 — Filtro exacto con WHERE
-- 1. Muestra los partidos cuyo group_name sea Group A.
-- 2. Conserva event_id, event_date, equipos, marcador y group_name.
-- 3. Comprueba que todas las filas devueltas tengan group_name = Group A.
-- Resultado esperado: 6 partidos.

SELECT 
    event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name,

FROM partidos
WHERE group_name = 'Group A'


-- TO-DO 3 — AND, OR e IN
-- 1. Muestra partidos de Group A o Group B usando IN.
-- 2. Añade status = finished mediante AND.
-- 3. Repite el filtro con OR y paréntesis; ambos resultados deben coincidir.
-- Resultado esperado: 12 partidos.

SELECT
    event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name,
    status

FROM partidos
WHERE group_name IN ('Group A', 'Group B') AND status = 'finished'


SELECT
    event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name,
    status

FROM partidos
WHERE (group_name = 'Group A' OR group_name = 'Group B') AND status = 'finished'


-- TO-DO 4 — BETWEEN y LIKE
-- 1. Muestra partidos entre el 11 y el 30 de junio de 2026.
-- 2. Conserva únicamente group_name que comience con Group.
-- 3. Devuelve event_id, event_date, equipos, marcador y group_name.

SELECT
    event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name

FROM partidos
WHERE event_date BETWEEN '2026-06-11' AND '2026-06-30' 
AND group_name like 'Group%'


-- TO-DO 5 — ORDER BY y TOP
-- 1. Filtra partidos de Group A o Group B.
-- 2. Calcula goles_totales y conserva valores de 4 o más.
-- 3. Devuelve los primeros 10 por goles_totales descendente y event_id ascendente.

SELECT
    event_id,
    event_date,
    home_team,
    away_team,
    home_score,
    away_score,
    group_name,
    home_score + away_score as goles_totales

FROM partidos
WHERE group_name IN ('Group A', 'Group B')
AND home_score + away_score >= 4
ORDER BY home_score + away_score DESC


-- TO-DO 6 — COUNT y DISTINCT
-- 1. Cuenta todas las filas de dbo.Partidos.
-- 2. Cuenta los event_id distintos.
-- 3. Cuenta partidos de fase de grupos con group_name LIKE N'Group%'.
-- 4. Comprueba que COUNT(*) y COUNT(DISTINCT event_id) coincidan.

SELECT 
    COUNT(*),
    COUNT(DISTINCT event_id) 
from Partidos

SELECT 
    count(*)
from Partidos
WHERE round_name IS NOT NULL