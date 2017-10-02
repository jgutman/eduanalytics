-- scores_current
create or replace view _scores_current as (
select aamc_id
	, application_year
	, score
from out$predictions$screening_current_cohort
where algorithm_id in (
	select id from algorithm
	where is_production = 1)
);

-- scores_historic
create or replace view _scores_historic as (
select aamc_id
	, application_year
	, predicted_invite - predicted_reject as score
	, outcome
from out$predictions$screening_train_val
where algorithm_id in (
	select id from algorithm
	where is_production = 1)
and `set` = "test"
);

-- gpa_mcat
create or replace view _gpa_mcat as (
select g.aamc_id
	, g.application_year
	, g.total_gpa_cumulative as gpa
	, cast(m.mcat as unsigned) as mcat
from vw$features$gpa g
left join
mcat_current_raw_score m
on (g.aamc_id = m.aamc_id 
	and g.application_year = m.application_year)
);

-- african_american
create or replace view _african_american as (
select aamc_id
	, application_year
	, if(african_american, "Y", "N") as african_american
from vw_african_american
);

-- demographics
create or replace view _demographics as (
select aamc_id
	, application_year
	, nullif(gender, "D") as gender
	, permanent_state as residency_state
	, ifnull(urm, "N") as urm
from vwScreenApplicationInfo
);

-- demographics_historic
create or replace view _demographics_historic as (
select s.*
	, d.gender
	, d.residency_state
	, d.urm
	, g.gpa
	, g.mcat
	, ifnull(a.african_american, "N") as african_american
from _scores_historic s
left join
_demographics d 
on (s.aamc_id = d.aamc_id 
	and s.application_year = d.application_year)
left join
_gpa_mcat g
on (s.aamc_id = g.aamc_id 
	and s.application_year = g.application_year)
left join
_african_american a
on (s.aamc_id = a.aamc_id 
	and s.application_year = a.application_year)
);

-- demographics_current
create or replace view _demographics_current as (
select s.*
	, d.gender
	, d.residency_state
	, d.urm
	, g.gpa
	, g.mcat
	, ifnull(a.african_american, "N") as african_american
from _scores_current s
left join
_demographics d 
on (s.aamc_id = d.aamc_id 
	and s.application_year = d.application_year)
left join
_gpa_mcat g
on (s.aamc_id = g.aamc_id 
	and s.application_year = g.application_year)
left join
_african_american a
on (s.aamc_id = a.aamc_id 
	and s.application_year = a.application_year)
);

-- historical_outcomes
create or replace view _historical_outcomes as (
select s.*
	, o.is_invited_interview
	, o.is_interviewed
	, o.is_offered_admission
	, (left(status, 1) in ('M', 'T')) as is_matriculated
from vw$filtered$screened o
right join 
_scores_historic s
on (s.aamc_id = o.aamc_id 
	and s.application_year = o.application_year)
);

select @lower_cutoff := -0.15, @upper_cutoff := 0.50;

-- predicted outcome: data = current
drop table if exists _data_current;
create temporary table _data_current as 
select * from (
	select *
		, (case when score > @upper_cutoff then "Invite"
			when score > @lower_cutoff then "Hold"
			else "Reject" end
		) as predicted_outcome
	from _demographics_current
	union
	# add overall category to predicted_outcome for group by 
	select *
		, "All" as predicted_outcome
	from _demographics_current
) as d;

-- predicted outcome: data = historic
drop table if exists _data_historic;
create temporary table _data_historic as 
select * from (
	select *
		, (case when score > @upper_cutoff then "Invite"
			when score > @lower_cutoff then "Hold"
			else "Reject" end
		) as predicted_outcome
	from _demographics_historic
	union
	# add overall category to predicted_outcome for group by
	select *
		, "All" as predicted_outcome
	from _demographics_historic
) as d;

-- predicted outcome: historic outcomes
drop table if exists _outcomes;
create temporary table _outcomes as 
select * from (
	select *
		, (case when score > @upper_cutoff then "Invite"
			when score > @lower_cutoff then "Hold"
			else "Reject" end
		) as predicted_outcome
	from _historical_outcomes
	union
	# add overall category to predicted_outcome for group by
	select *
		, "All" as predicted_outcome
	from _historical_outcomes
) as d;

#select predicted_outcome, count(*) from _data_current group by predicted_outcome;
#select predicted_outcome, count(*) from _data_historic group by predicted_outcome;
#select predicted_outcome, count(*) from _outcomes group by predicted_outcome;

-- crosstabs: current
select predicted_outcome
	, count(*) as "Number of applicants"
	, sum(gender = "F") as "Female"
	, round(avg(gender = "F"), 3) as "% Female"
	, sum(urm = "Y") as "URM"
	, round(avg(urm = "Y"), 3) as "% URM"
	, sum(african_american = "Y") as "African-American"
	, round(avg(african_american = "Y"), 3) as "% African-American"
	, sum(residency_state = "CA") as "California residency"
	, round(avg(residency_state = "CA"), 3) as "% California residency"
	# , median gpa as "Median GPA"
	# , concat (25% percentile gpa, - , 75% percentile gpa) as "25 - 75% cum. GPA"
	# , median mcat as "Median MCAT"
	# , concat (25% percentile mcat, - , 75% percentile mcat) as "25 - 75% MCAT"
from _data_current # change to _data_historic for historic toggle
group by predicted_outcome
order by (
# custom sort
case predicted_outcome 
	when "Reject" then 1
	when "Hold" then 2
	when "Invite" then 3
	else 4 end
);

drop table if exists _screening_counts;
create temporary table _screening_counts as 
select predicted_outcome
	, count(*) total
	, sum(	if( score > @lower_cutoff 
			and score <= @upper_cutoff, 1, 0)) as n_screenings
from _data_current
group by predicted_outcome
;

drop table if exists _historical_pcts;
create temporary table _historical_pcts as 
select predicted_outcome
	, avg(is_invited_interview) as invited
	, avg(is_offered_admission) as accepted
	, avg(is_matriculated) as matriculated
	, count(*) hist_total
	, sum(is_offered_admission)/sum(is_invited_interview) as accepted_if_invited
	, sum(is_matriculated)/sum(is_invited_interview) as matriculated_if_invited
	from _outcomes
	group by predicted_outcome
;

select * from _screening_counts;
select * from _historical_pcts;

-- projections: current
drop table if exists _intermediate_projections;
create temporary table _intermediate_projections as
select o.*
	, c.total
	, c.n_screenings
	, (case o.predicted_outcome
		when "Reject" then 0
		when "Hold" then round(o.invited * c.total)
		when "Invite" then c.total
		else NULL end) as n_invites
from _historical_pcts o
left join
_screening_counts c
on c.predicted_outcome = o.predicted_outcome
order by (
# custom sort
case o.predicted_outcome 
	when "Reject" then 1
	when "Hold" then 2
	when "Invite" then 3
	else 4 end
);

select @n_interviews := (select sum(n_invites) from _intermediate_projections);

update _intermediate_projections
	set n_invites = @n_interviews
	where predicted_outcome = "All";
	
drop table if exists _current_projections;
create temporary table _current_projections as	
select predicted_outcome
	, round(n_invites/total, 3) as "% applicants invited"
	, n_screenings as "Number of faculty screenings"
	, n_invites as "Number of interview invites"
	, round(invited, 3) as "Historical % invited"
	, round(accepted, 3) as "Historical % accepted"
	, round(matriculated, 3) as "Historical % matriculated"
	, hist_total as "Historical number of applicants"
	, round(accepted_if_invited, 3) as "Historical % accepted if invited"
	, round(matriculated_if_invited, 3) as "Historical % matriculated if invited"
	, if(predicted_outcome = "All", NULL, round(accepted_if_invited * n_invites)) as "Projected number accepted"
	, if(predicted_outcome = "All", NULL, round(matriculated_if_invited * n_invites)) as "Projected number matriculated"
from _intermediate_projections;

select @projected_accepted := (select sum(`Projected number accepted`) from _current_projections);
select @projected_matriculated := (select sum(`Projected number matriculated`) from _current_projections);

update _current_projections
	set `Projected number accepted` = @projected_accepted, 
		`Projected number matriculated` = @projected_matriculated 
	where predicted_outcome = "All";
