# == Class: mailman::postfix
#
# This is a helper class for Postfix that provides a bare minimum configuration.
# It is intended to help you get started quickly, but most people will probably
# outgrow this setup and need to configure Postfix with a different module.
#
# Postfix is a critical part of Mailman as it enables messages to be sent and
# received.
#
# If you're seeing strange results for myhostname or mydomain, check your
# settings in /etc/resolv.conf, especially on RedHat systems.
#
# === Examples
#
# include mailman::postfix
#
# === Authors
#
# Nic Waller <code@nicwaller.com>
#
# === Copyright
#
# Copyright 2013 Nic Waller, unless otherwise noted.
#
class mailman::postfix (
  $data_directory = '/usr/lib/postfix/sbin'
){

  if $mailman::mta != 'Postfix' {
    fail('Must set MTA=Postfix if using Postfix helper class')
  }

  # TODO FIXME ensure this is not an open relay

  class { '::postfix::server':
    inet_interfaces      => 'all',
    myhostname           => $mailman::smtp_hostname,
    mydomain             => $mailman::smtp_hostname,
    alias_maps           => "hash:${mailman::aliasfile}",
    data_directory       => $data_directory,
    # no other hosts are trusted to relay email through this server
    mynetworks_style     => 'host',
    extra_main_parameters => { shlib_directory => 'no'},

    # reply error 550 if list does not exist
    local_recipient_maps => "hash:${mailman::aliasfile}",
  }

  # Ensure that Postfix is installed before Mailman
  Package['postfix'] -> Package[$mailman::mm_package]

  # TODO: remove this hack once it is fixed upstream
  Package['postfix'] -> File['/etc/postfix/master.cf']
  Package['postfix'] -> File['/etc/postfix/main.cf']
}
