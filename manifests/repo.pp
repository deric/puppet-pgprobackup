# @api private
class pgprobackup::repo (
  Optional[String] $baseurl = undef,
  Optional[String] $version = undef,
  Boolean          $src     = false,
) {
  case $facts['os']['family'] {
    'RedHat', 'Linux': {
      contain pgprobackup::repo::yum
    }

    'Debian': {
      contain pgprobackup::repo::apt
    }

    default: {
      fail("Unsupported managed repository for osfamily: ${facts['os']['family']}, operatingsystem: ${facts['os']['name']}, module ${module_name} currently only supports managing repos for osfamily RedHat and Debian")
    }
  }
}
