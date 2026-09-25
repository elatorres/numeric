unit TELRational;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math, TELNumeric, TELInteger, TELFloat;

type
  ERationalError = class(ENumericError);

  { TRational - rational number num/den with automatic normalization.

    Invariant: den > 0 and gcd(|num|, den) = 1 (canonical form).
    Zero is represented as 0/1. }

  TRational = class(TInteger)
  private
    FNumerator: Int64;
    FDenominator: Int64;

    procedure SetNumerator(const AValue: Int64);
    procedure SetDenominator(const AValue: Int64);
    procedure Normalize;

    function  GetNumeratorF: TInteger;
    function  GetDenominatorF: TInteger;
    procedure SetNumeratorF(const AValue: TInteger);
    procedure SetDenominatorF(const AValue: TInteger);

    function  GetAsFloat: TFloat;
    function  GetAsInteger: TInteger;
  public
    constructor Create(const ANumerator: Int64 = 0; const ADenominator: Int64 = 1); overload;
    constructor Create(const ANumerator: TInteger; const ADenominator: TInteger = nil); overload;
    constructor Create(const AValue: TFloat); overload;   // from decimal (fractional part preserved)

    { TNumeric / TInteger interface }
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

    { Rational-specific helpers }
    function IsInteger: Boolean;                       // den divides num evenly
    function ToInteger: TInteger;                      // raises if not exact
    function FloatValue: TFloat;                       // allocated TFloat
    function Abs_: TRational;
    function Reciprocal: TRational;                    // 1 / self
    function Floor: TInteger;
    function Ceil: TInteger;
    function Round_: TInteger;

    property Numerator: Int64 read FNumerator write SetNumerator;
    property Denominator: Int64 read FDenominator write SetDenominator;

    { TInteger-typed accessors - caller owns the returned object }
    property NumeratorI: TInteger read GetNumeratorF write SetNumeratorF;
    property DenominatorI: TInteger read GetDenominatorF write SetDenominatorF;

    { Convenience read-only TFloat view - caller owns }
    property AsFloatValue: TFloat read GetAsFloat;
    property AsIntegerValue: TInteger read GetAsInteger;

    class function CreateFromString(const S: string): TRational; static;
  end;

// ============================================================================
//  Operator overloads
// ============================================================================

operator + (A, B: TRational): TRational;
operator - (A, B: TRational): TRational;
operator * (A, B: TRational): TRational;
operator / (A, B: TRational): TRational;
operator - (A: TRational): TRational;

{ Mixed with TInteger -> TRational }
operator + (A: TRational; B: TInteger): TRational;
operator + (A: TInteger; B: TRational): TRational;
operator - (A: TRational; B: TInteger): TRational;
operator - (A: TInteger; B: TRational): TRational;
operator * (A: TRational; B: TInteger): TRational;
operator * (A: TInteger; B: TRational): TRational;
operator / (A: TRational; B: TInteger): TRational;
operator / (A: TInteger; B: TRational): TRational;

{ Mixed with Integer (native) -> TRational }
operator + (A: TRational; B: Integer): TRational;
operator + (A: Integer; B: TRational): TRational;
operator - (A: TRational; B: Integer): TRational;
operator - (A: Integer; B: TRational): TRational;
operator * (A: TRational; B: Integer): TRational;
operator * (A: Integer; B: TRational): TRational;
operator / (A: TRational; B: Integer): TRational;
operator / (A: Integer; B: TRational): TRational;

{ Mixed with TFloat -> TFloat }
operator + (A: TRational; B: TFloat): TFloat;
operator + (A: TFloat; B: TRational): TFloat;
operator - (A: TRational; B: TFloat): TFloat;
operator - (A: TFloat; B: TRational): TFloat;
operator * (A: TRational; B: TFloat): TFloat;
operator * (A: TFloat; B: TRational): TFloat;
operator / (A: TRational; B: TFloat): TFloat;
operator / (A: TFloat; B: TRational): TFloat;

{ Mixed with Double -> TFloat }
operator + (A: TRational; B: Double): TFloat;
operator + (A: Double; B: TRational): TFloat;
operator - (A: TRational; B: Double): TFloat;
operator - (A: Double; B: TRational): TFloat;
operator * (A: TRational; B: Double): TFloat;
operator * (A: Double; B: TRational): TFloat;
operator / (A: TRational; B: Double): TFloat;
operator / (A: Double; B: TRational): TFloat;

// ============================================================================
implementation
// ============================================================================

// ----------------------------------------------------------------------------
//  Internal helpers
// ----------------------------------------------------------------------------

function GCD64(A, B: Int64): Int64;
begin
  A := Abs(A);
  B := Abs(B);
  while B <> 0 do
  begin
    Result := A mod B;
    A := B;
    B := Result;
  end;
  Result := A;
end;

// ----------------------------------------------------------------------------
//  Constructors
// ----------------------------------------------------------------------------

constructor TRational.Create(const ANumerator, ADenominator: Int64);
begin
  { Do NOT call TInteger.Create with a value; we manage the base's FValue
    as a mirrored view of the numerator so TInteger's virtual methods still
    make sense if someone treats us as a TInteger. }
  inherited Create(ANumerator);
  if ADenominator = 0 then
    raise ERationalError.Create('TRational.Create: denominator cannot be zero');
  FNumerator   := ANumerator;
  FDenominator := ADenominator;
  Normalize;
  { Mirror numerator into the TInteger base so AsFloat/ToString from the base
    would still be coherent if called via a TInteger reference. }
  Self.Value := FNumerator;
end;

constructor TRational.Create(const ANumerator: TInteger; const ADenominator: TInteger);
var
  D: Int64;
begin
  if ADenominator = nil then
    D := 1
  else
    D := ADenominator.Value;

  if ANumerator = nil then
    inherited Create(0)
  else
    inherited Create(ANumerator.Value);

  if D = 0 then
    raise ERationalError.Create('TRational.Create: denominator cannot be zero');

  if ANumerator = nil then
    FNumerator := 0
  else
    FNumerator := ANumerator.Value;
  FDenominator := D;
  Normalize;
  Self.Value := FNumerator;
end;

constructor TRational.Create(const AValue: TFloat);
var
  Num, Den: Int64;
  Scale: Int64;
  Frac: Double;
begin
  { Convert a decimal to a rational using continued-fraction-like scaling.
    We look for the smallest power of 10 that makes the fractional part
    integral within a tight tolerance. }
  Num := Trunc(AValue.Value);
  Frac := AValue.Value - Num;
  if Frac = 0.0 then
  begin
    inherited Create(Num);
    FNumerator := Num;
    FDenominator := 1;
    Exit;
  end;

  Scale := 1;
  while (Abs(Frac * Scale - Round(Frac * Scale)) > 1e-10) and (Scale < 1000000000) do
    Scale := Scale * 10;

  Num := Round(AValue.Value * Scale);
  Den := Scale;
  inherited Create(Num);
  FNumerator := Num;
  FDenominator := Den;
  Normalize;
  Self.Value := FNumerator;
end;

// ----------------------------------------------------------------------------
//  Normalization
// ----------------------------------------------------------------------------

procedure TRational.Normalize;
var
  G: Int64;
begin
  if FDenominator = 0 then
    raise ERationalError.Create('TRational: denominator became zero');

  { Force denominator positive }
  if FDenominator < 0 then
  begin
    FNumerator   := -FNumerator;
    FDenominator := -FDenominator;
  end;

  { Zero is always 0/1 }
  if FNumerator = 0 then
  begin
    FDenominator := 1;
    Exit;
  end;

  G := GCD64(FNumerator, FDenominator);
  if G > 1 then
  begin
    FNumerator   := FNumerator   div G;
    FDenominator := FDenominator div G;
  end;
end;

// ----------------------------------------------------------------------------
//  Property accessors
// ----------------------------------------------------------------------------

procedure TRational.SetNumerator(const AValue: Int64);
begin
  FNumerator := AValue;
  Normalize;
  Self.Value := FNumerator;
end;

procedure TRational.SetDenominator(const AValue: Int64);
begin
  if AValue = 0 then
    raise ERationalError.Create('TRational.SetDenominator: denominator cannot be zero');
  FDenominator := AValue;
  Normalize;
  Self.Value := FNumerator;
end;

function TRational.GetNumeratorF: TInteger;
begin
  Result := TInteger.Create(FNumerator);
end;

function TRational.GetDenominatorF: TInteger;
begin
  Result := TInteger.Create(FDenominator);
end;

procedure TRational.SetNumeratorF(const AValue: TInteger);
begin
  SetNumerator(AValue.Value);
end;

procedure TRational.SetDenominatorF(const AValue: TInteger);
begin
  SetDenominator(AValue.Value);
end;

function TRational.GetAsFloat: TFloat;
begin
  Result := TFloat.Create(AsFloat);
end;

function TRational.GetAsInteger: TInteger;
begin
  Result := ToInteger;
end;

// ----------------------------------------------------------------------------
//  TNumeric interface
// ----------------------------------------------------------------------------

function TRational.Add(const Other: TNumeric): TNumeric;
var
  R: TRational;
begin
  { If the other side is a TFloat (or plain real), return TFloat. }
  if Other is TFloat then
  begin
    Result := TFloat.Create(AsFloat + Other.AsFloat);
    Exit;
  end;

  if Other is TRational then
    R := TRational(Other)
  else if Other is TInteger then
    R := TRational.Create(TInteger(Other).Value, 1)
  else
  begin
    { Anything else - fall back to TFloat }
    Result := TFloat.Create(AsFloat + Other.AsFloat);
    Exit;
  end;

  try
    { a/b + c/d = (ad + cb) / bd }
    Result := TRational.Create(
      FNumerator * R.FDenominator + R.FNumerator * FDenominator,
      FDenominator * R.FDenominator);
  finally
    if not (Other is TRational) and not (Other is TInteger) then
      R.Free;
  end;
end;

function TRational.Subtract(const Other: TNumeric): TNumeric;
var
  R: TRational;
begin
  if Other is TFloat then
  begin
    Result := TFloat.Create(AsFloat - Other.AsFloat);
    Exit;
  end;

  if Other is TRational then
    R := TRational(Other)
  else if Other is TInteger then
    R := TRational.Create(TInteger(Other).Value, 1)
  else
  begin
    Result := TFloat.Create(AsFloat - Other.AsFloat);
    Exit;
  end;

  try
    { a/b - c/d = (ad - cb) / bd }
    Result := TRational.Create(
      FNumerator * R.FDenominator - R.FNumerator * FDenominator,
      FDenominator * R.FDenominator);
  finally
    if not (Other is TRational) and not (Other is TInteger) then
      R.Free;
  end;
end;

function TRational.Multiply(const Other: TNumeric): TNumeric;
var
  R: TRational;
begin
  if Other is TFloat then
  begin
    Result := TFloat.Create(AsFloat * Other.AsFloat);
    Exit;
  end;

  if Other is TRational then
    R := TRational(Other)
  else if Other is TInteger then
    R := TRational.Create(TInteger(Other).Value, 1)
  else
  begin
    Result := TFloat.Create(AsFloat * Other.AsFloat);
    Exit;
  end;

  try
    { a/b * c/d = ac / bd }
    Result := TRational.Create(
      FNumerator * R.FNumerator,
      FDenominator * R.FDenominator);
  finally
    if not (Other is TRational) and not (Other is TInteger) then
      R.Free;
  end;
end;

function TRational.Divide(const Other: TNumeric): TNumeric;
var
  R: TRational;
begin
  if Other is TFloat then
  begin
    if Other.AsFloat = 0.0 then
      raise ERationalError.Create('TRational.Divide: division by zero');
    Result := TFloat.Create(AsFloat / Other.AsFloat);
    Exit;
  end;

  if Other is TRational then
    R := TRational(Other)
  else if Other is TInteger then
    R := TRational.Create(TInteger(Other).Value, 1)
  else
  begin
    if Other.AsFloat = 0.0 then
      raise ERationalError.Create('TRational.Divide: division by zero');
    Result := TFloat.Create(AsFloat / Other.AsFloat);
    Exit;
  end;

  try
    if R.FNumerator = 0 then
      raise ERationalError.Create('TRational.Divide: division by zero');
    { a/b / c/d = ad / bc }
    Result := TRational.Create(
      FNumerator * R.FDenominator,
      FDenominator * R.FNumerator);
  finally
    if not (Other is TRational) and not (Other is TInteger) then
      R.Free;
  end;
end;

function TRational.Negate: TNumeric;
begin
  Result := TRational.Create(-FNumerator, FDenominator);
end;

function TRational.Clone: TNumeric;
begin
  Result := TRational.Create(FNumerator, FDenominator);
end;

function TRational.Zero: TNumeric; begin Result := TRational.Create(0, 1); end;
function TRational.One:  TNumeric; begin Result := TRational.Create(1, 1); end;

function TRational.Inverse: TNumeric;
begin
  if FNumerator = 0 then
    raise ERationalError.Create('TRational.Inverse: division by zero');
  Result := TRational.Create(FDenominator, FNumerator);
end;

function TRational.AsFloat: Double;
begin
  Result := FNumerator / FDenominator;
end;

function TRational.ToString: string;
begin
  if FDenominator = 1 then
    Result := IntToStr(FNumerator)
  else
    Result := IntToStr(FNumerator) + '/' + IntToStr(FDenominator);
end;

// ----------------------------------------------------------------------------
//  Rational-specific helpers
// ----------------------------------------------------------------------------

function TRational.IsInteger: Boolean;
begin
  Result := (FDenominator = 1) or (FNumerator mod FDenominator = 0);
end;

function TRational.ToInteger: TInteger;
begin
  if not IsInteger then
    raise ERationalError.CreateFmt(
      'TRational.ToInteger: %s is not an integer', [ToString]);
  Result := TInteger.Create(FNumerator div FDenominator);
end;

function TRational.FloatValue: TFloat;
begin
  Result := TFloat.Create(AsFloat);
end;

function TRational.Abs_: TRational;
begin
  Result := TRational.Create(Abs(FNumerator), FDenominator);
end;

function TRational.Reciprocal: TRational;
begin
  if FNumerator = 0 then
    raise ERationalError.Create('TRational.Reciprocal: division by zero');
  Result := TRational.Create(FDenominator, FNumerator);
end;

function TRational.Floor: TInteger;
var
  Q: Int64;
begin
  Q := FNumerator div FDenominator;
  { In Pascal, div truncates toward zero; adjust for negatives }
  if (FNumerator < 0) and (FNumerator mod FDenominator <> 0) then
    Dec(Q);
  Result := TInteger.Create(Q);
end;

function TRational.Ceil: TInteger;
var
  Q: Int64;
begin
  Q := FNumerator div FDenominator;
  if (FNumerator > 0) and (FNumerator mod FDenominator <> 0) then
    Inc(Q);
  Result := TInteger.Create(Q);
end;

function TRational.Round_: TInteger;
var
  Q, R: Int64;
begin
  Q := FNumerator div FDenominator;
  R := Abs(FNumerator mod FDenominator);
  { Round half away from zero }
  if 2 * R >= FDenominator then
  begin
    if FNumerator > 0 then Inc(Q)
    else if FNumerator < 0 then Dec(Q);
  end;
  Result := TInteger.Create(Q);
end;

class function TRational.CreateFromString(const S: string): TRational;
var
  Trimmed: string;
  SlashPos: Integer;
  NumStr, DenStr: string;
  Num, Den: Int64;
begin
  Trimmed := Trim(S);
  if Trimmed = '' then
    raise ERationalError.Create('TRational.CreateFromString: empty string');

  SlashPos := Pos('/', Trimmed);
  if SlashPos = 0 then
  begin
    { Plain integer }
    try
      Num := StrToInt64(Trimmed);
    except
      on E: EConvertError do
        raise ERationalError.CreateFmt(
          'TRational.CreateFromString: cannot parse "%s" as an integer', [S]);
    end;
    Result := TRational.Create(Num, 1);
    Exit;
  end;

  NumStr := Trim(Copy(Trimmed, 1, SlashPos - 1));
  DenStr := Trim(Copy(Trimmed, SlashPos + 1, MaxInt));

  if (NumStr = '') or (DenStr = '') then
    raise ERationalError.CreateFmt(
      'TRational.CreateFromString: malformed fraction "%s"', [S]);

  try
    Num := StrToInt64(NumStr);
    Den := StrToInt64(DenStr);
  except
    on E: EConvertError do
      raise ERationalError.CreateFmt(
        'TRational.CreateFromString: cannot parse "%s" as a fraction', [S]);
  end;

  if Den = 0 then
    raise ERationalError.CreateFmt(
      'TRational.CreateFromString: zero denominator in "%s"', [S]);

  Result := TRational.Create(Num, Den);
end;

// ============================================================================
//  Operator overloads
// ============================================================================

operator + (A, B: TRational): TRational;
begin
  Result := TRational(A.Add(B));
end;

operator - (A, B: TRational): TRational;
begin
  Result := TRational(A.Subtract(B));
end;

operator * (A, B: TRational): TRational;
begin
  Result := TRational(A.Multiply(B));
end;

operator / (A, B: TRational): TRational;
begin
  Result := TRational(A.Divide(B));
end;

operator - (A: TRational): TRational;
begin
  Result := TRational(A.Negate);
end;

// --- Mixed with TInteger -> TRational ---

operator + (A: TRational; B: TInteger): TRational;
begin
  Result := TRational(A.Add(B));
end;

operator + (A: TInteger; B: TRational): TRational;
begin
  Result := TRational(B.Add(A));  // commutative
end;

operator - (A: TRational; B: TInteger): TRational;
begin
  Result := TRational(A.Subtract(B));
end;

operator - (A: TInteger; B: TRational): TRational;
begin
  { A - B = A + (-B) }
  Result := TRational(TRational.Create(A.Value, 1).Subtract(B));
end;

operator * (A: TRational; B: TInteger): TRational;
begin
  Result := TRational(A.Multiply(B));
end;

operator * (A: TInteger; B: TRational): TRational;
begin
  Result := TRational(B.Multiply(A));
end;

operator / (A: TRational; B: TInteger): TRational;
begin
  Result := TRational(A.Divide(B));
end;

operator / (A: TInteger; B: TRational): TRational;
begin
  Result := TRational(TRational.Create(A.Value, 1).Divide(B));
end;

// --- Mixed with Integer (native) -> TRational ---

operator + (A: TRational; B: Integer): TRational;
begin
  Result := TRational(A.Add(TInteger.Create(B)));
end;

operator + (A: Integer; B: TRational): TRational;
begin
  Result := TRational(B.Add(TInteger.Create(A)));
end;

operator - (A: TRational; B: Integer): TRational;
begin
  Result := TRational(A.Subtract(TInteger.Create(B)));
end;

operator - (A: Integer; B: TRational): TRational;
begin
  Result := TRational(TRational.Create(A, 1).Subtract(B));
end;

operator * (A: TRational; B: Integer): TRational;
begin
  Result := TRational(A.Multiply(TInteger.Create(B)));
end;

operator * (A: Integer; B: TRational): TRational;
begin
  Result := TRational(B.Multiply(TInteger.Create(A)));
end;

operator / (A: TRational; B: Integer): TRational;
begin
  Result := TRational(A.Divide(TInteger.Create(B)));
end;

operator / (A: Integer; B: TRational): TRational;
begin
  Result := TRational(TRational.Create(A, 1).Divide(B));
end;

// --- Mixed with TFloat -> TFloat ---

operator + (A: TRational; B: TFloat): TFloat;
begin
  Result := TFloat.Create(A.AsFloat + B.Value);
end;

operator + (A: TFloat; B: TRational): TFloat;
begin
  Result := TFloat.Create(A.Value + B.AsFloat);
end;

operator - (A: TRational; B: TFloat): TFloat;
begin
  Result := TFloat.Create(A.AsFloat - B.Value);
end;

operator - (A: TFloat; B: TRational): TFloat;
begin
  Result := TFloat.Create(A.Value - B.AsFloat);
end;

operator * (A: TRational; B: TFloat): TFloat;
begin
  Result := TFloat.Create(A.AsFloat * B.Value);
end;

operator * (A: TFloat; B: TRational): TFloat;
begin
  Result := TFloat.Create(A.Value * B.AsFloat);
end;

operator / (A: TRational; B: TFloat): TFloat;
begin
  if B.Value = 0.0 then
    raise ERationalError.Create('TRational operator /: division by zero');
  Result := TFloat.Create(A.AsFloat / B.Value);
end;

operator / (A: TFloat; B: TRational): TFloat;
begin
  if B.AsFloat = 0.0 then
    raise ERationalError.Create('TRational operator /: division by zero');
  Result := TFloat.Create(A.Value / B.AsFloat);
end;

// --- Mixed with Double -> TFloat ---

operator + (A: TRational; B: Double): TFloat;
begin
  Result := TFloat.Create(A.AsFloat + B);
end;

operator + (A: Double; B: TRational): TFloat;
begin
  Result := TFloat.Create(A + B.AsFloat);
end;

operator - (A: TRational; B: Double): TFloat;
begin
  Result := TFloat.Create(A.AsFloat - B);
end;

operator - (A: Double; B: TRational): TFloat;
begin
  Result := TFloat.Create(A - B.AsFloat);
end;

operator * (A: TRational; B: Double): TFloat;
begin
  Result := TFloat.Create(A.AsFloat * B);
end;

operator * (A: Double; B: TRational): TFloat;
begin
  Result := TFloat.Create(A * B.AsFloat);
end;

operator / (A: TRational; B: Double): TFloat;
begin
  if B = 0.0 then
    raise ERationalError.Create('TRational operator /: division by zero');
  Result := TFloat.Create(A.AsFloat / B);
end;

operator / (A: Double; B: TRational): TFloat;
begin
  if B.AsFloat = 0.0 then
    raise ERationalError.Create('TRational operator /: division by zero');
  Result := TFloat.Create(A / B.AsFloat);
end;

end.
