/****** Script for SelectTopNRows command from SSMS  ******/
SELECT * FROM  [Benjaminproject].[dbo].[CovidVaccinations]
ORDER BY 3,4

SELECT * FROM [Benjaminproject].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT DATA TO BE USED--

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Benjaminproject].[dbo].[CovidDeaths]
ORDER BY 1,2

-- Analysing total cases against the total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Benjaminproject].[dbo].[CovidDeaths]
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Benjaminproject].[dbo].[CovidDeaths]
WHERE location LIKE '%United Kingdom%'
ORDER BY 1,2

-- Analysing total cases against population
-- shows that percentage of population that will contract covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS DeathPercentage
FROM [Benjaminproject].[dbo].[CovidDeaths]
WHERE location LIKE '%United Kingdom%'
ORDER BY 1,2

--Analysing at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentageofPopulationEffected
FROM [Benjaminproject].[dbo].[CovidDeaths]
GROUP BY location, population
ORDER BY PercentageofPopulationEffected DESC

---Analysis base on continents---

SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM [Benjaminproject].[dbo].[CovidDeaths]
WHERE continent IS NULL AND location NOT LIKE '[!WI]%'
GROUP BY location
ORDER BY TotalDeathCount DESC


--- showing continents with highest death count/population---

SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM [Benjaminproject].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-----Global Numbers----

SELECT date, SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths AS INT)) AS Total_Deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM [Benjaminproject].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


---Looking at Total Population vs Vaccinations--

SELECT *
FROM [Benjaminproject].[dbo].[CovidDeaths] dea
JOIN [Benjaminproject].[dbo].CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [Benjaminproject].[dbo].[CovidDeaths] dea
JOIN [Benjaminproject].[dbo].CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

---Using Partition By----

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
AS ContinuousVaccinatedCount
FROM [Benjaminproject].[dbo].[CovidDeaths] dea
JOIN [Benjaminproject].[dbo].CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

----Creating a CTE----

With PopulVsVacc (continent, location, date, population, new_vaccinations, ContinuousVaccinatedCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
AS ContinuousVaccinatedCount
FROM [Benjaminproject].[dbo].[CovidDeaths] dea
JOIN [Benjaminproject].[dbo].CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (ContinuousVaccinatedCount/population)*100 AS VaccinatedRatio
FROM PopulVsVacc

----- TEMP Table----
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
continent NVARCHAR(255),
Location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
ContinuousVaccinatedCount NUMERIC
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
AS ContinuousVaccinatedCount
FROM [Benjaminproject].[dbo].[CovidDeaths] dea
JOIN [Benjaminproject].[dbo].CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (ContinuousVaccinatedCount/population)*100 AS VaccinatedRatio
FROM #PercentagePopulationVaccinated


----Creating views to store data for visualizatio---

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
AS ContinuousVaccinatedCount
FROM [Benjaminproject].[dbo].[CovidDeaths] dea
JOIN [Benjaminproject].[dbo].CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
