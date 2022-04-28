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
        manage_ssh_keys: true
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
        is_expected.to contain_package('pg-probackup-12').with(
          ensure: 'present',
        )
      }
    when 'RedHat'
      it {
        is_expected.to contain_package('pg_probackup-12').with(
          ensure: 'present',
        )
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
        expect(exported_resources).to contain_cron('pgprobackup_full_psql.localhost-common')
          .with(
            user: 'pgbackup',
            monthday: '*',
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
                hour: '1',
                minute: '13',
              },
            },
          },
          version: '12',
        }
      end

      it {
        expect(exported_resources).to contain_cron('pgprobackup_full_psql.localhost-common')
          .with(
            user: 'pgbackup',
            monthday: '*',
            weekday: '*',
            hour: '1',
            minute: '13',
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
        expect(exported_resources).to contain_cron('pgprobackup_delta_psql.localhost-common')
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
            DELTA: {},
          },
          version: '12',
          retention_redundancy: 2,
          retention_window: 7,
          host_groups: ['common'],
        }
      end

      cmd = '[ -x /usr/bin/pg_probackup-12 ] && /usr/bin/pg_probackup-12 backup'\
      ' -B /var/lib/pgbackup --instance foo -b DELTA --stream'\
      ' --remote-host=psql.localhost --remote-user=postgres'\
      ' -U backup -d backup --log-filename=foo.log'\
      ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
      ' --retention-redundancy=2 --retention-window=7 --delete-expired'

      it {
        expect(exported_resources).to contain_cron('pgprobackup_delta_psql.localhost-common')
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
            DELTA: {},
            FULL: {},
          },
          version: '12',
          retention_redundancy: 2,
          retention_window: 7,
          delete_expired: false,
          merge_expired: true,
          host_groups: ['common'],
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
          expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-common")
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
            DELTA: {},
            FULL: {},
          },
          version: '12',
          threads: 4,
          host_groups: ['common'],
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
          expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-common")
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
            DELTA: {},
            FULL: {},
          },
          version: '12',
          temp_slot: true,
          host_groups: ['common'],
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
          expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-common")
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
            DELTA: {},
            FULL: {},
          },
          version: '12',
          slot: 'pg_probackup',
          host_groups: ['common'],
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
          expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-common")
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
            DELTA: {},
            FULL: {},
          },
          version: '12',
          validate: false,
          host_groups: ['common'],
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
          expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-common")
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
            DELTA: {},
            FULL: {},
          },
          version: '12',
          compress_algorithm: 'zlib',
          compress_level: 2,
          host_groups: ['common'],
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
          expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-common")
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
            DELTA: {},
            FULL: {},
          },
          version: '13',
          archive_timeout: 600,
          host_groups: ['common'],
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
          expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-common")
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
      backup_catalogs = [ 'b01', 'b02' ]
      let(:params) do
        {
          backups: {
            DELTA: {},
            FULL: {},
          },
          version: '13',
          archive_timeout: 600,
          host_groups: backup_catalogs,
        }
      end


      it {
        expect(exported_resources).to contain_ssh_authorized_key('postgres-psql.localhost')
          .with(
            user: 'pgbackup',
            type: 'ssh-rsa',
            key: 'AAABBBCCC',
            tag: ['pgprobackup-b01','pgprobackup-b02']
          )
      }

      backup_catalogs.each do |catalog|
        ['DELTA', 'FULL'].each do |backup|
          cmd = '[ -x /usr/bin/pg_probackup-13 ] && /usr/bin/pg_probackup-13 backup'\
          " -B /var/lib/pgbackup --instance foo -b #{backup} --stream"\
          ' --remote-host=psql.localhost --remote-user=postgres'\
          ' -U backup -d backup --log-filename=foo.log'\
          ' --log-level-file=info --log-directory=/var/lib/pgbackup/log'\
          ' --archive-timeout=600'

          it {
            expect(exported_resources).to contain_cron("pgprobackup_#{backup.downcase}_psql.localhost-#{catalog}")
              .with(
                command: cmd,
                user: 'pgbackup',
                hour: '4',
                minute: '0',
              )
          }
        end
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
