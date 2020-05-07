# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pgprobackup::install
class pgprobackup::install {

  if pgprobackup::manage_repo {
    contain pgprobackup::repo
  }



}
