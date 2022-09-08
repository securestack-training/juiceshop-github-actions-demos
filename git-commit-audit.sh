#!/bin/bash

set -e

function main() {

  if [ "$1" == "-h" -o "$1" == "--help" ]; then
    echo "usage: commit-check [-h|--help] [options]" >&2
    echo "Show long refs for all unsigned/unverified git commits in the current tree." >&2
    echo "  -h, --help  Display this usage guide." >&2
    echo "  options     Options to be passed to the invocation of git log." >&2
    return 1
  fi
  # git log --pretty='format:%H|%aN|%s|%G?' $@ | awk -F '|' '{ if($4 != "G"){print $1,$2;} }'
  GITARY=$(git log --pretty='format:%H|%aN|%s|%G?' $@)
  
  # check if there are any commits in git
  if [[ -z $GITARY ]]; then echo "No commits found.  Exiting... "; exit 1; fi

  #BADCOMMITS=$(git log --pretty='format:%H|%aN|%s|%G?' $@ | awk -F '|' '{ if($4 != "G"){print $1;} }' | wc -l | xargs)
  NUMBERCOMMITS=$(echo "$GITARY" | wc -l | xargs)
  BADCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 != "G"){print $1;} }' | wc -l | xargs)
  #GOODCOMMITS=$(git log --pretty='format:%H|%aN|%s|%G?' $@ | awk -F '|' '{ if($4 == "G"){print $1;} }' | wc -l)
  GOODCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "G"){print $1;} }' | wc -l | xargs)
  DEVNAMES=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u)

  if [[ $BADCOMMITS -gt $GOODCOMMITS ]]; then 
	PERCENT=$(bc <<< "scale=4; ($GOODCOMMITS/$BADCOMMITS ) * 100")
  elif [[ $BADCOMMITS -lt $GOODCOMMITS ]]; then 
	PERCENT=$(bc <<< "scale=4; ($BADCOMMITS/$GOODCOMMITS ) * 100")
  fi
  echo "Total commits: $NUMBERCOMMITS | Signed commits: $GOODCOMMITS | Un-signed commits: $BADCOMMITS"
  echo "Percentage of commits that have been signed = $PERCENT %"
  echo "Total number of Developers who have commited is $(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|wc -l|xargs)"
  echo "Developer Names:"
  DEVARRAY=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|sed "s/\ /_/g")
  echo "$DEVARRAY" > ./tempfile
  #for devname in "${DEVARRAY[@]}"; do
  for devname in $(<tempfile); do
        if [[ -n $devname ]]; then
		devname2=$(echo $devname | sed "s/\_/ /g")
		DEVCOMMITNUMBER=$(echo "$GITARY" | grep -i "$devname2" | wc -l | xargs)
		DEVGOODCOMMITS=$(echo "$GITARY" | grep -i "$devname2" | awk -F '|' '{ if($4 == "G"){print $1,$2,$3,$4;} }' | wc -l | xargs)
		DEVBADCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 != "G"){print $1,$2,$3,$4;} }' | grep -i "$devname2" | wc -l | xargs)
		echo "$devname2 = Total commits: $DEVCOMMITNUMBER | Signed commits: $DEVGOODCOMMITS | Un-signed commits: $DEVBADCOMMITS"
	fi
  done
  
}

if [[ ${BASH_SOURCE[0]} == $0 ]]; then
  main $@
fi
