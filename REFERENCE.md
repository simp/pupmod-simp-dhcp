# Reference
<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

**Classes**

* [`dhcp`](#dhcp): A selector for configuring the DHCP server or client
* [`dhcp::dhcpd`](#dhcpdhcpd): This class is used to start dhcpd and create dhcpd.conf

## Classes

### dhcp

The client portion has not yet been implemented.

#### Parameters

The following parameters are available in the `dhcp` class.

##### `is_client`

Data type: `Boolean`

Not yet implemented

Default value: `false`

##### `is_server`

Data type: `Boolean`

Denotes that the system is a DHCP server

Default value: `true`

### dhcp::dhcpd

This class is used to start dhcpd and create dhcpd.conf

#### Parameters

The following parameters are available in the `dhcp::dhcpd` class.

##### `package_name`

Data type: `String[1]`

The DHCP server package name

##### `enable_data_rsync`

Data type: `Boolean`

Enable the retrieval of the DHCP configuration from an rsync server

* NOTE: This will be disabled by default at some point in the future

Default value: `true`

##### `rsync_server`

Data type: `String[1]`

The address of the server from which to pull the DHCPD
configuration

Default value: simplib::lookup('simp_options::rsync::server', { 'default_value' => '127.0.0.1' })

##### `rsync_timeout`

Data type: `Stdlib::Compat::Integer`

The connection timeout when communicating with the rsync server

Default value: simplib::lookup('simp_options::rsync::timeout', { 'default_value' => '2' })

##### `dhcpd_conf`

Data type: `Optional[String[1]]`

The entire contents of the /etc/dhcpd.conf configuration file

* If this is set, `$enable_data_rsync` will be forced to `false`

Default value: `undef`

##### `firewall`

Data type: `Boolean`

Whether or not to include the SIMP iptables class

Default value: simplib::lookup('simp_options::firewall', { 'default_value' => false })

##### `logrotate`

Data type: `Boolean`

Whether or not to include the SIMP logrotate class

Default value: simplib::lookup('simp_options::logrotate', { 'default_value' => false })

##### `syslog`

Data type: `Boolean`

Whether or not to include the SIMP rsyslog class

Default value: simplib::lookup('simp_options::syslog', { 'default_value' => false })

##### `package_ensure`

Data type: `String[1]`

The ensure status of the dhcp package

Default value: simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })

##### `rsync_source`

Data type: `String[1]`



Default value: "dhcpd_${::environment}_${facts['os']['name']}/dhcpd.conf"

