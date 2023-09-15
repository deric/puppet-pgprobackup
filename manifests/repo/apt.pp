# @api private
class pgprobackup::repo::apt inherits pgprobackup::repo {
  include apt

  $default_baseurl = 'https://repo.postgrespro.ru/pg_probackup/deb/'

  $_baseurl = pick($pgprobackup::repo::baseurl, $default_baseurl)

  apt::source { 'pgprobackup':
    location => $_baseurl,
    release  => $facts['os']['distro']['codename'],
    repos    => "main-${facts['os']['distro']['codename']}",
    key      => {
      id     => '473F44A5E663EE574CE74E1FA78979F6636D717E',
      source => 'https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG_PROBACKUP',
    },
    include  => {
      src => $pgprobackup::repo::src,
    },
  }
}
