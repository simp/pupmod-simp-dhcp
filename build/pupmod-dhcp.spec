Summary: Dhcp Puppet Module
Name: pupmod-dhcp
Version: 4.1.0
Release: 4
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-iptables >= 4.1.0-3
Requires: pupmod-logrotate >= 4.1.0
Requires: pupmod-rsyslog >= 5.0.0
Requires: pupmod-rsync >= 4.0.1-14
Requires: puppet >= 3.3.0
Requires: simp_bootstrap >= 4.1.0-2
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-dhcp-test

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to configure dhcpd.
Configuration files are pulled over rsync.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/dhcp

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/dhcp
done

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/dhcp

%files
%defattr(0640,root,puppet,0750)
%{prefix}/dhcp

%post
#!/bin/sh

if [ -d %{prefix}/dhcp/plugins ]; then
  /bin/mv %{prefix}/dhcp/plugins %{prefix}/dhcp/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Fri Jul 21 2015 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-4
- Updated to use new rsyslog module.

* Fri Feb 27 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- Updated to use the new 'simp' environment.
- Changed calls directly to /etc/init.d/rsyslog to '/sbin/service rsyslog' so
  that both RHEL6 and RHEL7 are properly supported.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-2
- Changed puppet-server requirement to puppet

* Tue Jun 24 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-1
- Modified all checksums to be sha256 instead of md5 in an effort
  to enable FIPS.

* Wed Apr 16 2014 Kendall Moore <kmoore@keywcorp.com>
- Added spec tests.

* Mon Apr 14 2014 Trevor Vaughan <tvaughan@onyxpoint.com>
- Tidied up the code to work with Hiera.

* Mon Dec 10 2013 Kendall Moore <kmoore@keywcorp.com>
- Updated to new code documentation format.

* Mon Feb 25 2013 Maintenance
4.0.1-3
- Added a call to $::rsync_timeout to the rsync call since it is now required.
- Created a Cucumber test that configures and tests dhcp.

* Tue Oct 23 2012 Maintenance
4.0.1-2
- Updated the rsyslog rule to be more concise.

* Wed May 03 2012 Maintenance
4.0.1-1
- Linked /etc/dhcpd.conf to /etc/dhcp/dhcpd.conf for consistency between RHEL5
  and RHEL6.
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Maintenance
4.0.1-0
- Improved test stubs.
- DHCP is now set to no longer timeout at boot time. It will, by default, wait
  for a 7 days prior to failing.

* Mon Jan 30 2012 Maintenance
4.0-3
- Added test stubs

* Mon Dec 26 2011 Maintenance
4.0-2
- Updated the spec file to not require a separate file list.

* Mon Nov 07 2011 Maintenance
4.0-1
- Fixed call to rsyslog restart for RHEL6.

* Tue Jul 12 2011 Maintenance
4.0-0
- Use new RHEL6 location for dhcpd.conf.

* Tue Mar 29 2011 Maintenance - 2.0.0-2
- The dhcp module now expects to have an associated rsync space that is
  password protected.
- Modified to use a lower number for rsyslog so that the default rules would
  start at the appropriate location.

* Fri Feb 04 2011 Maintenance - 2.0.0-1
- Changed all instances of defined(Class['foo']) to defined('foo') per the
  directions from the Puppet mailing list.
- Updated to use rsync native type

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Tue Oct 26 2010 Maintenance - 1-2
- Converting all spec files to check for directories prior to copy.

* Tue Jun 10 2010 Maintenance
1.0-1
- No templates to copy in caused an RPM build failure.

* Thu Jun 10 2010 Maintenance
1.0-0
- Dhcpd now writes to /var/log/dhcpd.log
- Addition of pupmod-iptables, pupmod-rsyslog, and pupmod-logrotate to the requires list.
- Code refactor and doc update.

