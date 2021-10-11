////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Project   : Project1
//  * Unit Name : Unit1
//  * Purpose   : Демонстрация работы компонента TFWTrayIcon
//  * Author    : Александр (Rouse_) Багель
//  * Copyright : © Fangorn Wizards Lab 1998 - 2003.
//  * Version   : 1.00
//  ****************************************************************************
//

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, FWTrayIcon, StdCtrls, ExtCtrls, ExtDlgs, Spin, ComCtrls,
  ImgList, Menus, ShellAPI, FWHint;

type
  TForm1 = class(TForm)
    OpenPictureDialog1: TOpenPictureDialog;
    ImageList1: TImageList;
    FWTrayIcon1: TFWTrayIcon;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    CheckBox4: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox2: TCheckBox;
    LabeledEdit1: TLabeledEdit;
    CheckBox1: TCheckBox;
    TabSheet2: TTabSheet;
    Image1: TImage;
    Button1: TButton;
    Button2: TButton;
    TabSheet3: TTabSheet;
    CheckBox5: TCheckBox;
    RadioGroup1: TRadioGroup;
    Edit1: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    SpinEdit2: TSpinEdit;
    SpinEdit3: TSpinEdit;
    Label6: TLabel;
    Label7: TLabel;
    SpinEdit4: TSpinEdit;
    TabSheet4: TTabSheet;
    LabeledEdit2: TLabeledEdit;
    Label3: TLabel;
    Memo1: TMemo;
    SpinEdit1: TSpinEdit;
    Label1: TLabel;
    ComboBox1: TComboBoxEx;
    Button3: TButton;
    Label2: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    TabSheet5: TTabSheet;
    Bevel5: TBevel;
    Label8: TLabel;
    HotKey1: THotKey;
    Label9: TLabel;
    ComboBox2: TComboBox;
    RadioGroup2: TRadioGroup;
    Label10: TLabel;
    ComboBox3: TComboBox;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    CheckBox6: TCheckBox;
    Button4: TButton;
    TabSheet6: TTabSheet;
    ListBox1: TListBox;
    FWHint1: TFWHint;
    procedure CheckBox1Click(Sender: TObject);
    procedure LabeledEdit1Change(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox5Click(Sender: TObject);
    procedure FWTrayIcon1Animated(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure SpinEdit2Change(Sender: TObject);
    procedure SpinEdit3Change(Sender: TObject);
    procedure SpinEdit4Change(Sender: TObject);
    procedure HotKey1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure ComboBox3Change(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
    procedure CheckBox6Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FWTrayIcon1Click(Sender: TObject);
    procedure FWTrayIcon1Close(Sender: TObject);
    procedure FWTrayIcon1DblClick(Sender: TObject);
    procedure FWTrayIcon1Hide(Sender: TObject);
    procedure FWTrayIcon1Loaded(Sender: TObject);
    procedure FWTrayIcon1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FWTrayIcon1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FWTrayIcon1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FWTrayIcon1Popup(Sender: TObject);
    procedure FWTrayIcon1Show(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure FWTrayIcon1BalloonHide(Sender: TObject);
    procedure FWTrayIcon1BalloonShow(Sender: TObject);
    procedure FWTrayIcon1BalloonTimeout(Sender: TObject);
    procedure FWTrayIcon1BalloonUserClick(Sender: TObject);
  end;

  // Структура для получения списка текущий процессов и их параметров
  TProcessEntry32 = packed record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ProcessID: DWORD;
    th32DefaultHeapID: DWORD;
    th32ModuleID: DWORD;
    cntThreads: DWORD;
    th32ParentProcessID: DWORD;
    pcPriClassBase: Longint;
    dwFlags: DWORD;
    szExeFile: array [0..MAX_PATH - 1] of WideChar;
  end;

  function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): THandle;
    stdcall; external 'KERNEL32.DLL';

  function Process32First(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL;
    stdcall; external 'KERNEL32.DLL' name 'Process32FirstW';

  function Process32Next(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL;
    stdcall; external 'KERNEL32.DLL' name 'Process32NextW';

var
  Form1: TForm1;

implementation

{$R *.dfm}

//  Изменение видимости иконки в трее
// =============================================================================
procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  FWTrayIcon1.Visible := CheckBox1.Checked;
end;

//  Изменение хинта иконки
// =============================================================================
procedure TForm1.LabeledEdit1Change(Sender: TObject);
begin
  FWTrayIcon1.Hint := LabeledEdit1.Text; 
end;

//  Сворачивать форму в трей или не нужно
// =============================================================================
procedure TForm1.CheckBox2Click(Sender: TObject);
begin
  FWTrayIcon1.MinimizeToTray := CheckBox2.Checked;
end;

//  Сворачивать форму в трей при закрытии или не нужно
// =============================================================================
procedure TForm1.CheckBox3Click(Sender: TObject);
begin
  FWTrayIcon1.CloseToTray := CheckBox3.Checked;
  // Обратите внимание - если данная опция компонента включена,
  // то у формы не будут срабатывать события OnClose и OnCloseQuery
  // Что вполне логично, так как форма не закрывается.
  // Вместо этого события будет вызываться TFWTrayIcon.OnClose
  // извещающий вас о попытке закрытия формы.
end;

//  Скрытием\показом формы управляет компонент
// =============================================================================
procedure TForm1.CheckBox4Click(Sender: TObject);
begin
  FWTrayIcon1.AutoShowHide := CheckBox4.Checked;
  // Если данная опция отключена, то вместо скрытия показа приложения,
  // в PopupMenu ассоциированным с компонентом(если таковое имеется),
  // ищется пункт меню по умолчанию и, если таковой найден, вызывается его обработчик OnClick.
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Image1.Picture.Icon := FWTrayIcon1.Icon;
  ComboBox1.ItemIndex := 1;
end;

//  Загрузить и использовать новую иконку в качестве основной
// =============================================================================
procedure TForm1.Button1Click(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
    FWTrayIcon1.Icon.LoadFromFile(OpenPictureDialog1.FileName);
  Image1.Picture.Icon.Assign(FWTrayIcon1.Icon);
end;

//  Очистить основную иконку
// =============================================================================
procedure TForm1.Button2Click(Sender: TObject);
begin
  FWTrayIcon1.Icon := nil;
  // При очистке - изображение берется из иконки приложения
  Image1.Picture.Icon := FWTrayIcon1.Icon;
end;

//  Отображение BaloonHint
// =============================================================================
procedure TForm1.Button3Click(Sender: TObject);
begin
  FWTrayIcon1.ShowBalloonHint(Memo1.Text, LabeledEdit2.Text,
    TFWBalloonHintStyle(ComboBox1.ItemIndex), SpinEdit1.Value);
end;

//  Включение - выключение анимации
// =============================================================================
procedure TForm1.CheckBox5Click(Sender: TObject);
begin
  FWTrayIcon1.Animate.Active := CheckBox5.Checked;
  Edit1.Text := IntToStr(FWTrayIcon1.Animate.CurrentImageIndex);
end;

//  Событие срабатывает при изменении номера кадра анимации
// =============================================================================
procedure TForm1.FWTrayIcon1Animated(Sender: TObject);
begin
  Edit1.Text := IntToStr(FWTrayIcon1.Animate.CurrentImageIndex);
  // также можно и самому устанавливать текущий кадр анимации
  // FWTrayIcon1.Animate.CurrentImageIndex := 10;
  ListBox1.Items.Add('OnAnimated');
end;

//  Изменение стиля анимации
// =============================================================================
procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
  FWTrayIcon1.Animate.Style := TFWAnimateStyle(RadioGroup1.ItemIndex);
end;

//  Изменение скорости анимации
// =============================================================================
procedure TForm1.SpinEdit2Change(Sender: TObject);
begin
  FWTrayIcon1.Animate.Time := SpinEdit2.Value;
end;

//  Изменение начального кадра анимации
// =============================================================================
procedure TForm1.SpinEdit3Change(Sender: TObject);
begin
  FWTrayIcon1.Animate.AnimFrom := SpinEdit3.Value;
  SpinEdit4.MinValue := SpinEdit3.Value + 1;
end;

//  Изменение конечного кадра анимации
// =============================================================================
procedure TForm1.SpinEdit4Change(Sender: TObject);
begin
  FWTrayIcon1.Animate.AnimTo := SpinEdit4.Value;
  SpinEdit3.MaxValue := SpinEdit4.Value - 1;
end;

//  Изменение горячей клавиши
// =============================================================================
procedure TForm1.HotKey1Change(Sender: TObject);
begin
  FWTrayIcon1.ShortCut := HotKey1.HotKey;
end;

//  Изменение кнопки по умолчанию
// =============================================================================
procedure TForm1.ComboBox2Change(Sender: TObject);
begin
  FWTrayIcon1.ShowHideBtn := TFWShowHideBtn(ComboBox2.ItemIndex);
end;

//  Изменение кнопки контектсного меню
// =============================================================================
procedure TForm1.ComboBox3Change(Sender: TObject);
begin
  FWTrayIcon1.PopupBtn := TFWShowHideBtn(ComboBox3.ItemIndex);
end;

//  Изменение стиля реакции по щелчку на иконке
// =============================================================================
procedure TForm1.RadioGroup2Click(Sender: TObject);
begin
  FWTrayIcon1.ShowHideStyle := TFWShowHideStyle(RadioGroup2.ItemIndex);
end;

//  Скрыть/показать кнопку приложения
// =============================================================================
procedure TForm1.CheckBox6Click(Sender: TObject);
begin
  if CheckBox6.Checked then
    FWTrayIcon1.ShowTaskButton
  else
    FWTrayIcon1.HideTaskButton;
end;

//  Тест восстановления иконки при пересоздании панели инструментов
// =============================================================================
procedure TForm1.Button4Click(Sender: TObject);
const
  TH32CS_SNAPPROCESS  = $00000002;
var
  hProcessSnap: THandle;
  processEntry: TProcessEntry32;
begin
  if MessageBox(Handle,
    'Панель инструментов сейчас будет закрыта и запущена заново. Продолжить?',
    'Внимание!!!', MB_YESNO or MB_DEFBUTTON2 or MB_ICONQUESTION) = IDNO then Exit;
  hProcessSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hProcessSnap = INVALID_HANDLE_VALUE) then Exit;
  try
    FillChar(processEntry, SizeOf(TProcessEntry32), #0);
    processEntry.dwSize := SizeOf(TProcessEntry32);
    if not Process32First(hProcessSnap, processEntry) then Exit;
    repeat
      if UpperCase(ExtractFileName(processEntry.szExeFile)) = 'EXPLORER.EXE' then
      begin
        TerminateProcess(OpenProcess(PROCESS_ALL_ACCESS, False, processEntry.th32ProcessID), 0);
        Exit;
      end;
    // ищем пока не кончатся процессы
    until not Process32Next(hProcessSnap, processEntry);
  finally
    CloseHandle(hProcessSnap);
  end;
end;

//  Скрытие - показ формы
// =============================================================================
procedure TForm1.N1Click(Sender: TObject);
begin
  if FWTrayIcon1.IsMainFormHide then
     FWTrayIcon1.ShowMainForm
  else
    FWTrayIcon1.HideMainForm;
end;

//  Закрытие приложения 
// =============================================================================
procedure TForm1.N3Click(Sender: TObject);
begin
  FWTrayIcon1.CloseMainForm;
end;

//  Тут просто перечисление событий
// =============================================================================
procedure TForm1.FWTrayIcon1BalloonHide(Sender: TObject);
begin
  ListBox1.Items.Add('OnBalloonHide');
end;

procedure TForm1.FWTrayIcon1BalloonShow(Sender: TObject);
begin
  ListBox1.Items.Add('OnBalloonShow');
end;

procedure TForm1.FWTrayIcon1BalloonTimeout(Sender: TObject);
begin
  ListBox1.Items.Add('OnBalloonTimeout');
end;

procedure TForm1.FWTrayIcon1BalloonUserClick(Sender: TObject);
begin
  ListBox1.Items.Add('OnBalloonUserClick');
end;

procedure TForm1.FWTrayIcon1Click(Sender: TObject);
begin
  ListBox1.Items.Add('OnClick');
end;

procedure TForm1.FWTrayIcon1Close(Sender: TObject);
begin
  ListBox1.Items.Add('OnClose');
end;

procedure TForm1.FWTrayIcon1DblClick(Sender: TObject);
begin
  ListBox1.Items.Add('OnOnDblClick');
end;

procedure TForm1.FWTrayIcon1Hide(Sender: TObject);
begin
  ListBox1.Items.Add('OnHide');
end;

procedure TForm1.FWTrayIcon1Loaded(Sender: TObject);
begin
  ListBox1.Items.Add('OnLoaded');
end;

procedure TForm1.FWTrayIcon1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ListBox1.Items.Add('OnMouseDown');
end;

procedure TForm1.FWTrayIcon1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  ListBox1.Items.Add('OnMouseMove');
end;

procedure TForm1.FWTrayIcon1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ListBox1.Items.Add('OnMouseUp');
end;

procedure TForm1.FWTrayIcon1Popup(Sender: TObject);
begin
  ListBox1.Items.Add('OnPopUp');
end;

procedure TForm1.FWTrayIcon1Show(Sender: TObject);
begin
  ListBox1.Items.Add('OnShow');
end;

end.
