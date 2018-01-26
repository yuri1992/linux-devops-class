#!/bin/bash
# -----------------------------------------------
# Description : Check the system status in terms of cpu_idle and free_mem.
# Input		  : None
# Exit code   : 128 - unkown argumet
# -----------------------------------------------

CPU_IDLE_MIN=90	# Thresholds for CPU Idle percentage
FREE_MEM_MB_MIN=60 # Thresholds for free memory size
FREE_SWAP_MB_MIN=100 # Thresholds for free swap size
PROCCESS_COUNT_MAX=140 # Thresholds for max proccess count
DOCKER_CONTAINER_LIMIT=100 # Thresholds for max running containers
FILE_SYSTEM_USAGE_MAX=90 # Threshold for max file system usage
INODES_USAGE_MAX=90 # Threshold for inodes file system usage
ZOMBIES_PROCESS_MIN=0 # Threshold for zombiees process
LISTEN_PORTS_MAX=20 # Threshold Listen ports
RMPS_INSTALLED_MAX=3200 #hreshold for installed rmps

COUNT_FAILED_TEST=0
COUNTER_ITERATION=0 # Add check COUNTER_ITERATION to debug bg deamon runs

test_docker_alert () {
	# Alert if there are more than 100 docker containers running.

	# Get number of running containers,  remove header line
	running_dockers=`docker ps -f status=running | tail -n +2 | wc -l`
	echo -e "docker_containers: current running $running_dockers, threshold $DOCKER_CONTAINER_LIMIT \c"
	# check if number of running dockers is higher than threshold
	if [ $running_dockers -gt $DOCKER_CONTAINER_LIMIT ]; then
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
		echo " - FAILED"
	else
		echo " - PASSED"
	fi
}

test_file_system () {
    # Check file-systems size usage, alert if there is a file system with more than 90% usage.
	file_system_usage=`df | awk 'int($5) > $FILE_SYSTEM_USAGE_MAX {print $1, int($5)}'`
	
	# check if number of running dockers is higher than threshold
	if [ -z "$file_system_usage" ]; then
		echo "fs_usage: all fs usage under $FILE_SYSTEM_USAGE_MAX%  - PASSED"
	else
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
		echo "fs_usage: fs usage is higher than $FILE_SYSTEM_USAGE_MAX% - FAILED"
		#echo "$file_system_usage over threshold $FILE_SYSTEM_USAGE_MAX  - FAILED"
	fi
}

test_inodes_usage() {
    # Alert if inodes usage is higher than 90% on a file system.
	# Check file-systems size usage, alert if there is a file system with more than 90% usage.

	file_inodes_usage=`df -hi | grep -v '-' | awk 'int($5) > $INODES_USAGE_MAX {print $1, int($5)}'`

	# check if number of running dockers is higher than threshold
	if [ -z "$file_inodes_usage" ]; then
		echo "inode_usage: all inode usage under threshold $INODES_USAGE_MAX%  - PASSED"
	else
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
		echo "inode_usage: inode usage is higher than $INODES_USAGE_MAX% - FAILED"
		#echo "$file_inodes_usage over threshold $INODES_USAGE_MAX  - FAILED"
	fi
}

test_zombies_processes() {
    # 3. Alert if there are zombie processes.
	# Get number of running containers,  remove header line
	zombie_process_number=`ps aux | awk {'print $8'}|grep -c Z`
	echo -e "zombie_process: current running $zombie_process_number, threshold $ZOMBIES_PROCESS_MIN \c"
	# check if number of running dockers is higher than threshold
	if [ $zombie_process_number -gt $ZOMBIES_PROCESS_MIN ]; then
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
		echo " - FAILED"
	else
		echo " - PASSED"
	fi
}

test_listen_ports() {
    # 4. Alert if there are more than 20 ports in listen mode.
	listen_ports=`netstat -l | grep  -w LISTEN | wc -l`
	echo -e "listen_ports: current ports in listen mode $listen_ports, threshold $LISTEN_PORTS_MAX \c"
	if [ $listen_ports -gt $LISTEN_PORTS_MAX ]; then
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
		echo " - FAILED"
	else
		echo " - PASSED"
	fi
}

test_rmps_installed() {
    # 5. Alert if number of installed rpms is higher than 3200
	installed_rmps=`rpm -qa | wc -l`
	echo -e "rmps_installed: current $installed_rmps, threshold $RMPS_INSTALLED_MAX \c"
	if [ $installed_rmps -gt $RMPS_INSTALLED_MAX ]; then
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
		echo " - FAILED"
	else
		echo " - PASSED"
	fi
}

test_idle_cpu() {
    # get average cpu idle percentage:
	# Get stats report for all proccessors at 3 second interval 
	# filter Average row and cast the 12th column of the table
	cpu_idle=`mpstat 3 1 | grep Average | awk '{print int($NF)}'`

	# Original: cpu_idle=`mpstat 3 1 | grep Average | awk '{idle=int($12); print idle}'`
	# print current cpu stat, retrived above with threshold defined at top
	echo -e "cpu_idle    : current $cpu_idle%, threshold $CPU_IDLE_MIN% \c"

	# check if cpu idle is lower then defind threshold, print a warning and increment failure COUNTER_ITERATION
	if [ $cpu_idle -lt $CPU_IDLE_MIN ]; then
		echo " - FAILED" # Addiding space to echo for nicer daemon printout 
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
	else 
		echo " - PASSED"
	fi
}

test_free_mb() {
	# Get memory report in MB, filter the Memory row and get system's free memory size (4th col)
	free_mem_MB=`free -m | grep Mem | awk '{print $4}'`

    # print current free memory, retrived above with threshold defined at top
	echo -e "free_mem_MB : current ${free_mem_MB}MB, threshold ${FREE_MEM_MB_MIN}MB \c"

	# check if free memory is lower then defind threshold, print a warning and increment failure COUNTER_ITERATION
	if [ $free_mem_MB -lt $FREE_MEM_MB_MIN ]; then
		echo " - FAILED"
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
	else 
		echo " - PASSED"
	fi
}

test_free_swap() {
	# Get memory report in MB, filter the Swap row and gets ystem's free memory size (4th col)
	free_swap_MB=`free -m | grep Swap | awk '{print $4}'`
    # print current free swap memory, retrived above with threshold defined at top
	echo -e "free_swap_MB : current ${free_swap_MB}MB, threshold ${FREE_SWAP_MB_MIN}MB \c"

	# check if free memory is lower then defind threshold, print a warning and increment failure COUNTER_ITERATION
	if [ $free_swap_MB -lt $FREE_SWAP_MB_MIN ]; then
		echo " - FAILED"
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
	else 
		echo " - PASSED"
	fi
}

test_process_count() {
	# count rows of proccess print out, exept title row and commands used in this piped command
	proccess_count=`ps -e | egrep -v "PID|ps|grep|wc" | wc -l`
    #------------ Compare statuses to thresholds

	# print current free swap memory, retrived above with threshold defined at top
	echo -e "proccess_count : current ${proccess_count}, threshold ${PROCCESS_COUNT_MAX} \c"

	# check if free memory is lower then defind threshold, print a warning and increment failure COUNTER_ITERATION
	if [ $proccess_count -gt $PROCCESS_COUNT_MAX ]; then
		echo " - FAILED"
		COUNT_FAILED_TEST=`expr $COUNT_FAILED_TEST + 1`
	else 
		echo " - PASSED"
	fi
}

help_msg() {
	echo "systemStatus  [–c <file> | Configuration file describing limit of alerts]"
}


####### Handling Arguments #######
if [[ $# -gt 0 ]]; then
	case $1 in
    -c)
		# Checking if configuration file found.
		if [ ! -e "$2" ]; then
			echo "Error: Configuration file not found."
			exit 1
		fi
		
		echo "Config file found parsing file.."
		# Reading Configuration file.
		while IFS= read line ; do
			if [[ "$line" =~ ^\#(.)* ]]; then
				# line started as a note.
				:
			elif [ -z "$line" ]; then
				# Empty line
				:
			elif [[ "$line" =~ ([[:space:]]*)?([a-zA-Z_]+){1}([[:space:]]*)?(<|>){1}([[:space:]]*)?([0-9]+){1} ]]; then
				settings_name=${BASH_REMATCH[2]};
				settings_compertor=${BASH_REMATCH[4]};
				settings_value=${BASH_REMATCH[6]};

				case $settings_name in
					cpu_usage)
						echo "cpu_usage setting found, $settings_value"
						CPU_IDLE_MIN=$settings_value
					;;
					swap_usage)
						echo "swap_usage setting found, $settings_value"
						FREE_SWAP_MB_MIN=$settings_value
					;;
					zombiees_processes)
						echo "zombiees_processes setting found, $settings_value"
						ZOMBIES_PROCESS_MIN=$settings_value
					;;
					docker_containers)
						echo "docker_containers setting found, $settings_value"
						DOCKER_CONTAINER_LIMIT=$settings_value
					;;
					fs_usage)
						echo "fs_usage  found, $settings_value"
						FILE_SYSTEM_USAGE_MAX=$settings_value
					;;
					inode_usage)
						echo "inode_usage found, $settings_value"
						INODES_USAGE_MAX=$settings_value
					;;
					port_listen)
						echo "port_listen found, $settings_value"
						LISTEN_PORTS_MAX=$settings_value
					;;
					rmps_installed)
						echo "rmps_installed found, $settings_value"
						RMPS_INSTALLED_MAX=$settings_value
					;;
					process_running)
						echo "process_running found, $settings_value"
						PROCCESS_COUNT_MAX=$settings_value
					;;
					memory_mb)
						echo "memory_mb found, $settings_value"
						FREE_MEM_MB_MIN=$settings_value
					;;
					*)
					echo "Unknown Setting value $settings_name";  ;;
				esac
			else
				echo "ignoring $line";
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

##########################
#### Main While loop #####
##########################
echo "Starting moniroting..."

while [ true ]; do
	COUNTER_ITERATION=`expr $COUNTER_ITERATION + 1`
	echo "Checking status [#$COUNTER_ITERATION]..."

	#### Running test functions #####
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
	if [ $COUNT_FAILED_TEST -gt 0 ]; then
		# print Not OK (with date) and exit with error code 1
		echo "====> SUM: Status NOT OK [$current_date]"	
	else
		# print OK (with date) and exit with success code 0
		echo "====> SUM: Status OK [$current_date]"
	fi
	COUNT_FAILED_TEST=0

	sleep 2
done

exit 0