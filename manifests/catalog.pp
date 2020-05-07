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
#
# @example
#   include pgprobackup::catalog
class pgprobackup::catalog (
  Stdlib::AbsolutePath      $backup_dir = '/var/lib/pgbackup',
  String                    $user = 'pgbackup',
  String                    $group = 'pgbackup',
  String                    $dir_mode = '0750',
  Enum['present', 'absent'] $user_ensure = 'present',
  Boolean                   $manage_ssh_keys = true,
  Optional[Integer]         $uid = undef,
) {
  include ::pgprobackup

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
  }




}
