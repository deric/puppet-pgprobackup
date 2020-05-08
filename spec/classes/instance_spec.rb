# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup::instance' do
  os, os_facts = on_supported_os.first

  let(:pre_condition) { 'include postgresql::server' }

  context "with default parameters" do
    let(:facts) { os_facts }

    it { is_expected.to compile }

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
