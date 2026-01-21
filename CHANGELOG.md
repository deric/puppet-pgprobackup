# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v3.0.0](https://github.com/deric/puppet-pgprobackup/tree/v3.1.0) (2026-01-21)

 - Drop Puppet 7 support
 - Drop Ruby < 3.1 support
 - Support `puppetlabs/yumrepo_core` 3.x
 - Add param `manage_repo` (#11)
 - Use `ssh-ed25519` host key by default

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v2.1.0...v3.0.0)


## [v2.1.0](https://github.com/deric/puppet-pgprobackup/tree/v2.1.0) (2025-10-20)

 - Drop Debian 10, Ubuntu 18.04 support
 - Support Debian 13, Ubuntu 24.04
 - Support puppet/archive 8.x
 - Support puppetlabs/apt 11.x
 - Mark `ssh_key_fact` as Optional
 - Fix rexml dependency vulnerability

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v2.0.2...v2.1.0)



## [v2.0.2](https://github.com/deric/puppet-pgprobackup/tree/v2.0.0) (2024-06-22)

 - require `stdlib > 9.1.0` in order to support passing `undef` to `fqdn_rand_string` as 2nd arg

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v2.0.1...v2.0.2)


## [v2.0.1](https://github.com/deric/puppet-pgprobackup/tree/v2.0.0) (2024-06-21)

 - Use `stdlib::fqdn_rand_string`

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v2.0.0...v2.0.1)


## [v2.0.0](https://github.com/deric/puppet-pgprobackup/tree/v2.0.0) (2024-06-21)

 - Use prefixed Puppet 4.x functions
 - Puppet 8 compatible
 - stdlib >= 9 required

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v1.3.1...v2.0.0)



## [v1.3.1](https://github.com/deric/puppet-pgprobackup/tree/v1.3.1) (2024-04-04)

 - Fix postgresql 15 and 16 support

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v1.3.0...v1.3.1)


## [v1.3.0](https://github.com/deric/puppet-pgprobackup/tree/v1.3.0) (2024-04-04)

 - Optionally mangage grants
 - Support all Postgresql version >= 10

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v1.2.0...v1.3.0)

## [v1.2.0](https://github.com/deric/puppet-pgprobackup/tree/v1.1.0) (2024-02-01)

- Refactor GPG key usage for apt
- Use namespaced function `postgresql::postgresql_password`

## [v1.1.0](https://github.com/deric/puppet-pgprobackup/tree/v1.1.0) (2023-12-20)

- Fixed invalid common.yaml
- Support puppetlabs-postgresql 10.x
- Fix upper bounds for dependencies

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v1.0.0...v1.1.0)

## [v1.0.0](https://github.com/deric/puppet-pgprobackup/tree/v1.0.0) (2023-09-15)

- Puppet 8 compatibility
- Removed legacy facts

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.5.0...v1.0.0)


## [v0.5.0](https://github.com/deric/puppet-pgprobackup/tree/v0.5.0) (2022-05-05)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.4.1...v0.5.0)

### Added

- Better logging [\#8](https://github.com/deric/puppet-pgprobackup/pull/8) ([deric](https://github.com/deric))

## [v0.4.1](https://github.com/deric/puppet-pgprobackup/tree/v0.4.1) (2022-05-04)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.4.0...v0.4.1)

### Added

- Support custom backup binary [\#7](https://github.com/deric/puppet-pgprobackup/pull/7) ([deric](https://github.com/deric))

## [v0.4.0](https://github.com/deric/puppet-pgprobackup/tree/v0.4.0) (2022-05-04)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.3.1...v0.4.0)

### Added

- \[BC\] Support grouping backups by cluster name [\#5](https://github.com/deric/puppet-pgprobackup/pull/5) ([deric](https://github.com/deric))

### Fixed

- Fix importing ssh host keys [\#6](https://github.com/deric/puppet-pgprobackup/pull/6) ([deric](https://github.com/deric))

## [v0.3.1](https://github.com/deric/puppet-pgprobackup/tree/v0.3.1) (2022-04-29)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.3.0...v0.3.1)

### Added

- Support sensitive type [\#4](https://github.com/deric/puppet-pgprobackup/pull/4) ([deric](https://github.com/deric))

## [v0.3.0](https://github.com/deric/puppet-pgprobackup/tree/v0.3.0) (2022-04-28)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.2.2...v0.3.0)

### Added

- Support backups to multiple targets [\#3](https://github.com/deric/puppet-pgprobackup/pull/3) ([deric](https://github.com/deric))

## [v0.2.2](https://github.com/deric/puppet-pgprobackup/tree/v0.2.2) (2022-03-25)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.2.1...v0.2.2)

## [v0.2.1](https://github.com/deric/puppet-pgprobackup/tree/v0.2.1) (2022-03-25)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.2.0...v0.2.1)

## [v0.2.0](https://github.com/deric/puppet-pgprobackup/tree/v0.2.0) (2022-03-25)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/v0.1.0...v0.2.0)

## [v0.1.0](https://github.com/deric/puppet-pgprobackup/tree/v0.1.0) (2021-08-30)

[Full Changelog](https://github.com/deric/puppet-pgprobackup/compare/55ff72233194657655bd61aa382d5f88cbe780b7...v0.1.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
