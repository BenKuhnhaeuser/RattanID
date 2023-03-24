########################################################
### 24 March 2023                                    ###
### Benedikt Kuhnhäuser                              ###
### Skmer query pipeline                             ###
########################################################


#--------------------------------
# General instructions
#--------------------------------

# 1) Install software (installation using anaconda is recommended)
## Trimmomatic 0.39
## bbmap 38.96
## Kraken 2.1.2
## Skmer 3.2.1
## seqtk 1.3-r106

# 2) Run the script for each sample
## Create a directory called "logs" to which log files are written (otherwise the Slurm script will fail)
## Specify file locations in beginning of script
## If wanted to keep intermediate files, out-comment delete commands in end of script

# 3) Upon completion of individual runs, combine files using the following line of code
## cat *_summary.txt | awk '!seen[$0]++' | column -t > summary_all.txt


#--------------------------------------
# Slurm script "skmer_raw_to_query.sh" (RUN FOR EACH SAMPLE)
#--------------------------------------

#!/bin/bash
#
#SBATCH -D ~/analyses/
#SBATCH -p short
#SBATCH -J skmer_pipeline
#SBATCH -c 4
#SBATCH --mem=4GB
#SBATCH -o logs/skmer_pipeline_%A_%a.out
#SBATCH -e logs/skmer_pipeline_%A_%a.err


 Reference data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS)
#----------------
# Sequencing adapters file
adapters=./adapters/TruSeq3-PE-2.fa

# Kraken database directory for decontamination
kraken_db_calamoideae=./db_calamoideae/

# Skmer genomic reference database directory for identification
skmer_db=./skmer_reference_db_normalised_5e5reads/


# Query data (NEED TO SPECIFY FILE AND DIRECTORY LOCATIONS)
#------------
# Raw data directory
## Paired read data
## Assumed to be ending with "_S1_L005_R1_001.fastq.gz" or "_S2_L005_R1_001.fastq.gz", otherwise please change
data_directory=./data/

# Sequence name list
## One name per line
## Sequence name excluding common file ending. E.g., file "Sample_1_S1_L005_R1_001.fastq.gz" would have sequence name "Sample_1"
names_sequences=./namelist_sequences.txt

# Sample name list
## One name per line
## In exactly same order as sequence names
## No whitespace (" "), no special characters such as "/", "?", "*", ","
## Underscores ("_") are ok
## Each name must be unique
names_samples=./namelist_samples.txt


# Enable software
#-----------------
source activate
conda activate


# Namelists
#-----------
# Sequence names
name_sequence=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_sequences)

# Sample names
name_sample=$(awk -v lineid=$SLURM_ARRAY_TASK_ID 'NR==lineid{print;exit}' $names_samples)

# Sample names, but in lower case (needed for Skmer output)
name_lower=`echo "$name_sample" | tr '[:upper:]' '[:lower:]'`



# Trim
#------
# Adapter and quality trimming
trimmomatic PE -threads 4 -phred33 -basein "$data_directory"/"$name_sequence"_S1_L005_R1_001.fastq.gz -baseout "$name_sequence".fastq.gz ILLUMINACLIP:"$adapters":2:30:10:1:true LEADING:3 TRAILING:3 MAXINFO:40:0.8 MINLEN:36


# Decontaminate
#---------------
kraken2 --db "$kraken_db" --gzip-compressed --threads 4 --paired --report "$name_sample"_kraken.txt --classified-out "$name_sequence"#P_decontaminated.fastq "$name_sequence"_1P.fastq.gz "$name_sequence"_2P.fastq.gz


# Merge
#-------
bbmerge.sh in1="$name_sequence"_1P_decontaminated.fastq in2="$name_sequence"_2P_decontaminated.fastq out="$name_sample"_merged.fastq mix=t

# Normalise
#-----------
# Normalise query by downsampling to 500,000 reads (same as reference)
seqtk sample -2 -s100 "$name_sample"_merged.fastq 5e5 > "$name_sample".fastq


# Query
#-------
# Calculate genetic distances
skmer query "$name_sample".fastq "$skmer_db" -p 4 -o dist


# Rename
#--------
mv dist-"$name_lower".txt "$name_sample"_distances.txt


# Summarise
#-----------

# Query sample name, cleaned merged reads of query, closest reference (identification), minimum genomic distance to closest reference
echo "sample_id" "sequence_id" "reads" "identification" "min_distance" > "$name_sample"_summary.txt
(echo "$name_sample" "$name_sequence"; (echo $(cat $name_sample.fastq | wc -l)/4|bc); (sed -n '2 p' "$name_sample"_distances.txt)) | tr "\n" " " >> "$name_sample"_summary.txt

# Data check
## PASS if reads >= 500,000 and min genomic distance <= 0.05
## WARN if reads between 100,000 and 500,000 and min genomic distance <= 0.05
## FAIL otherwise
awk 'NR==1{print $0, "data_check"; next}; {data_check="FAIL"}; 100000<=$3 && 500000>$3 && 0.05>=$5 {data_check="WARN"}; 500000<=$3 && 0.05>=$5 {data_check="PASS"}; {print $0, data_check}' "$name_sample"_summary.txt  | awk '{print $1,$2,$3,$4,$5,$6}' > "$name_sample"_summary_tmp.txt

# Overwrite summary file to include new info
mv "$name_sample"_summary_tmp.txt "$name_sample"_summary.txt


# Clean up intermediate files (OUT-COMMENT IF WANT TO KEEP)
#----------
# Remove trimmed reads
rm "$name_sequence"_{1,2}{U,P}.fastq.gz

# Remove decontaminated reads
rm "$name_sequence"_{1,2}P_decontaminated.fastq

# Remove merged reads
rm "$name_sample"_merged.fastq

# Remove normalised reads
rm "$name_sample".fastq

# Remove kraken report
rm "$name_sample"_kraken.txt

