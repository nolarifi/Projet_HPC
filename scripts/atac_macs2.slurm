#!/bin/bash

##### this script permit the identification of DNA accessibility sites ########### 
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=26G
#SBATCH --cpus-per-task=6   # Nb of threads we want to run on ${SLURM_CPUS_ON_NODE}
#SBATCH -o atacseq/log/slurmjob-%A-%a
#SBATCH --job-name=macs2_atac
#SBATCH --partition=short
#SBATCH --array=0-5

# Program configuration
__author__='Nadia Goué'
__email__='nadia.goue@uca.fr'
__credits__=["Nadia Goué"]
__license__='GPL3'
__maintainer__='Nadia Goué'
__status__='Development'
__version__='0.0.1'
__developer__='Nour Larifi'

echo 'identification of DNA accessibility sites'


# Handling errors
#set -x # debug mode on
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation
#set -o verbose
#set -euo pipefail
IFS=$'\n\t'

#Set up whatever package we need to run with
module purge
module load gcc/4.8.4 python/2.7.9 numpy/1.9.2 cython/0.25.2 MACS2/2.1.2

echo "Set up directories ..." >&2
#Set up the temporary directory
SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"

OUTPUT="$HOME"/Project_HPC/results/MACS2
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"
cd "$SCRATCHDIR"

#Set up data directory
DATA_DIR="$HOME/Project_HPC/results/picard"

#Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Collect BAM files trimmed mapped sorted and with no duplicates  " >&2
tab=($(find $DATA_DIR -type f -name "*_trim_mapped_sorted_q2_nodup.bam" -printf "%f %p \n" | sort -k1 | cut -d " " -f 2 ))

echo "tab = " >&2
printf '%s\n' "${tab[@]}" >&2

# Current filename
SHORTNAME=$(basename "${tab[$SLURM_ARRAY_TASK_ID]}" .bam )
echo "shortname = $SHORTNAME" >&2

#Run the program
echo "Start job: "`date` >&2

# Run the program
# Args -t <filename>   : Input bam files
# Args  -f             : Format of output file
# Args   -n             : The prefix string for output files 
# Args -outdir         : MACS2 will save all output files into speficied folder for this option 

macs2 callpeak -t ${tab[$SLURM_ARRAY_TASK_ID]} -f BAM -n "$SHORTNAME" --outdir "$SCRATCHDIR"



#Move results in one's directory
mv  "$SCRATCHDIR" "$OUTPUT"

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

echo "Stop job: "`date` >&2
