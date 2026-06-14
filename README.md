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





FLOW STEP BY STEP
STEP           COMPONENT          ACTION                      HOW TO CHECK
1              USER               RUN SCRIPT                  ps aux | grep yes or Grafana UI dashboard
                                  yes > /dev/null &
2              Node Exporter      reports CPU usage           Prometheus UI: /targets – node_exporter state UP (normal)
                                  to Prometheus every 15s
3              Prometheus         Evaluates rule every 30s;   Prometheus UI: /alerts 
                                  if CPU >60% for 15s,
                                  sets alert to FIRING 
4              Alertmanager       Recieves firing alert        sudo journalctl -u alertmanager -f
                                  sends HTTP POST to
                                  JENKINS WEBHOOK URL

5              JENKINS            Authenticats via API token    JENKINS UI : job build history
                                  triggers build (Kill-CPU-Load)
                                  
6               Jenkins JOB       Runs yes_watcher.sh as user    Jenkins UI console build

7               Prometheus        CPU drops, alert resolves to OK   Prometheus UI:/ alert 

8               Grafana            Dashboard CPU spike recovery     Grafana node exporter FUll dashboard




TROUBLESHOOTING CHEATSHEET

Symptom                                     Likely cause	                                         Fix
Node Exporter target DOWN                   Node Exporter not running                           sudo systemctl restart node_exporter
Alert never becomes FIRING            	    CPU not high enough, or rule interval too long	    Lower threshold to 50%, reduce for: to 5s
Alertmanager log shows 403	                CSRF token missing or invalid	                      Use Basic Auth header with API token 
Jenkins build triggered but yes not killed	Jenkins user lacks permission                      	Verify sudoers entry and script ownership
Grafana no data                            	Data source not pointing to Prometheus	            Set URL http://localhost:9090 in Grafana datasource / 


Credits & Environment
OS: Ubuntu 24.04 LTS (WSL2 on Windows 10/11)

Tools: Prometheus 3.2.1, Node Exporter 1.9.0, Grafana 11.x, Jenkins 2.462, Alertmanager 0.28.0

Author:Socrates Reyes

Date: June 2026




