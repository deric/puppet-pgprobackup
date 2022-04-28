# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup::instance' do
  _, os_facts = on_supported_os.first

  let(:pre_condition) { 'include postgresql::server' }

  context 'with default parameters' do
    let(:facts) do
      os_facts.merge(
        pgprobackup_instance_key: 'ssh-rsa AAABBBCCC',
        fqdn: 'psql.localhost',
        manage_ssh_keys: true,
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
          user: 'pgbackup',
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

    context 'with enabled FULL backup' do
      let(:params) do
        {
          backups: {
            common: {
              FULL: {},
            }
          },
          version: '12',
        }
      end

      it {
        expect(exported_resources).to contain_exec('pgprobackup_add_instance_psql.localhost-common').with(
          tag: 'pgprobackup_add_instance-common',
          command: 'pg_probackup-12 add-instance -B /var/lib/pgbackup --instance foo --remote-host=psql.localhost --remote-user=postgres --remote-port=22 -D /var/lib/postgresql/12/main',
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
        }
      end

      cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
      ' -B /var/lib/pgbackup --instance foo -b DELTA --stream'\
      ' --remote-host=psql.localhost --remote-user=postgres'\
      ' -U backup -d backup --log-filename=foo.log'\
      ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'

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
          version: '12',
          retention_redundancy: 2,
          retention_window: 7,
        }
      end

      cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
      ' -B /var/lib/pgbackup --instance foo -b DELTA --stream'\
      ' --remote-host=psql.localhost --remote-user=postgres'\
      ' -U backup -d backup --log-filename=foo.log'\
      ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
      ' --retention-redundancy=2 --retention-window=7 --delete-expired'

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
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --threads=4'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --temp-slot'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' -S pg_probackup'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --no-validate'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --compress-algorithm=zlib --compress-level=2'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --archive-timeout=600'

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
            user: 'pgbackup',
            type: 'ssh-rsa',
            key: 'AAABBBCCC',
            tag: ['pgprobackup-b01', 'pgprobackup-b02'],
          )
      }

      it 'has DELTA backup on b01' do
        backup = 'DELTA'
        cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --archive-timeout=600'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --archive-timeout=600'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --archive-timeout=600'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --archive-timeout=600'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --threads=4 --compress-algorithm=zlib --compress-level=3 --archive-timeout=600'

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
        " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
        ' --remote-host=psql.localhost --remote-user=postgres'\
        ' -U backup -d backup --log-filename=foo.log'\
        ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
        ' --retention-redundancy=2 --retention-window=7 --delete-expired --archive-timeout=600'

        expect(exported_resources).to contain_cron("pgprobackup_#{backup}_psql.localhost-b02")
          .with(
            command: cmd,
            user: 'pgbackup',
            hour: 4,
          )
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
  end
end
