# VSEARCH Pipeline

Our VSEARCH Pipeline utilises genomic information contained in short read target capture data. It processes all samples to identify as follows:
- removes low quality and non-Calamoid sequences
- retrieves genes with high information content for identification
- conducts a search against the reference database for each retrieved gene
- generates a 'majority vote' consensus identification based on the individual gene identifications
- checks if there was enough data for the results to be reliable

The [tutorial](Tutorial.md) goes step by step through the molecular identification workflow of a single sample using our VSEARCH Pipeline. 

For batch processing of multiple samples, we also provide a [slurm script](vsearch_raw_to_query.sh). See instructions [here](Slurm_Instructions.md).

### Reference data
Reference data needed to run the pipeline can be found [here](https://doi.org/10.5281/zenodo.7733000). You need the following data:
- `adapters`: Sequencing adapters for adapter removal (for Illumina paired-end sequencing data)
- `kraken_db_calamoideae`: Kraken database for removal of non-calamoid DNA
- `vsearch_targetfile.fasta`: Target file for retrieving genes
- `vsearch_reference_db`: VSEARCH reference database  

Compressed files and directories (ending with `.tar.gz`) need to be uncompressed, e.g. using `tar -xzvf`.

### Citations
This pipeline incorporates several software tools. Please credit them by citing the following papers:
- Rognes, T., Flouri, T., Nichols, B., Quince, C., Mahé, F., 2016. VSEARCH: a versatile open source tool for metagenomics. PeerJ 4, e2584. https://doi.org/10.7717/peerj.2584
- Bolger, A.M., Lohse, M., Usadel, B., 2014. Trimmomatic: a flexible trimmer for Illumina sequence data. Bioinformatics 30, 2114-2120. https://doi.org/10.1093/bioinformatics/btu170
- Wood, D.E., Lu, J., Langmead, B., 2019. Improved metagenomic analysis with Kraken 2. Genome Biol. 20, 257. https://doi.org/10.1186/s13059-019-1891-0
- Johnson, M.G., Gardner, E.M., Liu, Y., Medina, R., Goffinet, B., Shaw, A.J., Zerega, N.J.C., Wickett, N.J., 2016. HybPiper: extracting coding sequence and introns for phylogenetics from high-throughput sequencing reads using target enrichment. Appl. Plant Sci. 4, 1600016. https://doi.org/10.3732/apps.1600016
