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
) {

  $hiera_merge_real = str2bool($hiera_merge)
  validate_bool($hiera_merge_real)
  if is_string($repotype) == false { fail('swrepo::repotype is not a string') }

  case $::osfamily {
    'RedHat': {
      $repotype_default = 'yum'
      $config_dir_name_real = '/etc/yum.repos.d'
      file { "$config_dir_name_real/redhat.repo":
        require => File[$config_dir_name_real],
      }
    }
    'Suse':   {
      $config_dir_name_real = '/etc/zypp/repos.d'
      case $::operatingsystemrelease {
        /^(11|12)\./: { $repotype_default = 'zypper' }
        default:      { fail("Supported osfamilies are RedHat and Suse 11/12. Yours identified as <${::osfamily}-${::operatingsystemrelease}>") }
      }
    }
    default:  { fail("Supported osfamilies are RedHat and Suse 11/12. Yours identified as <${::osfamily}-${::operatingsystemrelease}>") }
  }

  # Manage repo directory
  if $config_dir_name_real != undef {
    file { $config_dir_name_real:
      ensure  => directory,
      recurse => $config_dir_purge,
      purge   => $config_dir_purge,
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
}
