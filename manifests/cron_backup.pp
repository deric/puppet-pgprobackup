# @api private
# A cron job is exported from a database instance, but could be executed elsewhere.
# Typically on a catalog (backup) server.
define pgprobackup::cron_backup(
  String                          $id,
  String                          $cluster,
  String                          $host_group,
  Pgprobackup::Backup_type        $backup_type,
  String                          $server_address,
  String                          $db_name,
  String                          $db_user,
  String                          $version,
  String                          $backup_user,
  String                          $remote_user,
  Integer                         $remote_port,
  Stdlib::AbsolutePath            $backup_dir,
  Stdlib::AbsolutePath            $log_dir,
  Optional[Pgprobackup::LogLevel] $log_level_file,
  Optional[Pgprobackup::LogLevel] $log_level_console,
  Optional[String]                $log_file,
  Optional[Integer]               $retention_redundancy,
  Optional[Integer]               $retention_window,
  Boolean                         $delete_expired,
  Boolean                         $merge_expired,
  Optional[Integer]               $threads,
  Boolean                         $temp_slot,
  Optional[String]                $slot,
  Boolean                         $validate,
  Optional[String]                $compress_algorithm,
  Integer                         $compress_level,
  Optional[Integer]               $archive_timeout,
  Boolean                         $archive_wal,
  Optional[Pgprobackup::Hour]     $hour = 4,
  Optional[Pgprobackup::Minute]   $minute = 0,
  Optional[Pgprobackup::Month]    $month = '*',
  Optional[Pgprobackup::Weekday]  $weekday = '*',
  Optional[Pgprobackup::Monthday] $monthday = undef,
  Optional[String]                $binary,
  ){
    if $binary {
      $_binary = $binary
    } else {
      $_binary = "[ -x /usr/bin/pg_probackup-${version} ] && /usr/bin/pg_probackup-${version}"
    }
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

    # configure logging to file only when filename is given
    if $log_file {
      $file_logs = "--log-filename=${log_file} --log-level-file=${log_level_file} --log-directory=${log_dir}"
      $logging = ''
    } else {
      # some error messages might not be written to file log
      # thus defaulting to redirecting stdout & stderr
      $file_logs = ''
      $logging = " >> ${log_dir}/${cluster}.log 2>&1"
    }

    @@cron { "pgprobackup_${backup_type}_${server_address}-${host_group}":
      command  => @("CMD"/L),
      ${_binary} ${backup_cmd} --instance ${cluster} -b ${backup_type} ${stream}--remote-host=${server_address}\
       --remote-user=${remote_user} --remote-port=${remote_port} -U ${db_user} -d ${db_name}\
      ${file_logs}${retention}${_threads}${_temp_slot}${_slot}${_validate}${_compress}${_timeout}${logging}
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