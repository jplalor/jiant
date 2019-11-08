#!/bin/bash
#
#SBATCH --output=test_%j.txt
#SBATCH --partition=titanx-long
#SBATCH --gres=gpu:1

source user_config.sh 
python main.py --config_file jiant/config/artificial_crowd.conf --overrides "run_name = run1" 

