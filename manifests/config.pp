# == Class: mailman::config
#
# This class has one job: get started building mm_cfg.py for Mailman.
# When using big templates, I like to dedicate an entire class to the purpose
# so that all manifests are clear about which variables are actually used.
#
# === Examples
#
# This is used internally by class 'mailman'. Don't reference it externally.
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::config inherits mailman::params {
  $default_url_host         = $mailman::http_hostname
  $default_email_host       = $mailman::default_email_host
  $default_url_pattern      = 'http://%s/mailman/'
  $mailman_site_list        = $mailman::mailman_site_list
  $language                 = $mailman::language
  $mta                      = $mailman::mta
  $log_dir                  = $mailman::log_dir
  $lock_dir                 = $mailman::lock_dir
  $pid_dir                  = $mailman::pid_dir
  $var_prefix               = $mailman::var_prefix
  $data_dir                 = $mailman::data_dir
  $list_data_dir            = $mailman::list_data_dir
  $config_dir               = $mailman::data_dir # Unique to RHEL
  $site_pw_file             = $mailman::site_pw_file
  $creator_pw_file          = $mailman::creator_pw_file
  $private_archive_file_dir = $mailman::private_archive_file_dir
  $public_archive_file_dir  = $mailman::public_archive_file_dir
  $queue_dir                = $mailman::queue_dir
  $virtual_host_overview    = $mailman::virtual_host_overview
  $smtp_max_rcpts           = $mailman::smtp_max_rcpts
  $option_hash              = $mailman::option_hash
  $prefix                   = $mailman::params::prefix
  $bin_dir                  = $mailman::params::bin_dir
  $scripts_dir              = $mailman::params::scripts_dir
  $template_dir             = $mailman::params::template_dir
  $messages_dir             = $mailman::params::messages_dir
  $wrapper_dir              = $mailman::params::wrapper_dir
  $mm_package               = $mailman::params::mm_package
  $mm_service               = $mailman::params::mm_service
  $mm_username              = $mailman::params::mm_username
  $mm_groupname             = $mailman::params::mm_groupname

  if $::osfamily == 'Debian' {
    $mm_cfg_path = '/etc/mailman/mm_cfg.py'
    file { "${prefix}/Mailman/mm_cfg.py":
        ensure => link,
        target => $mm_cfg_path,
        require => File[$mm_cfg_path],
    }
  }
  else {
    $mm_cfg_path = "${prefix}/Mailman/mm_cfg.py"
  }
  file { 'mm_cfg':
    path    => $mm_cfg_path,
    content => template("${module_name}/mm_cfg.py.erb"),
    owner   => 'root',
    group   => $mm_groupname,
    mode    => '0644',
    require => Package[$mm_package],
    notify  => Service[$mm_service],
  }
}
