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
   if ($Stage == stCall) {
     if ($EXPORT == "Russian") {
      if ($this->Functions !== "") {
          ?> Добавим в решение новые функции "<? echo $this->Functions; ?>".<?
      }
?> Решим полученную систему уравнений.<?
     } else if ($EXPORT == "XML") {
      $n = GetNextMail("COUNTER");
      if ($this->Functions !== "") {
          ExportXMLElement($n++, "clsE_SSolver_Fs", "ID$n", array("Funs"=>$this->Functions));
      }
      ExportXMLElement($n++, "clsE_SSolver", "ID$n", array());
      PutMail("COUNTER", $n);
    }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n++;
      if ($this->Functions != "") $n++;
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

$this->Functions = UnrollIfNotExport($this->Functions);

switch ($Stage) {
  case stResource:
    $AdditionalVars = array("Lmin2","DIV","DivSolar");
    if ($powModify>0)
       $AdditionalVars = array_merge($AdditionalVars,$Modify["Name"]);
    $MultiVars = is_array($Eqtn["MultiName"]) ? $Eqtn["MultiName"] : array();
    $MultiNums = is_array($Eqtn["MultiNum"]) ? $Eqtn["MultiNum"] : array();
    $nPhases = array();
    foreach ($Eqtn["Phase"] as $Val)
      if ($Val["Nc"]>1)
         for ($i=0; $i<$Val["Nc"]; $i++)
             {
              $V = $Val;
              $V["Name"] .= $i;
              $V["Uw"] .= "[".$i."]";
              $V["SubClass"] = $i;
              if ($i>0)
                 {
                  unset($V["FVars"]);
                  unset($V["FText"]);
                  unset($V["SVars"]);
                  unset($V["SText"]);
                 }
              array_push($nPhases,$V);
             }
      else
         array_push($nPhases,$Val);
    if (is_array($Eqtn["Parameters"]))
       $nParams = $Eqtn["Parameters"];
    else
       $nParams = array();
    if (is_array($Modify["Parameters"]))
       $nParams = array_merge($nParams,$Modify["Parameters"]);
    foreach ($nPhases as $Val)
       if (is_array($Val["Parameters"]))
          $nParams = array_merge($nParams,$Val["Parameters"]);
    $hParams = array();
    foreach ($nParams as $Val)
      {
       if ($Val[0]=="[")
          if ($Val[1]=="]")
             {
              $Num = 50;
              $Val = substr($Val,2);
             }
          else
             {
              $Num = strtok($Val,"[]");
              $Val = strtok("");
             }
       else
          $Num = 0;
       $Nm = strtok($Val,"{");
       $Sect = strtok("{}");
       if (array_key_exists($Nm,$hParams))
          {
           $Num1 = strtok($hParams[$Nm],"{");
           $Sect1 = strtok("{}");
           if (strlen($Sect1)>strlen($Sect)) $Sect = $Sect1;
           $hParams[$Nm] = max($Num1,$Num)."{".$Sect."}";
          }
       else
          $hParams[$Nm] = $Num."{".$Sect."}";
      }
    $nParams = array();
    foreach ($hParams as $Key => $Val)
      {
       $Num = strtok($Val,"{");
       $Key .= "{".strtok("{}")."}";
       if ($Num==0) array_push($nParams,$Key);
       else array_push($nParams,"[".$Num."]".$Key);
      }
    $Params = array();
    foreach ($nParams as $Val)
      {
       $Prm = strtok($Val,"{");
       $Sect = strtok("{}");
       if (!$Sect) $Sect = " ";
       if (!array_key_exists($Prm,$Params))
          $Params[$Prm] = $Sect;
       else
          if ($Sect!=" ") $Params[$Prm] = $Sect;
      }
    foreach ($Params as $Key => $Val)
      { ?>double <?
        if (($Num = strtok($Key,"[]"))!=$Key)
           echo strtok(""),"[".$Num."];\n";
        else
           echo $Key,";\n";
      }
    $NumVars = count($Eqtn["Name"]);
    $VFields = array("Name","FBase","Projection","SubClass","NeedK","NeedS","Init","NuMol","Kappa","Solver","DefPhase","Nc","Description","Restrict","BndLevel");
    for ($i=0; $i<$NumVars-1; $i++)
        {
         $BestNum = $i;
         for ($j=$i+1; $j<$NumVars; $j++)
           if ($Eqtn["DefPhase"][$j]<$Eqtn["DefPhase"][$BestNum] ||
               $Eqtn["DefPhase"][$j]==$Eqtn["DefPhase"][$BestNum] &&
                  $Eqtn["FBase"][$j]<$Eqtn["FBase"][$BestNum] ||
               $Eqtn["DefPhase"][$j]==$Eqtn["DefPhase"][$BestNum] &&
                  $Eqtn["FBase"][$j]==$Eqtn["FBase"][$BestNum] &&
                  $Eqtn["Projection"][$j]<$Eqtn["Projection"][$BestNum]
              )
              $BestNum = $j;
         if ($BestNum!=$i)
            foreach ($VFields as $Val)
              {
               $Buf = $Eqtn[$Val][$BestNum];
               $Eqtn[$Val][$BestNum] = $Eqtn[$Val][$i];
               $Eqtn[$Val][$i] = $Buf;
              }
        }
    $Vars    = $Eqtn["Name"];
    $idVars  = array();
    for ($i=0; $i<$NumVars; $i++)
        $idVars[$i] = "_Num".$Vars[$i];
?>

#define NumEqs <? echo $NumVars,"\n";
?>

enum {<? echo implode(",",$idVars);?>};

#define _NumDn NumEqs /* Вещества */

int PredictControlVar = <? echo $Eqtn["Control"][0],";\n\n";

    $Phases = array();
    foreach($nPhases as $Key => $Value)
      if (array_key_exists($Value["Name"],$Phases))
         $Phases[$Value["Name"]] = array_merge($Phases[$Value["Name"]],$Value);
      else
         $Phases[$Value["Name"]] = $Value;
    $NumPhases = count($Phases);
    $NumHeavyPhases = 0;
    $idPhases = array();
    foreach ($Phases as $Key => $Val)
      {
       $NumHeavyPhases += $Val["Heavy"];
       $idPhases[$Key] = "ph".$Key;
       if ($Val["Carrier"]) $CarrierPhase = $idPhases[$Key];
      }
?>#define NumLightPhases <? echo $NumPhases-$NumHeavyPhases,"\n";
?>#define NumHeavyPhases <? echo $NumHeavyPhases,"\n";
?>#define NumPhases (NumLightPhases+NumHeavyPhases)

enum {<? echo implode(",",$idPhases); ?>};

int CarrierPhase = <? echo $CarrierPhase; ?>;

#define NumSaves (NumEqs-NumHeavyPhases*(nDims-1))

typedef struct {
 float  * Name[NumEqs];
 float ** Dn; /* Вещества */
 float  * eName[NumEqs];
 float ** eDn; /* Вещества по явному шагу Эйлера */
 int     BoundSize;
 float * Bounds[6];
 float * Parts[3];
 float * PartsV[3];
} StoreStruct;

typedef struct {
  int    IsLight;
  double * _Uw;
  int    _Ux, _Uy, _Uz, _Nu, _T, _Ro;
  const char * Source;
} PhaseDsc;

PhaseDsc PhaseVars[NumPhases] = {
<?
    if (!function_exists("CheckRef")) {
       function CheckRef($MVars,$Val,$SubClass) {
         if ($Val=="") return -1;
         else
            if ($SubClass!=="" && substr($Val,0,4)=="_Num" && in_array(substr($Val,4),$MVars))
               return $Val.$SubClass;
            else
               return $Val;
       }
    }
    
    $Sources = array();
    $PhaseDsc = array();
    $PhaseFVars = array();
    $PhaseFText = array();
    $i = 0;
    foreach ($Phases as $Key => $Val)
      {
       $PhaseDsc[$i] = " {";
       $PhaseDsc[$i] .= (($Val["Heavy"]==1 ? "0" : "1") . ",&" . $Val["Uw"]) . ",";
       $PhaseDsc[$i] .= CheckRef($MultiVars,$Val["Vx"],$Val["SubClass"]) . ",";
       $PhaseDsc[$i] .= CheckRef($MultiVars,$Val["Vy"],$Val["SubClass"]) . ",";
       $PhaseDsc[$i] .= CheckRef($MultiVars,$Val["Vz"],$Val["SubClass"]) . ",";
       $PhaseDsc[$i] .= CheckRef($MultiVars,$Val["Nu"],$Val["SubClass"]) . ",";
       $PhaseDsc[$i] .= CheckRef($MultiVars,$Val["T"],$Val["SubClass"])  . ",";
       $PhaseDsc[$i] .= CheckRef($MultiVars,$Val["Ro"],$Val["SubClass"]) . ",";
       $PhaseDsc[$i++] .= '"' . $Val["Source"] . '"}';
       if ($Val["Source"]!="")
          array_push($Sources,$Key);
       if ($Val["FVars"]!="")
          array_push($PhaseFVars,$Val["FVars"]);
       if ($Val["SVars"]!="")
          array_push($PhaseFVars,$Val["SVars"]);
       if ($Val["FText"]!="")
          array_push($PhaseFText,$Val["FText"]);
       if ($Val["SText"]!="")
          array_push($PhaseFText,$Val["SText"]);
      }
    echo implode(",\n",$PhaseDsc), "\n};\n";
?>

#define sign(a) ((a) == 0 ? 0 : (a) < 0 ? -1 : +1)

void _GetLU(int NN, int * iRow, double * A, double * LU)
{
	int i, j, k;

	memmove(LU, A, NN*NN*sizeof(double));
	for (i = 0; i<NN; i++)
		iRow[i] = i;
	for (i = 0; i<NN - 1; i++)
	{
		double Big = 0.0;
		int    iBig = -1;

		double Kf;

		for (j = i; j<NN; j++)
		{
			double size = fabs(LU[iRow[j] * NN + i]);

			if (size>Big)
			{
				Big = size;
				iBig = j;
			}
		}
		if (iBig != i)
		{
			int V = iRow[i];
			iRow[i] = iRow[iBig];
			iRow[iBig] = V;
		}
		Kf = 1.0 / LU[iRow[i] * NN + i];

		LU[iRow[i] * NN + i] = Kf;
		for (j = i + 1; j<NN; j++)
		{
			double Fact = Kf*LU[iRow[j] * NN + i];

			LU[iRow[j] * NN + i] = Fact;
			for (k = i + 1; k<NN; k++)
				LU[iRow[j] * NN + k] -= Fact*LU[iRow[i] * NN + k];
		}
	}
	LU[(iRow[NN - 1] + 1)*NN - 1] = 1.0 / LU[(iRow[NN - 1] + 1)*NN - 1];
}

void _SolveLU(int NN, int * iRow, double * LU, double * Y, double * X)
{
	int i, j, k;

	X[0] = Y[iRow[0]];
	for (i = 1; i<NN; i++)
	{
		double V = Y[iRow[i]];

		for (j = 0; j<i; j++)
			V -= LU[iRow[i] * NN + j] * X[j];
		X[i] = V;
	}

	X[NN - 1] *= LU[(iRow[NN - 1] + 1)*NN - 1];

	for (i = 1, j = NN - 2; i<NN; i++, j--)
	{
		double V = X[j];

		for (k = j + 1; k<NN; k++)
			V -= LU[iRow[j] * NN + k] * X[k];
		X[j] = V*LU[iRow[j] * NN + j];
	}
}

<? if ($this->Functions!=="") echo $this->Functions;
?>

enum {rsAny, rsPositive, rsNegative};

typedef struct {
  const char * FileBase;
  signed char  Projection;
  signed char  SubClass;
  _Solver      Solver;
  char         NeedK;
  char         NeedS;
  _InitVal     _Zero;
  double *     _NuMol;
  double *     _Kappa;
  char         Phase;
  const char * Description;
  char         Restrict;
  unsigned int Flags; // BBBBBBBB xxxxxxxx xxxxxxxx xxxxxxxD
  // BBBBBBBB -- boundary level.
  // D -- fld2RF
} VarDsc;

VarDsc VDefs[NumEqs] = {
<?
    $VarDsc = array();
    for ($i=0; $i<$NumVars; $i++)
      {
       $VarDsc[$i] =  " {" . '"' . $Eqtn["FBase"][$i] . '",' . $Eqtn["Projection"][$i] . ",";
       $VarDsc[$i] .= $Eqtn["SubClass"][$i] . ",";
       $VarDsc[$i] .= $Eqtn["Solver"][$i] . "," . ($Eqtn["NeedK"][$i] ? "1" : "0") . "," . ($Eqtn["NeedS"][$i] ? "1" : "0") . "," . $Eqtn["Init"][$i] . ",";
       $VarDsc[$i] .= "&" . $Eqtn["NuMol"][$i] . ",&" . $Eqtn["Kappa"][$i] . ",";
       $VarDsc[$i] .= $idPhases[$Eqtn["DefPhase"][$i]] . ",";
       $VarDsc[$i] .= "\"" . $Eqtn["Description"][$i] . "\", rs" . $Eqtn["Restrict"][$i] . ",";
       $VarDsc[$i] .= ($Eqtn["BndLevel"][$i] ? $Eqtn["BndLevel"][$i] : "0") . "}";
      }
    echo implode(",\n",$VarDsc), "\n};\n";
?>

int PhaseLinks[NumPhases];

<?
    if ($powModify>0)
       echo "enum {ref".implode(",ref",$Modify["Substance"])."};\n\n";
?>
char * SubstRefs[MaxActSubst] = {<? echo $powModify==0 ? "NULL" : '"'.implode('","',$Modify["Substance"]).'"'; ?>};

char   SLinks[MaxActSubst] = {0};

void AddCustomVars()
{
<?
    if (count($Params)>0)
       {
        asort($Params);
        $Sect = reset($Params);
        foreach ($Params as $Key => $Val)
          {
           if (($Num = strtok($Key,"[]"))==$Key)
              $Num = 1;
           else
              $Key = strtok("");
           if ($Val != $Sect)
              {
?> AddSection<? echo "(\"".$Val."\",1);\n";
               $Sect = $Val;
              }
?> AddVar<?echo "(".($Num==1 ? "&" : "").$Key.',"'.$Key."\",fltT,";
           echo $Num==1 ? "1,1" : $Num.",0";
           echo ",1,NULL,NULL,NULL,0,1,(char) (NSect-1));\n";
          }
       }
    $SolverCounts = array_count_values($Eqtn["Solver"]);
    if ($SolverCounts["PoissonSolver"]>0)
       {
?> nPoissons = <? echo $SolverCounts["PoissonSolver"],";\n";
       }
?>
}

#ifdef __PARALLEL__
 #define OffsBuf(S) (((NZ+2)*_Num##S+1)*NX*NY)
 #define DeclareRef(S) float * S = &V[OffsBuf(S)]
 #define DeclareDn(S,i) float * S = &V[((NZ+2)*(_NumDn+i)+1)*NX*NY]
 #define DeclareUpDown(S) \
           float * DH##S = z==0   ? &V[OffsBuf(S)-NY*NX] : &S[(z-1)*NY*NX]; \
           float * UH##S = z==NZs ? &V[OffsBuf(S)+NZ*NY*NX] : &S[(z+1)*NY*NX];
#else
 #define DeclareRef(S) float * S = V->Name[_Num##S]
 #define DeclareDn(S,i) float * S = V->Dn[i]
 #define DeclareUpDown(S) \
           float * DH##S = z==0   ? &S[NZs*NY*NX] : &S[(z-1)*NY*NX]; \
           float * UH##S = z==NZs ? &S[0] : &S[(z+1)*NY*NX];
#endif

#define vector(N) for (i=0; i<N; i++)

#ifdef __MPI2REENT__
namespace UPDOWN {
  float * DH__DIV__[__NPROCS__];
  float * UH__DIV__[__NPROCS__];
};
using namespace UPDOWN;
#endif

#ifdef __PARALLEL__
void CalculateK(WKoeffs * W, float ** Bounds, float * V, float ** Kf, float ** KDn,  float ** Sf, float ** SDn, int Delta, unsigned char * Area, unsigned char * Boundaries, MapItem * Maps)
{
#else
void CalculateK(WKoeffs * W, StoreStruct * V, float ** Kf, float ** KDn, float ** Sf, float ** SDn, unsigned char * Area, unsigned char * Boundaries, MapItem * Maps)
{
 int Delta = 0;
 float ** Bounds = V->Bounds;
#endif
<?  $FTexts = array_merge($Eqtn["FText"],$Modify["FText"],$Eqtn["SText"],$Modify["SText"],$Eqtn["BText"],$Modify["BText"],$PhaseFText);
    $NumFTexts = count($FTexts);
    $FVars = array_values(array_unique(array_merge($Eqtn["FVars"],$Modify["FVars"],$Eqtn["SVars"],$Modify["SVars"],$Eqtn["BVars"],$Modify["BVars"],$PhaseFVars)));
    $NumFVars = count($FVars);
    $UsedVars = array();
    foreach ($Vars as $Key => $Val)
     if ($Eqtn["Nc"][$Key]>1)
        { ?> DeclareRef<? echo "(".$Val.");\n"; }
     else
       {
        $Found = 0;
        for ($i=0; $i<$NumFTexts && !$Found; $i++)
          if (ereg("(([^a-z0-9A-Z_])|(^))".$Val."(([^a-z0-9A-Z_])|($))",$FTexts[$i]))
             $Found = 1;
        for ($i=0; $i<$NumFVars && !$Found; $i++)
          if (ereg("(([^a-z0-9A-Z_])|(^))".$Val."(([^a-z0-9A-Z_])|($))",$FVars[$i]))
             $Found = 1;
        if ($Found)
           {
            $UsedVars[$Val] = $Eqtn["Nc"][$Key];
?> DeclareRef<? echo "(".$Val.");\n";
           }
       }
    foreach ($Sources as $Val) {
?> DeclareDn<? echo "(Source_".$Val.",PhaseLinks[".$idPhases[$Val]."]);\n";
    }
    if (is_array($Eqtn["Refs"]))
       echo ShiftStr(" ",implode("\n",$Eqtn["Refs"]));
    if (is_array($Modify["Refs"]))
       echo "\n".ShiftStr(" ",implode("\n",$Modify["Refs"]));
?>

 int i,x,zy,strata,Ptr;

 int BSize = NY*NX*(NZ-2*Delta)*sizeof(float);
 for (i=0; i<NumEqs; i++)
     {
      if (Kf[i]) memset(&(Kf[i][Delta*NY*NX]),0,BSize);
      if (Sf[i]) memset(&(Sf[i][Delta*NY*NX]),0,BSize);
     }
 for (i=0; i<NSubst; i++)
     {
      if (KDn[i]) memset(&(KDn[i][Delta*NY*NX]),0,BSize);
      if (SDn[i]) memset(&(SDn[i][Delta*NY*NX]),0,BSize);
     }
 for (strata=0; strata<=1; strata++)
  #pragma omp parallel if(UseOpenMP)
  #pragma omp for schedule(dynamic,imax(1,NY*NZ/(4*nSMP))) private(zy,x,i,Ptr)
    for (zy=Delta*NY; zy<NY*(NZ-Delta); zy++)
     {
      int z = zy/NY;
      int y = zy%NY;
#ifdef __MPI2REENT__
      DH__DIV__[__id__] = z==0   ? &DIV[NZs*NY*NX] : &DIV[(z-1)*NY*NX];
      UH__DIV__[__id__] = z==NZs ? &DIV[0] : &DIV[(z+1)*NY*NX];
#else
      float * DHDIV = z==0   ? &DIV[NZs*NY*NX] : &DIV[(z-1)*NY*NX];
      float * UHDIV = z==NZs ? &DIV[0] : &DIV[(z+1)*NY*NX];
#endif
<?
    foreach ($UsedVars as $Key => $Val)
       {
        $Found = 0;
        foreach (array_merge($FTexts,$FVars) as $Val1)
          if (strstr($Val1,"dFdz(".$Key.")")!==false ||
              strstr($Val1,"dFdzb(".$Key.")")!==false ||
              strstr($Val1,"dFdzt(".$Key.")")!==false ||
              strstr($Val1,"dFdzn(".$Key.")")!==false ||
              ereg("dRdFdz2\(".$Key.",([a-z0-9A-Z_]+)\)",$Val1,$Rdummy)!==false ||
              ereg("dRdFdz2\(([a-z0-9A-Z_]+),".$Key."\)",$Val1,$Rdummy)!==false ||
              ereg("d2NFdz2\(".$Key.",([a-z0-9A-Z_]+)\)",$Val1,$Rdummy)!==false ||
              ereg("d2NFdz2\(([a-z0-9A-Z_]+),".$Key."\)",$Val1,$Rdummy)!==false ||
              ereg("_d2Fdz2\(([a-z0-9A-Z_]+),".$Key."\)",$Val1,$Rdummy)!==false)
             {
              $Found = 1;
              break;
             }
        if ($Found)
           {
?>      DeclareUpDown<? echo "(".$Key.")\n";
           }
       }
    $MultiDerivs = array();
    foreach ($MultiVars as $Key => $Val)
       {
        $Found = 0;
        foreach (array_merge($FTexts,$FVars) as $Val1)
          if (strstr($Val1,"dFdz(".$Val."[i])")!==false ||
              strstr($Val1,"dFdzn(".$Val."[i])")!==false ||
              strstr($Val1,"d2Fdz2(".$Val."[i])")!==false ||
              ereg("dRdFdz2\(".$Key."\[i\],([a-z0-9A-Z_]+)\)",$Val1,$Rdummy)!==false ||
              ereg("dRdFdz2\(([a-z0-9A-Z_]+),".$Key."\[i\]\)",$Val1,$Rdummy)!==false)
             {
              $Found = 1;
              break;
             }
        if ($Found)
           {
            for ($i=0; $i<$MultiNums[$Key]; $i++)
              {
?>      DeclareUpDown<? echo "(".$Val.$i.")\n";
              }
            $MultiDerivs[$Val] = $MultiNums[$Key];
           }
       }
    foreach ($MultiDerivs as $Key => $Val)
      {
       $Buf = array();
       for ($i=0; $i<$Val; $i++)
           array_push($Buf,"DH".$Key.$i);
?>      float * <? echo "DH".$Key."[".$Val."] = {".implode(",",$Buf)."};\n";
       $Buf = array();
       for ($i=0; $i<$Val; $i++)
           array_push($Buf,"UH".$Key.$i);
?>      float * <? echo "UH".$Key."[".$Val."] = {".implode(",",$Buf)."};\n";
      }
?>

      for (x=(z+y+strata)&1, Ptr = zy*NX+((z+y+strata)&1); x<NX; Ptr+=2,x+=2)
          if (Area[Ptr]!=1)
              {
<?
    if (!function_exists("ProcessDefinitions")) {
       function ProcessDefinitions(&$Arr,$NArr,$SV,$RV,$SD,$RD) {
         for ($i=0; $i<$NArr; $i++)
           {
            $Arr[$i] = ereg_replace($SV,$RV,$Arr[$i]);
            $Arr[$i] = ereg_replace($SD,$RD,$Arr[$i]);
           }
       }
    }
    
    foreach (array_merge(array_keys($UsedVars),$AdditionalVars) as $Key => $Val)
      {
       $SearchVarPtrn  = "(([^a-z0-9A-Z_])|(^))".$Val."(([^a-z0-9A-Z_])|($))";
       $ReplaceVarPtrn = "\\1".$Val."[Ptr]\\4";
       $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))d2?Fd[xyz][2nrlbft]?)\(".$Val."\[Ptr\]\)";
       $ReplaceDrvPtrn = "\\1(".$Val.")";
       ProcessDefinitions($FVars,$NumFVars,$SearchVarPtrn,$ReplaceVarPtrn,$SearchDrvPtrn,$ReplaceDrvPtrn);
       ProcessDefinitions($FTexts,$NumFTexts,$SearchVarPtrn,$ReplaceVarPtrn,$SearchDrvPtrn,$ReplaceDrvPtrn);
       $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))dRdFd[xyz]2)\(".$Val."\[Ptr\](,[^\)]+)\)";
       $ReplaceDrvPtrn = "\\1(".$Val."\\5)";
       ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))dRdFd[xyz]2)\(([^\)]+,)".$Val."\[Ptr\]\)";
       $ReplaceDrvPtrn = "\\1(\\5".$Val.")";
       ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))_d2?Fd[xyz]2?)\(([^\)]+,)".$Val."\[Ptr\]\)";
       $ReplaceDrvPtrn = "\\1(\\5".$Val.")";
       ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))d2NFd[xyz]2)\(".$Val."\[Ptr\](,[^\)]+)\)";
       $ReplaceDrvPtrn = "\\1(".$Val."\\5)";
       ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))d2NFd[xyz]2)\(([^\)]+,)".$Val."\[Ptr\]\)";
       $ReplaceDrvPtrn = "\\1(\\5".$Val.")";
       ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
       $SearchFPtrn  = "((([^a-z0-9A-Z_])|(^))IsClosed)\(".$Val."\[Ptr\]\)";
       $ReplaceFPtrn = "\\1(".$Val.")";
       ProcessDefinitions($FVars,$NumFVars,$SearchFPtrn,$ReplaceFPtrn,"a","a");
       ProcessDefinitions($FTexts,$NumFTexts,$SearchFPtrn,$ReplaceFPtrn,"a","a");
       $SearchFPtrn  = "((([^a-z0-9A-Z_])|(^))IsCond)\(".$Val."\[Ptr\],([a-z0-9A-Z])\)";
       $ReplaceFPtrn = "\\1(".$Val.",'\\5')";
       ProcessDefinitions($FVars,$NumFVars,$SearchFPtrn,$ReplaceFPtrn,"a","a");
       ProcessDefinitions($FTexts,$NumFTexts,$SearchFPtrn,$ReplaceFPtrn,"a","a");
      }
    if (is_array($MultiVars))
       foreach ($MultiVars as $Key => $Val)
         {
          $SearchVarPtrn  = "(([^a-z0-9A-Z_])|(^))".$Val."\[([^]]+)]";
          $ReplaceVarPtrn = "\\1".$Val."[\\4][Ptr]";
          $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))d2?Fd[xyz][2nrlbft]?)\(".$Val."\[([^]]+)]\[Ptr\]\)";
          $ReplaceDrvPtrn = "\\1(".$Val."[\\5])";
          ProcessDefinitions($FVars,$NumFVars,$SearchVarPtrn,$ReplaceVarPtrn,$SearchDrvPtrn,$ReplaceDrvPtrn);
          ProcessDefinitions($FTexts,$NumFTexts,$SearchVarPtrn,$ReplaceVarPtrn,$SearchDrvPtrn,$ReplaceDrvPtrn);
          $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))dRdFd[xyz]2)\(".$Val."\[([^]]+)]\[Ptr\](,[^\)]+)\)";
          $ReplaceDrvPtrn = "\\1(".$Val."[\\5]\\6)";
          ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))dRdFd[xyz]2)\(([^\)]+,)".$Val."\[([^]]+)]\[Ptr\]\)";
          $ReplaceDrvPtrn = "\\1(\\5".$Val."[\\6])";
          ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))_d2Fd[xyz]2)\(([^\)]+,)".$Val."\[([^]]+)]\[Ptr\]\)";
          $ReplaceDrvPtrn = "\\1(\\5".$Val."[\\6])";
          ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))d2NFd[xyz]2)\(".$Val."\[([^]]+)]\[Ptr\](,[^\)]+)\)";
          $ReplaceDrvPtrn = "\\1(".$Val."[\\5]\\6)";
          ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          $SearchDrvPtrn  = "((([^a-z0-9A-Z_])|(^))d2NFd[xyz]2)\(([^\)]+,)".$Val."\[([^]]+)]\[Ptr\]\)";
          $ReplaceDrvPtrn = "\\1(\\5".$Val."[\\6])";
          ProcessDefinitions($FVars,$NumFVars,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          ProcessDefinitions($FTexts,$NumFTexts,$SearchDrvPtrn,$ReplaceDrvPtrn,"a","a");
          $SearchFPtrn  = "((([^a-z0-9A-Z_])|(^))IsClosed)\(".$Val."\[([^]]+)]\[Ptr\]\)";
          $ReplaceFPtrn = "\\1(".$Val."[\\5])";
          ProcessDefinitions($FVars,$NumFVars,$SearchFPtrn,$ReplaceFPtrn,"a","a");
          ProcessDefinitions($FTexts,$NumFTexts,$SearchFPtrn,$ReplaceFPtrn,"a","a");
          $SearchFPtrn  = "((([^a-z0-9A-Z_])|(^))IsCond)\(".$Val."\[([^]]+)]\[Ptr\],([a-z0-9A-Z])\)";
          $ReplaceFPtrn = "\\1(".$Val."[\\5],'\\6')";
          ProcessDefinitions($FVars,$NumFVars,$SearchFPtrn,$ReplaceFPtrn,"a","a");
          ProcessDefinitions($FTexts,$NumFTexts,$SearchFPtrn,$ReplaceFPtrn,"a","a");
         }
    if (!function_exists("InlineExplode")) {
       function InlineExplode($Text,$FName,$Prefix,$Infix,$Postfix) {
         while (ereg("(([^a-z0-9A-Z_])|(^))".$FName."\{([^,]+),([^,]+),([^;}]+)(\;([a-zA-Z0-9_]+))?\}",$Text,$Regs))
           {
            $R = array();
            $From = (int) eval("return ".$Regs[4].";");
            $To = eval("return ".$Regs[5].";");
            $Idx = (trim($Regs[8]) === "") ? "i" : $Regs[8];
            for ($j = $From; $j <= $To; $j++)
                array_push($R,
                  "(".
                  ereg_replace("(([^a-z0-9A-Z_])|(^))".$Idx."(([^a-z0-9A-Z_])|(^))","\\1".$j."\\4",$Regs[6]).
                  ")");
            $Text = str_replace($Regs[0],$Regs[1].sprintf($Prefix,$To-$From+1).implode($Infix,$R).$Postfix,$Text);
           }
         return $Text;
       }
    }
    if (!function_exists("InlineFunctions")) {
       function InlineFunctions(&$Arr,$NArr) {
         for ($i=0; $i<$NArr; $i++)
           {
            $Arr[$i] = InlineExplode($Arr[$i],"Sum","(","+",")");
            $Arr[$i] = InlineExplode($Arr[$i],"Min","min%u(",",(double)",")");
            $Arr[$i] = InlineExplode($Arr[$i],"Max","max%u(",",(double)",")");
            $Arr[$i] = ereg_replace("(([^a-z0-9A-Z_])|(^))Split\{([^,]+),([^}]+)\}",
                                    "\\1((FastMode ? (\\4) : 0.0)+(SlowMode ? (\\5) : 0.0))",
                                    $Arr[$i]);
            $Arr[$i] = str_replace("[Ptr][up]","[ZPYX]",$Arr[$i]);
            $Arr[$i] = str_replace("[Ptr][down]","[ZMYX]",$Arr[$i]);
            $Arr[$i] = str_replace("[Ptr][left]","[ZYXM]",$Arr[$i]);
            $Arr[$i] = str_replace("[Ptr][right]","[ZYXP]",$Arr[$i]);
            $Arr[$i] = str_replace("[Ptr][forw]","[ZYPX]",$Arr[$i]);
            $Arr[$i] = str_replace("[Ptr][back]","[ZYMX]",$Arr[$i]);
           }
       }
    }
    InlineFunctions($FVars,$NumFVars);
    InlineFunctions($FTexts,$NumFTexts);
    /* Исключаем повторяющиеся декларации (полексемное сравнение) */
    $SplittedFVars = explode(";",implode("\n",$FVars));
    $TokenizedFVars = array();
    foreach ($SplittedFVars as $Key => $Val)
      {
       $Tokenized = "";
       $Val = ereg_replace("/\*.*\*/","",$Val);
       $Token = strtok($Val," \n\t");
       while ($Token)
         $Tokenized .= ($Token = strtok(" \n\t"));
       $TokenizedFVars[$Key] = $Tokenized;
      }
    asort($TokenizedFVars);
    $FVal = reset($TokenizedFVars);
    $FKey = key($TokenizedFVars);
    while (list($Key, $Val) = each ($TokenizedFVars))
      if ($Val==$FVal)
         if ((int) $FKey < (int) $Key)
            $TokenizedFVars[$Key] = "";
         else
            {
             $TokenizedFVars[$FKey] = "";
             $FKey = $Key;
            }
      else
         {
          $FKey = $Key;
          $FVal = $Val;
         }
    foreach ($TokenizedFVars as $Key => $Val)
      if ($Val=="") unset($SplittedFVars[$Key]);
    if (count($SplittedFVars))
       {
        reset($SplittedFVars);
        $FIRST = each($SplittedFVars);
        $SplittedFVars[$FIRST[0]] = "\n" . $FIRST[1];
       }
    /* Разделяем декларации на деклараторы и присваивания */
    $Declarators = array();
    foreach ($SplittedFVars as $Key => $Val)
      {
       for ($i = 0; $i<strlen($Val) && ($Val[$i]=="\n" || $Val[$i]=="\t" || $Val[$i]==" "); $i++);
       $Prefix = substr($Val,0,$i);
       $tok = strtok(substr($Val,$i),"() \n\t");
       if ($tok=="vector")
          {
           $VNum = strtok("()");
           $VName = strtok("[] =\n\t");
           array_push($Declarators,"\ndouble ".$VName."[".$VNum."]");
          }
       else
          {
           $SplittedFVars[$Key] = $Prefix . strtok("");
           $Type = strtok($Val,"() \n\t");
           $Name = strtok(" =\n\t");
           array_push($Declarators,"\n".$Type." ".$Name);
          }
      }
    /* Собираем имена переменных */
    $Names = array();
    $Keys = array();
    $Links = array(); /* Прямые связи */
    $RLinks = array(); /* Обратные связи */
    foreach ($SplittedFVars as $Key => $Val)
      {
       $Name = strtok($Val,"() =\n\t");
       if ($Name=="vector")
          {
           $Num = strtok("()");
           $Name = strtok("[] =\n\t");
          }
       $Names[$Key] = $Name;
       $Keys[$Name] = $Key;
       $RLinks[$Name] = array();
      }
    /* Сортируем декларации по зависимостям */
    foreach ($SplittedFVars as $Key => $Val)
      {
       $Name = $Names[$Key];
       $Link = array();
       foreach ($SplittedFVars as $Key1 => $Val1)
         {
          $Name1 = $Names[$Key1];
          if ($Key!=$Key1)
             if (ereg("(([^a-z0-9A-Z_])|(^))".$Name."(([^a-z0-9A-Z_])|($))",$Val1,$Regs))
                {
                 array_push($Link,$Name1);
                 array_push($RLinks[$Name1],$Name);
                }
         }
       $Links[$Name] = $Link;
      }
    $OutFVars = array();
    while (count($SplittedFVars))
      {
       /* Собираем фронт из узлов, на которые нет обратных ссылок */
       /* Это узлы, зависящие только от уже проработанных узлов */
       /* из предыдущих фронтов или исходно независимые. */
       $Front = array();
       foreach ($RLinks as $Key => $Val)
         if (count($Val)==0 && isset($SplittedFVars[$Keys[$Key]]))
            {
             $Front[$Keys[$Key]] = $SplittedFVars[$Keys[$Key]];
             unset($SplittedFVars[$Keys[$Key]]);
            }
       /* Уничтожаем обратные ссылки на узел, вошедший во фронт */
       foreach ($Front as $Key => $Val)
         {
          $Key = $Names[$Key];
          foreach ($Links[$Key] as $Val1)
            foreach ($RLinks[$Val1] as $Key2 => $Val2)
              if ($Key==$Val2)
                 {
                  unset($RLinks[$Val1][$Key2]);
                  break;
                 }
         }
       ksort($Front);
       $OutFVars = array_merge($OutFVars,$Front);
       if (count($Front) == 0 && count($SplittedFVars) > 0) {
          echo "--------------------\n";
          echo ShiftStr("               ",implode(";",$SplittedFVars)),";\n";
          echo "--------------------\n";
          MakeError("Model Error: ","Circular references in the above ----------marked---------- block!",__LINE__);
          break;
       }
      }
    if (count($Declarators))
       echo ShiftStr("               ",implode(";",$Declarators)),";\n\n";
    if (count($OutFVars))
       echo ShiftStr("               ",implode(";",$OutFVars)),";\n\n";
    if (count($FTexts))
       echo ShiftStr("               ",implode("\n",$FTexts)),"\n";
?>
              }
     }
 #if defined(__IMITATE__) && !defined(WIN32)
   Check();
 #endif
}

<?
    break;
  case stDone:
?>#endif
<?
}
?>
