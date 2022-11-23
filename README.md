
## Objective of the Project 


One of the main objectives of this project was to identify DNA accessible regions during transcription.

 -To conduct this analysis an ATAC-seq(A Method for Assaying Chromatin Accessibility Genome-Wide) experiments was performed. 
 -To see the whole work you can read the original publication " David Gomez-Cabrero et al. 2019 https://doi.org/10.1038/s41597-019-0202-7). 

 -In this publication, an analysis was performed on a B3 murine cellular line. 
 -This cell line from the mouse model refer to the pre-B1 stage. After the nuclear translocation of the transcription factor Ikaros, 
  these cells grow to the pre-BII stage. During this stage, the B cells progenitor are subject to a growth arrest and a 
  differentiation.
 - The B3 cell line was transduced by a retroviral pathway with a vector coding for a fusion protein called 
Ikaros-REt2. 
 -This protein have the particularity to control nuclear levels of Ikaros after exposition to the Tamoxifen drug.
 -After this treatment, the cultures were collected at t=0h and t=24h.

## Experimental design

 -Cells collected for 0 and 24hours post-treatment with tamoxifen
 -3 biological replicates of ~50,000 cells
 -paired end sequencing using Illumina technology with Nextera-based sequencing primers => 12 files (6 forward and 6 reverse)
 -reference genome : Mus musculus

## Raw dataset:

SRR4785152    50k_0h_R1_1      0.6G    50k_0h_R1_2      0.6G <br>
SRR4785153    50k_0h_R2_1      0.5G    50k_0h_R2_2      0.6G <br>
SRR4785154    50k_0h_R3_1      0.6G    50k_0h_R3_2      0.6G <br>

SRR4785341    50k_24h_R1_1    0.5G    50k_24h_R1_2    0.5G   <br>
SRR4785342    50k_24h_R2_1    0.5G    50k_24h_R2_2    0.5G   <br>
SRR4785343    50k_24h_R3_1    0.5G    50k_24h_R3_2    0.5G   <br>




## Extract pre-developed scripts
-A set of scripts are copied from /home/users/teacher/atacseq/scripts/*.slurm  into home/users/studentXX/Project_HPC/scripts.
These scripts will be modified later in order to be adapted to our dataset.
-Subset of 4000 lines equivalent to 1000 sequences created from the original subset in order to be pushed into the git repository 
  using this command line : 
 parallel 'zcat {} | head -n 4000 | gzip > /home/users/student05/Project_HPC/data/test.{/.}.gz' ::: /home/users/shared/data/atacseq/data/subset/ss_50k*
   
## WORKFLOW:

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
       -atac_picard.slurm:this script permit to eliminate duplicates by using the picard tool and visualization using IGV
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
        -atac_deeptools.slurm : this script permit to to generate bed file in order to visualize genome coverage using UCSC  and to calculate fragments length
             #2.1 Genome coverage : using banCoverage function to genetae bigwig or bed file. this file is used on UCSC                  
             #2.2 Fragments length: using bamPEFragmentSize function to calculate fragments length
              input :"$HOME/Project_HPC/results/picard"
              output: "$HOME/Project_HPC/results/deeptools" : bed file to see genome coverage using bamCoverage 
                                                                a function that offers normalization by scaling factor
                                                        -hist_fragments_length.png : displaying  fragment length using an histogram
                                                        -table_fragment_length.tsv : displaying  fragment length using a table
             this script is launched from home using this command line : sbatch Project_HPC/scripts/atac_deeptools.slurm
           

## V. Identification of DNA accessible sites
        -atac_macs2.slurm : this script permit to identify DNA accessible sites using macs2 by using callpeak function
              -peaks =  regions of the genome where multiple reads align that are indicative of protein binding
              input: $HOME/Project_HPC/results/picard
              output: "$HOME"/Project_HPC/results/MACS2 : 
                         _peaks.narrowPeak: BED6+4 format file which contains the peak locations together with peak summit, pvalue and qvalue
                         _peaks.xls: a tabular file which contains information about called peaks. Additional information includes pileup and fold enrichment
                         _summits.bed: peak summits locations for every peak. To find the motifs at the binding sites, this file is recommended
                         _model.R: an R script which you can use to produce a PDF image about the model based on your data and cross-correlation plot
                            the R script could be executed but first , R should be installed using this command line R/3.5.1 and then the script could be launched by taping in the terminal : Rscript _model.R 
                            this will generate pdf file containig 2 plots. you can send it either to your local machine or uploaded on git to visualize it
                            -to better explore .xls and .narrowPeak files. you can use this website : https://research.stowers.org/cws/CompGenomics/Projects/macs.html 

              this script is launched from home using this command line : sbatch Project_HPC/scripts/atac_macs2.slurm



## VI. Identification of common and unique DNA accessible sites    
     -atac_bedtools.slum : once DNA accessible sites are determined at t=0h and t=24h for the different replicates .
                           -Common accessible regions are determied using intersect function of bedtools
                              => Peaks are found at t=0h and t=24h => No effect of tamoxifen 
                           -unique accissible regions of each condition are determined using the option -v of 
                             the function intersect of bedtools. 
                              => there is an effect of tamoxifen
                                   - If an accessible site is open at t=0h but closed at t=24h 
                                       => Tamoxifen closed these sites 
             
                      input: $HOME/Project_HPC/results/MACS2
                      output: "$HOME"/Project_HPC/results/bedtools                                                             
       	              this script is launched from home using this command line : sbatch Project_HPC/scripts/atac_bedtools.slurm
            

the hole workflow could be launched from home by tapping this command line : bash Project_HPC/scripts/atacseq_wf_example.sh
