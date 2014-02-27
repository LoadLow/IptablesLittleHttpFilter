IptablesLittleHttpFilter
========================

A little http filter written with iptables rules
The file containing the rules : << filter.sh >>.

<h4>How does it work?</h4>
These iptables rules allow 5 connections / 20 seconds and 30 connections max per host.
However, when an "HTTP packet" has been received from host ("HTTP", "POST" or "GET" chain found on received packet),
a token is set to this host and this host will be allowed to create 20 connections / 5 seconds. 
This token has a lifetime of 1800 seconds (30 mins).

<h4>What is required?</h4>
- Iptables,
- "recent" iptables module,
- "state" iptables module,
- "string" iptables module with "bm" algo,
- "connlimit" iptables module.

<h4>Recommended:</h4>
"recent" module should be configured with a much larger cache than the original configuration.
You can find an exemple here : http://unix.stackexchange.com/questions/76271/iptables-recent-module?answertab=active#answer-76280

<h4>Is it really effective?</h4>
This is effective if you receive a flood of "zombie connections".
It has been tested with 1000 ip zombies. The attack was blocked after the first 5 seconds. 
With basic iptables rules, this attack increased the CPU of the server, and it created big lags, 
even with LiteSpeed!
