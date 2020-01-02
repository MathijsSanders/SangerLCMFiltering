#!/bin/bash

FT=4

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-a|--annotated-file)
		ANNOTATEDFILE="$2"
		shift
		shift
		;;
		-v|--vcf-file)
		VCFFILE="$2"
		shift
		shift
		;;
		-o|--output-directory)
		OUTPUT="$2"
		shift
		shift
		;;
		-p|--prefix)
		PREFIX="$2"
		shift
		shift
		;;
		-f|--fragment-threshold)
		FT="$2"
		shift
		shift
		;;
		-h|--help)
			echo "Usage: runScriptFiltering.sh -a ANNOTATED-file -v vcf-file -o OUTPUT-directory -p PREFIX [-f FRAGMENT_THRESHOLD (Default: 4)] [-h]"
			exit 0		
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}"

if [ -z $ANNOTATEDFILE ]
then
	echo "Please provide a file annotated with ANNOVAR, AnnotateBAMStatistics and AddtionalBAMStatistics"
	exit -1
elif [ ! -f $ANNOTATEDFILE ]
then
	echo "The provided annotated file does not exist"
	exit -1
fi

if [ -z $VCFFILE ]
then
	echo "Please provide the original VCF file"
	exit -4
elif [ ! -f $VCFFILE ]
then
	echo "The original VCF file does not exist"
	exit -4
fi

if [ -z $OUTPUT ]
then
	echo "Please provide an output directory"
	exit -2
fi

! mkdir -p $OUTPUT > /dev/null 2>&1 && echo "Could not create directory. Please provide a different location." && exit -2

if [ -z $PREFIX ]
then
	echo "Please provide a prefix"
	exit -3
fi

eval declare -A pos_array=($(head -1 $ANNOTATEDFILE | awk -F$'\t' 'BEGIN{counter=0;foundAnnot=0;foundAdd=0} {for(i=1;i<=NF;i++){if($i=="___" && !foundAnnot){printf "[\"%s\"]=\"%s\"\n","annot",i+1; foundAnnot++; counter++}else if($i=="Alternative_alignment" && !foundAdd){printf "[\"%s\"]=\"%s\"\n","add",i; foundAdd++; counter++};if(counter==2){exit 0}}} END{exit -1}'))

if [[ $? -ne 0 ]]
then
	echo 'Error: Could not find the correct columns in the provided annotated file'
	exit -4

fi

FUNC=$( gzip --test "$VCFFILE" > /dev/null 2>&1 && echo "zgrep" || echo "grep" )

$FUNC "^#" $VCFFILE | tee ${OUTPUT}/${PREFIX}_passed.vcf ${OUTPUT}/${PREFIX}_filtered.vcf > /dev/null

awk -F$'\t' -v PREFIX=${OUTPUT}/${PREFIX} -v FT=$FT -v ANNPOS=${pos_array["annot"]} -v ADDPOS=${pos_array["add"]} -v OFS=$'\t' 'FNR==NR{if($(ANNPOS+5) >= FT && $(ADDPOS+21) >= FT && (($(ADDPOS+13) == "NA" && $(ADDPOS+19) > 2) || ($(ADDPOS+18) == "NA" && $(ADDPOS+14) > 2) || (($(ADDPOS+11) > 1 && $(ADDPOS+14) > 2) || ($(ADDPOS+16) > 1 && $(ADDPOS+19) > 2))) && (($(ADDPOS+11) <= 1 && $(ADDPOS+16) > 1 && (($(ADDPOS+17)/$(ADDPOS+16)) <= 0.9 || ($(ADDPOS+18) > 0 && $(ADDPOS+19) >= 4))) || ($(ADDPOS+16) <= 1 && $(ADDPOS+11) > 1 && (($(ADDPOS+12)/$(ADDPOS+11))<=0.9 || ($(ADDPOS+13) > 0 && $(ADDPOS+14) >= 4))) || ($(ADDPOS+11) > 1 && $(ADDPOS+16) > 1 && (($(ADDPOS+12)/$(ADDPOS+11))<=0.9 || ($(ADDPOS+11) > 2 && $(ADDPOS+13) > 2) || ($(ADDPOS+16) > 1 && $(ADDPOS+19) > 10)) && (($(ADDPOS+17)/$(ADDPOS+16))<=0.9 || ($(ADDPOS+16) > 2 && $(ADDPOS+18)>2)|| ($(ADDPOS+11) > 1 && $(ADDPOS+14) > 10))))){a[$1"_"$2"_"$4"_"$5]++}} FNR!=NR{print >> ((a[$1"_"$2"_"$4"_"$5]) ? PREFIX"_passed.vcf" : PREFIX"_filtered.vcf")}' <(tail -n+2 $ANNOTATEDFILE) <($FUNC -v "^#" $VCFFILE)

exit
