-- ============================================================
-- DIMENSIÓN 1 — RESULTADO COMPETITIVO
-- ============================================================
WITH PartidosSeleccion AS (
    SELECT
        event_id, event_date,
        home_team AS seleccion, away_team AS rival,
        home_score + COALESCE(extra_time_score_home, 0) AS GF,
        away_score + COALESCE(extra_time_score_away, 0) AS GC,
        group_name, round_name
    FROM Partidos
    WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')

    UNION ALL

    SELECT
        event_id, event_date,
        away_team AS seleccion, home_team AS rival,
        away_score + COALESCE(extra_time_score_away, 0) AS GF,
        home_score + COALESCE(extra_time_score_home, 0) AS GC,
        group_name, round_name
    FROM Partidos
    WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
ResultadoPartido AS (
    SELECT
        *,
        CASE WHEN GF > GC THEN 1 ELSE 0 END AS gano,
        CASE WHEN GF = GC THEN 1 ELSE 0 END AS empato,
        CASE WHEN GF < GC THEN 1 ELSE 0 END AS perdio,
        CASE WHEN GF > GC THEN 3 WHEN GF = GC THEN 1 ELSE 0 END AS puntos_partido,
        CASE
            WHEN round_name = 'Final'                THEN 6
            WHEN round_name = 'Semifinals'            THEN 5
            WHEN round_name = 'Match for 3rd place'   THEN 5
            WHEN round_name = 'Quarterfinals'         THEN 4
            WHEN round_name = 'Round of 16'           THEN 3
            WHEN round_name = 'Round of 32'           THEN 2
            ELSE 1
        END AS orden_fase,
        COALESCE(round_name, 'Fase de grupos') AS fase_partido
    FROM PartidosSeleccion
),
FaseAlcanzada AS (
    SELECT
        seleccion, fase_partido,
        ROW_NUMBER() OVER (PARTITION BY seleccion ORDER BY orden_fase DESC) AS rn
    FROM ResultadoPartido
)
SELECT
    rp.seleccion                                                        AS "Selección",
    COUNT(DISTINCT rp.event_id)                                         AS "PJ",
    SUM(rp.gano)                                                        AS "G",
    SUM(rp.empato)                                                      AS "E",
    SUM(rp.perdio)                                                      AS "P",
    SUM(rp.puntos_partido)                                              AS "Puntos",
    ROUND(1.0*SUM(rp.puntos_partido)/COUNT(DISTINCT rp.event_id), 2)    AS "Puntos/partido",
    SUM(rp.GF)                                                          AS "GF",
    SUM(rp.GC)                                                          AS "GC",
    SUM(rp.GF - rp.GC)                                                  AS "DG",
    ROUND(1.0*SUM(rp.GF - rp.GC)/COUNT(DISTINCT rp.event_id), 2)        AS "DG/partido",
    fa.fase_partido                                                     AS "Fase alcanzada"
FROM ResultadoPartido rp
INNER JOIN FaseAlcanzada fa
    ON fa.seleccion = rp.seleccion AND fa.rn = 1
GROUP BY rp.seleccion, fa.fase_partido
ORDER BY "Puntos/partido" DESC;

-- ------------------------------------------------------------
-- Validaciones
-- ------------------------------------------------------------
-- 1) La normalización debe duplicar exactamente cada partido (una fila por lado)
WITH PartidosSeleccion AS (
    SELECT
        event_id, event_date,
        home_team AS seleccion, away_team AS rival,
        home_score + COALESCE(extra_time_score_home, 0) AS GF,
        away_score + COALESCE(extra_time_score_away, 0) AS GC,
        group_name, round_name
    FROM Partidos
    WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT
        event_id, event_date,
        away_team AS seleccion, home_team AS rival,
        away_score + COALESCE(extra_time_score_away, 0) AS GF,
        home_score + COALESCE(extra_time_score_home, 0) AS GC,
        group_name, round_name
    FROM Partidos
    WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
)
SELECT COUNT(*) AS filas_normalizadas
FROM PartidosSeleccion;

-- 2) Ninguna selección debe repetir el mismo event_id (llave seleccion+event_id)
WITH PartidosSeleccion AS (
    SELECT
        event_id, event_date,
        home_team AS seleccion, away_team AS rival,
        home_score + COALESCE(extra_time_score_home, 0) AS GF,
        away_score + COALESCE(extra_time_score_away, 0) AS GC,
        group_name, round_name
    FROM Partidos
    WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT
        event_id, event_date,
        away_team AS seleccion, home_team AS rival,
        away_score + COALESCE(extra_time_score_away, 0) AS GF,
        home_score + COALESCE(extra_time_score_home, 0) AS GC,
        group_name, round_name
    FROM Partidos
    WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
)
SELECT seleccion, event_id, COUNT(*) AS repeticiones
FROM PartidosSeleccion
GROUP BY seleccion, event_id
HAVING COUNT(*) > 1;

-- 3) La consulta final debe tener exactamente 5 filas (una por selección)
-- (verificar visualmente sobre el resultado de la consulta principal)

/*
Colombia fue, junto con España, Argentina y Suiza, una de las cuatro selecciones del grupo
comparado que no perdió ningún partido en tiempo reglamentario (0 derrotas en sus 5 encuentros:
3 victorias, 2 empates). Sin embargo, fue la que llegó menos lejos entre esas cuatro invictas:
mientras Suiza avanzó hasta Cuartos de Final y España/Argentina hasta la propia Final, Colombia
quedó eliminada en Octavos de Final (Round of 16). Su diferencia de gol por partido (+0,80) fue
también la más baja del grupo, por debajo incluso de Suiza y Portugal (+1,00 ambas), y muy lejos
de España (+1,50). La eliminación de Colombia no se decidió por una derrota en el campo, sino por
una definición por penales tras un 0-0 ante Suiza en Octavos — un desenlace que ninguna métrica
tradicional de resultado competitivo (G/E/P, puntos) captura como "derrota". En síntesis: el
resultado competitivo de Colombia fue sólido pero no sobresaliente frente al grupo comparado, y su
salida temprana respondió más a un mecanismo de definición (penales) que a una diferencia de nivel
competitivo medible en G/E/P o DG/partido.
*/


-- ============================================================
-- DIMENSIÓN 2 — PRODUCCIÓN OFENSIVA
-- ============================================================
WITH PartidosSeleccion AS (
    SELECT event_id, home_team AS seleccion
    FROM Partidos
    WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT event_id, away_team AS seleccion
    FROM Partidos
    WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
TirosSeleccion AS (
    SELECT
        t.event_id,
        CASE WHEN t.home = 1 THEN p.home_team ELSE p.away_team END AS seleccion,
        t.xg, t.type
    FROM Tiros t
    INNER JOIN Partidos p ON p.event_id = t.event_id
    WHERE ((t.home = 1 AND p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland'))
       OR (t.home = 0 AND p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')))
      AND t.sit <> 'shootout'
),
TirosPorPartido AS (
    SELECT
        ps.seleccion, ps.event_id,
        COUNT(ts.type) AS tiros_totales,
        SUM(CASE WHEN ts.type IN ('goal','save') THEN 1 ELSE 0 END) AS tiros_a_puerta,
        SUM(CASE WHEN ts.type = 'goal' THEN 1 ELSE 0 END) AS goles,
        SUM(COALESCE(ts.xg, 0)) AS xg_total
    FROM PartidosSeleccion ps
    LEFT JOIN TirosSeleccion ts ON ts.event_id = ps.event_id AND ts.seleccion = ps.seleccion
    GROUP BY ps.seleccion, ps.event_id
)
SELECT
    seleccion                                                     AS "Selección",
    COUNT(DISTINCT event_id)                                      AS "PJ",
    SUM(tiros_totales)                                            AS "Tiros totales",
    ROUND(1.0*SUM(tiros_totales)/COUNT(DISTINCT event_id), 2)     AS "Tiros/partido",
    SUM(tiros_a_puerta)                                           AS "Tiros a puerta",
    ROUND(1.0*SUM(tiros_a_puerta)/COUNT(DISTINCT event_id), 2)    AS "A puerta/partido",
    ROUND(1.0*SUM(xg_total)/COUNT(DISTINCT event_id), 2)          AS "xG/partido",
    ROUND(1.0*SUM(xg_total)/NULLIF(SUM(tiros_totales),0), 2)      AS "xG por tiro",
    ROUND(SUM(xg_total), 2)                                       AS "xG acumulado",
    SUM(goles)                                                    AS "GF",
    ROUND(100.0*SUM(goles)/NULLIF(SUM(tiros_totales),0), 1)       AS "Goles por tiro (%)",
    ROUND((1.0*SUM(goles) - SUM(xg_total))/COUNT(DISTINCT event_id), 2) AS "Diferencia Goles-xG por partido"
FROM TirosPorPartido
GROUP BY seleccion
ORDER BY "xG/partido" DESC;

-- ------------------------------------------------------------
-- Validaciones
-- ------------------------------------------------------------
-- 1) Ninguna selección debe repetir el mismo event_id en TirosPorPartido
WITH PartidosSeleccion AS (
    SELECT event_id, home_team AS seleccion
    FROM Partidos
    WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT event_id, away_team AS seleccion
    FROM Partidos
    WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
TirosSeleccion AS (
    SELECT
        t.event_id,
        CASE WHEN t.home = 1 THEN p.home_team ELSE p.away_team END AS seleccion,
        t.xg, t.type
    FROM Tiros t
    INNER JOIN Partidos p ON p.event_id = t.event_id
    WHERE ((t.home = 1 AND p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland'))
       OR (t.home = 0 AND p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')))
      AND t.sit <> 'shootout'
),
TirosPorPartido AS (
    SELECT
        ps.seleccion, ps.event_id,
        COUNT(ts.type) AS tiros_totales
    FROM PartidosSeleccion ps
    LEFT JOIN TirosSeleccion ts ON ts.event_id = ps.event_id AND ts.seleccion = ps.seleccion
    GROUP BY ps.seleccion, ps.event_id
)
SELECT seleccion, event_id, COUNT(*) AS repeticiones
FROM TirosPorPartido
GROUP BY seleccion, event_id
HAVING COUNT(*) > 1;

-- 2) El total de tiros agregados debe coincidir con un conteo directo sobre Tiros
WITH TirosSeleccion AS (
    SELECT
        t.event_id,
        CASE WHEN t.home = 1 THEN p.home_team ELSE p.away_team END AS seleccion,
        t.xg, t.type
    FROM Tiros t
    INNER JOIN Partidos p ON p.event_id = t.event_id
    WHERE ((t.home = 1 AND p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland'))
       OR (t.home = 0 AND p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')))
      AND t.sit <> 'shootout'
)
SELECT COUNT(*) AS total_tiros_directo
FROM TirosSeleccion;
-- comparar contra SUM("Tiros totales") de la consulta principal

/*
En producción ofensiva, Colombia lideró en tiros por partido (19,8) y tuvo un xG de 2,29, superior 
al promedio del torneo y al de finalistas como España y Argentina. Sin embargo, la calidad y eficacia
fueron bajas: su xG por tiro (0,12) fue de los peores y su conversión real apenas del 8,1%, muy por 
debajo de Argentina (16,5%) o Suiza (17,7%). Esto derivó en una diferencia negativa de -3,44 entre 
goles reales (8) y xG acumulado (11,44), el peor registro del grupo. En síntesis, Colombia no fue 
eliminada por falta de generación ofensiva, sino por la brecha entre ocasiones creadas y capacidad de 
concretarlas.
*/
-- ============================================================
-- DIMENSIÓN 3 — CONTROL Y DOMINIO DEL JUEGO
-- ============================================================
WITH EstadisticasSeleccion AS (
    SELECT ep.event_id, p.home_team AS seleccion,
           ep.home_ball_possession         AS posesion,
           ep.home_pass_accuracy_pct       AS precision_pases,
           ep.home_dangerous_attack        AS ataques_peligrosos,
           ep.home_final_third_entries     AS entradas_ultimo_tercio,
           ep.home_touches_in_penalty_area AS toques_area
    FROM EstadisticasPartido ep
    INNER JOIN Partidos p ON p.event_id = ep.event_id
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT ep.event_id, p.away_team,
           ep.away_ball_possession,
           ep.away_pass_accuracy_pct,
           ep.away_dangerous_attack,
           ep.away_final_third_entries,
           ep.away_touches_in_penalty_area
    FROM EstadisticasPartido ep
    INNER JOIN Partidos p ON p.event_id = ep.event_id
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
ResultadoDimension3 AS (
    SELECT
        seleccion,
        COUNT(DISTINCT event_id)                                      AS PJ,
        ROUND(AVG(CAST(posesion AS DECIMAL(10,2))), 2)                AS posesion_promedio,
        ROUND(AVG(CAST(precision_pases AS DECIMAL(10,2))), 2)         AS precision_pases_pct,
        ROUND(AVG(CAST(ataques_peligrosos AS DECIMAL(10,2))), 2)      AS ataques_peligrosos_promedio,
        ROUND(AVG(CAST(entradas_ultimo_tercio AS DECIMAL(10,2))), 2)  AS entradas_ultimo_tercio_promedio,
        ROUND(AVG(CAST(toques_area AS DECIMAL(10,2))), 2)             AS toques_area_promedio
    FROM EstadisticasSeleccion
    GROUP BY seleccion
),
MomentumPartido AS (
    SELECT m.event_id, p.home_team AS seleccion,
           AVG(CAST(m.momentum_value AS DECIMAL(10,2))) AS momentum_partido
    FROM Momentum m
    INNER JOIN Partidos p ON p.event_id = m.event_id
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    GROUP BY m.event_id, p.home_team
    UNION ALL
    SELECT m.event_id, p.away_team,
           AVG(CAST(-m.momentum_value AS DECIMAL(10,2)))
    FROM Momentum m
    INNER JOIN Partidos p ON p.event_id = m.event_id
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    GROUP BY m.event_id, p.away_team
),
MomentumSeleccion AS (
    SELECT seleccion, ROUND(AVG(momentum_partido), 2) AS momentum_promedio
    FROM MomentumPartido
    GROUP BY seleccion
)
SELECT
    r.seleccion, r.PJ,
    r.posesion_promedio          AS "Posesión (%)",
    r.precision_pases_pct        AS "Precisión de pases (%)",
    r.ataques_peligrosos_promedio AS "Ataques peligrosos/partido",
    r.entradas_ultimo_tercio_promedio AS "Entradas último tercio/partido",
    r.toques_area_promedio       AS "Toques en área rival/partido",
    ms.momentum_promedio         AS "Momentum promedio",
    RANK() OVER (ORDER BY r.posesion_promedio DESC) AS ranking_posesion
FROM ResultadoDimension3 r
INNER JOIN MomentumSeleccion ms ON ms.seleccion = r.seleccion
ORDER BY r.posesion_promedio DESC;
-- ------------------------------------------------------------
-- Validaciones
-- ------------------------------------------------------------
-- Ninguna selección debe repetir el mismo event_id en EstadisticasSeleccion
WITH EstadisticasSeleccion AS (
    SELECT ep.event_id, p.home_team AS seleccion
    FROM EstadisticasPartido ep
    INNER JOIN Partidos p ON p.event_id = ep.event_id
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT ep.event_id, p.away_team
    FROM EstadisticasPartido ep
    INNER JOIN Partidos p ON p.event_id = ep.event_id
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
)
SELECT seleccion, event_id, COUNT(*) AS repeticiones
FROM EstadisticasSeleccion
GROUP BY seleccion, event_id
HAVING COUNT(*) > 1;
/*
En control y dominio del juego, Colombia registró los valores más bajos del grupo comparado en 
posesión (57,60%), precisión de pases (87,16%) y ataques peligrosos por partido (51,60), incluso por 
debajo de Suiza y Portugal, selecciones con perfiles ofensivos más modestos según la Dimensión 2. Sus 
entradas al último tercio (57,00/partido) también fueron las más bajas, y sus toques en el área rival 
(25,60/partido) apenas superaron a Suiza. Sin embargo, su momentum promedio (+10,50) fue el segundo 
más alto del grupo, superando a Argentina (+7,06) y Portugal (+6,94), y solo por debajo de España 
(+17,25). Esta combinación —bajo control sostenido pero momentum elevado— sugiere que el dominio de 
Colombia no fue producto de una posesión estructurada y paciente como la de España, sino de tramos de 
intensidad puntual dentro de los partidos. En síntesis, Colombia no controló el juego de forma 
sostenida como las finalistas, lo que es coherente con el hallazgo de la Dimensión 2: generó volumen 
de tiros y momentos de dominio intenso, pero sin el control territorial constante que suele acompañar 
a una producción ofensiva eficiente.
*/
-- ============================================================
-- DIMENSIÓN 4 — SOLIDEZ Y CONSISTENCIA
-- ============================================================
WITH TarjetasLado AS (
    SELECT event_id, is_home, COUNT(*) AS tarjetas
    FROM Incidentes
    WHERE type = 'card' AND is_home IS NOT NULL
    GROUP BY event_id, is_home
),
XgLado AS (
    SELECT event_id, MAX(cum_home) AS xg_home, MAX(cum_away) AS xg_away
    FROM XgMinuto
    WHERE minute <= 120  -- excluye penales de shootout (xg=0.788 repetido en minutos >120)
    GROUP BY event_id
),
PorPartidoSolidez AS (
    SELECT p.home_team AS seleccion, p.event_id,
           p.away_score + COALESCE(p.extra_time_score_away, 0) AS goles_recibidos,
           e.home_fouls              AS faltas,
           COALESCE(tl.tarjetas, 0)  AS tarjetas,
           x.xg_home                 AS xg
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN XgLado x ON x.event_id = p.event_id
    LEFT JOIN TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 1
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')

    UNION ALL

    SELECT p.away_team, p.event_id,
           p.home_score + COALESCE(p.extra_time_score_home, 0), e.away_fouls, COALESCE(tl.tarjetas,0), x.xg_away
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN XgLado x ON x.event_id = p.event_id
    LEFT JOIN TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 0
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
ResumenSolidez AS (
    SELECT
        seleccion,
        COUNT(*)                               AS PJ,
        1.0 * SUM(goles_recibidos) / COUNT(*)   AS gc_por_partido,
        1.0 * SUM(faltas)          / COUNT(*)   AS faltas_por_partido,
        1.0 * SUM(tarjetas)        / COUNT(*)   AS tarjetas_por_partido,
        AVG(xg)                                 AS xg_medio,
        MAX(xg) - MIN(xg)                       AS rango_xg
    FROM PorPartidoSolidez
    GROUP BY seleccion
)
SELECT
    seleccion,
    PJ,
    ROUND(gc_por_partido, 2)     AS goles_recibidos_por_partido,
    ROUND(faltas_por_partido, 2) AS faltas_por_partido,
    ROUND(tarjetas_por_partido, 2) AS tarjetas_por_partido,
    ROUND(xg_medio, 2)           AS xg_medio,
    ROUND(rango_xg, 2)           AS rango_xg,
    RANK() OVER (ORDER BY gc_por_partido ASC) AS rank_solidez,
    CASE WHEN gc_por_partido <
              ( SELECT AVG(1.0 * gc)
                FROM ( SELECT away_score + COALESCE(extra_time_score_away, 0) AS gc FROM Partidos
                       UNION ALL
                       SELECT home_score + COALESCE(extra_time_score_home, 0) FROM Partidos ) t )
         THEN 'Más sólida que el promedio del torneo'
         ELSE 'Por debajo del promedio del torneo'
    END AS solidez_vs_torneo
FROM ResumenSolidez
ORDER BY rank_solidez;

-- ------------------------------------------------------------
-- Comparación fase de grupos vs. fases posteriores
-- ------------------------------------------------------------
WITH TarjetasLado AS (
    SELECT event_id, is_home, COUNT(*) AS tarjetas
    FROM Incidentes
    WHERE type = 'card' AND is_home IS NOT NULL
    GROUP BY event_id, is_home
),
XgLado AS (
    SELECT event_id, MAX(cum_home) AS xg_home, MAX(cum_away) AS xg_away
    FROM XgMinuto
    WHERE minute <= 120  -- excluye penales de shootout (xg=0.788 repetido en minutos >120)
    GROUP BY event_id
),
PorPartidoFase AS (
    SELECT p.home_team AS seleccion,
           CASE WHEN p.group_name IS NOT NULL THEN 'Grupos' ELSE 'Eliminatorias' END AS fase,
           p.away_score + COALESCE(p.extra_time_score_away, 0) AS gc, COALESCE(tl.tarjetas,0) AS tarjetas, x.xg_home AS xg
    FROM Partidos p
    JOIN XgLado x ON x.event_id = p.event_id
    LEFT JOIN TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 1
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')

    UNION ALL

    SELECT p.away_team,
           CASE WHEN p.group_name IS NOT NULL THEN 'Grupos' ELSE 'Eliminatorias' END,
           p.home_score + COALESCE(p.extra_time_score_home, 0), COALESCE(tl.tarjetas,0), x.xg_away
    FROM Partidos p
    JOIN XgLado x ON x.event_id = p.event_id
    LEFT JOIN TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 0
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
)
SELECT
    seleccion, fase,
    COUNT(*)                              AS PJ,
    ROUND(AVG(xg), 2)                     AS xg_medio,
    ROUND(1.0*SUM(gc)/COUNT(*), 2)        AS gc_por_partido,
    ROUND(1.0*SUM(tarjetas)/COUNT(*), 2)  AS tarjetas_por_partido
FROM PorPartidoFase
GROUP BY seleccion, fase
ORDER BY seleccion, fase DESC;
-- ------------------------------------------------------------
-- Validaciones
-- ------------------------------------------------------------
WITH XgLado AS (
    SELECT event_id, MAX(cum_home) AS xg_home, MAX(cum_away) AS xg_away
    FROM XgMinuto
    WHERE minute <= 120  -- excluye penales de shootout (xg=0.788 repetido en minutos >120)
    GROUP BY event_id
),
PorPartido AS (
    SELECT p.home_team AS seleccion, p.event_id
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN XgLado x ON x.event_id = p.event_id
    UNION ALL
    SELECT p.away_team, p.event_id
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN XgLado x ON x.event_id = p.event_id
)
SELECT
    (SELECT COUNT(*) FROM Partidos) * 2 AS filas_esperadas,
    (SELECT COUNT(*) FROM PorPartido)   AS filas_obtenidas,
    (SELECT COUNT(*) FROM (SELECT event_id, seleccion FROM PorPartido GROUP BY event_id, seleccion) z) AS combinaciones_unicas;

WITH XgLado AS (
    SELECT event_id, MAX(cum_home) AS xg_home, MAX(cum_away) AS xg_away
    FROM XgMinuto
    WHERE minute <= 120  -- excluye penales de shootout (xg=0.788 repetido en minutos >120)
    GROUP BY event_id
),
PorPartido AS (
    SELECT p.home_team AS seleccion, p.event_id FROM Partidos p JOIN XgLado x ON x.event_id = p.event_id
    UNION ALL
    SELECT p.away_team, p.event_id FROM Partidos p JOIN XgLado x ON x.event_id = p.event_id
)
SELECT seleccion, COUNT(*) AS filas_intermedias,
       (SELECT COUNT(*) FROM Partidos WHERE home_team = pp.seleccion OR away_team = pp.seleccion) AS PJ_reales
FROM PorPartido pp
WHERE seleccion IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
GROUP BY seleccion;

SELECT
    (SELECT COUNT(*) FROM Incidentes WHERE type = 'card') AS cards_crudo,
    (SELECT COUNT(*) FROM XgMinuto)                       AS xgminuto_crudo,
    (SELECT COUNT(*) FROM Incidentes i JOIN XgMinuto x ON x.event_id = i.event_id
        WHERE i.type = 'card')                            AS join_naive_inflado;

/*
INTERPRETACIÓN (grupos -> eliminatorias):
NOTA: xg_medio se calcula desde XgMinuto excluyendo minutos > 120 (WHERE minute <= 120),
para no contaminar el promedio con los penales del shootout, que en esta tabla aparecen
como filas adicionales en minutos ficticios (121-131) con xg=0.788 repetido por cada
penal. Sin este filtro, cualquier selección que definiera un partido por penales mostraba
un xG de eliminatorias artificialmente inflado.

Colombia   : xG 1.43 -> 1.61  y  GC 0.33 -> 0.00. Mejora leve en generación y deja de
             encajar goles, pero cae en octavos (0-0 vs Switzerland) por penales. El
             dominio del juego no se tradujo en avance: el formato premia CONVERTIR,
             no dominar, y el desenlace por penales no queda capturado por xG ni GC.
Spain      : xG 2.00 -> 2.08, GC 0.00 -> 0.20. Se mantuvo estable hasta la final.
Argentina  : xG 2.07 -> 1.86, GC 0.33 -> 1.40. Bajo su nivel pero avanzo (eficiencia/resultado).
Switzerland: xG 2.12 -> 1.14, GC 1.00 -> 1.00. Cayó su producción en eliminatorias y
             quedó eliminada en Cuartos.
Portugal   : xG 1.25 -> 1.43, bajo volumen en ambas fases; eliminada en Octavos.
*/
-- ================================================================
-- DIMENSIÓN 5 — CONTRIBUCIÓN DE JUGADORES
-- ================================================================
WITH MapeoEquipos AS (
    SELECT team_id, seleccion
    FROM (
        SELECT home_team_id AS team_id, home_team AS seleccion
        FROM Partidos
        WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
        UNION ALL
        SELECT away_team_id, away_team
        FROM Partidos
        WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    ) equipos
    GROUP BY team_id, seleccion
),
TirosJugadorConcentracion AS (
    SELECT j.player_id, j.name, me.seleccion, SUM(COALESCE(t.xg, 0)) AS xg_acumulado
    FROM Jugadores j
    INNER JOIN MapeoEquipos me ON me.team_id = j.team_id
    LEFT JOIN Tiros t ON t.player_id = j.player_id
    GROUP BY j.player_id, j.name, me.seleccion
),
RankingJugadoresConcentracion AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY seleccion ORDER BY xg_acumulado DESC) AS puesto_xg
    FROM TirosJugadorConcentracion
)
SELECT
    seleccion AS "Selección",
    ROUND(SUM(xg_acumulado), 2) AS "xG total selección",
    ROUND(SUM(CASE WHEN puesto_xg <= 3 THEN xg_acumulado ELSE 0 END), 2) AS "xG top 3 jugadores",
    ROUND(100.0 * SUM(CASE WHEN puesto_xg <= 3 THEN xg_acumulado ELSE 0 END)
          / NULLIF(SUM(xg_acumulado), 0), 1) AS "Concentración top 3 (%)"
FROM RankingJugadoresConcentracion
GROUP BY seleccion
ORDER BY "Concentración top 3 (%)" DESC;
-- ------------------------------------------------------------
-- Validaciones
-- ------------------------------------------------------------
-- El mapeo team_id -> selección no debe generar duplicados
WITH MapeoEquipos AS (
    SELECT team_id, seleccion
    FROM (
        SELECT home_team_id AS team_id, home_team AS seleccion
        FROM Partidos
        WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
        UNION ALL
        SELECT away_team_id, away_team
        FROM Partidos
        WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    ) equipos
    GROUP BY team_id, seleccion
)
SELECT team_id, COUNT(*) AS repeticiones
FROM MapeoEquipos
GROUP BY team_id
HAVING COUNT(*) > 1;

/*
En contribución de jugadores, Colombia mostró la producción ofensiva más repartida
de las cinco selecciones comparadas: sus tres jugadores con mayor xG (Luis Díaz,
Jaminton Campaz y Davinson Sánchez) concentraron apenas el 44,4% del xG total del
equipo (11,44), la cifra más baja del grupo, frente al 72,4% de Portugal o el 67,9%
de Argentina. Ni siquiera su máximo generador de xG, Luis Díaz (2,38), superó el 21%
de la producción total del equipo, y el segundo mayor generador no fue un delantero
sino un defensa central (Davinson Sánchez, 1,29 xG), lo que confirma que el peligro
ofensivo colombiano no dependía de una sola figura. En síntesis, el bajo rendimiento
de conversión detectado en la Dimensión 2 (8,1% de goles por tiro, el más bajo del
grupo) no puede explicarse por una dependencia excesiva de pocos jugadores: el
problema de eficacia fue colectivo y distribuido en todo el plantel, no el resultado
de que la ofensiva se apoyara en una sola estrella que rindió por debajo de lo
esperado.
*/

-- ================================================================================
-- CONSULTA FINAL
-- ================================================================================
WITH
-- ---------- Dimensión 1: Resultado competitivo ----------
D1_PartidosSeleccion AS (
    SELECT
        event_id, home_team AS seleccion, away_team AS rival,
        home_score + COALESCE(extra_time_score_home, 0) AS GF,
        away_score + COALESCE(extra_time_score_away, 0) AS GC, group_name, round_name
    FROM Partidos
    WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT
        event_id, away_team AS seleccion, home_team AS rival,
        away_score + COALESCE(extra_time_score_away, 0) AS GF,
        home_score + COALESCE(extra_time_score_home, 0) AS GC, group_name, round_name
    FROM Partidos
    WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
D1_ResultadoPartido AS (
    SELECT
        *,
        CASE WHEN GF > GC THEN 1 ELSE 0 END AS gano,
        CASE WHEN GF = GC THEN 1 ELSE 0 END AS empato,
        CASE WHEN GF < GC THEN 1 ELSE 0 END AS perdio,
        CASE WHEN GF > GC THEN 3 WHEN GF = GC THEN 1 ELSE 0 END AS puntos_partido,
        CASE
            WHEN round_name = 'Final'              THEN 6
            WHEN round_name = 'Semifinals'          THEN 5
            WHEN round_name = 'Match for 3rd place' THEN 5
            WHEN round_name = 'Quarterfinals'       THEN 4
            WHEN round_name = 'Round of 16'         THEN 3
            WHEN round_name = 'Round of 32'         THEN 2
            ELSE 1
        END AS orden_fase,
        COALESCE(round_name, 'Fase de grupos') AS fase_partido
    FROM D1_PartidosSeleccion
),
D1_FaseAlcanzada AS (
    SELECT
        seleccion, fase_partido,
        ROW_NUMBER() OVER (PARTITION BY seleccion ORDER BY orden_fase DESC) AS rn
    FROM D1_ResultadoPartido
),
D1_Resultado AS (
    SELECT
        rp.seleccion,
        COUNT(DISTINCT rp.event_id)                                      AS PJ,
        SUM(rp.gano)                                                     AS G,
        SUM(rp.empato)                                                   AS E,
        SUM(rp.perdio)                                                   AS P,
        SUM(rp.puntos_partido)                                           AS Puntos,
        ROUND(1.0*SUM(rp.puntos_partido)/COUNT(DISTINCT rp.event_id), 2) AS Puntos_partido,
        SUM(rp.GF)                                                       AS GF,
        SUM(rp.GC)                                                       AS GC,
        SUM(rp.GF - rp.GC)                                               AS DG,
        ROUND(1.0*SUM(rp.GF - rp.GC)/COUNT(DISTINCT rp.event_id), 2)     AS DG_partido,
        fa.fase_partido                                                  AS Fase_alcanzada
    FROM D1_ResultadoPartido rp
    INNER JOIN D1_FaseAlcanzada fa
        ON fa.seleccion = rp.seleccion AND fa.rn = 1
    GROUP BY rp.seleccion, fa.fase_partido
),

-- ---------- Dimensión 2: Producción ofensiva ----------
D2_PartidosSeleccion AS (
    SELECT event_id, home_team AS seleccion
    FROM Partidos
    WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT event_id, away_team AS seleccion
    FROM Partidos
    WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
D2_TirosSeleccion AS (
    SELECT
        t.event_id,
        CASE WHEN t.home = 1 THEN p.home_team ELSE p.away_team END AS seleccion,
        t.xg, t.type
    FROM Tiros t
    INNER JOIN Partidos p ON p.event_id = t.event_id
    WHERE ((t.home = 1 AND p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland'))
       OR (t.home = 0 AND p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')))
      AND t.sit <> 'shootout'
),
D2_TirosPorPartido AS (
    SELECT
        ps.seleccion, ps.event_id,
        COUNT(ts.type) AS tiros_totales,
        SUM(CASE WHEN ts.type IN ('goal','save') THEN 1 ELSE 0 END) AS tiros_a_puerta,
        SUM(CASE WHEN ts.type = 'goal' THEN 1 ELSE 0 END) AS goles,
        SUM(COALESCE(ts.xg, 0)) AS xg_total
    FROM D2_PartidosSeleccion ps
    LEFT JOIN D2_TirosSeleccion ts ON ts.event_id = ps.event_id AND ts.seleccion = ps.seleccion
    GROUP BY ps.seleccion, ps.event_id
),
D2_Ofensiva AS (
    SELECT
        seleccion,
        COUNT(DISTINCT event_id)                                     AS PJ,
        ROUND(1.0*SUM(tiros_totales)/COUNT(DISTINCT event_id), 2)    AS Tiros_partido,
        ROUND(1.0*SUM(tiros_a_puerta)/COUNT(DISTINCT event_id), 2)   AS A_puerta_partido,
        ROUND(1.0*SUM(xg_total)/COUNT(DISTINCT event_id), 2)         AS xG_partido,
        ROUND(1.0*SUM(xg_total)/NULLIF(SUM(tiros_totales),0), 2)     AS xG_por_tiro,
        SUM(goles)                                                   AS GF,
        ROUND(100.0*SUM(goles)/NULLIF(SUM(tiros_totales),0), 1)      AS Goles_por_tiro_pct,
        ROUND((1.0*SUM(goles) - SUM(xg_total))/COUNT(DISTINCT event_id), 2) AS Diferencia_Goles_xG_partido
    FROM D2_TirosPorPartido
    GROUP BY seleccion
),

-- ---------- Dimensión 3: Control y dominio del juego ----------
D3_EstadisticasSeleccion AS (
    SELECT ep.event_id, p.home_team AS seleccion,
           ep.home_ball_possession    AS posesion,
           ep.home_pass_accuracy_pct  AS precision_pases,
           ep.home_dangerous_attack   AS ataques_peligrosos
    FROM EstadisticasPartido ep
    INNER JOIN Partidos p ON p.event_id = ep.event_id
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT ep.event_id, p.away_team,
           ep.away_ball_possession,
           ep.away_pass_accuracy_pct,
           ep.away_dangerous_attack
    FROM EstadisticasPartido ep
    INNER JOIN Partidos p ON p.event_id = ep.event_id
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
D3_Base AS (
    SELECT
        seleccion,
        ROUND(AVG(CAST(posesion AS DECIMAL(10,2))), 2)           AS posesion_promedio,
        ROUND(AVG(CAST(precision_pases AS DECIMAL(10,2))), 2)    AS precision_pases_pct,
        ROUND(AVG(CAST(ataques_peligrosos AS DECIMAL(10,2))), 2) AS ataques_peligrosos_promedio
    FROM D3_EstadisticasSeleccion
    GROUP BY seleccion
),
D3_MomentumPartido AS (
    SELECT m.event_id, p.home_team AS seleccion,
           AVG(CAST(m.momentum_value AS DECIMAL(10,2))) AS momentum_partido
    FROM Momentum m
    INNER JOIN Partidos p ON p.event_id = m.event_id
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    GROUP BY m.event_id, p.home_team
    UNION ALL
    SELECT m.event_id, p.away_team,
           AVG(CAST(-m.momentum_value AS DECIMAL(10,2)))
    FROM Momentum m
    INNER JOIN Partidos p ON p.event_id = m.event_id
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    GROUP BY m.event_id, p.away_team
),
D3_Control AS (
    SELECT
        b.seleccion,
        b.posesion_promedio           AS Posesion_pct,
        b.precision_pases_pct         AS Precision_pases_pct,
        b.ataques_peligrosos_promedio AS Ataques_peligrosos_partido,
        ROUND(AVG(mp.momentum_partido), 2) AS Momentum_promedio
    FROM D3_Base b
    INNER JOIN D3_MomentumPartido mp ON mp.seleccion = b.seleccion
    GROUP BY b.seleccion, b.posesion_promedio, b.precision_pases_pct, b.ataques_peligrosos_promedio
),

-- ---------- Dimensión 4: Solidez y consistencia ----------
D4_TarjetasLado AS (
    SELECT event_id, is_home, COUNT(*) AS tarjetas
    FROM Incidentes
    WHERE type = 'card' AND is_home IS NOT NULL
    GROUP BY event_id, is_home
),
D4_XgLado AS (
    SELECT event_id, MAX(cum_home) AS xg_home, MAX(cum_away) AS xg_away
    FROM XgMinuto
    WHERE minute <= 120  -- excluye penales de shootout (xg=0.788 repetido en minutos >120)
    GROUP BY event_id
),
D4_PorPartidoSolidez AS (
    SELECT p.home_team AS seleccion, p.event_id,
           p.away_score + COALESCE(p.extra_time_score_away, 0) AS goles_recibidos,
           e.home_fouls AS faltas,
           COALESCE(tl.tarjetas, 0) AS tarjetas,
           x.xg_home AS xg
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN D4_XgLado x ON x.event_id = p.event_id
    LEFT JOIN D4_TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 1
    WHERE p.home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    UNION ALL
    SELECT p.away_team, p.event_id,
           p.home_score + COALESCE(p.extra_time_score_home, 0), e.away_fouls, COALESCE(tl.tarjetas,0), x.xg_away
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN D4_XgLado x ON x.event_id = p.event_id
    LEFT JOIN D4_TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 0
    WHERE p.away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
),
D4_Solidez AS (
    SELECT
        seleccion,
        ROUND(1.0*SUM(goles_recibidos)/COUNT(*), 2) AS goles_recibidos_por_partido,
        ROUND(1.0*SUM(faltas)/COUNT(*), 2)          AS faltas_por_partido,
        ROUND(1.0*SUM(tarjetas)/COUNT(*), 2)        AS tarjetas_por_partido,
        ROUND(AVG(xg), 2)                           AS xg_medio,
        ROUND(MAX(xg) - MIN(xg), 2)                 AS rango_xg
    FROM D4_PorPartidoSolidez
    WHERE seleccion IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    GROUP BY seleccion
),

-- ---------- Dimensión 5: Contribución de jugadores ----------
D5_MapeoEquipos AS (
    SELECT team_id, seleccion
    FROM (
        SELECT home_team_id AS team_id, home_team AS seleccion
        FROM Partidos
        WHERE home_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
        UNION ALL
        SELECT away_team_id, away_team
        FROM Partidos
        WHERE away_team IN ('Colombia','Spain','Argentina','Portugal','Switzerland')
    ) equipos
    GROUP BY team_id, seleccion
),
D5_TirosJugadorConcentracion AS (
    SELECT j.player_id, j.name, me.seleccion, SUM(COALESCE(t.xg, 0)) AS xg_acumulado
    FROM Jugadores j
    INNER JOIN D5_MapeoEquipos me ON me.team_id = j.team_id
    LEFT JOIN Tiros t ON t.player_id = j.player_id
    GROUP BY j.player_id, j.name, me.seleccion
),
D5_RankingJugadoresConcentracion AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY seleccion ORDER BY xg_acumulado DESC) AS puesto_xg
    FROM D5_TirosJugadorConcentracion
),
D5_Jugadores AS (
    SELECT
        seleccion,
        ROUND(SUM(xg_acumulado), 2) AS xG_total_seleccion,
        ROUND(100.0 * SUM(CASE WHEN puesto_xg <= 3 THEN xg_acumulado ELSE 0 END)
              / NULLIF(SUM(xg_acumulado), 0), 1) AS Concentracion_top3_pct
    FROM D5_RankingJugadoresConcentracion
    GROUP BY seleccion
)

-- ---------- Unión final: una fila por selección ----------
SELECT
    d1.seleccion            AS "Selección",
    d1.PJ                   AS "PJ",
    d1.G                    AS "G",
    d1.E                    AS "E",
    d1.P                    AS "P",
    d1.Puntos               AS "Puntos",
    d1.Puntos_partido       AS "Puntos/partido",
    d1.DG_partido           AS "DG/partido",
    d1.Fase_alcanzada       AS "Fase alcanzada",
    d2.Tiros_partido        AS "Tiros/partido",
    d2.A_puerta_partido     AS "A puerta/partido",
    d2.xG_partido           AS "xG/partido",
    d2.Goles_por_tiro_pct   AS "Goles por tiro (%)",
    d2.Diferencia_Goles_xG_partido AS "Diferencia Goles-xG/partido",
    d3.Posesion_pct              AS "Posesión (%)",
    d3.Precision_pases_pct       AS "Precisión de pases (%)",
    d3.Ataques_peligrosos_partido AS "Ataques peligrosos/partido",
    d3.Momentum_promedio         AS "Momentum promedio",
    d4.goles_recibidos_por_partido AS "GC/partido",
    d4.faltas_por_partido          AS "Faltas/partido",
    d4.tarjetas_por_partido        AS "Tarjetas/partido",
    d4.rango_xg                    AS "Rango xG (max-min)",
    d5.xG_total_seleccion       AS "xG total (jugadores)",
    d5.Concentracion_top3_pct   AS "Concentración top 3 (%)"
FROM D1_Resultado d1
INNER JOIN D2_Ofensiva  d2 ON d2.seleccion = d1.seleccion
INNER JOIN D3_Control   d3 ON d3.seleccion = d1.seleccion
INNER JOIN D4_Solidez   d4 ON d4.seleccion = d1.seleccion
INNER JOIN D5_Jugadores d5 ON d5.seleccion = d1.seleccion
ORDER BY d1.Puntos_partido DESC;

-- ================================================================================
-- CONSULTA DE DETALLE DE LA SELECCIÓN RECOMENDADA (Colombia)
-- ================================================================================
WITH
Det_XgLado AS (
    SELECT event_id, MAX(cum_home) AS xg_home, MAX(cum_away) AS xg_away
    FROM XgMinuto
    WHERE minute <= 120  -- excluye penales de shootout (xg=0.788 repetido en minutos >120)
    GROUP BY event_id
),
Det_TarjetasLado AS (
    SELECT event_id, is_home, COUNT(*) AS tarjetas
    FROM Incidentes
    WHERE type = 'card' AND is_home IS NOT NULL
    GROUP BY event_id, is_home
),
Det_Colombia AS (
    SELECT
        p.event_id, p.event_date AS fecha, p.away_team AS rival,
        CASE WHEN p.group_name IS NOT NULL THEN 'Grupos' ELSE 'Eliminatorias' END AS fase,
        p.home_score + COALESCE(p.extra_time_score_home, 0) AS GF,
        p.away_score + COALESCE(p.extra_time_score_away, 0) AS GC,
        e.home_ball_possession AS posesion,
        e.home_fouls AS faltas,
        COALESCE(tl.tarjetas, 0) AS tarjetas,
        x.xg_home AS xg
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN Det_XgLado x ON x.event_id = p.event_id
    LEFT JOIN Det_TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 1
    WHERE p.home_team = 'Colombia'

    UNION ALL

    SELECT
        p.event_id, p.event_date, p.home_team,
        CASE WHEN p.group_name IS NOT NULL THEN 'Grupos' ELSE 'Eliminatorias' END,
        p.away_score + COALESCE(p.extra_time_score_away, 0),
        p.home_score + COALESCE(p.extra_time_score_home, 0),
        e.away_ball_possession,
        e.away_fouls,
        COALESCE(tl.tarjetas, 0),
        x.xg_away
    FROM Partidos p
    JOIN EstadisticasPartido e ON e.event_id = p.event_id
    JOIN Det_XgLado x ON x.event_id = p.event_id
    LEFT JOIN Det_TarjetasLado tl ON tl.event_id = p.event_id AND tl.is_home = 0
    WHERE p.away_team = 'Colombia'
)
SELECT
    event_id  AS "event_id",
    fecha     AS "Fecha",
    rival     AS "Rival",
    fase      AS "Fase",
    GF        AS "GF",
    GC        AS "GC",
    (GF - GC) AS "Diferencia",
    posesion  AS "Posesión (%)",
    xg        AS "xG del partido",
    faltas    AS "Faltas",
    tarjetas  AS "Tarjetas"
FROM Det_Colombia
ORDER BY fecha;

/*
Colombia terminó invicta en tiempo reglamentario (3V-2E), con la mejor defensa del grupo (0,20
goles recibidos/partido) y el mayor volumen ofensivo (18,8 tiros/partido tras excluir los tiros
de shootout), pero la peor conversión (5,3%) y la peor diferencia Goles-xG por partido (-0,50) de
las cinco selecciones.

NOTA: el xG por partido de esta consulta de detalle excluye minutos > 120 en XgMinuto (penales de
shootout), igual que en la Dimensión 2 (tiros con sit='shootout' excluidos) y en la Dimensión 4
(xg_medio). Los tres cálculos, hechos desde tablas distintas, ahora coinciden exactamente en 1,50
xG/partido para Colombia — una validación cruzada fuerte de que el dato es consistente.

A diferencia de lo que sugería el dato contaminado, el partido de mayor producción ofensiva de
Colombia en todo el torneo NO fue la eliminación ante Suiza, sino Octavos de Final ante Ghana
(2,18 xG). El partido ante Suiza (0-0, definido por penales) fue, de hecho, el de MENOR xG de los
cinco (1,03) y también el de menor posesión del torneo para Colombia (47%). En síntesis: Colombia
no cayó eliminada en su mejor partido del Mundial, sino en uno de sus partidos más flojos en
generación de ocasiones — lo que matiza la narrativa de "dominó pero no convirtió" y sugiere que,
específicamente en el partido decisivo, el problema fue tanto de producción como de conversión.
*/