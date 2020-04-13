#!/bin/bash
set -ue

cd "$(dirname $(readlink -f "${BASH_SOURCE}"))"
source config.sh

function print_help() {
  echo -e "Required parameters:"
  echo -e "\t-n\tnetwork name"
  echo -e "\t-a\taddress range (e.g. 192.168.123.1/24)"
  echo -e "Optional parameters:"
  echo -e "\t-d\tdomain to use for the network"
}

function generate_mac() {
  local iprange=$1
  local seed=$(hostname -f)-${iprange}
  macaddr=$(echo $seed|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
  echo $macaddr
}

function calculate_ip() {
  local iprange=$1
  source <(./ipcalc.py $iprange)
}

function find_bridge_number() {
  current_count=$(ip l show type bridge | grep virbr | wc -l)
  if ! ip link show virbr${current_count} &>/dev/null; then
    echo ${current_count}
  else 
    echo $(( current_count + 1 ))
  fi
}

function generate_config() {
  cat <<EOT
<network>
  <name>${NETWORK_NAME}</name>
  <uuid>$(uuidgen)</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr${BRIDGE_NUMBER}' stp='on' delay='0'/>
  <mac address='${GENERATED_MAC}'/>
  <domain name='${DOMAIN}' localOnly='yes'/>
  <ip address='${GW}' netmask='${NETMASK}'>
    <dhcp>
      <range start='${DHCP_RANGE_START}' end='${DHCP_RANGE_END}'/>
    </dhcp>
  </ip>
</network>
EOT
}

NETWORK_NAME=""
IPRANGE=""
DOMAIN="kvm.local"

while getopts "n:a:d:h" opt; do
  case $opt in
    n) NETWORK_NAME=${OPTARG} ;;
    a) IPRANGE=${OPTARG} ;;
    d) DOMAIN=${OPTARG} ;;
    h|*) print_help; exit 1 ;;
  esac
done

if [[ -z "$NETWORK_NAME" ]] || [[ -z "$IPRANGE" ]]; then
  echo "NETWORK_NAME and IPRANGE are required to proceed..."
fi

GENERATED_MAC=$(generate_mac $IPRANGE)
calculate_ip $IPRANGE
BRIDGE_NUMBER=$(find_bridge_number)

cat <<EOT
Creating network "${NETWORK_NAME}" on interface virbr${BRIDGE_NUMBER}.
Gateway address: ${GW}
Netmask: ${NETMASK}
DHCP Range: ${DHCP_RANGE_START}-${DHCP_RANGE_END}
using domain: ${DOMAIN}
EOT

generate_config >${NETWORK_NAME}.xml
editor ${NETWORK_NAME}.xml
echo Adding new network...
virsh net-create --file ${NETWORK_NAME}.xml
rc=$?
if [[ $rc -eq 0 ]]; then
  cat <<EOT
Network ready to use! To use it in dnsmasq as local domain, add following lines to config:
server=/${DOMAIN}/${GW}
EOT
else
  echo "There was some error..."
  exit 1
fi
