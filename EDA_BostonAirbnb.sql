-- Análise Exploratória de Dados usando SQL Server: Boston Airbnb

---------------------------------------------------------------------------------------------------------
-- TOP 10 propriedades com maiores preços e qual é o tipo de propriedade de cada uma delas

SELECT TOP 10 po.id, pd.property_type, po.price 
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
ORDER BY po.price DESC;

---------------------------------------------------------------------------------------------------------
-- Preço médio por tipo de propriedade

SELECT pd.property_type AS tipo_propriedade, ROUND(AVG(po.price),2) As preço_médio
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
WHERE pd.property_type IS NOT NULL
GROUP BY pd.property_type
ORDER BY preço_médio DESC;

-----------------------------------------------------------------------------------------------------------
-- Desconto no preço de cada propriedade caso o hospede decida alugar por uma semana ou por um mês

SELECT id, price,
	   price*7 AS preço_bruto_semanal,
	   weekly_price, weekly_price - price*7  AS desconto_semanal,
	   price*30 AS preço_bruto_mensal,
	   monthly_price, monthly_price - price*30 AS desconto_mensal
FROM propriedades_ofertas;

----------------------------------------------------------------------------------------------------------
-- Média de preço por política de cancelamento

SELECT pd.property_type, po.cancellation_policy, AVG(price) AS preço_médio
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
WHERE property_type IS NOT NULL
GROUP BY pd.property_type, po.cancellation_policy
ORDER BY property_type, cancellation_policy;

-----------------------------------------------------------------------------------------------------------
-- Classifique as propriedades por faixa de preço e mostre a quantidade de casas por faixa de preço

WITH faixa_preço_count AS
(
SELECT id,
	   CASE
			WHEN price <= 100
				 THEN 'Preço Baixíssimo'
			WHEN price > 100 AND price <= 200
				THEN 'Preço Baixo'
			WHEN price > 200 AND price <= 500
				 THEN 'Preço Moderado'
			WHEN price > 500 AND price <= 1000
				 THEN 'Preço Alto'
			WHEN price > 1000
				THEN 'Preço Altíssimo'
		END faixa_preço
FROM propriedades_ofertas
)

SELECT faixa_preço, COUNT(faixa_preço) AS quantidade
FROM faixa_preço_count
GROUP BY faixa_preço
ORDER BY quantidade DESC;

--------------------------------------------------------------------------
-- Número de propriedades por tipo

SELECT property_type, COUNT(property_type) AS quantidade_tipo
FROM propriedades_descricao
GROUP BY property_type
ORDER BY quantidade_tipo DESC;

-------------------------------------------------------------------------------------------------------
-- Média de acomodações, banheiros, quartos e camas por tipo de propriedade e faixa de preço

WITH faixa_preço_count AS
(
SELECT id,
	   CASE
			WHEN price <= 100
				 THEN 'Preço Baixíssimo'
			WHEN price > 100 AND price <= 200
				THEN 'Preço Baixo'
			WHEN price > 200 AND price <= 500
				 THEN 'Preço Moderado'
			WHEN price > 500 AND price <= 1000
				 THEN 'Preço Alto'
			WHEN price > 1000
				THEN 'Preço Altíssimo'
		END faixa_preço
FROM propriedades_ofertas
)
SELECT property_type, fc.faixa_preço, ROUND(AVG(pd.accommodates), 2) acomodações,
       ROUND(AVG(pd.bathrooms),2) banheiros, ROUND(AVG(pd.bedrooms),2) quartos, ROUND(AVG(pd.beds),2) camas
FROM propriedades_descricao pd
INNER JOIN faixa_preço_count fc
	ON pd.id = fc.id
WHERE property_type IS NOT NULL
GROUP BY property_type, faixa_preço
ORDER BY property_type, faixa_preço;

-------------------------------------------------------------------------------------------------
-- Número de propriedades por avenida/rua

SELECT SUBSTRING(street, 1, CHARINDEX(',', street) - 1) As avenida_rua,
	   COUNT(id) propriedades_quantidade
FROM geolocalizacao
WHERE CHARINDEX(',', street) - 1 > 0
GROUP BY street
ORDER BY propriedades_quantidade DESC;

-------------------------------------------------------------------------------------------------
-- Preço médio dos tipos de propriedades em cada rua/avenida

-- DROP TABLE #id_rua;
CREATE TABLE #id_rua (id NUMERIC, rua VARCHAR(MAX));

INSERT INTO #id_rua
SELECT id, SUBSTRING(street, 1, CHARINDEX(',', street) - 1)
FROM geolocalizacao
WHERE CHARINDEX(',', street) - 1 > 0;

SELECT * FROM #id_rua;

SELECT rua, pd.property_type, AVG(price) AS preço_médio
FROM propriedades_ofertas po
INNER JOIN propriedades_descricao pd
	ON po.id = pd.id
INNER JOIN #id_rua ir
	ON po.id = ir.id
GROUP BY ir.rua, pd.property_type
ORDER BY ir.rua;

-------------------------------------------------------------------------------------------------
-- Os 20 proprietários com mais reviews e suas notas

SELECT TOP 20 p.host_id, SUM(pr.number_of_reviews) reviews_contagem, AVG(pr.review_scores_rating) AS score_médio
FROM proprietarios p
LEFT JOIN propriedades_descricao pd
	ON pd.host_id = p.host_id
INNER JOIN propriedades_reviews pr
	ON pd.id = pr.id
GROUP BY p.host_id
ORDER BY reviews_contagem DESC, score_médio;

--------------------------------------------------------------------------------------------------
-- Média dos scores por tipo de propriedade

SELECT pd.property_type, AVG(pr.review_scores_rating) AS scores_média
FROM propriedades_descricao pd
INNER JOIN propriedades_reviews pr
	ON pd.id = pr.id
GROUP BY pd.property_type
ORDER BY scores_média DESC;

--------------------------------------------------------------------------------------------------
-- Quais ruas/avenidas receberam as melhores notas de reviews?

SELECT g.street, AVG(pr.review_scores_location) AS location_review
FROM geolocalizacao g
INNER JOIN propriedades_reviews pr
	ON g.id = pr.id
WHERE pr.review_scores_location IS NOT NULL
GROUP BY g.street
ORDER BY location_review DESC;