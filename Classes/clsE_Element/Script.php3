<?
if (!function_exists("ExtractParams")) {
   function ExtractParams($Text,&$Params) {
     do {
       if (ereg("@((\[([0-9]*)\])?(([a-z0-9A-Z_]+)\{([a-z0-9A-Z_]+)\}))",$Text,$Regs))
          $Text = str_replace($Regs[0],$Regs[5],$Text);
       else if (ereg("@((\[([0-9]*)\])?([a-z0-9A-Z_]+))(([^\{a-z0-9A-Z_])|($))",$Text,$Regs))
          $Text = str_replace($Regs[0],$Regs[4].$Regs[5],$Text);
       else
          break;
       cortege_push($Params,$Regs[1]);
     } while (true);
     return $Text;
   }
}
if (!function_exists("AnalyzeFunction")) {
   function AnalyzeFunction(&$Vars,&$Text,$DefPhase) {
     $nLines = count(explode("\n",trim($Text)));
     $Vars = 
        ereg_replace("(([^a-z0-9A-Z_])|(^))Source(([^a-z0-9A-Z_])|($))",
                     "\\1Source_".$DefPhase."[Ptr]\\4",
                     $Vars);
     $Text = 
        ereg_replace("(([^a-z0-9A-Z_])|(^))Source(([^a-z0-9A-Z_])|($))",
                     "\\1Source_".$DefPhase."[Ptr]\\4",
                     $Text);
     if ($nLines<2)
        if (!ereg("(^([ \n]*))Result(([^a-z0-9A-Z_])|($))",$Text))
           $Text = "Result = ".$Text;
   }
}
if (!function_exists("AnalyzeFunctionItems")) {
   function AnalyzeFunctionItems(&$K,&$powK,$Calc,&$Solver,$KNmText,$NmText,$NmVars,$MultiPrefix,$MultiPostfix,$SinglePrefix,$SinglePostfix,$Operation) {
    for ($i=0; $i<$powK; $i++)
      {
       AnalyzeFunction($K["FVars"][$i],$K[$KNmText][$i],$Calc["DefPhase"][0].($Calc["Nc"][0]>1 ? "0" : ""));

       if ($Calc["Nc"][0]>1)
          {
           $Text = HandleMultiFunction(false,$K[$KNmText][$i],$Calc["Nc"][0]);
           if (ereg("(([^a-z0-9A-Z_])|(^))Result\[([^]i]+)\]",$Text))
              cortege_push($Solver[$NmText],
                 ereg_replace("(([^a-z0-9A-Z_])|(^))Result\[([^]i]+)\]([ \n]*)=([ \n]*)(([^a-z0-9A-Z_])|($))",
                                           "\\1".$MultiPrefix.$Calc["Name"][0]."[\\4]".$MultiPostfix." ".$Operation." \\7",
                                           $Text));
           else
             cortege_push($Solver[$NmText],
                "vector(".$Calc["Nc"][0].") {\n".
                ShiftStr(" ",ereg_replace("(([^a-z0-9A-Z_])|(^))Result([ \n]*)=([ \n]*)(([^a-z0-9A-Z_])|($))",
                                          "\\1".$MultiPrefix.$Calc["Name"][0]."[i]".$MultiPostfix." ".$Operation." \\6",
                                          $Text))."\n".
                "}\n");
           cortege_push($Solver[$NmVars],HandleMultiFunction(true,$K["FVars"][$i],$Calc["Nc"][0]));
          }
       else
          {
           $Solver[$NmVars] = $K["FVars"];
           if (ereg("(([^a-z0-9A-Z_])|(^))Result([ \n]*)=",$K[$KNmText][$i]))
              cortege_push($Solver[$NmText],
                 ereg_replace("(([^a-z0-9A-Z_])|(^))Result([ \n]*)=([ \n]*)(([^a-z0-9A-Z_])|($))",
                              "\\1".$SinglePrefix.$Calc["Name"][0].$SinglePostfix." ".$Operation." \\6",
                              $K[$KNmText][$i]));
           else
              cortege_push($Solver[$NmText],$SinglePrefix.$K[$KNmText][$i]);
          }
      }
   }
}
if (!function_exists("HandleMultiFExpression")) {
   function HandleMultiFExpression(&$FExpression,$Nc) {
    if (ereg("(([^a-z0-9A-Z_])|(^))Result\[([^]i]+)\]",$FExpression,$Regs))
       {
        $Expr = ereg_replace("(([^a-z0-9A-Z_])|(^))Nc(([^a-z0-9A-Z_])|($))",
                             "\\1ResultNc\\4",
                             $Regs[4]);
        $FExpression = str_replace($Regs[1]."Result[".$Regs[4]."]",
                                   $Regs[1]."Result[".$Expr."]",
                                   $FExpression);
       }
    $FExpression = HandleMultiFunction(false,$FExpression,$Nc);
    if (ereg("(([^a-z0-9A-Z_])|(^))Result\[([^]i]+)\]",$FExpression,$Regs))
       {
        $Expr = ereg_replace("(([^a-z0-9A-Z_])|(^))ResultNc(([^a-z0-9A-Z_])|($))",
                             "\\1Nc\\4",
                             $Regs[4]);
        $FExpression = str_replace($Regs[1]."Result[".$Regs[4]."]",
                                   $Regs[1]."Result[".$Expr."]",
                                   $FExpression);
       }
   }
}
if (!function_exists("HandleParameter")) {
   function HandleParameter($Stage,&$Var,$Nc,&$CVar,&$CParameters,$Name) {
     $Var = trim($Var);
     if ($Var[0]=="@")
        {
         cortege_push($CVar,($Name = strtok(substr($Var,1),"{")));
         $Prepend = ($Name[0]!="[" && $Nc>1) ? "[".$Nc."]" : "";
         cortege_push($CParameters,$Prepend.substr($Var,1));
        }
     else
        {
         if ($Stage==stResource)
            { ?>double <?
             if ($Nc==1)
                echo $Name." = ",$Var,";\n";
             else
                echo $Name."[".$Nc."] = {",$Var,"};\n";
            }
         cortege_push($CVar,$Name);
        }
   }
}
if (!function_exists("HandleInitParameter")) {
   function HandleInitParameter($Stage,&$Var,$Nc,&$CVar,&$CParameters,$Name) {
     $VarLines = count(explode("\n",trim($Var)));
     if ($VarLines<2) $Var = trim($Var);
     cortege_push($CVar,"_".$Name);
     $RetVal = ExtractParams($Var,$CParameters);
     if ($Stage==stResource)
        { ?>
double _<? echo $Name; ?> (int i, int x, int y, int z, unsigned char Map);
<?
        }
     if ($Stage==stDone)
        { ?>
double _<? echo $Name; ?> (int i, int x, int y, int z, unsigned char Map)
{
<?       if ($VarLines<2 && !ereg("(^([ \n]*))Result(([^a-z0-9A-Z_])|($))",$RetVal))
            echo " return ".$RetVal.";\n";
         else
            echo " double Result;\n".ShiftStr(" ",$RetVal)."\n return Result;\n"; ?>
}
<?
        }
   }
}
if (!function_exists("HandleMultiFunction")) {
   function HandleMultiFunction($HandleVectors,$Text,$Nc) {
     if ($HandleVectors)
        $Text = ereg_replace("(([^a-z0-9A-Z_])|(^))vector(([^a-z0-9A-Z_\(])|($))",
                             "\\1vector(".$Nc.")\\4",
                             $Text);
     $Text = ereg_replace("(([^a-z0-9A-Z_])|(^))Sum\{([^,}]+)\}",
                          "\\1Sum{0,".$Nc."-1,\\4}",
                          $Text);
     $Text = ereg_replace("(([^a-z0-9A-Z_])|(^))Min\{([^,}]+)\}",
                          "\\1Min{0,".$Nc."-1,\\4}",
                          $Text);
     $Text = ereg_replace("(([^a-z0-9A-Z_])|(^))Max\{([^,}]+)\}",
                          "\\1Max{0,".$Nc."-1,\\4}",
                          $Text);
     do {
        $RES = ereg_replace("((([^a-z0-9A-Z_])|(^))Nc(([^a-z0-9A-Z_])|($)))",
                          "\\2".$Nc."\\5",
                          $Text);
        if ($RES === $Text) return $RES;
        $Text = $RES;
     } while (1);
   }
}
if (!function_exists("SetXMLExportMode")) {
   function SetXMLExportMode($Path) {
     global $ExportPath;
     $ExportPath = $Path;
     SwitchExportOn();
   }
}
if (!function_exists("WriteXMLExportHeader")) {
   function WriteXMLExportHeader() {
       echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"; ?>
<!DOCTYPE System [
<!ELEMENT System (Elements)>
<!ATTLIST System
Lang CDATA #REQUIRED
>
<!ELEMENT Elements (Element*)>
<!ATTLIST Elements
NumItems CDATA #REQUIRED
>
<!ELEMENT Element (Show,Position,Parameters,InternalInputs,InternalOutputs,PublishedInputs,PublishedOutputs,InputLinks,OutputLinks)>
<!ATTLIST Element
ClassID CDATA #REQUIRED
ParentID CDATA #REQUIRED
ID ID #REQUIRED
Permanent (True | False) #REQUIRED
>
<!ELEMENT Show EMPTY>
<!ATTLIST Show
Class (True | False) #REQUIRED
Name (True | False) #REQUIRED
Image (True | False) #REQUIRED
>
<!ELEMENT Position EMPTY>
<!ATTLIST Position
Left CDATA #REQUIRED
Top CDATA #REQUIRED
>
<!ELEMENT Parameters (Parameter*)>
<!ATTLIST Parameters
NumItems CDATA #REQUIRED
>
<!ELEMENT Parameter (#PCDATA | EMPTY)*>
<!ATTLIST Parameter
ID CDATA #REQUIRED
Indent CDATA #IMPLIED
>
<!ELEMENT InternalInputs (iContact*)>
<!ATTLIST InternalInputs
NumItems CDATA #REQUIRED
>
<!ELEMENT InternalOutputs (iContact*)>
<!ATTLIST InternalOutputs
NumItems CDATA #REQUIRED
>
<!ELEMENT iContact EMPTY>
<!ATTLIST iContact
ID CDATA #REQUIRED
ElementID IDREF #REQUIRED
ContID CDATA #REQUIRED
>
<!ELEMENT PublishedInputs (pContact*)>
<!ATTLIST PublishedInputs
NumItems CDATA #REQUIRED
>
<!ELEMENT PublishedOutputs (pContact*)>
<!ATTLIST PublishedOutputs
NumItems CDATA #REQUIRED
>
<!ELEMENT pContact EMPTY>
<!ATTLIST pContact
ID CDATA #REQUIRED
PublicID CDATA #REQUIRED
PublicName CDATA #REQUIRED
>
<!ELEMENT InputLinks (Contact*)>
<!ELEMENT OutputLinks (Contact*)>
<!ELEMENT Contact (Link*)>
<!ATTLIST Contact
ID CDATA #REQUIRED
>
<!ELEMENT Link (Points?)>
<!ATTLIST Link
ElementID IDREF #REQUIRED
ContID CDATA #REQUIRED
Color CDATA #IMPLIED
Informational (True | False) #REQUIRED
>
<!ELEMENT Points (#PCDATA | EMPTY)*>
<!ATTLIST Points
NumItems CDATA #REQUIRED
>
]>
<System Lang="">
<?
   }
}
if (!function_exists("WriteXMLElementsQuantity")) {
   function WriteXMLElementsQuantity($n) {
       echo " <Elements NumItems=\"$n\">\n";
   }
}
if (!function_exists("WriteXMLExportFooter")) {
   function WriteXMLExportFooter() {
?> </Elements>
</System>
<?
   }
}
if (!function_exists("ExportXMLElement")) {
   function ExportXMLElement($n, $ClassID, $ID, $Params) {
     global $ExportPath;
     if ($ExportPath != "") {
        $Path = "Classes\\" . $ExportPath . "\\" . $ClassID;
        if (!file_exists($Path))
           mkdir($Path);
        $f = fopen($Path . "\\class.ini", "w");
        fwrite($f, "[Definition]\n");
        fwrite($f, "Name=ЭКСПОРТ_".substr($ClassID, 3)."\n");
        fwrite($f, "InheritScript=1\n\n");
        fwrite($f, "[Parameters]\n");
        foreach ($Params as $Key => $Val)
          fwrite($f, "{; Text; '$Key'} $Key=\n");
        fclose($f);
     }
?>
  <Element ClassID="<? echo $ClassID; ?>" ParentID="" ID="<? echo $ID; ?>" Permanent="False">
   <Show Class="True" Name="True" Image="False"/>
   <Position Left="<? echo ($n % 8)*150; ?>" Top="<? echo (int)($n/8)*150; ?>"/>
<?
     if (count($Params) == 0) echo "<Parameters NumItems=\"0\"/>\n";
     else {
        echo "<Parameters NumItems=\"".count($Params)."\">\n";
        foreach ($Params as $Key => $Val)
           echo "    <Parameter ID=\"".$Key."\" Indent=\"0\">".htmlspecialchars($Val)."</Parameter>\n";
        echo "</Parameters>\n";
     }
?>
   <InternalInputs NumItems="0"/>
   <InternalOutputs NumItems="0"/>
   <PublishedInputs NumItems="0"/>
   <PublishedOutputs NumItems="0"/>
   <InputLinks/>
   <OutputLinks/>
  </Element>
<?
   }
}
?>