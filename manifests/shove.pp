class captainshove::shove (
  $rabbit_host,
  $rabbit_user,
  $rabbit_pass,
  $rabbit_vhost,
  $project_path,
  $rabbit_port=5672,
  $settings_file='/etc/shove/settings.py'
){
  # Until we have a working mirror
  exec { 'install-shove':
      command => "dpkg -i /etc/mozpuppet/modules/captainshove/shove_0.1.4-2_all.deb;apt-get install -yf",
      path    => "/usr/bin",
  }

  class { 'supervisord':}

  supervisord::program { 'shove':
    command     => 'shove',
    priority    => '100',
    environment => {
      'SHOVE_SETTINGS_FILE' => $settings_file,
      'PYTHONPATH'          => '/usr/lib/python2.7/site-packages/:/usr/lib/python2.7/dist-packages/'
    }
  }

  file {[
    '/etc/',
    '/etc/shove',
  ]:
    ensure => "directory",
  }

  file { 'settings':
    content  => template("captainshove/shove-settings.py.erb"),
    ensure   => file,
    path     => $settings_file,
    mode     => 644
  }
}
