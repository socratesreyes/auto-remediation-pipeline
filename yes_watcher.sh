#!/bin/bash
#while true; do
#    # Only act if the signal file exists
#    if [ -f /tmp/kill_yes.signal ]; then
#        echo "Signal received from Jenkins! Clearing CPU load..."
        
#        # 1. Delete the signal file immediately so it doesn't loop
#        rm -f /tmp/kill_yes.signal
        
        # 2. Kill the current running 'yes' processes once
#        /usr/bin/pkill -u soc -f ^yes$
#    fi
    
#    # Wait 1 second before checking again to keep your CPU calm
#    sleep 1
#done

#!/bin/bash
#echo "Jenkins triggered a CPU cleanup!"

# 1. Kill the 'yes' processes once
#/usr/bin/pkill -u soc -f ^yes$

# 2. Tell systemd to stop this service immediately
#systemctl --user stop yes-watcher.service




################################################


#!/bin/bash

# 1. Delete the signal file so it doesn't get stuck
#rm -f /tmp/kill_yes.signal

# 2. Kill the 'yes' processes once
#/usr/bin/pkill -u soc -f ^yes$

# 3. Stop the service completely so it stops watching
#systemctl --user stop yes-watcher.service


#####################################################





#!/bin/bash
#echo "Watcher started. Waiting for Jenkins signal..."

#while true; do
#    # Check if the signal file exists
#    if [ -f /tmp/kill_yes.signal ]; then
#        echo "Signal detected! Cleaning up..."
        
        # 1. Delete the signal file immediately
#        rm -f /tmp/kill_yes.signal
        
        # 2. Kill the 'yes' processes
#        /usr/bin/pkill -u soc -f ^yes$
        
        # 3. Self-destruct: Stop this service completely
#        systemctl --user stop yes-watcher.service
        
        # Exit the script execution
#        exit 0
#    fi
    
    # Check every half second to keep CPU usage low
#    sleep 0.5
#done


##################

#!/bin/bash

# 1. Deletes the signal file (Takes less than a millisecond)
rm -f /tmp/kill_yes.signal

# 2. Kills the target 'yes' processes (Takes less than a millisecond)
/usr/bin/pkill -u soc -f ^yes$

# 3. Prints the completion message to your Jenkins console
echo "Remediation complete: 'yes' processes terminated."

# <-- There are no more lines here!
# The script has reached the end of the file.
# The system automatically destroys this script process right here.

