# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup::repo' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      case os_facts[:os]['family']
      when 'Debian'
        it {
          is_expected.to contain_class('pgprobackup::repo::apt')
        }
        it {
          is_expected.to contain_apt__source('pgprobackup').with(
            location: 'https://repo.postgrespro.ru/pg_probackup/deb/',
            release: os_facts[:os]['distro']['codename']
          )
        }
      when 'RedHat'
        it {
          is_expected.to contain_class('pgprobackup::repo::yum')
        }
      end
    end
  end
end
