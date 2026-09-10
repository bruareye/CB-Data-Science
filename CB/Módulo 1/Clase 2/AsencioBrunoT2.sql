-- Escriba un único archivo SQL que produzca un reporte de los partidos de France y Argentina en fase de grupos.

-- El reporte debe:

-- Incluir event_id, fecha, grupo, local, visitante, marcador y goles totales.
-- Conservar partidos donde cualquiera de las dos selecciones sea local o visitante.
-- Limitarse a valores de group_name que comiencen con Group.
-- Ordenarse por selección involucrada ascendente, goles totales descendente.
-- Incluir una segunda consulta con el total de filas y los event_id distintos del resultado filtrado.

SELECT  event_id,
		event_date,
		group_name,
		home_team,
		away_team,
		home_score, 
        away_score,
		(home_score + away_score) AS total_score
		
FROM PARTIDOS
WHERE (home_team IN ('France', 'Argentina') OR away_team IN ('France', 'Argentina'))
  AND group_name LIKE 'Group%'
ORDER BY home_team ASC, total_score DESC


SELECT  COUNT(*) AS total_filas, 
        COUNT(DISTINCT event_id) AS event_id_unicos
FROM (

SELECT  event_id,
		event_date,
		group_name,
		home_team,
		away_team,
		home_score, 
        away_score,
		(home_score + away_score) AS total_score
		
FROM PARTIDOS
WHERE (home_team IN ('France', 'Argentina') OR away_team IN ('France', 'Argentina'))
  AND group_name LIKE 'Group%'

) AS resultado_filtrado