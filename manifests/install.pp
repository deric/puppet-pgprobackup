# @api private
class pgprobackup::install {

  $package_ensure = $pgprobackup::package_ensure
  $_package_name = "${pgprobackup::package_name}-${pgprobackup::version}"

  $_package_ensure = $package_ensure ? {
    true     => 'present',
    false    => 'purged',
    'absent' => 'purged',
    default => $package_ensure,
  }

  $_packages = [$_package_name]

  if $pgprobackup::debug_symbols {
    case $facts['os']['family'] {
      'RedHat', 'Linux': {
        concat($_packages, "${_package_name}-debuginfo")
      }

      'Debian': {
        concat($_packages, "${_package_name}-dbg")
      }

      default: {
        fail("Unsupported managed repository for osfamily: ${::osfamily}, operatingsystem: ${::operatingsystem}, module ${module_name} currently only supports managing repos for osfamily RedHat and Debian")
      }
    }
  }

  ensure_packages($_packages, {
    ensure  => $_package_ensure,
    tag     => 'pgprobackup',
  })

}
