#!/usr/bin/env Rscript
PATH_PROGRAM="/Users/hung/miniconda/envs/biotools/bin"
# packages
packages <- c("tidyverse",
              "data.table",
              "argparse")
# load library quietly and stop if library can not be loaded
for (package in packages) {
  if (suppressPackageStartupMessages(require(package, character.only=TRUE))) {
  } else {
    stop("install required packages before running script")
  }
}
# parse arg from command line
parser <- ArgumentParser(description="convert output from ms program with even number of haplotypes to vcf genotype. Assuming 2 consecutive haplotype belong to 1 sample")
parser$add_argument("file", nargs="*",
                    help="input file path or read input from stdin")
parser$add_argument("-f", "--fasta", nargs="?", metavar="FA",
                    help="reference genome file path [fasta]")
parser$add_argument("-r", "--region", nargs=1, metavar="chr:beg-end",default="1:2E7-3E7",
                    help="region to simulate, default to \"%(default)s\". chr-beg-end is parsed with parse_number")
parser$add_argument("-p", "--prefix", nargs="?",
                    help="output file name prefix, default to \"stdout\"")
# create args in the global env for use with many function
# debug: args <- parser$parse_args(c("--region", "2:3E7-4E7", "example/output.ms"))
args <- parser$parse_args()
fasta <- args$fasta
fai <- paste0(args$fasta, ".fai")
filename <- args$file
region <- args$region
prefix <- args$prefix
df.region <- str_split(region, ":|-", simplify = TRUE) %>% as.data.frame()
colnames(df.region) <- c("chr", "beg", "end")
df.region <- df.region %>%
  mutate_at(c("beg", "end"), as.numeric) %>%
  mutate(len=end-beg)
#### check the requirement of the program before doing anything ####
if (length(fasta)==0) {
  requires <- c("tabix", "bgzip")
} else {
  # if fasta is provided, check bedtools program existence
  requires <- c("tabix", "bgzip", "bedtools")
}

for (require in requires){
  # check if path to program exist
  if (dir.exists(PATH_PROGRAM)) {
    PREFIX=paste0("export PATH=$PATH:", PATH_PROGRAM, " &&")
    
  } else {
    message("PATH_PROGRAM do not exist in your system")
    PREFIX=""
  }
  #
  COMMAND=paste(PREFIX, "command -v", require, "&> /dev/null ; echo $?")
  status <- system(COMMAND, intern=TRUE)
  if (status!="0") {
    stop(cat(paste(require, "do not exist in your system."),
             "Install it and make sure you can call them directly from terminal before continue.",
             "Or add the path to the folder where you install them to line 2 of this script",
             'example: PATH_PROGRAM="/Users/hung/miniconda/envs/biotools/bin"',
             sep="\n"))
  }
}
#### use args in the main function #####
main <- function() {
	# check input option arg and read geno matrix
	if (length(filename) == 0) {
		ls.df.vcf <- read_geno_matrix(file("stdin"))
	} else {
	  ls.df.vcf <- read_geno_matrix(filename)
	}
  # simulate ref or extract from fasta
  if (length(fasta)==0){
    ls.df.vcf2 <- lapply(ls.df.vcf, simulate_ref)
  } else {
    if ( file.exists(fasta) & file.exists(fai) ) {
      # extract info from ref
      ls.df.vcf2 <- lapply(ls.df.vcf, extract_ref)
    } else {
      stop("reference file or fai file do not exist")
    }
  }
  # write to std out or write file with prefix
  if (length(prefix)==0) {
    # write to stdout if there is only 1 vcf
    if (length(ls.df.vcf2)==1) {
      write_vcf(ls.df.vcf[[1]], prefix=stdout())
    } else {
      stop("there are multiple repetition in ms output. Should define a prefix to write to files")
    }
  } else {
    for (i in 1:length(ls.df.vcf2)) {
      df.vcf <- ls.df.vcf2[[i]]
      prefix <- paste(prefix, i, sep="_")
      write_vcf(df.vcf, prefix)
    }
    cat(paste("vcf file written with prefix:", prefix), file=stderr())
  }
  # report none
}
#### sub-process: read geno matrix from the ms output #####
read_geno_matrix <- function(filename) {
  # read ms output as an object
  vt.ms <- read_lines(filename, skip_empty_rows = TRUE)
  # check if ms command generate even number of sequence
  nseq <- str_extract(vt.ms[1], "(?<=ms )\\d+") %>% parse_number()
  if (nseq %% 2 ==0) {} else {
    stop("this is not output of ms that specified even number of haplotype")
  }
  # parse content and assign to list in case of multiple repetition
  ls.df.vcf <- list()
  index.sample <- grep("//", vt.ms) # get index of pattern "//" that mark sample
  for (i in 1:length(index.sample)) {
    # get vector based on line # in case of multiple repetition
    if (i < length(index.sample)) {
      vt.content <- vt.ms[index.sample[i]:(index.sample[i+1]-1)]  
    } else {
      vt.content <- vt.ms[index.sample[i]:length(vt.ms)]  
    }
    # add control flow if there are no variants
    if (any(grepl("segsites: 0", vt.content))) {
      # no matrix # write only header
      write_lines(header, OUTPUT)
    } else {
      # get line of relative position
      vt.pos <- vt.content[grep("^pos", vt.content)] %>%
        trimws() %>% str_split(., " ", simplify = TRUE) %>% .[-1] %>%
        as.numeric()
      vt.bp <- df.region$beg + df.region$len*vt.pos
      # parse the matrix assuming 2 consecutive sequence belong to 1 individual
      mat.geno <- vt.content[grep("^0|^1", vt.content)] %>%
        str_split(., "") %>%
        do.call(rbind, .) %>%
        t() %>% as.data.frame()
      mat.geno <- mapply(function(...){paste(...,sep="|")}, mat.geno[,c(TRUE,FALSE)], mat.geno[,c(FALSE,TRUE)])
      colnames(mat.geno) <- paste0("S", 1:ncol(mat.geno))
      df.vcf <- tibble(`#CHROM`=df.region$chr,
                       POS=vt.bp,
                       ID=".",
                       REF=".",
                       ALT=".",
                       QUAL=".",
                       FILTER=".",
                       INFO=".",
                       FORMAT="GT")
      df.vcf <- bind_cols(df.vcf, mat.geno)
      ls.df.vcf[[i]] <- df.vcf
    }
  }
  return(ls.df.vcf)
}
#### simulate ref ####
simulate_ref <- function(df.vcf) {
  # sim
  atcg <- c("A", "T", "C", "G")
  set.seed("1234")
  vt.ref <- sample(atcg, size=nrow(df.vcf), replace=TRUE)
  # swap alternate
  df.swap <- data.frame(REF=atcg, ALT=lag(atcg, default="G"))
  vt.alt <- left_join(data.frame(REF=vt.ref), df.swap, by="REF") %>% pull(ALT)
  df.vcf$REF <- vt.ref
  df.vcf$ALT <- vt.alt
  return(df.vcf)
}
#### extract from fasta ####
extract_ref <- function(df.vcf) {
  # extract ref from fasta
  df.bed <- df.vcf[,1:2] %>%
    mutate(BEG=POS-1) %>%
    select(1,3,2)
  dir.create("temp", showWarnings = FALSE)
  BED=paste0("temp/", prefix, ".bed")
  fwrite(df.bed, BED, sep="\t", col.names = FALSE)
  # extract REF with bedtools getfasta # debug with zprofile
  COMMAND=paste(PREFIX, "bedtools getfasta -fi", fasta, "-bed", BED, "-bedOut")
  vt.ref <- system(COMMAND, intern = TRUE, ignore.stderr = TRUE) %>%
    gsub(".*\t", "", .)
  # sim alt
  atcgn <- c("A", "T", "C", "G", "N")
  tcgaa <- c("T", "C", "G", "A", "A")
  df.swap <- data.frame(REF=atcgn, ALT=tcgaa)
  vt.alt <- left_join(data.frame(REF=vt.ref), df.swap, by="REF") %>% pull(ALT)
  df.vcf$REF <- vt.ref
  df.vcf$ALT <- vt.alt
  return(df.vcf)
}
#### write vcf ####
write_vcf <- function(df.vcf, prefix) {
  header <- c('##fileformat=VCFv4.2',
              '##reference=human_g1k_v37_decoy.fasta',
              '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">')
  # get connection
  if (any(class(prefix) == 'terminal')) {
    OUTPUT=prefix
    write_lines(header, OUTPUT)
    try(write_delim(df.vcf, OUTPUT, delim="\t", append=FALSE, col_names = TRUE, quote="none"), silent=TRUE)
  } else {
    OUTPUT=paste0(prefix, ".vcf")
    # extract genotype matrix and write vcf with header # add check if
    write_lines(header, OUTPUT)
    fwrite(df.vcf, OUTPUT, append = TRUE, sep="\t", quote=FALSE, col.names = TRUE)
    system(paste("bgzip", OUTPUT))
    system(paste0("tabix -p vcf ", OUTPUT, ".gz"))
  }
}
#### debug ####

# execute the main function
main()