#!/usr/bin/env bash

#
# Pre-receive hook that will block any new commits that contain files ending
# with .gz, .zip or .tgz
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

deploy_to_dir="/tmp/tst_work/"
GIT_CMD="env GIT_WORK_TREE=$deploy_to_dir /usr/bin/git"
shopt -s extglob
FILE_EXT_DISABLED='@(.env|Thumbs.db|*.rar|*.zip|*.gz|*.tgz|*.dll|*.exe)'

zero_commit="0000000000000000000000000000000000000000"

# Do not traverse over commits that are already in the repository
# (e.g. in a different branch)
# This prevents funny errors if pre-receive hooks got enabled after some
# commits got already in and then somebody tries to create a new branch
# If this is unwanted behavior, just set the variable to empty
excludeExisting="--not --all"

while read oldrev newrev refname; do
  # echo "payload"
  echo $refname $oldrev $newrev

  # branch or tag get deleted
  if [ "$newrev" = "$zero_commit" ]; then
    continue
  fi

  # Check for new branch or tag
  if [ "$oldrev" = "$zero_commit" ]; then
    span=`$GIT_CMD rev-list $newrev $excludeExisting`
  else
    span=`$GIT_CMD rev-list $oldrev..$newrev $excludeExisting`
  fi

  for COMMIT in $span;
  do
    for FILE  in `$GIT_CMD log -1 --name-only --pretty=format:'' $COMMIT`;
    do
      case $FILE in
      $FILE_EXT_DISABLED )
        echo " --------------------------- WARNING --------------------------- "
        echo "Hello there! We have restricted committing that filetype."
        echo "blocked filetypes: $FILE_EXT_DISABLED" | sed -r 's/[()@]+//g'
        echo "blocked file: $FILE"
        echo " --------------------------- WARNING --------------------------- "
        exit 1
        ;;
      esac
    done
  done
done
exit 0
