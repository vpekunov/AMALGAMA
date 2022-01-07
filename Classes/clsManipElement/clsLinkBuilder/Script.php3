<?
$Num = $In["Number"];
switch ($Stage) {
  case stResource:
    echo "T = ";
    for ($i = 1; $i<=$Num; $i++)
      echo "T".$i.($i==$Num ? ";\n" : "*");
    break;
  case stCall:
?>
T = simple(T);
C = simple(T*[0;0;0;1]);
<?
cortege_push($Eqtns["Variable"],"C(1:3)");
$Eqtns["Mins"] = $In["Mins"];
$Eqtns["Maxes"] = $In["Maxes"];
$Eqtns["sVars"] = $In["sVars"];
cortege_push($Eqtns["Caption"],"Уравнения связи");
}
?>
