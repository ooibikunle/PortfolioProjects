SELECT *
	FROM forbes_billionaires_2022;

--Total billionare count
SELECT COUNT(person_name) AS total_billionaire_count
	FROM forbes_billionaires_2022;

--Net worth of all billionaires
SELECT SUM(final_worth) AS total_net_worth
	FROM forbes_billionaires_2022;
	
--Top 10 billionaires
SELECT person_name, final_worth
	FROM forbes_billionaires_2022
ORDER BY 2 DESC
LIMIT 10;

--Youngest male billionaire
SELECT person_name, MIN(age) AS youngest_billionaire, final_worth
	FROM forbes_billionaires_2022
WHERE age IS NOT NULL AND gender = 'M'
GROUP BY 1, 3
ORDER BY 2 
LIMIT 1;

--Oldest male billionaire
SELECT person_name, MAX(age) AS oldest_billionaire, final_worth
	FROM forbes_billionaires_2022
WHERE age IS NOT NULL AND gender = 'M'
GROUP BY 1, 3
ORDER BY 2 DESC
LIMIT 1;

--Youngest female billionaire
SELECT person_name, MIN(age) AS youngest_billionaire, final_worth
	FROM forbes_billionaires_2022
WHERE age IS NOT NULL AND gender = 'F'
GROUP BY 1, 3
ORDER BY 2 
LIMIT 1;

--Oldest female billionaire
SELECT person_name, MAX(age) AS oldest_billionaire, final_worth
	FROM forbes_billionaires_2022
WHERE age IS NOT NULL AND gender = 'F'
GROUP BY 1, 3
ORDER BY 2 DESC
LIMIT 1;

--Count of billionaires per country (top 10)
SELECT country_of_citizenship, COUNT(country_of_citizenship) AS billionaires_count
	FROM forbes_billionaires_2022
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--Net worth of billionaires per country
SELECT country_of_citizenship, SUM(final_worth) AS net_worth
	FROM forbes_billionaires_2022
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--Count of billionaires per industry (top 10)
SELECT category, COUNT(category) AS billionaires_count
	FROM forbes_billionaires_2022
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--Net worth of billionaires per industry
SELECT category, SUM(final_worth) AS net_worth
	FROM forbes_billionaires_2022
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--Male vs Female vs Joint billionaire count
SELECT COUNT(CASE WHEN gender = 'F' THEN 1 ELSE NULL END) AS female_billionaire_count,
       COUNT(CASE WHEN gender = 'M' THEN 1 ELSE NULL END) AS male_billionaire_count,
	   COUNT(CASE WHEN gender IS NULL THEN 1 ELSE NULL END) AS joint_billionaire_count
	FROM forbes_billionaires_2022;

--Joint billionaires
SELECT person_name, final_worth
	FROM forbes_billionaires_2022
WHERE gender IS NULL
ORDER BY 2 DESC;

--Richest female billionaire
SELECT person_name, MAX(final_worth) AS richest_female_billionaire
	FROM forbes_billionaires_2022
WHERE gender = 'F'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

--Richest male billionaire
SELECT person_name, MAX(final_worth) AS richest_male_billionaire
	FROM forbes_billionaires_2022
WHERE gender = 'M'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

--Billionaire count by age group
SELECT COUNT(CASE WHEN age >= 60 THEN 1 ELSE NULL END) AS senior_adult_count,
       COUNT(CASE WHEN age >= 40 AND age <= 59 THEN 1 ELSE NULL END) AS middle_aged_count,
	   COUNT(CASE WHEN age >= 18 AND age <= 39 THEN 1 ELSE NULL END) AS young_adult_count,
	   COUNT(CASE WHEN age IS NULL THEN 1 ELSE NULL END) AS undisclosed_count
	FROM forbes_billionaires_2022;

--Forbes under 30
SELECT person_name, final_worth
	FROM forbes_billionaires_2022
WHERE age < 30
ORDER BY 2 DESC;

--Forbes under 30 & self-made
SELECT person_name, final_worth
	FROM forbes_billionaires_2022
WHERE age < 30 AND self_made = 'TRUE'
ORDER BY 2 DESC;

--Self-made vs Contingent billionaire count 1
SELECT COUNT(CASE WHEN self_made = 'TRUE' THEN 1 ELSE NULL END) AS selfmade_billionaire_count,
       COUNT(CASE WHEN self_made = 'FALSE' THEN 1 ELSE NULL END) AS contingent_billionaire_count
	FROM forbes_billionaires_2022;

--Self-made vs Contingent billionaire count 2
SELECT CASE WHEN self_made = 'TRUE' THEN 'self-made'
       		ELSE 'contingent'
	   		END AS selfmade_or_contingent_billionaire,
	   COUNT(*)
	FROM forbes_billionaires_2022
GROUP BY 1;

--Most philanthropic billionaires
SELECT person_name, final_worth, philanthropy_score
	FROM forbes_billionaires_2022
WHERE philanthropy_score >=4
ORDER BY 3 DESC, 2 DESC;

--Billionaires grouped by philanthropy score
SELECT CASE WHEN philanthropy_score >= 1 AND philanthropy_score <=5 THEN 'philanthropic'
	   ELSE 'non-philanthropic'
       END AS philanthropy_status,
	   COUNT(*) AS billionaire_count
	FROM forbes_billionaires_2022
GROUP BY 1;
