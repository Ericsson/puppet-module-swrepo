require 'spec_helper'
describe 'swrepo' do

  supported_os_families = {
    'RedHat'  => { :os => 'RedHat',  :lsbmajdist => '7',  :repotype => 'yum' },
    'Suse-11' => { :os => 'Suse',    :lsbmajdist => '11', :repotype => 'zypper' },
    'Suse-12' => { :os => 'Suse',    :lsbmajdist => '12', :repotype => 'zypper' },
  }

  unsupported_os_families = {
    'Suse-10' => { :os => 'Suse',    :lsbmajdist => '10', :repotype => nil },
    'Unknown' => { :os => 'Unknown', :lsbmajdist => '3',  :repotype => nil },
  }

  repos_hash = {
    'params-hash1' => { 'baseurl' => 'http://params.hash/repo1' },
    'params-hash2' => { 'baseurl' => 'http://params.hash/repo2' },
  }

  # ensure that the class is passive by default
  describe 'when all parameters are unset (unsing module defaults)' do
    it { should compile.with_all_deps }
    it { should contain_class('swrepo') }
    it { should have_resource_count(0) }
  end

  # ensure repotype can be set freely on any supported os
  %w(yum zypper).each do | repotype|
    describe "when repotype is set to the valid string #{repotype}" do
      let(:params) { { :repotype => repotype } }
      it { should have_swrepo__repo_resource_count(0) }

      supported_os_families.sort.each do |os, facts|
        context "with repos set to a valid hash on supported #{os}" do
          let(:facts) do
            {
              :osfamily          => facts[:os],
              :lsbmajdistrelease => facts[:lsbmajdist],
            }
            end
          let(:params) { { :repos => repos_hash}.merge({ :repotype => repotype }) }
          it { should have_swrepo__repo_resource_count(2) }
          it { should contain_swrepo__repo('params-hash1').with_repotype(repotype) }
          it { should contain_swrepo__repo('params-hash2').with_repotype(repotype) }
        end
      end
    end
  end

  # ensure repos hash is creating resources
  # ensure repotype will be set automatically
  supported_os_families.sort.each do |os, facts|
    describe "when repos is set to a valid hash on supported #{os}" do
      let(:facts) do
        {
          :osfamily          => facts[:os],
          :lsbmajdistrelease => facts[:lsbmajdist],
        }
      end
      let(:params) { { :repos => repos_hash } }
      it { should have_swrepo__repo_resource_count(2) }
      it { should contain_swrepo__repo('params-hash1').with_repotype(facts[:repotype]) }
      it { should contain_swrepo__repo('params-hash2').with_repotype(facts[:repotype]) }
    end
  end


  # ensure hiera merging works as intended
  describe 'with hiera providing data from multiple levels' do
    let(:facts) do
      {
        :fqdn     => 'swrepo.example.local',
        :common   => 'common',
      }
    end

    context 'when repos is unset' do
      context 'with hiera_merge set to boolean false' do
        let(:params) { { :hiera_merge => false } }
        it { should have_swrepo__repo_resource_count(1) }
        it { should contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
      end

      context 'with hiera_merge set to boolean true' do
        let(:params) { { :hiera_merge => true } }
        it { should have_swrepo__repo_resource_count(2) }
        it { should contain_swrepo__repo('hiera-common').with_baseurl('http://hiera.common/repo') }
        it { should contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
      end
    end

    context 'when repos is set to a valid hash' do
      context 'with hiera_merge set to boolean false' do
        let(:params) { { :repos => repos_hash}.merge({ :hiera_merge => false }) }
        it { should have_swrepo__repo_resource_count(2) }
        it { should contain_swrepo__repo('params-hash1').with_baseurl('http://params.hash/repo1') }
        it { should contain_swrepo__repo('params-hash2').with_baseurl('http://params.hash/repo2') }
      end

      context 'with hiera_merge set to boolean true' do
        let(:params) { { :repos => repos_hash}.merge({ :hiera_merge => true }) }
        it { should have_swrepo__repo_resource_count(2) }
        it { should_not contain_swrepo__repo('params-hash1') }
        it { should_not contain_swrepo__repo('params-hash2') }
        it { should contain_swrepo__repo('hiera-common').with_baseurl('http://hiera.common/repo') }
        it { should contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
      end
    end
  end

  # ensure it fails on unsupported os
  unsupported_os_families.sort.each do |os, facts|
    describe "when running on unsupported #{os}" do
      let(:facts) do
        {
          :osfamily          => facts[:os],
          :lsbmajdistrelease => facts[:lsbmajdist],
        }
      end
      it 'should fail' do
        expect { should contain_class(subject) }.to raise_error(Puppet::Error, %r{Supported osfamilies are RedHat and Suse 11/12})
      end
    end
  end

  # ensure parameters only takes intended data types
  describe 'variable type and content validations' do
    mandatory_params = {}
    validations = {
      'boolean' => {
        :name    => %w[hiera_merge],
        :valid   => [true, 'false'],
        :invalid => ['string', %w[array], { 'ha' => 'sh' }, 3, 2.42, nil],
        :message => 'str2bool',
      },
      'hash' => {
        :name    => %w[repos],
        :valid   => [repos_hash], # valid hashes are to complex to block test them here.
        :invalid => ['string', %w[array], 3, 2.42, true],
        :message => 'is not a Hash',
      },
      'string' => {
        :name    => %w[repotype],
        :valid   => %w[string],
        :invalid => [%w[array], { 'ha' => 'sh' }, 3, 2.42, true],
        :message => 'is not a string',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
