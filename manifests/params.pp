# == Class: mailman::params
#
# This class is used to setup reasonable defaults for the essential parameters
# of a Mailman configuration.
#
# Unfortunately, Puppet manifests make it impossible to define parameters that
# have default values which derive from other parameters to the same class.
# The best workaround is to extract this logic into a "params" class and make
# other classes inherit from this one to be sure that all of these variables
# are realized. To have parameter defaults derive from other parameters more
# than one layer deep, you need to use multiple layers of inheritance. I try
# to keep it simple here, and only use one layer.
#
# To make things even more complicated, some distributions (especially RedHat)
# have changed defaults and added new variables toward the goal of being
# FHS compliant. http://wiki.list.org/pages/viewpage.action?pageId=8486957
#
# === Examples
#
# include mailman::params
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::params {
  $mm_package = 'mailman'
  $mm_service = 'mailman'
  # ssl params
  $ssl_use = false
  $ssl_cert = ''
  $ssl_key = ''
  $ssl_ca = ''
  case $::osfamily {
    'RedHat': {
      $mm_username   = 'mailman'
      $mm_groupname  = 'mailman'
      $smtp_hostname = $::fqdn
      $prefix        = '/usr/lib/mailman'
      $exec_prefix   = $prefix
      $var_prefix    = '/var/lib/mailman'

      $list_data_dir = "${var_prefix}/lists"
      $log_dir       = '/var/log/mailman'
      $lock_dir      = '/var/lock/mailman'
      $config_dir    = '/etc/mailman' # Unique to RedHat packages
      $data_dir      = "${var_prefix}/data"
      $pid_dir       = '/var/run/mailman' # Unique to RedHat packages
      $spam_dir      = "${var_prefix}/spam"
      $wrapper_dir   = "${exec_prefix}/mail"
      $bin_dir       = "${prefix}/bin"
      $scripts_dir   = "${prefix}/scripts"
      if ($::operatingsystem=='Fedora') and ($::operatingsystemmajrelease==19){
        $template_dir  = '/etc/mailman/templates'
      } else {
        $template_dir  = "${prefix}/templates"
      }
      $messages_dir  = "${prefix}/messages"
      # archive_dir is not a real Mailman param, it's just useful in this module
      $archive_dir   = "${var_prefix}/archives"
      $queue_dir     = '/var/spool/mailman'

      # Other useful files
      $pid_file      = "${pid_dir}/master-qrunner.pid"
    }
    'Debian': {
      $mm_username   = 'list'
      $mm_groupname  = 'list'
      # Mailman requires two more DNS labels but Debian systems
      # only use single label "localhost" name.
      $smtp_hostname = "mail.${::hostname}"
      $prefix        = '/usr/lib/mailman'
      $exec_prefix   = $prefix
      $var_prefix    = '/var/lib/mailman'
      $cgi_dir      = '/usr/lib/cgi-bin/mailman' # unique to debian, tested on stretch
      $icons_dir     = '/usr/share/images/mailman' #tested on debian 9 (stretch)
      $list_data_dir = "${var_prefix}/lists"
      $log_dir       = '/var/log/mailman'
      $lock_dir      = '/var/lock/mailman'
      #$config_dir    = '/etc/mailman'
      $data_dir      = "${var_prefix}/data"
      $pid_dir       = '/var/run/mailman'
      $spam_dir      = "${var_prefix}/spam"
      $wrapper_dir   = "${exec_prefix}/mail"
      $bin_dir       = "${prefix}/bin"
      $scripts_dir   = "${prefix}/scripts"
      $template_dir  = '/etc/mailman' # unique to Debian
      $messages_dir  = "${var_prefix}/messages"
      # archive_dir is not a real Mailman param, it's just useful in this module
      $archive_dir   = "${var_prefix}/archives"
      $queue_dir     = '/var/spool/mailman'
      # Other useful files
      $pid_file      = "${pid_dir}/master-qrunner.pid"

    }
    default: {
      fail("Mailman module is not supported on ${::osfamily}.")
    }
  }
}
