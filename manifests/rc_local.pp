class captainshove::rc_local (
  $rc_path,
  $cwd,
  $command
) {
  exec {"add-to-$rc_path":
    command => "echo '$command' >> $rc_path",
    unless  => "grep '$command' $rc_path",
    path    => "/usr/bin/:/bin/",
  }
}
