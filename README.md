# collectl

Extending the open-source collectl tool to capture the hadoop cluster performance metrics and store them into the Teradata database.

Driver Program : MasterCollectl.sh

Usage:
sh MasterCollectl.sh --install : Installs collectl on each of the cluster nodes whose information is mentioned in the nodesConfig.cfg file. By default collectl is configured to sample performance metrics every 2 seconds and generate the raw CSV files at /var/log/collectl location.
collectl.conf : DaemonCommands = -f /var/log/collectl/daemon -P --sep , -scdnfjxmZ --align -F60 -m -i2

