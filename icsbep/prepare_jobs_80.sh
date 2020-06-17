#!/bin/bash

# Set number of particles, inactive batches, and total batches
PARTICLES=50000
INACTIVE=100
BATCHES=5100

# Check for argument -- if one exists, we assume it is a file with the list of
# directories to run. Otherwise, we simply search for directories containing a
# settings.xml file
if [[ $# -gt 0 ]]
then
    directories=$(cat $1)
else
    directories=$(find . -name settings.xml | sed 's/\/settings.xml//g' | sort)
fi

for dir in $directories
do
  echo Preparing ${dir}...

  # If qsub exists, create a pbs file to execute a job
  if [[ $(command -v qsub) ]]
  then
      cat <<EOF > $dir/openmc.pbs
#!/bin/sh

#PBS -N OpenMC_ICSBEP 
#PBS -l nodes=5:ppn=12
#PBS -l walltime=72:00:00
#PBS -j oe

cd \$PBS_O_WORKDIR
PATH=\$PBS_O_PATH

echo \$PBS_O_WORKDIR

module purge
module load openmc/gnu/develop
export OMP_NUM_THREADS=1
export OPENMC_CROSS_SECTIONS=/home/shared/nuclear-data/lib80x_hdf5/cross_sections.xml

python3 generate_materials.py 
mpiexec -rmk pbs openmc
EOF
  fi
  
  # Change number of batches and particles
  sed -i -e "s/\(<particles>\).*\(<\/particles>\)/\1${PARTICLES}\2/g" $dir/settings.xml
  sed -i -e "s/\(<inactive>\).*\(<\/inactive>\)/\1${INACTIVE}\2/g" $dir/settings.xml
  sed -i -e "s/\(<batches>\).*\(<\/batches>\)/\1${BATCHES}\2/g" $dir/settings.xml
done