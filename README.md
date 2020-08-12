# LCM filtering pipeline

This repository contains the complete pipeline for filtering variants called by CaVEMan (available as a Docker container at: https://quay.io/repository/wtsicgp/dockstore-cgpwgs) in the context of laser capture microdissection experiments. Input VCF files are annotated with useful read or fragment derived statistics for additional filtering based on user preferences. The default values currently set are those commonly used for LCM experiments. 

## How do I run it?

The LCM filtering pipeline comprises separate components pieced together to remove most common artefacts. There are two ways of getting the pipeline setup for use.

### Necessary - Indexed reference genome

Please make sure that the reference genome is indexed by SAMtools. If not, please run the following command:

```bash
samtools faidx <reference_FASTA_file>
```

### Recommendation - SNP database

AdditionalBAMStatistics, a component of the LCM filtering pipeline, is able to make use of SNP databases to mark reads with too many mismatches not reported as known SNPs. This statistics is especially informative in the context of cross-species contamination or false positive variants that derive from extremely homologous regions.

The following command downloads a database for common SNPs for hg19/GRCh37:

```bash
wget -q ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh37p13/VCF/common_all_20180423.vcf.gz
```

### Note - Installation ANNOVAR

ANNOVAR is a software tool to functionally annotate called variants (http://annovar.openbioinformatics.org/). Due to registration requirements this tool is not included in this repository. Installing this software tool separately adds informative annotation to the called variants. However, a shell script is included to transform a VCF file to standard ANNOVAR output for further processing and filtering purposes.

### 1. The easy way - Singularity container

#### Requirements

- Singularity
- Indexed reference FASTA file

#### Run information

The complete pipeline has been installed in a Singularity container. Please run the following:

```bash
singularity pull shub://MathijsSanders/SangerLCMFiltering
```

This includes the following apps:

- preselect 
- imitateANNOVAR
- annotateBAMStatistics
- additionalBAMStatistics
- filtering

**preselect**

The following parameters are available:

Parameter | Description
--- | ---
-v/--vcf-file* | Input VCF file (either vcf or vcf.gz)
-d/--deactivate-pass | Do not filter variants based of the 'PASS' flag (Default: variants filtered on PASS)
-a/--asmd | ASMD score (CaVEMan) threshold (Default: 140)
-c/--clpm | CLPM score (CaVEMan) threshold (Default: 0)
-h/--help | Help information
\* | Required

Filtering on ASMD and CLPM is skipped when this information is absent from the VCF file.

**imitateANNOVAR**

The following parameters are available:

Parameter | Description
--- | ---
-v/--vcf-file* | Input VCF file (either vcf or vcf.gz)
-h/--help | Help information
\* | Required

**annotateBAMStatistics**

The following parameters are available:

Parameter | Description
--- | ---
-a/--annovarfile* | Input ANNOVAR file
-b/--bamfiles* | Comma-separated list of BAM files (e.g. sample1.bam,sample2.bam)
-t/--threads | Number of threads
-m/--min-alignment-score | Minimum alignment score threshold for considering read/fragments as high quality (Default: 40)
-h/--help | Help information
\* | Required.

**additionalBAMStatistics**

The following parameters are available:

Parameter | Description
--- | ---
-a/--annovarfile* | Input ANNOVAR file for further annotation
-b/--bamfile* | BAM file of the sample of interest
-r/--reference* | The indexed reference FASTA file used for alignment
-o/--output-file | Output file for writing the results (Default: standard out)
-s/--snp-database | SNP database for annotating reads with too many mismatches not reported as SNPs (Either vcf or vcf.gz)
-m/--max-non-snp | The maximum number of mismatched not reported as SNP before a read is marked as having too many mutations (Default: 2)
-d/--diff-alignment-score | The difference between the current and alternative alignment score before a read is considered multi-mappable (Default: 5)
-t/--threads | Number of threads to use (Default: 1).
-c/--current-heapsize | The maximum heap size JAVA can use (Default: 10G). This threshold should be increased in case a larger SNP database is used.
-h/--help | Help information.
\* | Required.

**filtering**

The following parameters are available:

Parameter | Description
--- | ---
-a/--annotated-file* | Input ANNOVAR file annotated by AnnotateBAMStatistics and AdditionalBAMStatistics
-v/--vcf-file* | Original VCF file after running the preselect step
-o/--output-dir* | Output directory for writing the results
-p/--prefix* | Prefix for output files (Suggestion: Sample identifier or other useful information)
-f/--fragment-threshold | Fragment threshold use for filtering (Default: 4). Decrease in the context of low coverage or small clones. Lowering will result in the inclusion of more artefacts.
-h/--help | Help information.
\* | Required.

**Running the pipeline from A-to-Z:**

Please bind the appropriate directories to become available in the Singularity container (e.g., location of the VCF files or BAM files).

**preselect**

```bash
singularity run --bind /nfs,/lustre --app preselect SangerLCMFilteringSingularity_latest.sif -v Input_VCF > Filtered_VCF
```

**imitateANNOVAR**

```bash
singularity run --bind /nfs,/lustre --app imitateANNOVAR SangerLCMFilteringSingularity_latest.sif -v Filtered_VCF > ANNOVAR_FILE
```

**annotateBAMStatistics**

```bash
singularity run --bind /nfs,/lustre --app annotateBAMStatistics SangerLCMFilteringSingularity_latest.sif -a ANNOVAR_FILE -b COMMA_SEPARATED_BAM_FILES -t THREADS > ANNOTATED_ANNOVAR_FILE
```

**additionalBAMStatistics**

```bash
singularity run --bind /nfs,/lustre --app additionalBAMStatistics SangerLCMFilteringSingularity_latest.sif -a ANNOTATED_ANNOVAR_FILE -b BAM_FILE -t THREADS -r REFERENCE_FASTA_FILE -s SNP_DATABASE > FULLY_ANNOTATED_ANNOVAR_FILE
```

**filtering**

```bash
singularity run --bind /nfs,/lustre --app filtering SangerLCMFilteringSingularity_latest.sif -a FULLY_ANNOTATED_ANNOVAR_FILE -v ORIGINAL_VCF_FILE -o OUTPUT_DIRECTORY -p NAME_PREFIX
```

**Results**

The output directory will contain 2 file:

- ${PREFIX}\_passed.txt: VCF file containing all variants that passed filtering.
- ${PREFIX}\_filtered.txt: VCF file containg all filtered variants.

### 2. The difficult way - Compile AnnotateBAMStatistics & AdditionalBAMStatistics and run the scripts manually

#### Requirements

- gcc/g++ 4.5+
- JAVA JDK 11+
- SAMtools
- Indexed reference FASTA file

#### Run information

Please follow the following compilation tutorials listed at:

- AnnotateBAMStatistics (https://github.com/MathijsSanders/AnnotateBAMStatistics)
- AddtionalBAMStatistics (https://github.com/MathijsSanders/AdditionalBAMStatistics)

**preselect**

```bash
./runScriptPreselect.sh -v Input_VCF > Filtered_VCF
```

**imitateANNOVAR**

```bash
./runScriptImitateANNOVAR.sh -v Filtered_VCF > ANNOVAR_FILE
```

**annotateBAMStatistics**

```bash
AnnotateBAMStatistics -a ANNOVAR_FILE -b COMMA_SEPARATED_LIST_BAM_FILES --pileup-regions -t threads > ANNOTATED_ANNOVAR_FILE
```

**additionalBAMStatistics**

```bash
java -Xmx10G -jar additionalBAMStatistics.jar --input-annovar-file ANNOTATED_ANNOVAR_FILE --input-bam-file BAM_FILE --reference REFERENCE_FASTA_FILE --snp-database SNP_DATABASE --max-non-snp MAX_NON_SNP --difference-alignment-scores DIFFERENCE_ALIGNMENT_SCORES --threads threads > FULLY_ANNOTATED_ANNOVAR_FILE
```

**filtering**

```bash
./runScriptFiltering -a FULLY_ANNOTATED_ANNOVAR_FILE -v ORIGINAL_VCF_FILE -o OUTPUT_DIRECTORY -p NAME_PREFIX
```
