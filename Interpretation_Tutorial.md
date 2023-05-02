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

1. Clear identification, good data
2. Ambiguous identification, good data
3. Ambiguous identification, insufficient data

## 1. Clear identification, good data

### VSEARCH
The top hit is supported by well over 35 genes and thus passes the data check. A clear majority of genes supports one single species.  
In the example here, *Calamus trachycoleus* is identified by 194 genes (51 % of all genes retrieved for the analysed sample), whereas the next best species *Calamus caesius* and *Calamus optimus* are identified by only 47 genes (12 %) and 35 genes (9 %), respectively. Other species are only matched by a negligible number of genes and do not need to be considered.

Reference species | Number of genes | Percentage of genes
--- | --- | ---
Calamus_trachycoleus | 194 | 51.46
Calamus_caesius | 47 | 12.47
Calamus_optimus | 35 | 9.28
Calamus_manan | 10 | 2.65
Calamus_rhomboideus | 7 | 1.86


### Skmer
The top hit has a genomic distance smaller than 0.05 and thus passes the data check.  
In the example here, *Calamus trachycoleus* has the smallest genomic distance and is thus considered the main identification. *Calamus caesius* also has a genomic distance smaller than 0.05 and needs to be considered as well. Other reference species have genomic distances larger than 0.05 and do not need to be considered.

Reference species | Genomic distance
--- | ---
Calamus_trachycoleus_Baker_560_BKL020 | 0.0387
Calamus_caesius_Baker_547_JSL044 | 0.0426
Calamus_plicatus_Kuhnhäuser_74_JSL076 | 0.0531
Calamus_didymocarpus_Henderson_4283_JSL037 | 0.0535
Calamus_rhomboideus_Baker_565_RBL084 | 0.0535





