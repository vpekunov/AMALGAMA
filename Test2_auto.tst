%TestID=Test2auto
%���� �� ����������� � ������������ ��������

Text(Prompt)
     ���  ������  ��  ������  ������ ��� ������������ ��������� ��������� ������.
�������� ����  ��  ���������  � ������� ��������������� ������.  �����  �� ������
�������� �� 10 ��������.
EndT

Answer(A1,1)
  &EqualButtons
  @����� ������
  @� ����������� �������
  @������
  @�����
  @����� �������
EndA

Question(Q1):A1
   ������ 1
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
���������� �� �� "��������" ������ �  ���  �������,  �����  ����  (���
����������) ����������� ���?
EndQ

Question(Q2):A1
   ������ 2
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
���������� �� ��� ������ ������ �������� �� �������?
EndQ

Question(Q3):A1
   ������ 3
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
����� ��  ���������  ���������  ������� �������� �������������� ��� ��
�������� ��� ��������?
EndQ

Question(Q4):A1
   ������ 4
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
��������� �� �� �������� � �������� � ����������� ��� ������������ ���
���������?
EndQ

Question(Q5):A1
   ������ 5
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
������ �� �� �������� ���������� ����������?
EndQ

Question(Q6):A1
   ������ 6
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
������� �� �� ���,  ��� ����������� ��������,  � ���� ������� ������ �
������?
EndQ

Question(Q7):A1
   ������ 7
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
������� �� �� ���,  �����,  ��������� ���� � ����������� �� ����,  ���
��� ����������?
EndQ

Question(Q8):A1
   ������ 8
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
������� ��  ��  ����  ���������,  ����  �� �������� ���������� ��� ���
����?
EndQ

Question(Q9):A1
   ������ 9
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
����������� �� �� ��������,  ���� � ��� ����  �����������  �����������
������������� �����, ��������, �����������?
EndQ

Question(Q10):A1
   ������ 10
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
������ �� � ��� ��������������-���������� ��� � �������� �������������
� ������ �� ��������� � ����, � ��� �� ��������?
EndQ

Answer(A2,1)
  @ ��������� ������������
EndA

Question(Q11):A2
   &Font('Courier New Cyr',11,clBlack,1,0,0)
   ��  ��������  ��  ���  ������������  ���  �������. ���� ��
   �������  ���������������� ���� ������,  �� �������� ������
   ������ (�������)  �  ������� ������ "������" � "�����". ��
   ���������  �����������  ��������� �  ����� ����� � �������
   ������ "��������� ������������"
EndQ

Text(T1)
������ ������� ������������ �������
EndT

Main
  Size(obWindow,800,600)
  Title('���� �� ����������� � ������������ ��������')
  ShowPrompt(Prompt)
  Size(obQuestionPanel,2,75,650,235)
  Font(obQuestionPanel,'Times New Roman Cyr',14,clNavy,1,1,1)
  Color(obQuestionPanel,RGB(176,208,176))
  Size(obAnswerPanel,2,315,650,255)
  Font(obAnswerPanel,'Arial Cyr',10,clNavy,0,0,0)
  Color(obAnswerPanel,RGB(208,208,160))
  Size(obHandlePanel,655,75,141,495)
  Font(obHandlePanel,'Times New Roman Cyr',14,clBlack,0,0,0)
  Color(obHandlePanel,clBtnFace)
  HandlePanel(hbBack,hbForward)
  Open
  Ask(Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8,Q9,Q10,Q11)
  SaveResults
  Define qC:Array[1:10] = {&Q1,&Q2,&Q3,&Q4,&Q5,&Q6,&Q7,&Q8,&Q9,&Q10}
  Define aC:Array[1:5] = {1,2,3,4,5}
  Define sC:Array[1:5] = {2,4,6,8,10}
  Define C:Number = 0
  Define cC1:Number
  Define cC:Number = 1
  While (cC<=10)
    cC1:=1
    While (cC1<=5)
      If qC[cC]=aC[cC1]
         C := C+sC[cC1]
      EndIf
      cC1:=cC1+1
    EndW
    cC:=cC+1
  EndW

  Define nfS:Number = 1
  Define normS:Array[2:3] = {50,60}
  Define S:Number = 3
  While (S>1 And nfS)
    If (C>=normS[S])
       nfS:=0
    Else
       S:=S-1
    EndIf
  EndW

  Define Texts1:String = '������ ������� ��������� � �������� �����'
  Define Texts2:String = '������ ������� ������� � ������� �������'
  Define Texts:Array[1:3] = {#T1,#Texts1,#Texts2}
  Define textTexts:Array[1:3] = {1,0,0}
  ClearPut
  PutTitle('����������')
  PutLine('���������� ������ = ',C)
  If textTexts[S]
     PutText(GetTextByPtr(Texts[S]))
  Else
     PutLine(?Texts[S])
  EndIf

  ShowPut
  Exit
EndM
