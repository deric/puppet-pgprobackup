# @summary Manages PostgreSQL backups using pg_probackup
#
# @param package_ensure
#   Ensure package installation
# @param package_name
#   Base package name, e.g. `pg_probackup`, `pg_probackup-std`, `pg_probackup-ent`
# @param version
#   Main PostgreSQL version, to be appended to `package_name`
# @param debug_sumbols
#   Whether to install package with debugging symbols

# @example
#   include pgprobackup
class pgprobackup(
  String $package_ensure  = 'present',
  String $package_name    = 'pg_probackup',
  String $version         = '12',
  Boolean $debug_symbols  = true
) {

  contain pgprobackup::install
}
