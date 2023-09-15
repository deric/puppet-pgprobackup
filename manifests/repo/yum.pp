# @api private
class pgprobackup::repo::yum inherits pgprobackup::repo {
  $_flavor = downcase($facts['os']['name'])
  $default_baseurl = "https://repo.postgrespro.ru/pg_probackup/keys/pg_probackup-repo-${_flavor}.noarch.rpm"

  $_baseurl = pick($pgprobackup::repo::baseurl, $default_baseurl)

  yumrepo { 'pgprobackup':
    descr   => "pg_probackup \$releasever - \$basearch",
    baseurl => $_baseurl,
    enabled => 1,
  }

  Yumrepo['pgprobackup'] -> Package<|tag == 'pgprobackup'|>
}
