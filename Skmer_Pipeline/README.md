# Skmer Pipeline

Our Skmer Pipeline utilises genomic information contained in short read genome skim data. It processes all samples to identify as follows:
- removes low quality and non-Calamoid sequences
- calculates genetic distance to all species in the reference database
- provides the genetically closest reference species to the sample
- checks if there was enough data and if the genetic distance is small enough for the results to be reliable

The [tutorial](Tutorial.md) goes step by step through the molecular identification workflow of a single sample using our Skmer Pipeline. 

For batch processing of multiple samples, we also provide a [slurm script](skmer_raw_to_query.sh). See instructions [here](Slurm_Instructions.md).
