dir="${HOME}/Desktop/admissions_supp"
today=`date +%m_%d_%y`
cd ~/Desktop/admissions
source activate edu_analytics
python run_and_save_model.py --predict --id 3 --pkldir ${dir}/pkls \
--credpath ${dir}/db_credentials &> ${dir}/logs/log_${today}.out
cat ${dir}/logs/log_${today}.out
