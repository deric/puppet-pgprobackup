# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }


      it { is_expected.to contain_class('pgprobackup::install') }

      it { is_expected.to contain_package('pg_probackup-12').with(
        ensure: 'present',
      )}

      context 'disable installing debug symbols' do
        let(:params) do
          {
            debug_symbols: false
          }
        end

        case os_facts[:os]['family']
        when 'Debian'
          it { is_expected.not_to contain_package('pg-probackup-12-dbg').with(
            ensure: 'present',
          )}
        when 'RedHat'
          it { is_expected.not_to contain_package('pg_probackup-12-debuginfo').with(
            ensure: 'present',
          )}
        end
      end
    end
  end
end
