require 'spec_helper'
describe 'swrepo' do

  describe 'with default values for parameters' do
    context "where osfamily is RedHat" do
      let :facts do
        { :osfamily => 'RedHat' }
      end
      it { should contain_class('swrepo') }
    end

    context "where osfamily is Suse 11" do
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end
      it { should contain_class('swrepo') }
    end

    context "where osfamily is Suse 10" do
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '10',
        }
      end
      it 'should fail' do
        expect {
          should contain_class('swrepo')
        }.to raise_error(Puppet::Error,/Suse 10 not yet supported/)
      end
    end

    context "where Suse version is unsupported" do
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '12',
        }
      end
      it 'should fail' do
        expect {
          should contain_class('swrepo')
        }.to raise_error(Puppet::Error,/Unsupported Suse version/)
      end
    end

    context "where osfamily is Debian" do
      let :facts do
        { :osfamily => 'Debian' }
      end
      it 'should fail' do
        expect {
          should contain_class('swrepo')
        }.to raise_error(Puppet::Error,/Debian not yet supported/)
      end
    end

    context "with unsupported osfamily" do
      let :facts do
        { :osfamily => 'Solaris' }
      end
      it 'should fail' do
        expect {
          should contain_class('swrepo')
        }.to raise_error(Puppet::Error,/Supported osfamilies are RedHat, Suse and Debian/)
      end
    end
  end

end
