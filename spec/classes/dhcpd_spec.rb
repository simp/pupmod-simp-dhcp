require 'spec_helper'

file_content_7 = '/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true'
file_content_6 = '/sbin/service rsyslog restart > /dev/null 2>&1 || true'

describe 'dhcp::dhcpd' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:environment){'foo'}
      let(:facts) do
        facts
      end

      context 'in the foo environment' do
        it { is_expected.to create_class('dhcp::dhcpd') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('dhcp').with_ensure('latest') }
        it { is_expected.to contain_service('dhcpd').with({
            :ensure  =>'running',
            :require => ['File[/etc/dhcpd.conf]', 'Package[dhcp]']
          })
        }
        it { is_expected.to create_file('/etc/dhcp').with_ensure('directory') }
        it { is_expected.to create_file('/etc/dhcp/dhcpd.conf').with({
            :ensure  => 'file',
            :notify  => 'Rsync[dhcpd]',
            :require => 'File[/etc/dhcp]'
          })
        }
        it { is_expected.to create_file('/etc/dhcpd.conf').with({
            :ensure => 'symlink',
            :target => '/etc/dhcp/dhcpd.conf'
          })
        }
        it { is_expected.to contain_rsync('dhcpd').with({
            :source => "dhcpd_#{environment}_#{facts[:os][:name]}/dhcpd.conf"
          })
        }
        it { is_expected.to_not contain_iptables__rule('allow_bootp') }
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
        it { is_expected.to contain_iptables__rule('allow_bootp') }
        it { is_expected.to contain_logrotate__rule('dhcpd') }
        it { is_expected.to contain_rsyslog__rule__local('XX_dhcpd') }
        # it { require 'pry';binding.pry }

        if ['RedHat','CentOS','OracleLinux'].include?(facts[:operatingsystem])
          if facts[:operatingsystemmajrelease].to_s < '7'
            it { should contain_file('/etc/logrotate.simp.d/dhcpd').with_content(/#{file_content_6}/)}
          else
            it { should contain_file('/etc/logrotate.simp.d/dhcpd').with_content(/#{file_content_7}/)}
          end
        end

      end
    end
  end
end
