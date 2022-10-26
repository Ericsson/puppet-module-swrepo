require 'spec_helper'
describe 'swrepo' do
  on_supported_os.sort.each do |os, os_facts|
    describe "on #{os}" do
      apt_setting_hash = {
        'conf-paramshttpproxy'  => { 'content' => 'Acquire::http::proxy "http://proxy.domain.tld:8080";', 'notify_update' => false },
        'conf-paramshttpsproxy' => { 'content' => 'Acquire::https::proxy "https://proxy.domain.tld:8080";', 'notify_update' => false },
      }
      repos_hash = {
        'params-hash1' => { 'baseurl' => 'http://params.hash/repo1' },
        'params-hash2' => { 'baseurl' => 'http://params.hash/repo2' },
      }
      repos_hash1 = { 'params-hash1' => { 'baseurl' => 'http://params.hash/repo1' } }

      let(:facts) { os_facts }

      context 'with default values for parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('swrepo') }
        it { is_expected.to have_resource_count(0) }
      end

      context 'with config_dir_purge set to valid true' do
        let(:params) { { config_dir_purge: true } }

        if os_facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_file('/etc/yum.repos.d/redhat.repo').only_with_require('File[/etc/yum.repos.d]') }
        else
          it { is_expected.not_to contain_file('/etc/yum.repos.d/redhat.repo') }
          it { is_expected.not_to contain_file('/etc/zypp/repos.d/redhat.repo') }
        end

        case os_facts[:os]['family']
        when 'RedHat'
          it do
            is_expected.to contain_file('/etc/yum.repos.d').only_with(
              {
                'ensure'  => 'directory',
                'recurse' => true,
                'purge'   => true,
              },
            )
          end
        when 'Suse'
          it do
            is_expected.to contain_file('/etc/zypp/repos.d').only_with(
              {
                'ensure'  => 'directory',
                'recurse' => true,
                'purge'   => true,
              },
            )
          end
        else
          it { is_expected.not_to contain_file('/etc/yum.repos.d') }
          it { is_expected.not_to contain_file('/etc/zypp/repos.d') }
        end
      end

      # All tests are 'hidden' in the case clause and therefore rubocop does not see them.
      # rubocop:disable EmptyExampleGroup
      context 'with apt_setting set to valid hash' do
        let(:params) { { apt_setting: apt_setting_hash } }

        case os_facts[:os]['family']
        when 'Debian'
          it { is_expected.to have_swrepo__repo_resource_count(0) }
          it { is_expected.to have_apt__setting_resource_count(2) }
          it do
            is_expected.to contain_apt__setting('conf-paramshttpproxy').with(
              {
                'content'          => 'Acquire::http::proxy "http://proxy.domain.tld:8080";',
                'notify_update'    => false,
              },
            )
          end

          it do
            is_expected.to contain_apt__setting('conf-paramshttpsproxy').with(
              {
                'content'       => 'Acquire::https::proxy "https://proxy.domain.tld:8080";',
                'notify_update' => false,
              },
            )
          end

        else
          it 'fail' do
            expect { is_expected.to contain_class('swrepo') }.to raise_error(Puppet::Error)
          end
        end
      end
      # rubocop:enable EmptyExampleGroup

      context 'with repos set to valid hash' do
        let(:params) { { repos: repos_hash } }

        it { is_expected.to have_swrepo__repo_resource_count(2) }

        case os_facts[:os]['family']
        when 'Suse'
          it { is_expected.to contain_swrepo__repo('params-hash1').with_repotype('zypper') }
          it { is_expected.to contain_swrepo__repo('params-hash2').with_repotype('zypper') }
          it { is_expected.to contain_zypprepo('params-hash1') } # only needed for 100% resource coverage
          it { is_expected.to contain_zypprepo('params-hash2') } # only needed for 100% resource coverage
        when 'RedHat'
          it { is_expected.to contain_swrepo__repo('params-hash1').with_repotype('yum') }
          it { is_expected.to contain_swrepo__repo('params-hash2').with_repotype('yum') }
          it { is_expected.to contain_yumrepo('params-hash1') } # only needed for 100% resource coverage
          it { is_expected.to contain_yumrepo('params-hash2') } # only needed for 100% resource coverage
        when 'Debian'
          it { is_expected.to contain_swrepo__repo('params-hash1').with_repotype('apt') }
          it { is_expected.to contain_swrepo__repo('params-hash2').with_repotype('apt') }
          it { is_expected.to contain_apt__source('params-hash1') } # only needed for 100% resource coverage
          it { is_expected.to contain_apt__source('params-hash2') } # only needed for 100% resource coverage
        end
      end

      context 'with config_dir_name set to valid true' do
        let(:params) { { config_dir_name: '/test/ing' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('swrepo') }
        it { is_expected.to have_resource_count(0) }
      end

      context 'with config_dir_name set to valid true when config_dir_purge is true' do
        let(:params) { { config_dir_name: '/test/ing', config_dir_purge: true } }

        if os_facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_file('/test/ing/redhat.repo').only_with_require('File[/test/ing]') }
        else
          it { is_expected.not_to contain_file('/test/ing/redhat.repo') }
        end

        it { is_expected.to contain_file('/test/ing') }
      end

      context 'with config_dir_name set to valid true when repos is a valid hash' do
        let(:params) { { config_dir_name: '/test/ing', repos: repos_hash1 } }

        case os_facts[:os]['family']
        when 'Suse'
          repotype = 'zypper'
        when 'RedHat'
          repotype = 'yum'
        when 'Debian'
          repotype = 'apt'
        end

        it do
          is_expected.to contain_swrepo__repo('params-hash1').with(
            {
              'repotype'         => repotype,
              'config_dir'       => '/test/ing',
              'config_dir_purge' => false,
            },
          )
        end
      end

      context 'with repotype set to valid yum' do
        let(:params) { { repotype: 'yum' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('swrepo') }
        it { is_expected.to have_resource_count(0) }
      end

      context 'with repotype set to valid yum when repos is a valid hash' do
        let(:params) { { repotype: 'yum', repos: repos_hash1 } }

        it { is_expected.to contain_swrepo__repo('params-hash1').with_repotype('yum') }
      end
    end
  end
end
