# @api private
class pgprobackup::grants::psql10 (
  String $db_name,
  String $db_user
  ){

    # GRANT USAGE ON SCHEMA pg_catalog TO backup;
    postgresql::server::grant { "pg_catalog_usage_to_${db_user}":
      db          => $db_name,
      role        => $db_user,
      privilege   => 'USAGE',
      object_type => 'SCHEMA',
      object_name => 'pg_catalog',
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.current_setting(text) TO backup;
    postgresql::server::grant { "current_setting-to-${db_user}":
      db               => $db_name,
      role             => $db_user,
      privilege        => 'EXECUTE',
      object_type      => 'FUNCTION',
      object_name      => ['pg_catalog', 'current_setting'],
      object_arguments => ['text'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_is_in_recovery() TO backup;
    postgresql::server::grant { "pg_is_in_recovery-to-${db_user}":
      db          => $db_name,
      role        => $db_user,
      privilege   => 'EXECUTE',
      object_type => 'FUNCTION',
      object_name => ['pg_catalog', 'pg_is_in_recovery'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_start_backup(text, boolean, boolean) TO backup;
    postgresql::server::grant { "pg_start_backup-to-${db_user}":
      db               => $db_name,
      role             => $db_user,
      privilege        => 'EXECUTE',
      object_type      => 'FUNCTION',
      object_name      => ['pg_catalog','pg_start_backup'],
      object_arguments => ['text', 'boolean', 'boolean'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_stop_backup(boolean, boolean) TO backup;
    postgresql::server::grant { "pg_stop_backup-to-${db_user}":
      db               => $db_name,
      role             => $db_user,
      privilege        => 'EXECUTE',
      object_type      => 'FUNCTION',
      object_name      => ['pg_catalog','pg_stop_backup'],
      object_arguments => ['boolean', 'boolean'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_create_restore_point(text) TO backup;
    postgresql::server::grant { "pg_create_restore_point-to-${db_user}":
      db               => $db_name,
      role             => $db_user,
      privilege        => 'EXECUTE',
      object_type      => 'FUNCTION',
      object_name      => ['pg_catalog','pg_create_restore_point'],
      object_arguments => ['text'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_switch_wal() TO backup;
    postgresql::server::grant { "pg_switch_wal-to-${db_user}":
      db          => $db_name,
      role        => $db_user,
      privilege   => 'EXECUTE',
      object_type => 'FUNCTION',
      object_name => ['pg_catalog','pg_switch_wal'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_last_wal_replay_lsn() TO backup;
    postgresql::server::grant { "pg_last_wal_replay_lsn-to-${db_user}":
      db          => $db_name,
      role        => $db_user,
      privilege   => 'EXECUTE',
      object_type => 'FUNCTION',
      object_name => ['pg_catalog','pg_last_wal_replay_lsn'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.txid_current() TO backup;
    postgresql::server::grant { "txid_current-to-${db_user}":
      db          => $db_name,
      role        => $db_user,
      privilege   => 'EXECUTE',
      object_type => 'FUNCTION',
      object_name => ['pg_catalog','txid_current'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.txid_current_snapshot() TO backup;
    postgresql::server::grant { "txid_current_snapshot-to-${db_user}":
      db          => $db_name,
      role        => $db_user,
      privilege   => 'EXECUTE',
      object_type => 'FUNCTION',
      object_name => ['pg_catalog','txid_current_snapshot'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.txid_snapshot_xmax(txid_snapshot) TO backup;
    postgresql::server::grant { "txid_snapshot_xmax-to-${db_user}":
      db               => $db_name,
      role             => $db_user,
      privilege        => 'EXECUTE',
      object_type      => 'FUNCTION',
      object_name      => ['pg_catalog','txid_snapshot_xmax'],
      object_arguments => ['txid_snapshot'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_control_checkpoint() TO backup;
    postgresql::server::grant { "pg_control_checkpoint-to-${db_user}":
      db          => $db_name,
      role        => $db_user,
      privilege   => 'EXECUTE',
      object_type => 'FUNCTION',
      object_name => ['pg_catalog','pg_control_checkpoint'],
    }

}