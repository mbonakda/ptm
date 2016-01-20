# -*- coding: utf-8 -*-
# <nbformat>3.0</nbformat>

# <codecell>

from __future__ import division, unicode_literals

import os
import re
import random
import webbrowser
import pickle
import string
import nltk
import math
from textblob import TextBlob

path_arxiv = '/home/jerry/Data/Hopper_Project/ptm_data/arxiv_processed_trunc/'
path_wiki = '/home/jerry/Data/Hopper_Project/ptm_data/wiki/'

# load the document comparisons
doc_comparisons = pickle.load(open('./doc_comparisons.p', 'r'))

# function to take in a arxiv paper name and output the top k wiki concepts
def relevant_concepts(arxiv_doc, doc_comparisons, k):
    print("\nTop concepts in document {}:".format(arxiv_doc))
    
    # check if arxiv_doc in doc_comparsions
    if arxiv_doc in doc_comparisons.keys(): 
        scores = doc_comparisons[arxiv_doc]
        sorted_words = sorted(scores.items(), key=lambda x : x[1], reverse = True)
        for concept, score in sorted_words[:k]:
            print("\tConcept: {}, cosine dist: {}".format(concept, round(score, 5)))
    
    else:
        print("\tError: input doc not in doc_comparisons")
        
def show_doc_text(arxiv_doc):
    f = open('/home/jerry/Data/Hopper_Project/ptm_data/arxiv_processed_trunc/' + arxiv_doc, 'r')
    text = f.read()
    f.close()
    print('\n' + 'Title: ' + arxiv_doc + '\n\n' + text)

def show_doc_pdf(arxiv_doc):
    # first get the article id from string input
    id_string = re.sub('\_trunc.txt', '', arxiv_doc)
    webbrowser.open('http://arxiv.org/abs/' + id_string)
    #webbrowser.open('http://arxiv.org/pdf/' + id_string + '.pdf')

articles = doc_comparisons.keys()
indices = list(xrange(len(articles)))

while(1):
    i = raw_input("There are {} analyzed arxiv articles. Enter an integer from 0 to {} to access one of the articles.\n".format(len(articles),len(articles)-1))
    i = int(i)
    if i not in indices:
        print("Input not in range. Please try again.\n")
    else:
        relevant_concepts(articles[i], doc_comparisons, 5)
        show_doc_pdf(articles[i])
        #show_doc_text(articles[i])
        print('\n');

