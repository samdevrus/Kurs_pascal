program STT_1;
uses crt,dos,gui,db;
var
   m:byte;
   terminate:boolean;
procedure help;
var
   k:word;
begin
   win(10,3,70,24,0,7,'��ࠢ��',false);
   repeat
   k:=scankey;
   until (syskey(k)) or (k=esc);
   kr:=k;
   scrfill(10,3,70,24,white,1);
end;
{��ࠢ����� ������ ����}
procedure main_menu;
var
   password:string;
begin
   {�몫�祭�� ����� /gui.pas}
   vcurs(false);
   window(1,1,80,25);
   GoToXY(1,1);
   {�뢮� ���� hmenu /gui.pas}
   m:=0;
   m:=hmenu(menu_0,White,Blue,Black,White);
   {���室 � �������� ����}
   window(2,3,79,23);
   TextColor(white);
   textBackGround(blue);
   case m of
      1:{�⮡ࠧ��� ��}
      begin
         open;
         write_list(load(1,app.alphabet));
      end;
      11:{����஢�� �� ��䠢���}
      begin
         if app.alphabet=false then
         begin
            showmessage(25,10,60,14,black,white,'����饭��',
                 '��࠭�� ���஢�� �� ��䠢���');
            app.alphabet:=true;
         end else showmessage(25,10,60,15,black,white,'��������',
                 '����஢�� �� ��䠢��� 㦥 ��⠭�������');
      end;
      12:{����஢�� �� ���}
      begin
         if app.alphabet=false then
            showmessage(25,10,60,15,black,white,'��������',
                 '����஢�� �� ��� ���������� 㦥 ��⠭�������')
         else
         begin
            app.alphabet:=false;
            showmessage(25,10,60,15,black,white,'����饭��',
                 '��࠭�� ���஢�� �� ��� ����������');
         end;
      end;
      16:{����� ।����}
      begin
         {���� ��� ����� win_input /gui.pas}
         if app.editor=false then
         begin
            password:=win_input(20,10,60,13,black,white,'��஫�','������ ��஫�:');
            if app.password=password then
            begin
               app.editor:=true;
               showmessage(25,10,50,14,black,white,
                  '��������','����� ।���� ����祭');
            end else
               if password<>'' then showmessage(25,10,45,14,black,white,
                  '�訡��','������ ��஫�');
            password:='';
         end else
            showmessage(25,10,55,14,black,white,
               '�।�०�����','����� ।���� 㦥 ����祭');
      end;
      17:
      begin
         if app.editor then
         begin
            app.editor:=false;
            showmessage(25,10,51,14,black,white,'��������',
                 '����� ।���� �몫�祭');
         end else
            showmessage(25,10,55,14,black,white,
               '�।�०�����','����� ���짮��⥫� ����祭');
      end;
      19:{������� ⥪���� ��}
      begin
         if app.fileopened then
         begin
            close(f);
            {$I-}
            erase(f);
            if IOResult<>0 then scrwrite('�訡�� 㤠����� ��')
              else scrwrite('���� ������ 㤠����');
            app.fileopened:=false;
            {$I+}
         end else scrwrite('���� ������ �� ��࠭��');
      end;
      2:{����ன��}
      begin
      end;
      3:{��室}
      begin
         if win_ask('��室','�� ����⢨⥫쭮 ��� ���?') then
            terminate:=true else kr:=tab;

      end;
   end;
end;

begin
   {testmode}
   CHECKBREAK:=TRUE;
   clrscr;
   {�뢮� footer}
   app.cur_line:='* F1 * ��ࠢ�� * Tab * ���� * Alt+X * ��室';
   fline(app.cur_line);
   {�뢮� �������� ���� /gui.pas}
   win(1,2,80,25,white,1,' ������� �孨�᪨� �ନ��� ',true);
   {�r - ��� ������ scankey /gui.pas}
   {����⨥ �� � �����⮢�� � ࠡ�� /db.pas}
   open;
   kr:=9;
   terminate:=false;
   repeat
      if kr=0 then kr:=scankey;
      case kr of
         f1:help;
         tab:main_menu;
         alt_x:if win_ask('��室','�� ����⢨⥫쭮 ��� ���?') then
            terminate:=true else kr:=tab;
         else kr:=0;
      end;
   until terminate;
   if app.fileopened then close(f);
end.
