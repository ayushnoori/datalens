
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Alzheimer DataLENS

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<!-- badges: end -->

Alzheimer DataLENS is an open data analysis platform which aims to
advance Alzheimer’s disease research by enabling the analysis,
visualization, and sharing of -omics data. DataLENS will houses
bioinformatics pipelines for the analysis of -omics data on Alzheimer’s
disease and related dementias as well as streamlined web interfaces
which allow neuroscientists to browse and query the results of these
analyses. Currently, we have identified are over 50 possible genetic,
proteomics, and transcriptomics studies which are suitable for DataLENS.
Some example datasets which could be made available on DataLENS now or
in the future include:

**Gene Expression Data**

1.  Analysis of 60 human microarray expression profiling datasets across
    various neurodegenerative diseases (26 Alzheimer’s, 21 Lewy body
    dementia, 13 amyotrophic lateral sclerosis and frontotemporal
    dementia).
2.  Analysis of 30+ public human datasets spanning 19 brain regions and
    5 cohorts.
3.  Analysis of data from several Alzheimer’s disease animal models.
4.  Three single-cell RNA-sequencing datasets.

**Proteomics Data**

1.  Analysis of two proteomics studies, with additional studies
    currently in progress.

**Genome-Wide Association Studies (GWAS)**

1.  Results from the International Genomics of Alzheimer’s Project
    (IGAP) GWAS meta-analysis.
2.  Results from the Accelerating Medicines Partnership – Alzheimer’s
    Disease (AMP-AD) GWAS study.

**Pathways**

1.  Protein-protein interaction data and integration of expression,
    epigenetic, and genetic data.

## Installation

You can install the the development version of DataLENS from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("ayushnoori/datalens")
```

## Authorship

Alzheimer DataLENS was created by [Ayush
Noori](mailto:anoori1@mgh.harvard.edu) for CS50 at Harvard College.
DataLENS is an initiative of the [MIND Data Science
Lab](https://www.massgeneral.org/neurology/research/mind-data-science-lab)
in the MassGeneral Institute for Neurodegenerative Disease (MIND) at
Massachusetts General Hospital.

<!-- ## Example -->
<!-- This is a basic example which shows you how to solve a common problem: -->
<!-- ```{r example} -->
<!-- library(datalens) -->
<!-- ## basic example code -->
<!-- ``` -->
<!-- What is special about using `README.Rmd` instead of just `README.md`? You can include R chunks like so: -->
<!-- ```{r cars} -->
<!-- summary(cars) -->
<!-- ``` -->
<!-- You'll still need to render `README.Rmd` regularly, to keep `README.md` up-to-date. `devtools::build_readme()` is handy for this. You could also use GitHub Actions to re-render `README.Rmd` every time you push. An example workflow can be found here: <https://github.com/r-lib/actions/tree/master/examples>. -->
<!-- You can also embed plots, for example: -->
<!-- ```{r pressure, echo = FALSE} -->
<!-- plot(pressure) -->
<!-- ``` -->
<!-- In that case, don't forget to commit and push the resulting figure files, so they display on GitHub and CRAN. -->
