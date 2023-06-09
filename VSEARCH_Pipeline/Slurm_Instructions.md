# VSEARCH Pipeline - processing of multiple samples using Slurm

We recommend to first familiarise yourself with running the pipeline for a single sample using the [tutorial](Tutorial.md).

For batch processing of multiple samples at a high performance computing facility, you can use the provided [slurm script](vsearch_raw_to_query.sh). Here, we provide instructions to prepare the software and data, to modify the script to fit your dataset, and to execute the script.

## Preparations
### Install required software using anaconda
The script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- HybPiper 2.1.1
- VSEARCH 2.21.1

### Download reference data 
Download the following data from Zenodo (https://doi.org/10.5281/zenodo.7733000):
- `adapters.tar.gz`: Sequencing adapters for adapter removal (for Illumina paired-end sequencing data)
- `kraken_db_calamoideae.tar.gz`: Kraken database for removal of non-calamoid DNA
- `vsearch_targetfile.fasta`: Target file for retrieving genes
- `vsearch_reference_db.tar.gz`: VSEARCH reference database  

Uncompress directories
- `tar -xzvf adapters.tar.gz`
- `tar -xzvf kraken_db_calamoideae.tar.gz`
- `tar -xzvf vsearch_reference_db.tar.gz`

### Download query data 
If you don't have your own data yet but want to test the pipeline now, you can download example data from Zenodo (https://doi.org/10.5281/zenodo.7733000):
- Download `example_data_targetcapture.tar`
- Uncompress using `tar -xvf example_data_targetcapture.tar`  

### Make lists of sequence names and corresponding sample names
- List of sequence names  
  * One name per line
  *  Sequence name excluding common file ending. E.g., file "BKL001_S1_L005_R1_001.fastq.gz" would have sequence name "BKL001"
  *   Example sequence name list: [namelist_sequences.txt](../example/namelists/namelist_sequences.txt)  

- List of sample names  
  * One name per line
  * **In exactly the same order as the sequence names**
  * No whitespace (" "), no special characters such as "/", "?", "*", ","
  * Underscores `_`, hyphens `-` and full stops `.` are ok.
  * Each name must be unique
  * Example sample name list: [namelist_samples.txt](../example/namelists/namelist_samples.txt)  

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


### Specify reference data as needed
- Sequencing adapters file  
  `adapters=./adapters/TruSeq3-PE-2.fa`

- Kraken database directory for decontamination  
  `kraken_db=./kraken_db_calamoideae/`

- Target file for retrieving targeted genes  
  `targetfile=./vsearch_targetfile.fasta`

- VSEARCH genomic reference database directory for identification  
  `vsearch_db=./vsearch_reference_db/`


### Specify query data as needed
- Raw data  
  `data_directory=./data/`

- File endings  
  `file_ending="_S1_L005_R1_001.fastq.gz"`  
  This should be the common ending of all the files containing forward reads, excluding the parts that are specific to each sample. E.g., for the file `BKL001_S1_L005_R2_001.fastq.gz` the sequence name is `BKL001` and the file ending is `_S1_L005_R1_001.fastq.gz`.

- List of sequence names  
  `names_sequences=./namelist_sequences.txt`

- List of sample names  
  `names_samples=./namelist_samples.txt`


## Submit Slurm job array
`sbatch --array=1-3%1 vsearch_raw_to_query.sh`
- This submits the first three samples that are specified in the name lists `1-3`, one at a time `%1`
- Adapt as needed. For example, `--array=4-100%5` would submit samples 4 to 100 of the name lists, processing 5 samples in parallel

## Combine summary files
`cat *_summary.txt | awk '!seen[$0]++' | column -t > summary_all.txt`
- Do this upon completion of the individual runs
