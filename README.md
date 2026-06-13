nano README.md


Overview
This project monitors CPU usage on a Linux system (Ubuntu/WSL2). When CPU exceeds 60% for 15 seconds, Prometheus triggers an alert. Alertmanager sends an authenticated webhook to Jenkins, which runs a script that kills the offending yes process. The entire loop is visible in Grafana dashboards.

Architecture Diagram
UBUNTU SERVER [Node Exporter] --(metrics)--> [Prometheus] --(alert)--> [Alertmanager]  --(webhook)--> [Jenkins] --(executes)--> [yes_watcher.sh] --(kills)--> [yes process]                                                                    ^
                                                                            +-- uses API token for authentication

 
 File Locations (on Ubuntu/WSL2)   

 
Node Exporter       /usr/local/bin/node_exporter/etc/systemd/system/node_exporter.service                                     Exposes system metrics on port 9100
Prometheus          /opt/prometheus/prometheus.yml/opt/prometheus/rules/cpu_alert.yml/etc/systemd/system/prometheus.service   Scrapes metrics, evaluates alert rules
Alertmanager        /etc/alertmanager/alertmanager.yml/etc/systemd/system/alertmanager.service                             Receives alerts, sends webhook to Jenkins
Jenkins             /var/lib/jenkins/ (home)/etc/default/jenkinsJob: Kill-CPU-Load (configured via UI)                   Runs remediation script on webhook trigger 
Remediation Script  /home/soc/.local/bin/yes_watcher.sh                                                                  Kills all yes processes owned by soc
Sudoers Entry       /etc/sudoers.d/jenkins-pkill                                                                          Allows jenkins user to run script as soc without password
