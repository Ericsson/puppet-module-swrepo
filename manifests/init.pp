# @summary Class to manage swrepo
# Managing software repositories (yum, zypper)
#
# This module uses the custom types apt, zypprepo and rpmkey as dependencies.
# Please ensure that both of these modules are available in your setup:
#
#   https://github.com/puppetlabs/puppetlabs-apt
#   https://github.com/voxpupuli/puppet-zypprepo
#   https://github.com/stschulte/puppet-rpmkey
#
# When using Puppetv6 yumrepo_core is also required.
#
#   https://github.com/puppetlabs/puppetlabs-yumrepo_core
#
# @example Hiera Example
#
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
# @param repos_hiera_merge
#   Trigger to control merges of all found instances of repositories in Hiera. This is useful for specifying repositories
#   resources at different levels of the hierarchy and having them all included in the catalog.
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
# @param apt_setting_hiera_merge
#   Trigger to control merges of all found instances of apt_setting in Hiera. This is useful for specifying repositories
#   resources at different levels of the hierarchy and having them all included in the catalog.
#
class swrepo (
  Optional[String[1]]            $repotype                 = undef,
  Optional[Hash]                 $repos                    = undef,
  Boolean                        $repos_hiera_merge        = false,
  Optional[Stdlib::Absolutepath] $config_dir_name          = undef,
  Boolean                        $config_dir_purge         = false,
  Optional[Hash]                 $apt_setting              = undef,
  Boolean                        $apt_setting_hiera_merge  = false,
) {
  if $repotype == 'apt' and $facts['os']['family'] != 'Debian' { fail('swrepo::repo::repotype with value apt is only valid on osfamily Debian' ) } #lint:ignore:140chars

  case $facts['os']['family'] {
    'RedHat': {
      $repotype_default = 'yum'
      $config_dir_name_real = '/etc/yum.repos.d'
      if $config_dir_purge == true {
        file { "${config_dir_name_real}/redhat.repo":
          require => File[$config_dir_name_real],
        }
      }
    }
    'Suse':   {
      $config_dir_name_real = '/etc/zypp/repos.d'
      case $facts['os']['release']['full'] {
        /^(11|12)\./: { $repotype_default = 'zypper' }
        default:      { fail("Supported osfamilies are Debian, RedHat and Suse 11/12. Yours identified as <${facts['os']['family']}-${facts['os']['release']['full']}>") } #lint:ignore:140chars
      }
    }
    'Debian':  {
      $repotype_default = 'apt'
      $config_dir_name_real = undef
    }
    default: { fail("Supported osfamilies are Debian, RedHat and Suse 11/12. Yours identified as <${facts['os']['family']}-${facts['os']['release']['full']}>") } #lint:ignore:140chars
  }

  # Manage repo directory
  if $config_dir_purge == true and $config_dir_name_real != undef {
    file { $config_dir_name_real:
      ensure  => directory,
      recurse => true,
      purge   => true,
    }
  }

  $repotype_real = $repotype ? {
    undef   => $repotype_default,
    default => $repotype,
  }

  $defaults = {
    repotype          => $repotype_real,
    config_dir        => $config_dir_name_real,
    config_dir_purge  => $config_dir_purge,
  }

  if $repos != undef {
    if $repos_hiera_merge == true {
      $repos_real = hiera_hash('swrepo::repos')
    } else {
      $repos_real = $repos
    }
    validate_hash($repos_real)
    create_resources('swrepo::repo', $repos_real, $defaults)
  }

  if $apt_setting != undef {
    if $apt_setting_hiera_merge == true {
      $apt_setting_real = hiera_hash('swrepo::apt_setting')
    } else {
      $apt_setting_real = $apt_setting
    }
    validate_hash($apt_setting_real)
    create_resources('apt::setting', $apt_setting_real)
  }
}
