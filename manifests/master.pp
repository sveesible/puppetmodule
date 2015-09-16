# Class: puppet::master
#
# This class installs and configures a Puppet master
#
# Parameters:
#  ['user_id']                  - The userid of the puppet user
#  ['group_id']                 - The groupid of the puppet group
#  ['modulepath']               - Module path to be served by the puppet master
#  ['manifest']                 - Manifest path
#  ['external_nodes']           - ENC script path
#  ['node_terminus']            - Node terminus setting, is overridden to 'exec' if external_nodes is set
#  ['hiera_config']             - Hiera config file path
#  ['environments']             - Which environment method (directory or config)
#  ['environmentpath']          - Puppet environment base path (use with environments directory)
#  ['reports']                  - Turn on puppet reports
#  ['storeconfigs']             - Use storedconfigs
#  ['storeconfigs_dbserver']    - Puppetdb server
#  ['storeconfigs_dbport']      - Puppetdb port
#  ['certname']                 - The certname the puppet master should use
#  ['autosign']                 - Auto sign agent certificates default false
#  ['reporturl']                - Url to send reports to, if reporting enabled
#  ['puppet_ssldir']            - Puppet sll directory
#  ['puppet_docroot']           - Doc root to be configured in apache vhost
#  ['puppet_vardir']            - Vardir used by puppet
#  ['puppet_passenger_port']    - Port to configure passenger on default 8140
#  ['puppet_master_package']    - Puppet master package
#  ['puppet_master_service']    - Puppet master service
#  ['version']                  - Version of the puppet master package to install
#  ['apache_serveradmin']       - Apache server admin
#  ['pluginsync']               - Enable plugin sync
#  ['parser']                   - Which parser to use
#  ['puppetdb_startup_timeout'] - The timeout for puppetdb
#  ['dns_alt_names']            - Comma separated list of alternative DNS names
#  ['digest_algorithm']         - The algorithm to use for file digests.
#  ['generate_ssl_certs']       - Generate ssl certs (false to disable)
#  ['strict_variables']         - Makes the parser raise errors when referencing unknown variables
#  ['always_cache_features']    - if false (default), always try to load a feature even if a previous load failed
#  ['serialization_format']     - defaults to undef, otherwise it sets the preferred_serialization_format param (currently only msgpack is supported)
#  ['serialization_package']    - defaults to undef, if provided, we install this package, otherwise we fall back to the gem from 'serialization_format'
#
# Requires:
#
#  - inifile
#  - Class['puppet::params']
#  - Class[puppet::passenger]
#  - Class['puppet::storeconfigs']
#
# Sample Usage:
#
#  $modulepath = [
#    "/etc/puppet/modules/site",
#    "/etc/puppet/modules/dist",
#  ]
#
#  class { "puppet::master":
#    modulepath             => inline_template("<%= modulepath.join(':') %>"),
#    storeconfigs          => 'true',
#  }
#
class puppet::master (
  $user_id                       = undef,
  $group_id                      = undef,
  $modulepath                    = $::puppet::params::modulepath,
  $manifest                      = $::puppet::params::manifest,
  $external_nodes                = undef,
  $node_terminus                 = undef,
  $hiera_config                  = $::puppet::params::hiera_config,
  $environmentpath               = $::puppet::params::environmentpath,
  $environments                  = $::puppet::params::environments,
  $reports                       = store,
  $storeconfigs                  = false,
  $storeconfigs_dbserver         = $::puppet::params::storeconfigs_dbserver,
  $storeconfigs_dbport           = $::puppet::params::storeconfigs_dbport,
  $certname                      = $::fqdn,
  $autosign                      = false,
  $reporturl                     = undef,
  $puppet_ssldir                 = $::puppet::params::puppet_ssldir,
  $puppet_docroot                = $::puppet::params::puppet_docroot,
  $puppet_vardir                 = $::puppet::params::puppet_vardir,
  $puppet_passenger_port         = $::puppet::params::puppet_passenger_port,
  $puppet_passenger_ssl_protocol = $::puppet::params::puppet_passenger_ssl_protocol,
  $puppet_passenger_ssl_cipher   = $::puppet::params::puppet_passenger_ssl_cipher,
  $puppet_passenger_tempdir      = false,
  $puppet_passenger_cfg_addon    = '',
  $puppet_master_package         = $::puppet::params::puppet_master_package,
  $puppet_master_service         = $::puppet::params::puppet_master_service,
  $version                       = 'present',
  $apache_serveradmin            = $::puppet::params::apache_serveradmin,
  $pluginsync                    = true,
  $parser                        = $::puppet::params::parser,
  $puppetdb_startup_timeout      = '60',
  $puppetdb_strict_validation    = $::puppet::params::puppetdb_strict_validation,
  $dns_alt_names                 = ['puppet'],
  $digest_algorithm              = $::puppet::params::digest_algorithm,
  $generate_ssl_certs            = true,
  $strict_variables              = undef,
  $puppetdb_version              = 'present',
  $always_cache_features         = false,
  $passenger_max_pool_size       = $::processorcount,
  $passenger_high_performance    = on,
  $passenger_max_requests        = 10000,
  $passenger_stat_throttle_rate  = 30,
  $serialization_format          = undef,
  $serialization_package         = undef,
) inherits puppet::params {

  anchor { 'puppet::master::begin': }

  if ! defined(User[$::puppet::params::puppet_user]) {
    user { $::puppet::params::puppet_user:
      ensure => present,
      uid    => $user_id,
      gid    => $::puppet::params::puppet_group,
    }
  }

  if ! defined(Group[$::puppet::params::puppet_group]) {
    group { $::puppet::params::puppet_group:
      ensure => present,
      gid    => $group_id,
    }
  }

  if $::osfamily == 'Debian'
  {
    package { 'puppetmaster-common':
      ensure   => $version,
    }
    package { $puppet_master_package:
      ensure  => $version,
      require => Package[puppetmaster-common],
    }
  }
  else
  {
    package { $puppet_master_package:
      ensure         => $version,
    }
  }

  Anchor['puppet::master::begin'] ->
  class {'puppet::passenger':
    puppet_passenger_port         => $puppet_passenger_port,
    puppet_passenger_ssl_protocol => $puppet_passenger_ssl_protocol,
    puppet_passenger_ssl_cipher   => $puppet_passenger_ssl_cipher,
    puppet_docroot                => $puppet_docroot,
    apache_serveradmin            => $apache_serveradmin,
    puppet_conf                   => $::puppet::params::puppet_conf,
    puppet_ssldir                 => $puppet_ssldir,
    certname                      => $certname,
    conf_dir                      => $::puppet::params::confdir,
    dns_alt_names                 => join($dns_alt_names,','),
    generate_ssl_certs            => $generate_ssl_certs,
    puppet_passenger_tempdir      => $puppet_passenger_tempdir,
    config_addon                  => $puppet_passenger_cfg_addon,
    passenger_max_pool_size       => $passenger_max_pool_size,
    passenger_high_performance    => $passenger_high_performance,
    passenger_max_requests        => $passenger_max_requests,
    passenger_stat_throttle_rate  => $passenger_stat_throttle_rate,

  } ->
  Anchor['puppet::master::end']

  service { $puppet_master_service:
    ensure  => stopped,
    enable  => false,
    require => File[$::puppet::params::puppet_conf],
  }

  if ! defined(File[$::puppet::params::puppet_conf]){
    file { $::puppet::params::puppet_conf:
      ensure  => 'file',
      mode    => '0644',
      require => File[$::puppet::params::confdir],
      owner   => $::puppet::params::puppet_user,
      group   => $::puppet::params::puppet_group,
      notify  => Service['httpd'],
    }
  }
  else {
    File<| title == $::puppet::params::puppet_conf |> {
      notify  => Service['httpd'],
    }
  }

  if ! defined(File[$::puppet::params::confdir]) {
    file { $::puppet::params::confdir:
      ensure  => directory,
      mode    => '0755',
      require => Package[$puppet_master_package],
      owner   => $::puppet::params::puppet_user,
      group   => $::puppet::params::puppet_group,
      notify  => Service['httpd'],
    }
  }
  else {
    File<| title == $::puppet::params::confdir |> {
      notify  +> Service['httpd'],
      require +> Package[$puppet_master_package],
    }
  }

  file { $puppet_vardir:
    ensure  => directory,
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    notify  => Service['httpd'],
    require => Package[$puppet_master_package]
  }

  if $storeconfigs {
    Anchor['puppet::master::begin'] ->
    class { 'puppet::storeconfigs':
      dbserver                   => $storeconfigs_dbserver,
      dbport                     => $storeconfigs_dbport,
      puppet_service             => Service['httpd'],
      puppet_confdir             => $::puppet::params::confdir,
      puppet_conf                => $::puppet::params::puppet_conf,
      puppet_master_package      => $puppet_master_package,
      puppetdb_startup_timeout   => $puppetdb_startup_timeout,
      puppetdb_strict_validation => $puppetdb_strict_validation,
      puppetdb_version           => $puppetdb_version,
    } ->
    Anchor['puppet::master::end']
  }

  Ini_setting {
      path    => $::puppet::params::puppet_conf,
      require => File[$::puppet::params::puppet_conf],
      notify  => Service['httpd'],
      section => 'master',
  }

  case $environments {
    'config': {
      $setting_config='present'
      $setting_directory='absent'
    }
    'directory': {
      $setting_config='absent'
      $setting_directory='present'
    }
    default: { fail("Unknown value for environments ${environments}") }
  }
# DEPRECATED SETTINGS - REMOVING
#  ini_setting {'puppetmastermodulepath':
#    ensure  => $setting_config,
#    setting => 'modulepath',
#    value   => $modulepath,
#  }
#  ini_setting {'puppetmastermanifest':
#    ensure  => $setting_config,
#    setting => 'manifest',
#    value   => $manifest,
#  }
  ini_setting {'puppetmasterenvironmentpath':
    ensure  => $setting_directory,
    setting => 'environmentpath',
    value   => $environmentpath,
    section => 'main',
  }

  if $external_nodes != undef {
    ini_setting {'puppetmasterencconfig':
      ensure  => present,
      setting => 'external_nodes',
      value   => $external_nodes,
    }

    ini_setting {'puppetmasternodeterminus':
      ensure  => present,
      setting => 'node_terminus',
      value   => 'exec'
    }
  }
  elsif $node_terminus != undef {
    ini_setting {'puppetmasternodeterminus':
      ensure  => present,
      setting => 'node_terminus',
      value   => $node_terminus
    }
  }

  ini_setting {'puppetmasterhieraconfig':
    ensure  => present,
    setting => 'hiera_config',
    value   => $hiera_config,
  }

  ini_setting {'puppetmasterautosign':
    ensure  => present,
    setting => 'autosign',
    value   => $autosign,
  }

  ini_setting {'puppetmastercertname':
    ensure  => present,
    setting => 'certname',
    value   => $certname,
  }

  ini_setting {'puppetmasterreports':
    ensure  => present,
    setting => 'reports',
    value   => $reports,
  }

  ini_setting {'puppetmasterpluginsync':
    ensure  => present,
    setting => 'pluginsync',
    value   => $pluginsync,
  }

  ini_setting {'puppetmasterparser':
    ensure  => present,
    setting => 'parser',
    value   => $parser,
  }

  if $reporturl != undef {
    ini_setting {'puppetmasterreport':
      ensure  => present,
      setting => 'reporturl',
      value   => $reporturl,
    }
  }

  ini_setting {'puppetmasterdnsaltnames':
    ensure  => present,
    setting => 'dns_alt_names',
    value   => join($dns_alt_names, ','),
  }

  ini_setting {'puppetmasterdigestalgorithm':
    ensure  => present,
    setting => 'digest_algorithm',
    value   => $digest_algorithm,
  }

  if $strict_variables != undef {
    validate_bool(str2bool($strict_variables))
    ini_setting {'puppetmasterstrictvariables':
      ensure  => present,
      setting => 'strict_variables',
      value   => $strict_variables,
    }
  }
  validate_bool(str2bool($always_cache_features))
  ini_setting { 'puppetmasteralwayscachefeatures':
    ensure  => present,
    setting => 'always_cache_features',
    value   => $always_cache_features,
  }
  if $serialization_format != undef {
    if $serialization_package != undef {
      package { $serialization_package:
        ensure  => latest,
      }
    } else {
      if $serialization_format == 'msgpack' {
        unless defined(Package[$::puppet::params::ruby_dev]) {
          package {$::puppet::params::ruby_dev:
            ensure  => 'latest',
          }
        }
        unless defined(Package['gcc']) {
          package {'gcc':
            ensure  => 'latest',
          }
        }
        unless defined(Package['msgpack']) {
          package {'msgpack':
            ensure   => 'latest',
            provider => 'gem',
            require  => Package[$::puppet::params::ruby_dev, 'gcc'],
          }
        }
      }
    }
    ini_setting {'puppetagentserializationformatmaster':
      setting => 'preferred_serialization_format',
      value   => $serialization_format,
    }
  }
  anchor { 'puppet::master::end': }
}
