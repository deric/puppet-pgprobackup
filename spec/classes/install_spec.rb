# frozen_string_literal: true

require 'spec_helper'

describe 'pgprobackup::install' do
  let(:pre_condition) { 'include pgprobackup' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          versions: ['12'],
        }
      end

      it { is_expected.to contain_class('pgprobackup') }

      case os_facts[:os]['family']
      when 'Debian'
        it { is_expected.to compile }
        it {
          is_expected.to contain_package('pg-probackup-12').with(
            ensure: 'present',
          )
        }
        it {
          is_expected.to contain_package('pg-probackup-12-dbg').with(
            ensure: 'present',
          )
        }
      when 'RedHat'
        it {
          is_expected.to contain_package('pg_probackup-12').with(
            ensure: 'present',
          )
        }
        it {
          is_expected.to contain_package('pg_probackup-12-debuginfo').with(
            ensure: 'present',
          )
        }
      end

      context 'disable installing debug symbols' do
        let(:params) do
          {
            versions: ['12'],
            debug_symbols: false,
          }
        end

        it { is_expected.to contain_class('pgprobackup') }

        case os_facts[:os]['family']
        when 'Debian'
          it {
            is_expected.to contain_package('pg-probackup-12').with(
              ensure: 'present',
            )
          }
          it {
            is_expected.not_to contain_package('pg-probackup-12-dbg').with(
              ensure: 'present',
            )
          }
        when 'RedHat'
          it {
            is_expected.to contain_package('pg_probackup-12').with(
              ensure: 'present',
            )
          }
          it {
            is_expected.not_to contain_package('pg_probackup-12-debuginfo').with(
              ensure: 'present',
            )
          }
        else
          it { is_expected.to compile.and_raise_error(%r{Unsupported managed repository for osfamily}) }
        end
      end

      context 'when installing specific version' do
        let(:params) do
          {
            versions: ['11'],
          }
        end

        it { is_expected.to contain_class('pgprobackup') }

        case os_facts[:os]['family']
        when 'Debian'
          it {
            is_expected.to contain_package('pg-probackup-11').with(
              ensure: 'present',
            )
          }
          it {
            is_expected.to contain_package('pg-probackup-11-dbg').with(
              ensure: 'present',
            )
          }
        when 'RedHat'
          it {
            is_expected.to contain_package('pg_probackup-11').with(
              ensure: 'present',
            )
          }
          it {
            is_expected.to contain_package('pg_probackup-11-debuginfo').with(
              ensure: 'present',
            )
          }
        else
          it { is_expected.to compile.and_raise_error(%r{Unsupported managed repository for osfamily}) }
        end
      end

      context 'when installing multiple packages' do
        let(:params) do
          {
            versions: ['11', '12'],
            debug_symbols: false,
          }
        end

        it { is_expected.to contain_class('pgprobackup') }

        case os_facts[:os]['family']
        when 'Debian'
          it {
            is_expected.to contain_package('pg-probackup-11').with(
              ensure: 'present',
            )
          }
          it {
            is_expected.to contain_package('pg-probackup-12').with(
              ensure: 'present',
            )
          }
        when 'RedHat'
          it {
            is_expected.to contain_package('pg_probackup-11').with(
              ensure: 'present',
            )
          }
          it {
            is_expected.to contain_package('pg_probackup-12').with(
              ensure: 'present',
            )
          }
        else
          it { is_expected.to compile.and_raise_error(%r{Unsupported managed repository for osfamily}) }
        end
      end
    end
  end
end
