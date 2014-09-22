# == Class: splunk
#
# Full description of class splunk here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { splunk:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class splunk (
  $splunkhome   = $splunk::params::splunkhome,
  $local_conf   = $splunk::params::local_conf,
  $version      = $splunk::params::version,
  $release      = $splunk::params::release,
  $splunk_user  = $splunk::params::user,
  $splunk_group = $splunk::params::group
) inherits splunk::params {

  exec { 'update-inputs':
    command     => "/bin/cat ${local_conf}/inputs.d/* > ${local_conf}/inputs.conf; \
chown ${splunk_user}:${splunk_group} ${local_conf}/inputs.conf",
    refreshonly => true,
    subscribe   => File["${local_conf}/inputs.d/000_default"],
    notify      => Service[splunk],
  }

  # splunk::input()
  #
  define input(
    $disabled = 'false',
    $target = '',
    $inputtype = 'monitor',
    $sourcetype = 'auto',
    $index = '',
    $cache = 'true',
    $size = '1',
    $splunkhome,
    $local_conf,
    $options = '',
    $recurse = 'false'
    )
  {

    file { "${local_conf}/inputs.d/${title}":
      owner   => ${splunk_user},
      group   => ${splunk_group},
      mode    => '0440',
      content => template('splunk/input.erb'),
      require => File["${local_conf}/inputs.d"],
      notify  => Exec['update-inputs'],
    }

    if $inputtype == 'monitor' {
      acl::entry { "${title}":
        path     => "${target}",
        group    => ${splunk_group},
        readonly => 'true',
        recurse  => "${recurse}"
      }
    }
  }

  # splunk::index()
  #
  define index(
    $sign ='false',
    $archive = 'false',
    $frozenTime,
    $splunkhome,
    $local_conf
    )
  {
    file { "${local_conf}/indexes.d/${title}":
      owner   => ${splunk_user},
      group   => ${splunk_group},
      mode    => '0440',
      content => template('splunk/index.erb'),
      require => File["${local_conf}/indexes.d"],
      notify  => Exec['update-indexes'],
    }
  }

}
