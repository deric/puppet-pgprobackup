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
#   Whether to install package with debugging symbols, default: true
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
# @param backup_user
# @param manage_cron
# @param log_dir
# @param host_key_type
# @example
#   include pgprobackup
class pgprobackup (
  String                         $package_name,
  String                         $package_ensure,
  String                         $host_group,
  String                         $db_name,
  String                         $db_user,
  Boolean                        $debug_symbols,
  Stdlib::AbsolutePath           $backup_dir,
  String                         $backup_user,
  Boolean                        $manage_ssh_keys,
  Boolean                        $manage_host_keys,
  Boolean                        $manage_pgpass,
  Boolean                        $manage_hba,
  Boolean                        $manage_cron,
  String                         $host_key_type,
  Optional[Stdlib::AbsolutePath] $log_dir = undef,
  Optional[String]               $debug_suffix = undef,
) {
  contain pgprobackup::repo
}
