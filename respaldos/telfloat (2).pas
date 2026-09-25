unit TELFloat;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, TELNumeric;



// ============================================================================
//  TELFloat
// ============================================================================

type
  TFloat = class(TNumeric)
  private
    FValue: Double;
  public
    constructor Create(const AValue: Double = 0.0);

    function Add     (const Other: TNumeric): TNumeric; override;
    function Subtract(const Other: TNumeric): TNumeric; override;
    function Multiply(const Other: TNumeric): TNumeric; override;
    function Divide  (const Other: TNumeric): TNumeric; override;
    function Negate  :                        TNumeric; override;
    function Clone   :                        TNumeric; override;
    function Zero    :                        TNumeric; override;
    function One     :                        TNumeric; override;

    function Inverse :                        TNumeric; override;
    function AsFloat :                        Double;   override;
    function ToString:                        string;   override;

    property Value: Double read FValue write FValue;

    class function CreateFromString(const S: string): TFloat; static;
  end;


implementation


// ----------------------------------------------------------------------------
//  TFloat
// ----------------------------------------------------------------------------

constructor TFloat.Create(const AValue: Double);
begin
  inherited Create;
  FValue := AValue;
end;

function TFloat.Add(const Other: TNumeric): TNumeric;
begin
  Result := TFloat.Create(FValue + Other.AsFloat);
end;

function TFloat.Subtract(const Other: TNumeric): TNumeric;
begin
  Result := TFloat.Create(FValue - Other.AsFloat);
end;

function TFloat.Multiply(const Other: TNumeric): TNumeric;
begin
  Result := TFloat.Create(FValue * Other.AsFloat);
end;

function TFloat.Divide(const Other: TNumeric): TNumeric;
var
  Divisor: Double;
begin
  Divisor := Other.AsFloat;
  if Divisor = 0.0 then
    raise ENumericError.Create('TFloat.Divide: division by zero');
  Result := TFloat.Create(FValue / Divisor);
end;

function TFloat.Negate: TNumeric;
begin
  Result := TFloat.Create(-FValue);
end;

function TFloat.Clone: TNumeric;
begin
  Result := TFloat.Create(FValue);
end;

function TFloat.Zero: TNumeric; begin Result := TFloat.Create(0.0); end;
function TFloat.One:  TNumeric; begin Result := TFloat.Create(1.0); end;

function TFloat.Inverse: TNumeric;
begin
  if FValue = 0.0 then
    raise ENumericError.Create('TFloat.Inverse: division by zero');
  Result := TFloat.Create(1.0 / FValue);
end;

function TFloat.AsFloat: Double;
begin
  Result := FValue;
end;

function TFloat.ToString: string;
begin
  Result := FloatToStr(FValue);
end;

class function TFloat.CreateFromString(const S: string): TFloat;
var
  Trimmed: string;
  V: Double;
begin
  Trimmed := Trim(S);
  if Trimmed = '' then
    raise ENumericError.Create('TFloat.CreateFromString: empty string');
  try
    V := StrToFloat(Trimmed);
  except
    on E: EConvertError do
      raise ENumericError.CreateFmt(
        'TFloat.CreateFromString: cannot parse "%s" as a float', [S]);
  end;
  Result := TFloat.Create(V);
end;

end.

