# @summary Manages host where backups are being stored
#
# Configures server for storing backups.
#
# @param $backup_dir
#   Directory for storing backups, also home directory for backup user
# @param $user
#   User account used for running backups
# @param $group
#   Primary group of backup user
# @param dir_mode
#   Permission mode for backup storage
# @param manage_ssh_keys
#   Whether ssh directory should be managed
# @param host_group
#   Allows to import only certain servers
#
# @example
#   include pgprobackup::catalog
class pgprobackup::catalog (
  Stdlib::AbsolutePath      $backup_dir = $pgprobackup::backup_dir,
  String                    $user = 'pgbackup',
  String                    $group = 'pgbackup',
  String                    $dir_mode = '0750',
  Enum['present', 'absent'] $user_ensure = 'present',
  Boolean                   $manage_ssh_keys = $pgprobackup::manage_ssh_keys,
  Boolean                   $manage_host_keys = $pgprobackup::manage_host_keys,
  Boolean                   $manage_pgpass = $pgprobackup::manage_pgpass,
  Optional[Integer]         $uid = undef,
  String                    $host_group = $pgprobackup::host_group,
) inherits ::pgprobackup {

  user { $user:
    ensure => $user_ensure,
    uid    => $uid,
    gid    => $group, # a primary group
    home   => $backup_dir,
  }

  file { $backup_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => $dir_mode,
    require => User[$user],
  }

  file { "${backup_dir}/backups":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => $dir_mode,
    require => File[$backup_dir],
  }

  file { "${backup_dir}/wal":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => $dir_mode,
    require => File[$backup_dir],
  }

  if $manage_ssh_keys {
    file { "${backup_dir}/.ssh":
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0700',
      require => File[$backup_dir],
    }

    file { "${backup_dir}/.ssh/known_hosts":
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => '0600',
      require => File["${backup_dir}/.ssh"],
    }

    # Add public ssh keys from DB instances as authorized keys
    Ssh_authorized_key <<| tag == "pgprobackup-${host_group}-instance" |>>
  }

  if $manage_pgpass {
    # create an empty .pgpass file
    file { "${backup_dir}/.pgpass":
      ensure  => 'file',
      owner   => $user,
      group   => $group,
      mode    => '0600',
      require => File[$backup_dir],
    }

    # Fill the .pgpass file
    File_line <<| tag == "pgprobackup-${host_group}" |>>
  }

  if $manage_host_keys {
    # Import db instances host keys
    Sshkey <<| tag == "pgprobackup-${host_group}-instance" |>>

    # Export catalog's host key
    @@sshkey { "pgprobackup-catalog-${::fqdn}":
      ensure       => present,
      host_aliases => [$::hostname, $::fqdn, $::ipaddress],
      key          => $::sshecdsakey,
      type         => $pgprobackup::host_key_type,
      target       => '/var/lib/postgresql/.ssh/known_hosts',
      tag          => "pgprobackup-${host_group}",
    }
  }

}
