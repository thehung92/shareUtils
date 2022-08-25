# convert output of ms program to vcf format

## description

This Rscript program take input as the output of ms program and convert them to vcf. This will only accept ms program with even number of sequence generated for each repetition. Assuming 2 consecutive sequences belong to 1 sample.

If fasta is not provided, the ref allele are simulated with sampling from A,T,C,G. The alternate allele are cycled: G,A,T,C

If fasta is provided, the ref allele are extracted from fasta file using bedtools. Because there might be case with no ref allele: A,T,C,G,N. The alternate allele are match with T,C,G,A,A

Output is compressed to .vcf.gz and tabix index. Output is written to your working dir if not specified

## requirement

you can download this script from github with

```shell
git clone https://github.com/thehung92/shareUtils.git
cd shareUtils/ms2
```

This script is written in R 4.1.2 with the following required library that you need to install before running

```r
packages <- c("tidyverse",
              "data.table",
              "argparse")
# can be install with
install.packages(packages)
```


you must have 'tabix' and 'bgzip' installed on your system and available in your $PATH. Meaning you can call them directly with:

```shell
tabix --help
bgzip --help
```

if you want to extract reference allele from fasta file, you also have to install bedtools and be able to call it directly from your terminal, or provide the path to your bedtools in line 2 of the script

```shell
bedtools --help
```

## example

1  output from ms program is provided in example dir

```shell
# the output.ms in the example is generated with the following command
# $ms 100 1 -t 100 -eN 0.3 0.5 -eG 0.3 7.0 > example/output.ms
# read help of the program to see all the options
Rscript ms2vcf.R --help

# usage: ms2vcf.R [-h] [-f [FA]] [-r chr:beg-end] [-p [PREFIX]] [file ...]

# convert output from ms program with even number of haplotypes to vcf genotype.
# Assuming 2 consecutive haplotype belong to 1 sample

# positional arguments:
#   file                  input file path or read input from stdin

# optional arguments:
#   -h, --help            show this help message and exit
#   -f [FA], --fasta [FA]
#                         reference genome file path [fasta]
#   -r chr:beg-end, --region chr:beg-end
#                         region to simulate, default to "1:2E7-3E7". chr-beg-
#                         end is parsed with parse_number
#   -p [PREFIX], --prefix [PREFIX]
#                         output file name prefix, default to "sim_pop"

# an example of converting the ms sequence to vcf region: chromosome 2, start 30 000 000, end 40 000 000. and write vcf.gz file with prefix my_sim_pop in example folder
Rscript ms2vcf.R -r 2:3E7-4E7 -p example/my_sim_pop example/output.ms

```