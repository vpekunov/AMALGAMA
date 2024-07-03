<?php
$Num = $In["Number"];
switch ($Stage) {
  case stResource:
    echo "N = ", $Num, ";\n";
    echo "Ls = {", implode(";",$In["Handle"]), "};\n";
    echo "Kinds = '", implode("",$In["Kinds"]), "';\n";
    echo "Axes = [", implode(",",$In["Axes"]), "];\n";
    echo "Vars = {", implode(";",$In["Vars"]), "};\n";
    echo "sVars = {", implode(";",$In["sVars"]), "};\n";
    echo "dVars = {", implode(";",$In["dVars"]), "};\n";
    echo "moving = [", implode(";",$In["Moving"]), "];\n";
    echo "L = {", implode(";",$In["L"]), "};\n";
    echo "P = {", implode(";",$In["P"]), "};\n";
    echo "m = {", implode(";",$In["M"]), "};\n";
    echo "j = {", implode(";",$In["J"]), "};\n";
    echo "g = 9.81;\n";
    break;
  case stCall:
?>

T = sym(eye(4));

Wp = sym('0');
Wk = sym('0');
W  = sym(zeros(4,1));

k = 1;
for i=1:N
    if Kinds(i)=='l' & i>1
       A = sym(eye(4));
       if moving(i)
          A(Axes(i),4) = [Vars{i} '-' 'Sum' L{i} P{i}];
       else
          A(Axes(i),4) = P{i};
       end;
       W1 = sym(zeros(4,1));
       if Kinds(i-1)=='r'
          W1(Axes(i-1)) = diff(Vars{i-1},'t');
       end;
       W = simple(W+T*W1);
       Omega = simple(inv(T)*W);
       A  = simple(T*A*[0;0;0;1]);
       Wp = Wp+sym([m{i} '*g'])*A(3);
       V  = simple(diff(A,'t'));
       V2 = simple(sum(V.^2));
       Omega2 = simple(sum(Omega.^2));
       Wk = Wk+sym(m{i})*V2/2+sym(j{i})*Omega2/2;
       k  = k+1;
    end;
    if (i~=N); T = T*subs(eval(['T' '0'+i]),sVars{i},Vars{i},0); end;
end;

k = k-1;

qVars = cell(k,1);
for i=1:k
  qVars{i} = ['Q' '0'+i];
end;

Wp = simple(Wp);
Wk = simple(Wk);

dWp  = sym(zeros(k,1));
dWk  = sym(zeros(k,1));
dWk2 = sym(zeros(k,1));
F = sym(zeros(k,1));

for i=1:k
  Wp = sym(subs(Wp,['diff(' dVars{i} ',t)'],['d' qVars{i} '(' qVars{i} ')'],0));
  Wp = sym(subs(Wp,dVars{i},qVars{i},0));
  Wk = sym(subs(Wk,['diff(' dVars{i} ',t)'],['d' qVars{i} '(' qVars{i} ')'],0));
  Wk = sym(subs(Wk,dVars{i},qVars{i},0));
end;

Wk1 = Wk;
for i=1:k
  Wk1 = sym(subs(Wk1,['d' qVars{i} '(' qVars{i} ')'],['d' qVars{i}],0));
end;

for i=1:k
  dWp(i)  = sym(simple(diff(Wp,sym(qVars{i}))));
  dWk(i)  = sym(simple(diff(Wk,sym(qVars{i}))));
  dWk2(i) = sym(simple(diff(Wk1,sym(['d' qVars{i}]))));
end;

for i=1:k
  dWp  = sym(subs(dWp,['diff(d' qVars{i} '(' qVars{i} '),' qVars{i} ')'],['0'],0));
  dWp  = sym(subs(dWp,qVars{i},dVars{i},0));
  dWp  = sym(subs(simple(dWp),['d' qVars{i} '(' dVars{i} ')'],['diff(' dVars{i} ',t)'],0));
  dWk  = sym(subs(dWk,['diff(d' qVars{i} '(' qVars{i} '),' qVars{i} ')'],['0'],0));
  dWk  = sym(subs(dWk,qVars{i},dVars{i},0));
  dWk  = sym(subs(simple(dWk),['d' qVars{i} '(' dVars{i} ')'],['diff(' dVars{i} ',t)'],0));
  dWk2 = sym(subs(dWk2,qVars{i},dVars{i},0));
  dWk2 = sym(subs(simple(dWk2),['d' qVars{i}],['diff(' dVars{i} ',t)'],0));
  F(i) = sym(Ls{i});
end;

dWp  = simple(dWp);
dWk  = simple(dWk);
dWk2 = simple(dWk2);

Lagrange = simple(diff(dWk2,'t')-dWk+dWp-F);
Equations = Lagrange;
<?php
}
cortege_push($Eqtns["Number"],$Num);
cortege_push($Eqtns["Init"],$In["Init"]);
cortege_push($Eqtns["Variable"],"Equations");
cortege_push($Eqtns["Caption"],"Уравнения Лагранжа");
?>
