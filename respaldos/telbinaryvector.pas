unit TELBinaryVector;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, TELNumeric;

// ============================================================================
//  TBinaryVector  -  Dynamic bit vector of arbitrary length
// ============================================================================

type
  TBinaryVector = class(TNumeric)
  private
    FData: array of UInt64;
    FSize: Integer;
    FLength: Integer;

    function GetBit(const AIndex: Integer): Boolean;
    procedure SetBit(const AIndex: Integer; const AValue: Boolean);
    function GetWord(const AIndex: Integer): UInt64;
    procedure SetWord(const AIndex: Integer; const AValue: UInt64);
    procedure Reallocate(const ANewSize: Integer);
  public
    constructor Create(const ASize: Integer); overload;
    constructor Create(const AValue: string); overload;
    destructor Destroy; override;

    { Bit manipulation - PUBLIC versions }
    procedure SetBitPublic(const AIndex: Integer; const AValue: Boolean);
    function  GetBitPublic(const AIndex: Integer): Boolean;

    { Logical operations }
    function BitwiseAnd(const Other: TBinaryVector): TBinaryVector;
    function BitwiseOr (const Other: TBinaryVector): TBinaryVector;
    function BitwiseXor(const Other: TBinaryVector): TBinaryVector;
    function BitwiseNot: TBinaryVector;
    function ShiftLeft (const AShift: Integer): TBinaryVector;
    function ShiftRight(const AShift: Integer): TBinaryVector;
    function RotateLeft (const AShift: Integer): TBinaryVector;
    function RotateRight(const AShift: Integer): TBinaryVector;

    { Vector operations }
    procedure SetBits(const AStart: Integer; const ACount: Integer; const AValue: UInt64);
    function  GetBits(const AStart: Integer; const ACount: Integer): UInt64;
    function HammingWeight: Integer;
    function HammingDistance(const Other: TBinaryVector): Integer;
    function Concatenate(const Other: TBinaryVector): TBinaryVector;

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

    property Bits[Index: Integer]: Boolean read GetBit write SetBit; default;
    property Size: Integer read FSize;
    property Words[Index: Integer]: UInt64 read GetWord write SetWord;
  end;


implementation


// ----------------------------------------------------------------------------
//  TBinaryVector
// ----------------------------------------------------------------------------

constructor TBinaryVector.Create(const ASize: Integer);
begin
  inherited Create;
  if ASize < 0 then
    raise ENumericError.Create('TBinaryVector.Create: size must be non-negative');
  FSize := ASize;
  FLength := (ASize + 63) div 64;
  SetLength(FData, FLength);
  if FLength > 0 then
    FillChar(FData[0], FLength * SizeOf(UInt64), 0);
end;

constructor TBinaryVector.Create(const AValue: string);
var
  I, Len: Integer;
begin
  Len := Length(AValue);
  Create(Len);
  for I := 1 to Len do
  begin
    if AValue[I] = '1' then
      SetBit(Len - I, True)
    else if AValue[I] = '0' then
      SetBit(Len - I, False)
    else
      raise ENumericError.CreateFmt(
        'TBinaryVector.Create: invalid character "%s" in binary string',
        [AValue[I]]);
  end;
end;

destructor TBinaryVector.Destroy;
begin
  SetLength(FData, 0);
  inherited Destroy;
end;

function TBinaryVector.GetBit(const AIndex: Integer): Boolean;
var
  WordIdx, BitIdx: Integer;
begin
  if (AIndex < 0) or (AIndex >= FSize) then
    raise ENumericError.CreateFmt(
      'TBinaryVector.GetBit: index %d out of range [0..%d]',
      [AIndex, FSize - 1]);
  WordIdx := AIndex div 64;
  BitIdx := AIndex mod 64;
  Result := (FData[WordIdx] and (UInt64(1) shl BitIdx)) <> 0;
end;

procedure TBinaryVector.SetBit(const AIndex: Integer; const AValue: Boolean);
var
  WordIdx, BitIdx: Integer;
begin
  if (AIndex < 0) or (AIndex >= FSize) then
    raise ENumericError.CreateFmt(
      'TBinaryVector.SetBit: index %d out of range [0..%d]',
      [AIndex, FSize - 1]);
  WordIdx := AIndex div 64;
  BitIdx := AIndex mod 64;
  if AValue then
    FData[WordIdx] := FData[WordIdx] or (UInt64(1) shl BitIdx)
  else
    FData[WordIdx] := FData[WordIdx] and not (UInt64(1) shl BitIdx);
end;

{ Public wrappers for SetBit/GetBit }
procedure TBinaryVector.SetBitPublic(const AIndex: Integer; const AValue: Boolean);
begin
  SetBit(AIndex, AValue);
end;

function TBinaryVector.GetBitPublic(const AIndex: Integer): Boolean;
begin
  Result := GetBit(AIndex);
end;

function TBinaryVector.GetWord(const AIndex: Integer): UInt64;
begin
  if (AIndex < 0) or (AIndex >= FLength) then
    raise ENumericError.CreateFmt(
      'TBinaryVector.GetWord: index %d out of range [0..%d]',
      [AIndex, FLength - 1]);
  Result := FData[AIndex];
end;

procedure TBinaryVector.SetWord(const AIndex: Integer; const AValue: UInt64);
begin
  if (AIndex < 0) or (AIndex >= FLength) then
    raise ENumericError.CreateFmt(
      'TBinaryVector.SetWord: index %d out of range [0..%d]',
      [AIndex, FLength - 1]);
  FData[AIndex] := AValue;
end;

procedure TBinaryVector.Reallocate(const ANewSize: Integer);
var
  NewLength: Integer;
begin
  if ANewSize < 0 then
    raise ENumericError.Create('TBinaryVector.Reallocate: size must be non-negative');
  NewLength := (ANewSize + 63) div 64;
  if NewLength > FLength then
    SetLength(FData, NewLength);
  FSize := ANewSize;
  FLength := NewLength;
end;

function TBinaryVector.BitwiseAnd(const Other: TBinaryVector): TBinaryVector;
var
  I, MinWords: Integer;
  Res: TBinaryVector;
begin
  if Other.FSize <> FSize then
    raise ENumericError.CreateFmt(
      'TBinaryVector.BitwiseAnd: size mismatch (%d vs %d)',
      [FSize, Other.FSize]);

  Res := TBinaryVector.Create(FSize);
  MinWords := Min(FLength, Other.FLength);
  for I := 0 to MinWords - 1 do
    Res.FData[I] := FData[I] and Other.FData[I];
  Result := Res;
end;

function TBinaryVector.BitwiseOr(const Other: TBinaryVector): TBinaryVector;
var
  I, MinWords: Integer;
  Res: TBinaryVector;
begin
  if Other.FSize <> FSize then
    raise ENumericError.CreateFmt(
      'TBinaryVector.BitwiseOr: size mismatch (%d vs %d)',
      [FSize, Other.FSize]);

  Res := TBinaryVector.Create(FSize);
  MinWords := Min(FLength, Other.FLength);
  for I := 0 to MinWords - 1 do
    Res.FData[I] := FData[I] or Other.FData[I];
  Result := Res;
end;

function TBinaryVector.BitwiseXor(const Other: TBinaryVector): TBinaryVector;
var
  I, MinWords: Integer;
  Res: TBinaryVector;
begin
  if Other.FSize <> FSize then
    raise ENumericError.CreateFmt(
      'TBinaryVector.BitwiseXor: size mismatch (%d vs %d)',
      [FSize, Other.FSize]);

  Res := TBinaryVector.Create(FSize);
  MinWords := Min(FLength, Other.FLength);
  for I := 0 to MinWords - 1 do
    Res.FData[I] := FData[I] xor Other.FData[I];
  Result := Res;
end;

function TBinaryVector.BitwiseNot: TBinaryVector;
var
  I: Integer;
  Res: TBinaryVector;
  LastMask: UInt64;
begin
  Res := TBinaryVector.Create(FSize);
  for I := 0 to FLength - 1 do
    Res.FData[I] := not FData[I];

  if FSize mod 64 <> 0 then
  begin
    LastMask := (UInt64(1) shl (FSize mod 64)) - 1;
    Res.FData[FLength - 1] := Res.FData[FLength - 1] and LastMask;
  end;
  Result := Res;
end;

function TBinaryVector.ShiftLeft(const AShift: Integer): TBinaryVector;
var
  WordShift, BitShift: Integer;
  I: Integer;
  Res: TBinaryVector;
  Carry: UInt64;
begin
  if AShift = 0 then
  begin
    Result := Clone as TBinaryVector;
    Exit;
  end;

  WordShift := AShift div 64;
  BitShift := AShift mod 64;

  if WordShift >= FSize then
  begin
    Result := TBinaryVector.Create(FSize);
    Exit;
  end;

  Res := TBinaryVector.Create(FSize);

  if BitShift = 0 then
  begin
    for I := 0 to FLength - WordShift - 1 do
      Res.FData[I + WordShift] := FData[I];
  end
  else
  begin
    Carry := 0;
    for I := 0 to FLength - WordShift - 1 do
    begin
      Res.FData[I + WordShift] := (FData[I] shl BitShift) or Carry;
      Carry := FData[I] shr (64 - BitShift);
    end;
  end;

  if FSize mod 64 <> 0 then
    Res.FData[FLength - 1] := Res.FData[FLength - 1] and
      ((UInt64(1) shl (FSize mod 64)) - 1);

  Result := Res;
end;

function TBinaryVector.ShiftRight(const AShift: Integer): TBinaryVector;
var
  WordShift, BitShift: Integer;
  I: Integer;
  Res: TBinaryVector;
  Carry: UInt64;
begin
  if AShift = 0 then
  begin
    Result := Clone as TBinaryVector;
    Exit;
  end;

  WordShift := AShift div 64;
  BitShift := AShift mod 64;

  if WordShift >= FSize then
  begin
    Result := TBinaryVector.Create(FSize);
    Exit;
  end;

  Res := TBinaryVector.Create(FSize);

  if BitShift = 0 then
  begin
    for I := 0 to FLength - WordShift - 1 do
      Res.FData[I] := FData[I + WordShift];
  end
  else
  begin
    Carry := 0;
    for I := FLength - 1 downto WordShift do
    begin
      Res.FData[I - WordShift] := (FData[I] shr BitShift) or Carry;
      Carry := FData[I] shl (64 - BitShift);
    end;
  end;

  Result := Res;
end;

function TBinaryVector.RotateLeft(const AShift: Integer): TBinaryVector;
var
  Shift: Integer;
begin
  Shift := AShift mod FSize;
  if Shift = 0 then
    Result := Clone as TBinaryVector
  else
    Result := ShiftLeft(Shift).BitwiseOr(ShiftRight(FSize - Shift)) as TBinaryVector;
end;

function TBinaryVector.RotateRight(const AShift: Integer): TBinaryVector;
var
  Shift: Integer;
begin
  Shift := AShift mod FSize;
  if Shift = 0 then
    Result := Clone as TBinaryVector
  else
    Result := ShiftRight(Shift).BitwiseOr(ShiftLeft(FSize - Shift)) as TBinaryVector;
end;

procedure TBinaryVector.SetBits(const AStart: Integer; const ACount: Integer;
  const AValue: UInt64);
var
  I: Integer;
begin
  if (AStart < 0) or (AStart + ACount > FSize) then
    raise ENumericError.Create('TBinaryVector.SetBits: range out of bounds');
  for I := 0 to ACount - 1 do
    SetBit(AStart + I, (AValue and (UInt64(1) shl I)) <> 0);
end;

function TBinaryVector.GetBits(const AStart: Integer; const ACount: Integer): UInt64;
var
  I: Integer;
begin
  if (AStart < 0) or (AStart + ACount > FSize) then
    raise ENumericError.Create('TBinaryVector.GetBits: range out of bounds');
  Result := 0;
  for I := 0 to ACount - 1 do
    if GetBit(AStart + I) then
      Result := Result or (UInt64(1) shl I);
end;

function TBinaryVector.HammingWeight: Integer;
var
  I: Integer;
  W: UInt64;
begin
  Result := 0;
  for I := 0 to FLength - 1 do
  begin
    W := FData[I];
    while W <> 0 do
    begin
      Result := Result + 1;
      W := W and (W - 1);
    end;
  end;
end;

function TBinaryVector.HammingDistance(const Other: TBinaryVector): Integer;
var
  XORed: TBinaryVector;
begin
  if Other.FSize <> FSize then
    raise ENumericError.CreateFmt(
      'TBinaryVector.HammingDistance: size mismatch (%d vs %d)',
      [FSize, Other.FSize]);
  XORed := BitwiseXor(Other);
  Result := XORed.HammingWeight;
  XORed.Free;
end;

function TBinaryVector.Concatenate(const Other: TBinaryVector): TBinaryVector;
var
  Res: TBinaryVector;
  I: Integer;
begin
  { Result = Self ‖ Other in printed order (Self left, Other right).
    Printed order is high-index to low-index, so Self must go into the
    HIGH indices and Other into the LOW indices. }
  Res := TBinaryVector.Create(FSize + Other.FSize);

  { Copy Other's bits into the low positions 0 .. Other.FSize-1 }
  for I := 0 to Other.FSize - 1 do
    Res.SetBit(I, Other.GetBit(I));

  { Copy Self's bits into the high positions Other.FSize .. }
  for I := 0 to FSize - 1 do
    Res.SetBit(Other.FSize + I, GetBit(I));

  Result := Res;
end;

function TBinaryVector.Add(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBinaryVector) then
    raise ENumericError.Create('TBinaryVector.Add: operands must be TBinaryVector');
  Result := BitwiseXor(TBinaryVector(Other));
end;

function TBinaryVector.Subtract(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBinaryVector) then
    raise ENumericError.Create('TBinaryVector.Subtract: operands must be TBinaryVector');
  Result := BitwiseAnd(TBinaryVector(Other).BitwiseNot);
end;

function TBinaryVector.Multiply(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBinaryVector) then
    raise ENumericError.Create('TBinaryVector.Multiply: operands must be TBinaryVector');
  Result := BitwiseAnd(TBinaryVector(Other));
end;

function TBinaryVector.Divide(const Other: TNumeric): TNumeric;
begin
  if not (Other is TBinaryVector) then
    raise ENumericError.Create('TBinaryVector.Divide: operands must be TBinaryVector');
  Result := BitwiseXor(TBinaryVector(Other));
end;

function TBinaryVector.Negate: TNumeric;
begin
  Result := BitwiseNot;
end;

function TBinaryVector.Clone: TNumeric;
var
  Res: TBinaryVector;
  I: Integer;
begin
  Res := TBinaryVector.Create(FSize);
  for I := 0 to FLength - 1 do
    Res.FData[I] := FData[I];
  Result := Res;
end;

function TBinaryVector.Inverse: TNumeric;
begin
  raise ENumericError.Create('TBinaryVector.Inverse: inverse not defined for binary vectors');
  Result := nil;
end;

function TBinaryVector.AsFloat: Double;
var
  Val: UInt64;
begin
  if FLength > 0 then
    Val := FData[0]
  else
    Val := 0;
  Result := Val;
end;

function TBinaryVector.ToString: string;
var
  I: Integer;
begin
  Result := '';
  for I := FSize - 1 downto 0 do
    if GetBit(I) then
      Result := Result + '1'
    else
      Result := Result + '0';
end;



end.

