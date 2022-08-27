// Declare syntax version
nextflow.enable.dsl=2
// write description
println """
==== ====
this program will submit job to pbs.
add condition statement to the script.
collect output in a folder
==== ====
"""

// Script parameters
params.input = "/some/data/sample.fa"
params.option = 1
params.help = false

// help message
def helpMessage() {
log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run process_1.nf

    Mandatory arguments:
    --input       path to input file

    Optional arguments:
    --option    condition to check for process
    --help      This usage statement.
    """
}
// check params to print helpMessage and exit
if (params.help) {
    helpMessage()
    exit 0
}

// process definition
process base1 {
  input:
    path input
  output:
    path "output1"
  script:
  if ( params.option == 1 ) {
    """
    echo hello world > output1
    echo script loc dir: ${projectDir} >> output1
    echo launch dir: ${launchDir} >> output1
    """
  } else if ( params.option == 2 ) {
    """
    wc -l $input > output1
    """
  }
}

process uppercase {
  input:
    path input
  //output:
  //  path "output2"

    """
    awk '{print toupper(\$0)}' $input
    """
}

process multiInput {
  input:
    val x
    val y
  script:
    """
    echo $x and $y
    """
}

// declare channel and run workflow

input_ch = Channel.fromPath( 'data/script.pbs' )

workflow {
   base1(input_ch) | uppercase
}

/*
ch_num = Channel.of(1, 2)
ch_letters = Channel.of('a', 'b', 'c', 'd')

workflow {
  multiInput(ch_num, ch_letters)
}
*/