class captainshove::shove (
  $install_root,
  $rabbit_host,
  $rabbit_user,
  $rabbit_pass,
  $rabbit_port=5672,
  $debug=false,
  $dev=false,
  $screen_startup=false,
  $screen_startup_user='root',
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
  if $screen_startup {
    package {
      'screen':
        ensure  => 'latest'
    }

    captainshove::command_snippet {'rc.local':
      file_path => '/etc/rc.local',
      command => "sudo -u $screen_startup_user screen -d -m shove",
      cwd     => $install_root,
    }
  }
}
