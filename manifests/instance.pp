# @summary Configure a DB instance
#
# Prepares PostgreSQL host for running backups.
#
# @param id
#   Unique identifier within `host_group`
# @param host_group
#   Allows grouping DB servers to same backup server
# @param server_address
#   Address used for connecting to the DB server
# @param server_port
#   DB port
# @param manage_dbuser
#   Whether role for running backups should be managed.
# @param version
#   Major PostgreSQL release version for installing pg_probackup package
# @example
#   include pgprobackup::instance
class pgprobackup::instance(
  String  $id                               = $::hostname,
  String  $host_group                       = $pgprobackup::host_group,
  String  $server_address                   = $::fqdn,
  String  $cluster                          = 'main',
  Integer $server_port                      = 5432,
  Boolean $manage_dbuser                    = true,
  String  $db_name                          = $pgprobackup::db_name,
  String  $db_user                          = $pgprobackup::db_user,
  String  $db_password                      = '',
  Optional[String] $seed                    = undef,
  Boolean $manage_ssh_keys                  = $pgprobackup::manage_ssh_keys,
  Boolean $manage_host_keys                 = $pgprobackup::manage_host_keys,
  Boolean $manage_pgpass                    = $pgprobackup::manage_pgpass,
  Boolean $manage_hba                       = $pgprobackup::manage_hba,
  Boolean $manage_cron                      = $pgprobackup::manage_cron,
  Boolean $archive_wal                      = false,
  Stdlib::AbsolutePath      $backup_dir     = $pgprobackup::backup_dir,
  String                    $backup_user    = $pgprobackup::backup_user,
  String                    $ssh_key_fact   = $::pgprobackup_instance_key,
  Stdlib::AbsolutePath      $log_dir        = $pgprobackup::log_dir,
  String                    $log_file       = $pgprobackup::log_file,
  String                    $log_level      = $pgprobackup::log_level,
  Hash                      $backups        = {},
  String                    $version        = $::postgresql::globals::version,
  String                    $package_name   = $pgprobackup::package_name,
  Enum['present', 'absent'] $package_ensure = 'present',
  ) inherits ::pgprobackup {

  if !defined(Class['postgresql::server']) {
    fail('pgprobackup::instance requires the postgresql::server module installed and configured')
  }

  class {'pgprobackup::install':
    versions       => [$version],
    package_name   => $package_name,
    package_ensure => $package_ensure,
  }

  $_seed = $seed ? {
    undef   => fqdn_rand_string('64',''),
    default => $seed,
  }

  # Generate password if not defined
  $real_password = $db_password ? {
    ''      => fqdn_rand_string('64','',$_seed),
    default => $db_password,
  }

  if $manage_dbuser {
    postgresql::server::role { $db_user:
      login         => true,
      password_hash => postgresql_password($db_user, $real_password),
      superuser     => false,
      replication   => true,
    }

    postgresql::server::database { $db_name:
      owner   => $db_user,
      require => Postgresql::Server::Role[$db_user],
    }

    case $version {
      # TODO: add support for 9.5 and 9.6
      '10','11','12': {
        class {'pgprobackup::grants::psql10':
          db_name => $db_name,
          db_user => $db_user,
          require => Postgresql::Server::Database[$db_name],
        }
      }
      default: {
        fail("PostgreSQL ${version} not supported")
      }
    }

  }

  @@exec { "pgprobackup_add_instance_${::fqdn}":
    command => "pg_probackup-${version} add-instance -B ${backup_dir} --instance ${id} --remote-host=${server_address} --remote-user=postgres -D /var/lib/postgresql/${version}/${cluster}",
    path    => ['/usr/bin'],
    onlyif  => "test ! -d ${backup_dir}/backups/${id}",
    tag    => "pgprobackup_add_instance-${host_group}",
  }

  # Collect resources exported by pgprobackup::catalog
  Postgresql::Server::Pg_hba_rule <<| tag == "pgprobackup-${host_group}" |>>

  if $manage_ssh_keys {
    # Add public key from backup server as authorized
    Ssh_authorized_key <<| tag == "pgprobackup-${host_group}" |>> {
      require => Class['postgresql::server'],
    }

    # Export own public SSH key
    if ($ssh_key_fact != undef and $ssh_key_fact != '') {
      $ssh_key_split = split($ssh_key_fact, ' ')
      @@ssh_authorized_key { "postgres-${::fqdn}":
        ensure => present,
        user   => $backup_user,
        type   => $ssh_key_split[0],
        key    => $ssh_key_split[1],
        tag    => "pgprobackup-${host_group}-instance",
      }
    }
  }

  if $manage_pgpass {
    # Export .pgpass content to pgprobackup catalog
    @@file_line { "pgprobackup_pgpass_content-${id}":
      path  => "${backup_dir}/.pgpass",
      line  => "${server_address}:${server_port}:${db_name}:${db_user}:${real_password}",
      match => "^${regexpescape($server_address)}:${server_port}:${db_name}:${db_user}",
      tag   => "pgprobackup-${host_group}",
    }

    @@file_line { "pgprobackup_pgpass_replication-${id}":
      path  => "${backup_dir}/.pgpass",
      line  => "${server_address}:${server_port}:replication:${db_user}:${real_password}",
      match => "^${regexpescape($server_address)}:${server_port}:replication:${db_user}",
      tag   => "pgprobackup-${host_group}",
    }
  }

  if $manage_host_keys {
    # Import backup server host key
    Sshkey <<| tag == "pgprobackup-${host_group}" |>>

    # Export own host key
    @@sshkey { "postgres-${server_address}":
      ensure       => present,
      host_aliases => [$::hostname, $::fqdn, $::ipaddress, $server_address],
      key          => $::sshecdsakey,
      type         => $pgprobackup::host_key_type,
      target       => "${backup_dir}/.ssh/known_hosts",
      tag          => "pgprobackup-${host_group}-instance",
      require      => File["${backup_dir}/.ssh"],
    }
  }

  if $manage_cron {
    $binary = "[ -x /usr/bin/pg_probackup-${version} ] && /usr/bin/pg_probackup-${version}"
    $backup_cmd = "backup -B ${backup_dir}"
    if $archive_wal {
      $stream = ''
    } else {
      # with disabled WAL archiving, stream backup is needed
      $stream = '--stream '
    }
    $logging = "--log-filename=${log_file} --log-level-file=${log_level} --log-directory=${log_dir}"
    if has_key($backups, 'FULL') {
      $full = $backups['FULL']
      @@cron { "pgprobackup_full_${server_address}":
        command  => @("CMD"/L),
        ${binary} ${backup_cmd} --instance ${id} -b FULL ${stream}--remote-host=${server_address} --remote-user=postgres -U ${db_user} -d ${db_name} ${logging}
        | -CMD
        user     => $backup_user,
        weekday  => pick($full['weekday'], '*'),
        hour     => pick($full['hour'], 4),
        minute   => pick($full['minute'], 0),
        month    => pick($full['month'], '*'),
        monthday => pick($full['monthday'], '*'),
        tag      => "pgprobackup-${host_group}",
      }
    }

    if has_key($backups, 'DELTA') {
      $delta = $backups['DELTA']
      @@cron { "pgprobackup_delta_${server_address}":
        command  => @("CMD"/L),
        ${binary} ${backup_cmd} --instance ${id} -b DELTA ${stream}--remote-host=${server_address} --remote-user=postgres -U ${db_user} -d ${db_name} ${logging}
        | -CMD
        user     => $backup_user,
        weekday  => pick($delta['weekday'], '*'),
        hour     => pick($delta['hour'], 4),
        minute   => pick($delta['minute'], 0),
        month    => pick($delta['month'], '*'),
        monthday => pick($delta['monthday'], '*'),
        tag      => "pgprobackup-${host_group}",
      }
    }
  }
}
