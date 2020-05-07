# @summary Manages PostgreSQL backups using pg_probackup
#
#
#
# @example
#   include pgprobackup
class pgprobackup(
  Boolean $manage_repo = true,
)
{

  contain pgprobackup::install
}
