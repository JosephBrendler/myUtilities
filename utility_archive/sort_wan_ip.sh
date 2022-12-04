source /usr/local/sbin/script_header_brendlefly; for file in $(ls /home/joe/Dropbox/wan_ip/); do echo "$(cat /home/joe/Dropbox/wan_ip/$file)"; done | sort | uniq -c
