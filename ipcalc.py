#!/usr/bin/env python
import ipaddress
import sys

if __name__ == "__main__":
  if len(sys.argv) != 2:
    sys.exit(1)

  gw = None

  try:
    iprange = ipaddress.ip_network(unicode(sys.argv[1]))
  except ValueError:
    nic = ipaddress.ip_interface(unicode(sys.argv[1]))
    iprange = nic.network
    gw = nic.ip

  print("export NETMASK=%s" % (iprange.netmask,))
  if not gw: 
    hosts = list(iprange.hosts())
    gw=hosts[0]
  else:
    hosts = [ip for ip in iprange.hosts() if ip>gw]
  print("export GW=%s" % (gw,))
  print("export DHCP_RANGE_START=%s" % (hosts[0],))
  print("export DHCP_RANGE_END=%s" % (hosts[-1],))

