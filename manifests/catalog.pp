# @summary Manages host where backups are being stored
#
# Configures server for storing backups.
#
# @param $backup_dir
#   Directory for storing backups, also home directory for backup user
# @param $user
#   Local user account used for running and storing backups in its home dir.
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
  String                    $exported_ipaddress = "${::ipaddress}/32",
  String                    $user = 'pgbackup',
  String                    $group = 'pgbackup',
  String                    $dir_mode = '0750',
  Enum['present', 'absent'] $user_ensure = 'present',
  String                    $user_shell = '/bin/bash',
  Boolean                   $manage_ssh_keys = $pgprobackup::manage_ssh_keys,
  Boolean                   $manage_host_keys = $pgprobackup::manage_host_keys,
  Boolean                   $manage_pgpass = $pgprobackup::manage_pgpass,
  Boolean                   $manage_hba = $pgprobackup::manage_hba,
  Optional[Integer]         $uid = undef,
  String                    $host_group = $pgprobackup::host_group,
  Integer                   $hba_entry_order = 50,
) inherits ::pgprobackup {

  group { $group:
    ensure => $user_ensure,
  }

  user { $user:
    ensure  => $user_ensure,
    uid     => $uid,
    gid     => $group, # a primary group
    home    => $backup_dir,
    shell   => $user_shell,
    require => Group[$group],
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

  if $manage_hba {
    @@postgresql::server::pg_hba_rule { "pgprobackup ${::hostname} access":
      description => "pgprobackup ${::hostname} access",
      type        => 'host',
      database    => $pgprobackup::db_name,
      user        => $pgprobackup::db_user,
      address     => $exported_ipaddress,
      auth_method => 'md5',
      order       => $hba_entry_order,
      tag         => "pgprobackup-${host_group}",
    }
  }

}
