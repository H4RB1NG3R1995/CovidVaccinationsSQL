SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4

/*Data we are going to be using*/

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

/*Looking at total cases vs total deaths*/
/*Shows likelihood of dying if you conract covid in India*/

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'India' AND continent IS NOT NULL
ORDER BY DeathPercentage DESC

/*Looking at total cases vs population*/
/*Shows what percentage of population got Covid*/

SELECT location, date, population, total_cases, (total_cases/population) * 100 AS InfectedPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'India' AND continent IS NOT NULL
ORDER BY InfectedPercentage DESC

/*Looking at countries with highest infection rate compared to population*/

SELECT location, population, max(total_cases) AS HighestInfectionCount, max((total_cases/population)) * 100 AS MaxInfectedPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population 
ORDER BY MaxInfectedPercentage DESC

/*Looking at countries with highest death count compared to population*/

SELECT location, max(cast(total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

/*Looking at Continents with highest death count compared to population*/

SELECT location, max(cast(total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

/*Global numbers*/

SELECT date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY DeathPercentage DESC

/*Looking at total population vs vaccinations*/

-- Using CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
	INNER JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
),
VacvsPop AS
(
SELECT *, MAX(RollingPeopleVaccinated) OVER (PARTITION BY Continent, Location) AS MaxVaccinated
FROM PopvsVac
)
SELECT Continent, Location, Date, Population, RollingPeopleVaccinated, ROUND((MaxVaccinated/Population) * 100, 2) AS MaxVaccinatedvsPopulationPercentage
FROM VacvsPop
ORDER BY Location, Date

-- Using View

CREATE VIEW PercentPopulationVaccinated AS
(
SELECT Continent, Location, Date, Population, RollingPeopleVaccinated, ROUND((RollingPeopleVaccinated/Population) * 100, 2) AS RollingVaccinatedvsPopulation
FROM (SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	FROM PortfolioProject.dbo.CovidDeaths dea
		INNER JOIN PortfolioProject.dbo.CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL) AS Table1
)

SELECT *
FROM PercentPopulationVaccinated
ORDER BY Location, Date