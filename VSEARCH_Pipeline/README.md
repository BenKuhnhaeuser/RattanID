
# VSEARCH Pipeline

## 0) Overview
This VSEARCH Pipeline takes all the samples to identify and for each sample:
-
-
-


## 1) Reference data
Download these from Zenodo: https://doi.org/10.5281/zenodo.7733000
- Sequencing adapters file
- Kraken database for decontamination
- 


## 2) Required software
Installation using anaconda is recommended. Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- 


## 3) Run the identification pipeline for each sample
You can use the provided slurm script "vsearch_raw_to_query.sh". Detailed explanations of the script are below. The script needs to be run for each sample. Needed preparations and changes to the script:
- Create a directory called `logs` to which log files are written (otherwise the Slurm script will fail)
- Specify file and directory locations in beginning of script
- Change file endings of raw reads at trimming step
- If you want to keep intermediate files, out-comment delete commands in end of script

