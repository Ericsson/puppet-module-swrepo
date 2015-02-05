# == Class: swrepo
#
# Module to manage swrepo
#
class swrepo (
  $repotype     = 'USE_DEFAULT',
  $repos        = undef,
  $hiera_merge  = false,
) {

  case $::osfamily {
    'RedHat': {
      $default_repotype = 'yum'
    }
    'Suse': {
      case $::lsbmajdistrelease {
        '10': {
          fail('Suse 10 not yet supported')
        }
        '11': {
          $default_repotype = 'zypper'
        }
        default: {
          fail("Unsupported Suse version ${::lsbmajdistrelease}")
        }
      }
    }
    'Debian': {
      fail('Debian not yet supported')
    }
    default: {
      fail("Supported osfamilies are RedHat, Suse and Debian. Yours identified as <${::osfamily}>")
    }
  }

  if $repotype == 'USE_DEFAULT' {
    $_repotype = $default_repotype
  } else {
    $_repotype = $repotype
  }

  $defaults = {
    repotype => $_repotype,
  }

  if type($hiera_merge) == 'string' {
    $hiera_merge_real = str2bool($hiera_merge)
  } else {
    $hiera_merge_real = $hiera_merge
  }
  validate_bool($hiera_merge_real)

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
