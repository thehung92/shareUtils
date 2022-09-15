pbs_gen () {
jobName=${1:-defaultName}
node=${2:-1}
ncpus=${3:-1}
time=${4:-"01:00:00"}
# check if the file exist
if [ ! -f "$jobName" ]; then
    echo "function require a file" >&2
    return 1
fi
# main
echo "==== start of script ===="
printf "#PBS -N ${jobName}
#PBS -l select=${node}:ncpus=${ncpus}
#PBS -l walltime=${time}
#PBS -q normal
#PBS -j oe
#PBS -o logs/${jobName}.pbs.log
#PBS -P 12000454
cd \$PBS_O_WORKDIR
date
mkdir -p logs
####
`tail -n +2 ${jobName}`
" | tee ${jobName}.pbs
echo "==== end of script ===="
# confirm
read -p "submit the job now?[y|n] : "
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    return 1
fi
# submit
echo qsub ${jobName}.pbs
qsub ${jobName}.pbs
}
# file still work as a bash script
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    pbs_gen $@
fi