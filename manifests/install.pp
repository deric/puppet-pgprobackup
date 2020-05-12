# @api private
class pgprobackup::install(
  String                    $version,
  Enum['present', 'absent'] $package_ensure = 'present',
  String                    $package_name = $pgprobackup::package_name,
  Boolean                   $debug_symbols = true,
  ) {

  $_package_name = "${package_name}-${version}"

  if $debug_symbols {
    $_packages = [$_package_name, "${_package_name}-${pgprobackup::debug_suffix}"]
  } else {
    $_packages = [$_package_name]
  }

  ensure_packages($_packages, {
    ensure  => $package_ensure,
    tag     => 'pgprobackup',
  })

}
