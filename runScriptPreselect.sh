#!/bin/bash

ASMD=140
CLPM=0
DPASS=false
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
		-d|--deactivate-pass)
		DPASS=true
		shift
		shift
		;;
		-a|--asmd)
		ASMD="$2"
		shift
		shift
		;;
		-c|--clpm)
		CLPM="$2"
		shift
		shift
		;;
		-h|--help)
			echo "Usage: runScriptPreselect.sh -v VCF-file [-d -a ASMD_threshold -c CLPM_threshold]"
			exit 0
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}"

regex='^[0-9]+$'

FUNC=$( gzip --test "$VCF" > /dev/null 2>&1 && echo "zgrep" || echo "grep" )

if [ -z $VCF ]
then
	echo "Please provide a VCF file with the -v or --vcf-file command"
	exit -1
elif [ ! -f $VCF ]
then
	echo "The provided VCF files does not exist"
	exit -2
elif [ $($FUNC -i -m 1 "fileformat=vcf" $VCF | wc -l) -eq 0 ]
then
	echo "The provided VCF file is incorrectly formatted"
	exit -3
fi

if ! [[ $ASMD =~ $regex ]]
then
	echo "Please provide a positive integer as ASMD threshold"
	exit -4
fi

if ! [[ $CLPM =~ $regex ]]
then
	echo "Please provide a positive integer as CLPM threshold"
	exit -5
fi

PRESENT=$( $FUNC -P 'CLPM|ASMD' $VCF | wc -l )

($FUNC '^#' $VCF; $FUNC $( [[ "$DPASS" = true ]] && echo '.*' || echo 'PASS') $VCF | awk -F$'\t' -v CLPM=$CLPM -v ASMD=$ASMD -v PRESENT=$PRESENT '(PRESENT > 0){split($0,a,"\t"); n=split(a[8],b,";"); for(i=1; i<=n; i++){if(b[i]~/CLPM/){split(b[i],c,"=")}else if(b[i]~/ASMD/){split(b[i],d,"=")}}; if(c[2] == CLPM && d[2] >= ASMD){print}} (PRESENT == 0){print}')

exit 0
