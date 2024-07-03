<?php
  if (!function_exists("AnalyzeInput")) {
     function AnalyzeInput(&$powX,&$X) {
       $Counts = array_count_values($X["_ClassID"]);
       if ($Counts["clsI_Filter"])
          {
           if ($Counts["clsI_Filter"]!=$powX)
              MakeError("Model Error: ","Inputs must be traced from NON-FILTER OBJECTS or from ONE FILTER ONLY",__LINE__);
           $Counter = GetNextMail("COUNT_".$X["_ID"][0]);
           foreach ($X as $Key => $Val)
             if (_count($Val)!=$powX)
                $X[$Key] = array_slice($X[$Key],$Counter,$powX);
           PutMail("COUNT_".$X["_ID"][0],$Counter+$powX);
          }
     }
  }

  if (!function_exists("CollectUnaryIDs")) {
     function CollectUnaryIDs($ID,$powX,$X) {
       $IDs = array($ID);
       for ($i=0; $i<$powX; $i++)
           if (isset($X))
              $IDs =  _array_merge($IDs,$X[$i]);
       return $IDs;
     }
  }

  if (!function_exists("CollectBinaryIDs")) {
     function CollectBinaryIDs($powX1,$X1,$powX2,$X2,&$IDs1,&$IDs2) {
       $IDs1 = array();
       $IDs2 = array();
       for ($i=0; $i<$powX1; $i++)
           if (isset($X1) && isset($X1[$i]))
              $IDs1 =  _array_merge($IDs1,$X1[$i]);
       $IDs1 = array_unique($IDs1);
       for ($i=0; $i<$powX2; $i++)
           if (isset($X2) && isset($X2[$i]))
              $IDs2 =  _array_merge($IDs2,$X2[$i]);
       $IDs2 = array_unique($IDs2);
     }
  }

  if (!function_exists("CreateScript")) {
    function CreateScript($MLab,$MLabDir,&$MLabFuns,$Name,$Content) {
      if (file_exists($MLabDir."\\".$Name.".m"))
         {
          unlink($MLabDir."\\".$Name.".m");
          while (GetAns(com_invoke($MLab,"Execute","exist('$Name')"))!=0);
         }
      $File = fopen($MLabDir."\\".$Name.".m","wb");
      fwrite($File,implode("\n",$Content));
      fclose($File);
      if ($MLabFuns)
         {
          array_push($MLabFuns,$Name);
          $MLabFuns = array_unique($MLabFuns);
         }
      else
         $MLabFuns = array($Name);
      while (GetAns(com_invoke($MLab,"Execute","exist('$Name')"))!=2);
    }
  }

  if (!function_exists("CheckActive")) {
    function CheckActive($ID,&$Goal) {
      $Goal = "";
      $Activated = 0;
      while ($Mail = GetNextMail("Goal_".$ID))
        $Goal .= ($Activated++==0 ? "" : ";").$Mail;
      if ($Activated>1)
         $Goal = "mean([".$Goal."])";
      return $Activated;
    }
  }

  if (!function_exists("GetAns")) {
    function GetAns($Ans) {
      $Ans = str_replace("\n","",str_replace("\r","",$Ans));
      return str_replace("ans =","",$Ans);
    }
  }

  if (!function_exists("empty_array")) {
    function empty_array($Arr) {
      if (!empty($Arr))
         foreach ($Arr as $Val)
           if ($Val!="")
              return false;
      return true;
    }
  }

  if (!function_exists("nonempty_value")) {
    function nonempty_value($Arr) {
      if (!empty($Arr))
         foreach ($Arr as $Val)
           if ($Val!="")
              return $Val;
      return "";
    }
  }

  if (!function_exists("GetVectorLine")) {
    function GetVectorLine($Line,$NumInd) {
      $Pattern = "%lf";
      for ($i=1; $i<$NumInd; $i++)
        $Pattern .= " %lf";
      $Result = sscanf($Line,$Pattern);
      for ($i=$NumInd-1; $i>=0; $i--)
        if (!is_numeric($Result[$i]))
           unset($Result[$i]);
      return $Result;
    }
  }

  if (!function_exists("GetVector")) {
    function GetVector($Name,$NumInd) {
      $File = file($Name);
      $Result = array();
      foreach ($File as $Val)
        if ($Val!="")
           {
            $Add = GetVectorLine($Val,$NumInd);
            if (!empty($Add))
               $Result =  _array_merge($Result,$Add);
           }
      unlink($Name);
      return $Result;
    }
  }

  if (!function_exists("GetValue")) {
    function GetValue($Name) {
      $Result = GetVector($Name,1);
      return $Result[0];
    }
  }

  if (!function_exists("SelectBestVariant")) {
    function SelectBestVariant($ObjID, $Function, $Init, $Parameters,
        $Initialization,
        $arrN,$Out,$arrInps,$arrNorms,
        $arrInits,
        $MLab,$MLabDir,&$MLabFuns, $NP,$Rad,
        &$R2Norm,&$K,&$Res) {
      $Inp = "";
      $Add = $Initialization;
      if ($Init=="multinetwork")
         {
          $Selected[0] = -1;
          $XX = "X = [";
          for ($i=0; $i<$arrN[0]; $i++)
              {
               if ($arrInits)
                  $Add .= $arrInits[0][$i];
               $XNum = $i+1;
               $Inp .= "X$XNum=".$arrInps[0][$i].";";
               $XX  .= "X$XNum;";
              }
           $XX[strlen($XX)-1] = "]";
           $Inp .= $XX.";";
          }
      else
         foreach ($arrN as $Ind => $N)
          {
           $Selected[$Ind] = 0;
           for ($i=1; $i<$N; $i++)
             if ($arrNorms[$Ind][$i]<$arrNorms[$Ind][$Selected[$Ind]])
                $Selected[$Ind] = $i;
           $XNum = $Ind+1;
           if ($arrInits)
              $Add .= $arrInits[$Ind][$Selected[$Ind]];
           if (_count($arrN)==1)
              $Inp = "X=".$arrInps[$Ind][$Selected[$Ind]].";";
           else
              $Inp .= "X$XNum=".$arrInps[$Ind][$Selected[$Ind]].";";
          }
      $Inp = $Add.$Inp;

      echo "Clearing MatLAB workspace... ";
      echo com_invoke($MLab,"Execute","clear all");
      echo "wait for 1 sec.\n";
      sleep(1);
      PutMail("TIME",GetNextMail("TIME")+1);

      if ($Init=="network" || $Init=="multinetwork")
         {
          com_invoke($MLab,"Execute",
              $Inp.
              "Y = $Out;".
              "BestR2Norm=1E30;".
              ($NP && $NP>1 ? "for i=1:$NP;" : "").
                "K = $Function;".
                "K.trainParam.epochs = ".$Parameters["Epochs"].";".
                "K.trainParam.show   = 1;".
                "K = train(K,X,Y);".
                "Result = sim(K,X);".
                "R2Norm = (Y-Result)*(Y-Result)';".
                "if R2Norm<BestR2Norm;".
                "   BestR2Norm=R2Norm;".
                "   BestK=K;".
                "end;".
              ($NP && $NP>1 ? "end;" : "").
              "K=BestK;".
              "Result=sim(K,X);".
              "save '$MLabDir\\$ObjID.mat' BestK;".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.r2' BestR2Norm;".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.res' Result;");
          $K = "$MLabDir\\$ObjID.mat";
         }
      else if ($Init=="polynom")
         {
          echo com_invoke($MLab,"Execute",
              $Inp.
              "Y = $Out;".
              "if (X-Y)*(X-Y)';".
              "   K = polyfit(X,Y,".$Parameters["PolyN"].");".
              "   K(find(isnan(K)))=0;".
              "else;".
              "   K = zeros(1,".($Parameters["PolyN"]+1).");".
              "   K(".$Parameters["PolyN"].") = 1;".
              "end;".
              "Result = $Function;".
              "R2Norm = (Y-Result)*(Y-Result)';".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.k' K;".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.r2' R2Norm;".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.res' Result;");
          $K = GetVector($MLabDir."\\".$ObjID.".k",20);
         }
      else
         {
          if (_count($arrN)>1)
             CreateScript($MLab,$MLabDir,$MLabFuns,$ObjID,
                array(
                  "function Result = $ObjID(K)",
                  $Inp,
                  "Y=$Out;",
                  "Result = Y-($Function);",
                  "return;"
                )
             );
          echo com_invoke($MLab,"Execute",
              "BestK=0;".
              $Inp.
              (_count($arrN)==1 ?
                "Y=$Out;".
                "$ObjID = inline('$Function','K','X');" :
                ""
              ).
              ($Init=="[]" || $Init=="" ?
                "K=0;".
                "BestR2Norm=$ObjID(K)*$ObjID(K)';"
               :
                "K0=$Init;".
                "R=$Rad;".
                "BestR2Norm=1E30;".
                ($NP && $NP>1 ? "rand('state',sum(100*clock));for i=1:$NP;" : "").
                  (_count($arrN)==1 ?
                    "[K R2Norm]=lsqcurvefit($ObjID,K0,X,Y);" :
                    "[K R2Norm]=lsqnonlin(@{$ObjID},K0);"
                  ).
                  "if R2Norm<BestR2Norm;".
                  "   BestR2Norm=R2Norm;".
                  "   BestK=K;".
                  "end;".
                  ($NP && $NP>1 ?
                    (
                     substr($Rad,0,1)=="[" ?
                       "K0=K+rand(1,size(K,2)).*R;" :
                       "K0=K+rand(1,size(K,2)).*ones(1,size(K,2))*R;"
                    ).
                    "end;"
                   :
                    "")
              ).
              "K=BestK;".
              "Result=($Function);".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.k' BestK;".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.r2' BestR2Norm;".
              "save -ASCII -DOUBLE '$MLabDir\\$ObjID.res' Result;");
          $K = GetVector($MLabDir."\\".$ObjID.".k",20);
         }
      $R2Norm = GetValue($MLabDir."\\".$ObjID.".r2");
      $Res    = "[".implode(" ",GetVector($MLabDir."\\".$ObjID.".res",5000))."]";
      return $Selected;
    }
  }

  if ($Stage==stDone)
     if ($this->MLabFuns)
        {
         $this->MLabFuns = array_unique($this->MLabFuns);
         foreach ($this->MLabFuns as $Fun)
           unlink($this->MLabDir."\\".$Fun.".m");
         unset($this->MLabFuns);
        }
?>