require 'spec_helper'

describe 'dhcp::dhcpd' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:environment){'foo'}
      let(:facts) do
        os_facts
      end

      let(:file_content){
        if ['RedHat','CentOS','OracleLinux'].include?(os_facts[:operatingsystem])
          if os_facts[:operatingsystemmajrelease].to_s < '7'
            '/sbin/service rsyslog restart > /dev/null 2>&1 || true'
          else
            '/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true'
          end
        end
      }

      let(:package_name){
        if os_facts[:operatingsystemmajrelease].to_s < '8'
          'dhcp'
        else
          'dhcp-server'
        end
      }

      context 'in the foo environment' do
        it { is_expected.to create_class('dhcp::dhcpd') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package(package_name).with_ensure('installed') }
        it { is_expected.to contain_service('dhcpd').with({
            :ensure  =>'running',
            :require => ['File[/etc/dhcp/dhcpd.conf]', "Package[#{package_name}]"]
          })
        }
        it { is_expected.to create_file('/etc/dhcp').with_ensure('directory') }
        it { is_expected.to create_file('/etc/dhcp/dhcpd.conf').with_ensure('file') }
        it { is_expected.to create_file('/etc/dhcpd.conf').with({
            :ensure => 'symlink',
            :target => '/etc/dhcp/dhcpd.conf'
          })
        }
        it { is_expected.to contain_rsync('dhcpd').with({
            :source => "dhcpd_#{environment}_#{facts[:os][:name]}/dhcpd.conf",
            :subscribe => 'File[/etc/dhcp/dhcpd.conf]',
          })
        }
        it { is_expected.to_not contain_iptables__listen__udp('allow_bootp') }
        it { is_expected.to_not contain_logrotate__rule('dhcpd') }
        it { is_expected.to_not contain_rsyslog__rule__local ( 'XX_dhcpd' ) }
      end

      context 'with firewall => true, syslog => true, logrotate => true' do
        let(:params) {{
          :firewall  => true,
          :syslog    => true,
          :logrotate => true
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('dhcp::dhcpd') }
        it { is_expected.to contain_iptables__listen__udp('allow_bootp').with_dports([67]) }
        it { is_expected.to contain_logrotate__rule('dhcpd') }
        it { is_expected.to contain_rsyslog__rule__local('XX_dhcpd') }
        it { should contain_file('/etc/logrotate.simp.d/dhcpd').with_content(/#{file_content}/)}
      end
    end
  end
end
