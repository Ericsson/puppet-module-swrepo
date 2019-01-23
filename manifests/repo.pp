# == Define: swrepo::repo
#
# This define manages a repo instance
#
define swrepo::repo (
  $baseurl,
  $repotype,
  $autorefresh      = undef,
  $descr            = undef,
  $downcase_baseurl = false,
  $enabled          = true,
  $exclude          = undef,
  $gpgcheck         = undef,
  $gpgkey_keyid     = undef,
  $gpgkey_source    = undef,
  $keeppackages     = undef,
  $priority         = undef,
  $proxy            = undef,
  $type             = undef,
  $apt_repos        = 'main',
  $apt_release      = undef,
) {

  # variable validations
  if is_string($baseurl) == false { fail('swrepo::repo::baseurl is not a string.') }
  validate_re($baseurl,  '^https?:\/\/[\S]+$', 'swrepo::repo::baseurl is not an URL.')

  if is_string($repotype) == false { fail('swrepo::repo::repotype is not a string.') }
  validate_re($repotype, '^(apt|yum|zypper)$', 'swrepo::repo::repotype is invalid. Supported values are apt, yum and zypper.')

  if is_string($apt_repos) == false { fail('swrepo::repo::repos is not a string.') }

  if $autorefresh == undef {
    $autorefresh_num = undef
  } else {
    $autorefresh_num = bool2num(str2bool("${autorefresh}")) # lint:ignore:only_variable_string
  }

  if is_string($descr) == false { fail('swrepo::repo::descr is not a string.') }

  if str2bool("${downcase_baseurl}") { # lint:ignore:only_variable_string
    $baseurl_real = downcase($baseurl)
  } else {
    $baseurl_real = $baseurl
  }

  $enabled_num = bool2num(str2bool("${enabled}")) # lint:ignore:only_variable_string

  if $::osfamily == 'Debian' {
    if $gpgkey_keyid != undef and $gpgkey_source != undef {
      $gpgkey_hash = {'id' => $gpgkey_keyid, 'source' => $gpgkey_source}
    } else {
      $gpgkey_hash = undef
    }
    if $enabled_num == 1 {
      $enabled_real = 'present'
    } else {
      $enabled_real = 'absent'
    }
  } else {
    $enabled_real = $enabled_num
  }

  if $exclude != undef {
    if is_string($exclude) == false { fail('swrepo::repo::exclude is not a string.') }
  }

  if $gpgcheck == undef {
    $gpgcheck_num = undef
  } else {
    $gpgcheck_num = bool2num(str2bool("${gpgcheck}")) # lint:ignore:only_variable_string
  }

  if $gpgkey_keyid != undef {
    if is_string($gpgkey_keyid) == false { fail('swrepo::repo::gpgkey_keyid is not a string.') }
  }

  if $gpgkey_source != undef {
    if is_string($gpgkey_source) == false { fail('swrepo::repo::gpgkey_source is not a string.') }
    validate_re($gpgkey_source, '^https?:\/\/[\S]+$', 'swrepo::repo::gpgkey_source is not an URL.')
  }

  if $keeppackages == undef {
    $keeppackages_num = undef
  } else {
    $keeppackages_num = bool2num(str2bool("${keeppackages}")) # lint:ignore:only_variable_string
  }

  if $priority == undef {
    $priority_num = undef
  } else {
    case type3x($priority) {
      'integer': { $priority_num = 0 + $priority } # convert stringified to number
      default:   { fail('swrepo::repo::priority is not an integer.') }
    }
    validate_integer($priority_num, 99, 1)
  }

  if $proxy != undef {
    if is_string($proxy) == false { fail('swrepo::repo::proxy is not a string.') }
    validate_re($proxy, '^https?:\/\/[\S]+$', 'swrepo::repo::proxy is not an URL.')
  }

  if $type != undef {
    if is_string($type) == false { fail('swrepo::repo::type is not a string.') }
    validate_re($type, '^(yum|yast2|rpm-md|plaindir)$', 'swrepo::repo::type is invalid. Supported values are yum, yast2, rpm-md, and plaindir.')
  }

  # functionality
  case $repotype {
    'yum': {
      yumrepo { $name:
        baseurl  => $baseurl_real,
        descr    => $descr,
        enabled  => $enabled_real,
        gpgcheck => $gpgcheck_num,
        gpgkey   => $gpgkey_source,
        priority => $priority_num,
        exclude  => $exclude,
        proxy    => $proxy,
      }
    }
    'zypper': {
      zypprepo { $name:
        baseurl      => $baseurl_real,
        descr        => $descr,
        enabled      => $enabled_real,
        gpgcheck     => $gpgcheck_num,
        gpgkey       => $gpgkey_source,
        priority     => $priority_num,
        keeppackages => $keeppackages_num,
        type         => $type,
        autorefresh  => $autorefresh_num,
      }
    }
    'apt': {
      apt::source { $name:
        ensure         => $enabled_real,
        location       => $baseurl_real,
        comment        => $descr,
        allow_unsigned => $gpgcheck_num,
        key            => $gpgkey_hash,
        repos          => $apt_repos,
        release        => $apt_release,
      }
    }
    default: {
      fail("Invalid repotype ${repotype}. Supported repotypes are apt, yum and zypper.")
    }
  }

  # Associate .repo files in directory for yum and zypper
  # This is to prevent files from being purged
  if $swrepo::config_dir_purge_real == true and  $swrepo::config_dir_name_real != undef {
    file { "${swrepo::config_dir_name_real}/${name}.repo":
      require => File[$swrepo::config_dir_name_real],
    }
  }

  if $gpgkey_keyid != undef and $gpgkey_source == undef {
      fail('swrepo::repo::gpgkey_keyid is specified but swrepo::repo::gpgkey_source is missing.')
  }

  if $repotype =~ /yum|zypper/ and ($gpgkey_source and $gpgkey_keyid) {
    rpmkey { $gpgkey_keyid:
      ensure => present,
      source => $gpgkey_source,
    }
  }
}
