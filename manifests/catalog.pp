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
  Stdlib::AbsolutePath      $log_dir = $pgprobackup::log_dir,
  String                    $log_file = $pgprobackup::log_file,
  String                    $log_level = $pgprobackup::log_level,
  String                    $logrotate_template = 'pgprobackup/logrotate.conf.erb',
  String                    $exported_ipaddress = "${::ipaddress}/32",
  String                    $user = $pgprobackup::backup_user,
  String                    $group = $pgprobackup::backup_user,
  String                    $dir_mode = '0750',
  Enum['present', 'absent'] $user_ensure = 'present',
  String                    $user_shell = '/bin/bash',
  Boolean                   $manage_ssh_keys = $pgprobackup::manage_ssh_keys,
  Boolean                   $manage_host_keys = $pgprobackup::manage_host_keys,
  Boolean                   $manage_pgpass = $pgprobackup::manage_pgpass,
  Boolean                   $manage_hba = $pgprobackup::manage_hba,
  Boolean                   $manage_cron = $pgprobackup::manage_cron,
  Optional[Integer]         $uid = undef,
  String                    $host_group = $pgprobackup::host_group,
  Integer                   $hba_entry_order = 50,
  String                    $ssh_key_fact = $::pgprobackup_catalog_key,
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

  file { $log_dir:
    ensure  => directory,
    owner   => $user,
    group   => $group,
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
    # sufficient for full backup with enabled WAL archiving
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

    # needed for streaming backups or full backup with --stream option
    @@postgresql::server::pg_hba_rule { "pgprobackup ${::hostname} replication":
      description => "pgprobackup ${::hostname} replication",
      type        => 'host',
      database    => 'replication',
      user        => $pgprobackup::db_user,
      address     => $exported_ipaddress,
      auth_method => 'md5',
      order       => $hba_entry_order,
      tag         => "pgprobackup-${host_group}",
    }
  }

  # Export (and add as authorized key) ssh key from pgbackup user
  # to all DB instances in host_group. Key is generated/fetch via
  # custom Facter function `pgprobackup_keygen`
  if ($ssh_key_fact != undef and $ssh_key_fact != '') {
    $ssh_key_splitted = split($ssh_key_fact, ' ')
    @@ssh_authorized_key { "pgprobackup-${::fqdn}":
      ensure => present,
      user   => 'postgres',
      type   => $ssh_key_splitted[0],
      key    => $ssh_key_splitted[1],
      tag    => "pgprobackup-${host_group}",
    }
  }

  if $manage_cron {
    # Collect backup jobs to run
    Cron <<| tag == "pgprobackup-${host_group}" |>>
  }

}
