#!/bin/bash

machine="$1"
branch="$2"
duration="$3"
queue="$4"
run_tests="$5"

if [ -z "$machine" ]; then
    echo "ERROR: Machine must be specified!" 1>&2
    exit 1
fi

if [ -z "$branch" ]; then
    branch='master'
fi

if [ -z "$duration" ]; then
    duration=1h
fi

REPO_URL='https://github.com/WOnder93/argon2.git'

dest_dir="$(pwd)"

task_file="$(mktemp)"

cat >$task_file <<EOF
#!/bin/bash
#PBS -N argon2-cpu-$machine-$branch
#PBS -l walltime=$duration
#PBS -l nodes=1:ppn=16:cl_$machine
#PBS -l mem=16gb
$(if [ -n "$queue" ]; then echo "#PBS -q $queue"; fi)

module add cmake-3.6.1

mkdir -p "$dest_dir/\$PBS_JOBID" || exit 1

cd "$dest_dir/\$PBS_JOBID" || exit 1

git clone "$REPO_URL" argon2 || exit 1

cd argon2 || exit 1

git checkout "$branch" || exit 1

(autoreconf -i && ./configure && make) || exit 1

if [ "$run_tests" == "yes" ]; then
    make check
fi

bash scripts/run-benchmark.sh >"$dest_dir/\$PBS_JOBID/benchmark-$machine-$branch.csv"
EOF

qsub "$task_file"

rm -f "$task_file"