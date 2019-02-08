# == Class: swrepo
#
# Module to manage swrepo
#
class swrepo (
  $repotype                 = undef,
  $repos                    = undef,
  $repos_hiera_merge        = undef, # Use 'false' once $hiera_merge is deprecated
  $hiera_merge              = undef,
  $config_dir_name          = undef,
  $config_dir_purge         = false,
  $apt_setting              = undef,
  $apt_setting_hiera_merge  = false,
) {

  $repos_hiera_merge_bool = str2bool($repos_hiera_merge)
  validate_bool($repos_hiera_merge_bool)

  if $hiera_merge != undef {
    notify { '*** DEPRECATION WARNING***: Using $hiera_merge is deprecated. Please use $repos_hiera_merge instead!': }
    $hiera_merge_bool = str2bool($hiera_merge)
    validate_bool($hiera_merge_bool)
    if $repos_hiera_merge_bool != $hiera_merge_bool {
      fail("Different values for \$repos_hiera_merge (${repos_hiera_merge}) and \$hiera_merge (${hiera_merge}). Please use only one.")
    } else {
      $repos_hiera_merge_real = $hiera_merge_bool
    }
  } elsif $repos_hiera_merge == undef { # Remove elseif once $hiera_merge is deprecated
    $repos_hiera_merge_real = false
  } else {
    $repos_hiera_merge_real = $repos_hiera_merge_bool
  }

  $apt_setting_hiera_merge_bool = str2bool($apt_setting_hiera_merge)
  validate_bool($apt_setting_hiera_merge_bool)
  $config_dir_purge_bool = str2bool($config_dir_purge)
  validate_bool($config_dir_purge_bool)

  if $config_dir_name and is_string($config_dir_name) == false {
    fail('swrepo::config_dir_name is not a string')
  }

  if is_string($repotype) == false { fail('swrepo::repotype is not a string') }

  if $repotype == 'apt' and $::osfamily != 'Debian' { fail('swrepo::repo::repotype with value apt is only valid on osfamily Debian' ) }

  case $::osfamily {
    'RedHat': {
      $repotype_default = 'yum'
      $config_dir_name_real = '/etc/yum.repos.d'
      if $config_dir_purge_bool == true {
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
  if $config_dir_purge_bool == true and $config_dir_name_real != undef {
    file { $config_dir_name_real:
      ensure  => directory,
      recurse => $config_dir_purge_bool,
      purge   => $config_dir_purge_bool,
    }
  }

  $repotype_real = $repotype ? {
    undef   => $repotype_default,
    default => $repotype,
  }

  $defaults = {
    repotype          => $repotype_real,
    config_dir        => $config_dir_name_real,
    config_dir_purge  => $config_dir_purge_bool,
  }

  if $repos != undef {
    if $repos_hiera_merge_real == true {
      $repos_real = hiera_hash('swrepo::repos')
    } else {
      $repos_real = $repos
    }
    validate_hash($repos_real)
    create_resources('swrepo::repo', $repos_real, $defaults)
  }

  if $apt_setting != undef {
    if $apt_setting_hiera_merge_bool == true {
      $apt_setting_real = hiera_hash('swrepo::apt_setting')
    } else {
      $apt_setting_real = $apt_setting
    }
    validate_hash($apt_setting_real)
    create_resources('apt::setting', $apt_setting_real)
  }
}
