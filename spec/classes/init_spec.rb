require 'spec_helper'
describe 'swrepo' do
  supported_os_families = {
    'RedHat'  =>
      {
        os:              'RedHat',
        osrelease:       '7.4',
        repotype:        'yum',
        lsbdistid:       nil,
        lsbdistcodename: nil,
        config_file:     '/etc/yum.repos.d',
      },
    'Suse-11' =>
      {
        os:              'Suse',
        osrelease:       '11.1',
        repotype:        'zypper',
        lsbdistid:       nil,
        lsbdistcodename: nil,
        config_file:     '/etc/zypp/repos.d',
      },
    'Suse-12' =>
      {
        os:              'Suse',
        osrelease:       '12.2',
        repotype:        'zypper',
        lsbdistid:       nil,
        lsbdistcodename: nil,
        config_file:     '/etc/zypp/repos.d',
      },
    # 'Debian'  =>
    #   {
    #     os:              'Debian',
    #     osrelease:       'stretch/sid',
    #     repotype:        'apt',
    #     lsbdistid:       'Debian',
    #     lsbdistcodename: ''
    #   },
    'Ubuntu' =>
      {
        os:              'Debian',
        osrelease:       '16.04',
        repotype:        'apt',
        lsbdistid:       'Ubuntu',
        lsbdistcodename: 'xenial',
        config_file:     nil,
      },
  }

  unsupported_os_families = {
    'Suse-10' => { os: 'Suse',    osrelease: '10.0', repotype: nil, lsbdistid: nil },
    'Unknown' => { os: 'Unknown', osrelease: '2.42', repotype: nil, lsbdistid: nil },
  }

  repos_hash = {
    'params-hash1' => { 'baseurl' => 'http://params.hash/repo1' },
    'params-hash2' => { 'baseurl' => 'http://params.hash/repo2' },
  }
  repos_apt_hash = {
    'params-hash1' => { 'apt_repos' => 'main', 'baseurl' => 'http://params.hash/repo1' },
    'params-hash2' => { 'apt_repos' => 'main', 'baseurl' => 'http://params.hash/repo2' },
  }
  # notify_update => false to prevent apt::update from being triggered.
  apt_setting_hash = {
    'conf-paramshttpproxy'  => { 'content' => 'Acquire::http::proxy "http://proxy.domain.tld:8080";', 'notify_update' => false },
    'conf-paramshttpsproxy' => { 'content' => 'Acquire::https::proxy "https://proxy.domain.tld:8080";', 'notify_update' => false },
  }

  # ensure that the class is passive by default
  describe 'when all parameters are unset (unsing module defaults)' do
    let(:facts) { { osfamily: 'RedHat' } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('swrepo') }
    it { is_expected.to have_resource_count(0) }
  end

  # ensure repotype can be set freely on any supported os
  # apt module only works on osfamily Debian. Not including.
  ['yum', 'zypper'].each do |repotype|
    describe "when repotype is set to the valid string #{repotype}" do
      let(:facts) { { osfamily: 'RedHat' } }
      let(:params) { { repotype: repotype } }

      it { is_expected.to have_swrepo__repo_resource_count(0) }

      supported_os_families.sort.each do |os, facts|
        context "with repos set to a valid hash on supported #{os}" do
          let(:facts) do
            {
              osfamily:               facts[:os],
              operatingsystemrelease: facts[:osrelease],
              lsbdistid:              facts[:lsbdistid],
              lsbdistcodename:        facts[:lsbdistcodename],
            }
          end
          let(:params) { { repos: repos_hash }.merge({ repotype: repotype }) }

          it { is_expected.to have_swrepo__repo_resource_count(2) }
          it { is_expected.to contain_swrepo__repo('params-hash1').with_repotype(repotype) }
          it { is_expected.to contain_swrepo__repo('params-hash2').with_repotype(repotype) }
        end
      end
    end
  end

  describe 'when repotype is set to apt' do
    let(:params) do
      {
        repotype:    'apt',
        repos:       repos_apt_hash,
        apt_setting: apt_setting_hash,
      }
    end

    supported_os_families.sort.each do |_os, facts|
      context "and osfamily is #{facts[:os]} and repos and apt_setting set" do
        let(:facts) do
          {
            osfamily:               facts[:os],
            operatingsystemrelease: facts[:osrelease],
            lsbdistid:              facts[:lsbdistid],
            lsbdistcodename:        facts[:lsbdistcodename],
          }
        end

        if facts[:os] == 'Debian'
          it { compile.with_all_deps }
          it { is_expected.to have_swrepo__repo_resource_count(2) }
          # 2 repositories, 2 settings and 1 extra (default file created)
          it { is_expected.to have_apt__setting_resource_count(5) }
        else
          it 'fail' do
            expect { is_expected.to contain_class('swrepo') }.to raise_error(Puppet::Error, %r{with value apt is only valid on osfamily Debian})
          end
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
          osfamily:               facts[:os],
          operatingsystemrelease: facts[:osrelease],
          lsbdistid:              facts[:lsbdistid],
          lsbdistcodename:        facts[:lsbdistcodename],
        }
      end
      let(:params) { { repos: repos_hash } }

      it { is_expected.to have_swrepo__repo_resource_count(2) }
      it { is_expected.to contain_swrepo__repo('params-hash1').with_repotype(facts[:repotype]) }
      it { is_expected.to contain_swrepo__repo('params-hash2').with_repotype(facts[:repotype]) }
    end
    describe 'when config_dir_name is not set and config_dir_purge is true' do
      let(:facts) do
        {
          osfamily:               facts[:os],
          operatingsystemrelease: facts[:osrelease],
          lsbdistid:              facts[:lsbdistid],
          lsbdistcodename:        facts[:lsbdistcodename],
        }
      end
      let(:params) do
        {
          repos:            repos_hash,
          config_dir_purge: true,
        }
      end

      it { compile.with_all_deps }
      unless facts[:os] == 'Debian'
        it do
          is_expected.to contain_file(facts[:config_file]).with(
            {
              'ensure'  => 'directory',
              'recurse' => 'true',
              'purge'   => 'true',
            },
          )
        end
        it do
          is_expected.to contain_file("#{facts[:config_file]}/params-hash1.repo").with(
            {
              'require' => "File[#{facts[:config_file]}]",
            },
          )
        end
        it do
          is_expected.to contain_file("#{facts[:config_file]}/params-hash2.repo").with(
            {
              'require' => "File[#{facts[:config_file]}]",
            },
          )
        end
        it { is_expected.to contain_swrepo__repo('params-hash2').with_repotype(facts[:repotype]) }
        if facts[:os] == 'RedHat'
          it do
            is_expected.to contain_file("#{facts[:config_file]}/redhat.repo").with(
              {
                'require' => "File[#{facts[:config_file]}]",
              },
            )
          end
        end
      end
    end
  end

  # ensure hiera merging works as intended
  describe 'with hiera providing data from multiple levels' do
    describe 'for repos' do
      let(:facts) do
        {
          fqdn:   'swrepo.example.local',
          common: 'common',
        }
      end

      context 'when hiera_merge and repos_hiera_merge both are set' do
        context 'and they have the same values' do
          let(:params) { { repos_hiera_merge: true, hiera_merge: true } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_notify('*** DEPRECATION WARNING***: Using $hiera_merge is deprecated. Please use $repos_hiera_merge instead!') }
        end
        context 'and they have different values' do
          let(:params) { { repos_hiera_merge: true, hiera_merge: false } }

          it 'fail' do
            expect { is_expected.to contain_class('swrepo') }.to raise_error(Puppet::Error, %r{Different values for \$repos_hiera_merge \(true\) and \$hiera_merge \(false\)})
          end
        end
      end

      context 'when repos is unset' do
        context 'with repos_hiera_merge set to boolean false' do
          let(:params) { { repos_hiera_merge: false } }

          it { is_expected.to have_swrepo__repo_resource_count(1) }
          it { is_expected.to contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
        end

        context 'with repos_hiera_merge set to boolean true' do
          let(:params) { { repos_hiera_merge: true } }

          it { is_expected.to have_swrepo__repo_resource_count(2) }
          it { is_expected.to contain_swrepo__repo('hiera-common').with_baseurl('http://hiera.common/repo') }
          it { is_expected.to contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
        end
      end

      context 'when repos is set to a valid hash' do
        context 'with repos_hiera_merge set to boolean false' do
          let(:params) { { repos: repos_hash }.merge({ repos_hiera_merge: false }) }

          it { is_expected.to have_swrepo__repo_resource_count(2) }
          it { is_expected.to contain_swrepo__repo('params-hash1').with_baseurl('http://params.hash/repo1') }
          it { is_expected.to contain_swrepo__repo('params-hash2').with_baseurl('http://params.hash/repo2') }
        end

        context 'with repos_hiera_merge set to boolean true' do
          let(:params) { { repos: repos_hash }.merge({ repos_hiera_merge: true }) }

          it { is_expected.to have_swrepo__repo_resource_count(2) }
          it { is_expected.not_to contain_swrepo__repo('params-hash1') }
          it { is_expected.not_to contain_swrepo__repo('params-hash2') }
          it { is_expected.to contain_swrepo__repo('hiera-common').with_baseurl('http://hiera.common/repo') }
          it { is_expected.to contain_swrepo__repo('hiera-fqdn').with_baseurl('http://hiera.fqdn/repo') }
        end
      end
    end

    describe 'for apt_setting' do
      let(:facts) do
        {
          fqdn:            'swrepoapt.example.local',
          osfamily:        'Debian',
          osrelease:       '16.04',
          repotype:        'apt',
          lsbdistid:       'Ubuntu',
          lsbdistcodename: 'xenial',
        }
      end

      context 'when apt_setting is unset' do
        context 'with apt_setting_hiera_merge set to boolean false' do
          let(:params) { { apt_setting_hiera_merge: false } }

          it { is_expected.to have_apt__setting_resource_count(1) }
          it { is_expected.to contain_apt__setting('conf-hierafqdn').with_content('Acquire::http::proxy "https://proxy.hieradomain.tld:8080";') }
        end

        context 'with apt_setting_hiera_merge set to boolean true' do
          let(:params) { { apt_setting_hiera_merge: true } }

          it { is_expected.to have_apt__setting_resource_count(2) }
          it { is_expected.to contain_apt__setting('conf-hieraosfamily').with_content('Acquire::http::proxy "http://proxy.hieradomain.tld:8080";') }
          it { is_expected.to contain_apt__setting('conf-hierafqdn').with_content('Acquire::http::proxy "https://proxy.hieradomain.tld:8080";') }
        end
      end

      context 'when apt_setting is set to a valid hash' do
        context 'with apt_settinghiera_merge set to boolean false' do
          let(:params) { { apt_setting: apt_setting_hash }.merge({ apt_setting_hiera_merge: false }) }

          puts(:params)
          it { is_expected.to have_apt__setting_resource_count(2) }
          it { is_expected.to contain_apt__setting('conf-paramshttpproxy').with_content('Acquire::http::proxy "http://proxy.domain.tld:8080";') }
          it { is_expected.to contain_apt__setting('conf-paramshttpsproxy').with_content('Acquire::https::proxy "https://proxy.domain.tld:8080";') }
        end

        context 'with apt_setting_hiera_merge set to boolean true' do
          let(:params) { { apt_setting: apt_setting_hash }.merge({ apt_setting_hiera_merge: true }) }

          it { is_expected.to have_apt__setting_resource_count(2) }
          it { is_expected.not_to contain_apt__setting('conf-paramshttpproxy') }
          it { is_expected.not_to contain_apt__setting('conf-paramshttpsproxy') }
          it { is_expected.to contain_apt__setting('conf-hieraosfamily').with_content('Acquire::http::proxy "http://proxy.hieradomain.tld:8080";') }
          it { is_expected.to contain_apt__setting('conf-hierafqdn').with_content('Acquire::http::proxy "https://proxy.hieradomain.tld:8080";') }
        end
      end
    end
  end

  # ensure it fails on unsupported os
  unsupported_os_families.sort.each do |os, facts|
    describe "when running on unsupported #{os}" do
      let(:facts) do
        {
          osfamily:               facts[:os],
          operatingsystemrelease: facts[:osrelease],
        }
      end

      it 'fail' do
        expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{Supported osfamilies are Debian, RedHat and Suse 11/12})
      end
    end
  end

  # ensure parameters only takes intended data types
  describe 'variable type and content validations' do
    mandatory_params = {}
    validations = {
      'boolean' => {
        name:     ['apt_setting_hiera_merge', 'config_dir_purge', 'repos_hiera_merge'],
        valid:    [true, 'false'],
        invalid:  ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message:  'str2bool',
      },
      # hiera_merge will be deprecated and needs to be equal to repos_hiera_merge until then
      'boolean (hiera_merge = false)' => {
        name:     ['hiera_merge'],
        valid:    [false, 'false'],
        params:   { repos_hiera_merge: false },
        invalid:  [], # will be tested in the next case
        message:  'str2bool',
      },
      # hiera_merge will be deprecated and needs to be equal to repos_hiera_merge until then
      'boolean (hiera_merge = true)' => {
        name:     ['hiera_merge'],
        valid:    [true, 'true'],
        params:   { repos_hiera_merge: true },
        invalid:  ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message:  'str2bool',
      },
      'hash-repos' => {
        name:     ['repos'],
        valid:    [], # valid hashes are to complex to block test them here.
        invalid:  ['string', ['array'], 3, 2.42, true],
        message:  'is not a Hash',
      },
      'hash-apt_setting' => {
        name:     ['apt_setting'],
        valid:    [], # valid hashes are to complex to block test them here.
        invalid:  ['string', ['array'], 3, 2.42, true],
        message:  'is not a Hash',
        facts:    { osfamily: 'Debian', osrelease: '16.04', lsbdistid: 'Ubuntu', lsbdistcodename: 'xenial' }
      },
      'string' => {
        name:     ['repotype', 'config_dir_name'],
        valid:    ['string'],
        invalid:  [['array'], { 'ha' => 'sh' }, 3, 2.42, true],
        message:  'is not a string',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { "#{var_name}": valid, }].reduce(:merge) }

            it { is_expected.to compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { "#{var_name}": invalid, }].reduce(:merge) }

            it 'fail' do
              expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{#{var[:message]}})
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
