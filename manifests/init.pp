# == Class: mailman
#
# This class sets up a minimal Mailman environment, but does not provide any
# integration with mail transfer agents or web servers. Typically you would
# also want to use mailman::postfix and mailman::apache.
#
# It is assumed that the operating system provides Mailman packages, and that
# the compiled version is >= 2.1.5. The paths used by Mailman became compliant
# with the Filesystem Hierarchy Standard in 2.1.5.
#
# NOTE: Don't bother using the "check_perms" binary on RedHat systems. The
# RedHat packages have intentionally customized permissions for security.
#  https://bugzilla.redhat.com/show_bug.cgi?id=701539
#
# === Parameters
#
# Originally I wanted to use native Python path joins exactly the same
# as is done in Defaults.py. However, it is useful to have all of the
# paths fully resolved in the Puppet manifest so they can be used with
# file resources. Still, I try to track Defaults.py wherever possible.
#
# Caution: If you use Mailman on more than one server, be careful to
# only enable the Mailman service (qrunners) on ONE server.
#
# [*enable_service*]
#   Although it's possible to have a Mailman database shared among multiple
#   hosts, you *must not* enable the qrunners on more than one server at a
#   time. In a single server setup this should be enabled. In a multi-server
#   setup, ensure that only one node has this enabled. This is effectively
#   the same as "service mailman start".
#
# [*site_pw*]
#   Define the master password for Mailman administration. This password will
#   let you create lists, as well as view admin pages and list archives.
#
# [*language*]
#   Default language is English. Mailman supports a variety of languages.
#
# [*mta*]
#   A Mailman MTA module contains code to add and remove entries from aliases
#   files. Using Postfix with Mailman is the most typical choice.
#
# [*smtp_hostname*]
#   In Mailman parlance, this variable is known as "default_email_host".
#   This is the hostname used in email addresses for your domain.
#   Note this CANNOT be a single-label DNS name (eg. "localhost").
#   Mailman insists that the mail domain MUST have 2 or more parts.
#
# [*http_hostname*]
#   This is the hostname used in a web browser to access the frontend.
#   This commonly matches smtp_hostname but that isn't a requirement.
#   A single-label DNS name is permitted here (eg. "localhost").
#
# [*virtual_host_overview*]
#   This is normally set to true, which means that mailing lists will only show
#   up on the frontend if the HTTP hostname matches the list. This tends to
#   confuse people, so I have it turned off by default. Thus all mailing lists
#   will be shown on the frontend regardless of hostname in the HTTP request.
#   This is a deviation from the Mailman default of "true".
#
# [*smtp_max_rcpts*]
#   Maximum number of recipients used in a single message transaction. 500 is
#   the default value. Sometimes reducing this number increases the reliability
#   of message delivery. But larger numbers are theoretically faster. If you
#   have lists with a large number of invalid recipients in a single domain,
#   reducing this number is very likely to help with reliable delivery.
#
# [*list_data_dir, log_dir, lock_dir, data_dir, pid_dir, spam_dir, queue_dir
#   archive_dir,pid_file*]
#   These parameters define where Mailman stores the data it creates.
#   Each of this must be overridden individually.
#
# [*option_hash*]
#   This is a hash of key/value pairs that will be appended to the Mailman
#   configuration file. Use this to define parameters that aren't handled
#   already by this module.
#
# === Examples
#
#  include mailman
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman (
  $enable_service        = false,
  $site_pw               = 'CHANGEME',
  $language              = 'en',
  $mta                   = 'Manual',
  $smtp_hostname         = $mailman::params::smtp_hostname,
  $http_hostname         = $::hostname,
  $virtual_host_overview = false,
  $smtp_max_rcpts        = '500',
  $list_data_dir         = $mailman::params::list_data_dir,
  $log_dir               = $mailman::params::log_dir,
  $lock_dir              = $mailman::params::lock_dir,
  $data_dir              = $mailman::params::data_dir,
  $pid_dir               = $mailman::params::pid_dir,
  $spam_dir              = $mailman::params::spam_dir,
  $queue_dir             = $mailman::params::queue_dir,
  $archive_dir           = $mailman::params::archive_dir,
  $pid_file              = $mailman::params::pid_file,
  $option_hash           = { 'DEFAULT_MAX_NUM_RECIPIENTS' => 20 },
) inherits mailman::params {
  $langs = ['ar','ca','cs','da','de','en','es','et','eu','fi','fr','gl','he',
    'hr','hu','ia','it','ja','ko','lt','nl','no','pl','pt','pt_BR','ro',
    'ru','sk','sl','sr','sv','tr','uk','vi','zh_CN','zh_TW']
  validate_bool($enable_service)
  validate_re($language, $langs)
  validate_re($mta, ['Manual', 'Postfix'])
  validate_re($smtp_hostname, '^[-a-zA-Z0-9]+\.[-a-zA-Z0-9\.]+$')
  validate_re($http_hostname, '^[-a-zA-Z0-9\.]+$')
  validate_bool($virtual_host_overview)
  validate_re($smtp_max_rcpts, '[0-9]*')

  # Don't expose var_prefix as a parameter because no functionality depends on
  # it directly. It's only used to derive other parameters, like data_dir.
  # CAVEAT: On RHEL, rmlist requires var_prefix to match list_data_dir.
  $var_prefix               = $mailman::params::var_prefix
  if ($::osfamily == 'RedHat') and ($list_data_dir != "${var_prefix}/lists") {
    fail('rmlist requires that var_prefix is parent of list_data_dir on RHEL')
  }

  $mm_username              = $mailman::params::mm_username
  $mm_groupname             = $mailman::params::mm_groupname
  $mm_service               = $mailman::params::mm_service
  $mm_package               = $mailman::params::mm_package

  $site_pw_file             = "${data_dir}/adm.pw"
  $creator_pw_file          = "${data_dir}/creator.pw"
  $aliasfile                = "${data_dir}/aliases"
  $aliasfiledb              = "${data_dir}/aliases.db"
  $private_archive_file_dir = "${archive_dir}/private"
  $public_archive_file_dir  = "${archive_dir}/public"
  $mailman_site_list        = 'mailman' # Allows chars are [-+_.=a-z0-9]
  $default_email_host       = $smtp_hostname
  $admin_email              = "${mailman_site_list}@${default_email_host}"
  $site_pw_hash             = sha1($site_pw)

  package { $mm_package:
    ensure  => installed,
  }

  include mailman::config

  # Although running genaliases seems like a helpful idea, there is a known bug
  # in Mailman prior to 2.1.15 that causes genaliases to run very slowly on
  # systems with large numbers of lists. Only enable for new Mailman versions.
  if versioncmp($::mailmanversion, '2.1.15') > 0 {
    exec { 'genaliases':
      command     => 'genaliases',
      path        => $mailman::params::bin_dir,
      refreshonly => true,
      subscribe   => File['mm_cfg'],
    }
  } else {
    warning('Be careful using genaliases on Mailman < 2.1.15')
  }

  file { $queue_dir:
    ensure  => directory,
    owner   => $mm_username,
    group   => $mm_groupname,
    mode    => '2770',
    seltype => 'mailman_data_t',
    require => Package[$mm_package],
  }
  file { $log_dir:
    ensure  => directory,
    owner   => $mm_username,
    group   => $mm_groupname,
    mode    => '2770',
    seltype => 'mailman_log_t',
    require => Package[$mm_package],
  }
  file { $lock_dir:
    ensure  => directory,
    owner   => $mm_username,
    group   => $mm_groupname,
    mode    => '2770',
    seltype => 'mailman_lock_t',
    require => Package[$mm_package],
  }
  file { $var_prefix:
    ensure  => directory,
    owner   => 'root',
    group   => $mm_groupname,
    mode    => '2775',
    seltype => 'mailman_data_t',
    require => Package[$mm_package],
  }
  file { $data_dir:
    ensure  => directory,
    owner   => $mm_username, # required for postalias to run correctly
    group   => $mm_groupname,
    mode    => '2775',
    seltype => 'mailman_data_t',
  }
  file { [$site_pw_file, $creator_pw_file]:
    ensure  => present,
    content => "${site_pw_hash}\n",
    owner   => 'root',
    group   => $mm_groupname,
    mode    => '0644',
    seltype => 'mailman_data_t',
    require => File[$data_dir],
  }
  file { $aliasfile:
    ensure  => present,
    owner   => $mm_username,
    mode    => '0664',
    seltype => 'mailman_data_t',
    require => File[$data_dir],
  }
  file { $aliasfiledb:
    ensure  => present,
    owner   => $mm_username,
    mode    => '0664',
    seltype => 'mailman_data_t',
    require => File[$data_dir],
  }
  file { $list_data_dir:
    ensure  => directory,
    owner   => 'root',
    group   => $mm_groupname,
    mode    => '2775',
    seltype => 'mailman_data_t',
    require => File[$var_prefix],
  }
  file { $archive_dir:
    ensure  => directory,
    owner   => 'root',
    group   => $mm_groupname,
    mode    => '2775',
    seltype => 'mailman_archive_t',
  }
  file { $private_archive_file_dir:
    ensure  => directory,
    owner   => 'root',
    group   => $mm_groupname,
    mode    => '2771',
    seltype => 'mailman_archive_t',
    require => File[$archive_dir],
  }
  file { $public_archive_file_dir:
    ensure  => directory,
    owner   => 'root',
    group   => $mm_groupname,
    mode    => '2775',
    seltype => 'mailman_archive_t',
    require => File[$archive_dir],
  }

  if $::osfamily == 'RedHat' {
    # Put some symlinks in /etc/ to be more like the official RHEL packages
    include 'mailman::etclinks'
  }

  # If the site list doesn't exist already, then it is created and the
  # password is immediately reset.
  exec { 'create_site_list':
    command => "newlist -q '${mailman_site_list}' '${admin_email}' 'CHANGEME'",
    path    => $mailman::params::bin_dir,
    creates => "${list_data_dir}/${mailman_site_list}/config.pck",
    require => [ File[$list_data_dir], File['mm_cfg'] ],
    notify  => Exec['change_site_list_pw'],
  }
  exec { 'change_site_list_pw':
    command     => "change_pw --quiet -l '${mailman_site_list}'",
    path        => $mailman::params::bin_dir,
    refreshonly => true,
  }

  service { $mm_service:
    ensure  => $enable_service,
    enable  => $enable_service,
    require => Exec['create_site_list'],
  }
}
