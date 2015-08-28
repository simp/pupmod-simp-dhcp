require 'spec_helper'

describe 'dhcp::dhcpd' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      context "on #{os}" do
        it { should create_class('dhcp::dhcpd') }
        it { should compile.with_all_deps }
      
        it { should create_file('/etc/dhcp').with_ensure('directory') }
        it { should create_file('/etc/dhcp/dhcpd.conf').with({
            :ensure  => 'file',
            :notify  => 'Rsync[dhcpd]',
            :require => 'File[/etc/dhcp]'
          })
        }
      
        it { should create_file('/etc/dhcpd.conf').with({
            :ensure => 'symlink',
            :target => '/etc/dhcp/dhcpd.conf'
          })
        }
      
        it { should create_iptables_rule('allow_bootp') }
      
        it { should contain_package('dhcp').with_ensure('latest') }
      
        it { should contain_service('dhcpd').with({
            :ensure  =>'running',
            :require => ['File[/etc/dhcpd.conf]', 'Package[dhcp]']
          })
        }
      end
    end
  end
end

