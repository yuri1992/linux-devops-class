#!/bin/bash
# -----------------------------------------------
# Description : Check the system status in terms of cpu_idle and free_mem.
# Input		  : None
# Exit code   : Number of failed checks.
# -----------------------------------------------


# Improve the systemStatus.sh script by adding more system verification and improvements as follow:

# 7. Refactor the script:
# a. Make each verification as a function. - DONE

# b. The script should print which test named failed and which tests passed.

# c. Instead of hardcoded thresholds, the script should get a config file with all the thresholds (get it
#    with –c <file> flag). Every line in the file should look like this: [verification function name] [>
#    or <] [value]. Here is an example:
# The script should ignore comments or empty lines from the thresholds config file, also ignore
# unknown thresholds with warning.

# Thresholds for the checks
CPU_IDLE_MIN=90	# Thresholds for CPU Idle percentage
FREE_MEM_MB_MIN=60 # Thresholds for free memory size
FREE_SWAP_MB_MIN=100 # Thresholds for free swap size
PROCCESS_COUNT_MAX=140 # Thresholds for max proccess count
DOCKER_CONTAINER_LIMIT=100 # Thresholds for max running containers
FILE_SYSTEM_USAGE_MAX=90 # Threshold for max file system usage
INODES_USAGE_MAX=90 # Threshold for inodes file system usage
ZOMBIES_PROCESS_MIN=0
LISTEN_PORTS_MAX=20
RMPS_INSTALLED_MAX=3200


count_failed_test=0
counter=0 # Add check counter to debug bg deamon runs

function test_docker_alert () {
	# Alert if there are more than 100 docker containers running.

	# Get number of running containers,  remove header line
	running_dockers=`docker ps -f status=running | tail +2 | wc -l`

	# check if number of running dockers is higher than threshold
	if [ $running_dockers -gt $DOCKER_CONTAINER_LIMIT ]; then
		count_failed_test=`expr $count_failed_test + 1`
		echo "Test Running Dockers - FAILED"
	else
		echo "Test Running Dockers - PASSED"
	fi
}

function test_file_system () {
    # Check file-systems size usage, alert if there is a file system with more than 90% usage.
	file_system_bigger=`df | awk 'int($5) > $FILE_SYSTEM_USAGE_MAX {print ;}'`

	# check if number of running dockers is higher than threshold
	if [ -z "$file_system_bigger" ]; then
		echo "Test System File Usage - PASSED"
	else
		count_failed_test=`expr $count_failed_test + 1`
		echo "Test System File Usage - FAILED"
	fi
}

function test_inodes_usage() {
    # Alert if inodes usage is higher than 90% on a file system.
	
	# Check file-systems size usage, alert if there is a file system with more than 90% usage.
	file_inodes_usage=`df -hi | grep -v '-' | awk 'int($5) > $INODES_USAGE_MAX {print ;}'`

	# check if number of running dockers is higher than threshold
	if [ -z "$file_inodes_usage" ]; then
		echo "Test Inodes File Usage - PASSED"
	else
		count_failed_test=`expr $count_failed_test + 1`
		echo "Test Inodes File Usage - FAILED"
	fi
}

function test_zombies_processes() {
    # 3. Alert if there are zombie processes.
	zombie_process_number=`ps aux | awk {'print $8'}|grep -c Z`
	# check if number of zombies processes
	if [ $zombie_process_number -gt $ZOMBIES_PROCESS_MIN ]; then
		count_failed_test=`expr $count_failed_test + 1`
		echo "Test Zoombies Process - FAILED"
	else
		echo "Test Zoombies Process - PASSED"
	fi
}

function test_listen_ports() {
    # 4. Alert if there are more than 20 ports in listen mode.
	listen_ports=`netstat -l | grep  -w LISTEN | wc -l`
	if [ $listen_ports -gt $LISTEN_PORTS_MAX ]; then
		count_failed_test=`expr $count_failed_test + 1`
		echo "Test Listen Ports - FAILED"
	else
		echo "Test Listen Ports - PASSED"
	fi
}

function test_rmps_installed() {
    # 5. Alert if number of installed rpms is higher than 3200
	installed_rmps=`rpm -qa | wc -l`
	if [ $installed_rmps -gt $RMPS_INSTALLED_MAX ]; then
		count_failed_test=`expr $count_failed_test + 1`
		echo "Test RMPS installed - FAILED"
	else
		echo "Test RMPS installed - PASSED"
	fi
}

function test_idle_cpu() {
    # get average cpu idle percentage:
	# Get stats report for all proccessors at 3 second interval 
	# filter Average row and cast the 12th column of the table
	cpu_idle=`mpstat 3 1 | grep Average | awk '{print int($NF)}'`
	# Original: cpu_idle=`mpstat 3 1 | grep Average | awk '{idle=int($12); print idle}'`
	# print current cpu stat, retrived above with threshold defined at top
	echo "cpu_idle    : current $cpu_idle%, minimal $CPU_IDLE_MIN%"

	# check if cpu idle is lower then defind threshold, print a warning and increment failure counter
	if [ $cpu_idle -lt $CPU_IDLE_MIN ]; then
		echo "		-Not OK" # Addiding space to echo for nicer daemon printout 
		count_failed_test=`expr $count_failed_test + 1`
	fi
}

function test_free_mb() {
	# Get memory report in MB, filter the Memory row and get system's free memory size (4th col)
	free_mem_MB=`free -m | grep Mem | awk '{print $4}'`

    # print current free memory, retrived above with threshold defined at top
	echo "free_mem_MB : current ${free_mem_MB}MB, minimal ${FREE_MEM_MB_MIN}MB"

	# check if free memory is lower then defind threshold, print a warning and increment failure counter
	if [ $free_mem_MB -lt $FREE_MEM_MB_MIN ]; then
		echo "		-Not OK"
		count_failed_test=`expr $count_failed_test + 1`
	fi
}

function test_free_swap() {
	# Get memory report in MB, filter the Swap row and gets ystem's free memory size (4th col)
	free_swap_MB=`free -m | grep Swap | awk '{print $4}'`
    # print current free swap memory, retrived above with threshold defined at top
	echo "free_swap_MB : current ${free_swap_MB}MB, minimal ${FREE_SWAP_MB_MIN}MB"

	# check if free memory is lower then defind threshold, print a warning and increment failure counter
	if [ $free_swap_MB -lt $FREE_SWAP_MB_MIN ]; then
		echo "		-Not OK"
		count_failed_test=`expr $count_failed_test + 1`
	fi
}

function test_process_count() {
	# count rows of proccess print out, exept title row and commands used in this piped command
	proccess_count=`ps -e | egrep -v "PID|ps|grep|wc" | wc -l`
    #------------ Compare statuses to thresholds

	# print current free swap memory, retrived above with threshold defined at top
	echo "proccess_count : current ${proccess_count}, minimal ${PROCCESS_COUNT_MAX}"

	# check if free memory is lower then defind threshold, print a warning and increment failure counter
	if [ $proccess_count -gt $PROCCESS_COUNT_MAX ]; then
		echo "		-Not OK"
		count_failed_test=`expr $count_failed_test + 1`
	fi
}

function help_msg() {
	echo "systemStatus  [–c <file> | Configuration file describing limit of alerts]"
}

if [[ $# -gt 0 ]]; then
	case $1 in
    -c)
		# Checking if configuration file found.
		if [ ! -e "$2" ]; then
			echo "Error: Configuration file not found."
			exit 1
		fi
		
		echo "Config file found parsing file"
		# Reading Configuration file.
		while IFS= read line ; do
			if [[ "$line" =~ ^\#(.)* ]]; then
				echo "DEBUG: found a note, skip"
			elif [ -z "$line" ]; then
				echo "DEBUG: found a empty line, skip"
			elif [[ "$line" =~ ([[:space:]]*)?(.*)(<|>){1}([[:space:]]*)?([0-9]+){1} ]]; then
				#Todo: Add case switch to handle each configuration needed.
				echo "name: ${BASH_REMATCH[2]}";
				echo "bigger/smaller: ${BASH_REMATCH[3]}";
				echo "value: ${BASH_REMATCH[5]}";
			fi
		done <"$2"

      shift 2
      ;;    
    -h|--help|help)
      help_msg
      exit 0
      ;;
    *)
      echo "Unknown Argument $1"; exit 128 ;;
  esac
fi

while [ true ]; do
#----------- Get system statistics
	counter=`expr $counter + 1`
	echo "Checking status [#$counter]..."
	test_file_system;
	test_inodes_usage;
	test_zombies_processes;
	test_docker_alert;
	test_listen_ports;
	test_rmps_installed;
    test_free_mb;
    test_free_swap;
    test_idle_cpu;
    test_process_count;

	current_date=`date`
	# print a summary of the status checks 
	if [ $count_failed_test -gt 0 ]; then
		# print Not OK (with date) and exit with error code 1
		echo "====> SUM: Status NOT OK [$current_date]"	
	else
		# print OK (with date) and exit with success code 0
		echo "====> SUM: Status OK [$current_date]"
	fi
	count_failed_test=0

	sleep 2
done



