
CREATE VIEW senaryo2_sonuc AS
SELECT
    id,
    project_id,
    value_type,
    period_start,
    period_finish,
    CASE WHEN category_type = 'Fizibilite' THEN COST_VALUE ELSE 0 END AS FEASIBILITY,
    CASE WHEN category_type = 'Tamamlanma' THEN COST_VALUE ELSE 0 END AS FORECAST,
    CASE WHEN category_type = 'Gerçekleşme' THEN COST_VALUE ELSE 0 END AS ACTUAL
FROM ppmdb.z_beat_senaryo_2

select * from senaryo2_sonuc



--Answer with PIVOT
select * from (
	select category_type,sum(cost_value) from  ppmdb.z_beat_senaryo_2
	group by category_type
) as senaryo2_result
PIVOT
(
	sum(cost_value) for category_type in('Tamamlanma','Gerçekleşme','Fizibilite')
) as pivot_result
