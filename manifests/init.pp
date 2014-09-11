# == Class: swrepo
#
# Module to manage swrepo
#
class swrepo (
  $repotype = 'USE_DEFAULT',
  $repos    = undef,
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

  if $repos {
    validate_hash($repos)
    create_resources('swrepo::repo', $repos, $defaults)
  }
}
