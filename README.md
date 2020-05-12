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

Backup server:
```puppet
include pgprobackup::catalog
```

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

There are many shared parameters between `instance` and `catalog`. Such parameters are defined in `pgprobackup::` namespace, such as `pgprobackup::version` (major release version, respect PostgreSQL releases: `11`, `12` etc.).
