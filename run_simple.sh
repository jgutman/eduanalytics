#!/bin/sh
dir="${HOME}/Desktop/admissions_supp"
today=`date +%m_%d_%y`
cd $HOME/Desktop/admissions
source activate edu_analytics_simple
python run_and_save_model.py --predict --id 13 23 --pkldir ${dir}/pkls \
--dyaml all_features_non_urm.yaml all_features_urm.yaml \
--credpath ${dir}/db_credentials &> ${dir}/logs/log_${today}.out
cat ${dir}/logs/log_${today}.out
source deactivate
