# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup::instance' do
  _, os_facts = on_supported_os.first

  let(:pre_condition) { 'include postgresql::server' }

  context 'with default parameters' do
    let(:facts) do
      os_facts.merge(
        pgprobackup_instance_key: 'ssh-rsa AAABBBCCC',
        manage_ssh_keys: true,
        ssh: {
          ecdsa: {
            key: 'AAAAE2VjZHNhLXNoYTBtbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHSTDlBLg+FouBL5gEmO1PYmVNbguoZ5ECdIG/Acwt9SylhSAqZSlKKFojY3XwcTvokz/zfeVPesnNnBVgFWmXU=',
          }
        },
      )
    end

    let(:params) do
      {
        version: '12',
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_class('pgprobackup::install') }
    it { is_expected.to contain_class('pgprobackup::repo') }

    it {
      expect(exported_resources).to contain_ssh_authorized_key('postgres-psql.localhost')
        .with(
          user: 'postgres',
          type: 'ssh-rsa',
          key: 'AAABBBCCC',
          tag: ['pgprobackup-common'],
        )
    }

    case os_facts[:os]['family']
    when 'Debian'
      it {
        is_expected.to contain_package('pg-probackup-12').with_ensure(%r{present|installed})
      }
    when 'RedHat'
      it {
        is_expected.to contain_package('pg_probackup-12').with_ensure(%r{present|installed})
      }
    end

    it { is_expected.to contain_postgresql__server__grant('current_setting-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_start_backup-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_stop_backup-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_catalog_usage_to_backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_control_checkpoint-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_is_in_recovery-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_last_wal_replay_lsn-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_create_restore_point-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('pg_switch_wal-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('set_config-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('txid_current-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('txid_current_snapshot-to-backup') }
    it { is_expected.to contain_postgresql__server__grant('txid_snapshot_xmax-to-backup') }

    context 'with enabled FULL backup' do
      let(:params) do
        {
          backups: {
            common: {
              FULL: {},
            }
          },
          cluster: 'foo',
          version: '12',
          db_cluster: 'dev',
        }
      end

      it {
        expect(exported_resources).to contain_exec('pgprobackup_add_instance_psql.localhost-common').with(
          tag: 'pgprobackup_add_instance-common',
          command: 'pg_probackup-12 add-instance -B /var/lib/pgbackup --instance foo --remote-host=psql.localhost --remote-user=postgres --remote-port=22 -D /var/lib/postgresql/12/dev',
        )
      }

      it {
        expect(exported_resources).to contain_cron('pgprobackup_FULL_psql.localhost-common')
          .with(
            user: 'pgbackup',
            weekday: '*',
            hour: '4',
            minute: '0',
          )
      }
    end

    context 'with plain text password' do
      let(:params) do
        {
          backups: {
            common: {
              FULL: {},
            },
          },
          version: '13',
          id: 'psql',
          server_port: 5433,
          db_name: 'pg_backup',
          db_user:  'pg_probackup',
          db_password: 'TopSecret!',
        }
      end

      it {
        expect(exported_resources).to contain_file_line('pgprobackup_pgpass_content-psql').with(
          line: 'psql.localhost:5433:pg_backup:pg_probackup:TopSecret!',
        )
      }
    end

    context 'exporting host ssh key' do
      let(:params) do
        {
          version: '13',
          id: 'psql',
          manage_host_keys: true,
          backup_dir: '/backup',
        }
      end

      it {
        expect(exported_resources).to contain_sshkey('postgres-psql.localhost').with(
          ensure: 'present',
          target: '/backup/.ssh/known_hosts',
          key: 'AAAAE2VjZHNhLXNoYTBtbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHSTDlBLg+FouBL5gEmO1PYmVNbguoZ5ECdIG/Acwt9SylhSAqZSlKKFojY3XwcTvokz/zfeVPesnNnBVgFWmXU=',
          tag: ['pgprobackup-common'],
        )
      }
    end

    context 'with encrypted password' do
      let(:params) do
        {
          backups: {
            common: {
              FULL: {},
            },
          },
          version: '13',
          id: 'psql',
          server_port: 5433,
          db_name: 'pg_backup',
          db_user:  'pg_probackup',
          db_password: sensitive('TopSecret!'),
        }
      end

      it {
        expect(exported_resources).to contain_file_line('pgprobackup_pgpass_content-psql').with(
          line: 'psql.localhost:5433:pg_backup:pg_probackup:TopSecret!',
        )
      }
    end

    context 'with customized CRON schedule' do
      let(:params) do
        {
          backups: {
            common: {
              FULL: {
                hour: 1,
                minute: 13,
                monthday: 1,
              },
            },
          },
          version: '12',
        }
      end

      it {
        expect(exported_resources).to contain_cron('pgprobackup_FULL_psql.localhost-common')
          .with(
            user: 'pgbackup',
            weekday: '*',
            hour: '1',
            minute: '13',
            monthday: '1',
          )
      }
    end

    context 'with enabled DELTA backup' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
            },
          },
          version: '12',
          cluster: 'foo',
        }
      end

      cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
      ' -B /var/lib/pgbackup --instance foo -b DELTA --stream'\
      ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
      ' -U backup -d backup'

      it {
        expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: '4',
            minute: '0',
          )
      }
    end

    context 'with retention options' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
            }
          },
          cluster: 'foo',
          version: '12',
          retention_redundancy: 2,
          retention_window: 7,
        }
      end

      cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
      ' -B /var/lib/pgbackup --instance foo -b DELTA --stream'\
      ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
      ' -U backup -d backup --retention-redundancy=2 --retention-window=7'\
      ' --delete-expired'

      it {
        expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: '4',
            minute: '0',
          )
      }
    end

    context 'with custom backup script' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
            }
          },
          cluster: 'foo',
          binary: '/usr/local/backup',
          version: '14',
        }
      end

      cmd = '/usr/local/backup backup'\
      ' -B /var/lib/pgbackup --instance foo -b DELTA --stream'\
      ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
      ' -U backup -d backup'

      it {
        expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: '4',
            minute: '0',
          )
      }
    end

    context 'with retention disabled merge and delete' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            },
          },
          cluster: 'foo',
          version: '12',
          retention_redundancy: 2,
          retention_window: 7,
          delete_expired: false,
          merge_expired: true,
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup'\
        ' --retention-redundancy=2 --retention-window=7 --merge-expired'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'with number of parallel threads' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            }
          },
          version: '12',
          threads: 4,
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --threads=4'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'use temp slot' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            }
          },
          version: '12',
          temp_slot: true,
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --temp-slot'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'with named replication slot' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            }
          },
          version: '12',
          slot: 'pg_probackup',
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup -S pg_probackup'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'with disabled validation' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            }
          },
          version: '12',
          validate: false,
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --no-validate'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'with enabled compression' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            }
          },
          version: '12',
          compress_algorithm: 'zlib',
          compress_level: 2,
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --compress-algorithm=zlib --compress-level=2'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'configured archive-timeout' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            }
          },
          version: '13',
          archive_timeout: 600,
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --archive-timeout=600'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'backup instance to multiple servers' do
      let(:params) do
        {
          backups: {
            'b01': {
              DELTA: {
                hour: 3,
                minute: 14,
                weekday: ['0-2', '4-6'],
              },
              FULL: {
                hour: 6,
                minute: 5,
                weekday: 3,
              },
            },
            'b02': {
              DELTA: {
                weekday: ['0-6']
              },
              FULL: {
                monthday: 1,
              },
            }
          },
          version: '13',
          archive_timeout: 600,
        }
      end

      it {
        expect(exported_resources).to contain_ssh_authorized_key('postgres-psql.localhost')
          .with(
            user: 'postgres',
            type: 'ssh-rsa',
            key: 'AAABBBCCC',
            tag: ['pgprobackup-b01', 'pgprobackup-b02'],
          )
      }

      it 'has DELTA backup on b01' do
        backup = 'DELTA'
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --archive-timeout=600'

        expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-b01")
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: 3,
            minute: 14,
            weekday: ['0-2', '4-6'],
          )
      end

      it 'has FULL backup on b01' do
        backup = 'FULL'
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --archive-timeout=600'

        expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-b01")
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: 6,
            minute: 5,
            weekday: 3,
          )
      end

      it 'has DELTA backup on b02' do
        backup = 'DELTA'
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --archive-timeout=600'

        expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-b02")
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: 4,
            minute: 0,
            weekday: ['0-6'],
          )
      end

      it 'has FULL backup on b02' do
        backup = 'FULL'
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --archive-timeout=600'

        expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-b02")
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: 4,
            minute: 0,
            monthday: 1,
          )
      end
    end

    context 'configured params per backup server' do
      let(:params) do
        {
          backups: {
            b01: {
              DELTA: {
                hour: 5,
                threads: 4,
                compress_algorithm: 'zlib',
                compress_level: 3,
              },
            },
            b02: {
              FULL: {
                retention_redundancy: 2,
                retention_window: 7,
                delete_expired: true,
              },
            }
          },
          version: '13',
          archive_timeout: 600,
        }
      end

      it 'has DELTA backup on b01' do
        backup = 'DELTA'
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --threads=4 --compress-algorithm=zlib --compress-level=3'\
        ' --archive-timeout=600'

        expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-b01")
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: 5,
          )
      end

      it 'has FULL backup on b02' do
        backup = 'FULL'
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --retention-redundancy=2 --retention-window=7'\
        ' --delete-expired --archive-timeout=600'

        expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-b02")
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: 4,
          )
      end
    end

    context 'with cluster grouping' do
      let(:params) do
        {
          backups: {
            common: {
              DELTA: {},
              FULL: {},
            }
          },
          version: '13',
          id: 'psql01a',
          cluster: 'psql01',
        }
      end

      ['DELTA', 'FULL'].each do |backup|
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance psql01 -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup'

        it {
          expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-common")
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'install specific package version' do
      let(:params) do
        {
          version: '12',
          package_ensure: '2.4.2-1.8db55b42aeece064.stretch',
        }
      end

      it { is_expected.to contain_class('pgprobackup') }

      case os_facts[:os]['family']
      when 'Debian'
        it {
          is_expected.to contain_package('pg-probackup-12').with(
            ensure: '2.4.2-1.8db55b42aeece064.stretch',
          )
        }
      when 'RedHat'
        it {
          is_expected.to contain_package('pg_probackup-12').with(
            ensure: '2.4.2-1.8db55b42aeece064.stretch',
          )
        }
      else
        it { is_expected.to compile.and_raise_error(%r{Unsupported managed repository for osfamily}) }
      end
    end

    describe 'logging' do
      context 'with log_dir' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {
                  log_dir: '/var/log/pgbackup',
                },
              }
            },
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-directory=/var/log/pgbackup'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end

      context 'with log_file_level' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {},
              }
            },
            log_level_file: 'error',
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-level-file=error'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end

      context 'with log_console_level' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {
                  log_level_console: 'verbose',
                },
              }
            },
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-level-console=verbose'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end

      context 'with console level' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {
                  log_level_console: 'verbose',
                },
              }
            },
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-level-console=verbose'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end

      context 'with console level and redirect' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {
                  redirect_console: true,
                },
              }
            },
            log_dir: '/var/log/pgbackup',
            log_level_console: 'log',
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-level-console=log --log-directory=/var/log/pgbackup >> /var/log/pgbackup/psql01.log 2>&1'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end

      context 'with redirect and log file' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {
                  redirect_console: true,
                  log_console: 'pgbackup.log',
                  log_dir: '/var/log/pgbackup',
                  log_level_console: 'warning',
                  log_level_file: 'off',
                },
              }
            },
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-level-file=off --log-level-console=warning'\
        ' --log-directory=/var/log/pgbackup >> /var/log/pgbackup/pgbackup.log 2>&1'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end

      context 'with log rotation size' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {
                  log_level_file: 'info',
                  log_rotation_size: '100MB',
                },
              }
            },
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-level-file=info --log-rotation-size=100MB'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end

      context 'with log rotation age' do
        let(:params) do
          {
            backups: {
              common: {
                DELTA: {
                  log_level_file: 'info',
                  log_rotation_age: '1d',
                },
              }
            },
            version: '13',
            id: 'psql01a',
            cluster: 'psql01',
            binary: '/usr/local/backup',
          }
        end

        cmd = '/usr/local/backup backup'\
        ' -B /var/lib/pgbackup --instance psql01 -b DELTA --stream'\
        ' --remote-host=psql.localhost --remote-user=postgres --remote-port=22'\
        ' -U backup -d backup --log-level-file=info --log-rotation-age=1d'

        it {
          expect(exported_resources).to contain_cron('pgprobackup_DELTA_psql.localhost-common')
            .with(
              command: cmd,
              user: 'pgbackup',
              hour: '4',
              minute: '0',
            )
        }
      end
    end

    context 'with grants on postgresql 14' do
      let(:params) do
        {
          version: '14',
          id: 'psql',
          db_name: 'pg_backup',
          db_user:  'pg_probackup',
          manage_grants: true
        }
      end

      it { is_expected.to contain_postgresql__server__grant('current_setting-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_start_backup-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_stop_backup-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_catalog_usage_to_pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_control_checkpoint-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_is_in_recovery-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_last_wal_replay_lsn-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_create_restore_point-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('pg_switch_wal-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('set_config-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('txid_current-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('txid_current_snapshot-to-pg_probackup') }
      it { is_expected.to contain_postgresql__server__grant('txid_snapshot_xmax-to-pg_probackup') }
    end

    context 'with grants on postgresql 15' do
      let(:params) do
        {
          version: '15',
          id: 'psql',
          manage_grants: true
        }
      end

      it { is_expected.to contain_postgresql__server__grant('current_setting-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_backup_start-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_backup_stop-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_catalog_usage_to_backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_control_checkpoint-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_is_in_recovery-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_last_wal_replay_lsn-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_create_restore_point-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('pg_switch_wal-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('set_config-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('txid_current-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('txid_current_snapshot-to-backup') }
      it { is_expected.to contain_postgresql__server__grant('txid_snapshot_xmax-to-backup') }
    end
  end
end
