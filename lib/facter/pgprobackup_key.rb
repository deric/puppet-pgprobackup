# frozen_string_literal: true

require 'etc'

# Generate ssh keys if missing and return public ssh key
def pgprobackup_keygen(user)
  Etc.passwd do |entry|
    if entry.name == user
      return File.read("#{entry.dir}/.ssh/id_rsa.pub").chomp if File.exist? "#{entry.dir}/.ssh/id_rsa.pub"

      Facter::Util::Resolution.exec("su - #{entry.name} -c \"ssh-keygen -t rsa -b 4096 -P '' -q -f #{entry.dir}/.ssh/id_rsa\"")
      return File.read("#{entry.dir}/.ssh/id_rsa.pub").chomp if File.exist? "#{entry.dir}/.ssh/id_rsa.pub"
    end
  end
  ''
end

Facter.add('pgprobackup_catalog_key') do
  confine kernel: 'Linux'
  setcode do
    pgprobackup_keygen('pgbackup')
  end
end

Facter.add('pgprobackup_instance_key') do
  confine kernel: 'Linux'
  setcode do
    barman_safe_keygen_and_return('postgres')
  end
end
