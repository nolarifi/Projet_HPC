#!/bin/bash


### This script permit to generate bed file in order to visualize genome coverage using IGV  and to calculate fragments length ######## 
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=26G
#SBATCH --cpus-per-task=6   # Nb of threads we want to run on ${SLURM_CPUS_ON_NODE}
#SBATCH -o atacseq/log/slurmjob-%A-%a
#SBATCH --job-name=deepTools_atac
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

echo 'alignment analysis using deeptools'

# Handling errors
#set -x # debug mode on
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation
#set -o verbose
#set -euo pipefail
IFS=$'\n\t'

#Set up whatever package we need to run with
module purge
module load gcc/4.8.4 python/2.7.9 numpy/1.9.2 samtools/1.3 deepTools/3.1.2

echo "Set up directories ..." >&2
#Set up the temporary directory
SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"

OUTPUT="$HOME"/Project_HPC/results/deeptools
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"
cd "$SCRATCHDIR"

#Set up data directory
DATA_DIR="$HOME/Project_HPC/results/picard"

#Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Collect BAM files trimmed mapped sorted and with no duplicates to apply data analysis on " >&2
tab=($(find $DATA_DIR -type f -name "*_trim_mapped_sorted_q2_nodup.bam" -printf "%f %p \n" | sort -k1 | cut -d " " -f 2 ))

echo "tab = " >&2
printf '%s\n' "${tab[@]}" >&2

# Current filename
SHORTNAME=$(basename "${tab[$SLURM_ARRAY_TASK_ID]}" .bam )
echo "shortname = $SHORTNAME" >&2

echo "bamCoverage in order to see the coverage on the genome from each sample"
# Args -b <file> : Path to the input BAM file
# Args -o <file> : Path to where the output files should be writen
# Args --outFileFormat <character> : Choose whether the output will be in Bigwig or in bedgraph format

bamCoverage -b "${tab[$SLURM_ARRAY_TASK_ID]}" -o "$SHORTNAME".bed --outFileFormat bedgraph



echo "bamPEFragmentSize to compare the reads length according to the samples"
# Args -b <file> : Path to the input BAM files
# Args -o <file> : Path to where the output should be writen
# Args --samplesLabels <character> : Rename the samples by these labels

bamPEFragmentSize -b "${tab[@]}" --samplesLabel 0h_R1 0h_R2 0h_R3 24h_R1 24h_R2 24h_R3 \
          --table "$OUTPUT"/table_fragment_length.tsv -o "$OUTPUT"/hist_fragments_length.png


#Move results from scratch to user one's directory
mv  "$SCRATCHDIR" "$OUTPUT"

echo "Stop job : "`date` >&2
