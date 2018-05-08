#!/bin/bash -e

rev=$1
srev=`echo $rev | cut -c1-6`
echo 'steps:'

cmd() {
  cmd=$1
  cat <<EOL
- agents:
    docker: "true"
    os: "linux"
  label: ":camel: opam admin $cmd"
  command:
    - cd /home/opam/opam-repository
    - id
    - git pull origin master
    - opam update
    - opam admin $cmd 2>&1 | tee $cmd.txt
    - buildkite-agent artifact upload $cmd.txt
  plugins:
    docker#v1.1.1:
      image: "ocaml/opam2-staging"
      always_pull: true
EOL
}

cmd "lint"
cmd "cache"

cat <<EOL
- wait
- label: "Push Results"
  command:
    - rm -rf obi-logs
    - git clone -b lints --depth=1 git://github.com/avsm/obi-logs
    - find obi-logs/ -type f
  agents:
    githubpusher: "true"
EOL
