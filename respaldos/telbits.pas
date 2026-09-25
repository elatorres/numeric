unit TELBits;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, TELNumeric;

// ============================================================================
//  TBits  -  64-bit bit operations
// ============================================================================

type
  TBits = class(TNumeric)
  private
    FValue: UInt64;
  public
    constructor Create(const AValue: UInt64 = 0);

    { Bit manipulation }
    procedure SetBit(const ABit: Integer; const AValue: Boolean);
    function  GetBit(const ABit: Integer): Boolean;

    { Logical operations }
    function BitwiseAnd(const Other: TBits): TBits;
    function BitwiseOr (const Other: TBits): TBits;
    function BitwiseXor(const Other: TBits): TBits;
    function BitwiseNot: TBits;
    function ShiftLeft (const AShift: Integer): TBits;
    function ShiftRight(const AShift: Integer): TBits;

    { TNumeric interface }
    function Add     (const Other: TNumeric): TNumeric; override;
    function Subtract(const Other: TNumeric): TNumeric; override;
    function Multiply(const Other: TNumeric): TNumeric; override;
    function Divide  (const Other: TNumeric): TNumeric; override;
    function Negate  :                        TNumeric; override;
    function Clone   :                        TNumeric; override;
    function Inverse :                        TNumeric; override;
    function AsFloat :                        Double;   override;
    function ToString:                        string;   override;

    property Value: UInt64 read FValue write FValue;
  end;

implementation

// ----------------------------------------------------------------------------
//  TBits
// ----------------------------------------------------------------------------

constructor TBits.Create(const AValue: UInt64);
begin
  inherited Create;
  FValue := AValue;
end;

procedure TBits.SetBit(const ABit: Integer; const AValue: Boolean);
begin
  if (ABit < 0) or (ABit > 63) then
    raise ENumericError.CreateFmt('TBits.SetBit: bit index %d out of range', [ABit]);
  if AValue then
    FValue := FValue or (UInt64(1) shl ABit)
  else
    FValue := FValue and not (UInt64(1) shl ABit);
end;

function TBits.GetBit(const ABit: Integer): Boolean;
begin
  if (ABit < 0) or (ABit > 63) then
    raise ENumericError.CreateFmt('TBits.GetBit: bit index %d out of range', [ABit]);
  Result := (FValue and (UInt64(1) shl ABit)) <> 0;
end;

function TBits.BitwiseAnd(const Other: TBits): TBits;
begin
  Result := TBits.Create(FValue and Other.FValue);
end;

function TBits.BitwiseOr(const Other: TBits): TBits;
begin
  Result := TBits.Create(FValue or Other.FValue);
end;

function TBits.BitwiseXor(const Other: TBits): TBits;
begin
  Result := TBits.Create(FValue xor Other.FValue);
end;

function TBits.BitwiseNot: TBits;
begin
  Result := TBits.Create(not FValue);
end;

function TBits.ShiftLeft(const AShift: Integer): TBits;
begin
  Result := TBits.Create(FValue shl AShift);
end;

function TBits.ShiftRight(const AShift: Integer): TBits;
begin
  Result := TBits.Create(FValue shr AShift);
end;

function TBits.Add(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBits) then
    raise ENumericError.Create('TBits.Add: operands must be TBits');
  Result := BitwiseOr(TBits(Other));
end;

function TBits.Subtract(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBits) then
    raise ENumericError.Create('TBits.Subtract: operands must be TBits');
  Result := TBits.Create(FValue and not TBits(Other).FValue);
end;

function TBits.Multiply(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBits) then
    raise ENumericError.Create('TBits.Multiply: operands must be TBits');
  Result := BitwiseAnd(TBits(Other));
end;

function TBits.Divide(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBits) then
    raise ENumericError.Create('TBits.Divide: operands must be TBits');
  Result := BitwiseXor(TBits(Other));
end;

function TBits.Negate: TNumeric;
begin
  Result := BitwiseNot;
end;

function TBits.Clone: TNumeric;
begin
  Result := TBits.Create(FValue);
end;

function TBits.Inverse: TNumeric;
begin
  raise ENumericError.Create('TBits.Inverse: inverse not defined for bit values');
  Result := nil;
end;

function TBits.AsFloat: Double;
begin
  Result := FValue;
end;

function TBits.ToString: string;
var
  I: Integer;
begin
  Result := '';
  for I := 63 downto 0 do
    if (FValue and (UInt64(1) shl I)) <> 0 then
      Result := Result + '1'
    else
      Result := Result + '0';
end;


end.

