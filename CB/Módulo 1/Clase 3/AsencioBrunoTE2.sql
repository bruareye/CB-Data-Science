/*
Etapa 2 – Resumen global del torneo

Generar una sola fila con:

1. partidos;
2. goles locales;
3. goles visitantes;
4. goles totales;
5. promedio de goles por partido;
6. mínimo de goles en un partido;
7. máximo de goles en un partido.
*/

SELECT
    COUNT(event_id) AS partidos,
    SUM(home_score) AS golesLocales,
    SUM(away_score) AS golesVisitante,
    SUM(home_score + away_score) AS golesTotales,
    AVG(home_score + away_score) AS promedioDeGoles,
    MIN(home_score + away_score) AS minimo_goles,
    MAX(home_score + away_score) AS maximo_goles

FROM Partidos