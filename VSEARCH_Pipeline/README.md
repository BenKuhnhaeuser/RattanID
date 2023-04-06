# VSEARCH Pipeline

Our VSEARCH Pipeline utilises genomic information contained in short read target capture data. It processes all samples to identify as follows:
- removes low quality and non-Calamoid sequences
- retrieves genes with high information content for identification
- conducts a search against the reference database for each retrieved gene
- generates a 'majority vote' consensus identification based on the individual gene identifications
- checks if there was enough data for the results to be reliable

The [tutorial](Tutorial.md) goes step by step through the molecular identification workflow of a single sample using our VSEARCH Pipeline. 

For batch processing of multiple samples, we also provide a [slurm script](vsearch_raw_to_query.sh). See instructions [here](Slurm_Instructions.md). 
