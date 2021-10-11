////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Project   : Fangorn Wizards Lab Exstension Library v1.35
//  * Unit Name : FWTrayIcon
//  * Purpose   : Клас для работы с системным треем.
//  * Author    : Александр (Rouse_) Багель
//  * Copyright : © Fangorn Wizards Lab 1998 - 2003.
//  * Version   : 1.17
//  ****************************************************************************
//
// Последние изменения:
// 20 марта 2003 - добавлено свойство ShortCut
// 24 марта 2005 - слегка причесан код, добавлены комментарии
//
// Дополнительная информация:
// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/reference/functions/shell_notifyicon.asp
// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/reference/structures/notifyicondata.asp
// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/commctls/tooltip/usingtooltips.asp
// http://msdn.microsoft.com/msdnmag/issues/02/11/cqa/default.aspx
//

unit FWTrayIcon;

interface

uses
  Windows, Messages, Classes, Menus,
  Graphics, Forms, SysUtils, Controls, ImgList, CommCtrl;

type
  // Этим мы будем ругаться :)
  TFWTrayException = class(Exception);

  // Кнопка для контекстного меню может быть разная
  TFWPopupBtn = (btnLeft, btnRight, btnMiddle);

  // Кнопка по умолчанию, также может быть разная ;)
  TFWShowHideBtn = TFWPopupBtn;

  // Два способа реагирования нашей иконки в трее:
  // на одинарный и на двойной щелчек
  TFWShowHideStyle = (shDoubleClick, shSingleClick);

  // Три стиля анимации иконки в трее
  // asLine - иконки показываются друг за другом из ImageList от первой по последнюю
  // asCircle - иконки показываются друг за другом из ImageList от первой по последнюю и обратно
  // asFlash - мигает иконка помещенная в св-во Icon
  TFWAnimateStyle = (asFlash, asLine, asCircle);

  // Стиль иконки при отображении BalloonHint
  TFWBalloonHintStyle = (bhsNone, bhsInfo, bhsWarning, bhsError);

  // Возможный диапазон задержки хинта
  TFWBalloonTimeout = 10..30;

  // Основная и дополнительная структура для работы с треем
  _NOTIFYICONDATAA_V1 = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array [0..63] of AnsiChar;
  end;

  DUMMYUNIONNAME = record
    case Integer of
      0: (
        uTimeout: UINT);
      1: (
        uVersion: UINT);
  end;

  _NOTIFYICONDATAA_V2 = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;

    // Расширение структуры для Shell32.dll версии пять
    szTip: array [0..MAXCHAR] of AnsiChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array [0..MAXBYTE] of AnsiChar;
    UNIONNAME: DUMMYUNIONNAME;
    //uTimeout: UINT;
    szInfoTitle:  array [0..63] of AnsiChar;
    dwInfoFlags: DWORD;

    // Расширение структуры для Shell32.dll версии шесть
    //guidItem: DWORD;
  end;

  // В эту структуру получим информацию о библиотеке
  PDllVersionInfo = ^TDllVersionInfo;
  TDllVersionInfo = packed record
    cbSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
  end;

  TFWTrayIcon = class;

  // Класс отвечающий за анимацию иконки в трее
  // Придется наслдоваться от TComponent
  TFWAnimate = class(TPersistent)
  private
    FOwner: TFWTrayIcon;
    FActive: Boolean;            // Флаг запуска - остановки анимации
    FAnimFrom: TImageIndex;      // Начальный кадр анимации
    FStyle: TFWAnimateStyle;     // Стиль анимации
    FTime: Integer;              // Скорость анимации
    FAnimTo: TImageIndex;        // Завершающий кадр анимации
    procedure SetAnimateStyle(const Value: TFWAnimateStyle);
    procedure SetAnimateTime(const Value: Integer);
    procedure SetImages(const Value: TImageList);
    function GetIndex: Integer;
    procedure SetIndex(Value: Integer);
    procedure SetActive(const Value: Boolean);
    function GetImages: TImageList;
  protected
    procedure Animated(const Value: Boolean); virtual;
    procedure RefreshTimer;
  public
    constructor Create(const AOwner: TFWTrayIcon);
    destructor Destroy; override;
    property CurrentImageIndex: Integer read Getindex write SetIndex;
  published
    property Active: Boolean read FActive write SetActive default False;
    property Images: TImageList read GetImages write SetImages;
    property Time: Integer read FTime write SetAnimateTime default 500;
    property AnimFrom: TImageIndex read FAnimFrom write FAnimFrom default -1;
    property AnimTo: TImageIndex read FAnimTo write FAnimTo default -1;
    property Style: TFWAnimateStyle read FStyle write SetAnimateStyle default asFlash;
  end;

  // Основной класс
  TFWTrayIcon = class(TComponent)
  private
    FAbout: String;
    FAnimate: TFWAnimate;

    FAnimateHandle: HWND;               // Хэндл таймера анимации
    FHandle: HWND;                      // Хэндл нашего компонента
    FOwnerHandle: HWND;                 // Хэндл формы

    FTrayIcon: _NOTIFYICONDATAA_V1;     // Структура для отображения иконки
    FPopupMenu: TPopupMenu;             // Контекстное меню компонента
    FIcon: TIcon;                       // Основная иконка для отображения
    FHint: String;                      // Подсказка для иконки
    FStartMinimized: Boolean;           // Флаг отвечающй за скрытие приложения при запуске

    FPopupBtn: TFWPopupBtn;             // Переменная указывает по какой кнопке
                                        // будет показываться контекстное меню

    FShowHideBtn: TFWShowHideBtn;       // Переменная указывает по какой кнопке
                                        // будет показываться и скрываться приложение

    FShowHideStyle: TFWShowHideStyle;   // Стиль показа-скрытия приложения (одинарный - двойной клик)

    FAutoShowHide: Boolean;             // Флаг определяющий, будет ли управлять показом
                                        // главного окна компонент или нет (если нет, то компонент
                                        // выполняет пункт меню по умолчанию у контекстного меню)

    FMinimizeToTray: Boolean;           // Флаг определяющий скрытие формы при минимизации
    FCloseToTray: Boolean;              // Флаг блокирующий закрытие приложения
                                        // и скрывающий главную форму при закрытии

    FDesignPreview: Boolean;            // Флаг, дающий возможность протестировать иконку в DegignTime

    FCloses: Boolean;                   // Флаг указывающий завершается ли программа или нет

    FShortCut: TShortCut;               // Горячая клавиша для анимации или выполнения пункта меню по умолчанию

    FVisible: Boolean;                  // Флаг показа иконки в трее...

    WM_TASKBARCREATED: Cardinal;        // Сообщение которое придет нам, после пересоздания панели...
                          
    // Переменные для событий
    FOnAnimated: TNotifyEvent;
    FOnClick: TNotifyEvent;
    FOnDblClick: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FOnMouseDown: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseUp: TMouseEvent;
    FOnPopup: TNotifyEvent;
    FOnShow: TNotifyEvent;
    FOnLoaded: TNotifyEvent;
    FOnClose: TNotifyEvent;
    FOnBalloonShow: TNotifyEvent;
    FOnBalloonHide: TNotifyEvent;
    FOnBalloonTimeout: TNotifyEvent;
    FOnBalloonUserClick: TNotifyEvent;

    FImages: TImageList;         // Иконки для анимации
    FImageChangeLink: TChangeLink;

    // Временные переменные необходимые для работы компонента
    FOldWndProc, FHookProc: Integer;      // Адреса старой и новой оконной функции
    FCurrentIcon: TIcon;                  // Текущая иконка для обновления
    FCurrentImage: Integer;               // Номер текущего кадра анимации
    FTmpStep: Integer;                    // Переменная определяющая направления анимации для asCircle
    FTmpHot: Integer;                     // Глобальная горячая клавиша :)
    FFirstChange: Boolean;                // Для правильно реакции на изменения в ImageList

    // Процедуры и функции отвечающие
    // за правильную реакцию компонента на изменения
    procedure SetDesignPreview(const Value: Boolean);
    procedure SetIcon(const Value: TIcon);
    procedure SetHint(const Value: String);
    procedure SetShortCut(const Value: TShortCut);
    function GetAnimate: Boolean;
    procedure SetVisible(const Value: Boolean);
    function IsMainFormHiden: Boolean;
    procedure SetCloseToTray(const Value: Boolean);
    procedure ImageListChange(Sender: TObject);
  protected
    // Вспомогательные процедуры

    // Оконная процедура нашего компонента
    procedure WndProc(var Message: TMessage); virtual;
    procedure UpdateTray; virtual;
    procedure ShowHideForm; virtual;
    // Процедурs подменяющbt главную оконную процедуру приложения и главной формы
    procedure HookWndProc(var Message: TMessage); virtual;
    function HookAppProc(var Message: TMessage): Boolean;

    procedure MouseDown(const State: TShiftState;
      const Button: TFWShowHideBtn; const MouseButton: TMouseButton); virtual;
    procedure MouseUp(const State: TShiftState; const MouseButton: TMouseButton); virtual;
    procedure DblClick(const Button: TFWShowHideBtn); virtual;
    procedure OnImageChange(Sender: TObject); virtual;
    class procedure AddInstande;
    class procedure ReleaseInstance;
    // Это вызовы нашх обработчиков
    procedure DoAnimate; virtual;
    procedure DoClick; virtual;
    procedure DoClose; virtual;
    procedure DoDblClick; virtual;
    procedure DoHide; virtual;
    procedure DoLoaded; virtual;
    procedure DoMouseDown(Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer); virtual;
    procedure DoMouseMove(Shift: TShiftState;
      X, Y: Integer); virtual;
    procedure DoMouseUp(Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer); virtual;
    procedure DoPopup; virtual;
    procedure DoShow; virtual;
    procedure DoBalloonShow; virtual;
    procedure DoBalloonHide; virtual;
    procedure DoBalloonTimeout; virtual;
    procedure DoBalloonUserClick; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Loaded; override;
    destructor Destroy; override;
    class function GetShellVersion: Integer;
    class function InstancesCount: Integer;
    // Процедуры управления главной формы
    procedure CloseMainForm; // Закрывает программу
    procedure HideMainForm;  // Прячет форму
    procedure ShowMainForm;  // Показывает форму
    procedure ShowTaskButton;
    procedure HideTaskButton;

    // Показываем BalloonHint - в качестве информационного сообщения
    function ShowBalloonHint(const Hint, Title: String;
      Style: TFWBalloonHintStyle; TimeOut: TFWBalloonTimeout): Boolean;

    // Свойства
    property Handle: HWND read FHandle;
    property IsMainFormHide: Boolean read IsMainFormHiden;
    property IsCloses: Boolean read FCloses;
    property IsAnimate: Boolean read GetAnimate;
    property Owner;
  published
    property About: String read FAbout write FAbout;
    property Animate: TFWAnimate read FAnimate write FAnimate;
    property PopupMenu: TPopupMenu read FPopupMenu write FPopupMenu;
    property Icon: TIcon read FIcon write SetIcon;
    property Hint: String read FHint write SetHint;
    property StartMinimized: Boolean read FStartMinimized write FStartMinimized default False;
    property PopupBtn: TFWPopupBtn read FPopupBtn write FPopupBtn default btnRight;
    property ShowHideBtn: TFWShowHideBtn read FShowHideBtn write FShowHideBtn default btnLeft;
    property ShowHideStyle: TFWShowHideStyle read FShowHideStyle write FShowHideStyle default shDoubleClick;
    property AutoShowHide: Boolean read FAutoShowHide write FAutoShowHide default True;
    property MinimizeToTray: Boolean read FMinimizeToTray write FMinimizeToTray default False;
    property CloseToTray: Boolean read FCloseToTray write SetCloseToTray default False;
    property DesignPreview: Boolean read FDesignPreview write SetDesignPreview default False;
    property ShortCut: TShortCut read FShortCut write SetShortCut default 0;
    property Visible: Boolean read FVisible write SetVisible default True;

    property OnAnimated: TNotifyEvent read FOnAnimated write FOnAnimated;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnLoaded: TNotifyEvent read FOnLoaded write FOnLoaded;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnBalloonShow: TNotifyEvent read FOnBalloonShow write FOnBalloonShow;
    property OnBalloonHide: TNotifyEvent read FOnBalloonHide write FOnBalloonHide;
    property OnBalloonTimeout: TNotifyEvent read FOnBalloonTimeout write FOnBalloonTimeout;
    property OnBalloonUserClick: TNotifyEvent read FOnBalloonUserClick write FOnBalloonUserClick;
  end;

implementation

uses Math;

  function Shell_NotifyIcon(dwMessage: DWORD; lpData: Pointer): BOOL; stdcall;
    external 'shell32.dll' name 'Shell_NotifyIconA';

const
  NIM_ADD         = $00000000;
  NIM_MODIFY      = $00000001;
  NIM_DELETE      = $00000002;

  NIF_MESSAGE     = $00000001;
  NIF_ICON        = $00000002;
  NIF_TIP         = $00000004;
  NIF_STATE       = $00000008;
  NIF_INFO        = $00000010;
  NIF_GUID        = $00000020;

  NIIF_NONE       = $00000000;
  NIIF_INFO       = $00000001;
  NIIF_WARNING    = $00000002;
  NIIF_ERROR      = $00000003;

  NIN_BALLOONSHOW      = WM_USER + 2;
  NIN_BALLOONHIDE      = WM_USER + 3;
  NIN_BALLOONTIMEOUT   = WM_USER + 4;
  NIN_BALLOONUSERCLICK = WM_USER + 5;

  NOTIFYICONDATA_SIZE = $58;
  NOTIFYICONDATA_V2_SIZE = $1E8;

  NEED_SHELL_VER = 5;

  SNoTimers = 'Not enough timers available';
  WM_ICON_MESSAGE = WM_USER + $4625;
  ANIMATE_TIMER = 100;

var
  FWTrayIconInstances: Integer = 0;

function GetShiftState: TShiftState;
begin
  Result := [];
  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then
    Include(Result, ssCtrl);
  if GetKeyState(VK_MENU) < 0 then
    Include(Result, ssAlt);
end;

{ TFWAnimate }

//  Запуск - остановка таймера анимации
// =============================================================================
procedure TFWAnimate.Animated(const Value: Boolean);
begin
  if Value then
  begin
    if FOwner.FAnimateHandle <> 0 then
      Exit
    else
      FOwner.FAnimateHandle :=
        SetTimer(FOwner.FHandle, ANIMATE_TIMER, FTime, nil);
  end
  else
  begin
    if FOwner.FAnimateHandle <> 0 then
      KillTimer(FOwner.FHandle, ANIMATE_TIMER);
    FOwner.FAnimateHandle := 0;
  end;
end;

constructor TFWAnimate.Create(const AOwner: TFWTrayIcon);
begin
  if AOwner = nil then
    raise TFWTrayException.Create('AOwner is nil');
  inherited Create;
  FOwner := AOwner;
  FActive := False;
  FTime := 500;
  FStyle := asFlash;
  FAnimFrom := -1;
  FAnimTo := -1;
end;

destructor TFWAnimate.Destroy;
begin
  Animated(False);
  inherited;
end;

function TFWAnimate.GetImages: TImageList;
begin
  Result := FOwner.FImages;
end;

//  Чтение значения текущего индекса картинки анимации
// =============================================================================
function TFWAnimate.Getindex: Integer;
begin
  Result := FOwner.FCurrentImage;
end;

//  Установка нового значения для таймера анимации
// =============================================================================
procedure TFWAnimate.RefreshTimer;
begin
  if FOwner.FAnimateHandle <> 0 then
    KillTimer(FOwner.FHandle, ANIMATE_TIMER);
  if FActive then
    FOwner.FAnimateHandle :=
      SetTimer(FOwner.FHandle, ANIMATE_TIMER, FTime, nil);
end;

//  Запуск - остановка анимации иконки
// =============================================================================
procedure TFWAnimate.SetActive(const Value: Boolean);
begin
  FActive := Value;
  if (csDesigning in FOwner.ComponentState) and not FOwner.DesignPreview then
  begin
    Animated(False);
    Exit;
  end;
  Animated(Value);
  if not Value then
  begin
    FOwner.FCurrentImage := 0;
    FOwner.FCurrentIcon.Assign(FOwner.FIcon);
    FOwner.FTrayIcon.hIcon := FOwner.FCurrentIcon.Handle;
    Shell_NotifyIcon(NIM_MODIFY, @FOwner.FTrayIcon);
  end;
end;

//  Установка нового стиля анимации
// =============================================================================
procedure TFWAnimate.SetAnimateStyle(const Value: TFWAnimateStyle);
begin
  if FStyle = Value then Exit;
  FStyle := Value;
  case Value of
    asFlash:
      FOwner.FCurrentImage := 0;
    asLine:
      FOwner.FCurrentImage := AnimFrom;
    asCircle:
    begin
      FOwner.FCurrentImage := AnimFrom;
      FOwner.FTmpStep := 1;
    end;
  end;
end;

procedure TFWAnimate.SetAnimateTime(const Value: Integer);
begin
  FTime := Value;
  RefreshTimer;
end;

//  Установка текущего индекса анимации
// =============================================================================
procedure TFWAnimate.SetIndex(Value: Integer);
begin
  if Value < FAnimFrom then
    Value := FAnimFrom
  else
    if Value > FAnimTo then
      Value := FAnimTo;
  FOwner.FCurrentImage := Value;
end;

procedure TFWAnimate.SetImages(const Value: TImageList);
begin
  if Images <> nil then
    Images.UnRegisterChanges(FOwner.FImageChangeLink);
  FOwner.FImages := Value;
  if Images <> nil then
  begin
    Images.RegisterChanges(FOwner.FImageChangeLink);
    Images.FreeNotification(FOwner);
  end
  else
  begin
    AnimFrom := -1;
    AnimTo := -1;
  end;
end;

{ TFWTrayIcon }

//
// =============================================================================
class procedure TFWTrayIcon.AddInstande;
begin
  Inc(FWTrayIconInstances);
end;

//  Закрытие главной формы
// =============================================================================
procedure TFWTrayIcon.CloseMainForm;
begin
  Shell_NotifyIcon(NIM_DELETE, @FTrayIcon);
  FCloses := True;       // Выставляем нужные флаги
  FCloseToTray := False;
  TForm(Owner).Close; // Закрываем главную форму
end;

//  Конструктор класса
// =============================================================================
constructor TFWTrayIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Разрешаем создавать только один экземпляр класса в приложении
  AddInstande;
  if InstancesCount > 1 then
    raise TFWTrayException.Create('Too many instances of TFWTrayIcon.');

  // Подписываемся на прием сообщения о пересоздании Taskbar - а
  WM_TASKBARCREATED := RegisterWindowMessage('TaskbarCreated');

  // Адрес нашей оконной процедуры будет хэндлом компонента
  {$WARNINGS OFF}
  FHandle := AllocateHWnd(WndProc);
  {$WARNINGS ON}

  if not (csDesigning in ComponentState) then
  begin
    // Заменяем главную оконную процедуру приложения своей
    if AOwner <> nil then
    begin
      FOldWndProc := GetWindowLong(TForm(AOwner).Handle, GWL_WNDPROC);
      {$WARNINGS OFF}
      FHookProc := Integer(MakeObjectInstance(HookWndProc));
      {$WARNINGS ON}
      Application.HookMainWindow(HookAppProc);
      SetWindowLong(TForm(AOwner).Handle, GWL_WNDPROC, FHookProc);
      FOwnerHandle := TForm(AOwner).Handle;
    end
    else
      FOwnerHandle := 0;
  end;

  FTrayIcon.cbSize := NOTIFYICONDATA_SIZE;
  FTrayIcon.uFlags := NIF_ICON or NIF_TIP or NIF_MESSAGE;
  FTrayIcon.Wnd := FHandle;
  FTrayIcon.uCallbackMessage := WM_ICON_MESSAGE;
  FTrayIcon.szTip[0] := #0;

  FAnimate := TFWAnimate.Create(Self);

  FIcon := TIcon.Create; // Создаем основную иконку
  FCurrentIcon := TIcon.Create; // И временную иконку

  // Инициализируем остальные значения по умолчанию
  FStartMinimized := False;
  FPopupBtn := btnRight;
  FShowHideBtn := btnLeft;
  FShowHideStyle := shDoubleClick;
  FAutoShowHide := True;
  FMinimizeToTray := False;
  FCloseToTray := False;
  FDesignPreview := False;
  FTmpStep := 1;
  FCloses := False;
  FShortCut := 0;
  FVisible := True;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;
  FFirstChange := False;
end;

//  Общая процедура для всех кнопок Left, Middle, Right - двойной клик по иконке
// =============================================================================
procedure TFWTrayIcon.DblClick(const Button: TFWShowHideBtn);
var
  I: Integer;
begin
  if (csDesigning in ComponentState) then Exit;
  // Генерация события
  DoDblClick;

  // Скрытие - показ главной формы
  if (FShowHideStyle = shDoubleClick) and
     (FShowHideBtn = Button) and
     FAutoShowHide then
     begin
       ShowHideForm;
       Exit;
     end;

  // Выполнение пункта меню по умолчанию
  if (FShowHideStyle = shDoubleClick) and
     (FShowHideBtn = Button) and
     (not FAutoShowHide) then
    if Assigned(FPopupMenu) then
    begin
      for I:= 0 to TPopUpMenu(FPopupMenu).Items.Count - 1 do
        if TPopUpMenu(FPopupMenu).Items[i].Default then
          TPopUpMenu(FPopupMenu).Items[i].Click;
    end;
end;

//  Собственно деструктор класса
// =============================================================================
destructor TFWTrayIcon.Destroy;
begin
  ReleaseInstance;
  KillTimer(FHandle, 1); // и таймер обновления иконки
  Shell_NotifyIcon(NIM_DELETE, @FTrayIcon); // Удаляем иконку
  FIcon.Free;    // Освобождаем занятые ресурсы
  FCurrentIcon.Free;
  FAnimate.Free;
  FreeAndNil(FImageChangeLink);  
  {$WARNINGS OFF}
  DeallocateHWnd(FHandle); // Освобождаем оконные процедуры
  {$WARNINGS ON}
  if FOwnerHandle <> 0 then
  begin
    Application.UnhookMainWindow(HookAppProc);
    SetWindowLong(FOwnerHandle, GWL_WNDPROC, FOldWndProc);
    {$WARNINGS OFF}
    FreeObjectInstance(Pointer(FHookProc));
    {$WARNINGS ON}
  end;
  inherited;
end;

//  Следующие 15 процедур - просто обертки для вызова событий компонента
// =============================================================================
procedure TFWTrayIcon.DoAnimate;
begin
  if Assigned(FOnAnimated) then FOnAnimated(Self);
end;

procedure TFWTrayIcon.DoBalloonHide;
begin
  if Assigned(FOnBalloonHide) then FOnBalloonHide(Self);
end;

procedure TFWTrayIcon.DoBalloonShow;
begin
  if Assigned(FOnBalloonShow) then FOnBalloonShow(Self);
end;

procedure TFWTrayIcon.DoBalloonTimeout;
begin
  if Assigned(FOnBalloonTimeout) then FOnBalloonTimeout(Self);
end;

procedure TFWTrayIcon.DoBalloonUserClick;
begin
  if Assigned(FOnBalloonUserClick) then FOnBalloonUserClick(Self);
end;

procedure TFWTrayIcon.DoClick;
begin
  if Assigned(FOnClick) then FOnClick(Self);
end;

procedure TFWTrayIcon.DoClose;
begin
  if Assigned(FOnClose) then FOnClose(Self);
end;

procedure TFWTrayIcon.DoDblClick;
begin
  if Assigned(FOnDblClick) then FOnDblClick(Self);
end;

procedure TFWTrayIcon.DoHide;
begin
  if Assigned(FOnHide) then FOnHide(Self);
end;

procedure TFWTrayIcon.DoLoaded;
begin
  if Assigned(FOnLoaded) then FOnLoaded(Self);
end;

procedure TFWTrayIcon.DoMouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if Assigned(FOnMouseDown) then FOnMouseDown(Self, Button, Shift, X, Y);
end;

procedure TFWTrayIcon.DoMouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FOnMouseMove) then FOnMouseMove(Self, Shift, X, Y);
end;

procedure TFWTrayIcon.DoMouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if Assigned(FOnMouseUp) then FOnMouseUp(Self, Button, Shift, X, Y);
end;

procedure TFWTrayIcon.DoPopup;
begin
  if Assigned(FOnPopup) then FOnPopup(Self);
end;

procedure TFWTrayIcon.DoShow;
begin
  if Assigned(FOnShow) then FOnShow(Self);
end;   

//  Показывает - крутится ли сейчас таймер анимации
// =============================================================================
function TFWTrayIcon.GetAnimate: Boolean;
begin
  Result := FAnimateHandle <> 0;
end;

//  Функция возвращает версию shell32.dll - необходимо для работы класса
// =============================================================================
class function TFWTrayIcon.GetShellVersion: Integer;
type
  TDllGetVersionProc = function (var pdvi: TDllVersionInfo): HRESULT; stdcall;
var
  DllGetVersion: TDllGetVersionProc;
  hLib: HINST;
  Version: TDllVersionInfo;
begin
  Result := 0;
  hLib := LoadLibrary('shell32.dll');
  try
    if hLib <> 0 then
    begin
      @DllGetVersion := GetProcAddress(hLib, PChar('DllGetVersion'));
      if @DllGetVersion <> nil then
      begin
        Version.cbSize := SizeOf(TDllVersionInfo);
        if Succeeded(DllGetVersion(Version)) then
          Result := Version.dwMajorVersion;
      end;
    end;
  finally
    FreeLibrary(hLib);
  end;
end;

//  Прячем главную форму
// =============================================================================
procedure TFWTrayIcon.HideMainForm;
begin
  Application.Minimize;
  HideTaskButton;
  Application.MainForm.Visible := False;   // Прячем главную форму
  DoHide;                                  // Генерируем событие
end;

//  Удаляем кнопку с TaskBar-а
// =============================================================================
procedure TFWTrayIcon.HideTaskButton;
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

//  Новая оконная процедура приложения
// =============================================================================
function TFWTrayIcon.HookAppProc(var Message: TMessage): Boolean;
begin
  Result := False;
  with Message do
    case Msg of
      WM_SIZE:  // Ловим собщение о минимизации и,
                // в зависимости от состояния флага, скрываем форму
        if FMinimizeToTray and (wParam = SIZE_MINIMIZED) then
          HideMainForm;
      WM_CLOSE: // Блокируем, если нужно сообщение о закрытии пришедшее приложению
      begin
        if FCloseToTray then
        begin
          HookAppProc := True;
          DoClose;
          HideMainForm;
          Exit;
        end;
      end;
    end;
  inherited;
end;

//  Новая оконная процедура формы
// =============================================================================
procedure TFWTrayIcon.HookWndProc(var Message: TMessage);
begin
  with Message do
  begin
    case Msg of
      WM_CLOSE: // Блокируем, если нужно сообщение о закрытии пришедшее форме
      begin
        if FCloseToTray then
        begin
          DoClose;
          HideMainForm;
          Exit;
        end;
      end;
    end;
    // Все остальные сообщения отправляем в старую оконную процедуру
    Result := CallWindowProc(Pointer(FOldWndProc), FOwnerHandle,
    	Msg, wParam, lParam);
  end;
  inherited;
end;

//  Реагируем на изменения в ImageList
// =============================================================================
procedure TFWTrayIcon.ImageListChange(Sender: TObject);
begin
  if FImages.Count = 0 then
  begin
    Animate.FAnimFrom := -1;
    Animate.FAnimTo := -1;
  end;
end;

//  Отладочная функция - возвращает количество копий класса
// =============================================================================
class function TFWTrayIcon.InstancesCount: Integer;
begin
  Result := FWTrayIconInstances;
end;

//  Функция показывает - скрыта ли форма или нет
// =============================================================================
function TFWTrayIcon.IsMainFormHiden: Boolean;
begin
  Result := not IsWindowVisible(FOwnerHandle);
end;

//  Данная процедура выполнится в RunTime и по необходимости
//  скроет наше приложение при запуске
// =============================================================================
procedure TFWTrayIcon.Loaded;
begin
  inherited Loaded;
  if (csDesigning in ComponentState) then Exit;

  DoLoaded;
  // В самом начале смотрим: если мы не поместили в св-во Icon свою иконку,
  // то основная иконка компонента будет взята из иконки приложения
  if FIcon.Handle = 0 then
    FIcon.Assign(Application.Icon);
  FCurrentIcon.Assign(FIcon);
  FTrayIcon.hIcon := FCurrentIcon.Handle;

  FIcon.OnChange := OnImageChange;

  // Прячем главную форму приложения
  if (FStartMinimized) and not (csDesigning in ComponentState) then
  begin
    Application.ShowMainForm := False;
    ShowWindow(Application.Handle, SW_HIDE);
  end;
  // Добавляем иконку в трей
  if FVisible then
    Shell_NotifyIcon(NIM_ADD, @FTrayIcon);
  UpdateTray;
end;

//  Общая процедура для всех кнопок Left, Middle, Right - кнопка нажата
// =============================================================================
procedure TFWTrayIcon.MouseDown(const State: TShiftState;
  const Button: TFWShowHideBtn; const MouseButton: TMouseButton);
var
  P: TPoint;
  Shift: TShiftState;
  I: Integer;
begin
  if (csDesigning in ComponentState) then Exit;
  
  // Определение координат
  GetCursorPos(P);
  
  // Генерация события
  Shift := GetShiftState + State;
  DoMouseDown(MouseButton, Shift, P.X, P.Y);

  // Скрытие - показ главной формы
  if (FShowHideStyle = shSingleClick) and
     (FShowHideBtn = Button) and
     FAutoShowHide then
     begin
       ShowHideForm;
       Exit;
     end;

  // Показ всплывающего меню
  if (FPopupBtn = Button) then
    if Assigned(FPopupMenu) then
    begin
      Application.ProcessMessages;
      SetForegroundWindow((Owner as TWinControl).Handle);
      TPopUpMenu(FPopupMenu).Popup(P.X, P.Y);
      DoPopup;
      Exit;
    end;

  // Выполнение пункта меню по умолчанию
  if (FShowHideStyle = shSingleClick) and
     (FShowHideBtn = Button) and
     (not FAutoShowHide) then
    if Assigned(FPopupMenu) then
    begin
      for I:= 0 to TPopUpMenu(FPopupMenu).Items.Count - 1 do
        if TPopUpMenu(FPopupMenu).Items[i].Default then
          TPopUpMenu(FPopupMenu).Items[i].Click;
    end;
end;

//  Общая процедура для всех кнопок Left, Middle, Right - кнопка отпущена
// =============================================================================
procedure TFWTrayIcon.MouseUp(const State: TShiftState;
  const MouseButton: TMouseButton);
var
  P: TPoint;
  Shift: TShiftState;
begin
  if (csDesigning in ComponentState) then Exit;
  GetCursorPos(P);
  Shift := GetShiftState + State;
  DoMouseUp(MouseButton, Shift, P.X, P.Y);
  DoClick;
end;

//  Ловим нотификации, чтобы не поймать AV :)
// =============================================================================
procedure TFWTrayIcon.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = PopupMenu then FPopupMenu := nil;
    if AComponent = Animate.Images then
    begin
      FImages := nil;
      Animate.AnimFrom := -1;
      Animate.AnimTo := -1;
    end;
  end;
end;

//  Ловим изменения иконки
// =============================================================================
procedure TFWTrayIcon.OnImageChange(Sender: TObject);
begin
  FIcon.OnChange := nil;
  if FIcon.Handle = 0 then
    FIcon.Assign(Application.Icon);
  FCurrentIcon.Assign(FIcon);
  FTrayIcon.hIcon := FCurrentIcon.Handle;
  UpdateTray;
  FIcon.OnChange := OnImageChange;
end;

//  Отладочная процедура - уменьшает счетчик копий класса
// =============================================================================
class procedure TFWTrayIcon.ReleaseInstance;
begin
  Dec(FWTrayIconInstances);
end;

//  Плокируем возможность закрытия по Alt+F4
// =============================================================================
procedure TFWTrayIcon.SetCloseToTray(const Value: Boolean);
begin
  FCloseToTray := Value;
end;

//  Даем возможность просмотреть результат работы с иконкой прямо в приложении
// =============================================================================
procedure TFWTrayIcon.SetDesignPreview(const Value: Boolean);
begin
  if Value = FDesignPreview then Exit;
  FDesignPreview := Value;
  if (csDesigning in ComponentState) then
    if Value then
    begin
      // Показываем либо иконку приложения
      if FIcon.Handle = 0 then
        FTrayIcon.hIcon := Application.Icon.Handle
      else // Либо свою иконку
        FTrayIcon.hIcon := FIcon.Handle;
      Shell_NotifyIcon(NIM_ADD, @FTrayIcon);
      // Дублируем в класс анимации
      FAnimate.SetActive(FAnimate.Active);
    end
    else
      Shell_NotifyIcon(NIM_DELETE, @FTrayIcon);
end;

//  Новый хинт для нашей иконки (не путать с BalloonHint)
// =============================================================================
procedure TFWTrayIcon.SetHint(const Value: String);
begin
  FHint := Value;
  UpdateTray;
end;

//  Присваиваем новую главную иконку...
// =============================================================================
procedure TFWTrayIcon.SetIcon(const Value: TIcon);
begin
  FIcon.Assign(Value);
  FCurrentIcon.Assign(FIcon);
  // Знаю - знаю, просто лень было код дублировать ;)
  if (csDesigning in ComponentState) then
  begin
    DesignPreview := not DesignPreview;
    DesignPreview := not DesignPreview;
  end;
end;

//  Пытаемся установить горячую клавишу для нашей иконки - аналог щелчка на иконке
// =============================================================================
procedure TFWTrayIcon.SetShortCut(const Value: TShortCut);
var
  State: TShiftState;
  Vk, Mods: Word;
begin
  FShortCut := Value;
  if (csDesigning in ComponentState) then Exit;
  if FTmpHot <> 0 then DeleteAtom(FTmpHot);
  if FShortCut = 0 then Exit;
  FTmpHot := GlobalAddAtom('Fangorn Wizards Lab Tray Icon {71E330D0-B618-4A0D-AAB3-EF853FA5FEDD}');
  if FTmpHot <> 0 then
  begin
    Mods := 0;
    ShortCutToKey(FShortCut, Vk, State);
    if (ssShift in State) then Mods:= MOD_SHIFT;
    if (ssAlt in State) then Mods:= Mods + MOD_ALT;
    if (ssCtrl in State) then Mods:= Mods + MOD_CONTROL;
    RegisterHotKey(FHandle, FTmpHot, Mods, VK);
  end;
end;

//  Показываем или убираем наш иконку из трея
// =============================================================================
procedure TFWTrayIcon.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
  if (csDesigning in ComponentState) then Exit;
  if Value then
    Shell_NotifyIcon(NIM_ADD, @FTrayIcon)
  else
    Shell_NotifyIcon(NIM_DELETE, @FTrayIcon);
end;

//  Показываем BalloonHint для нашей иконки в трее
// =============================================================================
function TFWTrayIcon.ShowBalloonHint(const Hint, Title: String;
  Style: TFWBalloonHintStyle; TimeOut: TFWBalloonTimeout): Boolean;
const
  BalloonStyle: array[TFWBalloonHintStyle] of Byte =
    (NIIF_NONE, NIIF_INFO, NIIF_WARNING, NIIF_ERROR);
var
  BalonNID: _NOTIFYICONDATAA_V2;
begin
  // Выполняем данную процедуру только если версия Shell32.dll больше четвертой
  Result := GetShellVersion >= NEED_SHELL_VER;
  if not Result then Exit;
  // Для отображения BalloonHint используем немного расширенную структуру
  ZeroMemory(@BalonNID, NOTIFYICONDATA_V2_SIZE);
  BalonNID.cbSize := NOTIFYICONDATA_V2_SIZE;
  // Копируем необходимые св-ва со старой структуры
  BalonNID.Wnd := FTrayIcon.Wnd;
  BalonNID.uID := FTrayIcon.uID;
  // Добавляем свои данные
  StrPCopy(BalonNID.szInfo, Hint);
  StrPCopy(BalonNID.szInfoTitle, Title);
  BalonNID.UNIONNAME.uTimeout := TimeOut * 1000;
  BalonNID.dwInfoFlags := BalloonStyle[Style];
  // Выставляем флаг !!!
  BalonNID.uFlags := NIF_INFO;
  // Вуаля ;)
  Shell_NotifyIcon(NIM_MODIFY, @BalonNID);
end;
 
//  Процедура прячет или показывает главную форму
//  в зависимости от флага
// =============================================================================
procedure TFWTrayIcon.ShowHideForm;
begin
  if IsWindowVisible(FOwnerHandle) then
    HideMainForm
  else
    ShowMainForm;
end;

//  Показываем главную форму
// =============================================================================
procedure TFWTrayIcon.ShowMainForm;
var
  hWnd, hCurWnd, dwThreadID, dwCurThreadID: THandle;
  OldTimeOut: DWORD;
  AResult: Boolean;
begin
  ShowTaskButton;
  Application.MainForm.Visible := True;   // Показываем главную форму

  // Ставим нашу форму впереди всех окон
  hWnd := Application.Handle;
  SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @OldTimeOut, 0);
  SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, Pointer(0), 0);
  SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  hCurWnd := GetForegroundWindow;
  AResult := False;
  while not AResult do
  begin
    dwThreadID := GetCurrentThreadId;
    dwCurThreadID := GetWindowThreadProcessId(hCurWnd);
    AttachThreadInput(dwThreadID, dwCurThreadID, True);
    AResult := SetForegroundWindow(hWnd);
    AttachThreadInput(dwThreadID, dwCurThreadID, False);
  end;
  SetWindowPos(hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, Pointer(OldTimeOut), 0); 

  // Генерируем событие
  DoShow;
end;

//  Показываем кнопку на TaskBar-е
// =============================================================================
procedure TFWTrayIcon.ShowTaskButton;
begin
  ShowWindow(Application.Handle, SW_RESTORE);
end;

//  Процедура отвечает за правильное заполнение структуры
//  для отображения иконки в трее
// =============================================================================
procedure TFWTrayIcon.UpdateTray;
begin
  if (csDesigning in ComponentState) and not DesignPreview then Exit;
  if FHint = '' then
    FTrayIcon.szTip[0] := #0
  else
  if FHint <> '' then
  begin
    Move(FHint[1], FTrayIcon.szTip[0], Length(FHint));
    FTrayIcon.szTip[Length(FHint)] := #0;
  end;
  if FVisible then
    Shell_NotifyIcon(NIM_MODIFY, @FTrayIcon);
end;

//  Оконная процедура компонента
// =============================================================================
procedure TFWTrayIcon.WndProc(var Message: TMessage);
var
  P: TPoint;
  Shift: TShiftState;
  I: Integer;
begin
  inherited;
  try
    with Message do
    begin
      case Msg of
        WM_HOTKEY: // Реагируем на горячую клавишу
        begin
          if WParam <> FTmpHot then Exit;
          if FAutoShowHide then
            ShowHideForm
          else
            if Assigned(FPopupMenu) then
            begin
              for I:= 0 to TPopUpMenu(FPopupMenu).Items.Count - 1 do
                if TPopUpMenu(FPopupMenu).Items[i].Default then
                  TPopUpMenu(FPopupMenu).Items[i].Click;
            end;
          Exit;
        end;

        // Обработка сообщений от системного таймера
        WM_TIMER:
        begin
          if not FVisible then Exit;
          case WParam of
            ANIMATE_TIMER:
            begin // Таймер на анимацию
              case FAnimate.Style of

                // Мигаем главной иконкой
                asFlash:
                begin
                  FCurrentImage := Integer(not Boolean(FCurrentImage));
                  if Boolean(FCurrentImage) then
                    FCurrentIcon.Assign(FIcon)
                  else
                  begin
                    //FCurrentIcon.ReleaseHandle;
                    FCurrentIcon.Handle := 0;
                  end;
                  FTrayIcon.hIcon := FCurrentIcon.Handle;
                  Shell_NotifyIcon(NIM_MODIFY, @FTrayIcon);
                end;

                // Показываем по очереди кадры от начала до конца
                // и возвращаемся в начало
                asLine:
                begin
                  if not Assigned(FAnimate.Images) then
                  begin
                    FAnimate.Active := False;
                    Result := DefWindowProc(FHandle, Msg, WParam, LParam);
                    Exit;
                  end;
                  Inc(FCurrentImage);
                  if (FCurrentImage > FAnimate.AnimTo)
                    or (FCurrentImage > FAnimate.Images.Count - 1) then
                    FCurrentImage := FAnimate.AnimFrom;
                  FAnimate.Images.GetIcon(FCurrentImage, FCurrentIcon);
                  FTrayIcon.hIcon := FCurrentIcon.Handle;
                  Shell_NotifyIcon(NIM_MODIFY, @FTrayIcon);
                end;

                // Показываем по очереди кадры от начала до конца
                // и затем от конца до начала, т.е. по кругу :)
                asCircle:
                begin
                  if not Assigned(FAnimate.Images) then
                  begin
                    FAnimate.Active := False;
                    Result := DefWindowProc(FHandle, Msg, WParam, LParam);
                    Exit;
                  end;
                  Inc(FCurrentImage, FTmpStep);
                  if (FCurrentImage > FAnimate.AnimTo)
                    or (FCurrentImage > FAnimate.Images.Count - 1) then
                  begin
                    Dec(FCurrentImage, 2);
                    FTmpStep:= -1;
                  end;
                  if (FCurrentImage < FAnimate.AnimFrom)
                    or (FCurrentImage < 0) then
                  begin
                    Inc(FCurrentImage, 2);
                    FTmpStep:= 1;
                  end;
                  FAnimate.Images.GetIcon(FCurrentImage, FCurrentIcon);
                  FTrayIcon.hIcon := FCurrentIcon.Handle;
                  Shell_NotifyIcon(NIM_MODIFY, @FTrayIcon);
                end;
              end;
            end;
          end;
          DoAnimate;
          Exit;
        end;

        // Обработка трея
        WM_ICON_MESSAGE:
        begin
          case LParam of

            // Кнопка нажата
            WM_LBUTTONDOWN: MouseDown([ssLeft], btnLeft, mbLeft);
            WM_MBUTTONDOWN: MouseDown([ssMiddle], btnMiddle, mbMiddle);
            WM_RBUTTONDOWN: MouseDown([ssRight], btnRight, mbRight);

            // Кнопка отпущена
            WM_LBUTTONUP: MouseUp([ssLeft], mbLeft);
            WM_MBUTTONUP: MouseUp([ssMiddle], mbMiddle);
            WM_RBUTTONUP: MouseUp([ssRight], mbRight);

            // Двойной клик
            WM_LBUTTONDBLCLK: DblClick(btnLeft);
            WM_MBUTTONDBLCLK: DblClick(btnMiddle);
            WM_RBUTTONDBLCLK: DblClick(btnRight);

            // Перемещение курсора над иконкой приложения в трее
            WM_MOUSEMOVE:
            begin
              GetCursorPos(P);
              Shift := GetShiftState;
              DoMouseMove(Shift, P.X, P.Y);
            end;
            // обработчики BalloonHint
            NIN_BALLOONSHOW:
              DoBalloonShow;
            NIN_BALLOONHIDE:
              DoBalloonHide;
            NIN_BALLOONTIMEOUT:
              DoBalloonTimeout;
            NIN_BALLOONUSERCLICK:
              DoBalloonUserClick;
          end; { case }
        end; { begin }
      else
        // TASKBAR слетел - нужно добавить иконку заново
        if Msg = WM_TASKBARCREATED then
        begin
          if (csDesigning in ComponentState) then Exit;
          UpdateTray;
          if FVisible then
            Shell_NotifyIcon(NIM_ADD, @FTrayIcon);
        end;
      end; { case }

    end; { with }
  finally
    with Message do
      Result := DefWindowProc(FHandle, Msg, WParam, LParam);
  end;
end;


end.

