program STT_1;
uses crt,dos,gui,db;
var
   m:byte;
   terminate:boolean;
procedure help;
var
   k:word;
begin
   win(10,3,70,24,0,7,'Справка',false);
   repeat
   k:=scankey;
   until (syskey(k)) or (k=esc);
   kr:=k;
   scrfill(10,3,70,24,white,1);
end;
{Управление главным меню}
procedure main_menu;
var
   password:string;
begin
   {Выключение курсора /gui.pas}
   vcurs(false);
   window(1,1,80,25);
   GoToXY(1,1);
   {Вывод меню hmenu /gui.pas}
   m:=0;
   m:=hmenu(menu_0,White,Blue,Black,White);
   {Переход к главному окну}
   window(2,3,79,23);
   TextColor(white);
   textBackGround(blue);
   case m of
      1:{Отобразить все}
      begin
         open;
         write_list(load(1,app.alphabet));
      end;
      11:{Сортировка по алфавиту}
      begin
         if app.alphabet=false then
         begin
            showmessage(25,10,60,14,black,white,'Сообщение',
                 'Выбранна сортировка по алфавиту');
            app.alphabet:=true;
         end else showmessage(25,10,60,15,black,white,'Внимание',
                 'Сортировка по алфавиту уже установленна');
      end;
      12:{Сортировка по дате}
      begin
         if app.alphabet=false then
            showmessage(25,10,60,15,black,white,'Внимание',
                 'Сортировка по дате добавления уже установленна')
         else
         begin
            app.alphabet:=false;
            showmessage(25,10,60,15,black,white,'Сообщение',
                 'Выбранна сортировка по дате добавления');
         end;
      end;
      16:{Режим редактора}
      begin
         {Окно для ввода win_input /gui.pas}
         if app.editor=false then
         begin
            password:=win_input(20,10,60,13,black,white,'Пароль','Введите пароль:');
            if app.password=password then
            begin
               app.editor:=true;
               showmessage(25,10,50,14,black,white,
                  'Внимание','Режим редактора включен');
            end else
               if password<>'' then showmessage(25,10,45,14,black,white,
                  'Ошибка','Неверный пароль');
            password:='';
         end else
            showmessage(25,10,55,14,black,white,
               'Предупреждение','Режим редактора уже включен');
      end;
      17:
      begin
         if app.editor then
         begin
            app.editor:=false;
            showmessage(25,10,51,14,black,white,'Внимание',
                 'Режим редактора выключен');
         end else
            showmessage(25,10,55,14,black,white,
               'Предупреждение','Режим пользователя включен');
      end;
      19:{Удалить текущую БД}
      begin
         if app.fileopened then
         begin
            close(f);
            {$I-}
            erase(f);
            if IOResult<>0 then scrwrite('Ошибка удаления БД')
              else scrwrite('База данных удалена');
            app.fileopened:=false;
            {$I+}
         end else scrwrite('База данных не выбранна');
      end;
      2:{Настройки}
      begin
      end;
      3:{Выход}
      begin
         if win_ask('Выход','Вы действительно хотите выйти?') then
            terminate:=true else kr:=tab;

      end;
   end;
end;

begin
   {testmode}
   CHECKBREAK:=TRUE;
   clrscr;
   {Вывод footer}
   app.cur_line:='* F1 * Справка * Tab * Меню * Alt+X * Выход';
   fline(app.cur_line);
   {Вывод главного окна /gui.pas}
   win(1,2,80,25,white,1,' Словарь технических терминов ',true);
   {Кr - код клавиши scankey /gui.pas}
   {Открытие БД и подготовка к работе /db.pas}
   open;
   kr:=9;
   terminate:=false;
   repeat
      if kr=0 then kr:=scankey;
      case kr of
         f1:help;
         tab:main_menu;
         alt_x:if win_ask('Выход','Вы действительно хотите выйти?') then
            terminate:=true else kr:=tab;
         else kr:=0;
      end;
   until terminate;
   if app.fileopened then close(f);
end.
