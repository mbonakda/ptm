# Jerry Chee
# run a demo to lookup top concepts given tf-idf python dictionaries

from __future__ import division, unicode_literals

import os
import re
import webbrowser
import pickle

# change these paths
path_arxiv = '/home/jerry/Data/Hopper_Project/ptm_data/arxiv_processed_trunc/'
path_cosdist = './doc_comparisons.p'
path_tfidf = 'fill in here'

# =============================================================================
doc_comparisons = pickle.load(open(path_cosdist, 'r'))
# load tfidf keyword scores (regex improvements)
tfidf_arxiv = pickle.load(open(path_tfidf_re, 'r'))

# function to take in a arxiv paper name and output the top k wiki concepts
def relevant_concepts(arxiv_doc, dictionary, k):
    print("Top concepts in document {}:".format(arxiv_doc))
    
    # check if arxiv_doc in doc_comparsions
    if arxiv_doc in dictionary.keys(): 
        scores = dictionary[arxiv_doc]
        sorted_words = sorted(scores.items(), 
                key=lambda x : x[1], reverse = True)
        for concept, score in sorted_words[:k]:
            print("\tConcept: {}, score: {}".format(concept, 
                round(score, 5)))
            #print("\tConcept: {} ({})".format(concept, 
                #concept_member(concept)))
    
    else:
        print("\tError: input doc not in given dictionary")
        
def show_doc_text(arxiv_doc):
    f = open(path_arxiv + arxiv_doc, 'r')
    text = f.read()
    f.close()
    print('\n' + 'Title: ' + arxiv_doc + '\n\n' + text)

def show_doc_inbrowser(arxiv_doc):
    # first get the article id from string input
    id_string = re.sub('\_trunc.txt', '', arxiv_doc)
    webbrowser.open('http://arxiv.org/abs/' + id_string)

# =============================================================================
# currently only runs over arxiv papers analyzed using exact string matching,
# a smaller subset than the regex matching

articles = tfidf_arxiv.keys()
indices = list(xrange(len(articles)))

articles_old = doc_comparisons.keys()
indices_old = list(xrange(len(articles)))

# main loop
while(1):
    i = raw_input("There are {} analyzed arxiv articles under both methods of cosine distance and keyword tf-idf score.\nEnter an integer from 0 to {} to access one of the articles.\n".format(len(articles_old),len(articles_old)-1))
    i = int(i)
    if i not in indices_old:
        print("Input not in range. Please try again.\n")
    else:
        print("regex improved keyword tf-idf score")
        relevant_concepts(articles_old[i], tfidf_arxiv, 5)
        print("")
        print("cosine distance tf-idf score")
        relevant_concepts(articles_old[i], doc_comparisons, 5)
        show_doc_inbrowser(articles_old[i])
        print('\n');

