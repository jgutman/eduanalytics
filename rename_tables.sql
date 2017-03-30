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