# Makefile for creating Concrete ACE 2005 and SemEval datasets with
# annotations from Stanford and Chunklink.
#


SHELL = /bin/bash
JAVAIN = export CLASSPATH=`mvn -f ./scripts/maven/pom-acere.xml exec:exec -q -Dexec.executable="echo" -Dexec.args="%classpath"` && java
JAVACS = export CLASSPATH=`mvn -f ./scripts/maven/pom-cs.xml exec:exec -q -Dexec.executable="echo" -Dexec.args="%classpath"` && java
JAVAPA = java -cp /Users/mgormley/research/easy-pacaya/deps/pacaya-nlp/target/pacaya-nlp-3.1.2-SNAPSHOT-jar-with-dependencies.jar
PYTHON = python
JAVAFLAGS = -ea

CONCRETE_CHUNKLINK=./concrete-chunklink

# Machine specific parameters.
ifeq ($(MACHINE),COE)
LDC_DIR=/export/common/data/corpora/LDC
OUT_DIR=~/corpora/processed/ace_05_concrete4.3
JAVAFLAGS = -ea -Xmx10000m -XX:-UseParallelGC -XX:-UseParNewGC -XX:+UseSerialGC
else ifeq ($(MACHINE),LOCAL)
LDC_DIR=/Users/mgormley/research/LDC
OUT_DIR=/Users/mgormley/research/corpora/processed/ace_05_concrete4.3
JAVAFLAGS = -ea
else
JAVAFLAGS = -ea
########
# Error if LDC_DIR and OUT_DIR weren't defined on the command line.
ifndef LDC_DIR
$(error The variable LDC_DIR should be defined on the command line)
endif
ifndef OUT_DIR
$(error The variable OUT_DIR should be defined on the command line)
endif
#######
endif

# ACE 2005 variables.
ACE_OUT_DIR=$(abspath $(OUT_DIR))
LDC2006T06=$(abspath $(LDC_DIR))/LDC2006T06
LDC2006T06_EN=$(abspath $(LDC_DIR))/LDC2006T06/data/English
LDC2006T06_EN_SYM=$(ACE_OUT_DIR)/LDC2006T06_temp_copy
ACE05_COMMS=$(ACE_OUT_DIR)/ace-05-comms
ACE05_ANNO=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno
ACE05_CHUNK=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks
ACE05_TXT_NG14=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-txt-ng14
ACE05_TXT_PM13=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-txt-pm13
ACE05_TXT_YGD15_R11=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-txt-ygd15-r11
ACE05_TXT_YGD15_R32=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-txt-ygd15-r32
ACE05_SPLITS=$(ACE_OUT_DIR)/ace-05-splits
APF_XML_FILES =$(notdir $(wildcard $(LDC2006T06_EN)/*/adj/*.apf.xml)) 

# SemEval-2010 Task 8 variables.
SE_OUT_DIR=$(abspath $(OUT_DIR))/semeval_concrete4.5/
SE_COMMS=$(abspath $(OUT_DIR))/semeval_concrete4.4/comms
SE_ANNO=$(SE_OUT_DIR)/comms-anno
SE_CHUNK=$(SE_OUT_DIR)/comms-anno-chunks

.PHONY: all
all: 
	$(info "This Makefile should be run twice: 'make ace05splits' and 'make semevalanno'.) 

.PHONY: anno
anno: ace05splits semevalanno

# ----------------------------------------------------------------
# Install (clone) concrete-chunklink from GitHub
# ----------------------------------------------------------------

$(CONCRETE_CHUNKLINK):
	pip install 'concrete>=4.4.0,<4.8.0'
	git clone https://github.com/mgormley/concrete-chunklink.git $(CONCRETE_CHUNKLINK)
	cd $(CONCRETE_CHUNKLINK) && git checkout v0.2

# ----------------------------------------------------------------
# SemEval-2010 Task 8 Data
# ----------------------------------------------------------------

.PHONY: semevalanno
semevalanno: $(addprefix $(SE_CHUNK)/,$(notdir $(wildcard $(SE_COMMS)/*.comm)))
# $(SE_CHUNK)/SemEval.test.ner.comm $(SE_CHUNK)/SemEval.test.sst.comm $(SE_CHUNK)/SemEval.train.ner.comm $(SE_CHUNK)/SemEval.train.sst.comm

# Converts the parses from concrete-stanford to chunks with concrete-chunklink.
$(SE_CHUNK)/%.comm : $(SE_ANNO)/%.comm $(CONCRETE_CHUNKLINK)
	mkdir -p $(SE_CHUNK)
	$(PYTHON) $(CONCRETE_CHUNKLINK)/concrete_chunklink/add_chunks.py --chunklink $(CONCRETE_CHUNKLINK)/scripts/chunklink_2-2-2000_for_conll.pl $< $@

# Annotates the SemEval data with concrete-stanford.
$(SE_ANNO)/%.comm : $(SE_COMMS)/%.comm
	mkdir -p $(SE_ANNO)
	$(JAVACS) $(JAVAFLAGS) edu.jhu.hlt.concrete.stanford.TextSpanMaker $< $@.tmp.comm
	$(JAVACS) $(JAVAFLAGS) edu.jhu.hlt.concrete.stanford.AnnotateTokenizedConcrete $@.tmp.comm $@

# ----------------------------------------------------------------
# ACE 2005 Data
# ----------------------------------------------------------------

# Checks that the LDC directory exits.
$(LDC2006T06):
	$(error "LDC directory does not exist: $(LDC2006T06)")

# Copy over the required .dtd files.
$(LDC2006T06_EN_SYM)/apf.v5.1.1.dtd: $(LDC2006T06)/dtd/apf.v5.1.1.dtd
	mkdir -p $(dir $@)
	ln -s $< $@ || true

# Create a flat symlinks only copy of the LDC directory.
# (This is done so that we can move the dtd files into the correct place.)
$(LDC2006T06_EN_SYM)/%.apf.xml: $(LDC2006T06_EN)/*/adj/%.apf.xml $(LDC2006T06_EN)/*/adj/%.sgm
	mkdir -p $(dir $@)
	ln -s $^ $(dir $@) || true

# Converts the ACE 2005 data to Concrete Communications.
$(ACE05_COMMS)/%.comm: $(LDC2006T06_EN_SYM)/%.apf.xml $(LDC2006T06_EN_SYM)/apf.v5.1.1.dtd
	mkdir -p $(ACE05_COMMS)
	$(JAVAIN) $(JAVAFLAGS) edu.jhu.hlt.concrete.ingesters.acere.AceApf2Concrete $< $@ 

# Annotates the ACE Communications with concrete-stanford.
$(ACE05_ANNO)/%.comm : $(ACE05_COMMS)/%.comm
	mkdir -p $(ACE05_ANNO)
	$(JAVACS) $(JAVAFLAGS) edu.jhu.hlt.concrete.stanford.AnnotateTokenizedConcrete $< $@

# Converts the parses from concrete-stanford to chunks with concrete-chunklink.
$(ACE05_CHUNK)/%.comm : $(ACE05_ANNO)/%.comm $(CONCRETE_CHUNKLINK)
	mkdir -p $(ACE05_CHUNK)
	$(PYTHON) $(CONCRETE_CHUNKLINK)/concrete_chunklink/add_chunks.py --chunklink $(CONCRETE_CHUNKLINK)/scripts/chunklink_2-2-2000_for_conll.pl $< $@

$(ACE05_TXT_NG14)/%.txt : $(ACE05_CHUNK)/%.comm
	mkdir -p $(ACE05_TXT_NG14)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut SIMPLE_TEXT \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles false \
		--maxInterveningEntities 3 \
		--removeEntityTypes true \
		--useRelationSubtype false

$(ACE05_TXT_PM13)/%.txt : $(ACE05_CHUNK)/%.comm
	mkdir -p $(ACE05_TXT_PM13)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut SIMPLE_TEXT \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles true \
		--maxInterveningEntities 3 \
		--removeEntityTypes true \
		--useRelationSubtype false

$(ACE05_TXT_YGD15_R11)/%.txt : $(ACE05_CHUNK)/%.comm
	mkdir -p $(ACE05_TXT_YGD15_R11)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut SIMPLE_TEXT \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles true \
		--maxInterveningEntities 9999 \
		--removeEntityTypes false \
		--useRelationSubtype false

$(ACE05_TXT_YGD15_R32)/%.txt : $(ACE05_CHUNK)/%.comm
	mkdir -p $(ACE05_TXT_YGD15_R32)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut SIMPLE_TEXT \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles true \
		--maxInterveningEntities 9999 \
		--removeEntityTypes false \
		--useRelationSubtype true

# Converts all the ACE 2005 data to Concrete Communications.
.PHONY: ace05comms
ace05comms: $(addprefix $(ACE05_COMMS)/,$(subst .apf.xml,.comm,$(APF_XML_FILES)))

# Annotates all of the ACE 2005 data with Stanford tools and chunklink.pl.
.PHONY: ace05anno
ace05anno: $(addprefix $(ACE05_CHUNK)/,$(subst .apf.xml,.comm,$(APF_XML_FILES)))

.PHONY: ace05txt-ng14
ace05txt-ng14: $(addprefix $(ACE05_TXT_NG14)/,$(subst .apf.xml,.txt,$(APF_XML_FILES)))

.PHONY: ace05txt-pm13
ace05txt-pm13: $(addprefix $(ACE05_TXT_PM13)/,$(subst .apf.xml,.txt,$(APF_XML_FILES)))

.PHONY: ace05txt-ygd15-r11
ace05txt-ygd15-r11: $(addprefix $(ACE05_TXT_YGD15_R11)/,$(subst .apf.xml,.txt,$(APF_XML_FILES)))

.PHONY: ace05txt-ygd15-r32
ace05txt-ygd15-r32: $(addprefix $(ACE05_TXT_YGD15_R32)/,$(subst .apf.xml,.txt,$(APF_XML_FILES)))

# Split the annotated ACE Concrete files into domains.
.PHONY: ace05splits
ace05splits: $(LDC2006T06) ace05anno ace05txt-ng14 ace05txt-pm13 ace05txt-ygd15-r11 ace05txt-ygd15-r32
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_CHUNK) $(ACE05_SPLITS)/comms comm
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_TXT_NG14) $(ACE05_SPLITS)/txts-ng14 txt
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_TXT_PM13) $(ACE05_SPLITS)/txts-pm13 txt
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_TXT_YGD15_R11) $(ACE05_SPLITS)/txts-ygd15-r11 txt
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_TXT_YGD15_R32) $(ACE05_SPLITS)/txts-ygd15-r32 txt

# Count the number of training instances and relation labels.
.PHONY: ace05counts
ace05counts: ace05splits
	cat $(ACE05_SPLITS)/txts-ng14/bn+nw/*.txt | grep relLabels: | wc -l
	cat $(ACE05_SPLITS)/txts-ng14/bn+nw/*.txt | grep relLabels: | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/txts-pm13/bn+nw/*.txt | grep relLabels: | wc -l
	cat $(ACE05_SPLITS)/txts-pm13/bn+nw/*.txt | grep relLabels: | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/txts-ygd15-r11/bn+nw/*.txt | grep relLabels: | wc -l
	cat $(ACE05_SPLITS)/txts-ygd15-r11/bn+nw/*.txt | grep relLabels: | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/txts-ygd15-r32/bn+nw/*.txt | grep relLabels: | wc -l
	cat $(ACE05_SPLITS)/txts-ygd15-r32/bn+nw/*.txt | grep relLabels: | sort | uniq | wc -l

# Don't delete intermediate files.
.SECONDARY:

.SILENT: clean
.PHONY: clean
clean :
	-@rm -r $(ACE_OUT_DIR)
	-@rm -r $(SE_OUT_DIR)

