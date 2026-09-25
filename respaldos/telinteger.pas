unit TELInteger;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, TELNumeric, TELFloat;

// ============================================================================
//  TInteger
// ============================================================================

type
  TInteger = class(TNumeric)
  private
    FValue: Int64;
  public
    constructor Create(const AValue: Int64 = 0);

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

    property Value: Int64 read FValue write FValue;
  end;


implementation


// ----------------------------------------------------------------------------
//  TInteger
// ----------------------------------------------------------------------------

constructor TInteger.Create(const AValue: Int64);
begin
  inherited Create;
  FValue := AValue;
end;

{}
function TInteger.Add(const Other: TNumeric): TNumeric;
begin
  // If Other is a float, result should be a float
  if Other is TFloat then
    Result := TFloat.Create(FValue + Other.AsFloat)
  else
    Result := TInteger.Create(FValue + Round(Other.AsFloat));
end;

function TInteger.Subtract(const Other: TNumeric): TNumeric;
begin
  if Other is TFloat then
    Result := TFloat.Create(FValue - Other.AsFloat)
  else
    Result := TInteger.Create(FValue - Round(Other.AsFloat));
end;

function TInteger.Multiply(const Other: TNumeric): TNumeric;
begin
  if Other is TFloat then
    Result := TFloat.Create(FValue * Other.AsFloat)
  else
    Result := TInteger.Create(FValue * Round(Other.AsFloat));
end;

function TInteger.Divide(const Other: TNumeric): TNumeric;
var
  Divisor: Double;
begin
  Divisor := Other.AsFloat;
  if Divisor = 0.0 then
    raise ENumericError.Create('TInteger.Divide: division by zero');
  if Other is TFloat then
    Result := TFloat.Create(FValue / Divisor)
  else
    Result := TInteger.Create(FValue div Round(Divisor));
end;
{}

function TInteger.Negate: TNumeric;
begin
  Result := TInteger.Create(-FValue);
end;

function TInteger.Clone: TNumeric;
begin
  Result := TInteger.Create(FValue);
end;

function TInteger.Zero: TNumeric; begin Result := TInteger.Create(0); end;
function TInteger.One:  TNumeric; begin Result := TInteger.Create(1); end;

function TInteger.Inverse: TNumeric;
begin
  if FValue = 0 then
    raise ENumericError.Create('TInteger.Inverse: division by zero');
  Result := TFloat.Create(1.0 / FValue);
end;

function TInteger.AsFloat: Double;
begin
  Result := FValue;
end;

function TInteger.ToString: string;
begin
  Result := IntToStr(FValue);
end;


end.

