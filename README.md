# ACE 2005 Data Prep

## Description

This project ties together numerous tools. It converts from the [ACE
2005 file format](https://catalog.ldc.upenn.edu/LDC2006T06) (.sgm and .apf.xml files) to Concrete. It also
annotates the ACE 2005 data using Stanford CoreNLP and the
chunklink.pl script from CoNLL-2000. The data is the same as that used in (Yu, Gormley, & Dredze, NAACL 2015) and (Gormley, Yu, & Dredze, EMNLP 2015). See below for appropriate citations.

The output of the pipeline is available in two formats: Concrete and JSON.
Concrete is a data serialization format for NLP. See the [primer on Concrete](http://hltcoe.github.io/) for additional details. As a convenience, the output is also converted to an easy-to-parse [Concatenated JSON format](https://en.wikipedia.org/wiki/JSON_Streaming#Concatenated_JSON). This conversion is done by [Pacaya NLP](https://github.com/mgormley/pacaya-nlp). An example sentence is shown below. 

```json
{"words":["i","'m","wolf","blitzer","in","washington","."]
,"lemmas":["i","be","wolf","blitzer","in","washington","."]
,"posTags":["LS","VBP","JJ","NN","IN","NN","."]
,"chunks":["O","B-VP","B-NP","I-NP","B-PP","B-NP","O"]
,"parents":[3,3,3,-1,3,4,-2]
,"deprels":["nsubj","cop","amod","root","prep","pobj",null]
,"naryTree":"((ROOT (S (NP (LS i)) (VP (VBP 'm) (NP (NP (JJ wolf) (NN blitzer)) (PP (IN in) (NP (NN washington))))) (. .))))"
,"nePairs":"[{\"m1\":{\"start\":2,\"end\":4,\"head\":3,\"type\":null,\"subtype\":null,\"phraseType\":\"NAM\",\"id\":\"db1b9d9c-15cb-f7bb-7ded-00007733280a\"},\"m2\":{\"start\":5,\
,"relLabels":["PHYS(Arg-1,Arg-1)"]}
```

The words, named-entity pairs (nePairs), and relation labels (relLabels) are given by the original ACE 2005 data. The lemmas, part-of-speech tags (posTags), labeled syntactic dependency parse (parents, deprels), and constituency parse (naryTree) are automatically annotated by [Stanford CoreNLP](https://github.com/stanfordnlp/CoreNLP). The chunks are derived from the constituency parse using a [python wrapper](https://github.com/mgormley/concrete-chunklink) of the chunklink.pl script from CoNLL-2000.

After executing ```make LDC_DIR=./LDC OUT_DIR=./output ace05splits``` (see details below), the output will consist of the following directories:

* `LDC2006T06_temp_copy/`: A copy of the LDC input directory with DTD files placed appropriately.
* `ace-05-comms/`: The ACE 2005 data converted to Concrete.
* `ace-05-comms-ptb-anno/`: The ACE 2005 data converted to Concrete and annotated with Stanford CoreNLP.
* `ace-05-comms-ptb-anno-chunks/`: The ACE 2005 data converted to Concrete and annotated with Stanford CoreNLP and chunklink.pl.
* `ace-05-comms-ptb-anno-chunks-json{-ng14,-pm13,-ygd15-r11,-ygd15-r32}/`: The fully annotated data converted to Concatenated JSON. 
* `ace-05-splits/`: The same data as above but each subdirectory contains the data split into separate domains (i.e. Newswire (nw), Broadcast Conversation (bc), Broadcast News (bn), Telephone Speech (cts), Usenet Newsgroups (un), and Weblogs (wl)). It also includes the training set bn+nw from (Gormley, Yu, & Dredze, EMNLP 2015), as well as the dev and test splits of the bc domain: `bc_dev/` and `bc_test/` respectively.

We recommend all users of this pipeline use the files in `ace-05-splits` for replicating the settings of prior work.

A key difference between the Concrete and JSON formats: for each sentence, the Concrete data includes all of the relation and named entity labels. By contrast, the JSON data includes multiple copies of each sentence with one relation / named entity pair per copy. Further, the JSON data includes explict NO_RELATION labels, whereas the Concrete data only includes the positive labels.  The literature includes several ways of defining the positive relation labels (e.g. with or without direction) and the negative relations (i.e. NO_RELATION for all pairs vs. only those pairs with some number of intervening entity mentions). The JSON format for the directories ending in `{-ng14,-pm13,-ygd15-r11,-ygd15-r32}` corresponds to several such idiosyncractic formats. See below for more details.


## Citations

The data in the directories ending with `-pm13` is the same data from (Gormley, Yu, & Dredze, EMNLP 2015) that replicates the settings of (Plank & Moschitti, 2013). 

```bibtex
@inproceedings{gormley_improved_2015,
    author = {Matthew R. Gormley and Mo Yu and Mark Dredze},
    title = {Improved Relation Extraction with Feature-rich Compositional Embedding Model},
    booktitle = {Proceedings of {EMNLP}},
    year = {2015},
}
```

The data in the directories ending with `-ng14` replicates the settings of (Nguyen & Grishman, 2014). 

The data in the directories ending with `-ygd15-r11` and `-ygd-r32` is the 11 output and 32 output labeled data from (Yu, Gormley, & Dredze, NAACL 2015).

```bibtex
@inproceedings{yu_combining_2015,
    author = {Yu, Mo and Gormley, Matthew R. and Dredze, Mark},
    title = {Combining Word Embeddings and Feature Embeddings for Fine-grained Relation Extraction},
    booktitle = {Proceedings of {NAACL}},
    year = {2015}
}
```



## Requirements

- Java 1.8+
- Maven 3.4+
- Python 2.7.x
- GNU Make

## Convert ACE 2005 Data to Concrete

First find the correct ACE 2005 data from the LDC release
LDC2006T06. We use the adjudicated files located in 'adj'
subdirectories. 

### Convert and Annotate Full Dataset

A Makefile is included to  to convert the full ACE 2005 dataset to
Concrete. The same Makefile will also add Stanford CoreNLP annotations
and convert the constituency trees to chunks with chunklink.pl. 
It will also require install the latest version of concrete-python and
clone the concrete-chunklink repository. 

The command below will convert the data to Concrete
(with AceApf2Concrete), annotate (with Stanford and chunklink.pl), and
split the data back into domains (with split_ace_dir.sh).

    make LDC_DIR=<path to LDC dir> \
         OUT_DIR=<path for output dir> \
         ace05splits

### Convert a Single File to Concrete

To convert a single ACE file to Concrete use AceApf2Concrete. 
Note that the apf.v5.1.1.dtd file must be in the same directory 
as the .apf.xml and .sgm files or the DOM reader will throw a 
FileNotFound exception.

    source setupenv.sh
    cp LDC2006T06/dtd/*.dtd ./
    java -ea edu.jhu.re.AceApf2Concrete APW_ENG_20030322.0119.apf.xml APW_ENG_20030322.0119.comm
    
