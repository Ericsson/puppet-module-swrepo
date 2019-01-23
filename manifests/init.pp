# == Class: swrepo
#
# Module to manage swrepo
#
class swrepo (
  $repotype         = undef,
  $repos            = undef,
  $hiera_merge      = false,
  $config_dir_name  = undef,
  $config_dir_purge = false,
  $apt_setting      = undef,
) {

  $hiera_merge_real = str2bool($hiera_merge)
  validate_bool($hiera_merge_real)
  $config_dir_purge_real = str2bool($config_dir_purge)
  validate_bool($config_dir_purge_real)

  if $config_dir_name and is_string($config_dir_name) == false {
    fail('swrepo::config_dir_name is not a string')
  }

  if is_string($repotype) == false { fail('swrepo::repotype is not a string') }

  if $repotype == 'apt' and $::osfamily != 'Debian' { fail('swrepo::repo::repotype with value apt is only valid on osfamily Debian' ) }

  case $::osfamily {
    'RedHat': {
      $repotype_default = 'yum'
      $config_dir_name_real = '/etc/yum.repos.d'
      if $config_dir_purge_real == true {
        file { "${config_dir_name_real}/redhat.repo":
          require => File[$config_dir_name_real],
        }
      }
    }
    'Suse':   {
      $config_dir_name_real = '/etc/zypp/repos.d'
      case $::operatingsystemrelease {
        /^(11|12)\./: { $repotype_default = 'zypper' }
        default:      { fail("Supported osfamilies are Debian, RedHat and Suse 11/12. Yours identified as <${::osfamily}-${::operatingsystemrelease}>") }
      }
    }
    'Debian':  {
      $repotype_default = 'apt'
      $config_dir_name_real = undef
    }
    default: { fail("Supported osfamilies are Debian, RedHat and Suse 11/12. Yours identified as <${::osfamily}-${::operatingsystemrelease}>") }
  }

  # Manage repo directory
  if $config_dir_purge_real == true and $config_dir_name_real != undef {
    file { $config_dir_name_real:
      ensure  => directory,
      recurse => $config_dir_purge_real,
      purge   => $config_dir_purge_real,
    }
  }

  $repotype_real = $repotype ? {
    undef   => $repotype_default,
    default => $repotype,
  }

  $defaults = {
    repotype => $repotype_real,
  }

  if $repos != undef {
    if $hiera_merge_real == true {
      $repos_real = hiera_hash('swrepo::repos')
    } else {
      $repos_real = $repos
    }
    validate_hash($repos_real)
    create_resources('swrepo::repo', $repos_real, $defaults)
  }

  if $apt_setting != undef {
    if $hiera_merge_real == true {
      $apt_setting_real = hiera_hash('swrepo::apt_setting')
    } else {
      $apt_setting_real = $apt_setting
    }
    validate_hash($apt_setting_real)
    create_resources('apt::setting', $apt_setting_real)
  }
}
