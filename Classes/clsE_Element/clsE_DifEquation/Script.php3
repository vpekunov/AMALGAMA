<?
$EXPORT = GetNextMail("EXPORT");
if ($EXPORT === "") {
   global $XML;
   $ref = $XML->match("/System/Elements/Element[@ClassID='clsE_Export']/Parameters/Parameter[@ID='Lang']/text()");
   if ($ref[0] != "") {
       $EXPORT = $XML->wholeText($ref[0]);
   }
}
if ($EXPORT !== "") {
   SwitchExportOn();
   PutMail("EXPORT",$EXPORT);
   return;
}

$Solver["Phase"] = $Calc["Phase"];
$Solver["Control"] = $Calc["Control"];
if ($Calc["Nc"][0]>1)
   {
    $KRef = array();
    $SRef = array();
    $Ref = array();
    for ($i=0; $i<$Calc["Nc"][0]; $i++)
        {
         cortege_push($Solver["DefPhase"],$Calc["DefPhase"][0].$i);
         cortege_push($Solver["Init"],$Calc["Init"][0]);
         cortege_push($Solver["Projection"],$Calc["Projection"][0]);
         cortege_push($Solver["FBase"],$Calc["FBase"][0]);
         cortege_push($Solver["Nc"],$Calc["Nc"][0]);
         cortege_push($Solver["Name"],$Calc["Name"][0].$i);
         cortege_push($Solver["Restrict"],$Calc["Restrict"][0]);
         cortege_push($Solver["NeedK"],$powK!=0);
         cortege_push($Solver["Solver"],$this->Handler);
         cortege_push($Solver["BndLevel"],0);
         cortege_push($Solver["SubClass"],$i);
         cortege_push($Solver["Description"],$Calc["Description"][0]." [".$i."]");
         array_push($KRef,"Kf[_Num".$Calc["Name"][0].$i."]");
         array_push($Ref,$Calc["Name"][0].$i);
        }
    $KRef = "float * K_".$Calc["Name"][0]."[".$Calc["Nc"][0]."] = {".implode(",",$KRef)."};";
    cortege_push($Solver["Refs"],$KRef);
    $Ref = "float * ".$Calc["Name"][0]."[".$Calc["Nc"][0]."] = {".implode(",",$Ref)."};";
    cortege_push($Solver["Refs"],$Ref);
    cortege_push($Solver["MultiName"],$Calc["Name"][0]);
    cortege_push($Solver["MultiNum"],$Calc["Nc"][0]);
   }
else
   {
    $Solver["DefPhase"] = $Calc["DefPhase"];
    $Solver["Init"] = $Calc["Init"];
    $Solver["Projection"] = $Calc["Projection"];
    $Solver["FBase"] = $Calc["FBase"];
    $Solver["Nc"] = $Calc["Nc"];
    $Solver["Description"] = $Calc["Description"];
    cortege_push($Solver["Name"],$Calc["Name"][0]);
    cortege_push($Solver["Restrict"],$Calc["Restrict"][0]);
    cortege_push($Solver["NeedK"],$powK!=0);
    cortege_push($Solver["BndLevel"],0);
    cortege_push($Solver["SubClass"],-1);
    cortege_push($Solvers,$this->Handler);
    $Solver["Solver"] = $Solvers;
   }
if ($powK==0 && $powBound==0)
   $Solver["Parameters"] = $Calc["Parameters"];
else
   {
    if ($powK==0)
       $Solver["Parameters"] = $Calc["Parameters"];
    else
       $Solver["Parameters"] = array_merge($Calc["Parameters"],$K["Parameters"]);
    if ($powBound!=0)
       $Solver["Parameters"] = array_merge($Solver["Parameters"],$Bound["Parameters"]);
    AnalyzeFunctionItems($K,$powK,$Calc,$Solver,"FText","FText","FVars","K_","[Ptr]","Kf[_Num","][Ptr]","+=");

    $bounds = array('Right(X+)', 'Left(X-)', 'Forw(Y+)', 'Backw(Y-)', 'Up(Z+)', 'Down(Z-)');
    $conds = array('IsRight', 'IsLeft', 'IsForw', 'IsBack', 'IsTop', 'IsBottom');
    $prefs = array('_rg', '_lf', '_fw', '_bw', '_tp', '_bt');

    $keys = array_keys($Bound);
    $nNoVals = 0;
    $NoWalls = array();
    $nnWalls = 0;
    $nWalls = array();
    $Walls = array();
    foreach ($bounds as $wall) {
        $Walls[$wall] = array();
        $nWalls[$wall] = 0;
    }
    $i = 0;
    if (is_array($Bound["_ClassID"]))
       foreach ($Bound["_ClassID"] as $ClsID) {
          if ($ClsID == "clsE_BoundFunction") {
             $type = $Bound["Boundary"][$nnWalls];
             foreach ($keys as $key) {
               if ($key != "Boundary")  
                  cortege_push($Walls[$type][$key], $Bound[$key][$i]);
             }
             $nWalls[$type]++;
             $nnWalls++;
          } else {
             foreach ($keys as $key) {
                 if ($i < count($Bound[$key]))
                    cortege_push($NoWalls[$key], $Bound[$key][$i]);
             }
             $nNoWalls++;
          }
          $i++;
       }
    AnalyzeFunctionItems($NoWalls,$nNoWalls,$Calc,$Solver,"FText","BText","BVars","if (IsBound && !IsExchng) ","","if (IsBound && !IsExchng) ","","=");
    for ($idx = 0; $idx < count($bounds); $idx++) {
      $type = $bounds[$idx];
      AnalyzeFunctionItems($Walls[$type],$nWalls[$type],$Calc,$Solver,"FText","BText","BVars",
                           "if (IsBound && !IsExchng && ".$conds[$idx].") ".$prefs[$idx]."(",")",
                           "if (IsBound && !IsExchng && ".$conds[$idx].") ".$prefs[$idx]."(",")",
                           "=");
    }
   }
?>
