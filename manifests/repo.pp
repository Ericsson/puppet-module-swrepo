# The swrepo::repo definition is used to configure repositories.
# You can also specify swrepo::repos from hiera as a hash of repositories and they will be created by the base class using create_resources.
#
# @param baseurl
#   Specify the base URL for the repository.
#
# @param repotype
#   Specify the type of repository to configure. Valid values are 'yum' and 'zypper'.
#
# @param autorefresh
#   Specify if autorefresh will be used. Hint: only used for zypper, ignored on yum.
#
# @param descr
#   A human-readable description of the repository.
#
# @param downcase_baseurl
#   Trigger if $baseurl should be converted to lowercase characters.
#
# @param enabled
#   Specify if the repository will be used.
#
# @param exclude
#   List of shell globs. Matching packages will never be considered in updates or installs for the repository.
#
# @param gpgcheck
#   Specify if GPG signature checking will be used for packages from this repository.
#
# @param gpgkey_keyid
#   KeyID for the GPG key to import. 8 char hex key in uppercase. When $gpgkey_source is not specified too, the module will fail.
#
# @param gpgkey_source
#   URL pointing to the ASCII-armored GPG key file for the repository. When $gpgkey_keyid is not specified too,
#   this will be ignored silently.
#
# @param keeppackages
#   Specify if keeppackages will be used. Hint: only used for zypper, ignored on yum.
#
# @param priority
#   Priority of this repository from 1-99. Requires that the priorities plugin is installed and enabled.
#
# @param proxy
#   URL to the proxy server that should be used. Hint: only used for yum, ignored on zypper.
#
# @param type
#   Specify the type parameter. Valid values are 'yum', 'yast2', 'rpm-md', and 'plaindir'. Hint: only used for zypper, ignored on yum.
#
# @param apt_repos
#   Specify the apt_repos parameter. It is only used for repotype 'apt' and is passed as 'repos' to define 'apt'.
#
# @param apt_release
#   Specify the apt_release parameter. It is only used for repotype 'apt' and is passed as 'release' to define 'apt'.
#   Defaults to your current OS release. Hint: only used for apt, ignored on yum and zypper
#
# @param config_dir
#   TODO: add documentation
#
# @param config_dir_purge
#   TODO: add documentation
#
define swrepo::repo (
  Stdlib::HTTPUrl                                      $baseurl,
  Enum['apt', 'yum', 'zypper']                         $repotype,
  Optional[Boolean]                                    $autorefresh      = undef,
  Optional[String[1]]                                  $descr            = undef,
  Boolean                                              $downcase_baseurl = false,
  Boolean                                              $enabled          = true,
  Optional[String[1]]                                  $exclude          = undef,
  Optional[Boolean]                                    $gpgcheck         = undef,
  Optional[String[1]]                                  $gpgkey_keyid     = undef,
  Optional[Stdlib::HTTPUrl]                            $gpgkey_source    = undef,
  Optional[Boolean]                                    $keeppackages     = undef,
  Optional[Integer[1,99]]                              $priority         = undef,
  Optional[Stdlib::HTTPUrl]                            $proxy            = undef,
  Optional[Enum['yum', 'yast2', 'rpm-md', 'plaindir']] $type             = undef,
  String[1]                                            $apt_repos        = 'main',
  Optional[String[1]]                                  $apt_release      = undef,
  Optional[Stdlib::Absolutepath]                       $config_dir       = undef,
  Optional[Boolean]                                    $config_dir_purge = undef,
) {
  # variable validations
  if $gpgkey_keyid != undef and $gpgkey_source == undef { fail('swrepo::repo::gpgkey_keyid is specified but swrepo::repo::gpgkey_source is missing.') } #lint:ignore:140chars

  # variable preparations
  if $autorefresh == undef {
    $autorefresh_num = undef
  } else {
    $autorefresh_num = bool2num(str2bool($autorefresh))
  }

  if $downcase_baseurl == true {
    $baseurl_real = downcase($baseurl)
  } else {
    $baseurl_real = $baseurl
  }

  if $gpgkey_keyid != undef and $gpgkey_source != undef {
    $gpgkey_hash = { 'id' => $gpgkey_keyid, 'source' => $gpgkey_source }
  } else {
    $gpgkey_hash = undef
  }

  if $gpgcheck == undef {
    $gpgcheck_num = undef
  } else {
    $gpgcheck_num = bool2num(str2bool($gpgcheck))
  }

  if $keeppackages == undef {
    $keeppackages_num = undef
  } else {
    $keeppackages_num = bool2num(str2bool($keeppackages))
  }

  if $priority == undef {
    $priority_num = undef
  } else {
    $priority_num = 0 + $priority # convert stringified to number
  }

  # functionality
  case $repotype {
    'yum': {
      yumrepo { $name:
        baseurl  => $baseurl_real,
        descr    => $descr,
        enabled  => bool2num($enabled),
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
        enabled      => bool2num($enabled),
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
        ensure         => bool2str($enabled, 'present', 'absent'),
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
  if $config_dir_purge == true and $config_dir != undef {
    file { "${config_dir}/${name}.repo":
      require => File[$config_dir],
    }
  }

  if $repotype =~ /yum|zypper/ and ($gpgkey_source and $gpgkey_keyid) {
    rpmkey { $gpgkey_keyid:
      ensure => present,
      source => $gpgkey_source,
    }
  }
}
