# @summary Manages PostgreSQL backups using pg_probackup
#
# @param package_ensure
#   Ensure package installation
# @param package_name
#   Base package name, e.g. `pg_probackup`, `pg_probackup-std`, `pg_probackup-ent`
# @param host_group
#   Allows grouping DB servers, each host_group should have just one backup catalog.
# @param db_name
#   Database created on DB instance
# @param db_user
#   PostgreSQL role used for connecting to DB instance/replication.
# @param debug_symbols
#   Whether to install package with debugging symbols
# @param debug_suffix
#   Suffix for debug package
# @param backup_dir
#   Path to backup catalog (physical backups storage)
# @param manage_ssh_keys
#   When enabled public SSH key from backup catalog user will be
#   added as authorized key on DB instance
# @param manage_host_keys
#   Adds host's ssh fingerprint to known hosts (required to negotiate ssh connection)
# @param manage_pgpass
#   When true, configures password for database authentication (for backup role).
# @param manage_hba
#   When enabled, create rule for connection from backup catalog server to DB instance.
# @example
#   include pgprobackup
class pgprobackup(
  String                $package_name,
  String                $package_ensure   = 'present',
  String                $host_group       = 'common',
  String                $db_name          = 'backup',
  String                $db_user          = 'backup',
  Boolean               $debug_symbols    = true,
  Optional[String]      $debug_suffix,
  Stdlib::AbsolutePath  $backup_dir       = '/var/lib/pgbackup',
  String                $backup_user      = 'pgbackup',
  Stdlib::AbsolutePath  $log_dir          = '/var/lib/pgbackup/log',
  Boolean               $manage_ssh_keys  = true,
  Boolean               $manage_host_keys = true,
  Boolean               $manage_pgpass    = true,
  Boolean               $manage_hba       = true,
  Boolean               $manage_cron      = true,
  String                $host_key_type    = 'ecdsa-sha2-nistp256',
) {

  contain pgprobackup::repo

}
