unit TELBoolean;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, TELNumeric;

type
  EBooleanError = class(ENumericError);

  { TBoolean - a numeric-wrapper boolean value.
    It is a TNumeric so it can be stored inside matrices, passed to
    operator overloads, and returned from comparison-like operations. }
  TBoolean = class(TNumeric)
  private
    FValue: Boolean;
  public
    constructor Create(const AValue: Boolean); overload;
    constructor Create(const AValue: Integer); overload;   // 0 = False, else True
    constructor Create(const AValue: Double); overload;    // 0.0 = False, else True

    { TNumeric interface }
    function Add     (const Other: TNumeric): TNumeric; override;  // logical OR
    function Subtract(const Other: TNumeric): TNumeric; override;  // logical AND with NOT
    function Multiply(const Other: TNumeric): TNumeric; override;  // logical AND
    function Divide  (const Other: TNumeric): TNumeric; override;  // logical XOR
    function Negate  :                        TNumeric; override;  // logical NOT
    function Clone   :                        TNumeric; override;
    function Inverse :                        TNumeric; override;  // NOT
    function AsFloat :                        Double;   override;  // True -> 1.0
    function ToString:                        string;   override;

    function ToInt: Integer;
    function ToBool: Boolean;

    property Value: Boolean read FValue write FValue;
  end;

implementation

constructor TBoolean.Create(const AValue: Boolean);
begin
  inherited Create;
  FValue := AValue;
end;

constructor TBoolean.Create(const AValue: Integer);
begin
  inherited Create;
  FValue := AValue <> 0;
end;

constructor TBoolean.Create(const AValue: Double);
begin
  inherited Create;
  FValue := AValue <> 0.0;
end;

function TBoolean.Add(const Other: TNumeric): TNumeric;
begin
  { OR }
  Result := TBoolean.Create(FValue or (Other.AsFloat <> 0.0));
end;

function TBoolean.Subtract(const Other: TNumeric): TNumeric;
begin
  { A AND NOT B }
  Result := TBoolean.Create(FValue and (Other.AsFloat = 0.0));
end;

function TBoolean.Multiply(const Other: TNumeric): TNumeric;
begin
  { AND }
  Result := TBoolean.Create(FValue and (Other.AsFloat <> 0.0));
end;

function TBoolean.Divide(const Other: TNumeric): TNumeric;
begin
  { XOR }
  Result := TBoolean.Create(FValue xor (Other.AsFloat <> 0.0));
end;

function TBoolean.Negate: TNumeric;
begin
  Result := TBoolean.Create(not FValue);
end;

function TBoolean.Clone: TNumeric;
begin
  Result := TBoolean.Create(FValue);
end;

function TBoolean.Inverse: TNumeric;
begin
  Result := TBoolean.Create(not FValue);
end;

function TBoolean.AsFloat: Double;
begin
  if FValue then
    Result := 1.0
  else
    Result := 0.0;
end;

function TBoolean.ToString: string;
begin
  if FValue then
    Result := 'True'
  else
    Result := 'False';
end;

function TBoolean.ToInt: Integer;
begin
  if FValue then
    Result := 1
  else
    Result := 0;
end;

function TBoolean.ToBool: Boolean;
begin
  Result := FValue;
end;

end.
