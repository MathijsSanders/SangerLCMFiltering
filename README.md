# LCM filtering pipeline

This repository contains the complete pipeline for filtering variants called by CaVEMan (available in the Docker container at: https://quay.io/repository/wtsicgp/dockstore-cgpwgs) in the context of laser capture microdissection experiments.  

## How do I run it?

AdditionalBAMStatistics is a precompiled multi-threaded JAVA package that amends ANNOVAR files with useful statistics for filtering variants. There are three simple ways of installing AdditionalBAMStatistics.

### Recommendation - SNP database

AdditionalBAMStatistics is able to make use of SNP databases to mark reads with too many mismatches not reported as known SNPs. This statistics is especially informative in the context of cross-species contamination or false positive variants that derive from extremely homologous regions.

The following command downloads a database for common SNPs for hg19/GRCh37:

```bash
wget -q ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh37p13/VCF/common_all_20180423.vcf.gz
```

### Necessary - Indexed reference genome

Please make sure that the reference genome is indexed by SAMtools. If not, please run the following command:

```bash
samtools faidx <reference_FASTA_file>
```

### 1. The easiest way - Singularity container

#### Requirements

- Singularity
- Indexed reference FASTA file

#### Run information

The JAVA package has been incorporated into a Singularity container available from Singularity hub. In case singularity is installed, simply run:

```bash
singularity pull shub://MathijsSanders/AnnotateBAMStatisticsSingularity
```

 Still requires that the reference genome is indexed!

This includes:

- AdditionalBAMStatistics
- SAMtools

The following parameters are available:

Parameter | Description
--- | ---
-a/--annovarfile* | The ANNOVAR file to be further annotated.
-b/--bamfile* | The corresponding BAM files of the sample of interest.
-r/--reference* | The indexed reference FASTA file used for alignment.
-o/--output-file | Output file for writing the results (Default: standard out).
-s/--snp-database | SNP database for annotating reads with too many mismatches not reported as SNPs (Either vcf or vcf.gz).
-m/--max-non-snp | The maximum number of mismatched not reported as SNP before a read is marked as having too many mutations (Default: 2).
-d/--diff-alignment-score | The difference between the current and alternative alignment score before a read is considered multi-mappable (Default: 5).
-t/--threads | Number of threads to use (Default: 1).
-c/--current-heapsize | The maximum heap size JAVA can use (Default: 10G). This threshold should be increased in case a larger SNP database is used.
-h/--help | Help information.
\* | Required.

### 2. The easy way - Use precompiled JAR file

#### Requirements

- JAVA JDK 11+
- SAMtools
- Indexed reference FASTA file

#### Run information

Simply run the following command to download the repository:

```bash
git clone https://github.com/MathijsSanders/AdditionalBAMStatistics.git
```

Run the following command to start annotating the ANNOVAR file:

```bash
java -Xmx10G -jar additionalBamStatistics.jar --input-annovar-file <annovar_file> --input-bam-file <bam_file> --reference <reference_file> --output-file <output_file> --snp-database <snp_database> --max-non-snp <max_non_snp> --difference-alignment-scores <diff_scores> --threads <threads> --help --version
```

Parameter | Description
--- | ---
--input-annovar-file* | The ANNOVAR file to be further annotated.
--input-bam-file* | The corresponding BAM files of the sample of interest.
--reference* | The indexed reference FASTA file used for alignment.
--output-file | Output file for writing the results (Default: standard out).
--snp-database | SNP database for annotating reads with too many mismatches not reported as SNPs (Either vcf or vcf.gz)
--max-non-snp | The maximum number of mismatched not reported as SNP before a read is marked as having too many mutations (Default: 2).
--difference-alignment-score | The difference between the current and alternative alignment score before a read is considered multi-mappable (Default: 5).
--threads | Number of threads to use (Default: 1).
--help | Help information.
--version | Version information.
\* | Required.

### 3. The difficult way - Compile package

#### Requirements

- Maven version 3+ (For compiling only).
- Java JDK 11+

#### Run information

The precompiled JAR file is included with the repository, but in case the package needs to be recompiled, please run:

```bash
mvn package clean
```

Once the JAR file is compiled please follow the JAR-specific instructions listed under **point 2**.
