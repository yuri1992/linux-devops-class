# /bin/bash
# -----------------------------------------------
# Description : Remove images/containers
# Input		  : see help_msg
# Exit code   : 0 - Success
#               128 - Invalid Arguments
# -----------------------------------------------

DOCKER_COMPONENT="";
DRY_RUN_TEST_MODE=false
DOCKER_STATUS="";
DOCKER_PATTERN="";

help_msg() {
  echo "docker_clean [-c ps -s <status> | -c images -o <pattern> ] [-t]
        -c ps -s STATUS : remove all the docker containers with a given status. Status can be “running” or “exited”.
        -c images -o pattern : remove all the images that match the pattern.
        -t : a test mode, don’t delete anything just show what will be deleted";
}

# Parse Parameters #
while getopts ":hc:s:o:t" arg; do
  case "${arg}" in
    c)
      case "$OPTARG" in
        "ps") DOCKER_COMPONENT='ps' ; ;;
        "images") DOCKER_COMPONENT='images' ; ;;
        *) echo "Unknown Option for -c argument $OPTARG, valid options:{images,ps} "; exit 128; ;;
      esac
      ;;    
    s)
      case "$OPTARG" in
        "running") DOCKER_STATUS='running' ;;
        "exited") DOCKER_STATUS='exited' ;;
        *) echo "Unknown Option for -s argument $OPTARG, valid options:{running,exited} "; exit 128; ;;
      esac
      ;;
    o)
      DOCKER_PATTERN=$OPTARG
      ;;
    t)
      DRY_RUN_TEST_MODE=true
      ;;
    h|--help|help)
      help_msg
      exit 0
      ;;
    *)
      echo "Unknown Argument $*"; exit 128 ;;
  esac
done

shift $((OPTIND-1))

if [ -z "$DOCKER_COMPONENT" ]; then
  echo "you need to set -c <ps|images>"
  help_msg;
  exit 128
fi

if [ "$DOCKER_COMPONENT" == "ps" ] && [ -z "$DOCKER_STATUS" ]; then
  echo "you need to set -s <running|exited>"
  help_msg;
  exit 128
fi

if [ "$DOCKER_COMPONENT" == "images" ] && [ -z "$DOCKER_PATTERN" ]; then
  echo "you need to set -o <pattern>"
  help_msg;
  exit 128
fi

echo Starting Docker Clean

if [ "$DRY_RUN_TEST_MODE" == true ]; then
  echo "Running in dry run, no removes will be done."
fi

if [ "$DOCKER_COMPONENT" == "images" ]; then
  DOCKER_FOUND_IMAGES=$(docker images -a | awk "\$1 ~ /$DOCKER_PATTERN/ { print \$1}")
  if [ -z "$DOCKER_FOUND_IMAGES" ]; then
    echo "No images found."
  else
    if [ "$DRY_RUN_TEST_MODE" == false ]; then
      echo "Removing the following images matching $DOCKER_PATTERN pattern"
      echo "Removing..."
      docker rmi -f $(docker images -a | awk "\$1 ~ /$DOCKER_PATTERN/ { print \$3 }")
    else
      echo "Running in test mode, the following images would be deleted"
      printf '%s\n' "${DOCKER_FOUND_IMAGES[@]}"
    fi
  fi
elif [ "$DOCKER_COMPONENT" == "ps" ]; then
  DOCKER_FOUND_CONTAINERS=$(docker ps -f status=$DOCKER_STATUS -a --format '{{.ID}} {{.Names}} {{.Image}}')
  if [ -z "$DOCKER_FOUND_CONTAINERS" ]; then
    echo "No containers found."
  else
    if [ "$DRY_RUN_TEST_MODE" == false ]; then
      echo "Removing the following containers in $DOCKER_STATUS status"
      echo "Removing..."
      docker rm -f $(docker ps -a -q -f status=$DOCKER_STATUS)
    else
      echo "Running in test mode, the following images would be deleted"
      printf '%s\n' "${DOCKER_FOUND_CONTAINERS[@]}"
    fi
  fi
else
  echo "Invalid Component been provided"
  exit 128
fi

exit 0