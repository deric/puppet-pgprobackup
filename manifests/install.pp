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

  if $pgprobackup::debug_symbols {
    $_packages = [$_package_name, "${_package_name}-${pgprobackup::debug_suffix}"]
  } else {
    $_packages = [$_package_name]
  }

  ensure_packages($_packages, {
    ensure  => $_package_ensure,
    tag     => 'pgprobackup',
  })

}
