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
# @example
#   include pgprobackup::instance
class pgprobackup::instance(
  String  $id                            = $::hostname,
  String  $host_group                    = $pgprobackup::host_group,
  String  $server_address                = $::fqdn,
  Integer $server_port                   = 5432,
  Boolean $manage_dbuser                 = true,
  String  $db_name                       = $pgprobackup::db_name,
  String  $db_user                       = $pgprobackup::db_user,
  String  $db_password                   = '',
  Optional[String] $seed                 = undef,
  Boolean $manage_ssh_keys               = $pgprobackup::manage_ssh_keys,
  Boolean $manage_host_keys              = $pgprobackup::manage_host_keys,
  Boolean $manage_pgpass                 = $pgprobackup::manage_pgpass,
  Boolean $manage_hba                    = $pgprobackup::manage_hba,
  Stdlib::AbsolutePath      $backup_dir  = $pgprobackup::backup_dir,
  ) inherits ::pgprobackup {

  if !defined(Class['postgresql::server']) {
    fail('pgprobackup::instance requires the postgresql::server module installed and configured')
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
  }

  # Collect resources exported by pgprobackup::catalog
  Postgresql::Server::Pg_hba_rule <<| tag == "pgprobackup-${host_group}" |>>

  if $manage_ssh_keys {
    Ssh_authorized_key <<| tag == "pgprobackup-${host_group}" |>> {
      require => Class['postgresql::server'],
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
  }

  if $manage_host_keys {
    # Import backup server host key
    Sshkey <<| tag == "pgprobackup-${host_group}" |>>

    # Export own host key
    @@sshkey { "postgres-${id}":
      ensure       => present,
      host_aliases => [$::hostname, $::fqdn, $::ipaddress, $server_address],
      key          => $::sshecdsakey,
      type         => $pgprobackup::host_key_type,
      #target       => "${backup_dir}/.ssh/known_hosts",
      tag          => "pgprobackup-${host_group}-instance",
    }
  }


}
