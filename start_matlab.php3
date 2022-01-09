<?
  error_reporting(0);
  $MLab = com_load("Matlab.Application") or die("MATLAB call error");
  com_set($MLab,"Visible",0);
  $IN = file($argv[1]);
  echo com_invoke($MLab,"Execute",implode("\n",$IN));
  com_release($MLab);
  $MLab = null;
?>