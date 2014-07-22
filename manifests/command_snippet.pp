define captainshove::command_snippet (
  $file_path,
  $cwd,
  $command
) {
  exec {"add-to-$file_path":
    command => "echo '$command' >> $file_path",
    unless  => "grep '$command' $file_path",
    path    => "/usr/bin/:/bin/",
  }
}
