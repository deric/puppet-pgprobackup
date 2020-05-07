# @api private
class pgprobackup::repo(
  Optional[String] $baseurl = undef,
  Optional[String] $version = undef,
  Boolean          $src     = false,
) {

  case $facts['os']['family'] {
    'RedHat', 'Linux': {
      class { 'pgprobackup::repo::yum': }
    }

    'Debian': {
      class { 'pgprobackup::repo::apt': }
    }

    default: {
      fail("Unsupported managed repository for osfamily: ${::osfamily}, operatingsystem: ${::operatingsystem}, module ${module_name} currently only supports managing repos for osfamily RedHat and Debian")
    }
  }

}
