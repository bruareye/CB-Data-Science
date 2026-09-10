/*
Parte A – Perfil por fase
Agrupar dbo.Partidos por round_name y calcular:

partidos;
goles locales;
goles visitantes;
goles totales;
promedio, mínimo y máximo de goles.
Excluir fases vacías y ordenar por promedio de goles descendente.
*/

SELECT
    round_name,
    COUNT(*) AS partidos,
    SUM(home_score) AS goles_locales,
    SUM(away_score) AS goles_visitante,
    SUM(home_score + away_score) AS goles_totales,
    AVG((home_score + away_score) * 1.0) AS promedio_goles,
    MIN(home_score + away_score) AS minimo_goles,
    MAX(home_score + away_score) AS maximo_goles
FROM Partidos
WHERE round_name IS NOT NULL
GROUP BY round_name
ORDER BY promedio_goles DESC;

/*
Parte B – Distribución de marcadores
Agrupar por home_score y away_score. Calcular cuántos partidos terminaron con cada marcador y mostrar únicamente marcadores repetidos en dos o más partidos mediante HAVING.

Ordenar por cantidad de partidos descendente, home_score y away_score.
*/

SELECT
    home_score,
    away_score,
    COUNT(*) AS cantidad_partidos
FROM Partidos
GROUP BY home_score, away_score
HAVING COUNT(*) >= 2
ORDER BY cantidad_partidos DESC, home_score, away_score;

/*
Parte C – Rendimiento según condición
Entregar dos consultas independientes:

Perfil de cada selección cuando aparece como local: partidos, goles a favor, goles en contra, diferencia y promedio de goles a favor.
Perfil de cada selección cuando aparece como visitante: las mismas métricas usando las columnas correspondientes.
No se deben combinar ambos resultados.
*/

SELECT
    home_team AS seleccion,
    COUNT(*) AS partidos,
    SUM(home_score) AS goles_a_favor,
    SUM(away_score) AS goles_en_contra,
    SUM(home_score) - SUM(away_score) AS diferencia,
    AVG(home_score * 1.0) AS promedio_goles_a_favor
FROM Partidos
GROUP BY home_team
ORDER BY seleccion;

SELECT
    away_team AS seleccion,
    COUNT(*) AS partidos,
    SUM(away_score) AS goles_a_favor,
    SUM(home_score) AS goles_en_contra,
    SUM(away_score) - SUM(home_score) AS diferencia,
    AVG(away_score * 1.0) AS promedio_goles_a_favor
FROM Partidos
GROUP BY away_team
ORDER BY seleccion;


/*
Parte D – Umbrales analíticos
Mostrar grupos con promedio de 2,5 o más goles por partido.
Mostrar selecciones locales con tres o más partidos y promedio de al menos 1,5 goles locales.
Mostrar fases que acumularon diez o más goles.
Cada filtro agregado debe implementarse con HAVING.
*/

-- Punto 1
SELECT
    group_name AS grupo,
    COUNT(*) AS partidos,
    AVG((home_score + away_score) * 1.0) AS promedio_goles
FROM Partidos
WHERE group_name IS NOT NULL
GROUP BY group_name
HAVING AVG((home_score + away_score) * 1.0) >= 2.5
ORDER BY promedio_goles DESC;

-- Punto 2
SELECT
    home_team AS seleccion,
    COUNT(*) AS partidos,
    AVG(home_score * 1.0) AS promedio_goles_locales
FROM Partidos
GROUP BY home_team
HAVING COUNT(*) >= 3
    AND AVG(home_score * 1.0) >= 1.5
ORDER BY promedio_goles_locales DESC;

-- Punto 3
SELECT
    round_name AS fase,
    SUM(home_score + away_score) AS goles_totales
FROM Partidos
WHERE round_name IS NOT NULL
GROUP BY round_name
HAVING SUM(home_score + away_score) >= 10
ORDER BY goles_totales DESC;


/*
Parte E – Análisis directo de tiros
Sin combinar tablas:

Obtener una fila global con total de tiros, partidos distintos, suma de xg, promedio de xg y máximo xg.
Resumir por event_id: tiros, suma de xg, promedio y máximo de xg.
Conservar partidos con 20 o más tiros mediante HAVING.
Resumir por type: tiros, promedio de xg y máximo xg; conservar tipos con al menos 10 tiros.
*/
-- Punto 1
SELECT
    COUNT(*) AS total_tiros,
    COUNT(DISTINCT event_id) AS partidos_distintos,
    SUM(xg) AS suma_xg,
    AVG(xg) AS promedio_xg,
    MAX(xg) AS maximo_xg
FROM Tiros;

-- Punto 2/3
SELECT
    event_id,
    COUNT(*) AS tiros,
    SUM(xg) AS suma_xg,
    AVG(xg) AS promedio_xg,
    MAX(xg) AS maximo_xg
FROM Tiros
GROUP BY event_id
HAVING COUNT(*) >= 20
ORDER BY tiros DESC;

-- Punto 4
SELECT
    type,
    COUNT(*) AS tiros,
    AVG(xg) AS promedio_xg,
    MAX(xg) AS maximo_xg
FROM Tiros
GROUP BY type
HAVING COUNT(*) >= 10
ORDER BY tiros DESC;


/*
Parte F – Resultado ejecutivo
Entregar dos rankings separados:

TOP (5) selecciones con mejor diferencia de gol jugando como local.
TOP (5) selecciones con mejor diferencia de gol jugando como visitante.
Los títulos y alias deben indicar claramente que son rankings por condición y no un rendimiento total de la selección.
*/

-- Ranking 1 
SELECT TOP (5)
    home_team AS seleccion_como_local,
    COUNT(*) AS partidos_como_local,
    SUM(home_score) AS goles_a_favor_local,
    SUM(away_score) AS goles_en_contra_local,
    SUM(home_score) - SUM(away_score) AS diferencia_gol_como_local
FROM Partidos
GROUP BY home_team
ORDER BY diferencia_gol_como_local DESC;

-- Ranking 2
SELECT TOP (5)
    away_team AS seleccion_como_visitante,
    COUNT(*) AS partidos_como_visitante,
    SUM(away_score) AS goles_a_favor_visitante,
    SUM(home_score) AS goles_en_contra_visitante,
    SUM(away_score) - SUM(home_score) AS diferencia_gol_como_visitante
FROM Partidos
GROUP BY away_team
ORDER BY diferencia_gol_como_visitante DESC;