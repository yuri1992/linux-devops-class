#/bin/bash

DOCKER_COMPONENT="";
DRY_RUN_TEST_MODE=false
DOCKER_STATUS="";
DOCKER_PATTERN="";

function help_msg() {
  echo "docker_clean [-c ps -s <status> | -c images -o <pattern> ] [-t]
        -c ps -s STATUS : remove all the docker containers with a given status. Status can be “running” or “exited”.
        -c images -o pattern : remove all the images that match the pattern.
        -t : a test mode, don’t delete anything just show what will be deleted";
}

# Parse Parameters #
while [[ $# -gt 0 ]] ; do
  case $1 in
    -c)
      case "$2" in
        "ps") DOCKER_COMPONENT='ps' ; shift 2 ;;
        "images") DOCKER_COMPONENT='images' ; shift 2 ;;
        *) echo "Unknown Option for -c argument $2, valid options:{images,ps} "; exit 128; ;;
      esac
      ;;    
    -s)
      case "$2" in
        "running") DOCKER_STATUS='running' ; shift 2 ;;
        "exited") DOCKER_STATUS='exited' ; shift 2 ;;
        *) echo "Unknown Option for -s argument $2, valid options:{running,exited} "; exit 128; ;;
      esac
      ;;
    -o)
      DOCKER_PATTERN=$2
      shift 2
      ;;
    -t)
      DRY_RUN_TEST_MODE=true
      shift
      ;;
    -h|--help|help)
      help_msg
      exit 0
      ;;
    *)
      echo "Unknown Argument $1"; exit 128 ;;
  esac
done

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
  DOCKER_FOUND_IMAGES=$(docker images -a | awk "\$1 ~ /$DOCKER_PATTERN/ { print \$1,\$3}")
  if [ -z "$DOCKER_FOUND_IMAGES" ]; then
    echo "No images found."
  else
    if [ "$DRY_RUN_TEST_MODE" == false ]; then
      echo "Removing the following images matching $DOCKER_PATTERN pattern"
      echo "Removing..."
      DOCKER_IMAGES_IDS=$(docker images -a | awk "\$1 ~ /$DOCKER_PATTERN/ { print \$3 }")
      docker rmi -f $DOCKER_IMAGES_IDS
    else
      echo "Running in test mode, the following images would be deleted"
      echo $DOCKER_FOUND_IMAGES
    fi
  fi
elif [ "$DOCKER_COMPONENT" == "ps" ]; then
  DOCKER_FOUND_CONTAINERS=$(docker ps -f status=$DOCKER_STATUS -a --format '{{.ID}} {{.Names}} {{.Image}}')
  if [ -z "$DOCKER_FOUND_CONTAINERS" ]; then
    echo "No containers found."
  else
    if [ "$DRY_RUN_TEST_MODE" == false ]; then
      echo "Removing the following containers in $DOCKER_STATUS"
      echo "Removing..."
      DOKCER_IDS_TO_DELETE=$(docker ps -a -q -f status=$DOCKER_STATUS);
      docker rm -f $DOKCER_IDS_TO_DELETE
    else
      echo "Running in test mode, the following images would be deleted"
      echo $DOCKER_FOUND_CONTAINERS
    fi
  fi
fi

exit 0