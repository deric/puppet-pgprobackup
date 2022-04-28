# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup::catalog' do
  _, os_facts = on_supported_os.first
  context 'when running with default parameters' do
    let(:facts) do
      os_facts.merge(
        pgprobackup_catalog_key: 'ssh-rsa AAABBB',
        fqdn: 'test.localhost',
      )
    end

    it { is_expected.to compile }
    it { is_expected.to contain_class('pgprobackup::repo') }

    it { is_expected.to contain_user('pgbackup') }
    it { is_expected.to contain_group('pgbackup') }

    it {
      expect(exported_resources).to contain_ssh_authorized_key('pgprobackup-test.localhost')
        .with(
          user: 'postgres',
          type: 'ssh-rsa',
          key: 'AAABBB',
        )
    }

    it {
      is_expected.to contain_file('/var/lib/pgbackup')
        .with(ensure: 'directory',
              owner: 'pgbackup',
              group: 'pgbackup',
              mode: '0750')
    }

    it {
      is_expected.to contain_file('/var/lib/pgbackup/backups')
        .with(ensure: 'directory',
              owner: 'pgbackup',
              group: 'pgbackup',
              mode: '0750')
    }

    it {
      is_expected.to contain_file('/var/lib/pgbackup/wal')
        .with(ensure: 'directory',
              owner: 'pgbackup',
              group: 'pgbackup',
              mode: '0750')
    }

    it {
      is_expected.to contain_file('/var/lib/pgbackup/log')
        .with(ensure: 'directory',
              owner: 'pgbackup',
              group: 'pgbackup')
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

    context 'when exact version is given' do
      let(:params) do
        {
          package_ensure: '2.4.2-1.8db55b42aeece064',
        }
      end

      it { is_expected.to contain_class('pgprobackup') }

      case os_facts[:os]['family']
      when 'Debian'
        it {
          is_expected.to contain_package('pg-probackup-12').with(
            ensure: '2.4.2-1.8db55b42aeece064',
          )
        }
      when 'RedHat'
        it {
          is_expected.to contain_package('pg_probackup-12').with(
            ensure: '2.4.2-1.8db55b42aeece064',
          )
        }
      else
        it { is_expected.to compile.and_raise_error(%r{Unsupported managed repository for osfamily}) }
      end
    end
  end
end
