#!/bin/bash


########### This script permit to merge bam file in one file using multiBamSummary function in order to automatically clusterize samples 
#####                           based on the correlation coefficients 

#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=26G
#SBATCH --cpus-per-task=6   # Nb of threads we want to run on ${SLURM_CPUS_ON_NODE}
#SBATCH -o Project_HPC/log/slurmjob-%A-%a
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
__email__='nour.larifi@etu.uca.fr'

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

echo "multiBamSummary to combine the BAM files into one" >&2
# Args --bamfiles <file> : Path to the input BAM files to analyze
# Args -o <file> : Path to the output files

multiBamSummary bins --bamfiles "${tab[@]}" -o "$OUTPUT"/array.npz

#Set up the path to the combined bam file
comb_FILE="$OUTPUT"/array.npz

echo "plotCorrelation in order to see the correlation between samples" >&2
# Args -in <file>               : Path to the npz file
# Args --coreMehod <character>  : Select  between two different functions for the correlation computation: Pearson or Spearman.
# Args --removeOutliers         : Will remove outliers from the samples
# Args --whatToPLot <character> : Choose the format of the graph ( heatmap or scatterplot )
# Args -o <file>                : Path to the output file
# Args --outFileCorMatrix       : Save the distance between samples in a tab format

# Pearson correlation take into consideration correlation between samples

plotCorrelation -in "$comb_FILE" \
    --corMethod spearman \
    --removeOutliers \
    --whatToPlot heatmap --plotNumbers \
    -o "$OUTPUT"/heatmap_SpearmanCorr.png    


# pearson correlation doesn't take into consideration correlation between samples

plotCorrelation -in "$comb_FILE" \
    --corMethod pearson \
    --removeOutliers \
    --whatToPlot heatmap --plotNumbers \
    -o "$OUTPUT"/heatmap_PearsonCorr.png   


# Move results in one's directory
mv  "$SCRATCHDIR" "$OUTPUT"

echo "Stop job : "`date` >&2

unset IFS
