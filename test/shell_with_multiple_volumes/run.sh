#!/usr/bin/env bash
for i in 1 2 3 4 ; do
    # the test depends on the right output appearing
    # it isn't useful if run.sh fails, job fails with
    # 'ERROR: failed to build: exit status 1'
  tf="/volumes/$i/test"
  if [ -f "${tf}" ] ; then
    cat "${tf}"
  else
    echo "${tf} missing"
  fi
done
exit 0
