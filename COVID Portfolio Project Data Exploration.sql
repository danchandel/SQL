SELECT date
FROM covid_deaths
WHERE continent IS NOT NULL
order by 3, 4;

SELECT STR_TO_DATE(date,'%m/%d/%Y') as date
FROM covid_deaths;

/*
SELECT *
FROM covid_vaccinations
ORDER BY 3, 4; */ 

-- SELECT data that we are going to use

SELECT 
location,
STR_TO_DATE(date, '%m/%d/%Y') AS date, 
total_cases, 
new_cases,
total_deaths,
population
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT 
location, STR_TO_DATE(date, '%m/%d/%Y') AS date, total_cases, total_deaths,
(total_deaths/total_cases)*100 AS deathpercentage
FROM covid_deaths
WHERE location like '%pines%' AND continent IS NOT NULL
ORDER BY 1, 2;

-- Looking at the total cases vs. population
-- Shows what percentage of population got COVID
SELECT 
location, STR_TO_DATE(date, '%m/%d/%Y') AS date, population, total_cases,
(total_cases/population)*100 AS population_with_covid
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--  Looking at countries with highest infection rate compared to populations
SELECT 
location, population, MAX(total_cases) AS highestinfectioncount,
MAX((total_cases/population)*100) AS percentpopulationinfected
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY percentpopulationinfected DESC;

-- BREAKING THINGS DOWN BY CONTINENT

Select continent, MAX(cast(Total_deaths as decimal)) as TotalDeathCount
From covid_deaths
Where continent is not null
Group by continent
order by TotalDeathCount desc;

-- GLOBAL NUMBERS

SELECT 
-- location, 
-- STR_TO_DATE(date, '%m/%d/%Y') AS date, -- total_cases, total_deaths,
-- (total_deaths/total_cases)*100 AS deathpercentage
SUM(new_cases) AS total_cases,
SUM(CAST(new_deaths AS decimal)) AS total_deaths,
SUM(CAST(new_deaths AS decimal))/SUM(new_cases)*100 as DeathPercentage
FROM covid_deaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1;

-- Looking at Total Population vs Total Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS decimal)) OVER 
(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVac
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- USE CTE

WITH PopVSVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVac)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS decimal)) OVER 
(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVac
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3
)
SELECT *,
(RollingPeopleVac/Population)*100 
FROM PopVSVac;

DROP TABLE IF EXISTS percentpop_vaccinated;

-- TEMP TABLE
CREATE TEMPORARY TABLE percentpop_vaccinated (
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevac numeric);

INSERT INTO percentpop_vaccinated (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CASE WHEN vac.new_vaccinations = '' THEN NULL ELSE CAST(vac.new_vaccinations AS decimal) END)
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVac
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3);

SELECT *,
(RollingPeopleVac/Population)*100 
FROM percentpop_vaccinated;

-- Creating VIEW to store data later for data visualizations
CREATE VIEW percentpopulationvaccinated
AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CASE WHEN vac.new_vaccinations = '' THEN NULL ELSE CAST(vac.new_vaccinations AS decimal) END)
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVac
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

SELECT *
FROM percentpopulationvaccinated;