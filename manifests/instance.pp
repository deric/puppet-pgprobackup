# @summary Configure a DB instance
#
# Prepares PostgreSQL host for running backups.
#
# @param id
#   Unique identifier within `host_group`
# @param cluster
#   Could be used to group primary with standby servers
# @param server_address
#   Address used for connecting to the DB server
# @param server_port
#   DB port
# @param db_name
#   Database used for backups
# @param db_user
#   User connecting to database
# @param db_cluster
#   Postgresql cluster e.g. `main`
# @param db_dir
#   PostgreSQL home directory
# @param manage_dbuser
#   Whether role for running backups should be managed.
# @param version
#   Major PostgreSQL release version for installing pg_probackup package
# @param backups
#   Hash with backups schedule
# @example
#   pgprobackup::instance::backups:
#     common:
#       FULL:
#         hour: 3
#         minute: 15
#         weekday: 0
#       DELTA:
#         hour: 0
#         minute: 45
#
# @param retention_redundancy
#   The number of full backup copies to keep in the backup catalog.
# @param retention_window
#   Defines the earliest point in time for which pg_probackup can complete the recovery.
# @param delete_expired
#   Delete expired backups when `retention_redundancy` or `retention_window` is set.
# @param merge_expired
#   Merge expired backups when `retention_redundancy` or `retention_window` is set.
# @param threads
#   Number of parallel threads
# @param temp_slot
#   Use temporary replication slot
# @param slot
#   Replication slot name
# @param validate
#   Whether backups should be validated after taking backup
# @param compress_algorithm
#   Either `zlib`, `pglz` or `none` (default: `none`)
# @param compress_level
#   Integer between 0 and 9 (default: `1`)
# @param archive_timeout
#   Timeout in seconds for copying all remaining WAL files.
# @param remote_user
#   user used for ssh connection to the DB instance
# @param remote_port
#   ssh port used for connection to the DB instance from catalog server
# @param binary
#   custom script to be executed as backup command
# @param redirect_console
#   Redirect console output to a log file (make sense especially with custom backup command)
# @param log_console
#   File for storing console logs
# @param log_rotation_size
#   rotate logfile if its size exceeds this value; 0 disables; (default: 0)
#   available units: 'kB', 'MB', 'GB', 'TB' (default: kB)
# @param log_rotation_age
#   rotate logfile if its age exceeds this value; 0 disables; (default: 0)
#   available units: 'ms', 's', 'min', 'h', 'd' (default: min)
# @param db_password
# @param seed
# @param manage_ssh_keys
# @param manage_host_keys
# @param manage_pgpass
# @param manage_hba
# @param manage_cron
# @param manage_grants
#  Whether grants needed for backups are managed, default true
# @param archive_wal
# @param backup_dir
# @param backup_user
# @param ssh_key_fact
# @param log_dir
# @param log_file
# @param log_level_file
# @param log_level_console
# @param package_name
# @param package_ensure
#
# @example
#   include pgprobackup::instance
class pgprobackup::instance (
  String                            $id                   = $facts['networking']['hostname'],
  Optional[String]                  $cluster              = undef,
  String                            $server_address       = $facts['networking']['fqdn'],
  Integer                           $server_port          = 5432,
  Boolean                           $manage_dbuser        = true,
  String                            $db_dir               = '/var/lib/postgresql',
  String                            $db_name              = $pgprobackup::db_name,
  String                            $db_user              = $pgprobackup::db_user,
  String                            $db_cluster           = 'main',
  Optional[Variant[String,Sensitive[String]]] $db_password = undef,
  Optional[String]                  $seed                 = undef,
  String                            $remote_user          = 'postgres',
  Integer                           $remote_port          = 22,
  Boolean                           $manage_ssh_keys      = $pgprobackup::manage_ssh_keys,
  Boolean                           $manage_host_keys     = $pgprobackup::manage_host_keys,
  Boolean                           $manage_pgpass        = $pgprobackup::manage_pgpass,
  Boolean                           $manage_hba           = $pgprobackup::manage_hba,
  Boolean                           $manage_cron          = $pgprobackup::manage_cron,
  Boolean                           $manage_grants        = true,
  Boolean                           $archive_wal          = false,
  Stdlib::AbsolutePath              $backup_dir           = $pgprobackup::backup_dir,
  String                            $backup_user          = $pgprobackup::backup_user,
  Optional[String]                  $ssh_key_fact         = $facts['pgprobackup_instance_key'],
  Optional[Stdlib::AbsolutePath]    $log_dir              = $pgprobackup::log_dir,
  Optional[String]                  $log_file             = undef,
  Optional[Pgprobackup::LogLevel]   $log_level_file       = undef,
  Optional[Pgprobackup::LogLevel]   $log_level_console    = undef,
  Optional[Pgprobackup::Config]     $backups              = undef,
  # lint:ignore:lookup_in_parameter
  String                            $version              = lookup('postgresql::globals::version'),
  # lint:endignore
  String                            $package_name         = $pgprobackup::package_name,
  String                            $package_ensure       = $pgprobackup::package_ensure,
  Optional[Integer]                 $retention_redundancy = undef,
  Optional[Integer]                 $retention_window     = undef,
  Boolean                           $delete_expired       = true,
  Boolean                           $merge_expired        = false,
  Optional[Integer]                 $threads              = undef,
  Boolean                           $temp_slot            = false,
  Optional[String]                  $slot                 = undef,
  Boolean                           $validate             = true,
  Optional[String]                  $compress_algorithm   = undef,
  Integer                           $compress_level       = 1,
  Optional[Integer]                 $archive_timeout      = undef,
  Optional[String]                  $binary               = undef,
  Boolean                           $redirect_console     = false,
  Optional[String]                  $log_console          = undef,
  Optional[String]                  $log_rotation_size    = undef,
  Optional[String]                  $log_rotation_age     = undef,
) inherits pgprobackup {
  $_cluster = $cluster ? {
    undef   => $id,
    default => $cluster
  }

  class { 'pgprobackup::install':
    versions       => [$version],
    package_name   => $package_name,
    package_ensure => $package_ensure,
  }

  $_seed = $seed ? {
    undef   => stdlib::fqdn_rand_string(64),
    default => $seed,
  }

  # Generate password if not defined
  $real_password = $db_password ? {
    undef   => stdlib::fqdn_rand_string(64, undef, $_seed),
    default => $db_password =~ Sensitive ? {
      true  => $db_password.unwrap,
      false => $db_password
    },
  }

  if $manage_dbuser {
    postgresql::server::role { $db_user:
      login         => true,
      password_hash => postgresql::postgresql_password($db_user, $real_password),
      superuser     => false,
      replication   => true,
    }

    postgresql::server::database { $db_name:
      owner   => $db_user,
      require => Postgresql::Server::Role[$db_user],
    }

    if $manage_grants {
      case $version {
        '9.6': {
          fail("PostgreSQL ${version} not supported")
        }
        default: {
          # grants for postgresql 10 and newer
          class { 'pgprobackup::grants':
            db_name => $db_name,
            db_user => $db_user,
            version => $version,
            require => Postgresql::Server::Database[$db_name],
          }
        }
      }
    }
  }

  # tag all target catalogs
  if(!empty($backups)) {
    $tags = $backups.map|$group, $config| {
      "pgprobackup-${group}"
    }
  } else {
    $tags = ["pgprobackup-${pgprobackup::host_group}"]
  }

  if $manage_host_keys {
    # Export own host key
    @@sshkey { "postgres-${server_address}":
      ensure       => present,
      host_aliases => [$facts['networking']['hostname'], $facts['networking']['fqdn'], $facts['networking']['ip'], $server_address],
      key          => $facts['ssh']['ecdsa']['key'],
      type         => $pgprobackup::host_key_type,
      target       => "${backup_dir}/.ssh/known_hosts",
      tag          => $tags,
    }
  }

  if $manage_ssh_keys {
    # Export own public SSH key
    if ($ssh_key_fact != undef and $ssh_key_fact != '') {
      $ssh_key_split = split($ssh_key_fact, ' ')
      @@ssh_authorized_key { "${remote_user}-${facts['networking']['fqdn']}":
        ensure => present,
        user   => $remote_user,
        type   => $ssh_key_split[0],
        key    => $ssh_key_split[1],
        tag    => $tags,
      }
    }
  }

  if $manage_pgpass {
    # Export .pgpass content to pgprobackup catalog
    @@file_line { "pgprobackup_pgpass_content-${id}":
      path  => "${backup_dir}/.pgpass",
      line  => "${server_address}:${server_port}:${db_name}:${db_user}:${real_password}",
      match => "^${regexpescape($server_address)}:${server_port}:${db_name}:${db_user}",
      tag   => $tags,
    }

    @@file_line { "pgprobackup_pgpass_replication-${id}":
      path  => "${backup_dir}/.pgpass",
      line  => "${server_address}:${server_port}:replication:${db_user}:${real_password}",
      match => "^${regexpescape($server_address)}:${server_port}:replication:${db_user}",
      tag   => $tags,
    }
  }

  if !empty($backups) {
    $backups.each |String $host_group, Hash $config| {
      # lint:ignore:strict_indent
      @@exec { "pgprobackup_add_instance_${facts['networking']['fqdn']}-${host_group}":
        command => @("CMD"/L),
        pg_probackup-${version} add-instance -B ${backup_dir} --instance ${_cluster} \
        --remote-host=${server_address} --remote-user=${remote_user} \
        --remote-port=${remote_port} -D ${db_dir}/${version}/${db_cluster}
        | -CMD
        path    => ['/usr/bin'],
        cwd     => $backup_dir,
        onlyif  => "test ! -d ${backup_dir}/backups/${_cluster}",
        tag     => "pgprobackup_add_instance-${host_group}",
        user    => $backup_user, # note: error output might not be captured
        require => Package["${package_name}-${version}"],
      }
      # lint:endignore

      # Collect resources exported by pgprobackup::catalog
      Postgresql::Server::Pg_hba_rule <<| tag == "pgprobackup-${host_group}" |>>

      if $manage_ssh_keys {
        # Import public key from backup server as authorized
        Ssh_authorized_key <<| tag == "pgprobackup-catalog-${host_group}" |>> {
          require => Class['postgresql::server'],
        }
      }

      if $manage_host_keys {
        # Import backup server host key
        Sshkey <<| tag == "pgprobackup-catalog-${host_group}" |>>
      }

      if $manage_cron {
        $config.each |$backup_type, $schedule| {
          # declare cron job, use defaults from instance
          create_resources(pgprobackup::cron_backup, { "cron_backup-${host_group}-${server_address}-${backup_type}" => $schedule }, {
              id                   => $id,
              cluster              => $_cluster,
              db_name              => $db_name,
              db_user              => $db_user,
              version              => $version,
              host_group           => $host_group,
              backup_dir           => $backup_dir,
              backup_type          => $backup_type,
              backup_user          => $backup_user,
              server_address       => $server_address,
              delete_expired       => $delete_expired,
              retention_redundancy => $retention_redundancy,
              retention_window     => $retention_window,
              merge_expired        => $merge_expired,
              threads              => $threads,
              temp_slot            => $temp_slot,
              slot                 => $slot,
              validate             => $validate,
              compress_algorithm   => $compress_algorithm,
              compress_level       => $compress_level,
              archive_timeout      => $archive_timeout,
              archive_wal          => $archive_wal,
              log_dir              => $log_dir,
              log_file             => $log_file,
              log_level_file       => $log_level_file,
              log_level_console    => $log_level_console,
              remote_user          => $remote_user,
              remote_port          => $remote_port,
              binary               => $binary,
              redirect_console     => $redirect_console,
              log_rotation_size    => $log_rotation_size,
              log_rotation_age     => $log_rotation_age,
          })
        }
      } # manage_cron
    } # host_group
  }
}
