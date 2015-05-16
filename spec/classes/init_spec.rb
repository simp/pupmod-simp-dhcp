require 'spec_helper'

describe 'dhcp' do

  it { should create_class('dhcp') }

  context 'base' do
    it { should compile.with_all_deps }
    it { should contain_class('dhcp::dhcpd') }
  end
end
