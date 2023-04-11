# VSEARCH Pipeline Tutorial

This tutorial goes through the molecular identification workflow of a single sample using our VSEARCH Pipeline, step by step.  

For batch processing of multiple samples, follow the instructions [here](Slurm_Instructions.md).

## Computational resources
Recommended computational resource allocation: 8 cores, 16GB memory.

## Install required software
Script is verified to work with the indicated software versions.
- Trimmomatic 0.39
- Kraken 2.1.2
- HybPiper 2.1.1
- VSEARCH 2.21.1

Installation using anaconda is recommended. Enable software installed with anaconda using `conda activate`.

## Specify reference data (adapt path as needed)
- Specify sequencing adapters file  
  `adapters=./adapters/TruSeq3-PE-2.fa`
- Kraken database directory for decontamination  
  `kraken_db=./kraken_db_calamoideae/`
- Target file for retrieving targeted genes  
  `targetfile=./vsearch_targetfile.fasta`
- VSEARCH genomic reference database directory for identification  
  `vsearch_db=./vsearch_reference_db/`

Download these reference data from Zenodo: https://doi.org/10.5281/zenodo.7733000. Compressed files and directories (ending with `.tar.gz`) need to be uncompressed, e.g. using `tar -xzvf`.

## Specify query data (adapt path as needed)
- Directory containing paired end raw `.fastq.gz` data files  
  `data_directory=./data/`
- File ending of raw data files  
  `file_ending="_S1_L005_R1_001.fastq.gz"`
  * Common ending of forward read, excluding sequence name. E.g., for the file `BKL001_S1_L005_R2_001.fastq.gz` the sequence name is `BKL001` and the file ending is `_S1_L005_R1_001.fastq.gz`
- Sequence name and corresponding sample name
  * Sequence name  
    `name_sequence="BKL001"`
  * Sample name  
    `name_sample="Rattan_A_Kuhnhaeuser_BKL001"`

    Naming conventions: No whitespace ` `, no special characters such as `/`, `?`, `*`, `,`. Underscores `_` are ok.

## Pre-process query reads
### Adapter and quality trimming
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
### Conduct query against reference for each gene retrieved for sample 
- Make directory for query results to be saved  
  `mkdir -p "$name_sample"/queries`

- Conduct query  
  ```
  for gene in `cut -f 1 "$name_sample"/genes_with_seqs.txt`; do vsearch --db "$vsearch_db"/"$gene"_gene.fasta --usearch_global "$name_sample"/genes/"$gene".FNA --userfields query+target+id1+id2+ql+tl+alnlen+qcov+tcov+mism+opens+gaps+pctgaps --userout "$name_sample"/queries/vsearch_"$gene".tsv --id 0.5; done
  ```

## Summarise query results
- Combine results of individual gene searches  
`cat "$name_sample"/queries/vsearch_*.tsv | cut -f 2 | cut -f 1,2 -d "_" | sort | uniq -c | sort -k1 -nr > "$name_sample"/queries/tmp.txt`

- If resulting file is empty, add info that 0 genes were retrieved to file  
  `if [[ ! -s "$name_sample"/queries/tmp.txt ]]; then echo -e "0\tNA" > "$name_sample"/queries/tmp.txt; fi`

- Calculate percentages (unless file is empty, then output NAs)  
  `awk -v name_sample=$name_sample 'FNR==NR{sum += $1; next}; sum>0 {print name_sample "\t" $2 "\t" $1 "\t" $1/sum*100}; sum==0 {print  name_sample "\t" "NA" "\t" "0" "\t" "NA"}' "$name_sample"/queries/tmp.txt "$name_sample"/queries/tmp.txt > "$name_sample"_vsearch.txt`

- Add header row  
  `sed -i '1i Query\tIdentification\tCount\tPercentage' "$name_sample"_vsearch.txt`
  * `Query`: Query sample name
  * `Identification`: Species name of identification
  * `Count`: Number of genes supporting species identification
  * `Percentage`: Percentage of genes supporting species identification relative to total number of genes retrieved for sample

### Retrieve main identification
- Retrieve top hit  
  `head -2 "$name_sample"_vsearch.txt > "$name_sample"_summary.txt`

- Conduct check whether minimum data requirements were fulfilled for results to be reliable, add this as a new column `Data_check`  to summary file  
  `awk 'NR==1{print $0, "Data_check"; next}; $3<2 {Data_check="FAIL"}; $3>=2 && $3<35 {Data_check="WARN"}; $3>=35 {Data_check="PASS"}; {print $0, Data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt`
  * `PASS` if top hit has at least 35 hits
  * `WARN` if top hit has at least 2 but fewer than 35 hits
  * `FAIL` if no genes retrieved

- Overwrite summary file to include new info  
  `mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt`

## Examine results
- Complete results for the sample:  
  `cat "$name_sample"_vsearch.txt`
- Main identification of query sample, including summary statistics:  
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
