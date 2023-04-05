# Skmer Pipeline

## 0) Overview
This Skmer Pipeline utilises genomic information contained in short read genome skim ('shotgun') data. It processes all samples to identify as follows:
- removes low quality and non-Calamoid sequences
- calculates its genetic distance with all species in the reference database (based on sequence composition; give skmer ref)
- provides the genetically closest reference species to the sample
- checks if there was enough data and if the genetic distance is small enough for the results to be reliable


## 1) Reference data
Download these from Zenodo: https://doi.org/10.5281/zenodo.7733000
- Sequencing adapters file
- Kraken database for decontamination
- Skmer genomic reference database for identification


## 2) Required software
Installation using anaconda is recommended. Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- seqtk 1.3-r106  
- Skmer 3.2.1


## 3) Run the identification pipeline for each sample
You can use the provided slurm script "skmer_raw_to_query.sh". Detailed explanations of the script are below. The script needs to be run for each sample. Needed preparations and changes to the script:
- Computational resources: 4GB memory (required) and 4 cores (recommended)
- Create a directory called `logs` to which log files are written (otherwise the Slurm script will fail)
- Specify file and directory locations in beginning of script
- Change file endings of raw reads at trimming step
- If you want to keep intermediate files, out-comment delete commands in end of script


### 3.1) Specify data
#### 3.1.1) Reference data
##### Sequencing adapters file
##### Kraken database directory for decontamination
##### Skmer genomic reference database directory for identification

#### 3.1.2) Query data
##### Raw data directory
##### File endings of raw data files
- Common ending of forward read, excluding sequence name. E.g., for the file `BKL006_S1_L005_R2_001.fastq.gz` the sequence name is `BKL006` and the file ending is `_S1_L005_R1_001.fastq.gz`

##### Sequence name list
- One name per line
- Sequence name excluding common file ending. E.g., file `BKL006_S1_L005_R1_001.fastq.gz` would have sequence name `BKL006`
###### Example sequence name list
```
BKL006
BKL054
BKL182
```

##### Sample name list
- One name per line
- In exactly same order as sequence names
- No whitespace (" "), no special characters such as "/", "?", "*", ","
- Underscores ("_") are ok
- Each name must be unique
###### Example sample name list
```
Calamus_sp_1_Baker_561_BKL006
Calamus_sp_2_Henderson_3289_BKL054
Calamus_sp_3_Kuhnhaeuser_71_BKL182
```

### 3.2) Enable software using Anaconda

### 3.3) Get sequence and sample name for query
#### Sequence names

### 3.4) Pre-processing of query reads
#### 3.4.1) Adapter and quality trimming

#### 3.4.2) Removal of non-calamoid reads

#### 3.4.3) Merging of reads

#### 3.4.4) Normalisation of reads
- Normalise query by downsampling to 500,000 reads (same as reference)

### 3.5) Query sample against reference
#### 3.5.1) Calculate genetic distances between query and reference

#### 3.5.2) Rename file

#### 3.5.3) Summarise results
- Query sample name
- Query sequence name
- Number of cleaned merged reads of query
- Identification (reference with smallest genomic distance to query) 
- Minimum genomic distance any reference sample (i.e. genomic distance to identification)

#### 3.5.4) Data check
- `PASS` if reads >= 500,000 and min genomic distance <= 0.05
- `WARN` if reads between 100,000 and 500,000 and min genomic distance <= 0.05
- `FAIL` otherwise

#### 3.5.5) Overwrite summary file to include new info
`mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt`


### 3.6) Clean up intermediate files (Can out-comment if wanting to keep some files)
- Remove trimmed reads
- Remove decontaminated reads
- Remove merged reads
- Remove normalised reads
- Remove kraken report

## 4) Combine summary files
- Do this upon completion of the individual runs
