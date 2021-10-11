////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Project   : Fangorn Wizards Lab Exstension Library v1.35
//  * Unit Name : FWHint
//  * Purpose   : Регистрация класса для работы подсказками приложения.
//  * Author    : Александр (Rouse_) Багель
//  * Copyright : © Fangorn Wizards Lab 1998 - 2005.
//  * Version   : 1.00
//  ****************************************************************************
//

unit FWHintReg;

interface

{$I DFS.INC}

uses
  Windows, Classes, SysUtils, Controls, TypInfo, Graphics, 
  {$IFDEF VER130}
    DsgnIntf
  {$ELSE}
    DesignIntf, DesignEditors
  {$ENDIF};

type
  // Редактор для свойства About
  TFWHintAboutPropertyEditor = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

procedure Register;

implementation

uses FWHint;

procedure Register;
begin
  RegisterComponents('Fangorn Wizards Lab', [TFWHint]);
  RegisterPropertyEditor(TypeInfo(String), TFWHint, 'About', TFWHintAboutPropertyEditor);
end;

{ TAboutPropertyEditor }

procedure TFWHintAboutPropertyEditor.Edit;
begin
  inherited;
  MessageBoxEx(0,
    PAnsiChar('Fangorn Wizards Lab Exstension Library v1.35'+ #13#10 +
    '© Fangorn Wizards Lab 1998 - 2005' + #13#10 +
    'Author: Alexander (Rouse_) Bagel' + #13#10 +
    'Mailto: rouse79@yandex.ru'),
    'About...',  MB_ICONASTERISK, LANG_NEUTRAL);
end;

function TFWHintAboutPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

end.
