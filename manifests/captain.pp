class captainshove::captain (
  $install_root,
  $captain_apache_vhost,
  $captain_rabbit_vhost,
  $web_port,
  $rabbit_host,
  $rabbit_user,
  $rabbit_pass,
  $rabbit_port=5672,
  $debug=false,
  $dev=false,
  $git_url_ui='https://github.com/mozilla/captain.git',
  $secret_key='not-that-secret',
  $pip_cache='/tmp/pip_download_cache'
){
  exec {'initial-captain-code-install':
      command => "git clone --recursive $git_url_ui .",
      cwd     => "${install_root}",
      path    => "/usr/bin",
      unless  => "test -f ${install_root}/.git/index";
  }

  file {
    $pip_cache:
      ensure  => directory
  }

  package {
    'python-pip':
      ensure => latest;
    'python-devel':
      ensure => latest;
    'mysql-devel':
      ensure => latest;
    'gcc':
      ensure => latest;
  }

  # XXX did easy_install -U distribute
  # on centos6.5 distribute 0.6.10 is too old
  exec {'update-distribute-hack':
      command => "easy_install -U distribute && touch /var/hack-update-distribute-has-run",
      path    => "/usr/bin:/bin",
      unless  => "test -f /var/hack-update-distribute-has-run";
  }

  # TODO. Use a fucking cache. This takes forever
  exec{"install-captain-requirements":
    cwd       => "$install_root/",
    # TODO, variablize dev.txt
    environment => ["PIP_DOWNLOAD_CACHE=$pip_cache"],
    command   => "pip install -r requirements/dev.txt",
    path      => "/usr/bin",
    timeout => 0,
    require   => [
      Package['python-pip'],
      Package['gcc'],
      Package['python-devel'],
      Package['mysql-devel'],
      Exec['update-distribute-hack'],
      Exec['initial-captain-code-install'],
      File[$pip_cache]
    ]
  }

  file {'captain-local.py':
    path    => "$install_root/captain/settings/local.py",
    content => template("captainshove/captain-local.py.erb"),
    require => Exec['install-captain-requirements']
  }

  exec {'captain-sync-db':
      command => "python manage.py syncdb --noinput",
      cwd     => "${install_root}/",
      path    => "/usr/bin",
      require => Exec['install-captain-requirements']
  }

  exec {'captain-migrate-db':
      command => "python manage.py migrate",
      cwd     => "${install_root}/",
      path    => "/usr/bin",
      require => Exec['captain-sync-db']
  }

  class {'rabbitmq':
    port              => $rabbit_port,
    package_provider => 'yum',
    admin_enable     => true,
    manage_repos     => false,
    environment_variables   => {
      'RABBITMQ_NODENAME'     => $captain_rabbit_vhost,
      'RABBITMQ_SERVICENAME'  => 'RabbitMQ'
    }
  }

  rabbitmq_vhost { "$captain_rabbit_vhost":
    ensure  => present,
    require => Class['rabbitmq'],
  }

  rabbitmq_user { $rabbit_user:
      admin    => false,
      password => $rabbit_pass,
  }

  class {
    'apache':
      default_mods        => true,
      default_confd_files => false;
    'apache::mod::wsgi':
      wsgi_socket_prefix => '/var/run/wsgi';
  }


  apache::vhost { "$captain_apache_vhost":
      port                        => '80',
      docroot                     => "${install_root}/captain",
      wsgi_application_group      => '%{GLOBAL}',
      wsgi_daemon_process         => 'wsgi',
      wsgi_daemon_process_options => { 
        processes    => '2', 
        threads      => '15', 
        display-name => '%{GROUP}',
      },
      wsgi_import_script          => "${install_root}/captain/wsgi.py",
      wsgi_import_script_options  =>
        { process-group => 'wsgi', application-group => '%{GLOBAL}' },
      wsgi_process_group          => 'wsgi',
      wsgi_script_aliases         => { '/' => "${install_root}/captain/wsgi.py" },
  }
}
