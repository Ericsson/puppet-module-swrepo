require 'spec_helper'
describe 'swrepo' do
  supported_os_families = {
    'RedHat' =>
      {
        os: {
          family: 'RedHat',
          release: {
            full: '7.4',
            major: '7',
          },
        },
        osrelease:       '7.4',
        repotype:        'yum',
        lsbdistid:       nil,
        lsbdistcodename: nil,
        config_file:     '/etc/yum.repos.d',
      },
    'Suse-11' =>
      {
        os: {
          family: 'Suse',
          release: {
            full: '11.1',
            major: '11',
          },
        },
        osrelease:       '11.1',
        repotype:        'zypper',
        lsbdistid:       nil,
        lsbdistcodename: nil,
        config_file:     '/etc/zypp/repos.d',
      },
    'Suse-12' =>
      {
        os: {
          family: 'Suse',
          release: {
            full: '12.2',
            major: '12',
          },
        },
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
        os: {
          family: 'Debian',
          release: {
            full: '16.04',
            major: '16.04',
          },
        },
        osrelease:       '16.04',
        repotype:        'apt',
        lsbdistid:       'Ubuntu',
        lsbdistcodename: 'xenial',
        config_file:     nil,
      },
  }

  unsupported_os_families = {
    'Suse-10' => {
      os: {
        family: 'Suse',
        release: {
          full: '10.0',
          major: '10',
        },
      },
      repotype: nil,
      lsbdistid: nil,
    },
    'Unknown' => {
      os: {
        family: 'Unknown',
        release: {
          full: '2.42',
          major: '2',
        },
      },
      repotype: nil,
      lsbdistid: nil,
    },
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
    let(:facts) { { os: { family: 'RedHat' } } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('swrepo') }
    it { is_expected.to have_resource_count(0) }
  end

  # ensure repotype can be set freely on any supported os
  # apt module only works on osfamily Debian. Not including.
  ['yum', 'zypper'].each do |repotype|
    describe "when repotype is set to the valid string #{repotype}" do
      let(:facts) { { os: { family: 'RedHat' } } }
      let(:params) { { repotype: repotype } }

      it { is_expected.to have_swrepo__repo_resource_count(0) }

      supported_os_families.sort.each do |os, facts|
        context "with repos set to a valid hash on supported #{os}" do
          let(:facts) do
            {
              os: {
                family:               facts[:os][:family],
                release: {
                  full:               facts[:os][:release][:full],
                  major:              facts[:os][:release][:major],
                },
              },
              osfamily:               facts[:os][:family],
              operatingsystemrelease: facts[:osrelease],
              lsbdistid:              facts[:lsbdistid],
              lsbdistcodename:        facts[:lsbdistcodename],
            }
          end
          let(:params) { { repos: repos_hash }.merge({ repotype: repotype }) }

          it { is_expected.to have_swrepo__repo_resource_count(2) }
          it { is_expected.to contain_swrepo__repo('params-hash1').with_repotype(repotype) }
          it { is_expected.to contain_swrepo__repo('params-hash2').with_repotype(repotype) }

          case "#{facts[:os][:family]}-#{repotype}"
          when 'Suse-zypper'
            it { is_expected.to contain_zypprepo('params-hash1') } # only needed for 100% resource coverage
            it { is_expected.to contain_zypprepo('params-hash2') } # only needed for 100% resource coverage
          when 'RedHat-yum'
            it { is_expected.to contain_yumrepo('params-hash1') } # only needed for 100% resource coverage
            it { is_expected.to contain_yumrepo('params-hash2') } # only needed for 100% resource coverage
          end
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
            os: {
              family:               facts[:os][:family],
              release: {
                full:               facts[:os][:release][:full],
                major:              facts[:os][:release][:major],
              },
            },
            osfamily:               facts[:os][:family],
            operatingsystemrelease: facts[:osrelease],
            lsbdistid:              facts[:lsbdistid],
            lsbdistcodename:        facts[:lsbdistcodename],
          }
        end

        if facts[:os][:family] == 'Debian'
          it { compile.with_all_deps }
          it { is_expected.to have_swrepo__repo_resource_count(2) }
          # 2 repositories, 2 settings and 1 extra (default file created)
          it { is_expected.to have_apt__setting_resource_count(5) }
          # from repos_apt_hash
          it { is_expected.to contain_swrepo__repo('params-hash1').with_baseurl('http://params.hash/repo1') }
          it { is_expected.to contain_swrepo__repo('params-hash2').with_baseurl('http://params.hash/repo2') }
          it { is_expected.to contain_apt__source('params-hash1') } # only needed for 100% resource coverage
          it { is_expected.to contain_apt__source('params-hash2') } # only needed for 100% resource coverage

          # from apt_setting_hash
          it { is_expected.to contain_apt__setting('conf-paramshttpproxy') }
          it { is_expected.to contain_apt__setting('conf-paramshttpsproxy') }

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
          os: {
            family:               facts[:os][:family],
            release: {
              full:               facts[:os][:release][:full],
              major:              facts[:os][:release][:major],
            },
          },
          osfamily:               facts[:os][:family],
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
          os: {
            family:               facts[:os][:family],
            release: {
              full:               facts[:os][:release][:full],
              major:              facts[:os][:release][:major],
            },
          },
          osfamily:               facts[:os][:family],
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
      unless facts[:os][:family] == 'Debian'
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

      if facts[:os][:family] == 'RedHat'
        it { is_expected.to contain_file('/etc/yum.repos.d/redhat.repo') }
      end
    end
  end

  # ensure it fails on unsupported os
  unsupported_os_families.sort.each do |os, facts|
    describe "when running on unsupported #{os}" do
      let(:facts) do
        {
          os: {
            family:               facts[:os][:family],
            release: {
              full:               facts[:os][:release][:full],
              major:              facts[:os][:release][:major],
            },
          },
        }
      end

      it 'fail' do
        expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{Supported osfamilies are Debian, RedHat and Suse 11/12})
      end
    end
  end

  # ensure parameters only takes intended data types
  describe 'variable type and content validations' do
    let(:facts) { { os: { family: 'RedHat', release: { full: '7.4', major: '7' } } } }

    mandatory_params = {}
    validations = {
      'Boolean' => {
        name:    ['config_dir_purge'],
        valid:   [true, false],
        invalid: ['false', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message: 'expects a Boolean value',
      },
      'Hash' => {
        name:    ['repos'],
        valid:   [], # valid hashes are to complex to block test them here.
        invalid: ['string', ['array'], 3, 2.42, true],
        message: 'expects a Hash value',
      },
      'Optional[Stdlib::Absolutepath]' => {
        name:    ['config_dir_name'],
        valid:   ['/absolute/filepath', '/absolute/directory/'], # cant test undef :(
        invalid: ['relative/path', 3, 2.42, ['array'], { 'ha' => 'sh' }],
        message: 'expects a Stdlib::Absolutepath',
      },
      'Optional[String[1]]' => {
        name:    ['repotype'],
        valid:   ['string'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true],
        message: 'expects a value of type Undef or String',
      },
      'Hash apt_setting specific' => {
        name:    ['apt_setting'],
        valid:   [], # valid hashes are to complex to block test them here.
        invalid: ['string', ['array'], 3, 2.42, true],
        message: 'expects a Hash value',
        facts:   { osfamily: 'Debian', osrelease: '16.04', lsbdistid: 'Ubuntu', lsbdistcodename: 'xenial' }
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
