class captainshove::shove (
  $rabbit_host,
  $rabbit_user,
  $rabbit_pass,
  $rabbit_vhost,
  $project_path,
  $project_name,
  $rabbit_port=5672,
  $settings_file='/etc/shove/settings.py'
){
  # Until we have a working mirror
  exec { 'install-shove':
      command => "dpkg -i /etc/mozpuppet/modules/captainshove/shove_0.1.4-2_all.deb;apt-get install -yf",
      path    => "/usr/bin",
  }

  Supervisord::Supervisorctl['restart-shove'] ->
  supervisord::program['shove'] ->
  Class['supervisord'] ->
  Exec['install-shove'] ->
  File['shove-settings'] ->
  File['/etc/shove/']

  class { 'supervisord':}

  supervisord::program { 'shove':
    command     => 'shove',
    priority    => '100',
    autostart   => true,
    environment => {
      'SHOVE_SETTINGS_FILE' => $settings_file,
      'PYTHONPATH'          => '/usr/lib/python2.7/site-packages/:/usr/lib/python2.7/dist-packages/'
    }
  }

  supervisord::supervisorctl { 'restart-shove':
    command => 'restart',
    process => 'shove',
    require => Supervisord::Program['shove']
  }

  file {[
    '/etc/',
    '/etc/shove',
  ]:
    ensure => "directory",
  }
  file { 'shove-settings':
    content  => template("captainshove/shove-settings.py.erb"),
    ensure   => file,
    path     => $settings_file,
    mode     => 644,
  }
}
