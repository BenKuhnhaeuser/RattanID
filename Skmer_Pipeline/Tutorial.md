# Skmer Pipeline Tutorial

This tutorial goes through the molecular identification workflow of a single sample using our Skmer Pipeline, step by step.  

For batch processing of multiple samples, follow the instructions [here](Slurm_Instructions.md).

## Preparations
### Computational resources
Recommended computational resource allocation: 4 cores, 4GB memory.

### Install required software
The script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- seqtk 1.3-r106  
- Skmer 3.2.1

Installation using anaconda is recommended.

### Download reference data 
Download the following data from Zenodo (https://doi.org/10.5281/zenodo.7733000):
- `adapters.tar.gz`: Sequencing adapters file for adapter removal (for Illumina paired-end sequencing data)
- `kraken_db_calamoideae.tar.gz`: Kraken database for removal of non-calamoid DNA
- `skmer_reference_db_normalised_5e5reads.tar.gz`: Skmer genomic reference database directory for identification  

Uncompress directories
- `tar -xzvf adapters.tar.gz`
- `tar -xzvf kraken_db_calamoideae.tar.gz`
- `tar -xzvf skmer_reference_db.tar.gz`

### Download query data 
If you don't have your own data yet but want to test the pipeline now, you can download example data from Zenodo (https://doi.org/10.5281/zenodo.7733000):
- Download `example_data_skim.tar`
- Uncompress using `tar -xvf example_data_skim.tar`

### Specify reference data as needed
- Sequencing adapters file for adapter removal    
  `adapters=./adapters/TruSeq3-PE-2.fa`
- Kraken database directory for removal of non-calamoid DNA  
  `kraken_db=./db_calamoideae/`
- Skmer genomic reference database directory for identification  
  `skmer_db=./skmer_reference_db/`

### Specify query data as needed
- Directory containing compressed paired end raw data files (`.fastq.gz`)  
  `data_directory=./data/`
- File ending of raw data files  
  `file_ending="_S1_L005_R1_001.fastq.gz"`  
  This should be the common ending of all the files containing forward reads, excluding the parts that are specific to each sample. E.g., for the file `BKL001_S1_L005_R2_001.fastq.gz` the sequence name is `BKL001` and the file ending is `_S1_L005_R1_001.fastq.gz`.
- Sequence name and corresponding sample name
  Note: The pipeline replaces the sequence name by the sample name. 
  * Sequence name  
    `name_sequence="BKL001"`
  * Sample name  
    `name_sample="Rattan_A"`  
    Naming conventions: No whitespace ` `, no special characters such as `/`, `?`, `*`, `,`. Underscores `_`, hyphens `-` and full stops `.` are ok. It is possible to provide identical sequence and sample names.
  * Sample name, but in lower case (needed for Skmer output). Based on `name_sample` input given above:  
    ```
    name_lower=`echo "$name_sample" | tr '[:upper:]' '[:lower:]'`
    ```



## Pre-process query reads
### Enable software installed with Anaconda
`conda activate`  

### Adapter and quality trimming
Removal of adapter sequences and trimming of low quality sequence parts  
`trimmomatic PE -threads 4 -phred33 -basein "$data_directory"/"$name_sequence""$file_ending" -baseout "$name_sample".fastq.gz ILLUMINACLIP:"$adapters":2:30:10:1:true LEADING:3 TRAILING:3 MAXINFO:40:0.8 MINLEN:36`

### Remove non-calamoid reads
`kraken2 --db "$kraken_db" --gzip-compressed --threads 4 --paired --report "$name_sample"_kraken.txt --classified-out "$name_sample"#P_decontaminated.fastq "$name_sample"_1P.fastq.gz "$name_sample"_2P.fastq.gz`

### Merge forward and reverse reads per sample
`bbmerge.sh in1="$name_sample"_1P_decontaminated.fastq in2="$name_sample"_2P_decontaminated.fastq out="$name_sample"_merged.fastq mix=t`

### Normalise reads by downsampling to 500,000 reads
`seqtk sample -2 -s100 "$name_sample"_merged.fastq 5e5 > "$name_sample".fastq`

## Query sample against reference
### Calculate genetic distances between query and reference samples
`skmer query "$name_sample".fastq "$skmer_db" -p 4 -o dist`

### Rename output from default lowercase output to original file name
`mv dist-"$name_lower".txt "$name_sample"_distances.txt`

### Summarise results in a table
#### Create file with table header to store results
`echo "sample_id" "sequence_id" "reads" "identification" "min_distance" > "$name_sample"_summary.txt`
- `sample_id`: Query sample name
- `sequence_id`: Query sequence name
- `reads`: Number of cleaned merged reads of query
- `identification`: Reference species with smallest genomic distance to query
- `min_distance`: Smallest genomic distances between query and reference (i.e. genomic distance between query and `identification`)

#### Add results to file
`(echo "$name_sample" "$name_sequence"; (echo $(cat $name_sample.fastq | wc -l)/4|bc); (sed -n '2 p' "$name_sample"_distances.txt)) | tr "\n" " " >> "$name_sample"_summary.txt`

#### Add data check
Check whether minimum data requirements were fulfilled for results to be reliable, add this as a new column `Data_check`  
`awk 'NR==1{print $0, "Data_check"; next}; {Data_check="FAIL"}; 100000<=$3 && 500000>$3 && 0.05>=$5 {Data_check="WARN"}; 500000<=$3 && 0.05>=$5 {Data_check="PASS"}; {print $0, Data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt`
- `PASS` if reads >= 500,000 and min genomic distance <= 0.05
- `WARN` if reads between 100,000 and 500,000 and min genomic distance <= 0.05
- `FAIL` otherwise

#### Overwrite summary file to include new info
`mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt`

## Examine results
- Genomic distances of query sample to all reference samples:  
  `cat "$name_sample"_distances.txt`
    * The smaller the distance, the more closely related is the query to the reference sample
    * The reference sample with the smallest distance is regarded as the main identification
- Main identification of query sample, including summary statistics:  
  `cat "$name_sample"_summary.txt`

## Clean up intermediate files
- Remove trimmed reads: `rm "$name_sample"_{1,2}{U,P}.fastq.gz`
- Remove decontaminated reads: `rm "$name_sample"_{1,2}P_decontaminated.fastq`
- Remove merged reads: `rm "$name_sample"_merged.fastq`
- Remove normalised reads: `rm "$name_sample".fastq`
- Remove kraken report: `rm "$name_sample"_kraken.txt`

## Combine results of multiple identifications
`cat *_summary.txt | awk '!seen[$0]++' | column -t > summary_all.txt`
- Do this upon completion of several individual pipeline runs
