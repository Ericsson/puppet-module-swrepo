require 'spec_helper'
describe 'swrepo::repo' do
  mandatory_params = {
    repotype: 'yum',
    baseurl:  'http://spec.test/repo',
  }
  let(:title) { 'spectest-repo' }
  let(:params) { mandatory_params }

  on_supported_os.sort.each do |os, os_facts|
    # ensure that the define fails without mandatory parameters specified
    describe "on #{os}" do
      let(:facts) { os_facts }

      context 'with default values for parameters (mandatory parameters missing)' do
        let(:params) { {} }

        it 'fail' do
          expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{(expects a value for|Must pass)})
        end
      end

      describe 'with baseurl specified (mandatory parameters incomplete)' do
        let(:params) { { baseurl: 'http://spec.test/repo' } }

        it 'fail' do
          expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{(expects a value for|Must pass)})
        end
      end

      describe 'with repotype specified (mandatory parameters incomplete)' do
        let(:params) { { repotype: 'yum' } }

        it 'fail' do
          expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{(expects a value for|Must pass)})
        end
      end

      # ensure the default behavior on different repo types
      context 'with mandatory parameters specified' do
        context 'when repotype is set to yum' do
          let(:params) { mandatory_params }

          it do
            is_expected.to contain_yumrepo('spectest-repo').with(
              {
                'name'     => 'spectest-repo',
                'baseurl'  => 'http://spec.test/repo',
                'descr'    => nil,
                'enabled'  => '1',
                'gpgcheck' => nil,
                'gpgkey'   => nil,
                'priority' => nil,
                'exclude'  => nil,
                'proxy'    => nil,
              },
            )
          end

          it { is_expected.to have_yumrepo_resource_count(1) }
          it { is_expected.to have_zypprepo_resource_count(0) }
          it { is_expected.to have_rpmkey_resource_count(0) }
        end

        context 'when repotype is set to zypper' do
          let(:params) { mandatory_params.merge({ repotype: 'zypper' }) }

          it do
            is_expected.to contain_zypprepo('spectest-repo').with(
              {
                'name'          => 'spectest-repo',
                'baseurl'       => 'http://spec.test/repo',
                'descr'         => nil,
                'enabled'       => '1',
                'gpgcheck'      => nil,
                'gpgkey'        => nil,
                'priority'      => nil,
                'keeppackages'  => nil,
                'type'          => nil,
                'autorefreash'  => nil,
              },
            )
          end

          it { is_expected.to have_yumrepo_resource_count(0) }
          it { is_expected.to have_zypprepo_resource_count(1) }
          it { is_expected.to have_rpmkey_resource_count(0) }
        end
      end

      # repository handling
      ['yum', 'zypper'].each do |repotype|
        default_params = mandatory_params.merge({ repotype: repotype })

        context "with repotype set to #{repotype}" do
          context 'when baseurl is set to valid string http://specific.url/REPO' do
            let(:params) { default_params.merge({ baseurl: 'http://specific.url/REPO' }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_baseurl('http://specific.url/REPO') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_baseurl('http://specific.url/REPO') }
            end
          end

          # ensure bool2str functionality
          context 'when autorefresh is set to valid boolean true' do
            let(:params) { default_params.merge({ autorefresh: true }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').without_autorefresh }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_autorefresh('1') }
            end
          end

          context 'when descr is set to valid string custom-repo' do
            let(:params) { default_params.merge({ descr: 'custom-repo' }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_descr('custom-repo') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_descr('custom-repo') }
            end
          end

          context 'when downcase_baseurl is set to valid boolean true and baseurl contains uppercases' do
            let(:params) do
              default_params.merge(
                {
                  baseurl:          'http://specific.url/REPO',
                  downcase_baseurl: true,
                },
              )
            end

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_baseurl('http://specific.url/repo') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_baseurl('http://specific.url/repo') }
            end
          end

          # ensure bool2str functionality
          context 'when enabled is set to valid boolean false' do
            let(:params) { default_params.merge({ enabled: false }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_enabled('0') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_enabled('0') }
            end
          end

          context 'when exclude is set to valid string not_me' do
            let(:params) { default_params.merge({ exclude: 'not_me' }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_exclude('not_me') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').without_exclude }
            end
          end

          # ensure bool2str functionality
          context 'when gpgcheck is set to valid boolean true' do
            let(:params) { default_params.merge({ gpgcheck: true }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_gpgcheck('1') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_gpgcheck('1') }
            end
          end

          context 'when gpgkey_source is set to valid string http://path.to/gpgkey' do
            let(:params) { default_params.merge({ gpgkey_source: 'http://path.to/gpgkey' }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_gpgkey('http://path.to/gpgkey') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_gpgkey('http://path.to/gpgkey') }
            end
          end

          # ensure bool2str functionality
          context 'when keeppackages is set to valid boolean true' do
            let(:params) { default_params.merge({ keeppackages: true }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').without_keeppackages }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_keeppackages('1') }
            end
          end

          context 'when priority is set to valid integer 42' do
            let(:params) { default_params.merge({ priority: 42 }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_priority('42') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_priority('42') }
            end
          end

          context 'when proxy is set to valid string http://proxy.test' do
            let(:params) { default_params.merge({ proxy: 'http://proxy.test' }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').with_proxy('http://proxy.test') }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').without_proxy }
            end
          end

          context 'when type is set to valid string yum' do
            let(:params) { default_params.merge({ type: 'yum' }) }

            if repotype == 'yum'
              it { is_expected.to contain_yumrepo('spectest-repo').without_type }
            else
              it { is_expected.to contain_zypprepo('spectest-repo').with_type('yum') }
            end
          end
        end
      end # %w[yum zypper].each do |repotype|

      # RPM Key handling
      context 'with gpgkey_keyid set to valid string 0608B895' do
        let(:params) { mandatory_params.merge({ gpgkey_keyid: '0608B895' }) }

        it 'fail' do
          expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{swrepo::repo::gpgkey_keyid is specified but swrepo::repo::gpgkey_source is missing})
        end
      end

      context 'with gpgkey_source set to valid string http://url.to/gpgkey' do
        let(:params) { mandatory_params.merge({ gpgkey_source: 'http://url.to/gpgkey' }) }

        it { is_expected.to have_rpmkey_resource_count(0) }
      end

      context 'with gpgkey_keyid and gpgkey_source are both set to valid strings' do
        let(:params) do
          mandatory_params.merge(
            {
              gpgkey_keyid:  '0608B895',
              gpgkey_source: 'http://url.to/gpgkey',
            },
          )
        end

        it { is_expected.to have_rpmkey_resource_count(1) }
        it do
          is_expected.to contain_rpmkey('0608B895').with(
            {
              'ensure' => 'present',
              'source' => 'http://url.to/gpgkey',
            },
          )
        end
      end
    end
  end

  describe 'variable type and content validations' do
    validations = {
      'Boolean' => {
        name:     ['downcase_baseurl', 'enabled'],
        valid:    [true, false],
        invalid:  ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message:  'expects a Boolean value',
      },
      'Optional[Boolean]' => {
        name:     ['autorefresh', 'gpgcheck', 'keeppackages'],
        valid:    [true, false],
        invalid:  ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message:  'expects a value of type Undef or Boolean',
      },
      # ensure it only takes integers between 1 and 99
      'Optional[Integer[1,99]]' => {
        name:     ['priority'],
        valid:    [1, 99],
        invalid:  [0, 100, 'string', ['array'], { 'ha' => 'sh' }, 2.42, true, nil],
        message:  'expects a value of type Undef or Integer',
      },
      'Stdlib::HTTPUrl' => {
        name:     ['baseurl', 'gpgkey_source', 'proxy'],
        valid:    ['http://spec.test/repo', 'https://te.st/ing/'],
        invalid:  [['array'], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        message:  'expects a match for Stdlib::HTTPUrl',
      },
      'Enum[apt, yum, zypper]' => {
        name:     ['repotype'],
        valid:    ['yum', 'zypper'], # TODO: test apt under Debian/Ubuntu
        invalid:  ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        message:  'expects a match for Enum',
      },
      'Optional[Enum[yum, yast2, rpm-md, plaindir]]' => {
        name:     ['type'],
        valid:    ['yum', 'yast2', 'rpm-md', 'plaindir'],
        invalid:  ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        message:  'match for Enum', # expects a match for Enum',
      },
      'Optional[String[1]]' => {
        name:     ['descr', 'exclude'],
        valid:    ['string', nil],
        invalid:  ['', ['array'], { 'ha' => 'sh' }, 3, 2.42, true],
        message:  'expects a value of type Undef or String',
      },
      'Optional[String[1]] for gpgkey_keyid' => {
        name:     ['gpgkey_keyid'],
        params:   { gpgkey_source: 'http://spec.test/repo' }, # mandatory for gpgkey_keyid usage
        valid:    ['0608B895'],
        invalid:  [['array'], { 'ha' => 'sh' }, 3, 2.42, true],
        message:  'expects a value of type Undef or String',
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
