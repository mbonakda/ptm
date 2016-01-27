source('ptm_funcs.R')

############################################################
# Setup
############################################################
## directory to store cached files and results
PTM.PROJ.DIR <- '/Users/mbonakda/github/hopper-project/ptm/tm/analysis'

## the code assumes the following directories contain one text file per document
dir.impure   <- '/Users/mbonakda/projects/hopper/ptm/data/arxiv_processed_trunc/'
dir.pure     <- '/Users/mbonakda/projects/hopper/ptm/data/stat-th_pruned/'

############################################################
# Data Generation
############################################################
## process raw data
proc.lst <- ptm.transform.raw( dir.impure = dir.impure,
                               dir.pure   = dir.pure,
                               version    = '01')

dtm.impure  <- proc.lst[['dtm.impure']]
dtm.pure    <- proc.lst[['dtm.pure']]
n.pure      <- proc.lst[['n.pure']]
n.impure    <- proc.lst[['n.impure']]
vocab       <- proc.lst[['vocab']]
doc.names   <- proc.lst[['doc.names']]


## transform document-term matrix to list for lda Rpkg functions
## 01: ~6 minutes
lda.docs <- ptm.conform.to.lda( dtm     = rbind(dtm.impure, dtm.pure),
                                version = '01')

impure.docs   <- lda.docs[seq_len(n.impure)]
pure.docs     <- lda.docs[seq_len(n.pure)+n.impure]

############################################################
# Modeling
############################################################

##############
## 0. MLE
##############
ptm.mle   <- ptm.run.mle(version = '01', num.iter = 200)
doc.data  <- ptm.get.data(version = '01')

## top 10 words in each concept
concepts.mle           <- t(top.topic.words(ptm.mle$topics, 10))
rownames(concepts.mle) <- gsub('.txt', '', rownames(doc.data[['dtm.pure']]))
rownames(concepts.mle) <- paste(rownames(concepts.mle), ".mle", sep='')


##############
## 1. PTM1
##############
result.dir <- '/Users/mbonakda/github/hopper-project/ptm/tm/analysis/01/results'
ptm1       <- ptm.run.ptm1(version = '01', eta = 0.1)
doc.data   <- ptm.get.data(version = '01')


## save concept comparisons for varying levels of eta
eta.vec <- c(0.1, 1, 10, 100)
for( eta in eta.vec ) {
    ptm1      <- ptm.run.ptm1(version = '01', eta = eta)

    ## top 10 words in each concept + background
    concepts.ptm1            <- t(top.topic.words(ptm1$topics, 10, by.score=TRUE))
    rownames(concepts.ptm1)  <- c(gsub(".txt", "", rownames(doc.data[['dtm.pure']])), 'background')
    rownames(concepts.ptm1)  <- paste(rownames(concepts.ptm1), ".ptm1", sep='')

    ## compare concepts for MLE vs. PTM1
    cc        <- rbind(concepts.mle, concepts.ptm1)
    cc        <- cc[order(rownames(cc)),]
    cc        <- cc[c(which(rownames(cc)=='background.ptm1'),seq_len(nrow(cc))[-which(rownames(cc)=='background.ptm1')]),]
    write.table(cc, file = file.path(result.dir, paste('concepts_mle_vs_ptm1_eta=', eta, '.csv', sep='')),
                col.names=FALSE, sep =',', quote=FALSE)
}




## background topics
ptm1              <- ptm.run.ptm1(version = '01', eta = 100)
normalized.topics <- ptm1$topics/rowSums(ptm1$topics)
bground           <- normalized.topics[39,]
names(bground)    <- colnames(normalized.topics)
bground           <- data.frame(sort(bground, decreasing=TRUE))
colnames(bground) <- 'topic.proportion'
write.table(bground, file = file.path(result.dir, 'background_eta=100.csv'), col.names=FALSE,
            sep=',', quote=FALSE)


## top 10 words in each concept + background
concepts.ptm1            <- t(top.topic.words(ptm1$topics, 10, by.score=TRUE))
rownames(concepts.ptm1)  <- c(gsub(".txt", "", rownames(doc.data[['dtm.pure']])), 'background')
rownames(concepts.ptm1)  <- paste(rownames(concepts.ptm1), ".ptm1", sep='')
