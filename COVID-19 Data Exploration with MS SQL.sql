SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;


SELECT * 
FROM CovidVaccinations
ORDER BY 3,4;


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio Project.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


--Total cases vs Total deaths
--Shows likelihood of dying from COVID in each country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
--AND location = 'Nigeria'
ORDER BY 1,2;


--Total cases vs Population
--Shows percentage of population got COVID in each country
SELECT location, date, total_cases, population, (total_cases/population)*100 AS case_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
--AND location = 'Nigeria'
ORDER BY 1,2;


--Highest infection rates per country compared to population
SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((total_cases/population)*100) AS infection_rates
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;


--Highest death count per country compared to population #1
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;


--Highest death count per country compared to population #2
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidDeaths
WHERE location NOT IN('World', 'Europe', 'North America', 'European Union', 'South America', 'Asia', 'Africa','Oceania','International')
GROUP BY location
ORDER BY 2 DESC;


--Highest death count per continent compared to population #1 - captures International
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC;


--Highest death count per continent compared to population #2- does not capture International
SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;


--Global numbers #1
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;


--Global numbers #2
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


--Join Covid deaths and vaccinations tables
SELECT *
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date


--Total poulation vs. Vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS cumulative_vaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3


--Percentage cumulative vaccinations using CTE
WITH PopvsVac (Continent, Location, Date, Population,New_vaccinations, Cumulative_vaccinations)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS cumulative_vaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT *, (cumulative_vaccinations/Population)*100
FROM PopvsVac


--Percentage cumulative vaccinations using Temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS cumulative_vaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
--WHERE cd.continent IS NOT NULL
SELECT *, (cumulative_vaccinations/population)*100
FROM #PercentPopulationVaccinated


--Creating view to store data for visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS cumulative_vaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
