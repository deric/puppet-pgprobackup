# @api private
# A cron job is exported from a database instance, but could be executed elsewhere.
# Typically on a catalog (backup) server.
define pgprobackup::cron_backup(
  String                   $host_group,
  Pgprobackup::Backup_type $backup_type,
  String                   $server_address,
  String                   $db_name,
  String                   $db_user,
  String                   $backup_user,
  Optional[Integer]        $retention_redundancy = undef,
  Optional[Integer]        $retention_window     = undef,
  Boolean                  $delete_expired       = true,
  Boolean                  $merge_expired        = false,
  Optional[Integer]        $threads              = undef,
  Boolean                  $temp_slot            = false,
  Optional[String]         $slot                 = undef,
  Boolean                  $validate             = true,
  Optional[String]         $compress_algorithm   = undef,
  Integer                  $compress_level       = 1,
  Optional[Integer]        $archive_timeout      = undef,
  Optional[Cron::Hour]     $hour                 = 4,
  Optional[Cron::Minute]   $minute               = 0,
  Optional[Cron::Month]    $month                = '*',
  Optional[Cron::Weekday]  $weekday              = '*',
  Optional[Integer]        $monthday             = undef,
  ){

    $binary = "[ -x /usr/bin/pg_probackup-${version} ] && /usr/bin/pg_probackup-${version}"
    $backup_cmd = "backup -B ${backup_dir}"

    if $archive_wal {
      $stream = ''
    } else {
      # with disabled WAL archiving, stream backup is needed
      $stream = '--stream '
    }

    if $retention_redundancy {
      $_retention_redundancy = " --retention-redundancy=${retention_redundancy}"
    } else {
      $_retention_redundancy = ''
    }

    if $retention_window {
      $_retention_window = " --retention-window=${retention_window}"
    } else {
      $_retention_window = ''
    }

    if $retention_redundancy or $retention_window {
      if $delete_expired {
        $_dexpired = ' --delete-expired'
      } else {
        $_dexpired = ''
      }
      if $merge_expired {
        $_mexpired = ' --merge-expired'
      } else {
        $_mexpired = ''
      }
      $expired = "${_dexpired}${_mexpired}"
    } else {
      $expired = ''
    }

    if $threads {
      $_threads = " --threads=${threads}"
    } else {
      $_threads = ''
    }

    # replication slots
    if $temp_slot {
      $_temp_slot = ' --temp-slot'
    } else {
      $_temp_slot = ''
    }

    if $slot {
      $_slot = " -S ${slot}"
    } else {
      $_slot = ''
    }

    if $validate {
      $_validate = ''
    } else {
      $_validate = ' --no-validate'
    }

    $retention = "${_retention_redundancy}${_retention_window}${expired}"

    if $compress_algorithm {
      $_compress =" --compress-algorithm=${compress_algorithm} --compress-level=${compress_level}"
    } else {
      $_compress =''
    }

    if $archive_timeout {
      $_timeout = " --archive-timeout=${archive_timeout}"
    } else {
      $_timeout = ''
    }

    $logging = "--log-filename=${_log_file} --log-level-file=${log_level} --log-directory=${log_dir}"

    @@cron { "pgprobackup_delta_${server_address}-${host_group}":
      command  => @("CMD"/L),
      ${binary} ${backup_cmd} --instance ${id} -b $backup_type ${stream}--remote-host=${server_address}\
       --remote-user=postgres -U ${db_user} -d ${db_name}\
       ${logging}${retention}${_threads}${_temp_slot}${_slot}${_validate}${_compress}${_timeout}
      | -CMD
      user     => $backup_user,
      weekday  => $weekday,
      hour     => $hour,
      minute   => $minute,
      month    => $month,
      monthday => $monthday,
      tag      => "pgprobackup-${host_group}",
    }

}