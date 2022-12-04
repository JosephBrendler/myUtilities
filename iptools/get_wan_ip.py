#!/usr/bin/env python
# get_wan_ip.py  joe brendler  10 Dec 16
# scrape the network ipaddress my router is getting from the ISP, so I can
# use it separately from remote locations to target inbound vpn connections
# (NOTE: the trick is getting the urls and the value keys correct
#        e.g. it's "loginUsername", not "username" -- inspect the website's source
#        in order to glean the right info for these variables. And, of course,
#        don't forget to use the actual username and password)

import requests


# set these to whatever your account is
#login_url = 'http://10.17.31.1/goform/home_loggedout'
#query_url = 'http://10.17.31.1/vendor_network.asp'
login_url = 'http://192.168.1.1/index.html'
query_url = 'http://192.168.1.1/index.cgi?active_page=9132&active_page_str=page_home_act_vz&req_mode=0&mimic_button_field=submit_button_login_submit%3A+..&strip_page_top=0&button_value='
values = {'loginUsername': 'brendler',
          'loginPassword': '............'}

r = requests.post(login_url, data=values)
r = requests.get(query_url)
print r.content
