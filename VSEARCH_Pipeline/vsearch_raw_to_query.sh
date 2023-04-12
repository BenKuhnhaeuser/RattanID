#!/bin/bash
#
#SBATCH -D ~/analyses/
#SBATCH -p long
#SBATCH -J vsearch_pipeline
#SBATCH -c 8
#SBATCH --mem=16GB
#SBATCH -o logs/vsearch_pipeline_%A_%a.out
#SBATCH -e logs/vsearch_pipeline_%A_%a.err


#----------------
# Preparations
#----------------

# Reference data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS)
#----------------
# Sequencing adapters file for adapter removal
adapters=./adapters/TruSeq3-PE-2.fa

# Kraken database directory for removal of non-calamoid DNA  
kraken_db=./db_calamoideae/

# Target file
targetfile=./vsearch_targetfile.fasta

# VSEARCH genomic reference database for identification
vsearch_db=./vsearch_reference_db/


# Query data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS AND FILE ENDINGS)
#------------
# Raw data directory
data_directory=./data/

# File ending
## Common ending of forward reads, excluding sample name
file_ending="_S1_L005_R1_001.fastq.gz"

# Sequence name list, one per line
names_sequences=./namelist_sequences.txt

# Sample name list
names_samples=./namelist_samples.txt


# Enable software
#-----------------
source activate
conda activate


# Get sequence and sample name
#-----------
# Sequence names
name_sequence=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_sequences)

# Sample names
name_sample=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_samples)


#----------------
Pre-processing
#----------------

# Trim
#------
# Adapter and quality trimming
trimmomatic PE -threads 4 -phred33 -basein "$data_directory"/"$name_sequence""$file_ending" -baseout "$name_sample".fastq.gz ILLUMINACLIP:"$adapters":2:30:10:1:true LEADING:3 TRAILING:3 MAXINFO:40:0.8 MINLEN:36

# Decontaminate
#---------------
kraken2 --db "$kraken_db" --gzip-compressed --threads 4 --paired --report "$name_sample"_kraken.txt --classified-out "$name_sample"#P_decontaminated.fastq "$name_sample"_1P.fastq.gz "$name_sample"_2P.fastq.gz

# Get genes
#-----------
# Assemble
hybpiper assemble --readfiles "$name_sample"_{1,2}P_decontaminated.fastq --targetfile_aa "$targetfile" --cov_cutoff 3 --prefix "$name_sample" --timeout_assemble 600 --timeout_exonerate_contigs 600 --cpu 8

# Retrieve
hybpiper retrieve_sequences dna --targetfile_aa "$targetfile" --single_sample_name "$name_sample"

# Save genes into separate files
#--------------------------------
# Make directory
mkdir -p "$name_sample"/genes

# Save genes into file
for gene in `cut -f 1 "$name_sample"/genes_with_seqs.txt`; do samtools faidx "$name_sample"/"$gene"/"$name_sample"/sequences/FNA/"$gene".FNA "$name_sample" > "$name_sample"/genes/"$gene".FNA; done


#----------------
Identification
#----------------

# Query
#-------
# Make directory
mkdir -p "$name_sample"/queries

# Query reference
for gene in `cut -f 1 "$name_sample"/genes_with_seqs.txt`; do vsearch --db "$vsearch_db"/"$gene"_gene.fasta --usearch_global "$name_sample"/genes/"$gene".FNA --userfields query+target+id1+id2+ql+tl+alnlen+qcov+tcov+mism+opens+gaps+pctgaps --userout "$name_sample"/queries/vsearch_"$gene".tsv --id 0.5; done


# Summary stats
#---------------
# Concatenate individual results
cat "$name_sample"/queries/vsearch_*.tsv | cut -f 2 | cut -f 1,2 -d "_" | sort | uniq -c | sort -k1 -nr > "$name_sample"/queries/tmp.txt

# If resulting file is empty, write minimal output into file
if [[ ! -s "$name_sample"/queries/tmp.txt ]]; then echo -e "0\tNA" > "$name_sample"/queries/tmp.txt; fi

# Calculate percentages, unless file is empty (then output NAs)
awk -v name_sample=$name_sample 'FNR==NR{sum += $1; next}; sum>0 {print name_sample "\t" $2 "\t" $1 "\t" $1/sum*100}; sum==0 {print  name_sample "\t" "NA" "\t" "0" "\t" "NA"}' "$name_sample"/queries/tmp.txt "$name_sample"/queries/tmp.txt > "$name_sample"_vsearch.txt

# Add header row
sed -i '1i Query\tIdentification\tCount\tPercentage' "$name_sample"_vsearch.txt

# Retrieve top hit
head -2 "$name_sample"_vsearch.txt > "$name_sample"_summary.txt

# Data check
## PASS if top hit has at least 35 hits
## WARN if top hit has at least 2 but fewer than 35 hits
## FAIL if less than 2 genes retrieved
awk 'NR==1{print $0, "Data_check"; next}; $3<2 {Data_check="FAIL"}; $3>=2 && $3<35 {Data_check="WARN"}; $3>=35 {Data_check="PASS"}; {print $0, Data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt

# Overwrite summary file to include the data check information  
mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt


#-----------------------------
# Clean up intermediate files (DEACTIVATE COMMANDS USING `#` IF WANTING TO KEEP FILES)
#-----------------------------
# Remove trimmed reads
rm "$name_sample"_{1,2}{U,P}.fastq.gz

# Remove kraken report
rm "$name_sample"_kraken.txt

# Remove decontaminated reads
rm "$name_sample"_{1,2}P_decontaminated.fastq

# Remove assembled genes and vsearch queries
mkdir "$name_sample"_empty_dir_tmp
rsync -a --delete "$name_sample"_empty_dir_tmp/ "$name_sample"
rmdir "$name_sample"_empty_dir_tmp "$name_sample"

rm "$name_sample"_FNA.fasta
