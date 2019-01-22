# puppet-module-swrepo

[![Build Status](https://travis-ci.org/kodguru/puppet-module-swrepo.png?branch=master)](https://travis-ci.org/kodguru/puppet-module-swrepo)

#### Table of Contents

1. [Module Description](#module-description)
2. [Compatibility](#compatibility)
    * [Dependencies](#dependencies)
3. [Class Descriptions](#class-descriptions)
    * [swrepo](#class-swrepo)
4. [Define Descriptions](#define-descriptions)
    * [swrepo::repo](#defined-type-swreporepo)
5. [Changelog](#changelog)

# Module description

Managing software repositories (yum, zypper)

# Compatibility
This module has been tested to work on the following systems with Puppet v3
(with and without the future parser) and Puppet v4 (with strict variables)
using Ruby versions 1.8.7 (Puppet v3 only), 1.9.3, 2.0.0, 2.1.0 and 2.3.1. It
has also been tested on Puppet 4, 5 and 6.

* EL 7
* EL 6
* EL 5
* Suse 11
* Suse 12
* Ubuntu 16.04
* Ubuntu 18.04

## Dependencies
This module uses the custom types [apt](https://github.com/puppetlabs/puppetlabs-apt), [zypprepo](https://github.com/voxpupuli/puppet-zypprepo) and [rpmkey](https://github.com/stschulte/puppet-rpmkey) as dependencies.

Please ensure that both of these modules are available in your setup:

* https://github.com/puppetlabs/puppetlabs-apt
* https://github.com/voxpupuli/puppet-zypprepo
* https://github.com/stschulte/puppet-rpmkey

When using Puppetv6 [yumrepo_core](https://github.com/puppetlabs/puppetlabs-yumrepo_core) is also required.

* https://github.com/puppetlabs/puppetlabs-yumrepo_core

# Class Descriptions
## Class `swrepo`
### Description
The `swrepo` class is used to prepare and pass data to the `swrepo::repo` define.
The module will stay passive when no repositories are specified to it.

It will set the repository type (apt, yum or zypper) accordingly to the OS family running on.
It will also allow you to merge hiera data through all levels. This is useful for specifying
repositories at different levels of the hierarchy and having them all included in the catalog.

### Parameters

---
#### repotype (string / optional)
Type of repository type to configure. Valid values are 'apt', 'yum' and 'zypper'.
If not specified (undef) it will set the repotype accordingly to the running OS family.

NOTE: 'apt' only works for osfamily Debian because of limitation of the apt module.

- Default: ***undef*** (uses 'apt' for Debian, 'yum' for RHEL and 'zypper' for Suse)

---
#### repos (hash / optional)
Hash of repositories to configure. This hash will be passed to [swrepo::repo](#defined-type-swreporepo) define via create_resources.

- Default: ***undef***

##### Example:
```yaml
swrepo::repos:
  'repo1':
    baseurl: 'http://params.hash/repo1'
  'repo2':
    baseurl:     'http://params.hash/repo2'
    autorefresh: true
    priority:    42
```
*The above will add two repositories: repo1 with defaults and repo2 with autorefresh and priority parameters changed.*

---
#### hiera_merge (boolean / optional)
Trigger to control merges of all found instances of repositories in Hiera. This is useful for specifying repositories resources at different levels of the hierarchy and having them all included in the catalog.

- Default: ***false***
---
#### config_dir_name (string / optional)
Can be used if you want to manage a different directory for repositories.

- Default: ***undef*** but defaults to default repository directory based on OS.

---
#### config_dir_purge (boolean / optional)
When enabled, non-managed files in $config_dir_name will be purged.

#- Default: ***false***

---
#### apt_setting (hash / optional)
Hash of apt settings to configure. This hash will be passed to [apt::setting](#defined-type-aptsetting) define via create_resources.

- Default: ***undef***

##### Example:
```yaml
swrepo::apt_setting:
  conf-httpproxy:
    content: Acquire::http::proxy "http://proxy.hieradomain.tld:8080";
```

---
#### apt_setting_hiera_merge (boolean / optional)
Trigger to control merges of all found instances of apt_setting in Hiera. This is useful for specifying repositories resources at different levels of the hierarchy and having them all included in the catalog.

- Default: ***false***

# Define Descriptions
## Defined type `swrepo::repo`
### Description

The `swrepo::repo` definition is used to configure repositories.

You can also specify `swrepo::repos` from hiera as a hash of repositories and they will be created by the base class using create_resources.

### Parameters

---
#### baseurl (string / mandatory)
Specify the base URL for the repository.

- Default: ***N/A***

---
#### repotype (string / mandatory)
Specify the type of repository to configure. Valid values are 'yum' and 'zypper'.

- Default: ***N/A***

---
#### autorefresh (boolean / optional)
Specify if autorefresh will be used.

**Hint**: only used for zypper, ignored on yum

- Default: ***undef***

---
#### descr (string / optional)
A human-readable description of the repository.

- Default: ***undef***

---
#### downcase_baseurl (boolean / optional)
Trigger if $baseurl should be converted to lowercase characters.

- Default: ***false***

---
#### enabled (boolean / optional)
Specify if the repository will be used.

- Default: ***true***

---
#### exclude (string / optional)
List of shell globs. Matching packages will never be considered in updates or installs for the repository.

- Default: ***undef***

---
#### gpgcheck (boolean / optional)
Specify if GPG signature checking will be used for packages from this repository.

- Default: ***undef***

---
#### gpgkey_keyid (string / optional)
KeyID for the GPG key to import. 8 char hex key in uppercase. When $gpgkey_source is not specified too, the module will fail.

- Default: ***undef***

---
#### gpgkey_source (string / optional)
URL pointing to the ASCII-armored GPG key file for the repository. When $gpgkey_keyid is not specified too, this will be ignored silently.

- Default: ***undef***

---
#### keeppackages (boolean / optional)
Specify if keeppackages will be used.

**Hint**: only used for zypper, ignored on yum

- Default: ***undef***

---
#### priority (integer / optional)
Priority of this repository from 1-99. Requires that the priorities plugin is installed and enabled.

- Default: ***undef***

---
#### proxy (string / optional)
URL to the proxy server that should be used.

**Hint**: only used for yum, ignored on zypper

- Default: ***undef***

---
#### type (string / optional)
Specify the ```type``` parameter. Valid values are 'yum', 'yast2', 'rpm-md', and 'plaindir'.

**Hint**: only used for zypper, ignored on yum

- Default: ***undef***

---
#### apt_repos (string / optional)
Specify the ```apt_repos``` parameter. It's only used for repotype 'apt' and
is passed as 'repos' to define 'apt'

**Hint**: only used for apt, ignored on yum and zypper

---
#### apt_release (string / optional)
Specify the ```apt_release``` parameter. It's only used for repotype 'apt' and
is passed as 'release' to define 'apt'. Defaults to your current OS release.

**Hint**: only used for apt, ignored on yum and zypper

---

# Changelog

* 2.0.0 Adds support for Puppet 5 & 6
        Copied dependencies have been removed. It is needed to include stschulte/puppet-rpmkey and voxpupuli/puppet-zypprepo manually instead.
* 1.0.0 First stable release
