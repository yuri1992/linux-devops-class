#!/bin/bash -e

# Description : Sync source dir to destination dir
# Exit code:
#   0 - Exit
#   1 - Illegal argument issue
# ----------------------------------

#---------- Handle Signal Traps

# iignore SIGINT and SIGTERM
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

      #print_verbose "Scanning $1/$ITEM..."
      SCANNED=$((SCANNED + 1))

      if diff $1/$ITEM $2/$ITEM > /dev/null 2>&1 ; then
        print_verbose "‘$1/$ITEM‘ not copied"
      else
        SYNCED=$((SYNCED + 1))
        # make sure dest folder exists:
        mkdir $2 2> /dev/null || true
        if [ $IS_TEST_MODE -eq 0 ]; then
          cp ${CPO} $1/$ITEM $2/$ITEM
        else
          echo "‘$1/$ITEM‘ should be copied"
        fi
        #echo $1/$ITEM copied
      fi
    # else if folder - need to drill down sync
    elif [[ -d $1/$ITEM ]]; then
      scan_dir $1/$ITEM $2/$ITEM
    fi
  done
}

print_verbose()
{
  if [ $IS_VERBOSE -gt 0 ]; then
    echo $1
  fi
}

#===========================
#============ Main =========

#------------ VAR INIT
SOURCE=$SDIR
DEST=$DDIR
IS_SYNC_PERM=0
IS_VERBOSE=0
IS_PROMPT_EACH=0
IS_TEST_MODE=0
SCANNED=0
SYNCED=0

#------------ Arg validation

while getopts ":hs:d:avyt" arg; do
  case "${arg}" in
    s)
      if [[ $OPTARG =~ ^[/a-zA-Z0-9]+$ ]]; then
        SOURCE=${OPTARG}
      else
        abort "${OPTARG}: invalid argument" 11
      fi
      ;;
    d)
      if [[ $OPTARG =~ ^[/a-zA-Z0-9]+$ ]]; then
        DEST=${OPTARG}
      else
        abort "${OPTARG}: invalid argument" 12
      fi
      ;;
    a)
      IS_SYNC_PERM=1
      ;;
    v)
      IS_VERBOSE=1
      ;;
    y)
      IS_PROMPT_EACH=1
      ;;
    t)
      IS_TEST_MODE=1
      ;;
    h)
      description && exit 0
      ;;
    *)
      abort "$0: invalid option -- '$*'. Try '$0 -h' for more information." 13
      ;;
  esac
done
shift $((OPTIND-1))

# Folder validation
if [ ! -d $SOURCE ]; then
  abort "${SOURCE} is not a folder" 14
fi
if [ ! -d $DEST ]; then
  abort "${DEST} is not a folder" 15
fi

#------------ Source folder scan

# build copy options:
TODO: REMOVE CP V, I
  CPO='-v'
if [ $IS_PROMPT_EACH -gt 0 ]; then
  print_verbose "Enabled prompt each copy"
  CPO=$CPO'i'
fi

if [ $IS_SYNC_PERM -gt 0 ]; then
  print_verbose "Enabled sync permissions"
  CPO=$CPO'a'
fi

echo CPO is $CPO

scan_dir $SOURCE $DEST

echo
echo "======== Summary ========"
echo "Scanned $SCANNED files"
echo "Syned $SYNCED files"

exit 0
