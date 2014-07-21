class captainshove::shove (
  $install_root,
  $rabbit_host,
  $rabbit_user,
  $rabbit_pass,
  $rabbit_port=5672,
  $debug=false,
  $dev=false,
  $git_url_ui="https://github.com/mozilla/shove.git"
){

  exec {'initial-shove-code-install':
      command => "git clone --recursive $git_url_ui",
      cwd     => "${install_root}",
      path    => "/usr/bin",
      unless  => "test -f ${install_root}/shove/.git/index";
  }

  package {
    'python-pip':
      ensure => latest;
  }

  file {'shove-local.py':
    path    => "$install_root/shove/shove/settings.py",
    content => template("captainshove/shove-settings.py.erb"),
    require => Exec['initial-shove-code-install']
  }

  exec{"install-shove":
    cwd       => "$install_root/shove/",
    command   => "python setup.py install",
    path      => "/usr/bin",
    require   => [Package['python-pip'], File['shove-local.py']],
  }
}
