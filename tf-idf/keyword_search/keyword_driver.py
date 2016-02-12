# Jerry Chee
# drive to run tf-idf keyword analysis
# -*- coding: utf-8 -*-
from keyword_functions import *

# =============================================================================
# change the per system. 
# the script will check in path_save to see if the data objects exist.
# if not, the script will generate them and save to path_save
path_arxiv = '/home/jerry/Data/Hopper_Project/ptm_data/arxiv_processed_trunc/'
path_save = './test_data_objects/'

concepts_pickle = "master-concepts.p"
concepts_txt = "master-concepts"
path_concepts_txt = "./"
# =============================================================================


# load or generate concepts list
if (check_exist(concepts_pickle, path_save) == False):
    print("generating concepts list")
    concept_list(concepts_txt, path_concepts_txt, path_save)

concepts = pickle.load(open(path_save + concepts_pickle, 'r'))

# generate regex expressions
re_concepts = gen_regex(concepts)

# load or generate dicts needed to compute tf-idf
if (check_exist("arxiv_sep_byfile.p", path_save) == False
        | check_exist("arxiv_sep_byword.p", path_save) == False
        | check_exist("arxiv_wordsindoc.p", path_save) == False):
    print("computing data dictionaries")
    data_process(path_arxiv, re_concepts, path_save)

arxiv_sep_byfile = pickle.load(open(path_save + "arxiv_sep_byfile.p", 'r'))
arxiv_sep_byword = pickle.load(open(path_save + "arxiv_sep_byword.p", 'r'))
arxiv_wordsindoc = pickle.load(open(path_save + "arxiv_wordsindoc.p", 'r'))

# generate tf-idf scores
if (check_exist("tfidf_arxiv.p", path_save) == False):
    print("computing tf-idf scores")
    compute_tfidf(path_arxiv, path_save, arxiv_sep_byfile,
            arxiv_sep_byword, arxiv_wordsindoc)

# generate okapi scores
if (check_exist("okapi_arxiv.p", path_save) == False):
    print("computing okapi scores")
    compute_okapi(path_save, arxiv_sep_byfile,
            arxiv_sep_byword, arxiv_wordsindoc)
