# @summary Configure a DB instance
#
# Prepares PostgreSQL host for running backups.
#
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
  String  $host_group                    = $pgprobackup::host_group,
  String  $server_address                = $::fqdn,
  Integer $server_port                   = 5432,
  Boolean $manage_dbuser                 = true,
  String  $db_user                       = 'backup',
  String  $db_password                   = '',
  Optional[String] $seed                 = undef,
  ) inherits ::pgprobackup {

  if !defined(Class['postgresql::server']) {
    fail('pgprobackup::instance requires the postgresql::server module installed and configured')
  }

  if $manage_dbuser {
    $_seed = $seed ? {
      undef   => fqdn_rand_string('64',''),
      default => $seed,
    }

    # Generate password if not defined
    $real_password = $db_password ? {
      ''      => fqdn_rand_string('64','',$_seed),
      default => $db_password,
    }

    postgresql::server::role { $db_user:
      login         => true,
      password_hash => postgresql_password($db_user, $real_password),
      superuser     => false,
      replication   => true,
    }
  }



}
