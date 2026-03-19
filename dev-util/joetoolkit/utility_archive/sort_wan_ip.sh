source /usr/sbin/script_header_joetoo; for file in $(ls /home/joe/Dropbox/wan_ip/); do echo "$(cat /home/joe/Dropbox/wan_ip/$file)"; done | sort | uniq -c
