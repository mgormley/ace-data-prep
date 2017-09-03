# A script for splitting a directory of ACE 2005 Concrete files into
# domains and dev/test splits.
#
# This script must be run from the root of the project since it
# expects to find the files: ./config/pm13_folds/bc{0,1}.files.
#

set -x 
set -e
set -u # Fail if variables are not set.

ACE_DIR=$1 # The ACE LDC directory. ~/research/corpora/LDC/LDC2006T06
IN_DIR=$2 # The directory to split: e.g. ~/research/corpora/processed/ace_05_concrete4.3
OUT_DIR=$3 # The output directory. e.g. ./tmp/
SUFFIX=$4 # The suffix of the input files.

ACE_EN_DIR=$ACE_DIR/data/English

mkdir -p $OUT_DIR

# Domains: bc  bn  cts nw  un  wl
for FILESET in bn nw bc cts un wl
do
    # Find the adjudicated files for the given domain, strips the .sgm
    # suffix and the directory prefix.
    find $ACE_EN_DIR -name "*.sgm" | grep "/$FILESET/adj/" | sed -e "s/.sgm$//" | sed 's|^.*/||g' | sort > $OUT_DIR/$FILESET.files
done

# Create bn+nw training set.
cat $OUT_DIR/bn.files $OUT_DIR/nw.files | sort > $OUT_DIR/bn+nw.files

# Plank & Moschitti (2013) dev/test split:
comm -1 -2 ./config/pm13_folds/bc0.files $OUT_DIR/bc.files | sort > $OUT_DIR/bc_dev.files
comm -1 -2 ./config/pm13_folds/bc1.files $OUT_DIR/bc.files | sort > $OUT_DIR/bc_test.files

# Everything except bc_test.
cat $OUT_DIR/{bc_dev,bn,cts,nw,un,wl}.files | sort > $OUT_DIR/all_nobctest.files

# Everything.
cat $OUT_DIR/{bc,bn,cts,nw,un,wl}.files | sort > $OUT_DIR/all.files

for FILESET in bn+nw bc_dev bc_test bn nw bc cts un wl all_nobctest all
do 
    FILELIST=$OUT_DIR/$FILESET.files
    ABS_FILELIST=$FILELIST.abs
    # Prepends the IN_DIR and appends ${SUFFIX}.
    cat $FILELIST | awk "\$0=\"${IN_DIR}/\"\$0\".${SUFFIX}\"" > $ABS_FILELIST

    if [[ $SUFFIX = "json" ]]; then
        cat $ABS_FILELIST | xargs cat | gzip > $OUT_DIR/$FILESET.json.gz
    else
	SET_DIR=$OUT_DIR/$FILESET
	rm -r $SET_DIR || true
	mkdir -p $SET_DIR
	# Copies each file in to the SET_DIR.
	cat $ABS_FILELIST | xargs -n 1 -I % cp % $SET_DIR/
	ls $SET_DIR | wc -l
    fi
done

wc -l $OUT_DIR/*.files


