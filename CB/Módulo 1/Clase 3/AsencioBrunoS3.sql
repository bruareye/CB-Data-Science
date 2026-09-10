-- TO-DO 1 — Conteo global y completitud
-- 1. Cuenta todas las filas de dbo.Partidos con COUNT(*).
-- 2. Cuenta los event_id informados y los event_id distintos.
-- 3. Cuenta los valores informados de group_name y round_name.
-- Resultado esperado: una sola fila con controles de volumen y completitud.

SELECT COUNT(*),
    COUNT(event_id),
    COUNT(DISTINCT event_id),
    COUNT(group_name),
    COUNT(round_name)
FROM Partidos;


-- TO-DO 2 — Métricas globales del torneo
-- 1. Calcula los goles locales, visitantes y totales de toda la tabla.
-- 2. Calcula el promedio de goles por partido.
-- 3. Incluye el mínimo y el máximo de goles registrados en un partido.
-- Resultado esperado: una sola fila con el resumen global del torneo.

SELECT SUM(home_score) as GLocales,
SUM(away_score) as GVisitante,
SUM(home_score + away_score) as goles_totales,
AVG(home_score + away_score),
    MIN(home_score + away_score) as minimo_goles,
    MAX(home_score + away_score) as maximo_goles
FROM Partidos;


-- TO-DO 3 — Resumen por grupo
-- 1. Conserva únicamente los valores de group_name que comiencen con Group.
-- 2. Agrupa por group_name y calcula partidos, goles totales y promedio de goles.
-- 3. Ordena por group_name.
-- Resultado esperado: una fila por grupo del Mundial.

SELECT
    group_name,
    COUNT(*) AS PARTIDOS,
    SUM(home_score + away_score) AS goles_totales,
    AVG(CAST(home_score + away_score as decimal(10, 2))) as promedio_goles
FROM Partidos
WHERE group_name LIKE N'Group%'
GROUP BY group_name
ORDER BY group_name;

--  TO-DO 4 — Grupos de alta anotación
-- 1. Calcula el promedio de goles por grupo.
-- 2. Conserva promedios de 2,5 o más.
-- 3. Ordena de mayor a menor promedio.
-- Resultado esperado: solo grupos que superen el umbral.

SELECT
    group_name,
    COUNT(*) AS PARTIDOS,
    SUM(home_score + away_score) AS goles_totales,
    AVG(CAST(home_score + away_score as decimal(10, 2))) as promedio_goles
FROM Partidos
WHERE group_name LIKE N'Group%'
GROUP BY group_name
HAVING AVG(CAST(home_score + away_score as decimal(10, 2))) >= 2.5
ORDER BY group_name;


--  TO-DO 5 — Distribución de marcadores
-- 1. Agrupa por home_score y away_score.
-- 2. Cuenta cuántos partidos terminaron con cada marcador.
-- 3. Ordena por cantidad de partidos descendente y luego por marcador.
-- Resultado esperado: una fila por combinación de marcador local y visitante.

SELECT home_score,
    away_score,
    COUNT (*) AS partidos
FROM Partidos
GROUP BY home_score, away_score
ORDER BY partidos DESC, home_score, away_score;


-- TO-DO 6 — Fases ordenadas por promedio de goles
-- 1. Agrupa por round_name y excluye los valores vacíos.
-- 2. Calcula partidos, goles totales y promedio de goles.
-- 3. Ordena de mayor a menor promedio y luego por round_name.
-- Resultado esperado: una fila por fase, priorizada por intensidad goleadora.

SELECT round_name,
    COUNT (*) AS partidos,
    SUM(home_score + away_score) AS goles_totales,
    AVG(CAST(home_score + away_score as decimal(10, 2))) as promedio_goles

FROM Partidos
WHERE round_name IS NOT NULL
GROUP BY round_name
ORDER BY promedio_goles DESC, round_name;


-- TO-DO 7 — Volumen de tiros por partido
-- 1. Cuenta tiros y event_id distintos.
-- 2. Resume tiros por event_id.
-- 3. Conserva partidos con al menos 25 tiros mediante HAVING.
-- Resultado esperado: una fila por partido que supere el umbral.

SELECT COUNT(*) AS total_tiros,
    COUNT(DISTINCT event_id) AS partidos_distintos
FROM Tiros;

SELECT event_id,
    COUNT(*) as tiros
FROM Tiros 
GROUP BY event_id
HAVING COUNT(*) >= 25
ORDER BY Tiros DESC


-- TO-DO 8 — Calidad por resultado del tiro
-- 1. Agrupa dbo.Tiros por type.
-- 2. Calcula cantidad de tiros, promedio de xg y máximo de xg.
-- 3. Conserva tipos con al menos 10 tiros y ordena por cantidad descendente.
-- Resultado esperado: una fila por tipo de resultado con volumen suficiente.

SELECT type,
    COUNT(*) AS tiros,
    AVG(CAST(xg AS DECIMAL(10, 2))) AS promedio_xg,
    MAX(xg) AS max_xg
FROM Tiros 
GROUP BY type 
HAVING COUNT(*) >= 10
ORDER BY Tiros DESC
