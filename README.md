# puppet-pgprobackup

[![Puppet
Forge](http://img.shields.io/puppetforge/v/deric/pgprobackup.svg)](https://forge.puppet.com/modules/deric/pgprobackup) [![Build Status](https://img.shields.io/github/workflow/status/deric/puppet-pgprobackup/Static%20&%20Spec%20Tests/master)](https://github.com/deric/puppet-pgprobackup/actions?query=branch%3Amaster)



Automates PostgreSQL backups using [pgprobackup](https://postgrespro.github.io/pg_probackup/).

## Description

Module allows configuration of a PostgreSQL instance (role for backup, SSH keys, hba rules) and a (remote) backup catalog (user account, backup directory, host keys, SSH keys).

## Setup

### What pgprobackup affects

Module touches many resources, including PostgreSQL configuration that might require server restart (e.g. when `archive_mode` is modified). Make sure to understand the implications before using it. Each feature could be turned off in case you're using some other mechanism.

 - database configuration
 - database roles
 - role password
 - SSH host keys
 - SSH authorized keys (public SSH keys)
 - CRON jobs
 - user accounts
 - `pgprobackup` catalog

### Setup Requirements

 - Puppet >= 5
 - PostgreSQL instance >= 9.5
 - `puppetlabs/postgresql` is expected to manage the PostgreSQL instance

## Usage

Backup server(s) (where backup data will be stored) requires packages for all different PostgreSQL version that are running the same `host_group`, e.g. `pg_probackup-11`, `pg_probackup-12`.
```puppet
include pgprobackup::catalog
```

each backup server should define:
```yaml
pgprobackup::catalog::host_group: common
# pg_probackup has dedicated binaries for each major PostgreSQL versions
pgprobackup::catalog::versions:
  - '13'
  - '14'
```

NOTE: Package version `catalog` and `instance` needs to be exactly the same! (e.g. `2.3.3-1.6a736c2db6402d77`).

`pgprobackup::package_ensure` allows pinpointing to a specific version:
```puppet
pgprobackup::package_ensure: "2.4.2-1.8db55b42aeece064.%{facts.os.distro.codename}"
```

### Instance

DB server:
```puppet
include pgprobackup::instance
```
Configure `pgprobackup` to run full backup every Sunday (via CRON job):
```yaml
pgprobackup::manage_cron: true
pgprobackup::instance::backups:
  common:
    FULL:
      hour: 3
      minute: 15
      weekday: [0] # same as `7` or `Sunday`
```
Incremental (`DELTA`) backups every day except Sunday:
```yaml
pgprobackup::instance::backups:
  common:
    FULL:
      weekday: 0
    DELTA:
      weekday: [1-6]
```

Incremental (`DELTA`) backups every day except Friday, full backup on Friday:
```yaml
pgprobackup::instance::backups:
  common:
    FULL:
      weekday: 5
    DELTA:
      weekday: [0-4,6]
```

Target backup catalog servers (one database instance can be backed to multiple locations - first catalog is has `host_group` configured as `common` the other `off-site`):


```yaml
pgprobackup::instance::backups:
  common:
    FULL:
      weekday: 0
    DELTA:
      weekday: [1-6]
  # run full backup to `off-site` location on first of each month
  off-site:
    FULL:
      hour: 5
      monthday: 1
      retention_redundancy: 2
      retention_window: 7
      delete_expired: true
      merge_expired: true
      threads: 3
```


There are many shared parameters between `instance` and `catalog`. Such parameters are defined in `pgprobackup::` namespace, such as `pgprobackup::package_name` (base package name to be installed on both instance and catalog).

 * `retention_window` Defines the earliest point in time for which pg_probackup can complete the recovery.
 * `retention_redundancy` The number of full backup copies to keep in the backup catalog.
 * `delete_expired` Delete expired backups when `retention_redundancy` or `retention_window` is set.
 * `merge_expired` Merge expired backups when `retention_redundancy` or `retention_window` is set.

#### Instance parameters

  * `threads` Number of parallel threads
  * `temp_slot` Whether to use temporary replication slot, which should guarantee that WAL won't be removed from primary server. In case of backup failure the slot will be removed (default `false`).
  * `slot` Specifies the replication slot for WAL streaming. Can't be used together with `archive_wal=true`.
  * `validate` Validate backup consistency after backup completition (default: `true`).
  * `compress_algorithm` Currently supported algorithms `zlib` or `pglz` (default: 'none')
  * `compress_level` `0-9` (defalt: `1`)
  * `archive_timeout` Timeout in seconds for copying all remaining WAL files (default `300`).

### Logging

Parameters can be specified on `instance` level:

```yaml
pgprobackup::instance::log_dir: /var/log/pg_probackup
pgprobackup::instance::log_level_file: info
```

or for specific backup:
```yaml
pgprobackup::instance::backups:
  common:
    FULL:
      log_level_file: verbose
```

 * `log_dir` - by default stored to `backup dir/log`
 * `log_file` - custom filename
 * `redirect_console` redirect stdout & stderr to file (default: `false`)
 * `log_console` - custom filename for console log (requires `redirect_console: true`)
 * `log_level_file` - allowed values `off, error, warning, info, log, verbose`
 * `log_level_console` - allowed values `off, error, warning, info, log, verbose`

## Limitations

Error message on `catalog` server:
```
Could not find resource 'Package[pg-probackup-11]' in parameter 'require'
```

means, that the server requires packages for all different Postgresql versions that are being backed up.
```
pgprobackup::catalog::versions:
  - '11'
  - '12'
```