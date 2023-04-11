# RattanID

Rattans are spiny climbing palms – their long, flexible stems are the source of rattan cane, which is harvested mainly from the wild. Rattan is the raw material on which a multibillion-dollar trade in cane furniture and other woven articles are built. Out of the ca. 500 species of rattan palms worldwide, numerous are reported to be utilised for cane products. The accurate identification of rattan species based on their morphology can be challenging because of the large number of species. In processed rattan articles, such as furniture, identification based on morphology is impossible because all required characters have been lost during the processing.

The RattanID molecular identification toolkit enables the identification of rattan palms and furniture using genomic information. This enables the identification even of highly processed rattan canes. It is based on a near-complete genomic reference database of the palm subfamily Calamoideae, which contains all rattan palms. Particular attention has been paid to include economically important rattan species that are likely to be found in furniture.

We have developed two approaches for the identification of rattans using genomic data:
- [Skmer pipeline](Skmer_Pipeline): Identification using genome skimming data
- [VSEARCH pipeline](VSEARCH_Pipeline): Identification using [Angiosperms353](https://doi.org/10.1093/sysbio/syy086) and [PhyloPalm](https://doi.org/10.3389/fpls.2019.00864) target capture data

## Reference data
Reference data needed to run these analyses can be found [here](https://doi.org/10.5281/zenodo.7733000) and includes:
- for both pipelines:
  * Sequencing adapters for adapter removal (for Illumina paired-end sequencing data)
  * Kraken database for removal of non-calamoid DNA
- for the Skmer pipeline:
  * Skmer reference database 
- for the VSEARCH pipeline:
  * Target file for retrieving genes
  * VSEARCH reference database

This project is based on a collaboration between the Royal Botanic Gardens Kew and IKEA. More infos can be found here: https://www.kew.org/science/our-science/projects/sustainable-rattan

## Software
The rattan identification
