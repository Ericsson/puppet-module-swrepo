# @summary Class to manage swrepo
# Managing software repositories (apt, yum, zypper)
#
# This module uses the custom types apt, zypprepo and rpmkey as dependencies.
# Please ensure that both of these modules are available in your setup:
#
#   https://github.com/puppetlabs/puppetlabs-apt
#   https://github.com/voxpupuli/puppet-zypprepo
#   https://github.com/stschulte/puppet-rpmkey
#
# When using Puppet >= v6 yumrepo_core is also required.
#
#   https://github.com/puppetlabs/puppetlabs-yumrepo_core
#
# @param repotype
#   Type of repository type to configure. Valid values are 'apt', 'yum' and 'zypper'. If not specified (undef) it will
#   set the repotype accordingly to the running OS family.
#   NOTE: 'apt' only works for osfamily Debian because of limitation of the apt module.
#
# @param repos
#   Hash of repositories to configure. This hash will be passed to swrepo::repo define via create_resources.
#
# @example Hiera Example
#   swrepo::repos:
#     'repo1':
#       baseurl: 'http://params.hash/repo1'
#     'repo2':
#       baseurl:     'http://params.hash/repo2'
#       autorefresh: true
#       priority:    42
#
#   The above will add two repositories: repo1 with defaults and repo2 with autorefresh and priority parameters changed.
#
# @param config_dir_name
#   Can be used if you want to manage a different directory for repositories.
#
# @param config_dir_purge
#   When enabled, non-managed files in $config_dir_name will be purged.
#
# @param apt_setting
#   Hash of apt settings to configure. This hash will be passed to apt::setting define via create_resources.
#
# @example Hiera Example
#   swrepo::apt_setting:
#     conf-httpproxy:
#       content: Acquire::http::proxy "http://proxy.hieradomain.tld:8080";
#
class swrepo (
  Boolean                        $config_dir_purge         = false,
  Hash                           $apt_setting              = {},
  Hash                           $repos                    = {},
  Optional[Stdlib::Absolutepath] $config_dir_name          = undef,
  Optional[String[1]]            $repotype                 = undef,
) {
  # lint:ignore:140chars
  if $repotype == 'apt' and $facts['os']['family'] != 'Debian' { fail('swrepo::repo::repotype with value apt is only valid on osfamily Debian' ) }

  if $facts['os']['family'] in ['Debian', 'RedHat', 'Suse'] == false or $facts['os']['family'] == 'Suse' and $facts['os']['release']['major'] in ['11','12'] == false {
    fail("Supported osfamilies are Debian, RedHat and Suse 11/12. Yours identified as <${facts['os']['family']}-${facts['os']['release']['full']}>")
  }
  # lint:endignore

  if $config_dir_purge == true {
    # Manage repo directory
    if $config_dir_name != undef {
      file { $config_dir_name:
        ensure  => directory,
        recurse => true,
        purge   => true,
      }
    }

    if $facts['os']['family'] == 'RedHat' {
      file { "${config_dir_name}/redhat.repo":
        require => File[$config_dir_name],
      }
    }
  }

  $defaults = {
    repotype          => $repotype,
    config_dir        => $config_dir_name,
    config_dir_purge  => $config_dir_purge,
  }

  create_resources('swrepo::repo', $repos, $defaults)

  if $facts['os']['family'] == 'Debian' {
    create_resources('apt::setting', $apt_setting)
  } elsif $apt_setting != {} {
    fail('swrepo::repo::apt_setting is only valid on osfamily Debian' )
  }
}
