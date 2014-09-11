# puppet-module-swrepo
===

[![Build Status](https://travis-ci.org/jwennerberg/puppet-module-swrepo.png?branch=master)](https://travis-ci.org/jwennerberg/puppet-module-swrepo)

Puppet module for managing software repositories (yum, zypper, apt)

===

# Compatibility
---------------
This module is built for use with Puppet v3 on the following OS families.

* EL 7
* EL 6
* EL 5
* Suse 11

This module uses the custom types [zypprepo](https://github.com/deadpoint/puppet-zypprepo) and [rpmkey](https://github.com/stschulte/puppet-rpmkey).

===

# Class parameters
------------------

repotype
--------
Type of repository to configure. Default value depending on OS (yum for RHEL and so on).

- *Default*: 'USE_DEFAULT'

repos
-----
Hash of repositories to configure.

- *Default*: undef

===

# Define swrepo::repo
---------------------

*Parameters*
------------

repotype
--------
Type of repository to configure (yum, zypper, apt)

- *Default*: N/A

baseurl
-------
URL  to the directory where the yum repository 'repodata' directory lives.

- *Default*: N/A

enabled
-------
Either '1' or '0'. This tells yum whether or not use this repository.

- *Default*: '1'

autorefresh
-----------
Note: Suse only

- *Default*: undef

gpgcheck
--------
Either '1' or '0'. This tells yum whether or not it should perform a GPG signature check on the packages gotten from this repository.

- *Default*: undef

gpgkey_source
-------------
URL pointing to the ASCII-armored GPG key file for the repository.

- *Default*: undef

gpgkey_keyid
------------
KeyID for the GPG key to import. 8 char hex key in uppercase.

- *Default*: undef

priority
--------
Priority of this repository from 1-99. Requires that the priorities plugin is installed and enabled.

- *Default*: undef

keeppackages
------------
Note: Suse only.

- *Default*: undef

type
----
Note: Suse only.

- *Default*: undef

descr
-----
A human-readable description of the repository.

- *Default*: undef

exclude
-------
List of shell globs. Matching packages will never be considered in updates or installs for this repo.

- *Default*: undef

proxy
-----
URL to the proxy server that yum should use.

- *Default*: undef

