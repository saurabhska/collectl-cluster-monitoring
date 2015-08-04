# collectl-cluster-monitoring

Collectl is a very powerful and light weight tool (developed by Mark Seager) that can be used to monitor the cluster environment. It is very flexible and offers a large number of configuration parameters with several modes of operation. Using colmux on top of collectl we can see the performance metrics of each node of the cluster in a single view. But it does not provides a way to aggregate the CPU, IO, network and other metrics from all nodes in the cluster. Also, there is no direct way to store these metrics into a database for future reporting and adhoc querying.

This project involves extending the open-source collectl tool to capture the (hadoop but can be used with other clusters) cluster performance metrics and store them into the Teradata database. By default, it is configured to sample the metrics at the 2 second interval and collect the performance metrics for CPU, DISK, NETWORK, PROCESS, NFS, INTERRUPT and MEMORY subsystems.

The documentation of collectl can be found at - http://collectl.sourceforge.net/
Other Useful Links: http://www.rittmanmead.com/2014/12/linux-cluster-sysadmin-os-metric-monitoring-with-colmux/
                    http://rpm.pbone.net/index.php3/stat/45/idpl/17586165/numer/1/nazwa/collectl

Pre-Requisites: OpenSSH configuration between all the cluster nodes and the master node.
                Reference : http://www.thegeekstuff.com/2008/06/perform-ssh-and-scp-without-entering-password-on-openssh/

Driver Program : MasterCollectl.sh

Usage:
sh MasterCollectl.sh --install : Installs collectl on each of the cluster nodes whose information is mentioned in the nodesConfig.cfg file. The nodesConfig.cfg configuration file requires hostaddress and the username for each node.

sh MasterCollectl.sh --start : Starts the collectl daemon process on each node in the cluster whose information is mentioned in the nodesConfig.cfg file.

sh MasterCollectl.sh --stops : Stops the collectl daemon process on each node in the cluster whose information is mentioned in the nodesConfig.cfg file.

sh MasterCollectl.sh --dump : Copies the raw metrics collected by the collectl daemon processes to the master node, preprocesses them to generate the required CSVs, generates the aggregate outputs and stores them into the Teradata database. (It uses the Teradata multiload utility to load CSVs into the Teradata database, you can use the RDBMS specific utility to load the CSV into any other RDBMS of your choice).

sh MasterCollectl.sh --help : Displays the help information.

sh MasterCollectl.sh --verify : Verifies if the collectl daemon is running on each node of the cluster.

sh MasterCollectl.sh --cleanup : Deletes the old metric files from all nodes of the cluster specified in the nodesConfig.cfg file.
