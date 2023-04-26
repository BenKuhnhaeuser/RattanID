# RattanID

![image](https://user-images.githubusercontent.com/56020162/231502405-1e07a2e3-d497-442d-985c-9d67ab1b3032.png)

Rattans are spiny climbing palms – their long, flexible stems are the source of rattan cane, which is harvested mainly from the wild. Rattan is the raw material on which a multibillion-dollar trade in cane furniture and other woven articles are built. Out of the ca. 500 species of rattan palms worldwide, numerous are reported to be utilised for cane products. The accurate identification of rattan species based on their morphology can be challenging because of the large number of species. In processed rattan articles, such as furniture, identification based on morphology is impossible because all required characters have been lost during the processing.

**The RattanID molecular identification toolkit enables the identification of rattan palms and furniture using genomic information.** It is based on a near-complete genomic reference database of the palm subfamily Calamoideae, which contains all rattan palms. Particular attention has been paid to include economically important rattan species that are likely to be found in furniture.
  
The workflow of rattan identification involves four steps:  

| Step | Description
| --- | ---
| 1. Sampling | Sample collection, labelling and drying
| 2. DNA extraction | Isolating genetic material from the sample
| 3. DNA sequencing | Digitising genetic information to make it accessible for bioinformatic analysis
| 4. Identification | Species identification by comparison of its genetic information to a reference database  
  
**Steps 1 to 3 (Sampling, DNA extraction and Sequencing)** are covered in the laboratory protocol provided on [Zenodo](https://doi.org/10.5281/zenodo.7733000). **Step 4 (Identification)** is covered in detail on this webpage and requires downloading the reference datasets deposited on [Zenodo](https://doi.org/10.5281/zenodo.7733000). We have developed two approaches for the identification of rattans:
- **Skmer pipeline: Identification using genome skimming data**  
Shallow sequencing across the entire genome. Sample-specific genetic profiles are then computed using the composition of short stretches of DNA, so-called k-mers. Identification is based on the comparison of the k-mer profiles of the sample with the reference database. The reference species with the smallest genomic distance is considered the main identification. This procedure is relatively simple but cannot provide a measure of confidence in the identification.
  * [Overview](Skmer_Pipeline): Summary of the bioinformatic pipeline
  * [Tutorial](Skmer_Pipeline/Tutorial.md): Step-by-step instructions for analysis of a single sample
  * [HPC instructions](Skmer_Pipeline/Slurm_Instructions.md): Instructions for  processing of multiple samples on a high performance computer (HPC) using our provided [script](Skmer_Pipeline/skmer_raw_to_query.sh).
- **VSEARCH pipeline: Identification using target capture data**  
Targeted sequencing of hundreds of genes selected for their genetic informativeness. Retrieved genes are then compared one by one to the corresponding genes of the species in the reference database. The reference species identified by the highest proportion of genes is considered the main identification. This procedure is relatively complex but provides a good measure of confidence in the identification.  
  * [Overview](VSEARCH_Pipeline): Summary of the bioinformatic pipeline
  * [Tutorial](VSEARCH_Pipeline/Tutorial.md): Step-by-step instructions for analysis of a single sample
  * [HPC instructions](VSEARCH_Pipeline/Slurm_Instructions.md): Instructions for  processing of multiple samples on a high performance computer (HPC) using our provided [script](VSEARCH_Pipeline/vsearch_raw_to_query.sh).  
  
This project is based on a [collaboration between the Royal Botanic Gardens Kew and IKEA](https://www.kew.org/science/our-science/projects/sustainable-rattan) to support a more sustainable rattan industry.
