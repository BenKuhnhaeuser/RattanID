# VSEARCH Pipeline - processing of multiple samples using Slurm

We recommend to first familiarise yourself with running the pipeline for a single sample using the [tutorial](Tutorial.md).

For batch processing of multiple samples at a high performance computing facility, you can use the provided [slurm script](vsearch_raw_to_query.sh). Here, we provide instructions on what preparations and modifications to running the script are needed, and how to execute it.

## Preparations
### Install required software using anaconda
Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- HybPiper 2.1.1
- VSEARCH 2.21.1

### Download reference data 
Download from Zenodo: https://doi.org/10.5281/zenodo.7733000
- Sequencing adapters file
- Kraken database for decontamination
- Target file for retrieving genes
- VSEARCH genomic reference database for identification

### Make lists of sequence names and corresponding sample names
- List of sequence names  
  * One name per line
  *  Sequence name excluding common file ending. E.g., file "BKL006_S1_L005_R1_001.fastq.gz" would have sequence name "BKL006"
  *   Example sequence name list: [namelist_sequences.txt](../example/namelist_sequences.txt)  
      ```
      BKL006
      BKL054
      BKL182
      ```

- List of sample names  
  * One name per line
  * **In exactly same order as sequence names**
  * No whitespace (" "), no special characters such as "/", "?", "*", ","
  * Underscores ("_") are ok
  * Each name must be unique
  * Example sample name list: [namelist_samples.txt](../example/namelist_samples.txt)  
    ```
    Calamus_sp_1_Baker_561_BKL006
    Calamus_sp_2_Henderson_3289_BKL054
    Calamus_sp_3_Kuhnhaeuser_71_BKL182
    ```

### Create directory for log files
`mkdir logs`
- the  `logs` directory needs to be in the working directory specified in the slurm script
- if not specified, Slurm job will fail


## Modifications to Slurm script
### Adjust script header as needed
```
#!/bin/bash
#
#SBATCH -D ~/analyses/
#SBATCH -p short
#SBATCH -J vsearch_pipeline
#SBATCH -c 8
#SBATCH --mem=16GB
#SBATCH -o logs/vsearch_pipeline_%A_%a.out
#SBATCH -e logs/vsearch_pipeline_%A_%a.err
```

- `-D` Working directory
- `-p` Partition to run analyses on
- `-J` Job name
- `-c` Number of cores to use. 8 cores are recommended.
- `--mem` Memory allocation. At least 16GB should be allocated.
- `-o` and `-e` Logged outputs and error messages

### Specify reference file locations
- Sequencing adapters file  
  `adapters=./adapters/TruSeq3-PE-2.fa`

- Kraken database directory for decontamination  
  `kraken_db=./kraken_db_calamoideae/`

- Target file for retrieving targeted genes  
  `targetfile=./vsearch_targetfile.fasta`

- VSEARCH genomic reference database directory for identification  
  `vsearch_db=./vsearch_reference_db/`


### Specify query file locations
- Raw data  
  `data_directory=./data/`

- File endings  
  `file_ending="_S1_L005_R1_001.fastq.gz"`
  * Common ending of forward read, excluding sequence name. E.g., for the file `BKL006_S1_L005_R2_001.fastq.gz` the sequence name is `BKL006` and the file ending is `_S1_L005_R1_001.fastq.gz`

- List of sequence names  
  `names_sequences=./namelist_sequences.txt`

- List of sample names  
  `names_samples=./namelist_samples.txt`


## Submit Slurm job array
`sbatch --array=1-3%1 vsearch_raw_to_query.sh`
- This submits the first three samples that are specified in the name lists, one at a time
- Adapt as needed

## Combine summary files
`cat *_summary.txt | awk '!seen[$0]++' | column -t > summary_all.txt`
- Do this upon completion of the individual runs
