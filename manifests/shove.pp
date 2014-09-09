class captainshove::shove (
  $rabbit_host,
  $rabbit_user,
  $rabbit_pass,
  $rabbit_vhost,
  $project_path,
  $rabbit_port=5672,
  $settings_file='/etc/shove/settings.py'
){
  exec { 'initial-shove':
      command => "dpkg -i /etc/puppet/mozpuppet/modules/shove-puppet/shove_0.1.4-2_all.deb;apt-get install -yf",
      path    => "/usr/bin",
  }

  class { 'supervisord':}

  supervisord::program { 'shove':
    command     => 'shove',
    priority    => '100',
    environment => {
      'SHOVE_SETTINGS_FILE' => $settings_file,
    }
  }

  file { 'settings':
    contents => template("shove/shove-settings.py.erb"),
    ensure   => file,
    path     => $settings_file
  }
}
