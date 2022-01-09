<?
if ($Stage==stCall)
   {
?>  ClearPut
  PutTitle('Результаты')
<?
    $NumOuts = count($In["_ID"]);
    for ($i = 0; $i<$NumOuts; $i++)
      {
       $ID = $In["_ID"][$i];
       $Class = $In["_ClassID"][$i];
       $Nm    = $In["Name"][$i];
       if ($Class == "clsP_MapStrings")
          {
           $Val = $In["Var$ID"][0];
           echo "  If text".$ID."[$Val]\n";
           echo "     PutText(GetTextByPtr(".$ID."[$Val]))\n";
           echo "  Else\n";
           echo "     PutLine(?".$ID."[$Val])\n";
           echo "  EndIf\n\n";
          }
       else
          echo "  PutLine('$Nm = ',".$ID.")\n";
      }
?>  ShowPut
<?
   }
?>