# Interpretation tutorial

This tutorial will guide you through interpretation of the identification results retrieved using both the VSEARCH and Skmer pipelines. 

Each pipeline produces two output files:
- the top identification, named `[samplename]_summary.txt`.  
This file includes a column labelled `Data_check` that indicates whether the top identification has sufficient data for accurate identification:
  - `PASS`: sufficient data, enough data for accurate identification  
    VSEARCH: identification supported by at least 35 genes; Skmer: genomic distance not larger than 0.05
  - `WARN`: somewhat insufficient data, identifications need to be treated with caution  
    VSEARCH: identification supported by at least 2 but fewer than 35 genes; Skmer: genomic distance not larger than 0.05
  - `FAIL`: completely insufficient, resulting in most cases in wrong identification  
    VSEARCH: identification supported by only one gene; Skmer: genomic distance to identification is larger than 0.05
  
  **You should treat any identifications that do not pass these data checks with caution.**
 
- a detailed list of all matches of the sample against the reference dataset, named `[samplename]_vsearch.txt` (VSEARCH pipeline) / `[samplename]_distances.txt` (Skmer pipeline). **We recommend to always check these detailed outputs for a comprehensive understanding of the results.** You may encounter three different main scenarios that we discuss below (showing only the top 5 identifications):  
  ```
  1. Clear identification, good data
  2. Ambiguous identification, good data
  3. Ambiguous identification, insufficient data
  ```

## 1. Clear identification, good data

### VSEARCH
The top hit is supported by well over 35 genes and thus passes the data check. A clear majority of genes supports one single species.  
In the example here, *Calamus trachycoleus* is identified by 194 genes (51 % of all genes retrieved for the analysed sample), whereas the next best species *Calamus caesius* and *Calamus optimus* are identified by only 47 genes (12 %) and 35 genes (9 %), respectively. Other species are only matched by a negligible number of genes and do not need to be considered.

Reference species | Number of genes | Percentage of genes
--- | --- | ---
Calamus trachycoleus | 194 | 51.46
Calamus caesius | 47 | 12.47
Calamus optimus | 35 | 9.28
Calamus manan | 10 | 2.65
Calamus rhomboideus | 7 | 1.86


### Skmer
The top hit has a genomic distance smaller than 0.05 and thus passes the data check. Only few reference species have a genomic distances smaller than the cut-off.     
In the example here, *Calamus trachycoleus* has the smallest genomic distance and is thus considered the main identification. *Calamus caesius* also has a genomic distance smaller than 0.05 and needs to be considered as well. Other reference species have genomic distances larger than 0.05 and do not need to be considered.

Reference species | Genomic distance
--- | ---
Calamus trachycoleus | 0.0387
Calamus caesius | 0.0426
Calamus plicatus | 0.0531
Calamus didymocarpus | 0.0535
Calamus rhomboideus | 0.0535

### Combined evidence of VSEARCH and Skmer analyses
Both analyses identify the sample as *Calamus trachycoleus*.


## 2. Ambiguous identification, good data

### VSEARCH
The top hit is supported by well over 35 genes and thus passes the data check. The top hits are supported by very similar numbers of genes.  
In the example here, *Calamus applanatus* is identified by 55 genes (15 %), but *Calamus fissilis* and *Calamus eugenei* are close runner-ups with 51 genes (14 %) and 41 gene (11 %), respectively. All three species therefore are plausible identifications. Other reference species are matched by much fewer genes and can thus be disregarded.

Reference species | Number of genes | Percentage of genes
--- | --- | ---
Calamus applanatus | 55 | 15.71
Calamus fissilis | 51 | 14.57
Calamus eugenei | 41 | 11.71
Calamus mollispinus | 18 | 5.14
Calamus nuichuaensis | 15 | 4.29

### Skmer
The top hit has a genomic distance smaller than 0.05 and thus passes the data check. Many different reference species have a genomic distance smaller than the cut-off.  
In the example here, *Calamus fissilis* has the smallest genomic distance of 0.0409 but *Calamus eugenei* and *Calamus applanatus* have highly similar genomic distances of 0.0416 and 0.0418, respectively. All three species therefore are plausible identifications. Other reference species have considerably higher genomic distances compared to the differences between the first three species (distances are <0.001 between Calamus fissilis, eugenei and applanatus, but then there is a gap of > 0.002 to the other species) but are still well below the cut-off value of 0.05. This is plausible as all of these species belong to the *Calamus applanatus* species complex. 

Reference species | Genomic distance
--- | ---
Calamus fissilis | 0.0409
Calamus eugenei | 0.0416
Calamus applanatus | 0.0418
Calamus mollispinus | 0.0442
Calamus ocreatus | 0.0449

### Combined evidence of VSEARCH and Skmer analyses
At first sight, the outputs of the VSEARCH and Skmer pipelines seem to disagree as they return *Calamus applanatus* and *Calamus fissilis*, respectively, as main identification. However, closer analyses of the outputs of both methods reveals that *Calamus applanatus*, *Calamus fissilis* and *Calamus eugenei* all need to be considered as a joint identification. This is a highly plausible outcome as all three species are closely related members of the *Calamus applanatus* species group. The ambiguous identification thus results from the biological complexity of the species involved. 


## 3. Ambiguous identification, insufficient data

### VSEARCH
The top hit is supported by fewer than 35 genes and thus does not pass the data check. The top hits are supported by very similar numbers of genes. 
In the example here, only four genes could be retrieved for the analysed samples. *Calamus crassifolius* was identified by two genes (50 %), and *Korthalsia zippelii* and *Calamus peregrinus* by one gene (25 %), respectively. Because there is so little data, these results should be treated with extreme caution. No reliable identification can be made.

Reference species | Number of genes | Percentage of genes
--- | --- | ---
Calamus crassifolius | 2 | 50
Korthalsia zippelii | 1 | 25
Calamus peregrinus | 1 | 25


### Skmer
The top hit has a genomic distance higher than 0.05 and thus does not pass the data check.  
In the example here, the reference species with the smallest genomic distance to the sample is *Calamus burkillianus*. However, the distance is with 0.0989 much higher than the cut-off value of 0.05. For other reference species, it is even higher. These results should therefore be treated with extreme caution. No reliable identification can be made.

Reference species | Genomic distance
--- | ---
Calamus burkillianus | 0.0989
Calamus spiculifer | 0.1025
Calamus oblongus | 0.1026
Calamus metzianus | 0.1034
Calamus maturbongsii | 0.1069

### Combined evidence of VSEARCH and Skmer analyses
The VSEARCH and Skmer analyses differ in the identifications provided. These differences do not reflect biological complexity but are caused solely by data deficiency. No reliable identification can be made.

## Useful resources for validating species identifications
In case there is any remaining uncertainty about species identifications, we recommend consulting the excellent revision of the most important rattan genus *Calamus* by Andrew Henderson (2020): https://www.biotaxa.org/Phytotaxa/article/view/phytotaxa.445.1.1. This resource describes all species of *Calamus* in detail, including useful information on species complexes and maps of geographical distribution that can be useful if the provenance of samples is known.  

The Plants of the World Online webpage can also be a useful source of information: https://powo.science.kew.org/.






















