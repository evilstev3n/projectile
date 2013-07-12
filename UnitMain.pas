unit UnitMain;

interface

uses
  Windows
  , Messages
  , SysUtils
  , Variants
  , Classes
  , Graphics
  , Controls
  , Forms
  , Dialogs
  //, MMSystem
  , ExtCtrls
  , UnitSoundThread
  , StdCtrls;

const
  MAX_MINER = 3;
  MAX_ITEM = 50;
  MAX_WEAPON_EQUIPPED = 2;
  MAP_ITEM_NUM = 3;
  AREA_VIEW = 100;
  TIME_QUAD = 10000;
  TIME_SPAWN_MEDIC = 5000;
  TIME_SPAWN_ARMOR = 5000;
  TIME_SPAWN_QUAD = 1000;

type
  TSetting = record
    sound: Integer;
    ammocheck: Integer;
  end;

type
  TTypology = (
    I_PROJECTILE
    , I_MEDIC
    , I_ARMOR
    , I_QUAD
    , I_AMMO_ROCKET
    , I_AMMO_RAILGUN
    , I_AMMO_MEDIGUN
    );

type
  TItem = record
    sh: TShape;
    typology: TTypology;
    name: string;
    value: integer;
    speed: integer;
    dx: integer;
    dy: integer;
    owner: string;
    distance: Integer;
    distance_max: Integer;
    sound: string;
    mapitem: Integer;
  end;

type
  TWeapon = record
    name: string;
    ammo: Integer;
    ammo_clipsize: Integer;
    ammo_current: Integer;
    ammo_max: Integer;
    noreload: Integer;
    speed: Integer;
    damage: Integer;
    sound: string;
    color: TColor;
    timedeploy: Integer;
    timeinterval: Integer;
  end;

type
  TModel = record
    name: string;
    sound: string;
    Width: Integer;
    Height: Integer;
    color: TColor;
    max_health: Integer;
    speed: Integer;
  end;

type
  TMiner = record
    sh: TShape;
    health: Integer;
    armor: Integer;
    damage: Integer;
    name: string;
    weapon: Integer;
    weapon_equipped: array[0..MAX_WEAPON_EQUIPPED] of TWeapon;
    action: string;
    path_dest: TPoint;
    toattack: Integer;
    target: TPoint;
    model: TModel;
    tick_quad: Cardinal;
  end;

type
  TMapItem = record
    x: Integer;
    y: Integer;
    typology: TTypology;
    tick: Cardinal;
  end;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function findCollisions: Boolean;
    function calcolaTraiettoria(i: Integer): Integer;
    function getSlotItem: Integer;
    procedure init;
    procedure tick;
    procedure shoot(m: Integer; mdx, mdy: Integer; q: Integer = 1);
    procedure moveminer(m: TMiner; x, y: Integer);
    procedure ai;
    procedure updateGui;
    procedure emitSound(snd: string);
    procedure loadWeapons;
    procedure placeItems;
    procedure placeItemArmor(x, y: Integer; mid: Integer);
    procedure placeItemMedic(x, y: Integer; mid: Integer);
    procedure placeItemQuad(x, y: Integer; mid: Integer);
    procedure freeandnilItem(jj: Integer);

  end;

var
  Form1: TForm1;
  setting: TSetting;
  miner: array[0..MAX_MINER] of TMiner;
  item: array[0..MAX_ITEM] of TItem;
  weapon: array[0..MAX_WEAPON_EQUIPPED] of TWeapon;
  mapitem: array[0..MAP_ITEM_NUM] of TMapItem;
  interval: Integer = 1;
  checkPress: Integer;
  gdx: Integer;
  gdy: Integer;
  tickc: Cardinal;
  ticklast: Cardinal;
  p: TPoint;
  proj_count: Integer;
  proj_count_free: Integer;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Image1: TImage;
begin
  init;

  Image1 := TImage.Create(Self);
  with Image1 do
  begin
    Parent := Self;
    BringToFront;
    //Brush.Color := clBlue;
    Left := 400;
    Top := 200;
    Width := 20;
    Height := 40;
    Autosize := False;
  end;

end;

procedure TForm1.init;
var
  cc: Integer;
  tmpWeapon: TWeapon;
begin
  setting.sound := 1;
  setting.ammocheck := 1;

  tickc := GetTickCount;
  ticklast := ticklast;
  proj_count := 0;
  proj_count_free := 0;

  loadWeapons;

  // -----------------------------------------
  miner[0].sh := TShape.Create(self);
  with miner[0].sh do
  begin
    Parent := self;
    BringToFront;
    Brush.Color := clBlue;
    Left := 200;
    Top := 200;
    Width := 20;
    Height := 20;
  end;

  miner[0].health := 100;
  miner[0].name := 'Giulio';
  miner[0].weapon := 0;
  miner[0].damage := 1;
  miner[0].weapon_equipped[0] := weapon[0];
  miner[0].weapon_equipped[1] := weapon[1];
  miner[0].weapon_equipped[2] := weapon[2];

  //miner[0].action := 'SHOOT';
// -----------------------------------------
  miner[1].sh := TShape.Create(self);
  with miner[1].sh do
  begin
    Parent := self;
    BringToFront;
    Brush.Color := clGreen;
    Left := 100;
    Top := 10;
    Width := 20;
    Height := 20;
  end;

  miner[1].health := 100;
  miner[1].name := 'Bot1';
  miner[1].damage := 1;
  miner[1].weapon := 0;
  miner[1].weapon_equipped[0] := weapon[0];
  miner[1].weapon_equipped[1] := weapon[1];

  //miner[1].action := 'WALK';
  //miner[1].path_dest := Point(300, 300);
  // -----------------------------------------

  miner[2].sh := TShape.Create(self);
  with miner[2].sh do
  begin
    Parent := self;
    BringToFront;
    Brush.Color := clGreen;
    Left := 200;
    Top := 10;
    Width := 20;
    Height := 20;
  end;

  miner[2].health := 100;
  miner[2].name := 'Bot2';
  miner[2].damage := 1;
  miner[2].weapon := 1;
  miner[2].weapon_equipped[0] := weapon[0];
  miner[2].weapon_equipped[1] := weapon[1];

  // -----------------------------------------

  miner[3].sh := TShape.Create(self);
  with miner[3].sh do
  begin
    Parent := self;
    BringToFront;
    Brush.Color := clGreen;
    Left := 300;
    Top := 10;
    Width := 20;
    Height := 20;
  end;

  miner[3].health := 100;
  miner[3].name := 'Bot3';
  miner[3].damage := 1;
  miner[3].weapon := 1;
  miner[3].weapon_equipped[0] := weapon[0];
  miner[3].weapon_equipped[1] := weapon[1];

  // -----------------------------------------
  // resetto items
  // -----------------------------------------
  for cc := 0 to MAX_ITEM do
  begin
    freeandnilItem(cc);
  end;

  mapitem[0].x := 400;
  mapitem[0].y := 20;
  mapitem[0].typology := I_MEDIC;
  mapitem[0].tick := 1;

  mapitem[1].x := 400;
  mapitem[1].y := 60;
  mapitem[1].typology := I_ARMOR;
  mapitem[1].tick := 1;

  mapitem[2].x := 400;
  mapitem[2].y := 100;
  mapitem[2].typology := I_QUAD;
  mapitem[2].tick := 1;

  mapitem[3].x := 400;
  mapitem[3].y := 140;
  mapitem[3].typology := I_MEDIC;
  mapitem[3].tick := 1;

  placeItems;
end;

procedure TForm1.Label2Click(Sender: TObject);
begin
  if setting.sound = 1 then
    setting.sound := 0
  else
    setting.sound := 1;
end;

procedure TForm1.tick;
var
  cc: Integer;
begin
  if (GetAsyncKeyState(VK_F1) < 0) then
  begin
    miner[0].weapon := 0;
    emitSound('sound\change.wav');
  end;
  if (GetAsyncKeyState(VK_F2) < 0) then
  begin
    miner[0].weapon := 1;
    emitSound('sound\change.wav');
  end;
  if (GetAsyncKeyState(VK_F3) < 0) then
  begin
    miner[0].weapon := 2;
    emitSound('sound\change.wav');
  end;

  if (GetAsyncKeyState(VK_LEFT) < 0) then
  begin
    moveMiner(miner[0], -interval, 0);
    gdx := -1;
    gdy := 0;
  end
  else if (GetAsyncKeyState(VK_RIGHT) < 0) then
  begin
    moveMiner(miner[0], interval, 0);
    gdx := 1;
    gdy := 0;
  end

  else if (GetAsyncKeyState(VK_UP) < 0) then
  begin
    moveMiner(miner[0], 0, -interval);
    gdx := 0;
    gdy := -1;
  end
  else if (GetAsyncKeyState(VK_DOWN) < 0) then
  begin
    moveMiner(miner[0], 0, +interval);

    gdx := 0;
    gdy := 1;
  end;

  if (GetAsyncKeyState(VK_RETURN) < 0) then
  begin
    // sto sparando
    //shoot(0, gdx, gdy);
  end;

  if (GetAsyncKeyState(1) < 0) then
  begin
    GetCursorPos(p);
    //
    p.X := p.X - Form1.Left;
    p.Y := p.Y - Form1.Top - 20;
    //
    miner[0].target.X := p.X - miner[0].sh.Left;
    miner[0].target.Y := p.Y - miner[0].sh.Top;
    //
    shoot(0, calcolaTraiettoria(miner[0].target.X), calcolaTraiettoria(miner[0].target.Y));
  end;

  //
  // sposto proiettili
  for cc := 0 to MAX_ITEM do
  begin
    if item[cc].sh <> nil then
    begin
      if (item[cc].typology = I_PROJECTILE) then
      begin
        //muovo proiettile se esiste
        item[cc].sh.Left := item[cc].sh.Left + item[cc].dx;
        item[cc].sh.Top := item[cc].sh.Top + item[cc].dy;

        //
        if (item[cc].sh.Left > Form1.Width)
          or (item[cc].sh.Left < 0)
          or (item[cc].sh.Top > Form1.Height)
          or (item[cc].sh.Top < 0) then
        begin
          freeandnilItem(cc);
        end;
      end;
    end;
  end;

  if findCollisions = False then
  begin
    //
  end;

  {}
  ai;
  {}
  placeItems;
  {}
  updateGui;
end;

procedure TForm1.moveminer(m: TMiner; x, y: Integer);
begin
  if m.sh = nil then
    Exit;

  m.sh.Left := m.sh.Left + x;
  m.sh.Top := m.sh.Top + y;
end;

function TForm1.getSlotItem: Integer;
var
  jj: Integer;
begin
  Result := -1;
  for jj := 0 to MAX_ITEM do
  begin
    if item[jj].sh = nil then
    begin
      Result := jj;
      Exit;
    end;
  end;
end;

procedure TForm1.shoot(m: Integer; mdx, mdy: Integer; q: Integer = 1);
var
  jj: Integer;

begin
  tickc := GetTickCount;

  if tickc>=(ticklast + 200 + miner[m].weapon_equipped[miner[m].weapon].timeinterval) then
  begin
    ticklast := tickc;

    // prendo lo slot per spawnare l'item
    jj := getSlotItem;
    // non ci sono slot liberi
    if jj = -1 then
      Exit;

    if (setting.ammocheck = 1) then
    begin
      if (miner[m].weapon_equipped[miner[m].weapon].noreload = 0) then
      begin
        // non ho ammo infinite
        if (miner[m].weapon_equipped[miner[m].weapon].ammo <= 0) then
        begin
          if (miner[m].weapon_equipped[miner[m].weapon].ammo_current > 0) then
          begin
            // faccio reload
            miner[m].weapon_equipped[miner[m].weapon].ammo := miner[m].weapon_equipped[miner[m].weapon].ammo_clipsize;
            miner[m].weapon_equipped[miner[m].weapon].ammo_current := miner[m].weapon_equipped[miner[m].weapon].ammo_current - miner[m].weapon_equipped[miner[m].weapon].ammo;
            //
            emitSound('sound\change.wav');
          end
          else
          begin
            // out of ammo
          end;

          if (miner[m].weapon_equipped[miner[m].weapon].ammo_max = -1) then
          begin
            // ciclo continuo ma con reload
            miner[m].weapon_equipped[miner[m].weapon].ammo_current := miner[m].weapon_equipped[miner[m].weapon].ammo_clipsize;
          end;

          Exit;
        end;

        // calo
        miner[m].weapon_equipped[miner[m].weapon].ammo := miner[m].weapon_equipped[miner[m].weapon].ammo - 1;
      end; // controllo vincolo noreload
    end;

    item[jj].sh := TShape.Create(self);
    with item[jj].sh do
    begin
      Parent := self;
      Brush.Color := miner[m].weapon_equipped[miner[m].weapon].color;
      Left := miner[m].sh.Left + 0;
      Top := miner[m].sh.Top + 0;
      Width := 10;
      Height := 10;
      Shape := stEllipse;
      BringToFront;
    end;

    //caption := caption + '|';
    item[jj].owner := miner[m].name;
    item[jj].name := miner[m].weapon_equipped[miner[m].weapon].name;
    item[jj].value := (miner[m].weapon_equipped[miner[m].weapon].damage * miner[m].damage);
    item[jj].dx := mdx;
    item[jj].dy := mdy;
    item[jj].typology := I_PROJECTILE;

    //
    inc(proj_count);
    //
    emitSound(miner[m].weapon_equipped[miner[m].weapon].sound);
    //

    Exit;

  end;
end;

function TForm1.findCollisions: Boolean;
var
  jj: Integer;
  cc: Integer;
  tsnd: string;
  TestRect: TRect;
  DestRect: TRect;

  procedure collideQuad(jj: Integer; cc: Integer);
  begin
    miner[jj].tick_quad := GetTickCount;
    //
    miner[jj].damage := 4;
    //
    mapitem[item[cc].mapitem].tick := GetTickCount;
    //
    emitSound(item[cc].sound);
  end;
  procedure collideMedic(jj: Integer; cc: Integer);
  begin
    miner[jj].health := (miner[jj].health + item[cc].value);
    //
    mapitem[item[cc].mapitem].tick := GetTickCount;
    //
    emitSound(item[cc].sound);
  end;
  procedure collideArmor(jj: Integer; cc: Integer);
  begin
    miner[jj].armor := (miner[jj].armor + item[cc].value);
    //
    mapitem[item[cc].mapitem].tick := GetTickCount;
    //
    emitSound(item[cc].sound);
  end;
  procedure collideProjectile(jj: Integer; cc: Integer);
  begin
    // --------------------------------
    // tolgo i danni al giocatore
    // --------------------------------
    //miner[jj].armor := (miner[jj].armor - item[cc].value);
    //if (miner[jj].armor <= 0) then
    //begin
      //miner[jj].health := (miner[jj].health - Abs(miner[jj].armor));
      //miner[jj].armor := 0;
    //end;
    miner[jj].health := (miner[jj].health - item[cc].value);

    // --------------------------------
    tsnd := 'sound\pain100_1.wav';
    if (miner[jj].health < 200) then
    begin
      miner[jj].sh.Brush.Color := clOlive;
      tsnd := 'sound\pain100_1.wav';
    end;
    if (miner[jj].health < 100) then
    begin
      miner[jj].sh.Brush.Color := clOlive;
      tsnd := 'sound\pain100_1.wav';
    end;
    // --------------------------------
    if (miner[jj].health < 75) then
    begin
      miner[jj].sh.Brush.Color := clOlive;
      tsnd := 'sound\pain75_1.wav';
    end;
    // --------------------------------
    if (miner[jj].health < 50) then
    begin
      miner[jj].sh.Brush.Color := clOlive;
      tsnd := 'sound\pain50_1.wav';
    end;
    // --------------------------------
    if (miner[jj].health < 25) then
    begin
      miner[jj].sh.Brush.Color := clRed;
      tsnd := 'sound\pain25_1.wav';
    end;
    // --------------------------------
    if (miner[jj].health <= 0) then
    begin
      // morto
      miner[jj].sh.Free;
      miner[jj].sh := nil;
      //
      tsnd := 'sound\death1.wav';
    end;

    if (item[cc].value > 0) then
    begin
      // solo se faccio male

      if (miner[0].damage <> 1) then
        emitSound('sound\damage3.wav')
      else
        emitSound(tsnd);
    end;

  end;
begin
  Result := False;

  for jj := 0 to Length(miner) - 1 do
  begin

    if miner[jj].sh <> nil then
    begin

      // controllo scadenza quad
      if (miner[jj].damage <> 1) then
      begin
        if (GetTickCount>=(miner[jj].tick_quad + TIME_QUAD)) then
          miner[jj].damage := 1;
      end;

      (*
      if IntersectRect(TestRect, miner[0].sh.BoundsRect, miner[jj].sh.BoundsRect) then
      begin
        Result := True;
        Break;
      end; // collisione giocatori
      *)

      // collisione con proiettili
      for cc := 0 to MAX_ITEM do
      begin
        // per ogni item
        if (item[cc].sh <> nil) then
        begin

          if IntersectRect(TestRect, miner[jj].sh.BoundsRect, item[cc].sh.BoundsRect) then
          begin
            Result := True;

            if (item[cc].owner <> miner[jj].name) then
            begin
              if item[cc].typology = I_MEDIC then
              begin
                collideMedic(jj, cc);
              end;
              if item[cc].typology = I_ARMOR then
              begin
                collideArmor(jj, cc);
              end;
              if item[cc].typology = I_PROJECTILE then
              begin
                collideProjectile(jj, cc);
              end;
              if item[cc].typology = I_QUAD then
              begin
                collideQuad(jj, cc);
              end;

              // --------------------------------
              // distruggo l'item con cui ho colliso
              // --------------------------------
              freeandnilItem(cc);
            end;

            Break;
          end;
        end;
      end; // ciclo collisione proiettili
    end; // check esiste giocatore
  end;
end;

procedure TForm1.ai;
var
  cc: Integer;
  jj: Integer;
  tdist: TPoint;
  tre: TRect;
begin
  //
  for cc := 1 to Length(miner) - 1 do
  begin
    if miner[cc].sh <> nil then
    begin

      // controllo le distanze tra giocatori
      for jj := 0 to Length(miner) - 1 do
      begin
        if miner[jj].sh <> nil then
        begin
          if (miner[jj].name <> miner[cc].name) then
          begin
            // calcolo l'area visiva
            tre.Left := miner[jj].sh.Left - AREA_VIEW;
            tre.Right := miner[jj].sh.Left + AREA_VIEW;
            tre.Top := miner[jj].sh.Top - AREA_VIEW;
            tre.Bottom := miner[jj].sh.Top + AREA_VIEW;

            //caption := inttostr(tdist.X) + ',' + inttostr(tdist.Y);

            // se sotto una certa distanza sparo
            if ((miner[cc].sh.Left > tre.Left) and (miner[cc].sh.Left < tre.Right)
              and (miner[cc].sh.Top > tre.Top) and (miner[jj].sh.Top < tre.Bottom)) then
            begin
              miner[cc].target.X := (miner[jj].sh.Left - miner[cc].sh.Left);
              miner[cc].target.Y := (miner[jj].sh.Top - miner[cc].sh.Top);

              shoot(cc, calcolaTraiettoria(miner[cc].target.X), calcolaTraiettoria(miner[cc].target.Y));
            end;

          end;
        end;
      end; // controllo distanze

      if miner[cc].action = 'IDLE' then
      begin
        //
      end;
      if miner[cc].action = 'WALK' then
      begin
        //camminando
        //moveMiner(miner[cc], 0, 1);

        if (miner[cc].sh.Left < miner[cc].path_dest.X) then
          miner[cc].sh.Left := miner[cc].sh.Left + 1;

        if (miner[cc].sh.Top < miner[cc].path_dest.Y) then
          miner[cc].sh.Top := miner[cc].sh.Top + 1;

        if (miner[cc].sh.Left >= miner[cc].path_dest.X)
          and (miner[cc].sh.Top >= miner[cc].path_dest.Y) then
        begin
          miner[cc].action := 'IDLE';
        end;

      end;
      if miner[cc].action = 'SHOOT' then
      begin
        shoot(cc, -1, 0);
        miner[cc].action := 'IDLE';
      end;
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  tick;
end;

function TForm1.calcolaTraiettoria(i: Integer): Integer;
begin
  Result := (i * 3) div 100;
end;

procedure TForm1.updateGui;
var
  cc: Integer;
begin
  Label1.caption := IntToStr(proj_count) + '/' + IntToStr(proj_count_free)
    + #13#10 + 'Health: ' + IntToStr(miner[0].health) + #9 + ' Armor: ' + IntToStr(miner[0].armor) + #9 + ' Damage: ' + IntToStr(miner[0].damage)
    + #13#10 + 'Weapon: ' + miner[0].weapon_equipped[miner[0].weapon].name
    + #9 + 'Ammo: ' + IntToStr(miner[0].weapon_equipped[miner[0].weapon].ammo) + '/' + IntToStr(miner[0].weapon_equipped[miner[0].weapon].ammo_current);

  //Label2.caption := 'Sound: ' + IntToStr(setting.sound);
  Label2.Caption := '';
  for cc := 1 to MAX_MINER do
  begin
    Label2.Caption := Label2.Caption + #13#10 + 'Bot' + IntToStr(cc) + ' Health: ' + IntToStr(miner[cc].health) + ' Armor: ' + IntToStr(miner[cc].armor) + ' Damage: ' + IntToStr(miner[cc].Damage) + ' Weapon: ' + miner[cc].weapon_equipped[miner[cc].weapon].name;
    Label2.Caption := Label2.Caption + #9 + 'Ammo: ' + IntToStr(miner[cc].weapon_equipped[miner[cc].weapon].ammo) + '/' + IntToStr(miner[cc].weapon_equipped[miner[cc].weapon].ammo_current);
  end;

end;

procedure TForm1.emitSound(snd: string);
begin
  if setting.sound <> 1 then
    Exit;

  with TSoundThread.Create(true) do
  begin
    SetFileName(snd);
    FreeOnTerminate := true;
    Resume;
  end;

  (*
//PlaySound(PChar(snd), hInstance, SND_ASYNC or SND_MEMORY or SND_RESOURCE);
if FileExists(snd) then
begin
  sndPlaySound(PChar(snd),
    SND_ASYNC
    //SND_NODEFAULT or SND_ASYNC or SND_LOOP
    );
end;
*)
end;

procedure TForm1.loadWeapons;
begin
  weapon[0].name := 'Rocket';
  weapon[0].damage := 10;
  weapon[0].ammo_clipsize := 5;
  weapon[0].ammo := weapon[0].ammo_clipsize;
  weapon[0].ammo_current := 50;
  weapon[0].ammo_max := 50;
  weapon[0].sound := 'sound\rocklf1a.wav';
  weapon[0].color := clBlack;
  weapon[0].noreload := 0;
  weapon[0].timedeploy := 0;
  weapon[0].timeinterval := 0;
  //
  weapon[1].name := 'Railgun';
  weapon[1].damage := 1000;
  weapon[1].ammo_clipsize := 4;
  weapon[1].ammo := weapon[1].ammo_clipsize;
  weapon[1].ammo_current := 30;
  weapon[1].ammo_max := 30;
  weapon[1].sound := 'sound\railgf1a.wav';
  weapon[1].color := clLime;
  weapon[1].noreload := 0;
  weapon[1].timedeploy := 0;
  weapon[1].timeinterval := 1500;
  //
  weapon[2].name := 'Medigun';
  weapon[2].damage := -10;
  weapon[2].ammo_clipsize := 30;
  weapon[2].ammo := weapon[2].ammo_clipsize;
  weapon[2].ammo_current := 30;
  weapon[2].ammo_max := -1;
  weapon[2].noreload := 0;
  weapon[2].sound := '';
  weapon[2].color := clAqua;
  weapon[2].timedeploy := 0;
  weapon[2].timeinterval := 0;
end;

procedure TForm1.placeItemArmor(x, y: Integer; mid: Integer);
var
  jj: Integer;
begin
  jj := getSlotItem;
  if jj = -1 then
    Exit;

  item[jj].sh := TShape.Create(self);
  with item[jj].sh do
  begin
    Parent := self;
    BringToFront;
    Brush.Color := clYellow;
    Left := x;
    Top := y;
    Width := 15;
    Height := 15;
  end;
  item[jj].typology := I_ARMOR;
  item[jj].speed := 0;
  item[jj].owner := 'MAP';
  item[jj].value := 100;
  item[jj].sound := 'sound\ar2_pkup.wav';
  item[jj].mapitem := mid;
end;

procedure TForm1.placeItemMedic(x, y: Integer; mid: Integer);
var
  jj: Integer;
begin
  jj := getSlotItem;
  if jj = -1 then
    Exit;

  item[jj].sh := TShape.Create(self);
  with item[jj].sh do
  begin
    Parent := self;
    BringToFront;
    Brush.Color := clWhite;
    Left := x;
    Top := y;
    Width := 15;
    Height := 15;
  end;
  item[jj].typology := I_MEDIC;
  item[jj].speed := 0;
  item[jj].owner := 'MAP';
  item[jj].value := 100;
  item[jj].sound := 'sound\s_health.wav';
  item[jj].mapitem := mid;
end;

procedure TForm1.placeItemQuad(x, y: Integer; mid: Integer);
var
  jj: Integer;
begin
  jj := getSlotItem;
  if jj = -1 then
    Exit;

  item[jj].sh := TShape.Create(self);
  with item[jj].sh do
  begin
    Parent := self;
    BringToFront;
    Brush.Color := clDkGray;
    Left := x;
    Top := y;
    Width := 15;
    Height := 15;
  end;
  item[jj].typology := I_QUAD;
  item[jj].speed := 0;
  item[jj].owner := 'MAP';
  item[jj].value := 100;
  item[jj].sound := 'sound\quaddamage.wav';
  item[jj].mapitem := mid;
end;

procedure TForm1.freeandnilItem(jj: Integer);
begin
  item[jj].sh.Free;
  item[jj].sh := nil;
  inc(proj_count_free);
end;

procedure TForm1.placeItems;
var
  jj: Integer;
begin

  for jj := 0 to MAP_ITEM_NUM do
  begin
    // se diverso da zero significa che l'ho preso
    if (mapitem[jj].tick <> 0) then
    begin

      if (mapitem[jj].typology = I_MEDIC) and (GetTickCount>=(mapitem[jj].tick + TIME_SPAWN_MEDIC)) then
      begin
        mapitem[jj].tick := 0;
        placeItemMedic(mapitem[jj].x, mapitem[jj].y, jj);
      end;

      if (mapitem[jj].typology = I_ARMOR) and (GetTickCount>=(mapitem[jj].tick + TIME_SPAWN_ARMOR)) then
      begin
        mapitem[jj].tick := 0;
        placeItemArmor(mapitem[jj].x, mapitem[jj].y, jj);
      end;

      if (mapitem[jj].typology = I_QUAD) and (GetTickCount>=(mapitem[jj].tick + TIME_SPAWN_QUAD)) then
      begin
        mapitem[jj].tick := 0;
        placeItemQuad(mapitem[jj].x, mapitem[jj].y, jj);
      end;

    end;
  end;

end;

end.

