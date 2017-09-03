# Makefile for creating Concrete ACE 2005 and SemEval datasets with
# annotations from Stanford and Chunklink.
#
# TODO: Change all concrete directories from "comms" to "concrete".
#

SHELL = /bin/bash
JAVAIN = export CLASSPATH=`mvn -f ./scripts/maven/pom-acere.xml exec:exec -q -Dexec.executable="echo" -Dexec.args="%classpath"` && java
JAVACS = export CLASSPATH=`mvn -f ./scripts/maven/pom-cs.xml exec:exec -q -Dexec.executable="echo" -Dexec.args="%classpath"` && java
JAVAPA = export CLASSPATH=`mvn -f ./scripts/maven/pom-pacaya.xml exec:exec -q -Dexec.executable="echo" -Dexec.args="%classpath"` && java
PYTHON = python
JAVAFLAGS = -ea

CONCRETE_CHUNKLINK=./concrete-chunklink

# Machine specific parameters.
ifeq ($(MACHINE),COE)
LDC_DIR=/export/common/data/corpora/LDC
OUT_DIR=~/corpora/processed/ace_05_concrete4.8
JAVAFLAGS = -ea -Xmx10000m -XX:-UseParallelGC -XX:-UseParNewGC -XX:+UseSerialGC
else ifeq ($(MACHINE),LOCAL)
LDC_DIR=/Users/mgormley/research/LDC
OUT_DIR=/Users/mgormley/research/corpora/processed/ace_05_concrete4.8
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
ACE05_JSON_NG14=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-json-ng14
ACE05_JSON_PM13=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-json-pm13
ACE05_JSON_YGD15_R11=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-json-ygd15-r11
ACE05_JSON_YGD15_R32=$(ACE_OUT_DIR)/ace-05-comms-ptb-anno-chunks-json-ygd15-r32
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
setup: $(CONCRETE_CHUNKLINK)
	$(JAVAIN) -version
	$(JAVACS) -version
	$(JAVAPA) -version

$(CONCRETE_CHUNKLINK):
	pip install --user 'concrete>=4.4.0,<4.8.0'
	git clone https://github.com/mgormley/concrete-chunklink.git $(CONCRETE_CHUNKLINK)
	cd $(CONCRETE_CHUNKLINK) && git checkout v0.2

# ----------------------------------------------------------------
# SemEval-2010 Task 8 Data
# ----------------------------------------------------------------

.PHONY: semevalanno
semevalanno: $(addprefix $(SE_CHUNK)/,$(notdir $(wildcard $(SE_COMMS)/*.concrete)))
# $(SE_CHUNK)/SemEval.test.ner.concrete $(SE_CHUNK)/SemEval.test.sst.concrete $(SE_CHUNK)/SemEval.train.ner.concrete $(SE_CHUNK)/SemEval.train.sst.concrete

# Converts the parses from concrete-stanford to chunks with concrete-chunklink.
$(SE_CHUNK)/%.concrete : $(SE_ANNO)/%.concrete $(CONCRETE_CHUNKLINK)
	mkdir -p $(SE_CHUNK)
	$(PYTHON) $(CONCRETE_CHUNKLINK)/concrete_chunklink/add_chunks.py --chunklink $(CONCRETE_CHUNKLINK)/scripts/chunklink_2-2-2000_for_conll.pl $< $@

# Annotates the SemEval data with concrete-stanford.
$(SE_ANNO)/%.concrete : $(SE_COMMS)/%.concrete
	mkdir -p $(SE_ANNO)
	$(JAVACS) $(JAVAFLAGS) edu.jhu.hlt.concrete.stanford.TextSpanMaker $< $@.tmp.concrete
	$(JAVACS) $(JAVAFLAGS) edu.jhu.hlt.concrete.stanford.AnnotateTokenizedConcrete $@.tmp.concrete $@

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
$(ACE05_COMMS)/%.concrete: $(LDC2006T06_EN_SYM)/%.apf.xml $(LDC2006T06_EN_SYM)/apf.v5.1.1.dtd
	mkdir -p $(ACE05_COMMS)
	$(JAVAIN) $(JAVAFLAGS) edu.jhu.hlt.concrete.ingesters.acere.AceApf2Concrete $< $@ 

# Annotates the ACE Communications with concrete-stanford.
$(ACE05_ANNO)/%.concrete : $(ACE05_COMMS)/%.concrete
	mkdir -p $(ACE05_ANNO)
	$(JAVACS) $(JAVAFLAGS) edu.jhu.hlt.concrete.stanford.AnnotateTokenizedConcrete $< $@

# Converts the parses from concrete-stanford to chunks with concrete-chunklink.
$(ACE05_CHUNK)/%.concrete : $(ACE05_ANNO)/%.concrete $(CONCRETE_CHUNKLINK)
	mkdir -p $(ACE05_CHUNK)
	$(PYTHON) $(CONCRETE_CHUNKLINK)/concrete_chunklink/add_chunks.py --chunklink $(CONCRETE_CHUNKLINK)/scripts/chunklink_2-2-2000_for_conll.pl $< $@

$(ACE05_JSON_NG14)/%.json : $(ACE05_CHUNK)/%.concrete
	mkdir -p $(ACE05_JSON_NG14)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut JSON \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles false \
		--maxInterveningEntities 3 \
		--removeEntityTypes true \
		--useRelationSubtype false

$(ACE05_JSON_PM13)/%.json : $(ACE05_CHUNK)/%.concrete
	mkdir -p $(ACE05_JSON_PM13)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut JSON \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles true \
		--maxInterveningEntities 3 \
		--removeEntityTypes true \
		--useRelationSubtype false

$(ACE05_JSON_YGD15_R11)/%.json : $(ACE05_CHUNK)/%.concrete
	mkdir -p $(ACE05_JSON_YGD15_R11)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut JSON \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles true \
		--maxInterveningEntities 9999 \
		--removeEntityTypes false \
		--useRelationSubtype false

$(ACE05_JSON_YGD15_R32)/%.json : $(ACE05_CHUNK)/%.concrete
	mkdir -p $(ACE05_JSON_YGD15_R32)
	$(JAVAPA) $(JAVAFLAGS) edu.jhu.nlp.data.simple.CorpusConverter \
		--train $< \
		--trainGoldOut $@ \
		--trainType CONCRETE \
		--trainTypeOut JSON \
		--makeRelSingletons true \
		--shuffle false \
		--mungeRelations true \
		--predictArgRoles true \
		--maxInterveningEntities 9999 \
		--removeEntityTypes false \
		--useRelationSubtype true

# Converts all the ACE 2005 data to Concrete Communications.
.PHONY: ace05comms
ace05comms: $(addprefix $(ACE05_COMMS)/,$(subst .apf.xml,.concrete,$(APF_XML_FILES)))

# Annotates all of the ACE 2005 data with Stanford tools and chunklink.pl.
.PHONY: ace05anno
ace05anno: $(addprefix $(ACE05_CHUNK)/,$(subst .apf.xml,.concrete,$(APF_XML_FILES)))

.PHONY: ace05json-ng14
ace05json-ng14: $(addprefix $(ACE05_JSON_NG14)/,$(subst .apf.xml,.json,$(APF_XML_FILES)))

.PHONY: ace05json-pm13
ace05json-pm13: $(addprefix $(ACE05_JSON_PM13)/,$(subst .apf.xml,.json,$(APF_XML_FILES)))

.PHONY: ace05json-ygd15-r11
ace05json-ygd15-r11: $(addprefix $(ACE05_JSON_YGD15_R11)/,$(subst .apf.xml,.json,$(APF_XML_FILES)))

.PHONY: ace05json-ygd15-r32
ace05json-ygd15-r32: $(addprefix $(ACE05_JSON_YGD15_R32)/,$(subst .apf.xml,.json,$(APF_XML_FILES)))

# Split the annotated ACE Concrete files into domains.
.PHONY: ace05splits
ace05splits: $(LDC2006T06) ace05anno ace05json-ng14 ace05json-pm13 ace05json-ygd15-r11 ace05json-ygd15-r32
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_CHUNK) $(ACE05_SPLITS)/comms concrete
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_JSON_NG14) $(ACE05_SPLITS)/json-ng14 json
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_JSON_PM13) $(ACE05_SPLITS)/json-pm13 json
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_JSON_YGD15_R11) $(ACE05_SPLITS)/json-ygd15-r11 json
	bash ./scripts/data/split_ace_dir.sh $(LDC2006T06) $(ACE05_JSON_YGD15_R32) $(ACE05_SPLITS)/json-ygd15-r32 json

# Count the number of training instances and relation labels.
.PHONY: ace05counts
ace05counts: #ace05splits
	cat $(ACE05_SPLITS)/json-ng14/bn+nw.json.gz | gunzip | grep relLabels | wc -l
	cat $(ACE05_SPLITS)/json-ng14/bn+nw.json.gz | gunzip | grep relLabels | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/json-ng14/bn+nw.json.gz | gunzip | grep nePairs | perl -pe "s/, Fancy/\nFancy/g" | perl -pe "s/.*entityType=(\S+), entitySubType=(\S+),.*/\1 \2/g" | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/json-pm13/bn+nw.json.gz | gunzip | grep relLabels | wc -l
	cat $(ACE05_SPLITS)/json-pm13/bn+nw.json.gz | gunzip | grep relLabels | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/json-pm13/bn+nw.json.gz | gunzip | grep nePairs | perl -pe "s/, Fancy/\nFancy/g" | perl -pe "s/.*entityType=(\S+), entitySubType=(\S+),.*/\1 \2/g" | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/json-ygd15-r11/bn+nw.json.gz | gunzip | grep relLabels | wc -l
	cat $(ACE05_SPLITS)/json-ygd15-r11/bn+nw.json.gz | gunzip | grep relLabels | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/json-ygd15-r11/bn+nw.json.gz | gunzip | grep nePairs | perl -pe "s/, Fancy/\nFancy/g" | perl -pe "s/.*entityType=(\S+), entitySubType=(\S+),.*/\1 \2/g" | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/json-ygd15-r32/bn+nw.json.gz | gunzip | grep relLabels | wc -l
	cat $(ACE05_SPLITS)/json-ygd15-r32/bn+nw.json.gz | gunzip | grep relLabels | sort | uniq | wc -l
	cat $(ACE05_SPLITS)/json-ygd15-r32/bn+nw.json.gz | gunzip | grep nePairs | perl -pe "s/, Fancy/\nFancy/g" | perl -pe "s/.*entityType=(\S+), entitySubType=(\S+),.*/\1 \2/g" | sort | uniq | wc -l

# Don't delete intermediate files.
.SECONDARY:

.SILENT: clean
.PHONY: clean
clean :
	-@rm -r $(ACE_OUT_DIR)
	-@rm -r $(SE_OUT_DIR)

