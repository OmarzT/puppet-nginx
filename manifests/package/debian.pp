# Class: nginx::package::debian
#
# This module manages NGINX package installation on debian based systems
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::package::debian(
    $manage_repo    = true,
    $package_name   = 'nginx',
    $package_source = 'nginx',
    $package_ensure = 'present'
  ) {

  $distro = downcase($::operatingsystem)

  package { 'nginx':
    ensure => $package_ensure,
    name   => $package_name,
  }

  if $manage_repo {
    include '::apt'
    Exec['apt_update'] -> Package['nginx']

    case $package_source {
      'nginx', 'nginx-stable': {
        apt::source { 'nginx':
          location => "http://nginx.org/packages/${distro}",
          repos    => 'nginx',
          key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
        }
      }
      'nginx-mainline': {
        apt::source { 'nginx':
          location => "http://nginx.org/packages/mainline/${distro}",
          repos    => 'nginx',
          key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
        }
      }
      'passenger': {
        apt::source { 'nginx':
          location => 'https://oss-binaries.phusionpassenger.com/apt/passenger',
          repos    => 'main',
          key      => '16378A33A6EF16762922526E561F9B9CAC40B2F7',
        }

        package { ['apt-transport-https', 'ca-certificates']:
          ensure => 'present',
          before => Apt::Source['nginx'],
        }

        package { 'passenger':
          ensure  => 'present',
          require => Exec['apt_update'],
        }

        if $package_name != 'nginx-extras' {
          warning('You must set $package_name to "nginx-extras" to enable Passenger')
        }
      }
      'nginx-plus': {
        apt::source { 'nginx-plus':
          location => 'https://plus-pkgs.nginx.com/${distro}',
          repos    => 'nginx-plus',
          options => 'http-proxy="http://proxyuser:proxypass@example.org:3128"',
        }
        apt::conf { 'verifypeer':
          priority => 99,
          content  => 'Acquire::https::plus-pkgs.nginx.com::Verify- "true";',
          before => Apt::Source['nginx-plus'],
        }
        apt::conf { 'verifyhost':
          priority => 99,
          content  => 'Acquire::https::plus-pkgs.nginx.com::Verify- "true";',
          before => Apt::Source['nginx-plus'],
        }
        apt::conf { 'cainfo':
          priority => 99,
          content  => 'Acquire::https::plus-pkgs.nginx.com::CaInfo "/etc/ssl/nginx/CA.crt";',
          before => Apt::Source['nginx-plus'],
        }
        apt::conf { 'sslcert':
          priority => 99,
          content  => 'Acquire::https::plus-pkgs.nginx.com::SslCert  "/etc/ssl/nginx/nginx-repo.crt";',
          before => Apt::Source['nginx-plus'],
        }
        apt::conf { 'sslkey':
          priority => 99,
          content  => 'Acquire::https::plus-pkgs.nginx.com::SslKey "/etc/ssl/nginx/nginx-repo.key";',
          before => Apt::Source['nginx-plus'],
        }
        package { ['apt-transport-https', 'ca-certificates', 'libgnutls26', 'libcurl3-gnutls']:
          ensure => 'present',
          before => Apt::Source['nginx-plus'],
        }
      }
      default: {
        fail("\$package_source must be 'nginx-stable', 'nginx-mainline' or 'passenger'. It was set to '${package_source}'")
      }
    }
  }
}
