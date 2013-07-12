object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 341
  ClientWidth = 643
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 280
    Width = 643
    Height = 61
    Align = alBottom
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 8
      Width = 31
      Height = 13
      Caption = 'Label1'
    end
    object Label2: TLabel
      Left = 256
      Top = 8
      Width = 31
      Height = 13
      Caption = 'Label2'
      OnClick = Label2Click
    end
  end
  object Timer1: TTimer
    Interval = 10
    OnTimer = Timer1Timer
    Left = 32
    Top = 16
  end
end
