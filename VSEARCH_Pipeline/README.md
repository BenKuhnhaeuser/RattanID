# VSEARCH Pipeline

## 0) Overview
This VSEARCH Pipeline utilises genomic information contained in short read target capture data. It processes all samples to identify as follows:
- removes low quality and non-Calamoid sequences
- retrieves genes with high information content for identification
- conducts a search against the reference database for each retrieved gene
- generates a 'majority vote' consensus identification based on the individual gene identifications
- checks if there was enough data for the results to be reliable


## 1) Reference data
Download these from Zenodo: https://doi.org/10.5281/zenodo.7733000
- Sequencing adapters file
- Kraken database for decontamination
- Target file for retrieving genes
- VSEARCH genomic reference database for identification


## 2) Required software
Installation using anaconda is recommended. Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- HybPiper 2.1.1
- VSEARCH 2.21.1


## 3) Run the identification pipeline for each sample
You can use the provided slurm script "vsearch_raw_to_query.sh". Detailed explanations of the script are below. The script needs to be run for each sample. Needed preparations and changes to the script:
- Create a directory called `logs` to which log files are written (otherwise the Slurm script will fail)
- Specify file and directory locations in beginning of script
- Change file endings of raw reads at trimming step
- If you want to keep intermediate files, out-comment delete commands in end of script

### Script header
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


### 3.1) Specify data
#### 3.1.1) Reference data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS HERE)
##### Sequencing adapters file
`adapters=./adapters/TruSeq3-PE-2.fa`

##### Kraken database directory for decontamination
`kraken_db_calamoideae=./db_calamoideae/`

##### Target file for retrieving targeted genes
`targetfile=./vsearch_targetfile.fasta`

##### VSEARCH genomic reference database directory for identification
`vsearch_db=./vsearch_reference_db/`


#### 3.1.2) Query data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS)
##### Raw data
`data_directory=./data/`
- Directory with paired end read data

##### File ending
file_ending="_S1_L005_R1_001.fastq.gz"
- Common ending of forward read, excluding sequence name. E.g., for the file `BKL006_S1_L005_R2_001.fastq.gz` the sequence name is `BKL006` and the file ending is `_S1_L005_R1_001.fastq.gz`

##### Sequence name list
`names_sequences=./namelist_sequences.txt`
- One name per line
- Sequence name excluding common file ending. E.g., file "BKL006_S1_L005_R1_001.fastq.gz" would have sequence name "BKL006"
###### Example sequence name list
```
BKL006
BKL054
BKL182
```

##### Sample name list
`names_samples=./namelist_samples.txt`
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

### 3.2) Enable software
```
source activate
conda activate hybpiper
```

### 3.3) Get sequence and sample name for query
#### Sequence names
`name_sequence=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_sequences)`

#### Sample names
`name_sample=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_samples)`


### 3.4) Pre-processing of query reads
#### 3.4.1) Adapter and quality trimming (CHANGE FILE ENDING IF NEEDED)
`trimmomatic PE -threads 4 -phred33 -basein "$data_directory"/"$name_sequence""$file_ending" -baseout "$name_sample".fastq.gz ILLUMINACLIP:"$adapters":2:30:10:1:true LEADING:3 TRAILING:3 MAXINFO:40:0.8 MINLEN:36`
- Files are assumed to be ending with "_S1_L005_R1_001.fastq.gz" or "_S2_L005_R1_001.fastq.gz", otherwise please change

#### 3.4.2) Removal of non-calamoid reads
`kraken2 --db "$kraken_db" --gzip-compressed --threads 4 --paired --report "$name_sample"_kraken.txt --classified-out "$name_sample"#P_decontaminated.fastq "$name_sample"_1P.fastq.gz "$name_sample"_2P.fastq.gz`

#### 3.4.3) Get genes
##### Assemble
`hybpiper assemble --readfiles "$name_sample"_{1,2}P_decontaminated.fastq --targetfile_aa "$targetfile" --cov_cutoff 3 --prefix "$name_sample" --timeout_assemble 600 --timeout_exonerate_contigs 600 --cpu 8`

##### Retrieve
`hybpiper retrieve_sequences dna --targetfile_aa "$targetfile" --single_sample_name "$name_sample"`

##### Make new directory
`mkdir -p "$name_sample"/genes`

##### Retrieve genes and save them into the new directory
```
for gene in `cut -f 1 "$name_sample"/genes_with_seqs.txt`; do samtools faidx "$name_sample"/"$gene"/"$name_sample"/sequences/FNA/"$gene".FNA "$name_sample" > "$name_sample"/genes/"$gene".FNA; done
```


### 3.5) Query sample against reference
#### 3.5.1) Make directory for query results
`mkdir -p "$name_sample"/queries`

#### 3.5.2) Conduct query against reference for each gene retrieve for sample
`for gene in `cut -f 1 "$name_sample"/genes_with_seqs.txt`; do vsearch --db "$vsearch_db"/"$gene"_gene.fasta --usearch_global "$name_sample"/genes/"$gene".FNA --userfields query+target+id1+id2+ql+tl+alnlen+qcov+tcov+mism+opens+gaps+pctgaps --userout "$name_sample"/queries/vsearch_"$gene".tsv --id 0.5; done`
- Query against reference

#### 3.5.3) Summarise results
##### Concatenate individual results
`cat "$name_sample"/queries/vsearch_*.tsv | cut -f 2 | cut -f 1,2 -d "_" | sort | uniq -c | sort -k1 -nr > "$name_sample"/queries/tmp.txt`

##### If resulting file is empty, write minimal output into file
`if [[ ! -s "$name_sample"/queries/tmp.txt ]]; then echo -e "0\tNA" > "$name_sample"/queries/tmp.txt; fi`

##### Calculate percentages, unless file is empty (then output NAs)
`awk -v name_sample=$name_sample 'FNR==NR{sum += $1; next}; sum>0 {print name_sample "\t" $2 "\t" $1 "\t" $1/sum*100}; sum==0 {print  name_sample "\t" "NA" "\t" "0" "\t" "NA"}' "$name_sample"/queries/tmp.txt "$name_sample"/queries/tmp.txt > "$name_sample"_vsearch.txt`

##### Add header row
`sed -i '1i Query\tIdentification\tCount\tPercentage' "$name_sample"_vsearch.txt`
- Query sample name
- Query sequence name
- Count of genes supporting species identification
- Percentage of genes supporting species identification relative to total number of genes retrieved for sample

##### Retrieve top hit
`head -2 "$name_sample"_vsearch.txt > "$name_sample"_summary.txt`


#### 3.5.4) Data check
`awk 'NR==1{print $0, "Data_check"; next}; $3<2 {Data_check="FAIL"}; $3>=2 && $3<35 {Data_check="WARN"}; $3>=35 {Data_check="PASS"}; {print $0, Data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt`
- `PASS` if top hit has at least 35 hits
- `WARN` if top hit has at least 2 but fewer than 35 hits
- `FAIL` if no genes retrieved


#### 3.5.5) Overwrite summary file to include new info
`mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt`


### 3.6) Clean up intermediate files (OUT-COMMENT IF WANT TO KEEP)
`rm "$name_sample"_{1,2}{U,P}.fastq.gz` 
- Remove trimmed reads

`rm "$name_sample"_{1,2}P_decontaminated.fastq`
- Remove decontaminated reads

`rm "$name_sample"_merged.fastq`
- Remove merged reads

`rm "$name_sample".fastq`
- Remove normalised reads

`rm "$name_sample"_kraken.txt`
- Remove kraken report

## 4) Combine summary files
`cat *_summary.txt | awk '!seen[$0]++' | column -t > summary_all.txt`
- Do this upon completion of the individual runs
