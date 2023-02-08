<?php
$Num = $Eqtns["Number"][0];
switch ($Stage) {
  case stResource:
    echo "Time = ",$this->Time,";\n";
    echo "Init = [", implode(",",$Eqtns["Init"][0]), "];\n";
    break;
  case stCall:
?>

Lagrange = subs(Lagrange,'g',g);
SolveF = 'solve(Lagrange(1)';

for i=2:k
    SolveF   = [SolveF ',Lagrange(' '0'+i ')'];
end;

for i=1:k
    Lagrange = subs(Lagrange,['diff(' dVars{i} ',`$`(t,2))'],['D2' '0'+i],0);
    Lagrange = subs(simple(Lagrange),['diff(' dVars{i} ',$(t,2))'],['D2' '0'+i],0);
    Lagrange = subs(simple(Lagrange),['diff(' dVars{i} ',t)'],['D1' '0'+i],0);
    Lagrange = subs(simple(Lagrange),dVars{i},['D' '0'+i],0);
    SolveF   = [SolveF ',''D2' '0'+i ''''];
    clear ['D' '0'+i] ['D1' '0'+i] ['D2' '0'+i];
end;

SolveF = [SolveF ');'];
Solution = eval(SolveF);

Function = '[';
Labels = cell(k*2,1);
for j=1:k
  Eqtn = eval(['Solution.D2' '0'+j]);
  for i=1:k
    Eqtn = subs(simple(Eqtn),['D' '0'+i],['Y(' '0'+i*2 ')'],0);
    Eqtn = subs(simple(Eqtn),['D1' '0'+i],['Y(' '0'+i*2-1 ')'],0);
  end;
  if (j~=1); Function = [Function ';']; end;
  Function = [Function char(Eqtn) ';Y(' '0'+j*2-1 ')'];
  Labels{j*2-1} = ['d' dVars{j}];
  Labels{j*2} = dVars{j};
end;
Function = [Function ']'];

[t,y]=ode15s(inline(Function,'t','Y'),[0 Time],Init);
plot(t,y);
legend(Labels);
<?php
}
?>
