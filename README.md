# ACE 2005 Data Prep

## Description

This project ties together numerous tools. It converts from the ACE
2005 file format (.sgm and .apf.xml files) to Concrete. It also
annotates the ACE 2005 data using Stanford CoreNLP and the
chunklink.pl script from CoNLL-2000.

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

A Makefile is included to convert the full ACE 2005 dataset to
Concrete. To do so, run the following:

    make LDC2006T06=<path to LDC dir> ACE_OUT_DIR=<path for output dir> ace05comms

The same Makefile will also add Stanford CoreNLP annotations
and convert the constituency trees to chunks with chunklink.pl. 
First, you must install the latest version of concrete-python and
clone the concrete-chunklink repository.

    pip install concrete
    git clone https://github.com/mgormley/concrete-chunklink.git

Then run the make command below. It will convert the data to Concrete
(with AceApf2Concrete), annotate (with Stanford and chunklink.pl), and
split the data back into domains (with split_ace_dir.sh).

    make LDC2006T06=<path to LDC dir> \
         ACE_OUT_DIR=<path for output dir> \
         CONCRETE_CHUNKLINK=./concrete-chunklink \
         ace05splits

### Convert a Single File to Concrete

To convert a single ACE file to Concrete use AceApf2Concrete. 
Note that the apf.v5.1.1.dtd file must be in the same directory 
as the .apf.xml and .sgm files or the DOM reader will throw a 
FileNotFound exception.

    source setupenv.sh
    cp LDC2006T06/dtd/*.dtd ./
    java -ea edu.jhu.re.AceApf2Concrete APW_ENG_20030322.0119.apf.xml APW_ENG_20030322.0119.comm
    

## Convert SemEval-2010 Task 8 data to Concrete

Currently, the Makefile is only able to add annotations to the
SemEval-2010 Task 8 data, given Concrete files as input.
First, you must install the latest version of concrete-python and
clone the concrete-chunklink repository.

    pip install concrete
    git clone https://github.com/mgormley/concrete-chunklink.git

Then run the following to add annotations:

    make SE_COMMS=<path to SemEval Concrete dir> \
         SE_OUT_DIR=<path for output dir> \
         CONCRETE_CHUNKLINK=./concrete-chunklink \
         semevalanno


