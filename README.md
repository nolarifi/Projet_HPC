## Extract pre-developed scripts
-A set of scripts are copied from /home/users/teacher/atacseq/scripts/*.slurm  into home/users/studentXX/Project_HPC/scripts.
These scripts will be modified later in order to be adapted to our dataset.
-Subset of 4000 lines equivalent to 1000 sequences created from the original subset in order to be pushed into the git repository 
  using this command line : 
 parallel 'zcat {} | head -n 4000 | gzip > /home/users/student05/Project_HPC/data/test.{/.}.gz' ::: /home/users/shared/data/atacseq/data/subset/ss_50k*
   
 ## Workflow:
## I. data preprocessing :
      to ensure this task 3 scripts are developed:
          -atac_qc_init.slurm: this script permit to evaluate the quality of sequences before any treatment. 
             it’s launched from home using this command line:sbatch Project_HPC/scripts/atac_qc_init.slurm
          -atac_trim.slurm : this script permit to eliminate adapters using trommatic function. 
             it’s launched from home using this command line : sbatch Project_HPC/scripts/atac_trim.slurm
  	  -atac_qc_post.slurm: this script permit to evaluate the quality of sequences after pre-processing. 
             it’s launched from home using this command line : sbatch Project_HPC/scripts/atac_qc_post.slurm
## II. alignment
      # 1.Alignment to reference genome        
        - atac_bowtie2.slurm: this script permit to align sequences to the reference genome.
            it’s launched from home using this command line : sbatch Project_HPC/scripts/atac_bowtie2.slurm
      # 2. Eliminate duplicates
         -atac_picard.slurm : this script permit to eliminate duplicates . 
            it's launched from home using this command line : sbatch Project_HPC/scripts/atac_picard.slurm

## III. Duplicates elimination
       -atac_picard.slurm:this script permit to eliminate duplicates by using the picard tool.
           input: alignment file : $HOME/Project_HPC/results/bowtie2
           Output                : $HOME/Project_HPC/results/picards
          it’s launched from home using this command line : sbatch Project_HPC/scripts/atac_picard.slurm

## IV. Data exploration
       #1. evaluation of the correlation between samples
         -atac_deeptools-array.slurm: this script permit to to merge bam file in one file using multiBamSummary function in order to to see the correlation between samples using plotCorrelation function
           input:  $HOME/Project_HPC/results/picard" : BAM files trimmed mapped sorted and with no duplicates
           output: $HOME"/Project_HPC/results/deeptools : array.npz :file containing merged BAM files
                                                          heatmap_SpearmanCorr.png: heatmap based on spearman correlation ( taking in account other samples )
                                                          SpearmanCorr.tab: SpearmanCorr.tab : table containing the results on spearman correlation
           it’s launched from home using this command line : sbatch Project_HPC/scripts/atac_deeptools-array.slurm
       
       #2.Visualization of genome coverage using IGV  and to calculate fragments length   
        -atac_deeptools.slurm : this script permit to to generate bigwig file in order to visualize genome coverage using IGV  and to calculate fragments length
             #2.1 Genome coverage : using banCoverage function to genetae bigwig or bed file. this file is used on IGV                  
             #2.2 Fragments length: using bamPEFragmentSize function to calculate fragments length
              input :"$HOME/Project_HPC/results/picard"
              output: "$HOME/Project_HPC/results/picard" : bed file to see genome coverage
                                                        hist_fragments_length.png : displaying  fragment length using an histogram
                                                        table_fragment_length.tsv : displaying  fragment length using a table
             it’s launched from home using this command line : sbatch Project_HPC/scripts/atac_deeptools.slurm
           

# V. Identification of DNA accessibility sites
        -atac_macs2.slurm : this script permit to identify DNA accessible sites using macs2
              input: $HOME/Project_HPC/results/picard
              output: "$HOME"/Project_HPC/results/MACS2 : bed file is generated containing .....
