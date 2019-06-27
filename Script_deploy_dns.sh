 #!/bin/bash
#
# Simple script to generate a basic bind configuration for home/lab use
#

# Local config - adjust as required
OWNIP=192.168.100.161
NETWORK=192.168.100.0
NETMASK=/24
DNS1=192.168.100.116
DNS2=

# Advanced - should not be changed
DOMAIN=dupont.lan

# Internal - must not be changed
CONFDIR=/etc/bind



# Let's go - make sure we're in the right path
if [[ ! -d "${CONFDIR}" ]]
  then
	echo "ERROR: configuration path ${CONFDIR} does not exist, exiting"
	exit 1
  else
	echo "Configuration path ${CONFDIR}"
	cd $CONFDIR || exit 1
  fi

# Stop bind
echo "Stopping bind9 daemon..."
service bind9 stop

# Remove the root zone servers, we don't want to query these directly
[[ ! -f db.root.original ]] && mv db.root db.root.original
cat > db.root <<- EOF
\$TTL	2592000
@	IN	SOA	localhost. root.localhost. (
 			1		; Serial
 			2592000		; Refresh
 			86400		; Retry
 			2592000		; Expire
 			2592000		; Negative Cache TTL
			)
;
@	IN	NS	localhost.
EOF
echo "Created db.root"

# Set bind options and upstream DNS servers
[[ ! -f named.conf.options.original ]] && mv named.conf.options named.conf.options.original
cat > named.conf.options <<- EOF
options {
 	directory "/var/cache/bind";
 	auth-nxdomain no;
 	listen-on { any; };
 	listen-on-v6 { any; };
 	allow-recursion { 127.0.0.1; ${NETWORK}${NETMASK}; };
EOF
printf "\tforwarders { ${DNS1}" >> named.conf.options
[[ -n "${DNS2}" ]] && printf "; ${DNS2}" >> named.conf.options
printf "; };\n};\n" >> named.conf.options
echo "Created named.conf.options"

# Configure the local domain
[[ ! -f named.conf.local.original ]] && mv named.conf.local named.conf.local.original
REVADDR=$(for FIELD in 3 2 1; do printf "$(echo ${NETWORK} | cut -d '.' -f $FIELD)."; done)
cat > named.conf.local <<- EOF
zone "${DOMAIN}" {
 	type master;
 	notify no;
 	file "${CONFDIR}/db.${DOMAIN}";
};
zone "${REVADDR}in-addr.arpa" {
 	type master;
 	notify no;
 	file "${CONFDIR}/db.${REVADDR}in-addr.arpa";
};
include "${CONFDIR}/zones.rfc1918";
EOF
echo "Created named.conf.local"

# Populate the forward zone
SERIAL="$(date '+%Y%m%d')01"
NET="$(echo ${NETWORK} | cut -d '.' -f 1-3)"
cat > db.${DOMAIN} <<- EOF
\$ORIGIN ${DOMAIN}.
\$TTL	1d
@	IN	SOA	localhost. root.localhost. (
 			${SERIAL}	; Serial
 			86400		; Refresh
 			7200		; Retry
 			2592000		; Expire
 			172800		; Negative Cache TTL
 			)
 	IN	NS	dns.${DOMAIN}.
;
dns		IN	A	${OWNIP}
ntp		IN	CNAME	dns.${DOMAIN}.
esxi01		IN	A	${NET}.11
esxi02		IN	A	${NET}.12
esxi03		IN	A	${NET}.13
esxi04		IN	A	${NET}.14
;
vcenter		IN	A	${NET}.20
vma		IN	A	${NET}.21
EOF
echo "Populated forward zone file db.${DOMAIN} for ${DOMAIN}"

# Populate the reverse zone
OWNH="$(echo ${OWNIP} | cut -d '.' -f 4)"
cat > db.${REVADDR}in-addr.arpa <<- EOF
\$ORIGIN ${REVADDR}in-addr.arpa.
\$TTL	1d
@	IN	SOA	localhost. root.localhost. (
 			${SERIAL}	; Serial
 			86400		; Refresh
 			7200		; Retry
 			2592000		; Expire
 			172800		; Negative Cache TTL
 			)
 	IN	NS	dns.${DOMAIN}.
;
${OWNH}	IN	PTR	dns.${DOMAIN}.
;
11	IN	PTR	esxi01.${DOMAIN}.
12	IN	PTR	esxi02.${DOMAIN}.
13	IN	PTR	esxi03.${DOMAIN}.
14	IN	PTR	esxi04.${DOMAIN}.
;
20	IN	PTR	vcenter.${DOMAIN}.
21	IN	PTR	vma.${DOMAIN}.
EOF
echo "Populated reverse zone file db.${REVADDR}in-addr.arpa for ${NET}"

# Enable local DNS server
[[ ! -f /etc/resolv.conf.original ]] && mv /etc/resolv.conf /etc/resolv.conf.original
cat > /etc/resolv.conf <<- EOF
domain ${DOMAIN}
search ${DOMAIN}
nameserver ${OWNIP}
EOF
echo "Enabled local DNS server in /etc/resolv.conf"

# Start bind
echo "Starting bind9 daemon..."
service bind9 start

# Done
echo "Done."