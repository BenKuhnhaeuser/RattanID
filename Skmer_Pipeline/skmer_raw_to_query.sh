#!/bin/bash
#
#SBATCH -D ~/analyses/
#SBATCH -p short
#SBATCH -J skmer_pipeline
#SBATCH -c 4
#SBATCH --mem=4GB
#SBATCH -o logs/skmer_pipeline_%A_%a.out
#SBATCH -e logs/skmer_pipeline_%A_%a.err


#----------------
# Preparations
#----------------

# Reference data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS)
#----------------
# Sequencing adapters file for adapter removal
adapters=./adapters/TruSeq3-PE-2.fa

# Kraken database directory for removal of non-calamoid DNA  
kraken_db=./db_calamoideae/

# Skmer genomic reference database directory for identification  
skmer_db=./skmer_reference_db/


# Query data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS AND FILE ENDINGS)
#------------
# Raw data directory
data_directory=./data/

# File ending
## Common ending of forward reads, excluding sample name
file_ending="_S1_L005_R1_001.fastq.gz"

# Sequence name list
names_sequences=./namelist_sequences.txt

# Sample name list
names_samples=./namelist_samples.txt


# Enable software
#-----------------
source activate
conda activate


# Get sequence and sample name
#-----------
# Sequence name
name_sequence=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_sequences)

# Sample name
name_sample=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_samples)

# Sample name, but in lower case (needed for Skmer output)
name_lower=`echo "$name_sample" | tr '[:upper:]' '[:lower:]'`


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


# Merge
#-------
bbmerge.sh in1="$name_sample"_1P_decontaminated.fastq in2="$name_sample"_2P_decontaminated.fastq out="$name_sample"_merged.fastq mix=t


# Normalise
#-----------
# Normalise query by downsampling to 500,000 reads (same as reference)
seqtk sample -2 -s100 "$name_sample"_merged.fastq 5e5 > "$name_sample".fastq


# Create empty file if needed
#-----------------------------
if [[ ! -f "$name_sample".fastq ]]; then touch "$name_sample".fastq; fi

#----------------
Identification
#----------------

# Query
#-------
# Calculate genetic distances
skmer query "$name_sample".fastq "$skmer_db" -p 4 -o dist


# Rename
#--------
mv dist-"$name_lower".txt "$name_sample"_distances.txt


# Create empty file if needed
#-----------------------------
if [[ ! -f "$name_sample"_distances.txt ]]; then echo -e "\t$name_sample\nNA\tNA" > "$name_sample"_distances.txt; fi


# Summarise
#-----------

# Query sample name, cleaned merged reads of query, closest reference (identification), minimum genomic distance to closest reference
echo "sample_id" "sequence_id" "reads" "identification" "min_distance" > "$name_sample"_summary.txt
(echo "$name_sample" "$name_sequence"; (echo $(cat $name_sample.fastq | wc -l)/4|bc); (sed -n '2 p' "$name_sample"_distances.txt)) | tr "\n" " " >> "$name_sample"_summary.txt

# Data check
awk 'NR==1{print $0, "Data_check"; next}; {Data_check="FAIL"}; 100000<=$3 && 500000>$3 && 0.05>=$5 {Data_check="WARN"}; 500000<=$3 && 0.05>=$5 {Data_check="PASS"}; {print $0, Data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt

# Overwrite summary file to include new info
mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt


#-----------------------------
# Clean up intermediate files (DEACTIVATE COMMANDS USING '#' IF WANTING TO KEEP FILES)
#-----------------------------
# Remove trimmed reads
rm "$name_sample"_{1,2}{U,P}.fastq.gz

# Remove decontaminated reads
rm "$name_sample"_{1,2}P_decontaminated.fastq

# Remove merged reads
rm "$name_sample"_merged.fastq

# Remove normalised reads
rm "$name_sample".fastq

# Remove kraken report
rm "$name_sample"_kraken.txt

# Remove sample directories
rm -r "$name_sample"/
