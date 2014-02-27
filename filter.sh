#Create Network Chains
	iptables -N ESTABLISHED_CONNECTION
	iptables -N HTTP_PACKETS_TO_FILTER
	iptables -N HTTP_PACKETS_FILTERED
	iptables -N HTTP_PACKET_RECEIVED

#Ignore local network
	iptables -A INPUT -s 127.0.0.1 -j IN_LOCAL_NETWORK
	iptables -A INPUT -i lo -j IN_LOCAL_NETWORK

#Set in another rule established connections
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ESTABLISHED_CONNECTION

#Established Connection => TCP://80 ? => To HTTP Filter
	iptables -A ESTABLISHED_CONNECTION -p tcp --dport 80 -j HTTP_PACKETS_TO_FILTER

#Accept local network
	iptables -A IN_LOCAL_NETWORK -j ACCEPT	

#Accept established connections (already filtered)
	iptables -A ESTABLISHED_CONNECTION -j ACCEPT	

#Set max connections per ip on HTTP Port
	iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 30 -j DROP

#Jump new connection to HTTP_PACKETS_FILTERED if connection has "HTTP_FILTERED_TOKEN" token
	iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --name HTTP_FILTERED_TOKEN --update --seconds 1800 --hitcount 1 --rttl -j HTTP_PACKETS_FILTERED

#HTTP Filtered/Accepted Host => Host can create 20 connections / 5 seconds
	iptables -A HTTP_PACKETS_FILTERED -m recent --name HTTP_FILTERED_TOKEN --set
	iptables -A HTTP_PACKETS_FILTERED -m recent --name BLACKLIST_80 --set
	iptables -A HTTP_PACKETS_FILTERED -m recent --name BLACKLIST_80 --rcheck --seconds 5 --hitcount 20 --rttl -j DROP
	iptables -A HTTP_PACKETS_FILTERED -j ACCEPT

#NonFiltered / NonAccepted Host => Host can only create 5 connections / 30 seconds
	iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --name BLACKLIST_GUEST_80 --set
	iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --name BLACKLIST_GUEST_80 --rcheck --seconds 30 --hitcount 5 --rttl -j DROP
	iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	
#Accept packets of a connection set in HTTP_PACKETS_TO_FILTER that contains "HTTP_FILTERED_TOKEN" token => Already filtered
	iptables -A HTTP_PACKETS_TO_FILTER -m recent --name HTTP_FILTERED_TOKEN --update --seconds 1800 --hitcount 1 -j ACCEPT
	
#Match any "HTTP packet" => received "HTT packet" ?? => set connection to "HTTP_PACKET_RECEIVED"
	iptables -A HTTP_PACKETS_TO_FILTER -p tcp --dport 80 -m string --algo bm --string 'HTTP' -j HTTP_PACKET_RECEIVED
	iptables -A HTTP_PACKETS_TO_FILTER -p tcp --dport 80 -m string --algo bm --string 'POST' -j HTTP_PACKET_RECEIVED
	iptables -A HTTP_PACKETS_TO_FILTER -p tcp --dport 80 -m string --algo bm --string 'GET' -j HTTP_PACKET_RECEIVED
	
#if "HTTP packet" has been received, set the "HTTP_FILTERED_TOKEN" token to this host
	iptables -A HTTP_PACKET_RECEIVED -m recent --name HTTP_FILTERED_TOKEN --set
	
#Finally, accept packets from "HTTP_PACKET_RECEIVED" and "HTTP_PACKETS_TO_FILTER"(already filtered) connections
	iptables -A HTTP_PACKET_RECEIVED -j ACCEPT
	iptables -A HTTP_PACKETS_TO_FILTER -j ACCEPT