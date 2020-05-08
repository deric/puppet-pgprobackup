# puppet-pgprobackup

Manages PostgreSQL backups using [pgprobackup](https://postgrespro.github.io/pg_probackup/).

## Description

Module allows configuration of a PostgreSQL instance (role for backup, SSH keys exchange, hba rules) and a (remote) backup catalog (user account, backup directory).

## Setup

### What pgprobackup affects

Module touches many resources, including PostgreSQL configuration that might require server restart (e.g. `archive_mode`).

 - database configuration
 - database roles
 - SSH keys
 - CRON jobs
 - user accounts

### Setup Requirements

 - `puppetlabs/postgresql` is expected to managed PostgreSQL instance

## Usage

DB server:
```puppet
include pgprobackup::instance
```

Backup server:
```puppet
include pgprobackup::catalog
```
