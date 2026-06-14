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
Sudoers Entry       /etc/sudoers.d/jenkins-pkill                                                          Allows jenkins user to run script as soc without password


CONFIGURATION DETAILS
PROMETHEUS 
yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - "/opt/prometheus/rules/cpu_alert.yml"



Alert Rule (/opt/prometheus/rules/cpu_alert.yml)

groups:
  - name: cpu_alerts
    interval: 30s
    rules:
      - alert: HighCPULoad
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100) > 60
        for: 15s
        labels:
          severity: warning
        annotations:
          summary: "High CPU load on {{ $labels.instance }}"
          description: "CPU load > 60% for 15 seconds. Current value: {{ $value }}%"


3. Alertmanager (/etc/alertmanager/alertmanager.yml)
route:
  receiver: 'jenkins'
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h

receivers:
- name: 'jenkins'
  webhook_configs:
  - url: 'http://localhost:8080/job/Kill-CPU-Load/build?token=CPU123'
    send_resolved: true
    http_config:
      basic_auth:
        username: '###'
        password: "###"


4. Jenkins Job Kill-CPU-Load

Build Trigger: Remote API – token CPU123

Build Step: Execute shell

bash
sudo -u soc /home/soc/.local/bin/yes_watcher.sh



5. Remediation Script (/home/soc/.local/bin/yes_watcher.sh)

bash
# 1. Deletes the signal file 
rm -f /tmp/kill_yes.signal
# 2. Kills the target 'yes' processes 
/usr/bin/pkill -u soc -f ^yes$
# 3. Prints the completion message to your Jenkins console
echo "Remediation complete: 'yes' processes terminated."



6. Sudoers Entry (/etc/sudoers.d/jenkins-pkill)

 text
jenkins ALL=(soc) NOPASSWD: /home/soc/.local/bin/yes_watcher.sh







