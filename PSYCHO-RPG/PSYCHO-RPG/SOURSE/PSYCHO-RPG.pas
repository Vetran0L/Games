program movesct;

uses CRT, System.Media;

type
  TPlayerStat = (pHP, pMaxHP, pENERGY, pMaxENERGY, pXP, pMONEY, pLVL, pMPR, pMaxMPR);
  TPlayerItem = (iARMS, iHP_POT, iENERGY_POT, iSTICK, iSWORD, iBOW, iARMOR, iMINDNESS_POT);

const
  MAX_XY = 9801;

var
  x, y, startX, startY, NowXY, basedamage: integer;
  NOTHING, SOMETHING, VHP, VENERGY, VLVL: real;
  iet, IS_PLAYER_WIN, IS_PLAYER_LOSE, IS_PLAYER_FIGHTING, IMS, isCutscenePlayed, isArmorEquipped, isMadnessCutscenePlayed, isFINALCutscenePlayed, IsKillDEATH, IsMadnessDEATH: boolean;
  EVNT, DEAPH_PR: string;
  
  stats: array[TPlayerStat] of real;
  inventory: array[TPlayerItem] of integer;
  equippedWeapon: TPlayerItem;
  
  historyX: array[1..MAX_XY] of integer;
  historyY: array[1..MAX_XY] of integer;
  historyCount: integer;
  nothingStreak: integer; // Счётчик подряд идущих NOTHING
  
  player := new SoundPlayer;

function IsWeapon(item: TPlayerItem): boolean;
begin
  IsWeapon := (item = iARMS) or (item >= iSTICK);
end;

function GetItemName(item: TPlayerItem): string;
begin
  Result := '';
  case item of
    iARMS: Result := 'ARMS';
    iHP_POT: Result := 'HEALTH POTION';
    iENERGY_POT: Result := 'ENERGY POTION';
    iMINDNESS_POT: Result := 'MINDNESS POTION';
    iSTICK: Result := 'STICK';
    iSWORD: Result := 'SWORD';
    iBOW: Result := 'BOW';
    iARMOR: Result := 'ARMOR';
  else Result := 'UNKNOWN ITEM';
  end;
end;

procedure TypeWrite(text: string; delayTime, beepth: integer);
begin
  for var i := 1 to Length(text) do 
  begin
    write(text[i].ToString);
    if text[i] <> ' ' then 
      System.Console.Beep(beepth, 15); 
    Delay(delayTime); 
  end;
end;

procedure ClearKeyBuffer;
begin
  while KeyPressed do 
    ReadKey;
end;

procedure playmus(path: string; ime: boolean);
begin
  try
    path := System.IO.Path.GetFullPath(path);
    if System.IO.File.Exists(path) then
    begin
      player := new SoundPlayer(path);
      if ime = true then
        player.Play;
      if ime = false then
        player.Playlooping;
    end;
  except
    // Если аудиофайл не найден, игра просто продолжится без вылета
  end;
end;

procedure StarGame;
begin
  ClrScr;
  playmus('start_1.wav', true);
  delay(12500);
  ClearKeyBuffer;    
  Textcolor(LightGray);
  TypeWrite('LONG time ago... ', 150, 500);
  Sleep(500);
  ClrScr;
  TypeWrite('UNNAMED traveler come to STRANGE place...', 150, 500);
  Delay(2500);
  ClrScr;
  TextColor(LightMagenta);
  GotoXY(WindowWidth div 2 - 6, WindowHeight div 2);
  TypeWrite('DARK FOREST', 250, 400);
  Delay(5000);
end;

function ReadLimitedIntOrShop(maxLen: integer): integer;
var
  ch: char;
  s: string;
begin
  ClearKeyBuffer;
  s := '';
  startX := WhereX; 
  startY := WhereY;
  
  repeat
    ch := ReadKey; 
    
    if (ch = 'x') or (ch = 'X') then
    begin
      System.Console.Beep(1100, 80);
      ReadLimitedIntOrShop := -999; 
      exit;
    end;
    
    if (ch = 'e') or (ch = 'E') then
    begin
      System.Console.Beep(1100, 80);
      ReadLimitedIntOrShop := -888; 
      exit;
    end;
    
    if (ch >= '0') and (ch <= '9') and (Length(s) < maxLen) then
    begin
      s := s + ch;
      write(ch.ToString); 
      System.Console.Beep(900, 10);
    end
    else if (ch = #8) and (Length(s) > 0) then
    begin
      Delete(s, Length(s), 1); 
      gotoXY(WhereX - 1, WhereY);
      write(' '.ToString); 
      gotoXY(WhereX - 1, WhereY);
      System.Console.Beep(600, 15);
    end;
    
  until ((ch = #13) or (ch = #10)) and (Length(s) > 0); 
  
  ReadLimitedIntOrShop := s.ToInteger; 
end;

function GetRequiredXP(lvl: real): real;
begin
  GetRequiredXP := lvl * 350; 
end;

procedure InitGame;
begin
  x := 0;
  y := 0;
  
  nothingStreak := 0; 
  historyCount := 0; 
  
  stats[pLVL] := 1;
  stats[pMaxHP] := 100;
  stats[pMaxENERGY] := 50;
  stats[pHP] := stats[pMaxHP];
  stats[pENERGY] := stats[pMaxENERGY];
  stats[pMPR] := 0;
  stats[pMaxMPR] := 100;
  stats[pMONEY] := 55;
  stats[pXP] := 0;
  
  equippedWeapon := iARMS;
  EVNT := '';
  NowXY := 0;
  
  inventory[iHP_POT] := 0;
  inventory[iENERGY_POT] := 0;
  inventory[iMINDNESS_POT] := 0;
  inventory[iSTICK] := 0;
  inventory[iSWORD] := 0;
  inventory[iBOW] := 0;
  inventory[iARMOR] := 0;
  
  IMS := false;
  isMadnessCutscenePlayed := false;
  isCutscenePlayed := false;
  isFINALCutscenePlayed := false;
  isArmorEquipped := false;
  
  IsKillDEATH := False;
  IsMadnessDEATH := False;
end;

procedure WriteART;
begin
  // 1. Создаем массив строк с ASCII-артом слайма
  var ART: array of string := (
  '⠀⠀⠀⡐⠏⡂⢐⠂⠀⠀⠀',
  '⠀⣩⡟⣧⡿⣾⣌⣁⡀⣀⠀⠀',
  '⠘⣷⣿⡎⠛⡟⠋⠉⡗⡚⠀',
  '⠀⢫⠀⠄⠀⠜⠀⠀⠄⠀⣠⠇',
  '⠀⠙⣀⣀⣠⡻⡇⠀⠀⣺⠀⠀',
  '⠀⠀⠀⢃⢨⣅⣉⡦⣖⢻⠀⠀',
  '⠀⠀⠀⠈⡇⠉⠁⠃⣰⠉⠀⠀',
  '⠀⠀⠀⠀⢨⢉⡹⠜⠁⠀⠀⠀',
  '⠀⠀⠀⠀⣎⢏⢀⠀⡆⠀⠀⠀',
  '⠀⠀⠀⠀⢠⡇⣭⠃⠀⠀⠀⠀',
  '⠀⠀⠀⠀⡏⠹⣵⠀⠀⠀⠀⠀');
  
  var consoleWidth := 80;
  var consoleHeight := 25;
  
  // 3. Вычисляем размеры самого арта
  var artWidth := ART[0].Length;
  var artHeight := ART.Length;
  
  // 4. Находим стартовые координаты X и Y для центрирования
  var startX := (consoleWidth - artWidth) div 2;
  var startY := (consoleHeight - artHeight) div 2;
  
  
  
  // 5. Выводим каждую строку, предварительно смещая курсор по X
  for var i := 0 to ART.High do
  begin
    GotoXY(startX, startY + i);
    Write(ART[i]);
  end;
  
  // Смещаем курсор вниз, чтобы системный текст не перекрыл рисунок
  GotoXY(1, consoleHeight - 1); 
end;


procedure SetConsoleForArt(reqW, reqH: integer);
begin
  try
    // 1. Сначала полностью очищыв текущее (большое) окно
    TextColor(LightGray);
    TextBackground(Black);
    System.Console.Clear;
    ClrScr;
    
    var targetW := Min(reqW, System.Console.LargestWindowWidth);
    var targetH := Min(reqH, System.Console.LargestWindowHeight);
    
    // 2. Уменьшать или увеличивафывф окно и буфер
    if targetW < System.Console.WindowWidth then
    begin
      System.Console.SetWindowSize(targetW, targetH);
      System.Console.SetBufferSize(targetW, targetH);
    end
    else
    begin
      System.Console.SetBufferSize(targetW, targetH);
      System.Console.SetWindowSize(targetW, targetH);
    end;
    
    // 3. Принудительная затирка буфера для Windows Terminal
    System.Console.SetCursorPosition(0, 0);
    var emptyScreen := new string(' ', targetW * targetH);
    System.Console.Write(emptyScreen);
    
    System.Console.SetCursorPosition(0, 0);
    ClrScr;
  except
  end;
end;



procedure WriteART2;
begin
  SetConsoleForArt(135, 25);
  ClrScr;
  
  var ART: array of string := (
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⣤⣤⣤⣠⣀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⢞⣿⣿⣿⣿⣿⡟⠋⠅⠃⠈⠈⠀⠀⠀⠀⠀⠀⠀⠁⣿⣿⠁⠁⠇⡀⠀⠀⠀⠀⠀⠀⠇⠀⠀⠀⠀⠁⣿⣿⠁⠁⠇⡀⠀⠀⠁⣿⣿⠁⠀⠀⠇⠁',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠐⢫⢿⣟⠣⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⣿⣿⠀⠀⠀⠀⠇⠇⠇⠀⠀⠀⠀⣿⣿⠀⠀⠀⣿⣿⠀⠀⣿⣿⠀⢀⠁⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣼⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⣿⣿⠀⠀⠇⠀⠀⣿⣿⠀⠀⠀⣿⣿⠁⠁⠇⠁⠀⠀⠀⣿⣿⠁⠇⡀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⣿⣿⠀⢀⠁⠁⠁⠁⠇⡀⠀⠀⣿⣿⠀⠀⠀⠇⡀⠀⠀⣿⣿⠀⠀⣿',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣿⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⢀⢀⢀⠇⠁⠀⢀⠇⡀⠀⠀⢀⣿⣿⢀⢀⣿⣿⢀⠀⠀⠁⠇⡀⢀⣿⣿⢀⠀ ⣿',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣹⢇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡰',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⡀⢋⠴⣠⣄⣀⡀⠀⠀⠀⠀⠈⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢤⣤⣀⡀⠀⠀⠀⠀⠀⠌⣳⢿⠿⡙⠠⠀⠀⠀⠀⠀⠀⠀⠁⣿⣿⠁⠁⠁⠁⠇⠀ ⢀⢀⠇⠁⠁⣿⣿⠀⠀⠁⣿⣿⠁⠁⠇⡀⠀⠀⠁⣿⣿⠁⠁⠁⠁⠇⠀⠀⢀⠇⠁⠁⠁⢀⠇⠀⠀⠇⠁⠁⣿⣿⠁⠁⠇',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⠑⠢⠀⠀⠀⠀⠐⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⢀⠀⠀⠀⢀⠇⠁⠀⠀⠀⠀⣿⣿⠀⠀⣿⣿⠀⠀⠀⣿⣿⠀⠀⣿⣿⠀⠀⢀⠀⠀⠀⠀⣿⣿⢀⢀⠀⠀⠁⠀⠀⠀⠀  ⣿⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀ ⣿⣿⠁⠁⠇⠀⠀ ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⣿⣿⠁⠁⠇⠁⠀⠀⠀⣿⣿⠁⠁⠇⠀⠀⠀⠀⠀⠁⠁⣿⣿⠇⡀⠀⠀⠀⠀  ⣿⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣦⢶⣤⢆⡄⣀⠀⣄⠲⣈⠒⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀ ⠁⠇⡀⠀⠀⠀⠀⣿⣿⠀⠀⣿⣿⠀⠀⠀⠇⡀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠁⣿⣿⠀⠀⠀  ⣿⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⢾⣟⡾⣥⠏⠄⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⢀⠀⠀⠀⠀ ⠁⠁⠇⢀⢀⢀⠇⠁⠀⢀⣿⣿⢀⠀⠀⠁⠇⡀ ⢀⣿⣿⢀⢀⢀⢀⢀⠇⠀⠇⠁⢀⢀⢀⢀⠇⠁⠀⠀  ⢀⣿⢀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠁⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀');
  
  var artWidth := 0;
  for var i := 0 to ART.High do
    if ART[i].Length > artWidth then
      artWidth := ART[i].Length;
  
  var artHeight := ART.Length;
  var startX := Max(1, (WindowWidth - artWidth) div 2);
  var startY := Max(1, (WindowHeight - artHeight) div 2);
  
  for var i := 0 to ART.High do
  begin
    if (startY + i) <= WindowHeight then
    begin
      GotoXY(startX, startY + i);
      Write(ART[i]);
    end;
  end;
  
  GotoXY(1, Min(WindowHeight, startY + artHeight + 1));
end;

procedure WriteART3;
begin
  // Расширяем консоль под размеры финального экрана
  SetConsoleForArt(145, 48);
  ClrScr;
  
  var ART: array of string := (
    '⠀⠀⠀⠀⠀⠀⠀⠂⠄                                                                                                                          ',
    '⠀⠀⠀⠀⠀⠐⠀⠀⠀⠀  `7MM"""Yb.     db       `7MM"""Mq.  `7MMF''  `YMM''                                                                     ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀MM    `Yb.    ;MM:       MM   `MM.   MM    .M''          ⠐⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂                        ',
    '⠀⢀⡴⠢⡀⠀⠀⠀⠀⠀⠀⠀MM     `Mb   ,V^MM.      MM   ,M9    MM  .d"                              ⠐                                         ',
    '⠀⠈⠧⠴⠁⠀⠀⠀⠀⠀⠀⠀MM      MM  ,M  `MM      MMmmdM9     MMMMM.                                                             ⠄⠂         ',
    '⠀⠒⠤⣀⣀⠤⠒⠐⠀⠀⠀⠀MM     ,MP  AbmmmqMA     MM  YM.     MM  VMA                                                                        ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀MM    ,dP'' A''     VML    MM   `Mb.   MM   `MM.              ⠂                                                       ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ .JMMmmmdP'' .AMA.   .AMMA..JMML. .JMM..JMML.   MMb.                                            ⠄                       ',
    '⠀⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂                                                                                          ⠄               ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ `7MM"""YMM   .g8""8q.  `7MM"""Mq.  `7MM"""YMM  .M"""bgd  MMP""MM""YMM                       ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀⠀⠀MM    `7 .dP''    `YM.  MM   `MM.   MM    `7  ,MI    "Y  P''   MM   `7                       ',
    '⠀⠀⢀⣀⡤⠤⠔⠒⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀MM   d   dM''      `MM  MM   ,M9    MM   d    `MMb.           MM                            ',
    '⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀MM""MM   MM        MM  MMmmdM9     MMmmMM      `YMMNq.       MM                            ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀MM   Y   MM.      ,MP  MM  YM.     MM   Y  ,     `MM         MM                            ',
    '⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀MM       `Mb.    ,dP''  MM   `Mb.   MM     ,M Mb     dM       MM                            ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ .JMML.       `"bmmd"''  .JMML. .JMM..JMMmmmmMMM P"Ybmmd"     .JMML.                         ',
    '⠀⠀⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂    ',
    '⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⣠⣴⣶⡾⠛⡻⡷⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐        ',
    '⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⠟⠁⠀⢀⣠⢔⡽⡿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄  ',
    '⠀⠒⠒⠤⣀⡀⠀⠀⠀⠀⠀⢹⣿⣛⢤⠂⠰⣴⣷⡟⣡⠐⢽⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐  ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡿⣏⣴⣟⣯⢿⣽⣿⢽⣴⣿⣸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠄    ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣧⠿⢏⢈⢄⣱⣺⣿⣷⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠤⠒⠒⠤⣀⠀⠀⠀⠀⠐      ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⢋⣏⣾⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⢻⡄⠀⠀⠀⢐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂    ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢷⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠃⠀⠻⣄⠀⠀⠆⠀⠀⠀⠀⠀⠀⠀⠀⠄          ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣏⢀⡀⣄⣽⣄⡀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐  ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⢸⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⢾⣿⣿⡿⣿⣧⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠐        ',
    '⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣷⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣲⣿⣿⣿⣾⣿⣿⣿⣿⣷⠂⠃⠀⠀⠀⠒⠤⣀⡀⠀⢀⣀⠤⠒  ',
    '⠀⠀⠀⣀⡕⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣯⣿⣿⣿⣦⣀⣀⣀⡖⠀⠀⠀⠀⠀⠀⠀⠄    ',
    '⠀⠀⡄⠀⠑⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣟⣿⣷⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣦⡀⠀⣆                    ',
    '⠀⠐⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡿⡿⢻⣟⣽⣿⣿⣿⣍⠁⠀⠀⠀⠀⠈⣱⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠉⡇⠀⠀⠀⠀⠀⠀⠐      ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣾⣯⣴⠤⢾⢿⣿⣿⠿⠿⣿⡷⠂⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣧⡅⢀⡤⠒⠉⠉⠒⢤⡀    ',
    '⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠾⠿⢯⣿⣿⣿⣿⣿⣿⣿⣾⣿⣍⣀⣀⠀⡀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣿⡷⠀⠀⠀⠀⠀⠀⠀⠀⠐  ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣟⣿⣿⣿⣿⣿⣿⣟⣦⡀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢀⣠⣴⣶⣦⣄⡀      ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠲⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢠⣿⣿⣿⣿⣿⣿⣷⣄  ',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢙⠺⠿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠉⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⡿⣿⣿⣿⣿⡇⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⠁⠀⠀⣴⣿⣿⣫⣿⣷⣾⣿⣿⣿⣿⣿⣽⣿⣿⢿⡞⠋⢝⣿⣿⣿⣧⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
    '⢀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣩⡽⡷⣞⣿⣿⣿⣿⣿⣶⣾⣯⡿⢿⣿⣿⠿⠿⠿⢿⣿⣿⣻⡿⠿⡽⣟⣳⠜⠉⠽⠿⣿⡇⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿',
    '⠘⠪⠟⠿⢶⣤⣠⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣾⠽⠾⠶⢛⣿⣿⣿⣿⡷⣿⣿⣟⡺⡿⠒⠒⠂⠀⣰⣿⣿⣿⡟⢃⠀⣹⠟⠁⠘⠐⠀⢐⠚⣏⠀⠈⠻⣿⣿⣿⣿⣿⡿⠿',
    '⠀⠀⠀⠀⠄⠈⢻⣶⣤⣴⣶⠿⠿⠿⠛⠿⣷⣲⣤⣠⣶⣾⣿⣿⣟⡀⠀⣠⢀⢡⣿⣿⣿⣿⣿⣺⣿⣟⠀⣀⣠⣀⣠⣼⣿⣿⣿⣟⣵⣹⢛⣁⣠⠴⠢⡄⣶⣬⣿⠷⠀⠀⠀⠈⠛⢿⣿⡟⠁⠀',
    '⠀⠀⠀⠀⠀⠀⢀⡁⠀⠀⠀⢀⡤⠤⢬⢹⣿⣿⣏⣽⣿⣿⣟⣁⣤⣠⠄⣂⣀⣾⢿⣿⣿⣿⣿⣯⢻⣿⡒⠚⠪⡍⢻⣿⣿⣿⣣⣿⡿⣋⣾⣉⣠⠀⠀⡀⡠⢀⣹⠀⠀⠀⠀⠀⠀⢸⣿⡇⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠺⡂⠀⠁⠀⠀⠀⠠⣿⠿⢉⢸⠿⠛⣛⣗⣻⡿⠟⡛⠞⣿⣿⣯⠿⣿⣩⣟⣛⣿⣿⣿⣿⣯⢿⣽⣿⣿⣽⣿⣯⡽⣻⣽⣉⠉⠭⠉⠉⠃⠀⠹⣿⢃⠀⠀⠀⠀⠀⢸⣿⡇⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠠⠂⠀⠀⢀⣠⣰⣾⣟⣴⡿⠇⡦⣖⣵⡿⣿⣿⣿⣽⣽⣿⣿⣾⡿⠾⢔⣗⣾⣿⣿⣿⣿⢽⣿⣿⣿⣿⢿⢿⣾⢶⣟⡿⢻⣳⣶⠾⠒⢀⠐⠐⣺⡠⢀⣀⣠⣤⣤⣼⣿⣧⣤',
    '⠀⠀⠀⠀⠀⠀⠀⡆⠀⢠⢛⣾⣿⣧⣿⡿⣢⣮⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣉⣅⣽⣽⣶⣿⣿⣿⣿⣿⣿⣿⣿⣾⣵⣿⣵⣿⣼⣯⣶⡞⠱⡷⣶⠒⠃⠈⠚⢿⠀⠻⠿⠿⢿⣿⣿⣿⣿⣿⣿');
  
  var artWidth := 0;
  for var i := 0 to ART.High do
    if ART[i].Length > artWidth then
      artWidth := ART[i].Length;
  
  var artHeight := ART.Length;
  var startX := Max(1, (WindowWidth - artWidth) div 2);
  var startY := Max(1, (WindowHeight - artHeight) div 2);
  
  for var i := 0 to ART.High do
  begin
    if (startY + i) <= WindowHeight then
    begin
      GotoXY(startX, startY + i);
      Write(ART[i]);
    end;
  end;
  
  GotoXY(1, Min(WindowHeight, startY + artHeight + 1));
end;




procedure CheckLevelUp;
var
  reqXP: real;
begin
  reqXP := GetRequiredXP(stats[pLVL]);
  
  if stats[pXP] >= reqXP then
  begin
    stats[pXP] := stats[pXP] - reqXP; 
    stats[pLVL] := stats[pLVL] + 1;    
    
    stats[pMaxHP] := Round(stats[pMaxHP] * 1.2);
    stats[pMaxENERGY] := Round(stats[pMaxENERGY] * 1.2);
    
    stats[pHP] := stats[pMaxHP];
    stats[pENERGY] := stats[pMaxENERGY];
    
    ClrScr;
    TextColor(LightGreen);
    System.Console.Beep(523, 100); 
    System.Console.Beep(659, 100); 
    System.Console.Beep(784, 300);
    writeln('================');
    writeln('!!! LEVEL UP !!!');
    writeln('New Level: ' + stats[pLVL].ToString);
    writeln('Max HP: ' + stats[pMaxHP].ToString);
    writeln('Max Energy: ' + stats[pMaxENERGY].ToString);
    if (stats[pLVL] >= 2) and (inventory[iSTICK] = 0) then
    begin
      inventory[iSTICK] := 1; 
      TextColor(Yellow);
      writeln('New item: STICK!');
      writeln('Equip it in INVENTORY <E>');
    end;
    writeln('================');
    Delay(2500);
  end;
end;

procedure OpenShop;
var
  priceHP, priceEnergy, priceSword, priceBow, priceArmor, priceMindness: integer;
  ch: char;
begin
  priceHP := Round((15 * stats[pLVL]) - stats[pLVL] * 2.5);
  priceEnergy := Round((10 * stats[pLVL]) - stats[pLVL] * 2.5);
  priceMindness := Round((7 * stats[pLVL]) - stats[pLVL] * 2.5);
  priceSword := 60;
  priceBow := 85;
  priceArmor := 150;
  while true do
  begin
    ClrScr;
    TextColor(14);
    writeln('=========== SHOP ===========');
    writeln('Money: ' + stats[pMONEY].ToString);
    writeln('HP Potions: ' + inventory[iHP_POT].ToString);
    writeln('Energy Potions: ' + inventory[iENERGY_POT].ToString);
    writeln('============================');
    writeln;
    writeln('1. Buy HP POTION   [Cost: ' + priceHP.ToString + ']');
    writeln('2. Buy EN POTION   [Cost: ' + priceEnergy.ToString + ']');
    writeln('3. Buy SWORD       [Cost: ' + priceSword.ToString + ']');
    writeln('4. Buy BOW         [Cost: ' + priceBow.ToString + ']');
    if stats[pLVL] < 10 then
      writeln('5. Buy ARMOR       [Reach 10 LVL]')
    else
      writeln('5. Buy ARMOR       [Cost: ' + priceArmor.ToString + ']');
    if IMS = true then
      writeln('6. Buy MIND POTION [Cost: ' + priceMindness.ToString + ']');
    
    writeln('0. Exit Shop');
    writeln;
    write('Choose item: ');
    
    ClearKeyBuffer;
    ch := ReadKey;
    if ch = '0' then break;
    
    if ch = '1' then
    begin
      if stats[pMONEY] >= priceHP then
      begin
        stats[pMONEY] := stats[pMONEY] - priceHP;
        inventory[iHP_POT] := inventory[iHP_POT] + 1; 
        System.Console.Beep(1000, 100);
      end
      else
      begin
        TextColor(LightRed); writeln; writeln('Not enough money!'); Delay(800);
      end;
    end;
    
    if ch = '2' then
    begin
      if stats[pMONEY] >= priceEnergy then
      begin
        stats[pMONEY] := stats[pMONEY] - priceEnergy;
        inventory[iENERGY_POT] := inventory[iENERGY_POT] + 1; 
        System.Console.Beep(1000, 100);
      end
      else
      begin
        TextColor(LightRed); writeln; writeln('Not enough money!'); Delay(800);
      end;
    end;
    
    if ch = '3' then
    begin
      if inventory[iSWORD] > 0 then
      begin
        TextColor(LightCyan); writeln; writeln('Already own a SWORD!'); Delay(800);
      end
      else if stats[pMONEY] >= priceSword then
      begin
        stats[pMONEY] := stats[pMONEY] - priceSword;
        inventory[iSWORD] := 1; 
        System.Console.Beep(1000, 100);
      end
      else
      begin
        TextColor(LightRed); writeln; writeln('Not enough money!'); Delay(800);
      end;
    end;
    
    if ch = '4' then
    begin
      if inventory[iBOW] > 0 then
      begin
        TextColor(LightCyan); writeln; writeln('Already own a BOW!'); Delay(800);
      end
      else if stats[pMONEY] >= priceBow then
      begin
        stats[pMONEY] := stats[pMONEY] - priceBow;
        inventory[iBOW] := 1; 
        System.Console.Beep(1000, 100);
      end
      else
      begin
        TextColor(LightRed); writeln; writeln('Not enough money!'); Delay(800);
      end;
    end;
    
    if ch = '5' then
    begin
      if stats[pLVL] < 10 then
      begin
        TextColor(LightRed);
        writeln;
        writeln('Not enough LVL!'); Delay(800);
      end
      else if inventory[iARMOR] > 0 then
      begin
        TextColor(LightCyan); writeln; writeln('Already own a ARMOR!'); Delay(800);
      end
      else if stats[pMONEY] >= priceArmor then
      begin
        stats[pMONEY] := stats[pMONEY] - priceArmor;
        inventory[iARMOR] := 1; 
        System.Console.Beep(1000, 100);
      end
      else
      begin
        TextColor(LightRed); writeln; writeln('Not enough money!'); Delay(800);
      end;
    end;
    
    if ch = '6' then
    begin
      if stats[pMONEY] >= priceMindness then
      begin
        stats[pMONEY] := stats[pMONEY] - priceMindness;
        inventory[iMINDNESS_POT] := inventory[iMINDNESS_POT] + 1; 
        System.Console.Beep(1000, 100);
      end
      else
      begin
        TextColor(LightRed); writeln; writeln('Not enough money!'); Delay(800);
      end;
    end;
    
  end;
end;

procedure OpenInventory;
var
  ch: char;
  availableWeapons: array[1..10] of TPlayerItem;
  weaponCount: integer;
  keyNum: integer;
  hasArmor: boolean;
  armorOptionNum: integer;
begin
  while true do
  begin
    ClrScr;
    TextColor(LightCyan);
    writeln('========= INVENTORY =========');
    writeln('HP Potions: ' + inventory[iHP_POT].ToString);
    writeln('Energy Potions: ' + inventory[iENERGY_POT].ToString);
    if IMS or (inventory[iMINDNESS_POT] > 0) then
      writeln('Mind Potions: ' + inventory[iMINDNESS_POT].ToString);
    writeln('-----------------------------');
    
    // Отображение текущего оружия
    write('WEAPON: ');
    if equippedWeapon <> iARMS then
      writeln('[CURRENT: ' + GetItemName(equippedWeapon) + ']')
    else
      writeln('[ARMS]');
    
    // Отображение текущего статуса брони
    hasArmor := inventory[iARMOR] > 0;
    if hasArmor then
    begin
      write('ARMOR: ');
      if isArmorEquipped then
        writeln('[EQUIPPED] + 20% DEF')
      else
        writeln('[NOT EQUIPPED]');
    end;
    writeln('-----------------------------');
    
    // Вывод списка доступного оружия
    weaponCount := 0;
    for var item := iARMS to iBOW do
    begin
      if IsWeapon(item) and (item <> iARMS) and (inventory[item] > 0) then
      begin
        weaponCount := weaponCount + 1;
        availableWeapons[weaponCount] := item;
        
        write(weaponCount, '. ', GetItemName(item), ': ');
        if equippedWeapon = item then
          writeln('[EQ] (Press ' + weaponCount.ToString + ' to unequip)')
        else
          writeln('[Bag] (Press ' + weaponCount.ToString + ' to equip)');
      end;
    end;
    
    if weaponCount = 0 then
      writeln('(No weapons available)');
    
    // Динамическая вкладка брони
    armorOptionNum := 0;
    if hasArmor then
    begin
      armorOptionNum := weaponCount + 1;
      writeln('-----------------------------');
      write(armorOptionNum, '. ', GetItemName(iARMOR), ': ');
      if isArmorEquipped then
        writeln('[EQ] (Press ' + armorOptionNum.ToString + ' to unequip)')
      else
        writeln('[Bag] (Press ' + armorOptionNum.ToString + ' to equip)');
    end;
    
    // Пункт использования зелья рассудка (появляется, если оно есть в сумке)
    if inventory[iMINDNESS_POT] > 0 then
    begin
      writeln('-----------------------------');
      TextColor(LightMagenta);
      writeln('M. Use MIND POTION (-35 MADNESS) [Current: ' + Round(stats[pMPR]).ToString + '/' + Round(stats[pMaxMPR]).ToString + ']');
      TextColor(LightCyan);
    end;
    
    writeln('-----------------------------');
    writeln('0. Exit Inventory');
    writeln;
    write('Choose option: ');
    
    ClearKeyBuffer;
    ch := ReadKey;
    if ch = '0' then break;
    
    // Применение зелья рассудка
    if ((ch = 'm') or (ch = 'M')) and (inventory[iMINDNESS_POT] > 0) then
    begin
      if stats[pMPR] <= 0 then
      begin
        TextColor(Yellow);
        writeln;
        writeln('Your mind is already clear!');
        Delay(800);
      end
      else
      begin
        inventory[iMINDNESS_POT] := inventory[iMINDNESS_POT] - 1;
        stats[pMPR] := stats[pMPR] - 35; // Снижаем безумие на 35 единиц
        if stats[pMPR] < 0 then stats[pMPR] := 0;
        
        System.Console.Beep(650, 200);
        TextColor(LightGreen);
        writeln;
        writeln('Used MIND POTION! Madness decreased.');
        Delay(800);
      end;
    end
    // Обработка нажатия на пункт брони
    else if hasArmor and (ch = Chr(Ord('0') + armorOptionNum)) then
    begin
      isArmorEquipped := not isArmorEquipped;
      System.Console.Beep(900, 150);
    end
    // Обработка нажатия на пункты оружия
    else if (ch >= '1') and (ch <= Chr(Ord('0') + weaponCount)) then
    begin
      keyNum := Ord(ch) - Ord('0');
      var selectedWeapon := availableWeapons[keyNum];
      
      if equippedWeapon = selectedWeapon then
        equippedWeapon := iARMS
      else
        equippedWeapon := selectedWeapon;
      
      System.Console.Beep(900, 150);
    end;
  end;
end;



procedure CheckXY;
begin
  if (nowXY >= 100)  and (not isCutscenePlayed) then
  begin
    isCutscenePlayed := true; 
    
    Player.Stop;
    IMS := true;
    TextColor(LightGray);
    gotoXY(WindowWidth div 2 - 37, WindowHeight div 2);
    TypeWrite('YOU feel like what your MIND GRADUALLY becoming', 250, 400);
    delay(1000);
    TextColor(LightMagenta);
    gotoXY(WindowWidth div 2 + 11, WindowHeight div 2);
    TypeWrite('DISTORTED . . .', 300, 400);
    delay(2000);
    ClrScr;
    Playmus('start_2.wav', false); 
  end; 
end;

procedure GetMADNESS;
begin
  if IMS = true then
    stats[pMPR] := stats[pMPR] + random(5, 17);
end;

procedure checkMADNESS;
begin
  if (stats[pMPR] >= stats[pMaxMPR]) and (not isMadnessCutscenePlayed) then
  begin
    isMadnessCutscenePlayed := true;
    Player.Stop;
    
    ClrScr;
    TextColor(LightGray);
    gotoXY(WindowWidth div 2 - 24, WindowHeight div 2);
    TypeWrite('MADNESS will stronger than your MINDNESS . . .', 300, 400);
    delay(2000);
    
    ClrScr;
    gotoXY(WindowWidth div 2 - 13, WindowHeight div 2);
    TypeWrite('NOW YOU ARE PART OF . . .', 300, 400);
    delay(2500);
    
    PlayMus('end.wav', true);
    ClrScr;
    TextColor(LightMagenta);
    WriteART2;
    delay(24000);
    
    IsMadnessDEATH := True;
    
    player.Stop;
    SetConsoleForArt(95, 28);
    Delay(150);
    iet := false; // Возврат в MainMenu
  end;
end;

procedure CheckFINXY;
begin
  if (NowXY = MAX_XY) and (not isFINALCutscenePlayed) then
  begin
    isFINALCutscenePlayed := true;
    Player.Stop;
    Playmus('FINAL.WAV', true);
    delay(10000);
    
    ClrScr;
    TextColor(LightGray);
    GotoXY(WindowWidth div 2 - 7, WindowHeight div 2); 
    TypeWrite('At the end. . .', 150, 500);
    delay(2500);
    
    ClrScr;
    GotoXY(WindowWidth div 2 - 16, WindowHeight div 2); 
    TypeWrite('The TRAVELER MIGHT to escape from ', 150, 500);
    delay(1000);
    GotoXY(WindowWidth div 2 + 18, WindowHeight div 2); 
    TextColor(LightMagenta);
    TypeWrite('DARK FOREST', 250, 500);
    delay(2500);
    
    ClrScr;
    TextColor(LightGray);
    GotoXY(WindowWidth div 2 - 13, WindowHeight div 2); 
    TypeWrite('There is very far way. . .', 150, 500);
    delay(2500);
    
    ClrScr;
    GotoXY(WindowWidth div 2 - 2, WindowHeight div 2); 
    TypeWrite('BUT', 150, 500);
    delay(2500);
    
    // Вывод финального арта
    ClrScr;
    TextColor(LightMagenta);
    WriteART3;
    delay(5000);
    
    ClearKeyBuffer;
    GotoXY(Max(1, WindowWidth div 2 - 15), WindowHeight - 1);
    TextColor(DarkGray);
    Write('Press any key to finish...');
    ReadKey;
    
    SetConsoleForArt(95, 28);
    Delay(150); // Даем Windows Terminal время применить новый размер
    GotoXY(1, 1);
    
    iet := false;
    exit;
    
  end;
end;

procedure ridivivod;
var
  currentLVL, currentHP, currentMaxHP, currentMPR, currentMaxMPR: integer;
  currentEnergy, currentMaxEnergy, currentXP, reqXP, currentMoney: integer;
  potionsHP, potionsEnergy: integer;
begin
  
  CheckXY;
  checkMADNESS;
  if not iet then exit;
  CheckFINXY;
  if not iet then exit;

  
  currentLVL       := Round(stats[pLVL]);
  currentHP        := Round(stats[pHP]);
  currentMaxHP     := Round(stats[pMaxHP]);
  currentEnergy    := Round(stats[pENERGY]);
  currentMaxEnergy := Round(stats[pMaxENERGY]);
  currentXP        := Round(stats[pXP]);
  reqXP            := Round(GetRequiredXP(stats[pLVL]));
  currentMoney     := Round(stats[pMONEY]);
  
  potionsHP        := inventory[iHP_POT];
  potionsEnergy    := inventory[iENERGY_POT];
  
  currentMPR       := Round(stats[pMPR]);
  currentMaxMPR    := Round(stats[pMaxMPR]);
  
  gotoXY(1, 12); TextColor(LightCyan); writeln('INVENTORY: PRESS <E>');
  gotoXY(1, 13); TextColor(Yellow); writeln('SHOP: PRESS <X>');
  
  TextColor(magenta);
  gotoXY(1, 15); writeln('======= PLAYER =======');
  gotoXY(1, 16); writeln('LVL: ' + currentLVL.ToString);
  gotoXY(1, 17); writeln('HP: ' + currentHP.ToString + '/' + currentMaxHP.ToString);
  gotoXY(1, 18); writeln('EN: ' + currentEnergy.ToString + '/' + currentMaxEnergy.ToString);
  gotoXY(1, 19); writeln('XP: ' + currentXP.ToString + '/' + reqXP.ToString);
  gotoXY(1, 20); writeln('GOLD: ' + currentMoney.ToString);
  gotoXY(1, 21); write('POT: H[' + potionsHP.ToString + '] E[' + potionsEnergy.ToString + '] ');
  if IMS = true then
  begin
    gotoXY(1, 22); writeln('======================');
    gotoXY(1, 23); TextColor(LightMagenta); writeln('MADNESS: ' + currentMPR.ToString + '/' + currentMaxMPR.ToString);
    gotoXY(1, 24); TextColor(Magenta); writeln('======================');
  end;
  if (equippedWeapon > iARMS) and (equippedWeapon <= iBOW) then
  begin
    var wName: string := GetItemName(equippedWeapon);
    if (wName <> nil) and (Length(wName) > 0) then
    begin
      TextColor(LightCyan); write('[' + wName + ']'); TextColor(7);
    end;
  end;
  writeln;
  TextColor(magenta);
  gotoXY(1, 22); writeln('======================');
  gotoXY(1, 1); write('READ XY:[   |   ]');
  gotoXY(1, 8); write('======================');
  gotoXY(1, 10); write('======================');
  gotoXY(1, 9);
  var progressStr: string := 'COMPLETED: ' + NowXY.ToString + '/' + MAX_XY.ToString;
  write(progressStr);
  
  gotoXY(1 + 9, 1);
  x := ReadLimitedIntOrShop(2);
  if x = -999 then begin OpenShop; x := 0; y := 0; exit; end;
  if x = -888 then begin OpenInventory; x := 0; y := 0; exit; end;
  
  gotoXY(1 + 13, 1);
  y := ReadLimitedIntOrShop(2);
  if y = -999 then begin OpenShop; x := 0; y := 0; exit; end;
  if y = -888 then begin OpenInventory; x := 0; y := 0; exit; end;
end;

procedure FIND;
begin
  ClearKeyBuffer;
  var randitem: array of string := |'ENERGY POTION', 'HEAL POTION', 'MONEY', 'NONE'|;
  var RIT: string := randitem[Random(randitem.Length)];
  clrscr;
  if EVNT = 'Chest' then
  begin
    RIT := randitem[Random(randitem.Length)];
    TextColor(Yellow);
    gotoXY(1, 4);
    TypeWrite('YOU opened the CHEST. . .', 40, 700);
    delay(800);
    gotoXY(1, 5);
    TypeWrite('YOU got: ', 40, 700);
    TypeWrite(RIT, 40, 700);
  end;
  case RIT of
    'HEAL POTION': inventory[iHP_POT] := inventory[iHP_POT] + 1;
    'ENERGY POTION': inventory[iENERGY_POT] := inventory[iENERGY_POT] + 1;
    'MONEY': stats[pMONEY] := stats[pMONEY] + Random(20);
    'NONE': begin delay(1200); exit; end;
  end;
  NowXY += 1;
  GetMADNESS;
  delay(1200);
  Playmus('start_2.wav', false);
end;

procedure FIGHT;
var
  REQ_ENERGY: integer;
  action, itemAction: char;
  playerDamage, enemyDamage: integer;
  turnTaken: boolean;
  bonus_damage, armor_defence: real;
begin
  Playmus('start_3.wav', false);
  
  case equippedWeapon of
    iARMS: bonus_damage := 1;
    iSTICK: bonus_damage := 1.1;
    iSWORD: bonus_damage := 1.4;
    iBOW: bonus_damage := 1.5;
  end;
  
  if isArmorEquipped then
    armor_defence := 1.2
  else
    armor_defence := 1;
  
  
  ClrScr;
  
  if (EVNT = 'Goblin') or (EVNT = 'Slime') or (EVNT = 'Dragon') or (EVNT = 'Wizard') or (EVNT = 'Zombie') or (EVNT = 'Ghost') or (EVNT = 'Demon') then
  begin
    IS_PLAYER_FIGHTING := true;
    IS_PLAYER_LOSE := false;
    IS_PLAYER_WIN := false;
    while IS_PLAYER_FIGHTING do
    begin
      ClrScr;
      TextColor(10);
      writeln('======= PLAYER =======');
      writeln('LVL: ' + stats[pLVL].ToString);
      writeln('HP: ' + stats[pHP].ToString + '/' + stats[pMaxHP].ToString);
      writeln('EN: ' + stats[pENERGY].ToString + '/' + stats[pMaxENERGY].ToString);
      write('WEAPON: ');
      if equippedWeapon <> iARMS then writeln(GetItemName(equippedWeapon)) else writeln('ARMS');
      writeln('======================');
      writeln;
      TextColor(12);
      writeln('======= ENEMY ========');
      writeln(EVNT + ' LVL: ' + VLVL.ToString);
      writeln(EVNT + ' HP: ' + VHP.ToString);
      writeln('======================');
      writeln;
      TextColor(6);
      writeln('---- MOVE LIST ----');
      case equippedWeapon of
        iSWORD, iARMS, iSTICK: REQ_ENERGY := 10;
        iBOW: REQ_ENERGY := 20;
      end;
      writeln('1. ATTACK [-' + REQ_ENERGY.ToString + ']');
      writeln('2. USE ITEM');
      writeln('3. RUN AWAY');
      writeln('-------------------');
      write('Choose action: ');
      ClearKeyBuffer;
      action := ReadKey;
      turnTaken := false;
      writeln; 
      if action = '1' then
      begin
        if stats[pENERGY] >= REQ_ENERGY then
        begin
          stats[pENERGY] := stats[pENERGY] - REQ_ENERGY;
          playerDamage := Round((10 + Random(5)) * (1 + (stats[pLVL] - 1) * 0.2) * bonus_damage);
          VHP := VHP - playerDamage;
          System.Console.Beep(800, 100);
          TextColor(LightGreen);
          writeln('You hit ' + EVNT + ' for ' + playerDamage.ToString + ' DMG!');
          turnTaken := true;
          if VHP <= 0 then
          begin
            VHP := 0;
            IS_PLAYER_WIN := true;
            IS_PLAYER_FIGHTING := false;
          end;
        end
        else
        begin
          TextColor(LightRed);
          writeln('NO ENERGY!');
          Delay(800);
          turnTaken := true;
        end;
      end
      else if action = '2' then
      begin
        writeln('1:HP(' + inventory[iHP_POT].ToString + ') 2:EN(' + inventory[iENERGY_POT].ToString + ') 0:Back');
        write('Select item: ');
        ClearKeyBuffer;
        itemAction := ReadKey;
        writeln;
        if itemAction = '1' then
        begin
          if inventory[iHP_POT] > 0 then
          begin
            inventory[iHP_POT] := inventory[iHP_POT] - 1;
            stats[pHP] := stats[pHP] + 50;
            if stats[pHP] > stats[pMaxHP] then stats[pHP] := stats[pMaxHP];
            System.Console.Beep(600, 200);
            writeln('Used HP Potion (+50 HP)');
            turnTaken := true;
          end else begin writeln('No HP Potions!'); Delay(800); end;
        end
        else if itemAction = '2' then
        begin
          if inventory[iENERGY_POT] > 0 then
          begin
            inventory[iENERGY_POT] := inventory[iENERGY_POT] - 1;
            stats[pENERGY] := stats[pENERGY] + 30;
            if stats[pENERGY] > stats[pMaxENERGY] then stats[pENERGY] := stats[pMaxENERGY];
            System.Console.Beep(600, 200);
            writeln('Used Energy Potion (+30 EN)');
            turnTaken := true;
          end else begin writeln('No Energy Potions!'); Delay(800); end;
        end;
      end
      else if action = '3' then
      begin
        if Random <= 0.5 then
        begin
          Player.Stop;
          TextColor(Yellow);
          writeln('You successfully ran away!');
          ReadKey;
          IS_PLAYER_FIGHTING := false;
          NowXY += 1;
          GetMADNESS;
          Playmus('start_2.wav', false);
          exit;
        end
        else
        begin
          TextColor(LightRed);
          writeln('Failed to escape!');
          turnTaken := true;
        end;
      end;
      if IS_PLAYER_FIGHTING and turnTaken then
      begin
        enemyDamage := Round((basedamage + Random(4)) * (1 + (VLVL - 1) * 0.2) / armor_defence);
        stats[pHP] := stats[pHP] - enemyDamage;
        System.Console.Beep(400, 150);
        TextColor(LightRed);
        writeln(EVNT + ' hits you for ' + (enemyDamage.ToString) + ' DMG!');
        if stats[pHP] <= 0 then
        begin
          stats[pHP] := 0;
          IS_PLAYER_LOSE := true;
          IS_PLAYER_FIGHTING := false;
        end;
      end;
      if turnTaken then Delay(1200);
    end;
    ClrScr;
    if IS_PLAYER_WIN then
    begin
      player.Stop;
      var rewardXP := Round(VLVL * 35);
      var rewardMoney := Round(VLVL * 5);
      stats[pXP] := stats[pXP] + rewardXP;
      stats[pMONEY] := stats[pMONEY] + rewardMoney;
      ClearKeyBuffer;
      TextColor(Yellow);
      writeln('===================================');
      writeln('Victory! Defeated ' + EVNT + '!');
      writeln('XP: +' + rewardXP.ToString + ' | Gold: +' + rewardMoney.ToString);
      writeln('===================================');
      CheckLevelUp;
      NowXY += 1;
      GetMADNESS;
      ReadKey;
    end
     else if IS_PLAYER_LOSE then
    begin
      player.Stop;
      TextColor(Red);
      gotoXY(WindowWidth div 2 - 13, WindowHeight div 2); 
      TypeWrite('Next time be CAREFUL . . .', 250, 400);
      delay(1000);
      clrscr;
      WriteART;
      
      gotoXY(1, 1); writeln('===================================');
      gotoXY(1, 2); writeln('GAME OVER! Killed by ' + EVNT);
      gotoXY(1, 3); writeln('PERMADEATH: Returning to menu...');
      gotoXY(1, 4); writeln('===================================');
      Playmus('end.wav', true);
      
      ClearKeyBuffer;
      ReadKey;
      player.Stop;
      
      IsKillDEATH := True;
      
      SetConsoleForArt(95, 28);
      Delay(150);
      iet := false; 
      exit;         
    end;
  end;
  Playmus('start_2.wav', false);
end;

procedure vivod;
begin
  gotoXY(1, 3);
  write('XY: [ ' + x.ToString + ' | ' + y.ToString + ' ]');
end;

procedure SOMEEVNT;
var
  s: real;
  baseHP, baseEnergy: real;
  ichf: boolean;
begin
  VLVL := stats[pLVL] + Random(0, 2);
  if VLVL < 1 then VLVL := 1;
  ClearKeyBuffer;
  Randomize;
  s := Random;
  ichf := false;
  if s >= 0.70 then // 30% шанс (от 0.70 до 1.0)
  begin
    EVNT := 'Slime';
    baseHP := 20;
    baseEnergy := 10;
    basedamage := 10;
  end
  else if s >= 0.50 then // 20% шанс (от 0.50 до 0.70)
  begin
    EVNT := 'Zombie';
    baseHP := 30;
    baseEnergy := 5;
    baseDamage := 11;
  end
  else if s >= 0.35 then // 15% шанс (от 0.35 до 0.50)
  begin
    EVNT := 'Goblin';
    baseHP := 40;
    baseEnergy := 25;
    basedamage := 13;
  end
  else if s >= 0.25 then // 10% шанс (от 0.25 до 0.35)
  begin
    EVNT := 'Wizard';
    baseHP := 50;
    baseEnergy := 60;
    basedamage := 14;
  end
  else if s >= 0.15 then // 10% шанс (от 0.15 до 0.25)
  begin
    EVNT := 'Ghost';
    baseHP := 45;
    baseEnergy := 50;
    baseDamage := 14;
  end
  else if s >= 0.08 then // 7% шанс (от 0.08 до 0.15)
  begin
    EVNT := 'Demon';
    baseHP := 100;
    baseEnergy := 100;
    baseDamage := 16;
  end
  else if s >= 0.03 then // 5% шанс (от 0.03 до 0.08)
  begin
    EVNT := 'Chest';
    ichf := true;
    baseHP := 0;
    baseEnergy := 0;
  end
  else // 3% шанс (от 0.00 до 0.03)
  begin
    EVNT := 'Dragon';
    baseHP := 150;
    baseEnergy := 90;
    VLVL := VLVL + 2;
    basedamage := 17;
  end;
  VHP := Round(baseHP * (1 + (VLVL - 1) * 0.3));
  VENERGY := Round(baseEnergy * (1 + (VLVL - 1) * 0.2));
  
  gotoXY(1, 5);
  TextColor(LightRed);
  write('SOMETHING Happened!');
  System.Console.Beep(440, 150);
  System.Console.Beep(330, 250);
  Delay(800);
  ClrScr;
  player.Stop;
  gotoXY(1, 5);
  TypeWrite('YOU meet . . . ', 60, 700);
  Delay(400);
  TypeWrite(EVNT, 100, 700);
  if ichf then
  begin
    Delay(1000);
    FIND;
  end
  else
  begin
    Delay(1000);
    FIGHT;
  end;
end;

procedure radn;
var
  isAlreadyVisited: boolean;
begin
  if (x = 0) and (y = 0) then exit;
  SOMETHING := 0.5;
  isAlreadyVisited := false;
  
  if historyCount > 0 then
  begin
    for var i := 1 to historyCount do
    begin
      if (historyX[i] = x) and (historyY[i] = y) then
      begin
        isAlreadyVisited := true;
        break;
      end;
    end;
  end;
  
  if isAlreadyVisited then
  begin
    gotoXY(1, 5);
    write('NOTHING Happened (Visited)');
    Delay(1000);
  end
  else if Random <= SOMETHING then
  begin
    nothingStreak := 0;
    if historyCount < MAX_XY then
    begin
      historyCount := historyCount + 1;
      historyX[historyCount] := x;
      historyY[historyCount] := y;
    end;
    SOMEEVNT;
  end
  else
  begin
    nothingStreak := nothingStreak + 1;
    gotoXY(1, 5);
    
    if nothingStreak > 2 then
    begin
      TextColor(DarkGray);
      write('THERE IS NOTHING THERE');
      nothingStreak := 0; // Сбрасываем серию после срабатывания
      NowXY += 1;
      if historyCount < MAX_XY then
      begin
        historyCount := historyCount + 1;
        historyX[historyCount] := x;
        historyY[historyCount] := y;
      end;
    end
    else
    begin
      write('NOTHING Happened');
    end;
    
    Delay(1000);
  end;
end;


procedure PlayGame;
begin
  InitGame;
  StarGame;
  Playmus('start_2.wav', false); 
  iet := true;
  while iet do
  begin
    ClrScr;
    ridivivod;
    if not iet then break;
    vivod;
    radn;
  end;
end;

procedure README;
var
  keyInfo: System.ConsoleKeyInfo;
  text: array[1..7] of string;
  currentIndex: integer;
begin
  text[1] := '1. THIS IS 1.0 RELEASE VERSION, IF YOU NOTICE BUGS TEXT ME OR FIX YOURSELF.';
  text[2] := '2. IN FUTURE I WELL ADD MORE: ITEMS IN CHOP; ASCII GRAPHICS; NPCS; BOSSES.';
  text[3] := '3. MAIN MECHANIC OF PSYCHO-RPG PRETTY SIMPLE: READ X AND Y COORDINATES AND FIGHT OR WILL HAPPEN NOTHING.';
  text[4] := '4. YOU NEED TO BEAT ALL 9801 LOCATES TO WIN.';
  text[5] := '5. BUT IN THE END YOU WILL MEET . . .';
  text[6] := 'YOU MUST FIND ABOUT IT YOURSELF!!!';
  text[7] := 'VENERGY still not use... I''m too lazy. In next updates it will work.';
  
  Player.Stop;
  ClrScr;
  TextColor(Red);
  gotoXY(WindowWidth div 2 - 20, 1);
  writeln('=============== READ ME ===============');
  writeln;
  writeln('THANKS FOR PLAYING! READ THIS BEFORE STARTING: ');
  writeln;
  writeln('press <ENTER> to continue');
  
  // 1. Ждем первого нажатия Enter для начала просмотра
  repeat
    keyInfo := System.Console.ReadKey(true);
  until keyInfo.Key = System.ConsoleKey.Enter;
  System.Console.Beep(800, 100);
  
  currentIndex := 1;
  
  // Цикл отображения и переключения сообщений
  while true do
  begin
    ClrScr;
    TextColor(Red);
    gotoXY(WindowWidth div 2 - 20, 1);
    writeln('=============== READ ME ===============');
    writeln;
    
    // Вывод текста текущего сообщения
    TextColor(LightGray);
    writeln(text[currentIndex]);
    writeln;
    writeln;
    
    // Вывод подсказок по управлению
    TextColor(DarkGray);
    writeln('---------------------------------------');
    writeln('Page ' + currentIndex.ToString + ' of 7');
    if currentIndex > 1 then
      write('[<-] Prev   ');
    if currentIndex < 7 then
      write('[->] Next   ');
    if currentIndex = 7 then
    begin
      TextColor(Yellow);
      write('Press <ENTER> to return to menu');
    end;
    
    // Чтение клавиш навигации
    keyInfo := System.Console.ReadKey(true);
    
    case keyInfo.Key of
      System.ConsoleKey.RightArrow:
        if currentIndex < 7 then 
        begin
          currentIndex := currentIndex + 1;
          System.Console.Beep(900, 50);
        end;
      
      System.ConsoleKey.LeftArrow:
        if currentIndex > 1 then 
        begin
          currentIndex := currentIndex - 1;
          System.Console.Beep(900, 50);
        end;
      
      System.ConsoleKey.Enter:
        if currentIndex = 7 then 
        begin
          System.Console.Beep(1000, 100);
          break; // Выход из цикла и возврат в MainMenu
        end;
    end;
  end;
end;

procedure CheckDEATH;
begin
  DEAPH_PR := '';
  if IsKillDEATH then
  begin
    TextColor(Red);
    case EVNT of
      'Dragon': DEAPH_PR := 'Dragon is Strongest... Should use ARMOR and Stronger Weapon';
      'Demon':  DEAPH_PR := 'Demon... Deadly Creature. Use more Heal Potion';
      'Ghost':  DEAPH_PR := 'The Ghost is same strong as Wizard...';
    else
      DEAPH_PR := 'Next time Buy more Potion...';
    end;
  end
  else if IsMadnessDEATH then
  begin
    TextColor(LightMagenta);
    DEAPH_PR := 'Madness ABSORBED your Mindness... Do not skimp on Mindness Potion.';
  end;
end;

procedure WriteWrappedText(text: string; startX, startY, maxWidth: integer);
var
  words: array of string;
  currentLine: string;
  currentY: integer;
begin
  words := text.Split(' ');
  currentLine := '';
  currentY := startY;
  
  for var i := 0 to words.High do
  begin
    if Length(currentLine) + Length(words[i]) + 1 <= maxWidth then
    begin
      if currentLine <> '' then
        currentLine := currentLine + ' ';
      currentLine := currentLine + words[i];
    end
    else
    begin
      // Центрируем текущую строку внутри рамки и выводим
      GotoXY(startX + (maxWidth - Length(currentLine)) div 2, currentY);
      Write(currentLine);
      currentY := currentY + 1;
      currentLine := words[i];
    end;
  end;
  
  // Выводим последнюю оставшуюся строку
  if currentLine <> '' then
  begin
    GotoXY(startX + (maxWidth - Length(currentLine)) div 2, currentY);
    Write(currentLine);
  end;
end;

procedure MainMenu;
var
  keyInfo: System.ConsoleKeyInfo;
  vib: string;
  art: array[1..23] of string;
  i, vibY, vibX: integer;
begin
  art[1]  := '       .           *                        *         .                                    ';
  art[2]  := '                               .                                                           ';
  art[3]  := '    *                                      *               .                               ';
  art[4]  := '         .                                                /\                               ';
  art[5]  := '                                                         //\\                              ';
  art[6]  := '  |  |  |  |                              ______________///\\\______________       |  |    ';
  art[7]  := '  |  |  |  |  |  |  |                    /              \\\///              \      |  |  | ';
  art[8]  := '  |  |  |  |  |  |  |  |  . . _ _ _      \___________/\/\/\/\/\/\___________/      |  |  | ';
  art[9]  := '  |  |  |  |  |  |  |  | : : : : : :                                               |  |  | ';
  art[10] := '                    /\                                                             |  |    ';
  art[11] := '                    \/                                                                     ';
  art[12] := '         (_______/\/\/\/\_______)                                                          ';
  art[13] := '                                                                                           ';
  art[14] := '                                                                                           ';
  art[15] := '                                          _                               _                ';
  art[16] := '        (_________/\/\/\_________)       /______________/\/\/\_____________\               ';
  art[17] := '                   <  >                  \_____________/ /  \ \____________/               ';
  art[18] := '                    \/                                 \ \  / /                            ';
  art[19] := '                                                        \ \/ /                             ';
  art[20] := '                                                         \  /                              ';
  art[21] := '                                                          \/                               ';
  art[22] := '                                                                                           ';
  art[23] := '                                                                                           ';
  
  // Бесконечный цикл меню
  while true do
  begin
    vib := '->';
    vibY := 13;
    vibX := 17;
    ClrScr;
    playmus('start_2.wav', false);
    
    TextColor(DarkGray);
    for i := 1 to 23 do
    begin
      GotoXY(1, i);
      Write(art[i]);
    end;
    
    TextColor(LightGray);
    GotoXY(55, 10); Write('PSYCHO RPG');
    
    // Проверка смерти и вывод подсказки ниже названия игры с переносом
    CheckDEATH;
    if DEAPH_PR <> '' then
    begin
      WriteWrappedText(DEAPH_PR, 43, 12, 34);
      TextColor(LightGray);
    end;

    
    GotoXY(19, 13); Write('START');
    GotoXY(19, 14); Write('EXIT');
    GotoXY(18, 15); Write('READ ME');
    
    System.Console.CursorVisible := false;
    
    GotoXY(vibX, vibY); 
    Write(vib);
    
    repeat
      keyInfo := System.Console.ReadKey(true);
      GotoXY(vibX, vibY);
      Write('  ');
      
      case keyInfo.Key of
        System.ConsoleKey.UpArrow:
        if vibY > 13 then vibY := vibY - 1 else vibY := 15;
        System.ConsoleKey.DownArrow:
        if vibY < 15 then vibY := vibY + 1 else vibY := 13;
      end;
      
      if vibY = 15 then vibX := 16 else vibX := 17;
      
      GotoXY(vibX, vibY);
      Write(vib);
    until keyInfo.Key = System.ConsoleKey.Enter;
    
    case vibY of
      13: 
        begin
          PlayGame;
        end;
      14: exit; 
      15: README; // После выполнения README цикл повторится сам
    end;
  end;
end;


begin
  MainMenu;
end.