# @api private
class pgprobackup::install(
  Array[String]             $versions = ['12'],
  Enum['present', 'absent'] $package_ensure = 'present',
  String                    $package_name = $pgprobackup::package_name,
  Boolean                   $debug_symbols = true,
  ) {

  $versions.each |String $version| {
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

}
