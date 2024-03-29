-- PRGH ED visitors known to PARIS Community
IF OBJECT_ID('tempdb.dbo.#tempPRGHEDKnownToPARISMH') IS NOT NULL DROP TABLE #tempPRGHEDKnownToPARISMH
SELECT a.PatientID
	, a.VisitID
	, a.StartDate
	, a.StartTime
	, c.Interval_1_Hour
	, a.AdmittedFlag
	, Case when b.PatientID is not null then 1 else 0 end as KnownToPARISMH
	, datediff(day, '2017-04-01','2019-01-31') + 1 as DayCount
	, d.DayOfWeek
	, d.DayOfWeekNbr
	, d.CalendarYear
Into #tempPRGHEDKnownToPARISMH
FROM [EDMart].[dbo].[vwEDVisitIdentifiedRegional] a
Left join (SELECT Distinct PatientID
	FROM [CommunityMart].[dbo].[vwPARISReferral]
	Where CommunityProgramGroup = 'Mental Health & Addictions'
		and  CommunityProgram in ('Mental Health', 'Mental Health & Addiction')) b on a.PatientID = b.PatientID
Left join [ADTCMart].[dim].[Time] c on a.StartTime = c.Time24Hr
Left join [ADRMart].[Dim].[Date] d on a.StartDate = d.ShortDate
Where a.StartDate between '2017-04-01' and '2019-01-31' 
	and a.FacilityLongName = 'Powell River General Hospital'
-- Select * From #tempPRGHEDKnownToPARISMH
-- 32,632 rows

-- Average ED daily volume and Average number of ED visitors known to PARIS MH
Select count(PatientID)*1.0/avg(DayCount) as AvgEDVolbyDay
 , sum(KnownToPARISMH)*1.0/avg(DayCount) as AvgEDVolKnowntoParisMHbyDay
From #tempPRGHEDKnownToPARISMH


-- Time of day ED patients present to the ED
Select Interval_1_Hour
	, count(PatientID)*1.0/avg(DayCount) as AvgEDVolbyDay
	, sum(KnownToPARISMH)*1.0/avg(DayCount) as AvgEDVolKnowntoParisMHbyDay
From #tempPRGHEDKnownToPARISMH
Group by Interval_1_Hour
Order by Interval_1_Hour

-- The percentage of ED patients known to PARIS MH who are admitted
Select sum(Case when AdmittedFlag = 1 then 1 else 0 end) * 1.0 / count(PatientID)
From #tempPRGHEDKnownToPARISMH
Where KnownToPARISMH = 1


Select b.MCCPlus, count(a.PatientID)
From #tempPRGHEDKnownToPARISMH a
Left join [ADRMart].[dbo].[vwAbstractFact] b on a.PatientID = b.PatientID and a.VisitID = b.RegisterNumber

Where a.KnownToPARISMH = 1
	and a.AdmittedFlag = 1
	and b.MCCPlus is not NULL
Group by b.MCCPlus
Order by count(a.PatientID) desc



-- 1,071 rows


-- Average ED daily volume and Average number of ED visitors known to PARIS MH by day of week
Select a.DayOfWeek
	, a.DayOfWeekNbr
	, StartDate
	--, b.CountDayOfWeek
	, count(PatientID)*1.0 as ed_visits
    , sum(KnownToPARISMH)*1.0 ed_visits_known_to_PARIS_MH 
From #tempPRGHEDKnownToPARISMH a
Left join (Select DayOfWeek
				, count(DayOfWeek) as CountDayOfWeek
			From [ADRMart].[Dim].[Date] 
			Where ShortDate between '2017-04-01' and '2019-01-31' 
			Group by DayOfWeek) b on a.DayOfWeek= b.DayOfWeek
Group by StartDate
	, a.DayOfWeek
	, a.DayOfWeekNbr
Order by StartDate

