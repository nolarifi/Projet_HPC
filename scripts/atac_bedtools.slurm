#!/bin/bash


##### this script permit the identification of DNA accessibility sites ########### 
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=30G
#SBATCH --cpus-per-task=1   # Nb of threads we want to run on
#SBATCH -o Project_HPC/log/slurmjob-%A-%a
#SBATCH --job-name=bedtools_atac
#SBATCH --partition=short
#SBATCH --array=0

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

echo 'Identification of unique and common DNA access sites with bedtools'

# Handling errors
#set -x # debug mode on
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation
#set -o verbose
#set -euo pipefail

IFS=$'\n\t'

#Set up whatever package we need to run with
module purge
module load gcc/4.8.4 bedtools/2.27.1

echo "Set up directories ..." >&2
#Set up the temporary directory
SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"

OUTPUT="$HOME"/Project_HPC/results/bedtools
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"
cd "$SCRATCHDIR"

echo "Set up two arrays with results of 0h for one and 24h for the other from MACS2" >&2

tab_0h=($(find "$HOME"/Project_HPC/results/MACS2 -type f -name "50k_0h_*.narrowPeak" -printf "%f %p \n" | sort -k1 | cut -d " " -f 2))
echo "tab_0h = " >&2
printf '%s\n' "${tab_0h[@]}" >&2

tab_24h=($(find "$HOME"/Project_HPC/results/MACS2 -type f -name "50k_24h_*.narrowPeak" -printf "%f %p \n" | sort -k1 | cut -d " " -f 2))
echo "tab_24h = " >&2
printf '%s\n' "${tab_24h[@]}" >&2

# Current filename
SHORTNAME=$(basename "${tab_0h[$SLURM_ARRAY_TASK_ID]}" .bed )
echo "shortname = $SHORTNAME" >&2

# Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2


echo "Concatenate all narrowPrak files for each condition "

cat "${tab_0h[@]}"  > "$SCRATCHDIR"/50k_0h_trim_mapped_sorted_q2_nodup_combined_peaks.narrowPeak
cat "${tab_24h[@]}"  > "$SCRATCHDIR"/50k_24h_trim_mapped_sorted_q2_nodup_combined_peaks.narrowPeak 

zero_hour="$SCRATCHDIR"/50k_0h_trim_mapped_sorted_q2_nodup_combined_peaks.narrowPeak
twenty_four_hour="$SCRATCHDIR"/50k_24h_trim_mapped_sorted_q2_nodup_combined_peaks.narrowPeak

echo "Sort peaks based on coordinates and merge them"
#Args -i   : path to the input files

sort -k1,1 -k2,2n "$zero_hour" | bedtools merge -i - > "$SCRATCHDIR"/50k_0h_trim_mapped_sorted_q2_nodup_merged_peaks.bed
sort -k1,1 -k2,2n "$twenty_four_hour" | bedtools merge -i - > "$SCRATCHDIR"/50k_24h_trim_mapped_sorted_q2_nodup_merged_peaks.bed

echo "Identification of common DNA access sites between 0h and 24h"
# Args -a and -b : Path to the input BAM files to analyze
# Args -v : Returns entries in -a that have no overlap in -b 

bedtools intersect -a 50k_0h_trim_mapped_sorted_q2_nodup_merged_peaks.bed \
             -b 50k_24h_trim_mapped_sorted_q2_nodup_merged_peaks.bed \
                > "$SCRATCHDIR"/50k_trim_mapped_sorted_q2_nodup_common.bed 

echo "Looking for differences in enrichment between 0h and 24h"

echo "Identification of unique DNA access sites at 0h"
bedtools intersect -v -a 50k_0h_trim_mapped_sorted_q2_nodup_merged_peaks.bed \
                -b 50k_24h_trim_mapped_sorted_q2_nodup_merged_peaks.bed  \
                       > "$SCRATCHDIR"/50k_trim_mapped_sorted_q2_nodup_0h_unique.bed

echo "Identification of unique DNA access sites at 24h"
bedtools intersect -v -a 50k_24h_trim_mapped_sorted_q2_nodup_merged_peaks.bed \
       	       	-b 50k_0h_trim_mapped_sorted_q2_nodup_merged_peaks.bed  \
       	       	       > "$SCRATCHDIR"/50k_trim_mapped_sorted_q2_nodup_24h_unique.bed



#Move results from scratch to user one's directory
mv  "$SCRATCHDIR" "$OUTPUT"

echo "Stop job : "`date` >&2













