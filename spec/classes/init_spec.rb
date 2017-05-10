require 'spec_helper'
describe 'swrepo' do
  os_defaults_matrix = {
    'Debian'  => { :os => 'Debian',  :lsbmajdist => nil,  :repotype => nil },
    'RedHat'  => { :os => 'RedHat',  :lsbmajdist => nil,  :repotype => 'yum' },
    'Suse-10' => { :os => 'Suse',    :lsbmajdist => '10', :repotype => nil },
    'Suse-11' => { :os => 'Suse',    :lsbmajdist => '11', :repotype => 'zypper' },
    'Suse-12' => { :os => 'Suse',    :lsbmajdist => '12', :repotype => 'zypper' },
    'Unknown' => { :os => 'Unknown', :lsbmajdist => nil,  :repotype => nil },
  }

  repos_hash = {
    :repos => {
      'testhash' => {
        'baseurl' => 'http://spec.test/repo',
      }
    }
  }

  os_defaults_matrix.sort.each do |os, facts|
    describe "when running on #{os} osfamily" do
      let(:facts) do
        {
          :osfamily          => facts[:os],
          :lsbmajdistrelease => facts[:lsbmajdist],
        }
      end

      context 'with default values for all parameters' do
        if facts[:repotype] != nil
          it { should compile.with_all_deps }
          it { should contain_class('swrepo') }
          it { should have_swrepo__repo_resource_count(0) }
        else
          it 'should fail' do
            expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(not yet supported|Unsupported Suse version|Supported osfamilies are)/)
          end
        end
      end

      context 'when repos is set to a valid hash' do
        let(:params) { repos_hash }
        if facts[:repotype] != nil
          it { should have_swrepo__repo_resource_count(1) }
          it do
            should contain_swrepo__repo('testhash').with({
              'baseurl'  => 'http://spec.test/repo',
              'repotype' => facts[:repotype]
            })
          end
        end
      end
    end
  end

  describe 'when repotype is set to valid string apt' do
    let(:params) { repos_hash.merge({ :repotype => 'apt' }) }
    it { should contain_swrepo__repo('testhash').with_repotype('apt') }
  end

  describe 'when repos is set to a valid hash' do
    let(:facts) do
      {
        :osfamily => 'RedHat',
        :fqdn     => 'swrepo.example.local', # set fqdn to include hiera data
      }
    end

    context 'with hiera_merge set to boolean true' do
      let(:params) { repos_hash.merge({ :hiera_merge => true }) }
      it { should have_swrepo__repo_resource_count(1) }
      it { should contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
    end

    context 'with hiera_merge set to boolean false' do
      let(:params) { repos_hash.merge({ :hiera_merge => false }) }
      it { should have_swrepo__repo_resource_count(1) }
      it { should contain_swrepo__repo('testhash').with_baseurl('http://spec.test/repo') }
    end
  end

  describe 'when hiera_merge is set to boolean true' do
    let(:facts) do
      {
        :osfamily => 'RedHat',
        :fqdn     => 'swrepo.example.local', # set fqdn to include hiera data
      }
    end

    context 'with repos set to a valid hash' do
      let(:params) { repos_hash.merge({ :hiera_merge => true }) }
      it { should have_swrepo__repo_resource_count(1) }
      it { should contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
    end

    context 'with repos unset' do
      let(:params) { { :hiera_merge => true, :repos => nil } }
      it { should have_swrepo__repo_resource_count(1) }
      it { should contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
    end
  end

  describe 'with hiera providing data from multiple levels' do
    let(:facts) do
      {
        :osfamily => 'RedHat',
        :fqdn     => 'swrepo.example.local',
        :common   => 'common',
      }
    end

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

  describe 'variable type and content validations' do
    mandatory_params = {}
    validations = {
      'boolean' => {
        :name    => %w[hiera_merge],
        :valid   => [true, false, 'true', 'false'],
        :invalid => ['string', %w[array], { 'ha' => 'sh' }, 3, 2.42, nil],
        :message => 'str2bool',
      },
      'hash' => {
        :name    => %w[repos],
        :valid   => [], # valid hashes are to complex to block test them here.
        :invalid => ['string', %w[array], 3, 2.42, true],
        :message => 'is not a Hash',
      },
      'string' => {
        :name    => %w[repotype],
        :valid   => %w[string],
        :invalid => [], # no type validation yet, should fail on [%w[array], { 'ha' => 'sh' }, 3, 2.42, true],
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
