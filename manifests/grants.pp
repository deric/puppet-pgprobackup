# @summary Manages priviledges required for executing backup
# @api private
# @see https://postgrespro.com/docs/enterprise/15/app-pgprobackup
class pgprobackup::grants (
  String  $db_name,
  String  $db_user,
  Integer $version,
) {
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

  # GRANT EXECUTE ON FUNCTION pg_catalog.set_config(text, text, boolean) TO backup;
  postgresql::server::grant { "set_config-to-${db_user}":
    db               => $db_name,
    role             => $db_user,
    privilege        => 'EXECUTE',
    object_type      => 'FUNCTION',
    object_name      => ['pg_catalog', 'set_config'],
    object_arguments => ['text','text','boolean'],
  }

  # GRANT EXECUTE ON FUNCTION pg_catalog.pg_is_in_recovery() TO backup;
  postgresql::server::grant { "pg_is_in_recovery-to-${db_user}":
    db          => $db_name,
    role        => $db_user,
    privilege   => 'EXECUTE',
    object_type => 'FUNCTION',
    object_name => ['pg_catalog', 'pg_is_in_recovery'],
  }

  if $version < 15 {
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
  } else {
    # Introduced in PostgreSQL 15: https://pgpedia.info/p/pg_backup_start.html
    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_backup_start(text, boolean) TO backup;
    postgresql::server::grant { "pg_backup_start-to-${db_user}":
      db               => $db_name,
      role             => $db_user,
      privilege        => 'EXECUTE',
      object_type      => 'FUNCTION',
      object_name      => ['pg_catalog','pg_backup_start'],
      object_arguments => ['text', 'boolean'],
    }

    # GRANT EXECUTE ON FUNCTION pg_catalog.pg_backup_stop(boolean) TO backup;
    postgresql::server::grant { "pg_backup_stop-to-${db_user}":
      db               => $db_name,
      role             => $db_user,
      privilege        => 'EXECUTE',
      object_type      => 'FUNCTION',
      object_name      => ['pg_catalog','pg_backup_stop'],
      object_arguments => ['boolean'],
    }
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
