#!/bin/bash
#PBS -N proc
#PBS -q q30m32c
#PBS -m ae
#PBS -o zzz.$PBS_JOBID.out
#PBS -l nodes=1:ppn=32,walltime=30:00

cd $PBS_O_WORKDIR 
module load intel/18.0.2 mkl/18.0.2 impi/18.0.2
module load gcc/7.3.1
module load python/3.7.3-anaconda
source /share/apps/bin/conda-3.7.3.sh
conda activate rice_21

cd SetD/
cd Apr11/
python ../../eval_model.py SetD 0

cd ../May21/
python ../../eval_model.py SetD 1

cd ../Jun26/
python ../../eval_model.py SetD 3

cd ../Jul11/
python ../../eval_model.py SetD 4

cd ../Aug01/
python ../../eval_model.py SetD 5

cd ../Aug13/
python ../../eval_model.py SetD 6

cd ../Aug21/
python ../../eval_model.py SetD 7

cd ../Aug28/
python ../../eval_model.py SetD 8

cd ../Sep07/
python ../../eval_model.py SetD 9

cd ../Sep13/
python ../../eval_model.py SetD 10
