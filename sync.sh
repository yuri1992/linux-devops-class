#!/bin/bash -e

# Description : Sync source dir to destination dir
# Exit code:
#   0 - Exit
#   11 - Illegal argument issue
#   12 - Missing paramteres issue
# ----------------------------------

#---------- Handle Signal Traps

# Ignore SIGINT and SIGTERM
trap : INT
trap : TERM

#------------ Functions

usage()
{
  echo
  echo "Usage: $0 [OPTION]..."
  echo
}

abort()
{
  if [[ $2 -gt 0 ]]; then
    errcode=$2
  else
    errcode=9
  fi
  usage
  echo $1
  exit $errcode
}

description()
{
  usage
  echo "Sync source dir to destination dir."
  echo
  echo "  -s <source>        Source directory to sync from. if not given, use \$SDIR"
  echo "  -d <destination>   Destination directory to sync to. if not given, use \$DDIR"
  echo
  echo "  -h                 Display this help and exit"
  echo
  echo "  -a                 Sync the file permission and ownership (optional flag)"
  echo "  -v                 Verbose: Print every file tested (optional flag)"
  echo "  -y                 Prompt before every sync any file (optional flag)"
  echo "  -t                 Test Mode: Run the script without actually sync (optional flag)"
  echo
}

scan_dir()
{
  for ITEM in `ls $1`; do

    # check if file
    if [ -f $1/$ITEM ]; then
      SCANNED=$((SCANNED + 1))

      if diff $1/$ITEM $2/$ITEM > /dev/null 2>&1 ; then
        # Files have same content - check if premissions should be synced or skipped
        if ! $IS_SYNC_PERM; then
          print_verbose "‘$1/$ITEM‘ is already synced"
          continue
        fi

        # if user was prompted and asked to skip
        if ! prompt_user_if_needed "$1/$ITEM"; then
          print_verbose "‘$1/$ITEM‘ permissions will not be synced"
          continue
        fi

        if $IS_TEST_MODE; then
          echo "Test Mode: ‘$1/$ITEM‘ permissions should be copied"
        else
          chown --reference=$1/$ITEM $2/$ITEM
          chmod --reference=$1/$ITEM $2/$ITEM
          echo "Copied permissions and owner from ‘$1/$ITEM‘ to ‘$2/$ITEM‘"
        fi

      # Files are different, need to sync
      else
        # if user was prompted and asked to skip
        if ! prompt_user_if_needed "$1/$ITEM"; then
          print_verbose "‘$1/$ITEM‘ will not be copied"
          continue  # do not sync this file
        fi

        if $IS_TEST_MODE; then
          echo "Test Mode: ‘$1/$ITEM‘ should be copied" $COPYPERMSTRING
        else
          SYNCED=$((SYNCED + 1))
          # make sure dest folder exists:
          mkdir $2 2> /dev/null || true
          cp ${COPYARGS} $1/$ITEM $2/$ITEM
          echo "‘$1/$ITEM‘ copied to ‘$2/$ITEM‘" $COPYPERMSTRING
        fi
      fi

    # else if folder - need to recursively drill down
    elif [ -d $1/$ITEM ]; then
      scan_dir $1/$ITEM $2/$ITEM
    fi
  done
}

# Desc: Prompt user to proceed (if needed)
# Args: 1 = The file to prompt to user
# Return: Boolean: true if Should continue operation, false if operation should be skipped
prompt_user_if_needed()
{
  if $IS_PROMPT_EACH; then
    echo "Do you want to sync ‘"$1"’ (y/n)?"
    read response
    if [ $response == "y" ]; then
      true
    else
      false
    fi
  else
    true
  fi
}

# Desc: Echo argument string only if verbose logging is enabled
# Args: 1 = The string to echo 
print_verbose()
{
  if $IS_VERBOSE; then
    echo $1
  fi
}

#===========================
#============ Main =========

#------------ VAR INIT
SOURCE=$SDIR
DEST=$DDIR
IS_SYNC_PERM=false
IS_VERBOSE=false
IS_PROMPT_EACH=false
IS_TEST_MODE=false
SCANNED=0
SYNCED=0

#------------ Arg validation

while getopts ":hs:d:avyt" arg; do
  case "${arg}" in
    s)
      SOURCE=${OPTARG}
      ;;
    d)
      DEST=${OPTARG}
      ;;
    a)
      IS_SYNC_PERM=true
      ;;
    v)
      IS_VERBOSE=true
      ;;
    y)
      IS_PROMPT_EACH=true
      ;;
    t)
      IS_TEST_MODE=true
      ;;
    h)
      description && exit 0
      ;;
    *)
      abort "$0: invalid option -- '$*'. Try '$0 -h' for more information." 11
      ;;
  esac
done
shift $((OPTIND-1))

# Folder validation
# If env param are not set - script should not default to cwd
if [[ -z $SOURCE || -z $DEST ]]; then
  abort "Source or Destination folder are not defined" 12
elif [ ! -d $SOURCE ]; then
  abort "'${SOURCE}' is not a folder" 12
elif  [ ! -d $DEST ]; then
  abort "'${DEST}' is not a folder" 12
fi

#------------ Source folder scan

# build copy options:
if $IS_SYNC_PERM; then
  print_verbose "Enabled sync permissions"
  COPYARGS='-a'
  COPYPERMSTRING="(including permissions)"
fi

scan_dir $SOURCE $DEST

echo
echo "======== Summary ========"
echo "Scanned $SCANNED files"
echo "Syned $SYNCED files"
echo

exit 0
