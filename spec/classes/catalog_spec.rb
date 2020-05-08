# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup::catalog' do
  os, os_facts = on_supported_os.first
  context "when running with default parameters" do
    let(:facts) { os_facts }

    it { is_expected.to compile }
    it { is_expected.to contain_class('pgprobackup::install') }

    it { is_expected.to contain_user('pgbackup') }

    it { is_expected.to contain_file('/var/lib/pgbackup').with({
      ensure: 'directory',
      owner: 'pgbackup',
      group: 'pgbackup',
      mode: '0750',
    }) }

    it { is_expected.to contain_file('/var/lib/pgbackup/backups').with({
      ensure: 'directory',
      owner: 'pgbackup',
      group: 'pgbackup',
      mode: '0750',
    }) }

    it { is_expected.to contain_file('/var/lib/pgbackup/wal').with({
      ensure: 'directory',
      owner: 'pgbackup',
      group: 'pgbackup',
      mode: '0750',
    }) }

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
