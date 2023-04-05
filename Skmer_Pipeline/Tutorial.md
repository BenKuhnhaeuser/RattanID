# Skmer Pipeline Tutorial

## Overview
The [Skmer Pipeline](skmer_raw_to_query.sh) utilises genomic information contained in short read genome skim data. It processes all samples to identify as follows:
- remove low quality and non-Calamoid sequences
- calculate genetic distance to all species in the reference database
- provide the genetically closest reference species to the sample
- check if there was enough data and if the genetic distance is small enough for the results to be reliable

The tutorial given here shows the workflow for a single sample, step by step.

## Install required software
Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- bbmap 38.96
- Kraken 2.1.2
- seqtk 1.3-r106  
- Skmer 3.2.1

Installation using anaconda is recommended. Enable software installed with anaconda using `conda activate`.


## Specify reference data (adapt path as needed)
- Specify sequencing adapters file  
  `adapters=./adapters/TruSeq3-PE-2.fa`
- Kraken database directory for decontamination  
  `kraken_db=./kraken_db_calamoideae/`
- Skmer genomic reference database directory for identification  
  `skmer_db=./skmer_reference_db_normalised_5e5reads/`

Download these reference data from Zenodo: https://doi.org/10.5281/zenodo.7733000

## Specify query data (adapt path as needed)
- Directory containing paired end raw `.fastq.gz` data files  
  `data_directory=./data/`
- File ending of raw data files  
  `file_ending="_S1_L005_R1_001.fastq.gz"`
  * Common ending of forward read, excluding sequence name. E.g., for the file `BKL006_S1_L005_R2_001.fastq.gz` the sequence name is `BKL006` and the file ending is `_S1_L005_R1_001.fastq.gz`
- Sequence name and corresponding sample name
  * Sequence name  
    `name_sequence="BKL006"`
  * Sample name  
    `name_sample="Calamus_sp_1_Baker_561_BKL006"`
  * Sample name, but in lower case (needed for Skmer output). Based on `name_sample` input given above:  
    ```
    name_lower=`echo "$name_sample" | tr '[:upper:]' '[:lower:]'`
    ```

Naming conventions: No whitespace ` `, no special characters such as `/`, `?`, `*`, `,`. Underscores `_` are ok.

## Pre-process query reads
### Adapter and quality trimming
`trimmomatic PE -threads 4 -phred33 -basein "$data_directory"/"$name_sequence""$file_ending" -baseout "$name_sample".fastq.gz ILLUMINACLIP:"$adapters":2:30:10:1:true LEADING:3 TRAILING:3 MAXINFO:40:0.8 MINLEN:36`

### Remove non-calamoid reads
`kraken2 --db "$kraken_db" --gzip-compressed --threads 4 --paired --report "$name_sample"_kraken.txt --classified-out "$name_sample"#P_decontaminated.fastq "$name_sample"_1P.fastq.gz "$name_sample"_2P.fastq.gz`

### Merge forward and reverse reads per sample
`bbmerge.sh in1="$name_sample"_1P_decontaminated.fastq in2="$name_sample"_2P_decontaminated.fastq out="$name_sample"_merged.fastq mix=t`

### Normalise reads by downsampling to 500,000 reads
`seqtk sample -2 -s100 "$name_sample"_merged.fastq 5e5 > "$name_sample".fastq`

## Query sample against reference
### Calculate genetic distances between query and refereence samples
`skmer query "$name_sample".fastq "$skmer_db" -p 4 -o dist`

### Rename output from default lowercase output to original file name
`mv dist-"$name_lower".txt "$name_sample"_distances.txt`

### Summarise query results
#### Write header line
`echo "sample_id" "sequence_id" "reads" "identification" "min_distance" > "$name_sample"_summary.txt`
- `sample_id`: Query sample name
- `sequence_id`: Query sequence name
- `reads`: Number of cleaned merged reads of query
- `identification`: Reference species with smallest genomic distance to query
- `min_distance`: Smallest genomic distances between query and reference (i.e. genomic distance between query and `identification`)

#### Add query results to file
`(echo "$name_sample" "$name_sequence"; (echo $(cat $name_sample.fastq | wc -l)/4|bc); (sed -n '2 p' "$name_sample"_distances.txt)) | tr "\n" " " >> "$name_sample"_summary.txt`

#### Conduct check whether minimum data requirements were fulfilled for results to be reliable, add this as a new column `Data_check`
`awk 'NR==1{print $0, "Data_check"; next}; {Data_check="FAIL"}; 100000<=$3 && 500000>$3 && 0.05>=$5 {Data_check="WARN"}; 500000<=$3 && 0.05>=$5 {Data_check="PASS"}; {print $0, Data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt`
- `PASS` if reads >= 500,000 and min genomic distance <= 0.05
- `WARN` if reads between 100,000 and 500,000 and min genomic distance <= 0.05
- `FAIL` otherwise

#### Overwrite summary file to include new info
`mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt`

#### Examine results of Skmer identification pipeline:
`cat "$name_sample"_summary.txt`

## Clean up intermediate files
- Remove trimmed reads: `rm "$name_sample"_{1,2}{U,P}.fastq.gz`
- Remove decontaminated reads: `rm "$name_sample"_{1,2}P_decontaminated.fastq`
- Remove merged reads: `rm "$name_sample"_merged.fastq`
- Remove normalised reads: `rm "$name_sample".fastq`
- Remove kraken report: `rm "$name_sample"_kraken.txt`