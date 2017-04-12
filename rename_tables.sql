RENAME TABLE edu_analytics.`2013_all_applicants_orig` TO edu_analytics.`identified$raw$2013_all_applicants`;
RENAME TABLE edu_analytics.`2013_matriculated_report_orig` TO edu_analytics.`identified$raw$2013_matriculated_report`;
RENAME TABLE edu_analytics.`2013_tracking_report` TO edu_analytics.`identified$raw$2013_tracking_report`;
RENAME TABLE edu_analytics.`2014_all_applicants_orig` TO edu_analytics.`identified$raw$2014_all_applicants`;
RENAME TABLE edu_analytics.`2014_matriculated_report_orig` TO edu_analytics.`identified$raw$2014_matriculated_report`;
RENAME TABLE edu_analytics.`2014_tracking_report` TO edu_analytics.`identified$raw$2014_tracking_report`;
RENAME TABLE edu_analytics.`2015_all_applicants_orig` TO edu_analytics.`identified$raw$2015_all_applicants`;
RENAME TABLE edu_analytics.`2015_matriculated_report_orig` TO edu_analytics.`identified$raw$2015_matriculated_report`;
RENAME TABLE edu_analytics.`2015_tracking_report` TO edu_analytics.`identified$raw$2015_tracking_report`;
RENAME TABLE edu_analytics.`2016_all_applicants_orig` TO edu_analytics.`identified$raw$2016_all_applicants`;
RENAME TABLE edu_analytics.`2016_matriculated_report_orig` TO edu_analytics.`identified$raw$2016_matriculated_report`;
RENAME TABLE edu_analytics.`2016_tracking_report` TO edu_analytics.`identified$raw$2016_tracking_report`;

RENAME TABLE edu_analytics.`2013_all_applicants` TO edu_analytics.`hashed$raw$2013_all_applicants`;
RENAME TABLE edu_analytics.`2013_matriculated_report` TO edu_analytics.`hashed$raw$2013_matriculated_report`;
RENAME TABLE edu_analytics.`2014_all_applicants` TO edu_analytics.`hashed$raw$2014_all_applicants`;
RENAME TABLE edu_analytics.`2014_matriculated_report` TO edu_analytics.`hashed$raw$2014_matriculated_report`;
RENAME TABLE edu_analytics.`2015_all_applicants` TO edu_analytics.`hashed$raw$2015_all_applicants`;
RENAME TABLE edu_analytics.`2015_matriculated_report` TO edu_analytics.`hashed$raw$2015_matriculated_report`;
RENAME TABLE edu_analytics.`2016_all_applicants` TO edu_analytics.`hashed$raw$2016_all_applicants`;
RENAME TABLE edu_analytics.`2016_matriculated_report` TO edu_analytics.`hashed$raw$2016_matriculated_report`;

RENAME TABLE edu_analytics.ethnicity_raw_orig TO edu_analytics.`identified$raw$ethnicity`;
RENAME TABLE edu_analytics.ethnicity_raw TO edu_analytics.`hashed$raw$ethnicity`;
RENAME TABLE edu_analytics.ethnicity_orig TO edu_analytics.`identified$clean$ethnicity`;
RENAME TABLE edu_analytics.ethnicity TO edu_analytics.`hashed$clean$ethnicity`;

RENAME TABLE edu_analytics.gpa_scores_raw_orig TO edu_analytics.`identified$raw$gpa`;
RENAME TABLE edu_analytics.gpa_scores_raw TO edu_analytics.`hashed$raw$gpa`;
RENAME TABLE edu_analytics.gpa_orig TO edu_analytics.`identified$clean$gpa`;
RENAME TABLE edu_analytics.gpa TO edu_analytics.`hashed$clean$gpa`;

RENAME TABLE edu_analytics.mcat_raw_orig TO edu_analytics.`identified$raw$old_mcat`;
RENAME TABLE edu_analytics.mcat_raw TO edu_analytics.`hashed$raw$old_mcat`;
RENAME TABLE edu_analytics.old_mcat_scores_orig TO edu_analytics.`identified$clean$old_mcat`;
RENAME TABLE edu_analytics.old_mcat_scores TO edu_analytics.`hashed$clean$old_mcat`;

RENAME TABLE edu_analytics.new_mcat_raw_orig TO edu_analytics.`identified$raw$new_mcat`;
RENAME TABLE edu_analytics.new_mcat_raw TO edu_analytics.`hashed$raw$new_mcat`;
RENAME TABLE edu_analytics.new_mcat_scores_orig TO edu_analytics.`identified$clean$new_mcat`;
RENAME TABLE edu_analytics.new_mcat_scores TO edu_analytics.`hashed$clean$new_mcat`;

RENAME TABLE edu_analytics.mmi_scores_raw_orig TO edu_analytics.`identified$raw$mmi_scores`;
RENAME TABLE edu_analytics.`raw$mmi_scores` TO edu_analytics.`hashed$raw$mmi_scores`;
RENAME TABLE edu_analytics.mmi_scores_orig TO edu_analytics.`identified$clean$mmi_scores`;
RENAME TABLE edu_analytics.mmi_scores TO edu_analytics.`hashed$clean$mmi_scores`;

RENAME TABLE edu_analytics.parent_guardian_orig TO edu_analytics.`identified$raw$parent_guardian`;
RENAME TABLE edu_analytics.parent_guardian TO edu_analytics.`hashed$raw$parent_guardian`;

RENAME TABLE edu_analytics.race_raw_orig TO edu_analytics.`identified$raw$race`;
RENAME TABLE edu_analytics.race_raw TO edu_analytics.`hashed$raw$race`;
RENAME TABLE edu_analytics.race_orig TO edu_analytics.`identified$clean$race`;
RENAME TABLE edu_analytics.race TO edu_analytics.`hashed$clean$race`;

RENAME TABLE edu_analytics.school_raw_orig TO edu_analytics.`identified$raw$school`;
RENAME TABLE edu_analytics.school_raw TO edu_analytics.`hashed$raw$school`;
RENAME TABLE edu_analytics.schools_orig TO edu_analytics.`identified$clean$school`;
RENAME TABLE edu_analytics.schools TO edu_analytics.`hashed$clean$school`;

ALTER TABLE `identified$raw$mmi_scores` MODIFY start_time datetime;
ALTER TABLE `identified$raw$2013_all_applicants` MODIFY committee_date date;

ALTER TABLE `identified$raw$2013_all_applicants` MODIFY ses VARCHAR(255);
ALTER TABLE `hashed$raw$2013_all_applicants` MODIFY ses VARCHAR(255);

ALTER TABLE `hashed$raw$2013_all_applicants` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$2013_matriculated_report` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$2014_all_applicants` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$2014_matriculated_report` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$2015_all_applicants` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$2015_matriculated_report` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$2016_all_applicants` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$2016_matriculated_report` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$ethnicity` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$gpa` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$mmi_scores` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$new_mcat` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$old_mcat` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$parent_guardian` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$race` DROP COLUMN row_names;
ALTER TABLE `hashed$raw$school` DROP COLUMN row_names;

SELECT COUNT(*) FROM `deidentified$raw$gpa`;

select * from `deidentified$raw$old_mcat` limit 1;

ALTER TABLE `hashed$raw$old_mcat` CHANGE vr_low_p vr_low_percentile DOUBLE;
ALTER TABLE `hashed$raw$old_mcat` CHANGE vr_high_p vr_high_percentile DOUBLE;
ALTER TABLE `hashed$raw$old_mcat` CHANGE ps_low_p ps_low_percentile DOUBLE;
ALTER TABLE `hashed$raw$old_mcat` CHANGE ps_high_p ps_high_percentile DOUBLE;
ALTER TABLE `hashed$raw$old_mcat` CHANGE ws_low_p ws_low_percentile DOUBLE;
ALTER TABLE `hashed$raw$old_mcat` CHANGE ws_high_p ws_high_percentile DOUBLE;
ALTER TABLE `hashed$raw$old_mcat` CHANGE bs_low_p bs_low_percentile DOUBLE;
ALTER TABLE `hashed$raw$old_mcat` CHANGE bs_high_p bs_high_percentile DOUBLE;

ALTER TABLE `deidentified$clean$old_mcat` CHANGE vr_low_p vr_low_percentile DOUBLE;
ALTER TABLE `deidentified$clean$old_mcat` CHANGE vr_high_p vr_high_percentile DOUBLE;
ALTER TABLE `deidentified$clean$old_mcat` CHANGE ps_low_p ps_low_percentile DOUBLE;
ALTER TABLE `deidentified$clean$old_mcat` CHANGE ps_high_p ps_high_percentile DOUBLE;
ALTER TABLE `deidentified$clean$old_mcat` CHANGE ws_low_p ws_low_percentile DOUBLE;
ALTER TABLE `deidentified$clean$old_mcat` CHANGE ws_high_p ws_high_percentile DOUBLE;
ALTER TABLE `deidentified$clean$old_mcat` CHANGE bs_low_p bs_low_percentile DOUBLE;
ALTER TABLE `deidentified$clean$old_mcat` CHANGE bs_high_p bs_high_percentile DOUBLE;

select study_id, app_year,   from `hashed$raw$mmi_scores` where study_id = "a86d7afd4468bfc4fbbb79b8364c2175";

select study_id, app_year, interview_type, interviewer_type,
	attribute, faculty_id, rank, start_time  from `hashed$raw$mmi_scores`;

select count(*) from
(select * from `hashed$raw$parent_guardian` b where appl_year >= 2013 
group by b.study_id, b.name) a;

select count(*) from
(select * from `hashed$raw$parent_guardian` c where appl_year >= 2013 
group by c.study_id, c.occupation_desc, c.edu_level_desc, c.gender) d;

select * from
(select study_id, name, count(distinct(occupation_desc)) as n_occ
from `hashed$raw$parent_guardian` 
group by study_id, name) a
where a.n_occ > 1;

describe `identified$raw$experiences_2006_2012`;
describe `identified$raw$experiences_2013_2017`;

SELECT DISTINCT (appl_year) from `identified$raw$experiences`;

