# original view for vw$screen$send$predictions
# excludes predictions already sent to admissions (appears in application_algorithm_screening_score)
# excludes predictions already screened or currently in screening
select
    `o`.`aamc_id` AS `aamc_id`,
    `o`.`application_year` AS `application_year`,
    `o`.`algorithm_id` AS `algorithm_id`,
    `o`.`score` AS `score`
from
    (
        `edu_analytics`.`out$predictions$screening_current_cohort` `o` join `edu_analytics`.`vw$filtered$screen_eligible` `e` on
        (
            (
                (
                    `o`.`aamc_id` = `e`.`aamc_id`
                )
                and(
                    `o`.`application_year` = `e`.`application_year`
                )
            )
        )
    ) join `edu_analytics`.`algorithm` `a`
where
    (
        (
            `o`.`algorithm_id` = `a`.`id`
        )
        and(
            `a`.`is_production` = 1
        )
        and(
            `e`.`is_eligible` = 1
            or (
            	`e`.`is_postbacc_eligible` = 1
            )
        )
        and(
            not(
                (
                    `o`.`aamc_id`,
                    `o`.`application_year`
                ) in(
                    select
                        `s`.`aamc_id`,
                        `s`.`application_year`
                    from
                        `edu_analytics`.`application_algorithm_screening_score` `s`
                )
            )
        )
    )
    
select
    `i`.*,
    `e`.`is_post_back` AS `is_postbacc_eligible`,
    `e`.`is_eligible` AS `is_eligible`,
    (
        `i`.`interview_invite_date` is not null
    ) AS `is_invited_interview`,
    (
        `i`.`interview_complete_date` is not null
    ) AS `is_interviewed`,
    (
        `i`.`offer_date` is not null
    ) AS `is_offered_admission`,
    coalesce(
        (
            `i`.`application_waiver` > 0
        ),
        0
    ) AS `application_waiver_approved`,
    coalesce(
        (
            `i`.`ses` in(
                'EO1',
                'EO2'
            )
        ),
        0
    ) AS `ses_low`,
    `i`.`disadvantaged_ind` AS `self_id_disadvantaged`,
    `z`.`Median` AS `median_census_income`
from
    (
        (
            `edu_analytics`.`vwScreenApplicationInfo` `i` left join `edu_analytics`.`static_zipcode` `z` on
            (
                (
                    left(
                        `i`.`permanent_zipcode`,
                        5
                    )= `z`.`Zip`
                )
            )
        ) join `edu_analytics`.`vwScreenEligible` `e` on
        (
            (
                (
                    `i`.`aamc_id` = `e`.`aamc_id`
                )
                and(
                    `i`.`application_year` = `e`.`application_year`
                )
            )
        )
    )
where
    (
        (
            (
                `e`.`is_eligible` = 1 # is eligible for screening, URM or non-URM
            )
            or(
                `i`.`screening_complete_date` is not null # has already completed screening
            )
            or(
                `i`.`status` = 'SI' # currently assigned to or in process of screening
            )
            or(
                `e`.`is_post_back` = 1 # is eligible for screening as postbacc candidate
            )
        )
        and(
            `i`.`appl_type_desc` in(
                'Regular M.D.',
                'Combined Medical Degree/Graduate',
                'Combined  Medical Degree/Graduate'
            )
        )
        and(
            not(
                (
                    `i`.`status` regexp '^M[[:upper:]]{2}'
                )
            )
        )
        and(
            `i`.`app_submit_date` is not null
        )
        and(
            `i`.`appl_complete_date` is not null
        )
        and(
            `i`.`application_year` =(
                select
                    max( `edu_analytics`.`vwScreenApplicationInfo`.`application_year` )
                from
                    `edu_analytics`.`vwScreenApplicationInfo`
            )
        )
    )

update algorithm
set is_production = 1
where id = 3;

delete from algorithm where id > 3;
delete from `out$predictions$screening_current_cohort` where algorithm_id > 3;
delete from `out$predictions$screening_train_val` where algorithm_id > 3;

ALTER TABLE algorithm AUTO_INCREMENT = 13;

select aamc_id, application_year,
'fit' as fit_or_predict,
(case when `s`.`urm` = 'Y'
	then 'urm' 
	else 'not urm' end) as `urm`,
(case when `s`.`ses_low`
	or `s`.`application_waiver_approved`
	then 'is disadvantaged' 
	else 'not disadvantaged' end) as `disadvantaged`,
(case when `s`.`urm` = 'Y'
	and (`s`.`ses_low`
	or `s`.`application_waiver_approved`)
	then 'urm + disadvantaged'
	when `s`.`urm` = 'Y'
	then 'urm not disadvantaged'
	when (`s`.`ses_low`
	or `s`.`application_waiver_approved`)
	then 'disadvantaged not urm'
	else 'neither urm nor disadvantaged' end) as 'urm_disadvantaged'
from `vw$filtered$screened` s
union 
SELECT aamc_id, application_year,
'predict' as fit_or_predict,
(case when `e`.`urm` = 'Y'
	then 'urm' 
	else 'not urm' end) as `urm`,
(case when `e`.`ses_low`
	or `e`.`application_waiver_approved`
	then 'is disadvantaged' 
	else 'not disadvantaged' end) as `disadvantaged`,
(case when `e`.`urm` = 'Y'
	and (`e`.`ses_low`
	or `e`.`application_waiver_approved`)
	then 'urm + disadvantaged'
	when `e`.`urm` = 'Y'
	then 'urm not disadvantaged'
	when (`e`.`ses_low`
	or `e`.`application_waiver_approved`)
	then 'disadvantaged not urm'
	else 'neither urm nor disadvantaged' end) as 'urm_disadvantaged'
from `vw$filtered$screen_eligible` e

select count(*) from out$predictions$screening_current_cohort
where algorithm_id = 33;

select count(*) from out$predictions$screening_current_cohort
where algorithm_id = 43;

select count(*) from `vw$filtered$screen_eligible`
where urm = 'Y';

select count(*) from `vw$filtered$screen_eligible`
where urm is null;