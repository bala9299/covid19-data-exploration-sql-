/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- look at the databases
Select *
From covid19db..CovidDeaths

Select *
From covid19db..CovidVaccinations
order by 1,2

Select *
From covid19db..CovidDeaths
Where continent is not null 
order by 1,2

-- Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From covid19db..CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows deathpercentage in your country

SELECT Location, date, total_cases, total_deaths, 
       (CONVERT(FLOAT, total_deaths) / CONVERT(FLOAT, total_cases)) * 100 AS DeathPercentage
FROM covid19db..CovidDeaths
WHERE Location = 'India' AND continent IS NOT NULL
ORDER BY 1, 2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in india

Select Location, date, Population, total_cases,  (CONVERT(FLOAT, total_cases) / CONVERT(FLOAT, Population))*100 as PercentPopulationInfected
From covid19db..CovidDeaths
Where location ='India' 
order by 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(
        (CONVERT(FLOAT, total_cases) / NULLIF(CONVERT(FLOAT, Population), 0)) * 100
    ) AS PercentPopulationInfected
FROM covid19db..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Infection Rate in my country

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  
			Max((CONVERT(FLOAT, total_cases) / CONVERT(FLOAT, Population)))*100 as PercentPopulationInfected
From covid19db..CovidDeaths
Where location ='India'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From covid19db..CovidDeaths
--Where location like '%india%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From covid19db..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	 SUM(CONVERT(int,cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
	
From covid19db..CovidDeaths cd
Join covid19db..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, (CONVERT(int,vac.new_vaccinations))
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From covid19db..CovidDeaths dea
Join covid19db..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From covid19db..CovidDeaths dea
Join covid19db..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid19db..CovidDeaths dea
Join covid19db..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


select * 
from PercentPopulationVaccinated






