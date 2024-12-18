require 'spec_helper'

describe 'dhcp::dhcpd' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:environment) { 'foo' }
      let(:facts) { os_facts }

      let(:file_content) do
        '/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true'
      end

      let(:package_name) do
        if os_facts[:os][:release][:major].to_s < '8'
          'dhcp'
        else
          'dhcp-server'
        end
      end

      context 'in the foo environment' do
        it { is_expected.to create_class('dhcp::dhcpd') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package(package_name).with_ensure('installed') }
        it do
          is_expected.to contain_service('dhcpd')
            .with(
              ensure: 'running',
              require: ['File[/etc/dhcp/dhcpd.conf]', "Package[#{package_name}]"],
            )
        end
        it { is_expected.to create_file('/etc/dhcp').with_ensure('directory') }
        it { is_expected.to create_file('/etc/dhcp/dhcpd.conf').with_ensure('file') }
        it do
          is_expected.to create_file('/etc/dhcpd.conf')
            .with(
              ensure: 'symlink',
              target: '/etc/dhcp/dhcpd.conf',
            )
        end
        it do
          is_expected.to contain_rsync('dhcpd')
            .with(
              source: "dhcpd_#{environment}_#{facts[:os][:name]}/dhcpd.conf",
              subscribe: 'File[/etc/dhcp/dhcpd.conf]',
            )
        end
        it { is_expected.not_to contain_iptables__listen__udp('allow_bootp') }
        it { is_expected.not_to contain_logrotate__rule('dhcpd') }
        it { is_expected.not_to contain_rsyslog__rule__local('XX_dhcpd') }
      end

      context 'with firewall => true, syslog => true, logrotate => true' do
        let(:params) do
          {
            firewall: true,
            syslog: true,
            logrotate: true,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('dhcp::dhcpd') }
        it { is_expected.to contain_iptables__listen__udp('allow_bootp').with_dports([67]) }
        it { is_expected.to contain_logrotate__rule('dhcpd') }
        it { is_expected.to contain_rsyslog__rule__local('XX_dhcpd') }
        it { is_expected.to contain_file('/etc/logrotate.simp.d/dhcpd').with_content(%r{#{file_content}}) }
      end
    end
  end
end
