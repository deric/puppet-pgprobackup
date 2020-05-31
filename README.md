# puppet-pgprobackup

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

Backup server (where backup data will be stored) requires packages for all different PostgreSQL version that are running the same `host_group`, e.g. `pg_probackup-11`, `pg_probackup-12`.
```puppet
include pgprobackup::catalog
```
NOTE: Package version `catalog` and `instance` needs to be exactly the same! (e.g. `2.3.3-1.6a736c2db6402d77`).

### Instance

DB server:
```puppet
include pgprobackup::instance
```
Configure `pgprobackup` to run full backup every Sunday (via CRON job):
```yaml
pgprobackup::manage_cron: true
pgprobackup::instance::backups:
  FULL:
    hour: 3
    minute: 15
    weekday: 0 # same as `7` or `Sunday`
```
Incremental (`DELTA`) backups every day except Sunday:
```yaml
pgprobackup::instance::backups:
  FULL:
    weekday: 0
  DELTA:
    weekday: 1-6
```

There are many shared parameters between `instance` and `catalog`. Such parameters are defined in `pgprobackup::` namespace, such as `pgprobackup::package_name` (base package name to be installed on both instance and catalog).

 * `retention_window` Defines the earliest point in time for which pg_probackup can complete the recovery.
 * `retention_redundancy` The number of full backup copies to keep in the backup catalog.


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