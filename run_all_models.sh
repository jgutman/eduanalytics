tbl_model_data="aoa_admissions
aoa_admissions_inschool
residency_top_25_admissions
residency_top_25_admissions_inschool
step1_admissions
step1_admissions_inschool
step2_admissions
step2_admissions_inschool"

for tbl_name in $tbl_model_data
do
  python run_and_save_model.py --tbl $tbl_name
done