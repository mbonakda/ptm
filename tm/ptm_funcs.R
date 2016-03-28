## input: directory containing pure and impure documents
## create and serialize a document-term matrix, vocabulary, and document names
ptm.transform.raw <- function(dir.impure, dir.pure, version, verbose=TRUE, min.words.pure=150, min.words.impure=150) {
    library(tm)
    #browser()
    out.dir        <- file.path(PTM.PROJ.DIR, version, 'data')
    dtm.file       <- file.path(out.dir, 'dtm.txt')
    vocab.file     <- file.path(out.dir, 'vocab.txt')
    doc.file       <- file.path(out.dir, 'docs.txt')
    doc.cnt.file   <- file.path(out.dir, 'docCounts.txt')
    dir.names.file <- file.path(out.dir, 'dirNames.txt')

    # check cached files
    if( all( sapply(c(dtm.file, vocab.file, doc.file, doc.cnt.file, dir.names.file), file.exists) ) ) {
        if(verbose) print("Loading cached DTM data.")
        dtm         <- read.csv(dtm.file, header=FALSE)
        vocab       <- read.csv(vocab.file, header=FALSE, stringsAsFactors = FALSE)[,1]
        doc.names   <- read.csv(doc.file, header=FALSE, stringsAsFactors = FALSE)[,1]
        doc.cnt     <- read.csv(doc.cnt.file, header=FALSE, row.names=1)
        n.pure      <- doc.cnt['n.pure',]
        n.impure    <- doc.cnt['n.impure',]
    } else {
        if(verbose) print("No cached data.")
        dir.create(out.dir, recursive=TRUE, showWarnings = FALSE)

        ## document count
        n.pure      <- length(list.files(dir.pure))
        n.impure    <- length(list.files(dir.impure))
        if (verbose) {
            paste("VERBOSE: Number of impure docs: ", n.impure)
        }

        ## construct document-term matrix
        corpus      <- Corpus(DirSource(c(dir.impure,dir.pure)), readerControl=list(language="English"))
        corpus      <- tm_map(corpus, content_transformer(tolower))
        corpus      <- tm_map(corpus, removePunctuation)
        corpus      <- tm_map(corpus, removeNumbers)
        corpus      <- tm_map(corpus, stripWhitespace)
        corpus      <- tm_map(corpus, removeWords, stopwords('english'))
        dtm.d       <- DocumentTermMatrix(corpus, control=list(wordLengths=c(1,15)))
        dtm.s       <- removeSparseTerms(dtm.d, .99)
        dtm         <- as.matrix(dtm.s)

        ## prune vocabulary by word count
        wc.impure   <- colSums(dtm[seq_len(n.impure),])
        wc.pure     <- colSums(dtm[seq_len(n.pure)+n.impure,])
        valid.idx   <- wc.pure > 3 & wc.impure > 10 & sapply(names(wc.pure), nchar) > 2 & wc.pure < quantile(wc.pure, 0.98) & wc.impure < quantile(wc.impure,0.98)
        dtm         <- dtm[, valid.idx]
        rownames(dtm) <- gsub(",", "", rownames(dtm))

        ## prune document by length
        dtm.impure <- dtm[seq_len(n.impure),]
        dtm.pure   <- dtm[seq_len(n.pure)+n.impure,]

        valid.idx  <- rowSums(dtm.impure) > min.words.impure
        dtm.impure <- dtm.impure[valid.idx,]
        n.impure   <- dim(dtm.impure)[1]
        print(paste("Pruning", sum(!valid.idx), "impure document"))

        valid.idx  <- rowSums(dtm.pure) > min.words.pure
        dtm.pure   <- dtm.pure[valid.idx,]
        n.pure     <- dim(dtm.pure)[1]
        print(paste("Pruning", sum(!valid.idx), "pure document"))


        dtm         <- rbind(dtm.impure, dtm.pure)
        vocab       <- colnames(dtm)
        doc.names   <- rownames(dtm)
        doc.cnts    <- t(data.frame(n.pure = n.pure, n.impure=n.impure))
        dir.names   <- t(data.frame(dir.impure=dir.impure, dir.pure=dir.pure))

        ## serialize
        write.table(as.matrix(dtm),file = dtm.file,
                    row.names=FALSE, col.names=FALSE, sep=',')
        write.table(data.frame(vocab),file = vocab.file,
                    row.names=FALSE, col.names=FALSE, sep=',', quote=FALSE)
        write.table(data.frame(doc.names),file = doc.file,
                    row.names=FALSE, col.names=FALSE, sep=',', quote=FALSE)
        write.table(doc.cnts,file = doc.cnt.file,
                    col.names=FALSE, sep=',', quote=FALSE)
        write.table(dir.names,file = dir.names.file,
                    col.names=FALSE, sep=',', quote=FALSE)
    }


    rownames(dtm) <- doc.names
    colnames(dtm) <- vocab
    dtm.impure <- dtm[seq_len(n.impure),]
    dtm.pure   <- dtm[seq_len(n.pure)+n.impure,]

    if(verbose) {
        print(paste("size of pure corpus = ", n.pure))
        print(paste("size of impure corpus = ", n.impure))
        print(paste("size of vocab = ", length(vocab)))
    }

    return(list(dtm.impure=dtm.impure, dtm.pure=dtm.pure, n.pure=n.pure, n.impure=n.impure,
                vocab=vocab, doc.names=doc.names))
}


# transforms document-term matrix to a list for lda Rpkg
ptm.conform.to.lda <- function(dtm, version, verbose=TRUE) {


    out.dir       <- file.path(PTM.PROJ.DIR, version, 'data')
    lda.doc.file  <- file.path(out.dir, 'ldaDocs.Rdata')

    if( file.exists(lda.doc.file) ) {
        print("Loading cached LDA document file.")
        load(lda.doc.file)
    } else {
        dir.create(out.dir, recursive=TRUE, showWarnings=FALSE)

        lda.docs <- vector('list', nrow(dtm))
        for( i in seq_len(length(lda.docs)) ) {

            word.idx          <- sapply(which(dtm[i,]> 0), as.integer)
            lda.docs[[i]]     <- matrix(0, nrow=2, ncol=length(word.idx))

            ## lda uses 0-indexing
            lda.docs[[i]][1,] <- word.idx - 1

            ## lda C code requires integer type
            lda.docs[[i]][2,] <- sapply(dtm[i,word.idx], as.integer)
            lda.docs[[i]]     <- apply(lda.docs[[i]], 2, as.integer)
        }
        save(lda.docs, file  = lda.doc.file)
    }

    return(lda.docs)

}

ptm.get.data <- function(version) {

    data.dir       <- file.path(PTM.PROJ.DIR, version, 'data')
    dtm.file       <- file.path(data.dir, 'dtm.txt')
    vocab.file     <- file.path(data.dir, 'vocab.txt')
    doc.file       <- file.path(data.dir, 'docs.txt')
    doc.cnt.file   <- file.path(data.dir, 'docCounts.txt')
    dir.names.file <- file.path(data.dir, 'dirNames.txt')
    lda.doc.file   <- file.path(data.dir,  'ldaDocs.Rdata')

    if( all( sapply(c(dtm.file, vocab.file, doc.file, doc.cnt.file, dir.names.file, lda.doc.file),
                    file.exists) ) ) {
        print("Loading cached document data.")
        dtm         <- read.csv(dtm.file, header=FALSE)
        vocab       <- read.csv(vocab.file, header=FALSE, stringsAsFactors = FALSE)[,1]
        doc.names   <- read.csv(doc.file, header=FALSE, stringsAsFactors = FALSE)[,1]
        doc.cnt     <- read.csv(doc.cnt.file, header=FALSE, row.names=1)
        n.pure      <- doc.cnt['n.pure',]
        n.impure    <- doc.cnt['n.impure',]
        load(lda.doc.file)

        rownames(dtm) <- doc.names
        colnames(dtm) <- vocab
        dtm.impure <- dtm[seq_len(n.impure),]
        dtm.pure   <- dtm[seq_len(n.pure)+n.impure,]

        print(paste("size of pure corpus = ", n.pure))
        print(paste("size of impure corpus = ", n.impure))
        print(paste("size of vocab = ", length(vocab)))

        return(list(dtm.impure=dtm.impure, dtm.pure=dtm.pure, n.pure=n.pure, n.impure=n.impure,
                    vocab=vocab, doc.names=doc.names, lda.docs=lda.docs))
    } else {
        stop("ERROR: need to generate data first")
    }


}

## 1. set concepts equal to MLE of pure documents
## 2. fix concepts to above and cook on impure documents
ptm.run.mle <-  function(version, force=FALSE, num.iter=200) {

    out.dir       <- file.path(PTM.PROJ.DIR, version, 'topic_model')
    result.file   <- file.path(out.dir, paste('ptm_mle_iter=', num.iter, '.Rdata', sep=''))

    if(file.exists(result.file) && !force) {
        print("Loading cached PTM_MLE data")
        load(result.file)
    } else {

        dir.create(out.dir, recursive=TRUE, showWarnings=FALSE)

        ## load cached data
        doc.data    <- ptm.get.data(version)

        dtm.impure  <- doc.data[['dtm.impure']]
        dtm.pure    <- doc.data[['dtm.pure']]
        n.pure      <- doc.data[['n.pure']]
        n.impure    <- doc.data[['n.impure']]
        vocab       <- doc.data[['vocab']]
        doc.names   <- doc.data[['doc.names']]
        lda.docs    <- doc.data[['lda.docs']]

        impure.docs   <- lda.docs[seq_len(n.impure)]
        pure.docs     <- lda.docs[seq_len(n.pure)+n.impure]

        ## concept MLE
        concepts     <- apply(as.matrix(dtm.pure), 2, as.integer)
        concept.sums <- apply(as.matrix(rowSums(concepts)), 2, as.integer)

        library(lda)
        print("Cooking...")
        ptm.mle        <- lda.collapsed.gibbs.sampler(impure.docs,
                                                      length(concept.sums),
                                                      vocab,
                                                      num.iter,
                                                      0.1,
                                                      0.1,
                                                      compute.log.likelihood = TRUE,
                                                      freeze.topics          = TRUE,
                                                      initial                = list(topics = concepts,
                                                      topic_sums=concept.sums)
                                                      )
        save(ptm.mle, file = result.file)
    }
    return(ptm.mle)
}

## 1. pure documents come from either pure topic or shared background topic
## 2. cook with above model on pure documents
## 2. fix concepts to above and cook on impure documents
ptm.run.ptm1 <-  function(version, eta, force=FALSE, num.iter=2000) {

    out.dir       <- file.path(PTM.PROJ.DIR, version, 'topic_model')
    result.file   <- file.path(out.dir, paste('ptm1_iter=', num.iter, '_eta=', eta, '.Rdata', sep=''))

    if(file.exists(result.file) && !force) {
        print("Loading cached PTM1 data")
        load(result.file)
    } else {

        dir.create(out.dir, recursive=TRUE, showWarnings=FALSE)

        ## load cached data
        doc.data    <- ptm.get.data(version)

        dtm.impure  <- doc.data[['dtm.impure']]
        dtm.pure    <- doc.data[['dtm.pure']]
        n.pure      <- doc.data[['n.pure']]
        n.impure    <- doc.data[['n.impure']]
        vocab       <- doc.data[['vocab']]
        doc.names   <- doc.data[['doc.names']]
        lda.docs    <- doc.data[['lda.docs']]

        impure.docs   <- lda.docs[seq_len(n.impure)]
        pure.docs     <- lda.docs[seq_len(n.pure)+n.impure]

        library(lda)
        print("Cooking...")
        ptm1 <- ptm1.collapsed.gibbs.sampler(documents      = pure.docs,
                                             vocab          = vocab,
                                             num.iterations = num.iter,
                                             alpha          = 0.1, # word-specific background
                                             eta            = eta, # word-specific pure
                                             gamma          = 0.1  # document-specific (both)
                                             )

        save(ptm1, file = result.file)
    }
    return(ptm1)
}

