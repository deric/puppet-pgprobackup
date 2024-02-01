# @api private
class pgprobackup::repo::apt (
  String $baseurl = 'https://repo.postgrespro.ru/pg_probackup/deb/',
  String $arch    = 'amd64',
) {
  include apt

  $_keyring = '/usr/share/keyrings/pg_probackup.gpg'
  $_tmp_gpg = '/tmp/pg_probackup.gpg'
  # TODO: Switch to apt::keyring once supported by puppetlabs-apt
  # see: https://github.com/puppetlabs/puppetlabs-apt/pull/1128
  archive { $_tmp_gpg:
    source          => 'https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG-PROBACKUP',
    extract         => true,
    extract_path    => '/usr/share/keyrings',
    extract_command => 'gpg --dearmor < %s > pg_probackup.gpg',
    creates         => $_keyring,
  }

  apt::source { 'pgprobackup':
    location     => $baseurl,
    release      => $facts['os']['distro']['codename'],
    architecture => $arch,
    repos        => "main-${facts['os']['distro']['codename']}",
    include      => {
      src => $pgprobackup::repo::src,
    },
    keyring      => $_keyring,
    require      => Archive[$_tmp_gpg],
  }
}
