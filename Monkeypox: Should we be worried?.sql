--WHO African Countries (Endemic countries)
SELECT *
	FROM monkeypox_who_africa;

--Insert region as a new column in monkeypox_who_africa
ALTER TABLE monkeypox_who_africa
	ADD COLUMN region VARCHAR;
	
--Update region column to reflect Africa
UPDATE monkeypox_who_africa
SET region = 'Africa'
WHERE region IS NULL;

--Death percentage in African countries
SELECT country, (confirmed_cases + suspected_cases) AS total_cases, deaths, 
ROUND((deaths * 100)/(confirmed_cases + suspected_cases)::numeric, 1) AS death_percentage
	FROM monkeypox_who_africa
WHERE deaths != 0;

--WHO Non-African Countries
SELECT * 
	FROM monkeypox_who_nonafrica;

--Confirmed cases per region in Non-African Countries
SELECT region, COUNT(*)
	FROM monkeypox_who_nonafrica
GROUP BY 1
ORDER BY 2 DESC;

--Combine all data
(SELECT *
	FROM monkeypox_who_nonafrica
UNION
SELECT region, country, confirmed_cases
	FROM monkeypox_who_africa)
ORDER BY confirmed_cases DESC;

--Create new table to reflect combined data from both African and non-African regions
CREATE TABLE monkeypox_who AS
(SELECT *
	FROM monkeypox_who_nonafrica
UNION
SELECT region, country, confirmed_cases
	FROM monkeypox_who_africa);

--The new table
SELECT *
	FROM monkeypox_who;

--Top 10 countries by confirmed cases
SELECT country, confirmed_cases
	FROM monkeypox_who
ORDER BY 2 DESC
LIMIT 10;

--Confirmed cases by regions
SELECT region, SUM(confirmed_cases) AS total_cases
	FROM monkeypox_who
GROUP BY 1
ORDER BY 1, 2;

--Countries with confirmed cases by regions
SELECT region, COUNT(*) AS country_count
	FROM monkeypox_who
GROUP BY 1
ORDER BY 1, 2

--Count of Endemic vs Non-Endemic countries
SELECT CASE WHEN region = 'Africa' THEN 'Endemic'
		ELSE 'Non-endemic' END AS country_classification, 
		COUNT(*)
	FROM monkeypox_who
GROUP BY 1
ORDER BY 2;
