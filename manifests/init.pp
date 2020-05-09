# @summary Manages PostgreSQL backups using pg_probackup
#
# @param package_ensure
#   Ensure package installation
# @param package_name
#   Base package name, e.g. `pg_probackup`, `pg_probackup-std`, `pg_probackup-ent`
# @param version
#   Main PostgreSQL version, to be appended to `package_name`
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
#
# @example
#   include pgprobackup
class pgprobackup(
  String               $package_name,
  String               $package_ensure   = 'present',
  String               $version          = '12',
  String               $host_group       = 'common',
  Boolean              $debug_symbols    = true,
  Optional[String]     $debug_suffix,
  Stdlib::AbsolutePath $backup_dir       = '/var/lib/pgbackup',
  Boolean              $manage_ssh_keys  = true,
  Boolean              $manage_host_keys = true,
  Boolean              $manage_pgpass    = true,
  String               $host_key_type    = 'ecdsa-sha2-nistp521',
) {

  contain pgprobackup::install
}
