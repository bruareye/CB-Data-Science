/* ================================================================
TO-DO 1 — Perfil y cardinalidad de las fuentes
===================================================================
Construye cuatro consultas independientes, una por tabla:

- Partidos: cantidad de filas y partidos distintos.
- EstadisticasPartido: cantidad de filas y partidos distintos.
- Tiros: cantidad de filas, partidos distintos y tiros promedio por partido.
- Incidentes: cantidad de filas, partidos distintos e incidentes promedio
  por partido.

Resultado esperado: cuatro resultados que permitan clasificar las
relaciones con Partidos como 1:1 o 1:N.
*/

SELECT 
    COUNT(*) as CantidadFilas, 
    COUNT(DISTINCT event_id) as PartidosDistintos 
FROM Partidos

SELECT 
    COUNT(*) as CantidadFilas, 
    COUNT(DISTINCT event_id) as PartidosDistintos 
FROM EstadisticasPartido

SELECT 
    COUNT(*) as CantidadFilas, 
    COUNT(DISTINCT event_id) as PartidosDistintos,
    ROUND(CAST(COUNT(*) AS FLOAT) / COUNT(DISTINCT event_id), 2) as TirosPromedioPartido    
    FROM Tiros

SELECT 
    COUNT(*) as CantidadFilas,
    COUNT(DISTINCT(event_id)) as PartidosDistintos,
    ROUND(CAST(COUNT(*) AS FLOAT) / COUNT(DISTINCT event_id), 2) as IncidentesPromedioPartido    
FROM Incidentes


/* ================================================================
TO-DO 2 — Dominio territorial y producción ofensiva reportada
===================================================================
Relaciona Partidos con EstadisticasPartido mediante INNER JOIN.
Devuelve una fila por partido con:

- event_id, fecha, selección local y visitante;
- marcador;
- posesión de ambos equipos;
- pases de ambos equipos;
- tiros reportados de ambos equipos;
- goles esperados de ambos equipos;
- diferencia absoluta de posesión;
- diferencia absoluta de goles esperados.

Ordena de mayor a menor diferencia de posesión y, en caso de empate,
de mayor a menor diferencia de goles esperados. Limita a 15 filas.
Valida que el número de filas coincida con el número de partidos distintos.
*/

SELECT TOP 15
    p.event_id,
    p.event_date,
    p.home_team,
    p.away_team,
    p.home_score,
    p.away_score,
    ep.home_ball_possession,
    ep.away_ball_possession,
    ep.home_passes,
    ep.away_passes,
    ep.home_total_shots,
    ep.away_total_shots,
    ep.home_expected_goals,
    ep.away_expected_goals,
    ABS(ep.home_ball_possession - ep.away_ball_possession) as diferencia_posesion,
    ABS(ep.home_expected_goals - ep.away_expected_goals) as diferencia_xg

FROM Partidos p
INNER JOIN EstadisticasPartido ep
ON p.event_id = ep.event_id
ORDER BY diferencia_posesion DESC, diferencia_xg DESC

-- Validación
SELECT COUNT(*) AS filas_del_join
FROM Partidos p
INNER JOIN EstadisticasPartido ep
    ON p.event_id = ep.event_id;

SELECT COUNT(DISTINCT event_id) AS partidos_distintos
FROM Partidos;


/*
TO-DO 3 — Efecto analítico de ON y WHERE
Escribe dos consultas con Partidos como tabla izquierda y
EstadisticasPartido como tabla derecha.
Consulta A:
- usa LEFT JOIN;
- coloca e.home_ball_possession >= 55 dentro de ON;
- muestra event_id, equipos y posesión local.
Consulta B:
- usa el mismo LEFT JOIN;
- coloca e.home_ball_possession >= 55 dentro de WHERE.
Después, crea una consulta de conteo para cada versión. Compara:
- filas totales;
- partidos distintos;
- valores NULL en home_ball_possession.

Escribe como comentario por qué los resultados no representan la misma
población de análisis.
*/
-- Consulta A
SELECT
    p.event_id,
    p.home_team,
    p.away_team,
    e.home_ball_possession
FROM Partidos p
LEFT JOIN EstadisticasPartido e
    ON p.event_id = e.event_id
    AND e.home_ball_possession >= 55;

-- Consulta B
SELECT
    p.event_id,
    p.home_team,
    p.away_team,
    e.home_ball_possession
FROM Partidos p
LEFT JOIN EstadisticasPartido e
    ON p.event_id = e.event_id
WHERE e.home_ball_possession >= 55;

-- Conteo Consulta A
SELECT
    COUNT(*) AS filas_totales,
    COUNT(DISTINCT p.event_id) AS partidos_distintos,
    SUM(CASE WHEN e.home_ball_possession IS NULL THEN 1 ELSE 0 END) AS nulos_posesion
FROM Partidos p
LEFT JOIN EstadisticasPartido e
    ON p.event_id = e.event_id
    AND e.home_ball_possession >= 55;

-- Conteo Consulta B
SELECT
    COUNT(*) AS filas_totales,
    COUNT(DISTINCT p.event_id) AS partidos_distintos,
    SUM(CASE WHEN e.home_ball_possession IS NULL THEN 1 ELSE 0 END) AS nulos_posesion
FROM Partidos p
LEFT JOIN EstadisticasPartido e
    ON p.event_id = e.event_id
WHERE e.home_ball_possession >= 55;

/*
Las dos consultas NO representan la misma población de análisis:

1. Consulta A (condición en el ON):
   El LEFT JOIN preserva TODOS los partidos de la tabla izquierda
   (Partidos), sin importar el resultado de la condición extra.
   La condición "e.home_ball_possession >= 55" solo decide CUÁLES
   filas de EstadisticasPartido pueden emparejarse; si ninguna
   cumple, el partido igual aparece en el resultado, con NULL en
   home_ball_possession. Por eso nulos_posesion puede ser > 0 y
   partidos_distintos debería acercarse al total de Partidos.

2. Consulta B (condición en el WHERE):
   El WHERE se evalúa DESPUES de resolver el LEFT JOIN completo.
   Como NULL >= 55 se evalúa como UNKNOWN (no TRUE), cualquier fila
   sin match real, o con posesión menor a 55, se descarta del
   resultado. Esto elimina por completo a los partidos que no
   tienen ninguna fila calificante en EstadisticasPartido -en la
   práctica, el LEFT JOIN se comporta como un INNER JOIN. Por eso
   nulos_posesion siempre da 0 en esta version.

3. Factor adicional (ya detectado en el TO-DO 2):
   EstadisticasPartido tiene multiples filas por event_id (no es
   1:1 con Partidos). Esto significa que, incluso dentro de una
   misma consulta, un partido puede aparecer repetido si mas de una
   de sus filas en EstadisticasPartido cumple la condicion de
   posesion >= 55. Por eso filas_totales puede ser mayor que
   partidos_distintos en AMBAS consultas, independientemente de si
   la condicion esta en el ON o en el WHERE.

En resumen: la Consulta A representa "todos los partidos, indicando
si tuvieron o no dominio de posesion >= 55"; la Consulta B representa
unicamente "los partidos (o instancias de sus estadisticas) que
efectivamente tuvieron esa posesion" -son universos de analisis
distintos, y comparar sus resultados sin tener esto en cuenta
llevaria a conclusiones equivocadas.
*/


/* ================================================================
TO-DO 4 — Intensidad de tiro por partido
===================================================================
Relaciona Partidos con Tiros mediante LEFT JOIN. Devuelve una fila por
partido con:

- event_id y equipos;
- cantidad total de tiros observados;
- tiros del equipo local;
- tiros del equipo visitante;
- xG total, xG local y xG visitante;
- cantidad de tiros a puerta, usando xgot informado como criterio.

Conserva únicamente partidos con al menos 20 tiros observados y ordena
de mayor a menor xG total. Valida que el resultado tenga una fila por
event_id.
*/

SELECT
    p.event_id,
    p.home_team,
    p.away_team,
    COUNT(t.event_id) as tiros_observados,
    SUM(CASE WHEN t.home = 1 THEN 1 ELSE 0 END) as tiros_locales,
    SUM(CASE WHEN t.home = 0 THEN 1 ELSE 0 END) as tiros_visitantes,
    SUM(COALESCE(t.xg, 0)) as xg_total,
    SUM(CASE WHEN t.home = 1 THEN COALESCE(t.xg, 0) ELSE 0 END) as xg_local,
    SUM(CASE WHEN t.home = 0 THEN COALESCE(t.xg, 0) ELSE 0 END) as xg_visitante,
    SUM(CASE WHEN t.xgot IS NOT NULL THEN 1 ELSE 0 END) as tiros_a_puerta
FROM Partidos p
LEFT JOIN Tiros t
    ON p.event_id = t.event_id
GROUP BY p.event_id, p.home_team, p.away_team
HAVING COUNT(t.event_id) >= 20
ORDER BY xg_total DESC;

/*
TO-DO 5 — Perfil de incidentes por partido
Relaciona Partidos con Incidentes mediante LEFT JOIN. Devuelve una fila
por partido con:
- event_id y equipos;
- cantidad total de incidentes;
- cantidad de goles;
- cantidad de tarjetas;
- cantidad de sustituciones;
- incidentes del equipo local;
- incidentes del equipo visitante.
Usa la columna i.type para clasificar el incidente y i.is_home para el
lado del equipo. Ordena de mayor a menor cantidad total de incidentes.
*/

SELECT
    p.event_id,
    p.home_team,
    p.away_team,
    COUNT(i.event_id) AS total_incidentes,
    SUM(CASE WHEN i.type = 'goal' THEN 1 ELSE 0 END) AS cantidad_goles,
    SUM(CASE WHEN i.type = 'card' THEN 1 ELSE 0 END) AS cantidad_tarjetas,
    SUM(CASE WHEN i.type = 'substitution' THEN 1 ELSE 0 END) AS cantidad_sustituciones,
    SUM(CASE WHEN i.is_home = 1 THEN 1 ELSE 0 END) AS incidentes_local,
    SUM(CASE WHEN i.is_home = 0 THEN 1 ELSE 0 END) AS incidentes_visitante
FROM Partidos p
LEFT JOIN Incidentes i
    ON p.event_id = i.event_id
GROUP BY p.event_id, p.home_team, p.away_team
ORDER BY total_incidentes DESC;

/*
TO-DO 6 — Tablero integrado de rendimiento ofensivo
Usa Partidos como tabla principal y agrega, mediante LEFT JOIN:
- EstadisticasPartido, relación 1:1;
- Tiros, relación 1:N.
Devuelve una fila por partido con marcador, posesión, pases, tiros
reportados por el proveedor, tiros observados en Tiros, xG observado y
tiros a puerta. Usa MAX para las métricas de EstadisticasPartido que se
repiten después de unir Tiros. Muestra los 10 partidos con mayor xG
observado.
*/

SELECT TOP 10
    p.event_id,
    p.home_team,
    p.away_team,
    p.home_score,
    p.away_score,
    MAX(e.home_ball_possession) AS posesion_local,
    MAX(e.away_ball_possession) AS posesion_visitante,
    MAX(e.home_passes) AS pases_local,
    MAX(e.away_passes) AS pases_visitante,
    MAX(e.home_total_shots) AS tiros_reportados_local,
    MAX(e.away_total_shots) AS tiros_reportados_visitante,
    COUNT(t.event_id) AS tiros_observados,
    SUM(COALESCE(t.xg, 0)) AS xg_observado,
    SUM(CASE WHEN t.xgot IS NOT NULL THEN 1 ELSE 0 END) AS tiros_a_puerta
FROM Partidos p
LEFT JOIN EstadisticasPartido e
    ON p.event_id = e.event_id
LEFT JOIN Tiros t
    ON p.event_id = t.event_id
GROUP BY p.event_id, p.home_team, p.away_team, p.home_score, p.away_score
ORDER BY xg_observado DESC;

