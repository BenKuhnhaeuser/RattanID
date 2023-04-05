# Skmer Pipeline

## Overview
The [Skmer Pipeline](skmer_raw_to_query.sh) utilises genomic information contained in short read genome skim data. It processes all samples to identify as follows:
- remove low quality and non-Calamoid sequences
- calculate genetic distance to all species in the reference database
- provide the genetically closest reference species to the sample
- check if there was enough data and if the genetic distance is small enough for the results to be reliable

Check out the [tutorial](Tutorial.md) to test identification of a single sample using the Skmer Pipeline step by step.

## Preparations
### Required software
Installation using anaconda is recommended. Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- seqtk 1.3-r106  
- Skmer 3.2.1

### Skmer identification pipeline for each sample
You can use the provided slurm script [skmer_raw_to_query.sh](skmer_raw_to_query.sh). An overview of the computations performed by the script is given. The script needs to be run for each sample. Needed preparations and specifications to make the script functional:
- Provide sufficient computational resources: 4GB memory (required) and 4 cores (recommended)
- Create a directory called `logs` to which log files are written (otherwise the Slurm script will fail)
- Specify file and directory locations
- If you want to keep intermediate files, out-comment delete commands in end of script

### Specify reference data locations
Download these from Zenodo: https://doi.org/10.5281/zenodo.7733000
- Sequencing adapters file
- Kraken database directory for decontamination
- Skmer genomic reference database directory for identification

### Specify query data locations
- Directory containing raw data
- File endings of raw data files
  * Common ending of forward read, excluding sequence name. E.g., for the file `BKL006_S1_L005_R2_001.fastq.gz` the sequence name is `BKL006` and the file ending is `_S1_L005_R1_001.fastq.gz`

- Sequence name list
  * One name per line
  * Sequence name excluding common file ending. E.g., file `BKL006_S1_L005_R1_001.fastq.gz` would have sequence name `BKL006`
  * Example sequence name list:
    ```
    BKL006
    BKL054
    BKL182
    ```

- Sample name list
  * One name per line
  * In exactly same order as sequence names
  * No whitespace ` `, no special characters such as `/`, `?`, `*`, `,`.
  * Underscores `_` are ok.
  * Each name must be unique
  * Example sample name list:
    ```
    Calamus_sp_1_Baker_561_BKL006
    Calamus_sp_2_Henderson_3289_BKL054
    Calamus_sp_3_Kuhnhaeuser_71_BKL182
    ```

## Pre-process query reads
- Adapter and quality trimming
- Removal of non-calamoid reads
- Merging of reads
- Normalisation of reads (downsampling to 500,000 reads)

## Query sample against reference
- Calculate genetic distances between query and reference
- Summarise results
  * Query sample name
  * Query sequence name
  * Number of cleaned merged reads of query
  * Identification (reference with smallest genomic distance to query) 
  * Minimum genomic distance any reference sample (i.e. genomic distance to identification)
- Conduct data requirements check
  * `PASS` if reads >= 500,000 and min genomic distance <= 0.05
  * `WARN` if reads between 100,000 and 500,000 and min genomic distance <= 0.05
  * `FAIL` otherwise

## Clean up intermediate files
- Can out-comment remove commands if wanting to keep specific files

## Combine summary files
- Do this upon completion of the individual Skmer Pipeline runs
