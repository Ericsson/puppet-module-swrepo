require 'spec_helper'
describe 'swrepo::repo' do
  mandatory_params = {
    :repotype => 'yum',
    :baseurl  => 'http://spec.test/repo',
  }
  let(:title) { 'spectest-repo' }
  let(:params) { mandatory_params }

  describe 'with defaults for all parameters (mandatory parameters missing)' do
    let(:params) { {} }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(expects a value for|Must pass)/)
    end
  end

  describe 'with repotype specified (mandatory parameter incomplete)' do
    let(:params) { { :repotype => 'yum' } }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(expects a value for|Must pass)/)
    end
  end

  describe 'with baseurl specified (mandatory parameter incomplete)' do
    let(:params) { { :baseurl  => 'http://spec.test/repo' } }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(expects a value for|Must pass)/)
    end
  end

  describe 'with mandatory parameters specified' do
    let(:params) { mandatory_params }

    it do
      should contain_yumrepo('spectest-repo').with({
        'name'     => 'spectest-repo',
        'baseurl'  => 'http://spec.test/repo',
        'descr'    => nil,
        'enabled'  => '1',
        'gpgcheck' => nil,
        'gpgkey'   => nil,
        'priority' => nil,
        'exclude'  => nil,
        'proxy'    => nil,
      })
    end

    it { should have_yumrepo_resource_count(1) }
    it { should have_zypprepo_resource_count(0) }
    it { should have_rpmkey_resource_count(0) }
  end

  describe 'with repotype set to valid yum' do
    let(:params) { mandatory_params.merge({ :repotype => 'yum' }) }

    it { should contain_yumrepo('spectest-repo') }
    it { should have_yumrepo_resource_count(1) }
    it { should have_zypprepo_resource_count(0) }
    it { should have_rpmkey_resource_count(0) }
  end

  describe 'with repotype set to valid zypper' do
    let(:params) { mandatory_params.merge({ :repotype => 'zypper' }) }

    it { should contain_zypprepo('spectest-repo') }
    it { should have_yumrepo_resource_count(0) }
    it { should have_zypprepo_resource_count(1) }
    it { should have_rpmkey_resource_count(0) }
  end

  describe 'with repotype set to valid apt (no functionality yet)' do
    let(:params) { mandatory_params.merge({ :repotype => 'apt' }) }

    # only prints out the notice 'apt support coming'
    it { should have_yumrepo_resource_count(0) }
    it { should have_zypprepo_resource_count(0) }
    it { should have_rpmkey_resource_count(0) }
  end

  # Repository handling
  %w[yum zypper].each do |repotype|
    describe "with repotype set to #{repotype}" do

      context 'when baseurl is set to valid string http://specific.url/REPO' do
        let(:params) {
          mandatory_params.merge({
            :baseurl  => 'http://specific.url/REPO',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_baseurl('http://specific.url/REPO') }
        else
          it { should contain_zypprepo('spectest-repo').with_baseurl('http://specific.url/REPO') }
        end
      end


      context 'when baseurl contains uppercases and downcase_baseurl set to boolean true' do
        let(:params) {
          mandatory_params.merge({
            :baseurl          => 'http://specific.url/REPO',
            :downcase_baseurl => true,
            :repotype         => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_baseurl('http://specific.url/repo') }
        else
          it { should contain_zypprepo('spectest-repo').with_baseurl('http://specific.url/repo') }
        end
      end

      context 'when enabled is set to valid string 0' do
        let(:params) {
          mandatory_params.merge({
            :enabled  => '0',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_enabled('0') }
        else
          it { should contain_zypprepo('spectest-repo').with_enabled('0') }
        end
      end

      context 'when autorefresh is set to valid string 1' do
        let(:params) {
          mandatory_params.merge({
            :autorefresh  => '1',
            :repotype     => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_autorefresh }
        else
          it { should contain_zypprepo('spectest-repo').with_autorefresh('1') }
        end
      end

      context 'when gpgcheck is set to valid string 1' do
        let(:params) {
          mandatory_params.merge({
            :gpgcheck => '1',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_gpgcheck('1') }
        else
          it { should contain_zypprepo('spectest-repo').with_gpgcheck('1') }
        end
      end

      context 'when gpgkey_source is set to valid string http://path.to/gpgkey' do
        let(:params) {
          mandatory_params.merge({
            :gpgkey_source => 'http://path.to/gpgkey',
            :repotype      => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_gpgkey('http://path.to/gpgkey') }
        else
          it { should contain_zypprepo('spectest-repo').with_gpgkey('http://path.to/gpgkey') }
        end
      end

      context 'when priority is set to valid string 42' do
        let(:params) {
          mandatory_params.merge({
            :priority => '42',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_priority('42') }
        else
          it { should contain_zypprepo('spectest-repo').with_priority('42') }
        end
      end

      context 'when keeppackages is set to valid string 1' do
        let(:params) {
          mandatory_params.merge({
            :keeppackages => '1',
            :repotype     => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_keeppackages }
        else
          it { should contain_zypprepo('spectest-repo').with_keeppackages('1') }
        end
      end

      context 'when type is set to valid string 1' do
        let(:params) {
          mandatory_params.merge({
            :type     => '1',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_type }
        else
          it { should contain_zypprepo('spectest-repo').with_type('1') }
        end
      end

      context 'when descr is set to valid string custom-repo' do
        let(:params) {
          mandatory_params.merge({
            :descr    => 'custom-repo',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_descr('custom-repo') }
        else
          it { should contain_zypprepo('spectest-repo').with_descr('custom-repo') }
        end
      end

      context 'when exclude is set to valid string not_me' do
        let(:params) {
          mandatory_params.merge({
            :exclude  => 'not_me',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_exclude('not_me') }
        else
          it { should contain_zypprepo('spectest-repo').without_exclude }
        end
      end

      context 'when proxy is set to valid string http://proxy.test' do
        let(:params) {
          mandatory_params.merge({
            :proxy    => 'http://proxy.test',
            :repotype => repotype,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_proxy('http://proxy.test') }
        else
          it { should contain_zypprepo('spectest-repo').without_proxy }
        end
      end

    end
  end # %w[yum zypper].each do |repotype|

  # RPM Key handling
  describe 'with gpgkey_keyid set to valid string 0608B895' do
    let(:params) {
      mandatory_params.merge({
        :gpgkey_keyid => '0608B895',
      })
    }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /swrepo::repo::gpgkey_keyid is specified but swrepo::repo::gpgkey_source is missing/)
    end
  end

  describe 'with gpgkey_source set to valid string http://url.to/gpgkey' do
    let(:params) {
      mandatory_params.merge({
        :gpgkey_source => 'http://url.to/gpgkey',
      })
    }
    it { should have_rpmkey_resource_count(0) }
  end

  describe 'with gpgkey_keyid and gpgkey_source are both set to valid strings' do
    let(:params) {
      mandatory_params.merge({
        :gpgkey_keyid => '0608B895',
        :gpgkey_source => 'http://url.to/gpgkey',
      })
    }
    it { should have_rpmkey_resource_count(1) }
    it do
      should contain_rpmkey('0608B895').with({
        'ensure' => 'present',
        'source' => 'http://url.to/gpgkey',
      })
    end
  end
end
