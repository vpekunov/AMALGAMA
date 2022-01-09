<?
switch ($Stage) {
  case stCall:
    $ViewF = $this->Disp=="Yes" ? "disp" : "pretty";
    for ($i = 0; $i<$powView; $i++)
      {
       if ($In["Caption"][$i] !== "") echo "disp('".$View["Caption"][$i]."');\n";
       echo $ViewF."(".$View["Variable"][$i].");\n";
      }
    break;
}
?>
