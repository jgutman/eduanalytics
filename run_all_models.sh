tbl_model_data="aoa_admissions
aoa_admissions_inschool
residency_noncompete_admit
residency_noncompete_admit_inschool
residency_top25_admissions
residency_top25_admissions_inschool
worry_score_admissions
screener_scores_admissions
"

source activate edu_analytics
for tbl_name in $tbl_model_data
do
  python run_and_save_model.py --tbl $tbl_name
done

cp pkls/*.pkl.z /Volumes/IIME/EDS/data/admissions/pkls/
echo 'pkls copied to shared drive'
