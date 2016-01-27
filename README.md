# Paedic Topic Models

## Topic Modeling 
* The ptm/tm directory contains the code used for topic modeling:  
  * the ptm_funcs.R file contains the functions used to process raw data and run LDA
  * the ptm_driver.R shows how to use the functions in ptm_funcs.R  
  * the lda_1.4.3.tar.gz file contains modified C code to run the "PTM1" model. It is based on [this R package](https://cran.r-project.org/web/packages/lda/).
    * To install it from the command line, run: R CMD INSTALL lda_1.4.3.tar.gz. **Warning: this is overwrite your current version of LDA**.
* To download the raw data, click [here](https://www.dropbox.com/s/u93t9fzn3knbxnr/PTM_DATA_01.tar.gz?dl=0).  
  * The stat-th_pruned directory contains a pruned subset (38) of the wikipedia documents corresponding to "Statistical Theory"  
  * The arxiv_processed_trunc directory contains 3631 documents listed under the 'stat-th' category.  
    * The document have been truncated at 1000 words and the LaTeX has been stripped. 
    * Date range: 03/2011 - 11/2015  

## tf-idf 
