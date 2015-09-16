class puppet::repo::passenger{

 if($::osfamily == 'Debian') {
    apt::source { "passenger_repo":
      location    => "https://oss-binaries.phusionpassenger.com/apt/passenger",
      key         => {
        id     => "561F9B9CAC40B2F7",
        server => "hkp://keyserver.ubuntu.com:80" 
      },
      include_src => false,
    }
 } elsif $::osfamily == 'Redhat' {
     yumrepo {'passenger':
       baseurl =>'https://oss-binaries.phusionpassenger.com/yum/passenger/el/$releasever/$basearch',
       gpgcheck => 0,
       enabled => 1,
       gpgkey => 'https://packagecloud.io/gpg.key',
       sslverify=> 1,
       sslcacert=>'/etc/pki/tls/certs/ca-bundle.crt'
     }
  }
  else {
    fail("Unsupported osfamily ${::osfamily}")
  }
}
