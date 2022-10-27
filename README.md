-A set of scripts are copied from /home/users/teacher/atacseq/scripts/*.slurm  into home/users/studentXX/atacseq/scripts.These scripts will be modified later in order to be adapted to our dataset.
-Subset of 4000 lines equivalent to 1000 sequences created from the original subset in order to be pushed into the git repository using this command line : 
zcat /home/users/shared/data/atacseq/data/subset/ss_50k_0h_R1_1.fastq.gz | head -n 4000 | gzip > /home/users/studentXX/atacseq/data/test.ss_50k_0h_R1_1.fastq.gz

