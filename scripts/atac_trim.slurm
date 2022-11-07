#!/bin/bash

### this script permit to remove adapters From atac-Seq Data by using trimmomatic module ###

#SBATCH --time=0:40:00                              ### execution time 
#SBATCH --nodes=1                                
#SBATCH --ntasks=1 
#SBATCH --mem=12G                                   ###  memory resource
#SBATCH --cpus-per-task=6                           ### Nb of threads we want to run on
#SBATCH -o Project_HPC/log/slurmjob-%A-%a            ### specify the path to log repo  
#SBATCH --job-name=trim_atac
#SBATCH --partition=short
#SBATCH --array=0-5                                 ###Job array submission that will permit to launch 6 jobs in parallel 

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

echo 'Quality control and trimming'

# Handling errors
#set -x # debug mode on
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation
#set -o verbose
#set -euo pipefail

IFS=$'\n\t'

#Set up whatever package we need to run with
module purge                                                       ### to ensure that there is no gcc(compiler) utilized 
module load gcc/8.1.0 java/oracle-1.7.0_79 trimmomatic/0.38        ### load compiler , java , trimmomatic


echo "Set up directories ..." >&2
#Set up the temporary directory
SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"                

OUTPUT="$HOME"/Project_HPC/results/trim                                   ## create an output repo
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"
cd "$SCRATCHDIR"

#Set up data directory                  
DATA_DIR=/home/users/shared/data/atacseq/data/subset 
ADAP_DIR=/home/users/shared/data/atacseq/data/

#Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2                            # specify which node wil be used 

#Contruct tables for the 2 arrays
echo "Set up 2 arrays with forward and reverse fastq.gz sequence files..." >&2 
tab_fwd=($(ls "$DATA_DIR"/*_1.fastq.gz | sort -k9,9 ))                 #only forward sequences are listed in this first table              
echo "tab_fwd = " >&2
printf '%s\n' "${tab_fwd[@]}" >&2                                      #print the table: @:permit to retrieve all the element in the table

tab_rev=($(ls "$DATA_DIR"/*_2.fastq.gz | sort -k9,9))
echo "tab_rev = " >&2
printf '%s\n' "${tab_rev[@]}" >&2

echo "Run the trimming with trimmomamic tool..." >&2
#exception: precise the path to .jar of java , PE=paired end , nb of threads
#keep sequences that have 33 nuc min 
#retrieve adapt sequences  
java -jar /opt/apps/trimmomatic-0.38/trimmomatic-0.38.jar PE -threads ${SLURM_CPUS_ON_NODE} \
    -trimlog "$OUTPUT"/trim.log -summary "$OUTPUT"/stats \
    "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" "${tab_rev[$SLURM_ARRAY_TASK_ID]}" \
    $(basename "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_paired.fastq.gz \
    $(basename "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_unpaired.fastq.gz \
    $(basename "${tab_rev[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_paired.fastq.gz \
    $(basename "${tab_rev[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_unpaired.fastq.gz \
    ILLUMINACLIP:"$ADAP_DIR"/NexteraPE-PE.fa:2:30:10:2:keepBothReads \
    LEADING:3 \
    TRAILING:3 \
    SLIDINGWINDOW:4:15 \
    MINLEN:33

# Move results in one's directory
mv  "$SCRATCHDIR" "$OUTPUT"

echo "Stop job : "`date` >&2

unset IFS

