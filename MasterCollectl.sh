#!/bin/ksh

#Steps to setup openssh
#http://www.thegeekstuff.com/2008/06/perform-ssh-and-scp-without-entering-password-on-openssh/

#Nodes configuration file (nodesConfig.cfg) format
#hostAddress,Username

#Path where collectl is configured to store the collected metrics.
#If needs to be changed, make changes here and in the collectl.conf file present in collectl.tar.gz
metricsFilePath=/var/log/collectl

#Name of package with Collectl scripts
collectlPkg='collectl.tar.gz'

#Path on master node where collectl will copy/create all the temporary metric files/directories
#Make sure that this directory structure exists on master before running collectl
configPath=/root/tmp

#Columns from collected raw-metric files of collectl to be considered for creating CSV and to store in the database
CPU_COLS=1-23
DSK_COLS=1-2,61-69
NWK_COLS=1-2,52-60
MEM_COLS=1-2,24-51
NFS_COLS=1-2,70-84
PRC_COLS=1-19,21-30

#function to flush old files and create directory structure for this script
initialize ()
{
	rm -rf $configPath/collectlMasterTemp #flush older temporary data directory
	mkdir $configPath/collectlMasterTemp #create a temp directory for collectl master to copy files from nodes 

	if [ -s ./nodesConfig.cfg ] #check if configuration file exists in current directory
	then #initialize the configurationFilename variable
		configurationFilename='nodesConfig.cfg'
	else #echo configurationFile does not exists and exit
      echo "==> Configuration file not available"
	  exit
	fi
}

Usage ()
{
	echo "Usage : sh MasterCollectl.sh [--install] [--start] 
	              [--stop] [--dump] [--help] [--cleanup] [--verify]"
	echo " "
	echo "--install   : install collectl on all nodes specified in the nodesConfig.cfg"
	echo "--start 	  : start collectl on all nodes specified in the nodesConfig.cfg"
	echo "--stop 	  : stop collectl on all nodes specified in the nodesConfig.cfg"
	echo "--dump 	  : store the metrics from all nodes into Teradata database"
	echo "--help 	  : display usage information"
	echo "--cleanup   : delete old metric files from all nodes specified in the nodesConfig.cfg"
	echo "--verify 	  : verify if collectl is running on all nodes specified in the nodesConfig.cfg"
}

#install COLLECTL on nodes from configuration file
installCollectl () 
{
	configFileName=$1
	while IFS=',' read -r HostAddress Username
	do
		if [[ (${#Username} == 0)||(${#HostAddress} == 0)]];then #check if variable length is 0
			echo "==> Bad configuration file"
			exit
		fi
		echo "==> Copying setup file $collectlPkg to $HostAddress's home directory"
		#Perform cleanup
		ssh -l $Username $HostAddress exec 'rm -rf ~/collectl.tar.gz' < /dev/null;
		ssh -l $Username $HostAddress exec 'rm -rf ~/collectl' < /dev/null;
		ssh -l $Username $HostAddress exec 'rm -rf //usr/share/man/man1/collectl.1.gz' < /dev/null;
		#copy core collectl package to the current node's home directory
		scp $collectlPkg $Username@$HostAddress:~ < /dev/null;
		if [[ $? -ne 0 ]]; then #if copy fails 
			echo "==> Copying file $collectlPkg to node $HostAddress failed"
			exit
		else
			#install collectl in home directory of node
			ssh -l $Username $HostAddress exec tar -zxf ~/$collectlPkg < /dev/null;
			ssh -l $Username $HostAddress exec sh '~/collectl/INSTALL' < /dev/null;
			if [[ $? -ne 0 ]]; then #if installation fails
				echo "==> Installation of collectl on $HostAddress failed"
				exit
			else
				echo "==> Successfully installed collectl on $HostAddress"
			fi
		fi
	done < $configFileName
}

#uninstall COLLECTL from all nodes from configuration file
uninstallCollectl () 
{
	configFileName=$1
	while IFS=',' read -r HostAddress Username
	do
		if [[ (${#Username} == 0)||(${#HostAddress} == 0)]];then #check if variable #length is 0
			echo "==> Bad configuration file"
			exit
		fi
		echo "==>Uninstalling collectl from node $HostAddress"
		#uninstall collectl
		ssh -l $Username $HostAddress exec sh '~/collectl/UNINSTALL' < /dev/null;
		if [[ $? -ne 0 ]]; then #if copy fails
				echo "==> Uninstall Collectl on $HostAddress failed"
				exit
			else
				echo "==> Successfully uninstalled collectl on $HostAddress"
			fi
		#perform cleanup
		ssh -l $Username $HostAddress exec 'rm -rf ~/collectl' < /dev/null;
		ssh -l $Username $HostAddress exec 'rm -rf ~/collectl.tar.gz' < /dev/null;
		ssh -l $Username $HostAddress exec 'rm -rf //usr/share/man/man1/collectl.1.gz' < /dev/null;
		
	done < $configFileName
}

#extract the zipped node metrics file
uncompressFiles () #uncompress the node metrics dump files
{
	for file in $configPath/collectlMasterTemp/*.gz 
	do 
		gunzip $file
	done
}

#convert date from yyyymmdd to yyyy-mm-dd format
formatDate ()
{
	for filename in `ls $configPath/collectlMasterTemp/output`
	do
		cat $configPath/collectlMasterTemp/output/$filename | awk -F, -v q="-"  '{sub($2, substr($2,1,4) q substr($2,5,7)); print}' | awk -F, -v q="-"  '{sub($2, substr($2,1,7) q substr($2,8)); print}' > $configPath/collectlMasterTemp/output/tmp_$filename
		
		mv $configPath/collectlMasterTemp/output/tmp_$filename $configPath/collectlMasterTemp/output/$filename
	done
}

#create CSV files for each subsystem to store in the database
createMetricsCSV ()
{
	fileType=$1	#metric dump file to process
	if [[ $fileType == 'tab' ]]; then
		echo "************Processing $fileType files***********"
		for myFile in `ls $configPath/collectlMasterTemp | grep -i .tab`
		do
			echo "==>************Processing $myFile file***********"
			hostname=`echo $myFile | cut -d "-" -f 2`
			
			#generate CPU metric file
			sed '/#/d' $configPath/collectlMasterTemp/$myFile | cut -d "," -f $CPU_COLS > $configPath/collectlMasterTemp/tmp.csv
			sed "s/^/$hostname,/" $configPath/collectlMasterTemp/tmp.csv >> $configPath/collectlMasterTemp/output/cpu.txt
			
			#generate DISK metric file
			sed '/#/d' $configPath/collectlMasterTemp/$myFile | cut -d "," -f $DSK_COLS > $configPath/collectlMasterTemp/tmp.csv
			sed "s/^/$hostname,/" $configPath/collectlMasterTemp/tmp.csv >> $configPath/collectlMasterTemp/output/dsk.txt
			
			#generate NETWORK metric file
			sed '/#/d' $configPath/collectlMasterTemp/$myFile | cut -d "," -f $NWK_COLS > $configPath/collectlMasterTemp/tmp.csv
			sed "s/^/$hostname,/" $configPath/collectlMasterTemp/tmp.csv >> $configPath/collectlMasterTemp/output/net.txt
			
			#generate MEMORY metric file
			sed '/#/d' $configPath/collectlMasterTemp/$myFile | cut -d "," -f $MEM_COLS > $configPath/collectlMasterTemp/tmp.csv
			sed "s/^/$hostname,/" $configPath/collectlMasterTemp/tmp.csv >> $configPath/collectlMasterTemp/output/mem.txt
			
			#generate NFS metric file
			sed '/#/d' $configPath/collectlMasterTemp/$myFile | cut -d "," -f $NFS_COLS > $configPath/collectlMasterTemp/tmp.csv
			sed "s/^/$hostname,/" $configPath/collectlMasterTemp/tmp.csv >> $configPath/collectlMasterTemp/output/nfs.txt
		done
	
	else 
		echo "************Processing $fileType files***********"
		for myFile in `ls $configPath/collectlMasterTemp | grep -i .prc`
		do
			echo "==>************Processing $myFile file***********"
			hostname=`echo $myFile | cut -d "-" -f 2`
			#generate PROCESS metric file
			sed '/#/d' $configPath/collectlMasterTemp/$myFile | cut -d "," -f $PRC_COLS > $configPath/collectlMasterTemp/tmp.csv
			sed "s/^/$hostname,/" $configPath/collectlMasterTemp/tmp.csv >> $configPath/collectlMasterTemp/output/prc.txt
		done
	fi
}
#Loads the CSV files into Teradata database using multiload utility
storeValuesInDatabase ()
{
	rm -rf $configPath/collectlMasterTemp/output/*.csv
	
	echo "**********************Storing Disk Metrics**********************"
	mload < collectl_load_dsk.mload
	echo "**********************Storing Network Metrics**********************"
	mload < collectl_load_net.mload
	echo "**********************Storing Memory Metrics**********************"
	mload < collectl_load_mem.mload
	echo "**********************Storing CPU Metrics**********************"
	mload < collectl_load_cpu.mload
	echo "**********************Storing NFS Metrics**********************"
	mload < collectl_load_nfs.mload
	echo "**********************Storing Process Metrics**********************"
	mload < collectl_load_prc.mload
}

#Copy the raw collectl output from each node to the central TD master
processNodeMetricsFile () 
{
	configurationFilename=$1
	rm -rf $configPath/collectlMasterTemp/output
	mkdir $configPath/collectlMasterTemp/output
	while IFS=',' read -r HostAddress Username
	do
		if [[ (${#Username} == 0)||(${#HostAddress} == 0)]];then #check if variable #length is 0
			echo "==> Bad configuration file"
			exit
		fi 
		echo "==> Copying files from $HostAddress and path $metricsFilePath"
		scp $Username@$HostAddress:$metricsFilePath/* $configPath/collectlMasterTemp < /dev/null;
		if [[ $? -ne 0 ]]; then #if copy fails
			echo "==> Copying from $metricsFilePath path from node $HostAddress failed"
			exit
		fi
	done < $configurationFilename
	uncompressFiles #uncompress the node metrics dump files
	createMetricsCSV 'tab'
	createMetricsCSV 'prc'
	aggregateNodeMetrics
}



#Run Collectl as a daemon service on each node of the cluster
startCollectlService () 
{
	while IFS=',' read -r HostAddress Username 
	do
		if [[ (${#Username} == 0)||(${#HostAddress} == 0)]];then #check if variable #length is 0
			echo "==> Bad configuration file"
			exit
		fi
		ssh -l $Username $HostAddress exec '/etc/init.d/collectl start' < /dev/null;
		if [[ $? -ne 0 ]]; then #if copy fails
			echo "==> Failed to start collectl on node $HostAddress"
			exit
		else
			echo "==> Started collectl successfully on node $HostAddress"
		fi
	done < $1
}
#Stop Collectl daemon service on each node of the cluster
stopCollectlService () 
{
	while IFS=',' read -r HostAddress Username 
	do
		if [[ (${#Username} == 0)||(${#HostAddress} == 0)]];then #check if variable #length is 0
			echo "==> Bad configuration file"
			exit
		fi
		ssh -l $Username $HostAddress exec '/etc/init.d/collectl stop' < /dev/null;
		if [[ $? -ne 0 ]]; then #if copy fails 
			echo "==> Failed to stop collectl on node $HostAddress"
			exit
		else
			echo "==> Stopped collectl successfully on node $HostAddress"
		fi
	done < $1
}

#Collectl package is configured to output the metric files at /var/log/collectl path on each node
#Deletes past Collectl metric files from /var/log/collectl path of each node
cleanupClusterNodes () 
{
	while IFS=',' read -r HostAddress Username 
	do
		if [[ (${#Username} == 0)||(${#HostAddress} == 0)]];then #check if variable #length is 0
			echo "==> Bad configuration file"
			exit
		fi
		ssh -l $Username $HostAddress exec 'rm -rf /var/log/collectl' < /dev/null;
		if [[ $? -ne 0 ]]; then #if copy fails 
			echo "==> Failed to cleanup /var/log/collectl on node $HostAddress"
			exit
		else
			echo "==> Deleted files from /var/log/collectl successfully on node $HostAddress"
		fi
	done < $1
}

#Verify if collectl service is running on each cluster node
verifyCollectlService () 
{
	configFile=$1
	for line in $(cat $configFile);
	do
		HostAddress=`echo $line | cut -d "," -f 1`
		Username=`echo $line | cut -d "," -f 2`
		count=$(ssh -n -l $Username $HostAddress exec 'ps -ef | grep -i collectl | grep -v 'grep' | wc -l')
		#echo "count : $count"
		if [[ $count -eq 1 ]]; then #if copy fails 
			echo "==> Collectl service running successfully on node $HostAddress"
		else
			echo "==> Collectl service NOT running on node $HostAddress"
		fi
	done
}

#compute aggregates from generated output
aggregateNodeMetrics ()
{
	rm -rf $configPath/collectlMasterTemp/output/aggregates
	mkdir  $configPath/collectlMasterTemp/output/aggregates
	
	#aggregate CPU-metrics
	echo "hostname,user_cpu,nice,sys,wait,soft,steal,ideal,totl,guest" > $configPath/collectlMasterTemp/output/aggregates/aggregateCpu.txt
	
	awk -F, '{user[$1]+=$4;a+=$4;nice[$1]+=$5;b+=$5;sys[$1]+=$6;c+=$6;wait[$1]+=$7;d+=$7;soft[$1]+=$9;e+=$9;steal[$1]+=$10;f+=$10;ideal[$1]+=$11;g+=$11;totl[$1]+=$12;h+=$12;guest[$1]+=$13;i+=$13} END { for (hostname in user) {print hostname","user[hostname]","nice[hostname]","sys[hostname]","wait[hostname]","soft[hostname]","steal[hostname]","ideal[hostname]","totl[hostname]","guest[hostname]};print "Cluster,"a","b","c","d","e","f","g","h","i}' $configPath/collectlMasterTemp/output/cpu.txt >> $configPath/collectlMasterTemp/output/aggregates/aggregateCpu.txt
	
	#aggregate NET-metrics
	echo "hostname,RxPktTot,TxPktTot,RxKBTot,TxKBTot" > $configPath/collectlMasterTemp/output/aggregates/aggregateNet.txt
	
	awk -F, '{rxpkt[$1]+=$4;a+=$4;txpkt[$1]+=$5;b+=$5;rxkb[$1]+=$6;c+=$6;txkb[$1]+=$7;d+=$7} END { for (hostname in rxpkt) {print hostname","rxpkt[hostname]","txpkt[hostname]","rxkb[hostname]","txkb[hostname]}; print "Cluster,"a","b","c","d}' $configPath/collectlMasterTemp/output/net.txt >> $configPath/collectlMasterTemp/output/aggregates/aggregateNet.txt
	
	#aggregate DISK-metrics
	echo "hostname,ReadKBTot,WriteKBTot" > $configPath/collectlMasterTemp/output/aggregates/aggregateDsk.txt
	
	awk -F, '{readKBtot[$1]+=$7;a+=$7;writeKBtot[$1]+=$8;b+=$8} END { for (hostname in readKBtot) {print hostname","readKBtot[hostname]","writeKBtot[hostname]};print "Cluster,"a","b}' $configPath/collectlMasterTemp/output/dsk.txt >> $configPath/collectlMasterTemp/output/aggregates/aggregateDsk.txt
	
	#aggregate MEM-metrics
	echo "hostname,Tot,Used,Free,Shared,Buf,Cached" > $configPath/collectlMasterTemp/output/aggregates/aggregateMem.txt
	
	awk -F, '{Tot[$1]+=$4;a+=$4;Used[$1]+=$5;b+=$5;Free[$1]+=$6;c+=$6;Shared[$1]+=$7;d+=$7;Buf[$1]+=$8;e+=$8;Cached[$1]+=$9;f+=$9} END { for (hostname in Tot) {print hostname","Tot[hostname]","Used[hostname]","Free[hostname]","Shared[hostname]","Buf[hostname]","Cached[hostname]};print "Cluster,"a","b","c","d","e","f}' $configPath/collectlMasterTemp/output/mem.txt >> $configPath/collectlMasterTemp/output/aggregates/aggregateMem.txt
	
	#aggregate NFS-metrics
	echo "hostname,ReadsS,WritesS" > $configPath/collectlMasterTemp/output/aggregates/aggregateNfs.txt
	
	awk -F, '{ReadsS[$1]+=$4;a+=$4;WritesS[$1]+=$5;b+=$5} END { for (hostname in ReadsS) {print hostname","ReadsS[hostname]","WritesS[hostname]};print "Cluster,"a","b}' $configPath/collectlMasterTemp/output/nfs.txt >> $configPath/collectlMasterTemp/output/aggregates/aggregateNfs.txt
}

# Transform long options to short ones  cleanupClusterNodes
for arg in "$@"; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--install") set -- "$@" "-i" ;;
    "--start")   set -- "$@" "-s" ;;
	"--stop")   set -- "$@" "-c" ;;
	"--dump")   set -- "$@" "-d" ;;
	"--uninstall")   set -- "$@" "-u" ;;
	"--cleanup")   set -- "$@" "-z" ;;
	"--verify")   set -- "$@" "-v" ;;
    *)        set -- "$@" "$arg"
  esac
done

# Parse short options
OPTIND=1
while getopts "hisdcuzv" opt
do 
  case "$opt" in
    "h") Usage ; exit 0 ;;
    "i") initialize; installCollectl $configurationFilename ;;
    "s") initialize; startCollectlService $configurationFilename ;;
	"c") initialize; stopCollectlService $configurationFilename ;;
	"d") initialize; processNodeMetricsFile $configurationFilename; formatDate; storeValuesInDatabase ;;
	"u") initialize; uninstallCollectl $configurationFilename ;;
	"z") initialize; cleanupClusterNodes $configurationFilename ;;
	"v") initialize; verifyCollectlService $configurationFilename ;;
    "?") Usage ; exit 1 ;;
  esac
done
shift $(expr $OPTIND - 1) # remove options from positional parameters