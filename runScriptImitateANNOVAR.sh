#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-v|--vcf-file)
		VCF="$2"
		shift
		shift
		;;
		-h|--help)
			echo "Usage: runScriptImitateAnnovar -v VCF-file [-h (help)]"
			exit 0
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}"

if [ -z $VCF ]
then
	echo "Please provide a VCF file with the -v or --vcf-file command"
	exit -1
elif [ ! -f $VCF ]
then
	echo " The provided VCF file does not exist"
	exit -2
fi

FUNC=$( gzip --test "$VCF" > /dev/null 2>&1 && echo "zgrep" || echo "grep" )

if [ $($FUNC -i -m 1 "fileformat=vcf" $VCF | wc -l) -eq 0 ]
then
	echo "The provided VCF file does not fit the requirements"
	exit -3
fi

(echo -e "Chr\tStart\tEnd\tRef\tAlt"; $FUNC -v "^#" $VCF | awk -F$'\t' -v OFS=$'\t' '{print $1,$2,$2,$4,$5}')

exit 0
