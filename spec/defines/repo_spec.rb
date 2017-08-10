require 'spec_helper'
describe 'swrepo::repo' do
  mandatory_params = {
    :repotype => 'yum',
    :baseurl  => 'http://spec.test/repo',
  }
  let(:title) { 'spectest-repo' }
  let(:params) { mandatory_params }

  # ensure that the define fails without mandatory parameters specified
  describe 'with defaults for all parameters (mandatory parameters missing)' do
    let(:params) { {} }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(expects a value for|Must pass)/)
    end
  end

  describe 'with baseurl specified (mandatory parameters incomplete)' do
    let(:params) { { :baseurl  => 'http://spec.test/repo' } }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(expects a value for|Must pass)/)
    end
  end

  describe 'with repotype specified (mandatory parameters incomplete)' do
    let(:params) { { :repotype => 'yum' } }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /(expects a value for|Must pass)/)
    end
  end

  # ensure the default behavior on different repo types
  describe 'with mandatory parameters specified' do
    context' when repotype is set to yum' do
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

    context' when repotype is set to zypper' do
      let(:params) { mandatory_params.merge({ :repotype => 'zypper' }) }

      it do
        should contain_zypprepo('spectest-repo').with({
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
        })
      end

      it { should have_yumrepo_resource_count(0) }
      it { should have_zypprepo_resource_count(1) }
      it { should have_rpmkey_resource_count(0) }
    end
  end

  # repository handling
  %w[yum zypper].each do |repotype|
    default_params = mandatory_params.merge({ :repotype => repotype })

    describe "with repotype set to #{repotype}" do
      context 'when baseurl is set to valid string http://specific.url/REPO' do
        let(:params) { default_params.merge({ :baseurl => 'http://specific.url/REPO' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_baseurl('http://specific.url/REPO') }
        else
          it { should contain_zypprepo('spectest-repo').with_baseurl('http://specific.url/REPO') }
        end
      end

      # ensure bool2str functionality
      context 'when autorefresh is set to valid boolean true' do
        let(:params) { default_params.merge({ :autorefresh => true }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_autorefresh }
        else
          it { should contain_zypprepo('spectest-repo').with_autorefresh('1') }
        end
      end

      # ensure backward compatibility for migration only
      context 'when autorefresh is set to valid string 1' do
        let(:params) { default_params.merge({ :autorefresh => '1' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_autorefresh }
        else
          it { should contain_zypprepo('spectest-repo').with_autorefresh('1') }
        end
      end

      context 'when descr is set to valid string custom-repo' do
        let(:params) { default_params.merge({ :descr => 'custom-repo' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_descr('custom-repo') }
        else
          it { should contain_zypprepo('spectest-repo').with_descr('custom-repo') }
        end
      end

      context 'when downcase_baseurl is set to valid boolean true and baseurl contains uppercases' do
        let(:params) {
          default_params.merge({
            :baseurl          => 'http://specific.url/REPO',
            :downcase_baseurl => true,
          })
        }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_baseurl('http://specific.url/repo') }
        else
          it { should contain_zypprepo('spectest-repo').with_baseurl('http://specific.url/repo') }
        end
      end

      # ensure bool2str functionality
      context 'when enabled is set to valid boolean false' do
        let(:params) { default_params.merge({ :enabled => false }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_enabled('0') }
        else
          it { should contain_zypprepo('spectest-repo').with_enabled('0') }
        end
      end

      # ensure backward compatibility for migration only
      context 'when enabled is set to valid string 0' do
        let(:params) { default_params.merge({ :enabled => '0' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_enabled('0') }
        else
          it { should contain_zypprepo('spectest-repo').with_enabled('0') }
        end
      end

      context 'when exclude is set to valid string not_me' do
        let(:params) { default_params.merge({ :exclude => 'not_me' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_exclude('not_me') }
        else
          it { should contain_zypprepo('spectest-repo').without_exclude }
        end
      end

      # ensure bool2str functionality
      context 'when gpgcheck is set to valid boolean true' do
        let(:params) { default_params.merge({ :gpgcheck => true }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_gpgcheck('1') }
        else
          it { should contain_zypprepo('spectest-repo').with_gpgcheck('1') }
        end
      end

      # ensure backward compatibility for migration only
      context 'when gpgcheck is set to valid string 1' do
        let(:params) { default_params.merge({ :gpgcheck => '1' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_gpgcheck('1') }
        else
          it { should contain_zypprepo('spectest-repo').with_gpgcheck('1') }
        end
      end

      context 'when gpgkey_source is set to valid string http://path.to/gpgkey' do
        let(:params) { default_params.merge({ :gpgkey_source => 'http://path.to/gpgkey' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_gpgkey('http://path.to/gpgkey') }
        else
          it { should contain_zypprepo('spectest-repo').with_gpgkey('http://path.to/gpgkey') }
        end
      end

      # ensure bool2str functionality
      context 'when keeppackages is set to valid boolean true' do
        let(:params) { default_params.merge({ :keeppackages => true }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_keeppackages }
        else
          it { should contain_zypprepo('spectest-repo').with_keeppackages('1') }
        end
      end

      # ensure backward compatibility for migration only
      context 'when keeppackages is set to valid string 1' do
        let(:params) { default_params.merge({ :keeppackages => '1' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_keeppackages }
        else
          it { should contain_zypprepo('spectest-repo').with_keeppackages('1') }
        end
      end

      context 'when priority is set to valid integer 42' do
        let(:params) { default_params.merge({ :priority => 42 }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_priority('42') }
        else
          it { should contain_zypprepo('spectest-repo').with_priority('42') }
        end
      end

      # ensure backward compatibility for migration only
      context 'when priority is set to valid string 42' do
        let(:params) { default_params.merge({ :priority => '42' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_priority('42') }
        else
          it { should contain_zypprepo('spectest-repo').with_priority('42') }
        end
      end

      context 'when proxy is set to valid string http://proxy.test' do
        let(:params) { default_params.merge({ :proxy => 'http://proxy.test' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').with_proxy('http://proxy.test') }
        else
          it { should contain_zypprepo('spectest-repo').without_proxy }
        end
      end

      context 'when type is set to valid string yum' do
        let(:params) { default_params.merge({ :type => 'yum' }) }
        if repotype == 'yum'
          it { should contain_yumrepo('spectest-repo').without_type }
        else
          it { should contain_zypprepo('spectest-repo').with_type('yum') }
        end
      end
    end
  end # %w[yum zypper].each do |repotype|

  # RPM Key handling
  describe 'with gpgkey_keyid set to valid string 0608B895' do
    let(:params) { mandatory_params.merge({ :gpgkey_keyid => '0608B895' }) }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /swrepo::repo::gpgkey_keyid is specified but swrepo::repo::gpgkey_source is missing/)
    end
  end

  describe 'with gpgkey_source set to valid string http://url.to/gpgkey' do
    let(:params) { mandatory_params.merge({ :gpgkey_source => 'http://url.to/gpgkey' }) }
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

  describe 'variable type and content validations' do
    validations = {
      'boolean & stringified bools' => {
        :name    => %w[autorefresh downcase_baseurl enabled gpgcheck keeppackages],
        :valid   => [true, 'false', '1', 0], # support for stringified booleans is for backward compatibility only
        :invalid => ['string', %w[array], { 'ha' => 'sh' }, 3, 2.42, nil],
        :message => '(is not a boolean|str2bool)',
      },
      # ensure it only takes integers between 1 and 99
      'integer 1..99' => {
        :name    => %w(priority),
        :valid   => [1, 99],
        :invalid => [0, 100, 'string', %w(array), { 'ha' => 'sh' }, 2.42, true, nil],
        :message => '(is not an integer|is not a number|validate_integer)',
      },
      'regex for URLs' => {
        :name    => %w[baseurl gpgkey_source proxy],
        :valid   => %w[http://spec.test/repo https://te.st/ing/],
        :invalid => [%w[array], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        :message => '(is not a string|is not an URL)',
      },
      'regex for repotype' => {
        :name    => %w[repotype],
        :valid   => %w[yum zypper],
        :invalid => ['string', %w[array], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        :message => '(is not a string|repotype is invalid)',
      },
      'regex for type' => {
        :name    => %w[type],
        :valid   => %w[yum yast2 rpm-md plaindir],
        :invalid => ['string', %w[array], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        :message => '(is not a string|type is invalid)',
      },
      'string' => {
        :name    => %w[descr exclude],
        :valid   => ['string', nil],
        :invalid => [%w[array], { 'ha' => 'sh' }, 3, 2.42, true],
        :message => 'is not a string',
      },
      'string (HEX)' => {
        :name    => %w[gpgkey_keyid],
        :params  => { :gpgkey_source => 'http://spec.test/repo' }, # mandatory for gpgkey_keyid usage
        :valid   => %w[DEADC0DE],
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
