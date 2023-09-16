
--drop table temp_sure
CREATE TEMP TABLE temp_sure
  (
     request_id INT,
	  analiz_onayi_suresi INT
  );
insert into temp_sure
SELECT request_id,
    EXTRACT(DAY FROM MAX(bitis_tarihi) - MIN(baslangic_tarihi)) as analiz_onayi_suresi
FROM (

select request_id,
        TO_TIMESTAMP(start, 'MM.DD.YY HH24:MI') AS baslangic_tarihi,
        TO_TIMESTAMP(finish, 'MM.DD.YY HH24:MI') AS bitis_tarihi,
		stage
		from ppmdb.z_beat_senaryo_1 
		where stage <> 'TAMAMLANDI' and stage = 'ANALIZ_ONAYI'
	)
	as filtered_data2
GROUP BY request_id
order by request_id;

SELECT * FROM temp_sure

--drop table sonuc
CREATE TEMP TABLE sonuc
  (
     request_id INT,
	 ay text,
	  tamamlanma_suresi_gun INT,
	  ortalama_gun_yillik INT
  );
INSERT INTO sonuc
SELECT 
	filtered_data.request_id,
	TO_CHAR(MAX(CAST(filtered_data.bitis_tarihi AS DATE)), 'Month YYYY')  as ay,
    (EXTRACT(DAY FROM MAX(bitis_tarihi) - MIN(baslangic_tarihi))) - MAX(temp_sure.analiz_onayi_suresi) as tamamlanma_suresi_aylik,
	(EXTRACT(DAY FROM MAX(bitis_tarihi) - MIN(baslangic_tarihi))) - MAX(temp_sure.analiz_onayi_suresi) as tamamlanma_suresi_yillik
	
FROM (
    SELECT 
        request_id,
        TO_TIMESTAMP(start, 'MM.DD.YY HH24:MI') AS baslangic_tarihi,
        TO_TIMESTAMP(finish, 'MM.DD.YY HH24:MI') AS bitis_tarihi,
        stage
    FROM ppmdb.z_beat_senaryo_1
    WHERE stage <> 'ANALIZ_ONAYI' AND stage <> 'TAMAMLANDI' AND finish IS NOT NULL
) as filtered_data
inner join temp_sure
on filtered_data.request_id = temp_sure.request_id
GROUP BY filtered_data.request_id
order by 2

select * from sonuc

WITH result AS (
    SELECT 
        ay, 
        AVG(tamamlanma_suresi_gun) as Ortalama_Gün_Aylık,
	count(ay) as satırSayısı,
	count(ay) * AVG(tamamlanma_suresi_gun) as toplam,
        ROW_NUMBER() OVER (ORDER BY TO_DATE(CONCAT('01-', ay, ' 2000'), 'DD-Month YYYY')) as RowNum
    FROM Sonuc
    GROUP BY ay
)


SELECT 
    r.ay,
    r.Ortalama_Gün_Aylık,
    (
        1
    ) as Yıllık_Ortalama
FROM result r
ORDER BY r.RowNum;





select * into resultv2 from (
 SELECT 
        ay, 
        AVG(tamamlanma_suresi_gun) as Ortalama_Gün_Aylık,
	count(ay) as satırSayısı,
	count(ay) * AVG(tamamlanma_suresi_gun) as toplam,
        ROW_NUMBER() OVER (ORDER BY TO_DATE(CONCAT('01-', ay, ' 2000'), 'DD-Month YYYY')) as RowNum
    FROM Sonuc 
    GROUP BY ay) as snc
	
	select * from resultv2
	
ALTER TABLE resultv2
ADD COLUMN sonuc numeric;

UPDATE resultv2
SET sonuc = (
    SELECT COALESCE(SUM(toplam), 0)
    FROM resultv2 t2
    WHERE t2.rownum <= resultv2.rownum
);	

ALTER TABLE resultv2
ADD COLUMN toplamsatırsayısı numeric;

UPDATE resultv2
SET toplamsatırsayısı = (
    SELECT COALESCE(SUM(satırsayısı), 0)
    FROM resultv2 t2
    WHERE t2.rownum <= resultv2.rownum
);


select ay,ortalama_gün_aylık,sonuc/toplamsatırsayısı as ortalama_gun_yillik from resultv2

