# == Class: dhcp
#
# This class provides an input selector for configuring the DHCP
# server or client.
#
# The client portion has not yet been implemented.
#
# Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class dhcp (
  Boolean $is_client = false,
  Boolean $is_server = true
){
  if $is_client {
    notify { 'dhcp::client is not yet implemented': }
  }

  if $is_server {
    include 'dhcp::dhcpd'
  }
}
