#!/bin/bash

########## RGis script permit to eliminate duplicates #####
#SBATCH --time=0:50:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=15G
#SBATCH --cpus-per-task=6   # Nb of threads we want to run on ${SLURM_CPUS_ON_NODE}
#SBATCH -o Project_HPC/log/slurmjob-%A-%a
#SBATCH --job-name=picard_atac
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
__email__='nour.larifi@etu.uca.fr'

echo 'Remove PCR duplicates'

# Handling errors
#set -x # debug mode on
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation
#set -o verbose
#set -euo pipefail

IFS=$'\n\t'

#Set up whatever package we need to run with
module purge
module load gcc/8.1.0 java/oracle-1.11.0_11 picard/2.18.25 samtools/1.9


echo "Set up directories ..." >&2
#Set up the temporary directory
SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"

OUTPUT="$HOME"/Project_HPC/results/picard
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"
cd "$SCRATCHDIR"

#Set up data directory
DATA_DIR="$HOME/Project_HPC/results/bowtie2"

#Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Collect BAM files to clean ..." >&2
tab=($(find $DATA_DIR -type f -name "*_trim_mapped_sorted_q2.bam" -printf "%f %p \n" | sort -k1 | cut -d " " -f 2 ))

echo "tab = " >&2
printf '%s\n' "${tab[@]}" >&2

# Current filename
SHORTNAME=$(basename "${tab[$SLURM_ARRAY_TASK_ID]}" .bam )
echo "shortname = $SHORTNAME" >&2



echo "Run the cleaning with picard tool..." >&2
# MarkDuplicates tends to initiate garbage collection threads. 
# It's suggested to use option -XX:ParallelGCThreads=5 in the picard command and request 6 cpus for the command (1 for picard, 5 for garbage collection for example)
myGC=$((${SLURM_CPUS_ON_NODE} - 1))
java -XX:ParallelGCThreads="$myGC" -jar /opt/apps/picard-2.18.25/picard.jar MarkDuplicates \
    I="${tab[$SLURM_ARRAY_TASK_ID]}" \
    O="$SHORTNAME"_nodup.bam \
    M="$SHORTNAME"_dups.txt \
    REMOVE_DUPLICATES=true

echo "Indexing mapped sorted bam file ..." >&2

samtools index -b "$SHORTNAME"_nodup.bam

echo "List SCRATCHDIR: "
ls "$SCRATCHDIR" >&2

echo "Statistics on mapping ..." >&2
samtools idxstats "$SHORTNAME"_nodup.bam > $OUTPUT/"$SHORTNAME".log

# Move results in one's directory
mv  "$SCRATCHDIR" "$OUTPUT"

echo "Stop job : "`date` >&2

unset IFS
