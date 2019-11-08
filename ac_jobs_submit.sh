#!/bin/bash

for p in $(seq 0.02 0.02 1.0)
do 
sbatch --output=/mnt/nfs/work1/hongyu/lalor/data/jiant/logs/ac-$p.txt --export p=$p ac_job.slurm 
done 
