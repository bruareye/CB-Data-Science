/* TO-DO 1 — Diagnóstico de nulos
1. Cuenta nulos en round_name.
2. Cuenta nulos en group_name.
3. Cuenta nulos en home_score.
Resultado esperado: tres conteos explícitos de calidad.
*/
SELECT
    SUM(CASE WHEN round_name IS NULL THEN 1 ELSE 0 END) AS nulos_round_name,
    SUM(CASE WHEN group_name IS NULL THEN 1 ELSE 0 END) AS nulos_group_name,
    SUM(CASE WHEN home_score IS NULL THEN 1 ELSE 0 END) AS nulos_home_score
FROM Partidos;

/* TO-DO 2 — Fase analítica
1. Crea fase_analitica con group_name y round_name.
2. Usa Sin fase como último recurso.
3. Muestra event_id y la nueva etiqueta.
Resultado esperado: una fase legible para cada partido.
*/
SELECT event_id, COALESCE(group_name, round_name, 'Sin Fase') as fase_analitica
FROM Partidos

/* TO-DO 3 — Resultado e intensidad
1. Crea resultado_partido. (Local, Visitante, Empate)
2. Crea intensidad_goles: Alta, Media o Baja. (Alta >=4, media >=2 y baja)
3. Conserva equipos, marcador y categorías.
Resultado esperado: dos variables categóricas por partido.
*/
SELECT event_id, home_team, away_team, home_score, away_score,
    CASE 
        WHEN home_score > away_score THEN 'Local'
        WHEN home_score = away_score THEN 'Empate'
        ELSE 'Visitante'
    END AS resultado_partido,
    CASE 
        WHEN home_score + away_score >= 4 THEN 'Alta'
        WHEN home_score + away_score >= 2 THEN 'Media'
        ELSE 'Baja'
    END AS intensidad_goles
FROM Partidos;

/* TO-DO 4 — Rendimiento como local
1. Agrupa los partidos directamente por home_team.
2. Calcula partidos, ganados, empatados y perdidos con SUM y CASE.
3. Calcula puntos estimados obtenidos como local.
Resultado esperado: una fila por selección con su rendimiento únicamente como local.
*/

SELECT home_team as seleccion, 
    count(*) as partidos_locales,
    SUM(CASE WHEN home_score > away_score THEN 1 ELSE 0 END) AS Ganados,
    SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Empate,
    SUM(CASE WHEN home_score < away_score THEN 1 ELSE 0 END) AS Perdido,
    SUM(CASE 
        WHEN home_score > away_score THEN 3
        WHEN home_score = away_score THEN 1
        ELSE 0
    END) AS PuntosGanados
FROM Partidos
GROUP BY home_team
ORDER BY PuntosGanados DESC, seleccion;

/* TO-DO 5 — Porcentaje de goles locales
1. Calcula goles totales.
2. Protege el denominador con NULLIF.
3. Devuelve porcentaje con dos decimales.
Resultado esperado: una métrica segura por partido con goles.
*/

SELECT event_id,
    home_team,
    away_team,
    home_score + away_score as golesTotales,
    COALESCE(CAST(100.0 * home_score / NULLIF(home_score + away_score, 0) AS DECIMAL(5,2)), 0) AS PorcentajeGolesLocal
FROM Partidos