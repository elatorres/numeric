object Form1: TForm1
  Left = 86
  Height = 472
  Top = 85
  Width = 604
  Caption = 'Form1'
  ClientHeight = 472
  ClientWidth = 604
  LCLVersion = '8.7'
  object Bevel1: TBevel
    Left = 0
    Height = 50
    Top = 0
    Width = 604
    Align = alTop
  end
  object Memo1: TMemo
    Left = 0
    Height = 422
    Top = 50
    Width = 604
    Align = alClient
    ScrollBars = ssAutoBoth
    TabOrder = 1
  end
  object Button1: TButton
    Left = 16
    Height = 25
    Top = 8
    Width = 75
    Caption = 'Run'
    TabOrder = 0
    OnClick = Button1Click
  end
end
