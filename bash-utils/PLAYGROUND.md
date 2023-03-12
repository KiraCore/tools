## Useful Scripts

### Benchmarking Hash Algorithms

```bash
# hashBenchmark "sha256sum" 1000000
# hashBenchmark "md5sum" 1000000
# hashBenchmark "cksum" 1000000
# hashBenchmark "xxhsum" 1000000
function hashBenchmark() {
  hash_algorithm=$1
  num_iterations=$2
  [ -z "$num_iterations" ] && num_iterations=1000

  echoInfo "INFO: Please, wait benchmarking $1 started..."
  file=/tmp/hashBenchmark.tmp
  head -c 1024 /dev/urandom > $file

  start_time=$(date +%s%N)
  for i in $(seq 1 $num_iterations); do
    $hash_algorithm $file > /dev/null
  done
  end_time=$(date +%s%N)

  total_time=$((end_time - start_time))
  avg_time=$((total_time / num_iterations))

  hashes_per_sec=$(bc -l <<< "$num_iterations / ($total_time / 1000000000)")
  echoInfo "INFO: Hashes per second: $hashes_per_sec"
}

commandBench "globName test_VariaBle"
function commandBench() {
  command=$1
  num_iterations=$2
  [ -z "$num_iterations" ] && num_iterations=1000

  start_time=$(date +%s%N)
  for i in $(seq 1 $num_iterations); do
    eval "$command" > /dev/null
  done
  end_time=$(date +%s%N)

  total_time=$((end_time - start_time))
  avg_time=$((total_time / num_iterations))

  hashes_per_sec=$(bc -l <<< "$num_iterations / ($total_time / 1000000000)")
  echoInfo "INFO: Commands per second: $hashes_per_sec"
}
```

### Benchmarking Commands

```bash
# commandBench "globName test_VariaBle"
# commandBench "echoC \"sto;whi\" \"|\$(echoC \"res;bla\" \"\$(strRepeat - 78)\")|\""
# commandBench "echoC \";whi\" \"|\$(echoC \"res;bla\" \"------------------\")|\""
# commandBench "echoC \";whi\" \"----------------------------------------------\""
# commandBench "echoNC \"res;whi\" \"-------------------------------------------\""
# commandBench "globSet test value"
# commandBench "globGet test"
# commandBench "globFile test"
# commandBench "strRepeat a 30"
# commandBench "isNullOrEmpty n"
# commandBench "pp=aaa && [ -z \"\$pp\" ] && echo yes || echo no"
function commandBench() {
  command=$1
  num_iterations=$2
  [ -z "$num_iterations" ] && num_iterations=1000

  start_time=$(date +%s%N)
  for i in $(seq 1 $num_iterations); do
    eval "$command" > /dev/null
  done
  end_time=$(date +%s%N)

  total_time=$((end_time - start_time))
  avg_time=$((total_time / num_iterations))

  hashes_per_sec=$(bc -l <<< "$num_iterations / ($total_time / 1000000000)")
  echoInfo "INFO: Commands per second: $hashes_per_sec"
}
```