# VSEARCH Pipeline Tutorial

This tutorial goes through the molecular identification workflow of a single sample using our VSEARCH Pipeline, step by step.  

For batch processing of multiple samples, follow the instructions [here](Slurm_Instructions.md).

## Preparations
### Computational resources
Recommended computational resource allocation: 8 cores, 16GB memory.  

### Install required software
The script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- Kraken 2.1.2
- HybPiper 2.1.1
- VSEARCH 2.21.1

Installation using anaconda is recommended.

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

### Specify reference data as needed
- Sequencing adapters file for adapter removal   
  `adapters=./adapters/TruSeq3-PE-2.fa`
- Kraken database directory for removal of non-calamoid DNA  
  `kraken_db=./db_calamoideae/`
- Target file for retrieving targeted genes  
  `targetfile=./vsearch_targetfile.fasta`
- VSEARCH genomic reference database directory for identification  
  `vsearch_db=./vsearch_reference_db/`

### Specify query data as needed
- Directory containing compressed paired end raw data files (`.fastq.gz`)   
  `data_directory=./data/`
- File ending of raw data files  
  `file_ending="_S1_L005_R1_001.fastq.gz"`  
  This should be the common ending of all the files containing forward reads, excluding the parts that are specific to each sample. E.g., for the file `BKL001_S1_L005_R2_001.fastq.gz` the sequence name is `BKL001` and the file ending is `_S1_L005_R1_001.fastq.gz`.
- Sequence name and corresponding sample name
  * Sequence name  
    `name_sequence="BKL001"`
  * Sample name  
    `name_sample="Rattan_A"`  
    Naming conventions: No whitespace ` `, no special characters such as `/`, `?`, `*`, `,`. Underscores `_`, hyphens `-` and full stops `.` are ok. It is possible to provide identical sequence and sample names.

## Pre-process query reads
### Enable software installed with Anaconda
`conda activate`  

### Adapter and quality trimming
Removal of adapter sequences and trimming of low quality sequence parts  
`trimmomatic PE -threads 4 -phred33 -basein "$data_directory"/"$name_sequence""$file_ending" -baseout "$name_sample".fastq.gz ILLUMINACLIP:"$adapters":2:30:10:1:true LEADING:3 TRAILING:3 MAXINFO:40:0.8 MINLEN:36`

### Remove non-calamoid reads
`kraken2 --db "$kraken_db" --gzip-compressed --threads 4 --paired --report "$name_sample"_kraken.txt --classified-out "$name_sample"#P_decontaminated.fastq "$name_sample"_1P.fastq.gz "$name_sample"_2P.fastq.gz`

### Get genes
- Assemble genes from raw data  
  `hybpiper assemble --readfiles "$name_sample"_{1,2}P_decontaminated.fastq --targetfile_aa "$targetfile" --cov_cutoff 3 --prefix "$name_sample" --timeout_assemble 600 --timeout_exonerate_contigs 600 --cpu 8`

- Retrieve assembled genes  
  `hybpiper retrieve_sequences dna --targetfile_aa "$targetfile" --single_sample_name "$name_sample"`

- Make new directory  
  `mkdir -p "$name_sample"/genes`

- Save genes into the new directory  
  ```
  for gene in `cut -f 1 "$name_sample"/genes_with_seqs.txt`; do samtools faidx "$name_sample"/"$gene"/"$name_sample"/sequences/FNA/"$gene".FNA "$name_sample" > "$name_sample"/genes/"$gene".FNA; done
  ```

## Query sample against reference
### Search query against reference for each gene retrieved for sample 
- Make directory for results to be saved  
  `mkdir -p "$name_sample"/queries`

- Conduct search  
  ```
  for gene in `cut -f 1 "$name_sample"/genes_with_seqs.txt`; do vsearch --db "$vsearch_db"/"$gene"_gene.fasta --usearch_global "$name_sample"/genes/"$gene".FNA --userfields query+target+id1+id2+ql+tl+alnlen+qcov+tcov+mism+opens+gaps+pctgaps --userout "$name_sample"/queries/vsearch_"$gene".tsv --id 0.5; done
  ```

### Summarise query results in a table
- Combine results of individual gene searches into a table  
`cat "$name_sample"/queries/vsearch_*.tsv | cut -f 2 | cut -f 1,2 -d "_" | sort | uniq -c | sort -k1 -nr > "$name_sample"/queries/tmp.txt`  
  * This results in one line for as many different species identifications as there are for the sample 

- If resulting file is empty, add info that 0 genes were retrieved to file  
  `if [[ ! -s "$name_sample"/queries/tmp.txt ]]; then echo -e "0\tNA" > "$name_sample"/queries/tmp.txt; fi`

- Calculate percentages of genes supporting identification (unless file is empty, then output NAs)  
  `awk -v name_sample=$name_sample 'FNR==NR{sum += $1; next}; sum>0 {print name_sample "\t" $2 "\t" $1 "\t" $1/sum*100}; sum==0 {print  name_sample "\t" "NA" "\t" "0" "\t" "NA"}' "$name_sample"/queries/tmp.txt "$name_sample"/queries/tmp.txt > "$name_sample"_vsearch.txt`

- Add header row to the results table  
  `sed -i '1i Query\tIdentification\tCount\tPercentage' "$name_sample"_vsearch.txt`
  * `Query`: Query sample name
  * `Identification`: Tentative species identification for the sample, i.e. reference species found to be the most similar to the sample
  * `Count`: Number of genes supporting the species identification
  * `Percentage`: Percentage of the genes retrieved from the sample that support the species identification

### Retrieve main identification
- Retrieve main identification, which is at the top of the sorted table   
  `head -2 "$name_sample"_vsearch.txt > "$name_sample"_summary.txt`

- Add data check
Conduct check whether minimum data requirements were fulfilled for results to be reliable, add this as a new column `Data_check`  to summary file  
  `awk 'NR==1{print $0, "Data_check"; next}; $3<2 {Data_check="FAIL"}; $3>=2 && $3<35 {Data_check="WARN"}; $3>=35 {Data_check="PASS"}; {print $0, Data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt`
  * `PASS` if main identification has at least 35 hits
  * `WARN` if main identification has at least 2 but fewer than 35 hits
  * `FAIL` if less than 2 genes retrieved

- Overwrite summary file to include the data check information  
  `mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt`

## Examine results
- Complete results for the sample:  
  `cat "$name_sample"_vsearch.txt`
- Main identification of the sample, including summary statistics:  
  `cat "$name_sample"_summary.txt`

## Clean up intermediate files
- Remove trimmed reads: `rm "$name_sample"_{1,2}{U,P}.fastq.gz`
- Remove decontaminated reads: `rm "$name_sample"_{1,2}P_decontaminated.fastq`
- Remove kraken report: `rm "$name_sample"_kraken.txt`
- Remove assembled genes and vsearch queries:  
  `mkdir "$name_sample"_empty_dir_tmp`  
  `rsync -a --delete "$name_sample"_empty_dir_tmp/ "$name_sample"`  
  `rmdir "$name_sample"_empty_dir_tmp "$name_sample"`  
  `rm "$name_sample"_FNA.fasta`

## Combine results of multiple identifications
`cat *_summary.txt | awk '!seen[$0]++' | column -t > summary_all.txt`
- Do this upon completion of several individual pipeline runs
