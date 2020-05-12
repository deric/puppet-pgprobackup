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
  end
end
