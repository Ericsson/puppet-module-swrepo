# == Class: swrepo
#
# Module to manage swrepo
#
class swrepo (
  $repotype     = undef,
  $repos        = undef,
  $hiera_merge  = false,
) {

  $hiera_merge_real = str2bool($hiera_merge)
  validate_bool($hiera_merge_real)
  if is_string($repotype) == false { fail('swrepo::repotype is not a string') }

  case $::osfamily {
    'RedHat': { $repotype_default = 'yum' }
    'Suse':   {
      case $::lsbmajdistrelease {
        '11','12': { $repotype_default = 'zypper' }
        default:   { fail("Supported osfamilies are RedHat and Suse 11/12. Yours identified as <${::osfamily}-${::lsbmajdistrelease}>") }
      }
    }
    default:  { fail("Supported osfamilies are RedHat and Suse 11/12. Yours identified as <${::osfamily}-${::lsbmajdistrelease}>") }
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
