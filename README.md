### Extract pre-developped scripts 
-A set of scripts are copied from /home/users/teacher/atacseq/scripts/*.slurm  into home/users/studentXX/atacseq/scripts.These scripts will be modified later in order to be adapted to our dataset.
-Subset of 4000 lines equivalent to 1000 sequences created from the original subset in order to be pushed into the git repository using this command line : 
zcat /home/users/shared/data/atacseq/data/subset/ss_50k_0h_R1_1.fastq.gz | head -n 4000 | gzip > /home/users/studentXX/atacseq/data/test.ss_50k_0h_R1_1.fastq.gz

## Workflow:
## I. Data preprocessing : 
to ensure this task 3 scripts are developed:
	   -atac_qc_init.slurm: this script permit to evaluate the quality of sequences before any treatment. it’s launched from home using this command line:sbatch Projet_HPC/scripts/atac_qc_init.slurm
     -atac_trim.slurm : this script permit to eliminate adapters using trommatic function. it’s launched from home using this command line : sbatch Projet_HPC/scripts/atac_trim.slurm
	   -atac_qc_post.slurm: this script permit to evaluate the quality of sequences after pre-processing.  it’s launched from home using this command line : sbatch Projet_HPC/scripts/atac_qc_post.slurm
 ## II. alignment to the reference genome in order to determine the number of reads mapped to the reference genome for each transcripts:
        atac_bowtie2.slurm: this script permet to align sequences to the reference genome.it’s launched from home using this command line : sbatch Projet_HPC/scripts/atac_bowtie2.slurm
