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

# @example
#   include pgprobackup
class pgprobackup(
  String $package_ensure  = 'present',
  String $package_name,
  String $version         = '12',
  String $host_group      = 'common',
  Boolean $debug_symbols  = true,
  Optional[String] $debug_suffix,
) {

  contain pgprobackup::install
}
