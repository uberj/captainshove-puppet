class captainshove::screen_startup (
  $rc_path,
  $cwd,
  $user,
  $command
) {
  $screen_command = "sudo -u $user screen -d -m $command"
  exec {"add-to-$rc_path":
    command => "echo '$screen_command' >> $rc_path",
    unless  => "grep '$screen_command' $rc_path",
    path    => "/usr/bin/:/bin/",
  }
}
