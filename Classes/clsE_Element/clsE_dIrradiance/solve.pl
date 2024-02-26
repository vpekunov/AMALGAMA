solve(ID,Phase,Solver):-
  element(ID,'clsE_dIrradiance',_,_),
  !,
  show(ID,Class,Name,Image),
  position(ID,Left,Top),
  =(TopBase,Top),
  =(LeftBase,Left),
  Left1 is Left-20,
  asserta(counter(Left1,Top)),
  i_contact(ID,'Phase'),
  i_link(ID,'Phase',PhaseID,PhaseCID,_),
  o_link(PhaseID,PhaseCID,ID,'Phase',ColorI,_,_,_),
  o_contact(ID,'Solver'),
  o_link(ID,'Solver',SolverID,SolverCID,ColorO,_,_,_),
  i_link(SolverID,SolverCID,ID,'Solver',_),
  i_contact(ID,'Drops'),
  (
   i_link(ID,'Drops',DropsID,DropsCID,_) ->
     o_link(DropsID,DropsCID,ID,'Drops',ColorD,_,_,_);
     =(ColorD,'clYellow')
  ),
  expand_irradiances(ID,Class,Name,Image,ColorI,ColorO,ColorD,PhaseID,PhaseCID,SolverID,SolverCID,LeftBase,TopBase),
  retractall(counter(_,_)),
  delete_element(ID),
  =(Solver,'null').

expand_irradiances(ID,Class,Name,Image,ColorI,ColorO,ColorD,PhaseID,PhaseCID,SolverID,SolverCID,LeftBase,TopBase):-
  irradiance(ID,Prefix,RangeName),
  =(VarID,RangeName),
  =(FBase,Prefix),
  atom_concat('Eq',VarID,EqID),
  counter(Left,Top),
  retractall(counter(_,_)),
  LeftNext is Left+10,
  TopNext is Top+220,
  asserta(counter(LeftNext,TopNext)),
  atom_concat('Интенсивность ',RangeName,V), atom_concat(V,'-диффузного излучения',Desc),
  insert_element(VarID,'clsE_Var',Class,Name,Image,Left,Top,['Desc','FBase'],[Desc,FBase],['Phase'],['Calc']),
  LeftEq is LeftBase+220,
  insert_element(EqID,'clsE_PoissonEquation',Class,Name,Image,LeftEq,Top,[],[],['K','S','Calc','Bound'],['Solver']),
  LeftK is Left+90, TopK is Top+20,
  LeftB is Left+100, TopB is Top+40,
  LeftS is Left+110, TopS is Top+60,
  atom_concat('K_',VarID,KID),
  atom_concat('B_',VarID,BID),
  atom_concat('S_',VarID,SID),
  atom_concat('F',RangeName,VarFID),
  atom_concat('K_',VarFID,KFID),
  atom_concat('S_',VarFID,SFID),
  atom_concat('EqF',VarID,EqFID),
  (predicate_property(thermal(_,_),'dynamic'),thermal(ID,RangeName) ->
    (
     (
      predicate_property(temperature(_),'dynamic'), temperature(TID) ->
       str_replace('"double TK = 273.15+$2;","double $1kAlbAsm = $1kAlbedo*$1kAsymm;","double $1tAlpha = $1eBeta*(1-$1kAlbedo);","double $1tBeta = $1eBeta*(1-$1kAlbAsm);","double $1Planck = (@[]IntPlanck[0]+TK*(@IntPlanck[1]+TK*(@IntPlanck[2]+TK*@IntPlanck[3])));","double $1Ft = 3.0*$1tAlpha*$1Planck;"',[Prefix,TID],VarsK0);
       str_replace('"double TK = 273.15+DefaultT;","double $1kAlbAsm = $1kAlbedo*$1kAsymm;","double $1tAlpha = $1eBeta*(1-$1kAlbedo);","double $1tBeta = $1eBeta*(1-$1kAlbAsm);","double $1Planck = (@[]IntPlanck[0]+TK*(@IntPlanck[1]+TK*(@IntPlanck[2]+TK*@IntPlanck[3])));","double $1Ft = 3.0*$1tAlpha*$1Planck;"',[Prefix],VarsK0)
     ),
     convert_string_list(VarsK0, VarsK),
     str_replace('"Split{0.0,-$1Ft*$1tBeta};"',[Prefix],ExprK0),
     convert_string_list(ExprK0, ExprK),
     str_replace('"double $1k1 = 2.0/3.0/$1tBeta;","double $1k1a = $1k1*(2.0-@SurfaceEmissivity);","double $1FluxPi = @$1DiffuseFlux/Pi;"',[Prefix],VarsB0),
     convert_string_list(VarsB0, VarsB),
     str_replace('"      if (IsClosed($2))","        {","         if (IsForw)   _fw($2) = ($1k1a*$2[back]+HY[y-1]*@SurfaceEmissivity*(@[]IntPlanck[0]+(273.15+_fw($3))*(@IntPlanck[1]+(273.15+_fw($3))*(@IntPlanck[2]+(273.15+_fw($3))*@IntPlanck[3])))/Pi)/($1k1a+HY[y-1]*@SurfaceEmissivity);","         if (IsBack)   _bw($2) = ($1k1a*$2[forw]+HY[y]*  @SurfaceEmissivity*(@[]IntPlanck[0]+(273.15+_bw($3))*(@IntPlanck[1]+(273.15+_bw($3))*(@IntPlanck[2]+(273.15+_bw($3))*@IntPlanck[3])))/Pi)/($1k1a+HY[y]*@SurfaceEmissivity);","         if (IsBottom) _bt($2) = ($1k1a*$2[up]+HZ[z]*    @SurfaceEmissivity*(@[]IntPlanck[0]+(273.15+_bt($3))*(@IntPlanck[1]+(273.15+_bt($3))*(@IntPlanck[2]+(273.15+_bt($3))*@IntPlanck[3])))/Pi)/($1k1a+HZ[z]*@SurfaceEmissivity);","         if (IsTop)    _tp($2) = ($1k1a*$2[down]+HZ_ZM*  @SurfaceEmissivity*(@[]IntPlanck[0]+(273.15+_tp($3))*(@IntPlanck[1]+(273.15+_tp($3))*(@IntPlanck[2]+(273.15+_tp($3))*@IntPlanck[3])))/Pi)/($1k1a+HZ_ZM*@SurfaceEmissivity);","         if (IsLeft)   _lf($2) = ($1k1a*$2[right]+HX[x]* @SurfaceEmissivity*(@[]IntPlanck[0]+(273.15+_lf($3))*(@IntPlanck[1]+(273.15+_lf($3))*(@IntPlanck[2]+(273.15+_lf($3))*@IntPlanck[3])))/Pi)/($1k1a+HX[x]*@SurfaceEmissivity);","         if (IsRight)  _rg($2) = ($1k1a*$2[left]+HX[x-1]*@SurfaceEmissivity*(@[]IntPlanck[0]+(273.15+_rg($3))*(@IntPlanck[1]+(273.15+_rg($3))*(@IntPlanck[2]+(273.15+_rg($3))*@IntPlanck[3])))/Pi)/($1k1a+HX[x-1]*@SurfaceEmissivity);","        }","      else","        {","         if (IsForw)   _fw($2) = ($1k1*$2[back]+HY[y-1]*$1FluxPi)/($1k1+HY[y-1]);","         if (IsBack)   _bw($2) = ($1k1*$2[forw]+HY[y]*$1FluxPi)/($1k1+HY[y]);","         if (IsBottom) _bt($2) = ($1k1*$2[up]+HZ[z]*$1FluxPi)/($1k1+HZ[z]);","         if (IsTop)    _tp($2) = ($1k1*$2[down]+HZ_ZM*$1FluxPi)/($1k1+HZ_ZM);","         if (IsLeft)   _lf($2) = ($1k1*$2[right]+HX[x]*$1FluxPi)/($1k1+HX[x]);","         if (IsRight)  _rg($2) = ($1k1*$2[left]+HX[x-1]*$1FluxPi)/($1k1+HX[x-1]);","        }"',[Prefix,VarID,TID],ExprB0),
     convert_string_list(ExprB0, ExprB)
    );
    (
     str_replace('"double Pi = 3.1415926535897932;","double $1kAlbAsm = $1kAlbedo*$1kAsymm;","double $1tAlpha = $1eBeta*(1-$1kAlbedo);","double $1tBeta = $1eBeta*(1-$1kAlbAsm);","double $1_Ft = 3.0*$1eBeta*$1kAlbedo/4.0/Pi;","double $1Ft = $1_Ft*$2;"',[Prefix,VarFID],VarsK0),
     convert_string_list(VarsK0, VarsK),
     str_replace('"Split{0.0,-$1Ft*$1tBeta};"',[Prefix],ExprK0),
     convert_string_list(ExprK0, ExprK),
     str_replace('"double $1k1 = 2.0/3.0/$1tBeta;","double $1k1a = $1k1*(1+@SurfaceAlbedo);","double $1FluxPi = @$1DiffuseFlux/Pi;"',[Prefix],VarsB0),
     convert_string_list(VarsB0, VarsB),
     str_replace('"      if (IsClosed($2))","        {","         if (IsForw)   _fw($2) = ($1k1a*$2[back]+HY[y-1]*SolarY*_fw($3)*@SurfaceAlbedo/Pi)/($1k1a+HY[y-1]*(1-@SurfaceAlbedo));","         if (IsBack)   _bw($2) = ($1k1a*$2[forw]-HY[y]*SolarY*  _bw($3)*@SurfaceAlbedo/Pi)/($1k1a+HY[y]*(1-@SurfaceAlbedo));","         if (IsBottom) _bt($2) = ($1k1a*$2[up]-HZ[z]*SolarZ*  _bt($3)*@SurfaceAlbedo/Pi)/($1k1a+HZ[z]*(1-@SurfaceAlbedo));","         if (IsTop)    _tp($2) = ($1k1a*$2[down]+HZ_ZM*SolarZ*  _tp($3)*@SurfaceAlbedo/Pi)/($1k1a+HZ_ZM*(1-@SurfaceAlbedo));","         if (IsLeft)   _lf($2) = ($1k1a*$2[right]-HX[x]*SolarX*  _lf($3)*@SurfaceAlbedo/Pi)/($1k1a+HX[x]*(1-@SurfaceAlbedo));","         if (IsRight)  _rg($2) = ($1k1a*$2[left]+HX[x-1]*SolarX*_rg($3)*@SurfaceAlbedo/Pi)/($1k1a+HX[x-1]*(1-@SurfaceAlbedo));","        }","      else","        {","         if (IsForw)   _fw($2) = ($1k1*$2[back]+HY[y-1]*$1FluxPi)/($1k1+HY[y-1]);","         if (IsBack)   _bw($2) = ($1k1*$2[forw]+HY[y]*$1FluxPi)/($1k1+HY[y]);","         if (IsBottom) _bt($2) = ($1k1*$2[up]+HZ[z]*$1FluxPi)/($1k1+HZ[z]);","         if (IsTop)    _tp($2) = ($1k1*$2[down]+HZ_ZM*$1FluxPi)/($1k1+HZ_ZM);","         if (IsLeft)   _lf($2) = ($1k1*$2[right]+HX[x]*$1FluxPi)/($1k1+HX[x]);","         if (IsRight)  _rg($2) = ($1k1*$2[left]+HX[x-1]*$1FluxPi)/($1k1+HX[x-1]);","        }"',[Prefix,VarID,VarFID],ExprB0),
     convert_string_list(ExprB0, ExprB),
     TopF is Top+110,
     atom_concat('Интенсивность ',RangeName,VV), atom_concat(VV,'-прямого солнечного излучения',FDesc),
     atom_concat('f',FBase,FFBase),
     insert_element(EqFID,'clsE_SolarEquation',Class,Name,Image,LeftEq,TopF,[],[],['K','S','Calc'],['Solver']),
     insert_element(VarFID,'clsE_Var',Class,Name,Image,Left,TopF,['Desc','FBase'],[FDesc,FFBase],[],['Calc']),
     insert_link(PhaseID,PhaseCID,VarFID,'Phase',ColorI),
     insert_link(VarFID,'Calc',EqFID,'Calc','clBlack'),
     insert_link(EqFID,'Solver',SolverID,SolverCID,ColorO),
     LeftKF is Left+90, TopKF is TopF+20,
     LeftSF is Left+110, TopSF is TopF+40,
     str_replace('$1eBeta;',[Prefix],ExprKF),
     insert_element(KFID,'clsE_Function',Class,Name,Image,LeftKF,TopKF,['Expression'],[ExprKF],['Phase'],['Val']),
     str_replace('@$1SolarIntensity;',[Prefix],ExprSF),
     insert_element(SFID,'clsE_Function',Class,Name,Image,LeftSF,TopSF,['Expression'],[ExprSF],['Phase'],['Val']),
     insert_link(KFID,'Val',EqFID,'K','clBlack'),
     insert_link(SFID,'Val',EqFID,'S','clYellow')
    )
  ),
  (i_link(ID,'Drops',DropsID,DropsCID,_) ->
     str_replace('"vector $1ieC0[i] = @[]$1QeC0{Drops}[i];","vector $1ieC1[i] = @[]$1QeC1{Drops}[i]*1E6;","vector $1ieC2[i] = @[]$1QeC2{Drops}[i]*1E12;","vector $1ieC3[i] = @[]$1QeC3{Drops}[i]*1E18;","vector $1ieC4[i] = @[]$1QeC4{Drops}[i]*1E24;","vector $1ieC5[i] = @[]$1QeC5{Drops}[i]*1E30;","vector $1iaC0[i] = @[]$1QaC0{Drops}[i];","vector $1iaC1[i] = @[]$1QaC1{Drops}[i]*1E6;","vector $1iaC2[i] = @[]$1QaC2{Drops}[i]*1E12;","vector $1iaC3[i] = @[]$1QaC3{Drops}[i]*1E18;","vector $1iaC4[i] = @[]$1QaC4{Drops}[i]*1E24;","vector $1iaC5[i] = @[]$1QaC5{Drops}[i]*1E30;","vector $1igC0[i] = @[]$1gC0{Drops}[i];","vector $1igC1[i] = @[]$1gC1{Drops}[i]*1E6;","vector $1igC2[i] = @[]$1gC2{Drops}[i]*1E12;","vector $1igC3[i] = @[]$1gC3{Drops}[i]*1E18;","vector $1igC4[i] = @[]$1gC4{Drops}[i]*1E24;","vector $1igC5[i] = @[]$1gC5{Drops}[i]*1E30;",,"vector $1iBeta[i] = Split{0.0,EMPTY[i] ? 0.0 :","                    Pi/4.0*","                      (","                       An[i]*($1ieC0[i]*XY4[i]+$1ieC1[i]*XY5[i]+$1ieC2[i]*XY6[i]+$1ieC3[i]*XY7[i]+$1ieC4[i]*XY8[i]+$1ieC5[i]*XY9[i])+","                       Bn[i]*($1ieC0[i]*XY3[i]+$1ieC1[i]*XY4[i]+$1ieC2[i]*XY5[i]+$1ieC3[i]*XY6[i]+$1ieC4[i]*XY7[i]+$1ieC5[i]*XY8[i])","                      )","                  };","vector $1iAbs[i] = Split{0.0,EMPTY[i] ? 0.0 :","                    Pi/4.0*","                      (","                       An[i]*($1iaC0[i]*XY4[i]+$1iaC1[i]*XY5[i]+$1iaC2[i]*XY6[i]+$1iaC3[i]*XY7[i]+$1iaC4[i]*XY8[i]+$1iaC5[i]*XY9[i])+","                       Bn[i]*($1iaC0[i]*XY3[i]+$1iaC1[i]*XY4[i]+$1iaC2[i]*XY5[i]+$1iaC3[i]*XY6[i]+$1iaC4[i]*XY7[i]+$1iaC5[i]*XY8[i])","                      )","                 };","vector $1iAsym[i] = Split{0.0,EMPTY[i] ? 0.0 :","                      (","                       An[i]*($1igC0[i]*XY2[i]+$1igC1[i]*XY3[i]+$1igC2[i]*XY4[i]+$1igC3[i]*XY5[i]+$1igC4[i]*XY6[i]+$1igC5[i]*XY7[i])+","                       Bn[i]*($1igC0[i]*XY1[i]+$1igC1[i]*XY2[i]+$1igC2[i]*XY3[i]+$1igC3[i]*XY4[i]+$1igC4[i]*XY5[i]+$1igC5[i]*XY6[i])","                      )/Nk[i]","                   };","vector $1iAlbedo[i] = Split{0.0,EMPTY[i] ? 0.0 : ($1iBeta[i]-$1iAbs[i])/$1iBeta[i]};","double $1eBeta = @$1AirBeta+Sum{$1iBeta[i]};","double $1eScat = @$1AirAlbedo*@$1AirBeta+Sum{$1iAlbedo[i]*$1iBeta[i]};","double $1kAlbedo = $1eScat/$1eBeta;","double $1kAsymm = (@$1AirAlbedo*@$1AirBeta*@$1AirAsymmetry+Sum{$1iAlbedo[i]*$1iBeta[i]*$1iAsym[i]})/$1eScat;"',[Prefix],DropsK0);
     str_replace('"double $1eBeta = @$1AirBeta;","double $1eScat = @$1AirAlbedo*@$1AirBeta;","double $1kAlbedo = @$1AirAlbedo;","double $1kAsymm = @$1AirAsymmetry;"',[Prefix],DropsK0)
  ),
  convert_string_list(DropsK0, DropsK),
  (predicate_property(temperature(_),'dynamic'),temperature(TID) ->
    (
     atom_concat(RangeName,'_',Part1), atom_concat(Part1,TID,KTID),
     str_replace('"double TK = 273.15+$1;","double RO0 = 352.984/TK;","double CC0 = 1.4*(718+0.1167*RO0);"',[TID],VarsKT0),
     convert_string_list(VarsKT0, VarsKT),
     o_link(TID,'Calc',EqTID,_,_,_,_,_),
     position(EqTID,LeftT,TopT),
     LeftKT is LeftT-140+Left-LeftBase,
     TopKT is round(TopT+(Top-TopBase)/200*20),
     (
      predicate_property(thermal(_,_),'dynamic'),thermal(ID,RangeName) ->
       str_replace('"Split{0.0,4.0*Pi*($1tAlpha*$2-$1Ft/3.0)/RO0/CC0};"',[Prefix,VarID],ExprKT0);
       str_replace('"Split{0.0,$1tAlpha*(4.0*Pi*$2+$3)/RO0/CC0};"',[Prefix,VarID,VarFID],ExprKT0)
     ),
     convert_string_list(ExprKT0, ExprKT),
     insert_element(KTID,'clsE_Function',Class,Name,Image,LeftKT,TopKT,['Vars','Expression'],[VarsKT,ExprKT],['Phase'],['Val']),
     insert_link(KTID,'Val',EqTID,'K','clBlack')
    );
    true
  ),
  atom_concat(DropsK,',',VarsK_add),
  atom_concat(VarsK_add,VarsK,VarsK_full),
  insert_element(KID,'clsE_Function',Class,Name,Image,LeftK,TopK,['Vars','Expression'],[VarsK_full,ExprK],['Phase'],['Val']),
  insert_element(BID,'clsE_Function',Class,Name,Image,LeftB,TopB,['Vars','Expression'],[VarsB,ExprB],['Phase'],['Val']),
  str_replace('"Split{0.0,3.0*$1tAlpha*$1tBeta};"',[Prefix],ExprS0),
  convert_string_list(ExprS0, ExprS),
  insert_element(SID,'clsE_Function',Class,Name,Image,LeftS,TopS,['Vars','Expression'],[VarsK_full,ExprS],['Phase'],['Val']),
  insert_link(VarID,'Calc',EqID,'Calc','clBlack'),
  insert_link(KID,'Val',EqID,'K','clBlack'),
  insert_link(SID,'Val',EqID,'S','clYellow'),
  insert_link(DropsID,DropsCID,KID,'Phase',ColorD),
  insert_link(DropsID,DropsCID,SID,'Phase',ColorD),
  insert_link(BID,'Val',EqID,'Bound','#FF8080'),
  insert_link(PhaseID,PhaseCID,VarID,'Phase',ColorI),
  insert_link(EqID,'Solver',SolverID,SolverCID,ColorO),
  fail.
expand_irradiances(_,_,_,_,_,_,_,_,_,_,_,_,_):-
  !.
