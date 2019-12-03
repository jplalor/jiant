#!/bin/bash
#
#SBATCH --partition=titanx-long
#SBATCH --gres=gpu:1 
#SBATCH --mem=80000

source activate jiant 
source user_config.sh 
python main.py --config_file jiant/config/artificial_crowd.conf --overrides "run_name = artcrowd-$p, pretrain_data_fraction = $p" 

