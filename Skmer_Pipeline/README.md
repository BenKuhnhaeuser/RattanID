# Skmer Pipeline

Our Skmer Pipeline utilises genomic information contained in short read genome skim data. It processes all samples to reveal their species identity as follows:
- removes low quality and non-Calamoid sequences using Trimmomatic and Kraken
- calculates the genetic distances between the sample and each species of the reference database using Skmer
- generates an identification by returning the reference species that is genetically closest to the sample
- checks if there was enough data and if the genetic distance is small enough for the identification to be reliable. There are three possible outcomes:
  * `PASS`: the identification is likely correct
  * `WARN`: the identification is less certain
  * `FAIL`: the identification is likely wrong

The [tutorial](Tutorial.md) goes step by step through the molecular identification workflow of a single sample using the pipeline.  

For batch processing of multiple samples, we also provide a [slurm script](skmer_raw_to_query.sh). See instructions [here](Slurm_Instructions.md).

### Reference data
Reference data needed to run the pipeline can be found [here](https://doi.org/10.5281/zenodo.7733000). You need the following data:
- `adapters`: Sequencing adapters for adapter removal (for Illumina paired-end sequencing data)
- `kraken_db_calamoideae`: Kraken database for removal of non-calamoid DNA
- `skmer_reference_db_normalised_5e5reads`: Skmer genomic reference database directory for identification  

Compressed files and directories (ending with `.tar.gz`) need to be uncompressed, e.g. using `tar -xzvf`.

### Software
This pipeline incorporates several software tools. Please credit them by citing the following papers:
- Sarmashghi, S., Bohmann, K., P. Gilbert, M.T., Bafna, V., Mirarab, S., 2019. Skmer: assembly-free and alignment-free sample identification using genome skims. Genome Biol. 20, 20. https://doi.org/10.1186/s13059-019-1632-4
- Bolger, A.M., Lohse, M., Usadel, B., 2014. Trimmomatic: a flexible trimmer for Illumina sequence data. Bioinformatics 30, 2114-2120. https://doi.org/10.1093/bioinformatics/btu170
- Wood, D.E., Lu, J., Langmead, B., 2019. Improved metagenomic analysis with Kraken 2. Genome Biol. 20, 257. https://doi.org/10.1186/s13059-019-1891-0
- Bushnell, B., Rood, J., Singer, E., 2017. BBMerge – accurate paired shotgun read merging via overlap. Plos One 12, e0185056. https://doi.org/10.1371/journal.pone.0185056
- Li, H., Seqtk. https://github.com/lh3/seqtk
