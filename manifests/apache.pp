# == Class: mailman::apache
#
# This is a helper class for Apache that provides a bare minimum configuration.
# It is intended to help you get started quickly, but most people will probably
# outgrow this setup and need to configure Apache with a different module.
#
# Apache is an important part of Mailman as it provides for web-based
# moderation, list management, and viewing of list archives.
#
# === Examples
#
# include mailman::apache
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::apache (
  $ssl               = false,
  $ssl_cert              = '/tmp/cert',
  $ssl_key               = '/tmp/key',
  $ssl_ca                = '/tmp/ca',
){
  $prefix             = $mailman::params::prefix
  # have to keep http logs and mailman logs separate because of selinux
  # TODO: create symlinks from mm logdir to http logdir
  $log_dir            = $::apache::params::logroot
  $public_archive_dir = $mailman::public_archive_file_dir
  $server_name        = $mailman::http_hostname
  $document_root      = '/var/www/html/mailman'
  $mailman_cgi_dir    = $mailman::cgi_dir
  $mailman_icons_dir  = $mailman::params::icons_dir
  $custom_log_name    = 'apache_access_log'
  $error_log_name     = 'apache_error_log'
  $custom_log         = "${log_dir}/${custom_log_name}"
  $error_log          = "${log_dir}/${error_log_name}"
  $favicon            = "${document_root}/favicon.ico"

  # we need to work with apache 2.4
  #if versioncmp($::apache::version, '2.4.0') >= 0 {
  #  fail('Apache 2.4 is not supported by this Puppet module.')
  #}

  class { '::apache':
    servername    => $server_name,
    serveradmin   => "mailman@${mailman::smtp_hostname}",
    default_mods  => true,
    default_vhost => false,
    logroot       => '/var/log/httpd',
  }
  apache::listen { '80': }

  # TODO This is parse-order dependent. Can that be avoided?
  $http_username      = $::apache::params::user
  $http_groupname     = $::apache::params::group
  $httpd_service      = $::apache::params::apache_name

  include apache::mod::alias
  $cf1 = "ScriptAlias /mailman ${mailman_cgi_dir}/"
  $cf2 = "RedirectMatch ^/mailman[/]*$ https://${server_name}/mailman/listinfo"
  $cf3 = "RedirectMatch ^/?$ https://${server_name}/mailman/listinfo"
  $cf_all = "${cf0}\n${cf1}\n${cf2}\n${cf3}\n"
  $cf0 = "RedirectMatch ^/pipermail/(.*)$ https://lists2.feds.ca/pipermail/$1"
  if $ssl == true {
    $port = '443' 
  apache::vhost { "${server_name}-ssl":
    docroot         => $document_root,
    docroot_owner   => $http_username,
    docroot_group   => $http_groupname,
    port            => $port,
    ssl             => $ssl,
    ssl_cert        => $ssl_cert,
    ssl_key         => $ssl_key,
    ssl_ca          => $ssl_ca,
    access_log_file => $custom_log_name,
    error_log_file  => $error_log_name,
    logroot         => $log_dir,
    ip_based        => true, # dedicate apache to mailman
    custom_fragment => $cf_all,
    aliases         => [ {
      alias => '/pipermail',
      path  => $public_archive_dir
    }, {
      alias => '/doc/mailman/images',
      path  =>  $mailman_icons_dir
    }, {
      alias => '/images/mailman',
      path  =>  $mailman_icons_dir
    }],
    directories     => [
      {
        path            => $mailman_cgi_dir,
        allow_override  => ['None'],
        options         => ['ExecCGI'],
        order           => 'Allow,Deny',
        allow           => 'from all'
      },
      {
        path            => $mailman_icons_dir,
        allow_override  => ['None'],
        order           => 'Allow,Deny',
        allow           => 'from all'
      },
      {
        path            => $public_archive_dir,
        allow_override  => ['None'],
        options         => ['Indexes', 'MultiViews', 'FollowSymLinks'],
        order           => 'Allow,Deny',
        custom_fragment => 'AddDefaultCharset Off'
      }
    ],
  }
    apache::vhost { "${server_name}-redir":
    docroot         => $document_root,
    docroot_owner   => $http_username,
    docroot_group   => $http_groupname,
    port            => '80',
    custom_fragment => "RedirectMatch ^/pipermail/(.*)$ https://lists2.feds.ca/pipermail/\$1\r\n  RedirectMatch ^(.*)$ https://${server_name}/\r\n"
    }
  }
  else {
    $port = '80'
      apache::vhost {  "${server_name}-80":
    docroot         => $document_root,
    docroot_owner   => $http_username,
    docroot_group   => $http_groupname,
    port            => $port,
    ssl             => $ssl,
    ssl_cert        => $ssl_cert,
    ssl_key         => $ssl_key,
    ssl_ca          => $ssl_ca,
    access_log_file => $custom_log_name,
    error_log_file  => $error_log_name,
    logroot         => $log_dir,
    ip_based        => true, # dedicate apache to mailman
    custom_fragment => $cf_all,
    aliases         => [ {
      alias => '/pipermail',
      path  => $public_archive_dir
    }, {
      alias => '/doc/mailman/images',
      path  =>  $mailman_icons_dir
    }, {
      alias => '/images/mailman',
      path  =>  $mailman_icons_dir
    }],
    directories     => [
      {
        path            => $mailman_cgi_dir,
        allow_override  => ['None'],
        options         => ['ExecCGI'],
        order           => 'Allow,Deny',
        allow           => 'from all'
      },
      {
        path            => $mailman_icons_dir,
        allow_override  => ['None'],
        order           => 'Allow,Deny',
        allow           => 'from all'
      },
      {
        path            => $public_archive_dir,
        allow_override  => ['None'],
        options         => ['Indexes', 'MultiViews', 'FollowSymLinks'],
        order           => 'Allow,Deny',
        custom_fragment => 'AddDefaultCharset Off'
      }
    ],
  }
  }
  

  # Spaceship Operator lets us defer setting group owner until we know it.
  File <| title == $mailman::aliasfile |> {
    group   => $http_groupname,
  }
  File <| title == $mailman::aliasfiledb |> {
    group   => $http_groupname,
  }

  file { [ $custom_log, $error_log ]:
    ensure  => present,
    owner   => $http_username,
    group   => $http_groupname,
    mode    => '0664',
    seltype => 'httpd_log_t',
  }

  # Mailman does include a favicon in the HTML META section, but some silly
  # browsers still look for favicon.ico. Create a blank one to reduce 404's.
  exec { 'ensure_favicon':
    command => "touch ${favicon}",
    path    => '/bin',
    creates => $favicon,
    require => File[$document_root],
  }
}
