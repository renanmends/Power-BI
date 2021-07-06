-- An�lise Explorat�ria de Dados usando SQL Server: Boston Airbnb

---------------------------------------------------------------------------------------------------------
-- TOP 10 propriedades com maiores pre�os e qual � o tipo de propriedade de cada uma delas

SELECT TOP 10 po.id, pd.property_type, po.price 
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
ORDER BY po.price DESC;

---------------------------------------------------------------------------------------------------------
-- Pre�o m�dio por tipo de propriedade

SELECT pd.property_type AS tipo_propriedade, ROUND(AVG(po.price),2) As pre�o_m�dio
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
WHERE pd.property_type IS NOT NULL
GROUP BY pd.property_type
ORDER BY pre�o_m�dio DESC;

-----------------------------------------------------------------------------------------------------------
-- Desconto no pre�o de cada propriedade caso o hospede decida alugar por uma semana ou por um m�s

SELECT id, price,
	   price*7 AS pre�o_bruto_semanal,
	   weekly_price, weekly_price - price*7  AS desconto_semanal,
	   price*30 AS pre�o_bruto_mensal,
	   monthly_price, monthly_price - price*30 AS desconto_mensal
FROM propriedades_ofertas;

----------------------------------------------------------------------------------------------------------
-- M�dia de pre�o por pol�tica de cancelamento

SELECT pd.property_type, po.cancellation_policy, AVG(price) AS pre�o_m�dio
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
WHERE property_type IS NOT NULL
GROUP BY pd.property_type, po.cancellation_policy
ORDER BY property_type, cancellation_policy;

-----------------------------------------------------------------------------------------------------------
-- Classifique as propriedades por faixa de pre�o e mostre a quantidade de casas por faixa de pre�o

WITH faixa_pre�o_count AS
(
SELECT id,
	   CASE
			WHEN price <= 100
				 THEN 'Pre�o Baix�ssimo'
			WHEN price > 100 AND price <= 200
				THEN 'Pre�o Baixo'
			WHEN price > 200 AND price <= 500
				 THEN 'Pre�o Moderado'
			WHEN price > 500 AND price <= 1000
				 THEN 'Pre�o Alto'
			WHEN price > 1000
				THEN 'Pre�o Alt�ssimo'
		END faixa_pre�o
FROM propriedades_ofertas
)

SELECT faixa_pre�o, COUNT(faixa_pre�o) AS quantidade
FROM faixa_pre�o_count
GROUP BY faixa_pre�o
ORDER BY quantidade DESC;

--------------------------------------------------------------------------
-- N�mero de propriedades por tipo

SELECT property_type, COUNT(property_type) AS quantidade_tipo
FROM propriedades_descricao
GROUP BY property_type
ORDER BY quantidade_tipo DESC;

-------------------------------------------------------------------------------------------------------
-- M�dia de acomoda��es, banheiros, quartos e camas por tipo de propriedade e faixa de pre�o

WITH faixa_pre�o_count AS
(
SELECT id,
	   CASE
			WHEN price <= 100
				 THEN 'Pre�o Baix�ssimo'
			WHEN price > 100 AND price <= 200
				THEN 'Pre�o Baixo'
			WHEN price > 200 AND price <= 500
				 THEN 'Pre�o Moderado'
			WHEN price > 500 AND price <= 1000
				 THEN 'Pre�o Alto'
			WHEN price > 1000
				THEN 'Pre�o Alt�ssimo'
		END faixa_pre�o
FROM propriedades_ofertas
)
SELECT property_type, fc.faixa_pre�o, ROUND(AVG(pd.accommodates), 2) acomoda��es,
       ROUND(AVG(pd.bathrooms),2) banheiros, ROUND(AVG(pd.bedrooms),2) quartos, ROUND(AVG(pd.beds),2) camas
FROM propriedades_descricao pd
INNER JOIN faixa_pre�o_count fc
	ON pd.id = fc.id
WHERE property_type IS NOT NULL
GROUP BY property_type, faixa_pre�o
ORDER BY property_type, faixa_pre�o;

-------------------------------------------------------------------------------------------------
-- N�mero de propriedades por avenida/rua

SELECT SUBSTRING(street, 1, CHARINDEX(',', street) - 1) As avenida_rua,
	   COUNT(id) propriedades_quantidade
FROM geolocalizacao
WHERE CHARINDEX(',', street) - 1 > 0
GROUP BY street
ORDER BY propriedades_quantidade DESC;

-------------------------------------------------------------------------------------------------
-- Pre�o m�dio dos tipos de propriedades em cada rua/avenida

-- DROP TABLE #id_rua;
CREATE TABLE #id_rua (id NUMERIC, rua VARCHAR(MAX));

INSERT INTO #id_rua
SELECT id, SUBSTRING(street, 1, CHARINDEX(',', street) - 1)
FROM geolocalizacao
WHERE CHARINDEX(',', street) - 1 > 0;

SELECT * FROM #id_rua;

SELECT rua, pd.property_type, AVG(price) AS pre�o_m�dio
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
INNER JOIN #id_rua ir
	ON po.id = ir.id
GROUP BY ir.rua, pd.property_type
ORDER BY ir.rua;

-------------------------------------------------------------------------------------------------
-- Os 20 propriet�rios com mais reviews e suas notas

SELECT TOP 20 p.host_id, SUM(pr.number_of_reviews) reviews_contagem, AVG(pr.review_scores_rating) AS score_m�dio
FROM proprietarios p
LEFT JOIN propriedades_descricao pd
	ON pd.host_id = p.host_id
INNER JOIN propriedades_reviews pr
	ON pd.id = pr.id
GROUP BY p.host_id
ORDER BY reviews_contagem DESC, score_m�dio;

--------------------------------------------------------------------------------------------------
-- M�dia dos scores por tipo de propriedade

SELECT pd.property_type, AVG(pr.review_scores_rating) AS scores_m�dia
FROM propriedades_descricao pd
INNER JOIN propriedades_reviews pr
	ON pd.id = pr.id
GROUP BY pd.property_type
ORDER BY scores_m�dia DESC;

--------------------------------------------------------------------------------------------------
-- Quais ruas/avenidas receberam as melhores notas de reviews?

SELECT g.street, AVG(pr.review_scores_location) AS location_review
FROM geolocalizacao g
INNER JOIN propriedades_reviews pr
	ON g.id = pr.id
WHERE pr.review_scores_location IS NOT NULL
GROUP BY g.street
ORDER BY location_review DESC;