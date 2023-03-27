# General instructions for Skmer Pipeline

## 0) Overview
This Skmer Pipeline takes all the samples to identify and for each sample:
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
- Skmer 3.2.1
- seqtk 1.3-r106  


## 3) Run the identification pipeline for each sample
You can use the provided slurm script "skmer_raw_to_query.sh". Detailed explanations of the script are below. The script needs to be run for each sample. Needed preparations and changes to the script:
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
#SBATCH -J skmer_pipeline
#SBATCH -c 4
#SBATCH --mem=4GB
#SBATCH -o logs/skmer_pipeline_%A_%a.out
#SBATCH -e logs/skmer_pipeline_%A_%a.err
```

- `-D` Working directory
- `-p` Partition to run analyses on
- `-J` Job name
- `-c` Number of cores to use
- `--mem` Memory allocation
- `-o` and `-e` Logged outputs and error messages


### 3.1) Specify data
#### 3.1.1) Reference data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS HERE)
##### Sequencing adapters file
`adapters=./adapters/TruSeq3-PE-2.fa`

##### Kraken database directory for decontamination
`kraken_db_calamoideae=./db_calamoideae/`

##### Skmer genomic reference database directory for identification
`skmer_db=./skmer_reference_db_normalised_5e5reads/`


#### 3.1.2) Query data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS)
##### Raw data directory with paired read data
`data_directory=./data/`

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
conda activate
```

### 3.3) Get sequence and sample name for query
#### Sequence names
`name_sequence=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_sequences)`

#### Sample names
`name_sample=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_samples)`

#### Sample names, but in lower case (needed for Skmer output)
```
name_lower=`echo "$name_sample" | tr '[:upper:]' '[:lower:]'`
```

### 3.4) Pre-processing of query reads
#### 3.4.1) Adapter and quality trimming (CHANGE FILE ENDING IF NEEDED)
`trimmomatic PE -threads 4 -phred33 -basein "$data_directory"/"$name_sequence"_S1_L005_R1_001.fastq.gz -baseout "$name_sequence".fastq.gz ILLUMINACLIP:"$adapters":2:30:10:1:true LEADING:3 TRAILING:3 MAXINFO:40:0.8 MINLEN:36`
- Files are assumed to be ending with "_S1_L005_R1_001.fastq.gz" or "_S2_L005_R1_001.fastq.gz", otherwise please change

#### 3.4.2) Removal of non-calamoid reads
`kraken2 --db "$kraken_db" --gzip-compressed --threads 4 --paired --report "$name_sample"_kraken.txt --classified-out "$name_sequence"#P_decontaminated.fastq "$name_sequence"_1P.fastq.gz "$name_sequence"_2P.fastq.gz`

#### 3.4.3) Merging of reads
`bbmerge.sh in1="$name_sequence"_1P_decontaminated.fastq in2="$name_sequence"_2P_decontaminated.fastq out="$name_sample"_merged.fastq mix=t`

#### 3.4.4) Normalisation of reads
`seqtk sample -2 -s100 "$name_sample"_merged.fastq 5e5 > "$name_sample".fastq`
- Normalise query by downsampling to 500,000 reads (same as reference)


### 3.5) Query sample against reference
#### 3.5.1) Calculate genetic distances between query and reference
`skmer query "$name_sample".fastq "$skmer_db" -p 4 -o dist`

#### 3.5.2) Rename file
`mv dist-"$name_lower".txt "$name_sample"_distances.txt`

#### 3.5.3) Summarise results
```
echo "sample_id" "sequence_id" "reads" "identification" "min_distance" > "$name_sample"_summary.txt
(echo "$name_sample" "$name_sequence"; (echo $(cat $name_sample.fastq | wc -l)/4|bc); (sed -n '2 p' "$name_sample"_distances.txt)) | tr "\n" " " >> "$name_sample"_summary.txt
```
- Query sample name
- Query sequence name
- Number of cleaned merged reads of query
- Identification (reference with smallest genomic distance to query) 
- Minimum genomic distance any reference sample (i.e. genomic distance to identification)

#### 3.5.4) Data check
`awk 'NR==1{print $0, "data_check"; next}; {data_check="FAIL"}; 100000<=$3 && 500000>$3 && 0.05>=$5 {data_check="WARN"}; 500000<=$3 && 0.05>=$5 {data_check="PASS"}; {print $0, data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt`
- `PASS` if reads >= 500,000 and min genomic distance <= 0.05
- `WARN` if reads between 100,000 and 500,000 and min genomic distance <= 0.05
- `FAIL` otherwise

#### 3.5.5) Overwrite summary file to include new info
`mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt`


### 3.6) Clean up intermediate files (OUT-COMMENT IF WANT TO KEEP)
`rm "$name_sequence"_{1,2}{U,P}.fastq.gz` 
- Remove trimmed reads

`rm "$name_sequence"_{1,2}P_decontaminated.fastq`
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
