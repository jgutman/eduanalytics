dir="${HOME}/Desktop/admissions_supp"
today=`date +%m_%d_%y`
source activate edu_analytics
python run_and_save_model.py --fit --pkldir ${dir}/pkls \
--dyaml all_features_non_urm.yaml all_features_urm.yaml \
--credpath ${dir}/db_credentials &> ${dir}/logs/log_${today}_fit_model.out
cat ${dir}/logs/log_${today}.out
