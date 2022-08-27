#!/usr/bin/env Rscript
# packages
packages <- c("tidyverse",
              "data.table",
              "janitor",
              "openxlsx",
              "argparse")
# load library quietly and stop if library can not be loaded
for (package in packages) {
  if (suppressPackageStartupMessages(require(package, character.only=TRUE))) {
  } else {
    stop("install required packages before running script")
  }
}
# parse arg from command line
parser <- ArgumentParser(description="parse arg from command line")
parser$add_argument("file", nargs="*",
                    help="input file path")
parser$add_argument("-x", "--action", action="store_true", default=FALSE,
                    help="condition of action, default to false")
# use arg in the main function
main <- function() {
	args <- parser$parse_args()
	# check args for path
	filenames <- args$file
	if (!args$action) {
		process(getwd())
	} else {
		for (filename in filenames) {
			process(filename)
		}
	}
}
# sub-process of the main function
process <- function(filename) {
	# 
}

# execute the main function
main()