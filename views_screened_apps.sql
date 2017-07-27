# all applications in application years 2013-2018
# excluding MD/PhD, postbacc linkage
# excluding incomplete applications
create or replace view filtered_apps_all as
select *,
	(interview_invite_date is not null) as is_invited_interview,
	(interview_complete_date is not null) as is_interviewed,
	(offer_date is not null) as is_offered_admission
from vwScreenApplicationInfo
where appl_type_desc in ('Regular M.D.', 'Combined Medical Degree/Graduate')
	and status not regexp '^M[[:upper:]]{2}'
	and app_submit_date is not null
	and appl_complete_date is not null
	and application_year >= 2013;

# the earliest screened regular application per applicant 
# in application years 2013-2017
create or replace view screened_first_apps as
select *
from filtered_apps_all
where screening_complete_date is not null
	and application_year <> 2018
	and (aamc_id, application_year) in
	(select aamc_id, min(application_year) as application_year
	from filtered_apps_all
	where screening_complete_date is not null
	group by aamc_id);

# total number of screened, invited for interview, interviewed, and accepted applications
# grouped by application year
select application_year, count(*) n_screened, 
	sum(is_invited_interview) n_invited,
	sum(is_interviewed) n_interviewed,
	sum(is_offered_admission) n_accepted
from vw$filtered$screened
group by application_year;

select *
from vwScreenRace
where (aamc_id, application_year) IN
	(select aamc_id, application_year
	from vwScreenApplicationInfo
	where urm = 'Y')
order by aamc_id, application_year

select *
from vwScreenEthnicity
where (aamc_id, application_year) IN
	(select aamc_id, application_year
	from vwScreenApplicationInfo
	where urm = 'Y')
order by aamc_id, application_year

# binary indicators for URM eligible races
# discuss with admissions whether additional categories need to be considered
create or replace view race_all as
select aamc_id, application_year, 
	sum(race = 'Black or African American') is_black_or_african_american,
	sum(race = 'African American') is_african_american,
	sum(race = 'African') is_african,
	sum(race = 'Afro-Caribbean') is_afro_caribbean,
	sum(race = 'Native Hawaiian or Other Pacific Islander') is_pacific_islander,
	sum(race = 'Native Hawaiian') is_native_hawaiian,
	sum(race = 'American Indian or Alaskan Native') is_american_indian
from vwScreenRace
where application_year >= 2013
group by aamc_id, application_year;

# binary indicators for any Hispanic/Latino ethnicity
# currently table does not contain ethnicity labels for
# self-identified "Not Spanish/Hispanic/Latino/Latina"
create or replace view ethnicity_all as
select aamc_id, application_year, 
	1 hispanic_latino_ethnicity
from vwScreenEthnicity
where application_year >= 2013
#	and ethnicity not like 'Not Spanish%'
group by aamc_id, application_year;

# URM if any one of a number of protected race categories,
# or if any type of Hispanic/Latino ethnicity
# or if self-identify as URM (AMCAS URM field)
create or replace view urm_status as
select f1.aamc_id, f1.application_year,
	coalesce(r.is_black_or_african_american, 0) is_black_or_african_american,
	coalesce(r.is_african_american, 0) is_african_american,
	coalesce(r.is_african, 0) is_african,
	coalesce(r.is_afro_caribbean, 0) is_afro_caribbean,
	coalesce(r.is_pacific_islander, 0) is_pacific_islander,
	coalesce(r.is_native_hawaiian, 0) is_native_hawaiian,
	coalesce(r.is_american_indian, 0) is_american_indian,
	coalesce(e.hispanic_latino_ethnicity, 0) hispanic_latino_ethnicity,
	coalesce(f1.urm = 'Y', 0) self_id_urm
from screened_first_apps f1
left join race_all r
on (r.aamc_id = f1.aamc_id 
	and r.application_year = f1.application_year)
left join ethnicity_all e
on (e.aamc_id = f1.aamc_id
	and e.application_year = f1.application_year);

# application waiver approved if 1 (approved and used) or 2 (approved but not used)
# ses low if EO1 or EO2 based on parental education and occupation type
create or replace view disadvantaged_status as
select aamc_id, application_year,
	coalesce(application_waiver > 0, 0) application_waiver_approved,
	coalesce(ses in ('EO1', 'EO2'), 0) ses_low,
	disadvantaged_ind self_id_disadvantaged
from screened_first_apps;

create or replace view urm_or_disadvantaged as
select u.aamc_id, u.application_year,
	(application_waiver_approved or ses_low) is_disadvantaged,
	(is_black_or_african_american
	or is_african_american
	or is_african
	or is_afro_caribbean
	or is_pacific_islander
	or is_native_hawaiian
	or is_american_indian
	or hispanic_latino_ethnicity
	or self_id_urm) is_urm
from disadvantaged_status d
left join urm_status u
on (u.aamc_id = d.aamc_id 
	and u.application_year = d.application_year);

# binary indicators if any listed experiences in 
# specified experience type description categories
# total hours available for application years 2014-2018 only where appropriate
select DISTINCT(exp_type_desc)
from vwScreenExperiences
where exp_type_desc like 'Physician Shadowing%';

select ex.aamc_id, ex.application_year, ex.exp_type, 
sum(ex.total_hours) as total_hours,
count(*) as n_experiences
from
(select aamc_id, application_year,
(case when e.application_year = 2013 then null 
	else e.total_hours end) as total_hours,
(case
	when e.exp_type_desc in ('Publications', 'Presentations/Posters') then 'publications'
	when e.exp_type_desc in ('Community Service/Volunteer - Medical/Clinical',
	'Paid Employment - Medical/Clinical') then 'medical'
	when e.exp_type_desc in ('Military Service', 'Military Services', 
	'Paid Employment - Military') then 'military'
	when e.exp_type_desc = 'Research/Lab' then 'research'
	when e.exp_type_desc = 'Intercollegiate Athletics' then 'athletics'
	when e.exp_type_desc = 'Leadership - not Listed Elsewhere' then 'leadership'
	when e.exp_type_desc = 'Physician Shadowing/Clinical Observation' then 'shadowing'
	else null end) as exp_type
from vwScreenExperiences e
where application_year > 2012) ex
where exp_type is not null
group by aamc_id, application_year, exp_type;

select aamc_id, application_year, org_name, total_hours 
from vwScreenExperiences
where aamc_id = 13795635 and application_year = 2017
order by total_hours desc;

select aamc_id, appl_year, org_name, exp_type_desc, 
(coalesce(first_total_hrs, 0) + coalesce(second_total_hrs, 0) + 
	coalesce(third_total_hrs, 0) + coalesce(fourth_total_hrs, 0)) total_hours
from `identified$raw$experiences`
where aamc_id = 13795635 and appl_year = 2017
order by total_hours desc;

select permanent_zipcode, Zip
from `vw$filtered$screened`
	
create or replace view experiences_all as
select aamc_id, application_year,
	(sum(exp_type_desc = 'Publications') > 0) exp_publications,
	(sum(exp_type_desc like 'Leadership%') > 0) exp_leadership,
	(sum(exp_type_desc in (
		'Community Service/Volunteer - Medical/Clinical',
		'Paid Employment - Medical/Clinical')) > 0) exp_medical,
	(sum(exp_type_desc = 'Physician Shadowing%') > 0) exp_shadowing,
	(sum(exp_type_desc in ('Military Service',
		'Military Services',
		'Paid Employment - Military')) > 0) exp_military,
	(sum(exp_type_desc = 'Research/Lab') > 0) exp_research,
	(sum(exp_type_desc = 'Intercollegiate Athletics') > 0) exp_athletics
from vwScreenExperiences
where application_year >= 2013
group by aamc_id, application_year;

select application_year, count(*)
from `vw$filtered$screened`
where screening_complete_date is not null
group by application_year;

select application_year, count(*)
from screened_first_apps
group by application_year;

select permanent_zipcode, Zip, median_census_income from `vw$filtered$screened`
where permanent_country <> 'USA'

select aca_status_desc, bcmp_ind, count(*) n
from vwScreenGrades
where application_year >= 2013
group by aca_status_desc, bcmp_ind
order by n desc;

select h.aamc_id, h.application_year, h.grade_cat, count(*) c
from 
(select aamc_id, application_year, 
CONCAT_WS('_', g.class_desc, g.grade, 'counts') grade_cat
from
(select aamc_id, application_year, 
(case class_desc when 'Physics' then 'phy'
when 'Biology' then 'bio'
when 'Math' then 'math'
when 'Chemistry' then 'chem'
else null end) class_desc,
(case when amcas_grade in ('A', 'A-') then 'A'
when amcas_grade in ('B', 'B+', 'B-', 'AB') then 'B'
when amcas_grade in ('C', 'C+', 'C-', 'BC') then 'C'
when amcas_grade in ('D', 'D+', 'D-', 'DE') then 'D'
when amcas_grade = 'F' then 'F'
else null end) grade
from vwScreenGrades
where application_year >= 2013
and bcmp_ind = 1
and aca_status_desc not in ('High School', 'Graduate')) g
where g.grade is not null) h
group by aamc_id, application_year, grade_cat;

SELECT disadvantaged_ind, self_id_disadvantaged
from vw$filtered$screened
where disadvantaged_ind <> self_id_disadvantaged

select aamc_id, application_year,
(case when screener_dec = 2 then 'invite'
when screener_dec in (3,4) then 'hold'
when screener_dec in (5,6) then 'reject'
end) outcome
from vw$filtered$screened
where screener_dec is not null;

select aamc_id, appl_year, program_type_desc, 
mod_school_desc, primary_undergrad_inst_ind,
attend_start_dt, attend_finish_dt 
from identified$raw$school 
where (aamc_id, appl_year) in 
(select aamc_id, appl_year from
(select aamc_id, appl_year,
sum(program_type_desc = 'Undergraduate') n_undergraduate,
sum(primary_undergrad_inst_ind) n_primary
from identified$raw$school
where appl_year >= 2013
group by aamc_id, appl_year) b
where n_primary <> 1)
order by aamc_id, appl_year;

select ap.aamc_id, ap.application_year,
	grad_year_und,
	left(attend_finish_dt, 4) grad_year
from vw$filtered$screened ap
left join
	(select * from identified$raw$school
	where primary_undergrad_inst_ind = 1
	and program_type_desc = 'Undergraduate') s
	on (s.aamc_id = ap.aamc_id and
	s.appl_year = ap.application_year)

create or replace view graduation_dates as
	select aamc_id, 
	appl_year application_year, 
	STR_TO_DATE(attend_finish_dt, '%Y-%m-%d') grad_year_undergrad
	from identified$raw$school
	where primary_undergrad_inst_ind = 1
	and appl_year >= 2013
	group by aamc_id, appl_year
	order by aamc_id, appl_year;
	
select aamc_id, application_year,
MONTHNAME(appl_complete_date) month_app_completed
from vw$filtered$screened;

select aamc_id, appl_year, attend_start_dt, attend_finish_dt, 
mod_school_desc, program_type_desc, primary_undergrad_inst_ind
from `identified$raw$school`
where (aamc_id, appl_year) in
	(select aamc_id, appl_year
	from `identified$raw$school`
	where summer_schl_ind <> 1
	and study_abroad_ind <> 1
	and degree_cd = 'ND'
	and program_type_desc = 'Undergraduate'
	and appl_year >= 2013)
and program_type_desc = 'Undergraduate'
order by aamc_id, appl_year

create or replace view `vw$cohorts$urm_or_disadvantaged` as
select aamc_id, application_year,
	(case when urm = 'Y' then 'urm' else 'not urm' end) urm,
	(case when ses_low or application_waiver_approved then 'is disadvantaged'
		else 'not disadvantaged' end) is_disadvantaged,
	(case when (urm = 'Y' or ses_low or application_waiver_approved) then 
		'urm or disadvantaged' else 'neither urm or disadvantaged' end) urm_disadvantaged
from `vw$filtered$screened`;

create or replace view `vw$outcomes$screening` as
select aamc_id, application_year,
(case when screener_dec = 2 then 'invite'
when screener_dec in (3,4) then 'hold'
when screener_dec in (5,6) then 'reject'
end) outcome
from `vw$filtered$screened`
where screener_dec is not null;
	

select * 
from vw$features$experiences a
left join vw$features$grades b
on (a.aamc_id = b.aamc_id and a.application_year = b.application_year)

select aamc_id, appl_year,
undergrad_ind, prog_type_desc,
school_name, degree_name
from vwScreenSchool
where appl_year >= 2013
order by appl_year, aamc_id

select * from vwScreenApplicationInfo 
where (aamc_id, application_year) in
(select aamc_id, application_year
from vwScreenEligible
where URM is null
and is_eligible = 1
and application_year = 2018);

select * 
from 
(select i.aamc_id, i.application_year, i.grad_year_und,
	EXTRACT(YEAR from g.grad_year_undergrad) grad_year_vw
from vwScreenApplicationInfo i
left JOIN
graduation_dates g
on (g.aamc_id = i.aamc_id 
and g.application_year = i.application_year)) bb
where bb.grad_year_und != bb.grad_year_vw

select degree_cd, degree_desc, count(*)
from vwScreenSchool
where undergrad_ind
group by degree_cd, degree_desc

select *
from vwScreenSchool
where PRIMARY_UNDERGRAD_INST_IND
and degree_cd not in ('BA', 'BS', 'BH')
and appl_year >= 2013
order by aamc_id, appl_year;

select aamc_id, application_year, 
	extract(year from min(degree_dt)) graduation_year_undergrad
from vwScreenSchool
where degree_cd in ('BA', 'BS', 'BH')
group by aamc_id, application_year;



select * from `vw$features$mcat`
group by aamc_id, application_year
having count(*) > 1

create or replace view graduation_dates as 
select s.aamc_id, s.appl_year as application_year, 
extract(year from min(s.degree_dt)) as graduation_year_undergrad
from vwScreenSchool s
where s.degree_cd in ('BA', 'BS', 'BH')
left JOIN
vwScreenApplicationInfo a
on (a.aamc_id = s.aamc_id and a.application_year = s.appl_year)
group by s.aamc_id, s.appl_year;
select count(*) from `vw$filtered$screen_eligible`

DELETE FROM edu_analytics.algorithm;
ALTER TABLE edu_analytics.algorithm AUTO_INCREMENT = 3

select max(parent_less_high_school), max(parent_high_school), max(parent_associate), max(parent_bachelor), max(parent_masters),
	max(parent_doctoral_non_medical), max(parent_medical)
from vw$features$parent

delete from out$predictions$screening_current_cohort;
delete from out$predictions$screening_train_val;

CREATE TABLE out$predictions$screening_current_cohort (
	aamc_id bigint(20), application_year int(4),
    predicted_hold double, predicted_invite double, predicted_reject DOUBLE,
    score double, algorithm_id bigint(20));

select age, count(*)
from `vw$features$app_info`
where application_year >= 2013
group by age
;

select d.aamc_id, d.application_year, d.is_disadvantaged, i.is_disadvantaged
from `vw$cohorts$urm_or_disadvantaged` d
left join 
`vw$features$app_info` i
on d.aamc_id = i.aamc_id and d.application_year = i.application_year
where d.is_disadvantaged = 'not disadvantaged' and i.is_disadvantaged is null


select distinct(month_app_completed)
from `vw$features$app_info`
where (aamc_id, application_year) in
(select aamc_id, application_year from `vw$filtered$screen_eligible`)

select column_name
from information_schema.columns
where table_name in ('vw$features$mcat', 'vw$features$grades', 'vw$features$experiences')
and column_name not in ('aamc_id', 'application_year');

select count(*) from vwScreenApplicationInfo where application_year = 2018 and appl_complete_date is not null and app_submit_date;

select distinct(edu_level_desc)
from vwScreenParent
where application_year >= 2013;

create or replace view `vw$filtered$screen_eligible` as
select *
from vwScreenApplicationInfo
where appl_type_desc in ('Regular M.D.',
                'Combined Medical Degree/Graduate')
and (not status REGEXP 'M[[:upper:]]{2}')
and app_submit_date is not NULL
and appl_complete_date is not NULL
and application_year = (
	select max(application_year) from vwScreenApplicationInfo)
and (aamc_id, application_year) in (
	select aamc_id, application_year
	from vwScreenEligible
	where urm is NULL
	and is_eligible = 1);
	
select * from 
current_year_screened
where (aamc_id, application_year, screener_dec) 
not in (select aamc_id, application_year, screener_dec
from vwScreenApplicationInfo
where (aamc_id, application_year) in 
(select aamc_id, application_year
from vw$filtered$screen_eligible)
and screener_dec is not null);

select i.* 
from vwScreenApplicationInfo i
left join
vwScreenEligible e
on i.aamc_id = e.aamc_id and i.application_year = e.application_year
where i.aamc_id =  13578091
and (e.is_eligible = 1 or i.screener_dec is not null)
and ;

select count(*)
from `vw$filtered$screened`
where appl_type_desc = 'Combined Medical Degree/Graduate'

select * 
from vwScreenEligible
where aamc_id =  13578091;
	
select aamc_id, application_year, screener_dec, screening_complete_date, status
from vwScreenApplicationInfo where application_year = 2018;

select *
from vwScreenEligible
where aamc_id = 13396290;

create or replace view current_year_screened as
select i.aamc_id, i.application_year, i.screener_dec, i.urm, e.is_eligible
from vwScreenApplicationInfo i
left JOIN
vwScreenEligible e
on i.aamc_id = e.aamc_id and i.application_year = e.application_year
where i.application_year = (select max(application_year) from vwScreenApplicationInfo)
and i.screener_dec is not null
and i.urm is null;
