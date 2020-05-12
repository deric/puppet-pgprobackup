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
      )
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
            FULL: {},
          },
        }
      end

      it {
        expect(exported_resources).to contain_cron('pgprobackup_full_psql.localhost')
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
            FULL: {
              hour: '1',
              minute: '13',
            },
          },
        }
      end

      it {
        expect(exported_resources).to contain_cron('pgprobackup_full_psql.localhost')
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
            DELTA: {},
          },
        }
      end

      it {
        expect(exported_resources).to contain_cron('pgprobackup_delta_psql.localhost')
          .with(
            user: 'pgbackup',
            hour: '4',
            minute: '0',
          )
      }
    end
  end
end
