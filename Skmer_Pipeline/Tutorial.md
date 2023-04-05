# Skmer Pipeline Tutorial

## Overview
The [Skmer Pipeline](skmer_raw_to_query.sh) utilises genomic information contained in short read genome skim data. It processes all samples to identify as follows:
- remove low quality and non-Calamoid sequences
- calculate genetic distance to all species in the reference database
- provide the genetically closest reference species to the sample
- check if there was enough data and if the genetic distance is small enough for the results to be reliable

The tutorial given here shows the workflow for a single sample

## Install required software
Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- seqtk 1.3-r106  
- Skmer 3.2.1

Installation using anaconda is recommended. Enable software installed with anaconda using `conda activate`.


## Specify reference data locations (adapt path as needed)
- Specify sequencing adapters file: `adapters=./adapters/TruSeq3-PE-2.fa`
- Kraken database directory for decontamination: `kraken_db=./kraken_db_calamoideae/`
- Skmer genomic reference database directory for identification: `skmer_db=./skmer_reference_db_normalised_5e5reads/`

Download these reference data from Zenodo: https://doi.org/10.5281/zenodo.7733000

## Specify query data locations (adapt path as needed)
- Directory containing raw `.fastq.gz` data files with paired end reads: `data_directory=./data/`
- File endings of raw data files `file_ending="_S1_L005_R1_001.fastq.gz"`
  * Common ending of forward read, excluding sequence name. E.g., for the file `BKL006_S1_L005_R2_001.fastq.gz` the sequence name is `BKL006` and the file ending is `_S1_L005_R1_001.fastq.gz`

## Sequence name and corresponding sample name
- Sequence name: `name_sequence="BKL006"`
- Sample name: `name_sample="Calamus_sp_1_Baker_561_BKL006"`

Naming conventions: No whitespace (" "), no special characters such as "/", "?", "*", ",". Underscores ("_") are ok.
