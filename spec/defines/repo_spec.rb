require 'spec_helper'

describe 'swrepo::repo' do
  context 'YUM repo' do
    let(:title) { 'custom-repo' }
    let(:params) {
      {
        :repotype      => 'yum',
        :baseurl       => 'http://yum.server.tld/Repo',
        :descr         => 'custom-repo',
        :gpgcheck      => '1',
        :gpgkey_source => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
        :enabled       => '1',
        :priority      => '1',
        :exclude       => 'kernel-debug',
        :proxy         => 'absent',
      }
    }
    let(:facts) {
      { :osfamily => 'RedHat', }
    }

    it {
      should contain_yumrepo('custom-repo').with({
        'ensure'   => 'present',
        'name'     => 'custom-repo',
        'descr'    => 'custom-repo',
        'baseurl'  => 'http://yum.server.tld/Repo',
        'gpgcheck' => '1',
        'gpgkey'   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
        'enabled'  => '1',
        'priority' => '1',
        'exclude'  => 'kernel-debug',
        'proxy'    => 'absent',
      })
    }
  end

  context 'YUM repo with gpgkey_keyid' do
    let(:title) { 'custom-repo' }
    let(:params) {
      {
        :repotype      => 'yum',
        :baseurl       => 'http://yum.server.tld/repo/SubDir',
        :descr         => 'custom-repo',
        :gpgcheck      => '1',
        :gpgkey_source => 'http://yum.server.tld/GPGKEY',
        :gpgkey_keyid  => '1HEXHEX0',
        :enabled       => '1',
        :priority      => '1',
        :exclude       => 'kernel-debug',
        :proxy         => 'absent',
      }
    }
    let(:facts) {
      { :osfamily => 'RedHat', }
    }

    it {
      should contain_yumrepo('custom-repo').with({
        'ensure'   => 'present',
        'name'     => 'custom-repo',
        'descr'    => 'custom-repo',
        'baseurl'  => 'http://yum.server.tld/repo/SubDir',
        'gpgcheck' => '1',
        'gpgkey'   => 'http://yum.server.tld/GPGKEY',
        'enabled'  => '1',
        'priority' => '1',
        'exclude'  => 'kernel-debug',
        'proxy'    => 'absent',
      })
    }

    it {
      should contain_rpmkey('1HEXHEX0').with({
        'ensure' => 'present',
        'source' => 'http://yum.server.tld/GPGKEY',
      })
    }
  end

  context 'YUM repo with downcase_baseurl = true' do
    let(:title) { 'custom-repo' }
    let(:params) {
      {
        :repotype         => 'yum',
        :baseurl          => 'http://yum.server.tld/repo/SubDir',
        :descr            => 'custom-repo',
        :gpgcheck         => '1',
        :gpgkey_source    => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
        :enabled          => '1',
        :priority         => '1',
        :exclude          => 'kernel-debug',
        :proxy            => 'absent',
        :downcase_baseurl => 'true',
      }
    }
    let(:facts) {
      { :osfamily => 'RedHat', }
    }

    it {
      should contain_yumrepo('custom-repo').with({
        'ensure'   => 'present',
        'name'     => 'custom-repo',
        'descr'    => 'custom-repo',
        'baseurl'  => 'http://yum.server.tld/repo/subdir',
        'gpgcheck' => '1',
        'gpgkey'   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
        'enabled'  => '1',
        'priority' => '1',
        'exclude'  => 'kernel-debug',
        'proxy'    => 'absent',
      })
    }
  end

  context 'YUM repo with ensure = absent' do
    let(:title) { 'custom-repo' }
    let(:params) {
      {
        :ensure        => 'absent',
        :repotype      => 'yum',
        :baseurl       => 'http://yum.server.tld/repo/SubDir',
        :gpgkey_keyid  => '1HEXHEX0',
        :gpgkey_source => 'http://yum.server.tld/GPGKEY',
      }
    }
    let(:facts) {
      { :osfamily => 'RedHat', }
    }

    it {
      should contain_yumrepo('custom-repo').with_ensure('absent')
    }
    it {
      should contain_rpmkey('1HEXHEX0').with_ensure('absent')
    }
  end

  context 'Zypper repo' do
    let(:title) { 'custom-repo' }
    let(:params) {
      {
        :repotype      => 'zypper',
        :baseurl       => 'http://zypp.server.tld/repo',
        :descr         => 'custom-repo',
        :gpgcheck      => '1',
        :gpgkey_source => 'http://zypp.server.tld/GPGKEY',
        :gpgkey_keyid  => '1HEXHEX0',
        :enabled       => '1',
        :priority      => '1',
        :autorefresh   => '1',
        :keeppackages  => '0',
        :type          => 'rpm-md',
      }
    }
    let(:facts) {
      { :osfamily => 'Suse', }
    }

    it {
      should contain_zypprepo('custom-repo').with({
        'name'         => 'custom-repo',
        'descr'        => 'custom-repo',
        'baseurl'      => 'http://zypp.server.tld/repo',
        'gpgcheck'     => '1',
        'gpgkey'       => 'http://zypp.server.tld/GPGKEY',
        'enabled'      => '1',
        'priority'     => '1',
        'autorefresh'  => '1',
        'keeppackages' => '0',
        'type'         => 'rpm-md',
      })
    }
  end

  context 'Zypper repo with gpgkey_keyid' do
    let(:title) { 'custom-repo' }
    let(:params) {
      {
        :repotype      => 'zypper',
        :baseurl       => 'http://zypp.server.tld/repo',
        :descr         => 'custom-repo',
        :gpgcheck      => '1',
        :gpgkey_source => 'http://zypp.server.tld/GPGKEY',
        :gpgkey_keyid  => '1HEXHEX0',
        :enabled       => '1',
        :priority      => '1',
        :autorefresh   => '1',
        :keeppackages  => '0',
        :type          => 'rpm-md',
      }
    }
    let(:facts) {
      { :osfamily => 'Suse', }
    }

    it {
      should contain_zypprepo('custom-repo').with({
        'name'         => 'custom-repo',
        'descr'        => 'custom-repo',
        'baseurl'      => 'http://zypp.server.tld/repo',
        'gpgcheck'     => '1',
        'gpgkey'       => 'http://zypp.server.tld/GPGKEY',
        'enabled'      => '1',
        'priority'     => '1',
        'autorefresh'  => '1',
        'keeppackages' => '0',
        'type'         => 'rpm-md',
      })
    }

    it {
      should contain_rpmkey('1HEXHEX0').with({
        'ensure' => 'present',
        'source' => 'http://zypp.server.tld/GPGKEY',
      })
    }
  end

  context 'Zypper repo with downcase_baseurl = true' do
    let(:title) { 'custom-repo' }
    let(:params) {
      {
        :repotype         => 'zypper',
        :baseurl          => 'http://zypp.server.tld/repo',
        :descr            => 'custom-repo',
        :gpgcheck         => '1',
        :gpgkey_source    => 'http://zypp.server.tld/GPGKEY',
        :gpgkey_keyid     => '1HEXHEX0',
        :enabled          => '1',
        :priority         => '1',
        :autorefresh      => '1',
        :keeppackages     => '0',
        :type             => 'rpm-md',
        :downcase_baseurl => 'true',
      }
    }
    let(:facts) {
      { :osfamily => 'Suse', }
    }

    it {
      should contain_zypprepo('custom-repo').with({
        'name'         => 'custom-repo',
        'descr'        => 'custom-repo',
        'baseurl'      => 'http://zypp.server.tld/repo',
        'gpgcheck'     => '1',
        'gpgkey'       => 'http://zypp.server.tld/GPGKEY',
        'enabled'      => '1',
        'priority'     => '1',
        'autorefresh'  => '1',
        'keeppackages' => '0',
        'type'         => 'rpm-md',
      })
    }
  end

  context "with invalid ensure attribute" do
    let(:title) { 'custom-repo' }
    let(:params) {{
      :ensure   => 'stopped',
      :repotype => 'yum',
      :baseurl  => 'http://yum.server.tld/Repo',
    }}

    it 'should fail' do
      expect {
        should contain_yumrepo('custom-repo')
      }.to raise_error(Puppet::Error,/ensure must be either present or absent/)
    end
  end

  context "with invalid repotype attribute" do
    let(:title) { 'custom-repo' }
    let(:params) {{
      :repotype => 'rpm',
      :baseurl  => 'http://yum.server.tld/Repo',
    }}

    it 'should fail' do
      expect {
        should contain_define('swrepo::repo')
      }.to raise_error(Puppet::Error,/Invalid repotype rpm. Supported repotypes are yum, zypper and apt/)
    end
  end

end
