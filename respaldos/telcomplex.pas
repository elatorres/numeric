unit TELComplex;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, TELNumeric, TELFloat, Math;

type
  EComplexError = class(ENumericError);

  { TComplex - complex number with real and imaginary parts.
    Real and imaginary components are accessible as TFloat values,
    so they interoperate with the rest of the TNumeric hierarchy. }
  TComplex = class(TNumeric)
  private
    FReal: Double;
    FImag: Double;

    procedure SetRealD(const AValue: Double);
    procedure SetImagD(const AValue: Double);
    function  GetRealF: TFloat;
    function  GetImagF: TFloat;
    procedure SetRealF(const AValue: TFloat);
    procedure SetImagF(const AValue: TFloat);
    function  GetModulus: TFloat;
    procedure SetModulus(const AValue: TFloat);
    function  GetAngle: TFloat;
    procedure SetAngle(const AValue: TFloat);
    function  GetIsReal: Boolean;
    function  GetIsImaginary: Boolean;
  public
    constructor Create(const AReal: Double = 0.0; const AImag: Double = 0.0); overload;
    constructor Create(const AReal: Double); overload;             // imag = 0
    constructor Create(const AReal: Int64; const AImag: Int64 = 0); overload;
    constructor Create(const AValue: TFloat); overload;            // from TFloat
    constructor Create(const AReal, AImag: TFloat); overload;      // from two TFloat
    constructor CreatePolar(const AModulus, AAngle: Double); overload;
    constructor CreatePolar(const AModulus, AAngle: TFloat); overload;

    { TNumeric interface }
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

    { Complex-specific operations (returning TComplex) }
    function Conjugate: TComplex;
    function Power(const AExponent: Double): TComplex; overload;
    function Power(const AExponent: TFloat): TComplex; overload;
    function Sqrt: TComplex;
    function Exp: TComplex;
    function Ln: TComplex;

    { Comparison helpers (return Boolean directly - no operator overloading) }
    function Equals(const Other: TComplex; const AEpsilon: Double = 1e-12): Boolean; overload;
    function Equals(const Other: TNumeric;  const AEpsilon: Double = 1e-12): Boolean; overload;
    function IsReal: Boolean;
    function IsImaginary: Boolean;
    function IsZero(const AEpsilon: Double = 1e-12): Boolean; override;

    { Accessors }
    property Real: TFloat read GetRealF write SetRealF;        // 3 + 4i -> Real = 3
    property Imag: TFloat read GetImagF write SetImagF;        // 3 + 4i -> Imag = 4
    property Modulus: TFloat read GetModulus write SetModulus; // sqrt(re² + im²)
    property Angle: TFloat read GetAngle write SetAngle;       // radians, (-pi, pi]

    { Direct Double accessors (no allocation, read-only for convenience) }
    property RealD: Double read FReal;
    property ImagD: Double read FImag;
  end;

// ============================================================================
//  Operator overloads for TComplex
// ============================================================================

operator + (A, B: TComplex): TComplex;
operator - (A, B: TComplex): TComplex;
operator * (A, B: TComplex): TComplex;
operator / (A, B: TComplex): TComplex;
operator - (A: TComplex): TComplex;

{ Mixed operations with native types }
operator + (A: TComplex; B: Double): TComplex;
operator + (A: Double; B: TComplex): TComplex;
operator + (A: TComplex; B: Integer): TComplex;
operator + (A: Integer; B: TComplex): TComplex;

operator - (A: TComplex; B: Double): TComplex;
operator - (A: Double; B: TComplex): TComplex;
operator - (A: TComplex; B: Integer): TComplex;
operator - (A: Integer; B: TComplex): TComplex;

operator * (A: TComplex; B: Double): TComplex;
operator * (A: Double; B: TComplex): TComplex;
operator * (A: TComplex; B: Integer): TComplex;
operator * (A: Integer; B: TComplex): TComplex;

operator / (A: TComplex; B: Double): TComplex;
operator / (A: Double; B: TComplex): TComplex;
operator / (A: TComplex; B: Integer): TComplex;
operator / (A: Integer; B: TComplex): TComplex;

{ Mixed operations with TFloat }
operator + (A: TComplex; B: TFloat): TComplex;
operator + (A: TFloat; B: TComplex): TComplex;
operator - (A: TComplex; B: TFloat): TComplex;
operator - (A: TFloat; B: TComplex): TComplex;
operator * (A: TComplex; B: TFloat): TComplex;
operator * (A: TFloat; B: TComplex): TComplex;
operator / (A: TComplex; B: TFloat): TComplex;
operator / (A: TFloat; B: TComplex): TComplex;

// ============================================================================
implementation
// ============================================================================

// ----------------------------------------------------------------------------
//  Constructors
// ----------------------------------------------------------------------------

constructor TComplex.Create(const AReal, AImag: Double);
begin
  inherited Create;
  FReal := AReal;
  FImag := AImag;
end;

constructor TComplex.Create(const AReal: Double);
begin
  inherited Create;
  FReal := AReal;
  FImag := 0.0;
end;

constructor TComplex.Create(const AReal, AImag: Int64);
begin
  inherited Create;
  FReal := AReal;
  FImag := AImag;
end;

constructor TComplex.Create(const AValue: TFloat);
begin
  inherited Create;
  FReal := AValue.Value;
  FImag := 0.0;
end;

constructor TComplex.Create(const AReal, AImag: TFloat);
begin
  inherited Create;
  FReal := AReal.Value;
  FImag := AImag.Value;
end;

constructor TComplex.CreatePolar(const AModulus, AAngle: Double);
begin
  inherited Create;
  FReal := AModulus * Cos(AAngle);
  FImag := AModulus * Sin(AAngle);
end;

constructor TComplex.CreatePolar(const AModulus, AAngle: TFloat);
begin
  inherited Create;
  FReal := AModulus.Value * Cos(AAngle.Value);
  FImag := AModulus.Value * Sin(AAngle.Value);
end;

// ----------------------------------------------------------------------------
//  Property accessors - Double forms
// ----------------------------------------------------------------------------

procedure TComplex.SetRealD(const AValue: Double);
begin
  FReal := AValue;
end;

procedure TComplex.SetImagD(const AValue: Double);
begin
  FImag := AValue;
end;

// ----------------------------------------------------------------------------
//  Property accessors - TFloat forms (return fresh TFloat instances)
// ----------------------------------------------------------------------------

function TComplex.GetRealF: TFloat;
begin
  Result := TFloat.Create(FReal);
end;

function TComplex.GetImagF: TFloat;
begin
  Result := TFloat.Create(FImag);
end;

procedure TComplex.SetRealF(const AValue: TFloat);
begin
  FReal := AValue.Value;
end;

procedure TComplex.SetImagF(const AValue: TFloat);
begin
  FImag := AValue.Value;
end;

function TComplex.GetModulus: TFloat;
begin
    Result := TFloat.Create( System.Sqrt(FReal * FReal + FImag * FImag));
end;

procedure TComplex.SetModulus(const AValue: TFloat);
var
  CurrentAngle: Double;
  NewModulus: Double;
begin
  NewModulus := AValue.Value;
  if NewModulus < 0 then
    raise EComplexError.Create('TComplex.SetModulus: modulus must be non-negative');
  CurrentAngle := ArcTan2(FImag, FReal);
  FReal := NewModulus * Cos(CurrentAngle);
  FImag := NewModulus * Sin(CurrentAngle);
end;

function TComplex.GetAngle: TFloat;
begin
  Result := TFloat.Create(ArcTan2(FImag, FReal));
end;

procedure TComplex.SetAngle(const AValue: TFloat);
var
  CurrentModulus: Double;
  NewAngle: Double;
begin
  NewAngle := AValue.Value;
  CurrentModulus := System.Sqrt(FReal * FReal + FImag * FImag);
  FReal := CurrentModulus * Cos(NewAngle);
  FImag := CurrentModulus * Sin(NewAngle);
end;

function TComplex.GetIsReal: Boolean;
begin
  Result := FImag = 0.0;
end;

function TComplex.GetIsImaginary: Boolean;
begin
  Result := (FReal = 0.0) and (FImag <> 0.0);
end;

// ----------------------------------------------------------------------------
//  TNumeric interface
// ----------------------------------------------------------------------------

function TComplex.Add(const Other: TNumeric): TNumeric;
var
  B: TComplex;
  OwnB: Boolean;
begin
  if Other is TComplex then
  begin
    B := TComplex(Other);
    OwnB := False;
  end
  else
  begin
    B := TComplex.Create(Other.AsFloat, 0.0);
    OwnB := True;
  end;
  try
    Result := TComplex.Create(FReal + B.FReal, FImag + B.FImag);
  finally
    if OwnB then
      B.Free;
  end;
end;

function TComplex.Subtract(const Other: TNumeric): TNumeric;
var
  B: TComplex;
  OwnB: Boolean;
begin
  if Other is TComplex then
  begin
    B := TComplex(Other);
    OwnB := False;
  end
  else
  begin
    B := TComplex.Create(Other.AsFloat, 0.0);
    OwnB := True;
  end;
  try
    Result := TComplex.Create(FReal - B.FReal, FImag - B.FImag);
  finally
    if OwnB then
      B.Free;
  end;
end;

function TComplex.Multiply(const Other: TNumeric): TNumeric;
var
  B: TComplex;
  OwnB: Boolean;
begin
  if Other is TComplex then
  begin
    B := TComplex(Other);
    OwnB := False;
  end
  else
  begin
    B := TComplex.Create(Other.AsFloat, 0.0);
    OwnB := True;
  end;
  try
    { (a + bi)(c + di) = (ac - bd) + (ad + bc)i }
    Result := TComplex.Create(
      FReal * B.FReal - FImag * B.FImag,
      FReal * B.FImag + FImag * B.FReal);
  finally
    if OwnB then
      B.Free;
  end;
end;

function TComplex.Divide(const Other: TNumeric): TNumeric;
var
  B: TComplex;
  OwnB: Boolean;
  Denom: Double;
begin
  if Other is TComplex then
  begin
    B := TComplex(Other);
    OwnB := False;
  end
  else
  begin
    B := TComplex.Create(Other.AsFloat, 0.0);
    OwnB := True;
  end;
  try
    Denom := B.FReal * B.FReal + B.FImag * B.FImag;
    if Denom = 0.0 then
      raise EComplexError.Create('TComplex.Divide: division by zero');
    { (a+bi)/(c+di) = [(ac+bd) + (bc-ad)i] / (c² + d²) }
    Result := TComplex.Create(
      (FReal * B.FReal + FImag * B.FImag) / Denom,
      (FImag * B.FReal - FReal * B.FImag) / Denom);
  finally
    if OwnB then
      B.Free;
  end;
end;

function TComplex.Negate: TNumeric;
begin
  Result := TComplex.Create(-FReal, -FImag);
end;

function TComplex.Clone: TNumeric;
begin
  Result := TComplex.Create(FReal, FImag);
end;

function TComplex.Zero: TNumeric; begin Result := TComplex.Create(0, 0); end;
function TComplex.One:  TNumeric; begin Result := TComplex.Create(1, 0); end;

function TComplex.Inverse: TNumeric;
var
  Denom: Double;
begin
  Denom := FReal * FReal + FImag * FImag;
  if Denom = 0.0 then
    raise EComplexError.Create('TComplex.Inverse: division by zero');
  Result := TComplex.Create(FReal / Denom, -FImag / Denom);
end;

function TComplex.AsFloat: Double;
begin
  if FImag <> 0.0 then
    raise EComplexError.Create(
      'TComplex.AsFloat: cannot coerce non-real complex number to Double');
  Result := FReal;
end;

function TComplex.ToString: string;
begin
  if FImag = 0.0 then
    Result := FloatToStr(FReal)
  else if FImag > 0.0 then
    Result := Format('%s + %si', [FloatToStr(FReal), FloatToStr(FImag)])
  else
    Result := Format('%s - %si', [FloatToStr(FReal), FloatToStr(-FImag)]);
end;

// ----------------------------------------------------------------------------
//  Complex-specific operations
// ----------------------------------------------------------------------------

function TComplex.Conjugate: TComplex;
begin
  Result := TComplex.Create(FReal, -FImag);
end;

function TComplex.Power(const AExponent: Double): TComplex;
var
  M, Theta: Double;
begin
  { z^n = r^n * (cos(nθ) + i·sin(nθ)) - De Moivre's formula }
  M := System.Sqrt(FReal * FReal + FImag * FImag);
  if M = 0.0 then
  begin
    if AExponent > 0 then
      Result := TComplex.Create(0.0, 0.0)
    else
      raise EComplexError.Create('TComplex.Power: 0 raised to non-positive power');
    Exit;
  end;
  Theta := ArcTan2(FImag, FReal);
  Result := TComplex.CreatePolar(
    Math.Power(M, AExponent),
    AExponent * Theta);
end;

function TComplex.Power(const AExponent: TFloat): TComplex;
begin
  Result := Power(AExponent.Value);
end;

function TComplex.Sqrt: TComplex;
begin
  Result := Power(0.5);
end;

function TComplex.Exp: TComplex;
var
  EM: Double;
begin
  { e^(a + bi) = e^a * (cos b + i·sin b) }
  EM := System.Exp(FReal);
  Result := TComplex.Create(EM * Cos(FImag), EM * Sin(FImag));
end;

function TComplex.Ln: TComplex;
var
  M: Double;
begin
  { ln(z) = ln|z| + i·arg(z) }
  M := System.Sqrt(FReal * FReal + FImag * FImag);
  if M = 0.0 then
    raise EComplexError.Create('TComplex.Ln: logarithm of zero');
  Result := TComplex.Create(System.Ln(M), ArcTan2(FImag, FReal));
end;

// ----------------------------------------------------------------------------
//  Comparison helpers
// ----------------------------------------------------------------------------

function TComplex.Equals(const Other: TComplex; const AEpsilon: Double): Boolean;
begin
  Result := (Abs(FReal - Other.FReal) <= AEpsilon) and
            (Abs(FImag - Other.FImag) <= AEpsilon);
end;

function TComplex.Equals(const Other: TNumeric; const AEpsilon: Double): Boolean;
begin
  if Other is TComplex then
    Result := Equals(TComplex(Other), AEpsilon)
  else
  begin
    { Compare against a real number }
    Result := (Abs(FReal - Other.AsFloat) <= AEpsilon) and
              (Abs(FImag) <= AEpsilon);
  end;
end;

function TComplex.IsReal: Boolean;
begin
  Result := GetIsReal;
end;

function TComplex.IsImaginary: Boolean;
begin
  Result := GetIsImaginary;
end;

function TComplex.IsZero(const AEpsilon: Double): Boolean;
begin
  Result := (Abs(FReal) <= AEpsilon) and (Abs(FImag) <= AEpsilon);
end;

// ============================================================================
//  Operator overloads
// ============================================================================

operator + (A, B: TComplex): TComplex;
begin
  Result := TComplex.Create(A.FReal + B.FReal, A.FImag + B.FImag);
end;

operator - (A, B: TComplex): TComplex;
begin
  Result := TComplex.Create(A.FReal - B.FReal, A.FImag - B.FImag);
end;

operator * (A, B: TComplex): TComplex;
begin
  Result := TComplex.Create(
    A.FReal * B.FReal - A.FImag * B.FImag,
    A.FReal * B.FImag + A.FImag * B.FReal);
end;

operator / (A, B: TComplex): TComplex;
var
  Denom: Double;
begin
  Denom := B.FReal * B.FReal + B.FImag * B.FImag;
  if Denom = 0.0 then
    raise EComplexError.Create('TComplex operator /: division by zero');
  Result := TComplex.Create(
    (A.FReal * B.FReal + A.FImag * B.FImag) / Denom,
    (A.FImag * B.FReal - A.FReal * B.FImag) / Denom);
end;

operator - (A: TComplex): TComplex;
begin
  Result := TComplex.Create(-A.FReal, -A.FImag);
end;

// --- Mixed with Double ---

operator + (A: TComplex; B: Double): TComplex;
begin
  Result := TComplex.Create(A.FReal + B, A.FImag);
end;

operator + (A: Double; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A + B.FReal, B.FImag);
end;

operator - (A: TComplex; B: Double): TComplex;
begin
  Result := TComplex.Create(A.FReal - B, A.FImag);
end;

operator - (A: Double; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A - B.FReal, -B.FImag);
end;

operator * (A: TComplex; B: Double): TComplex;
begin
  Result := TComplex.Create(A.FReal * B, A.FImag * B);
end;

operator * (A: Double; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A * B.FReal, A * B.FImag);
end;

operator / (A: TComplex; B: Double): TComplex;
begin
  if B = 0.0 then
    raise EComplexError.Create('TComplex operator /: division by zero');
  Result := TComplex.Create(A.FReal / B, A.FImag / B);
end;

operator / (A: Double; B: TComplex): TComplex;
var
  Denom: Double;
begin
  Denom := B.FReal * B.FReal + B.FImag * B.FImag;
  if Denom = 0.0 then
    raise EComplexError.Create('TComplex operator /: division by zero');
  Result := TComplex.Create(A * B.FReal / Denom, -A * B.FImag / Denom);
end;

// --- Mixed with Integer ---

operator + (A: TComplex; B: Integer): TComplex;
begin
  Result := TComplex.Create(A.FReal + B, A.FImag);
end;

operator + (A: Integer; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A + B.FReal, B.FImag);
end;

operator - (A: TComplex; B: Integer): TComplex;
begin
  Result := TComplex.Create(A.FReal - B, A.FImag);
end;

operator - (A: Integer; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A - B.FReal, -B.FImag);
end;

operator * (A: TComplex; B: Integer): TComplex;
begin
  Result := TComplex.Create(A.FReal * B, A.FImag * B);
end;

operator * (A: Integer; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A * B.FReal, A * B.FImag);
end;

operator / (A: TComplex; B: Integer): TComplex;
begin
  if B = 0 then
    raise EComplexError.Create('TComplex operator /: division by zero');
  Result := TComplex.Create(A.FReal / B, A.FImag / B);
end;

operator / (A: Integer; B: TComplex): TComplex;
var
  Denom: Double;
begin
  Denom := B.FReal * B.FReal + B.FImag * B.FImag;
  if Denom = 0.0 then
    raise EComplexError.Create('TComplex operator /: division by zero');
  Result := TComplex.Create(A * B.FReal / Denom, -A * B.FImag / Denom);
end;

// --- Mixed with TFloat ---

operator + (A: TComplex; B: TFloat): TComplex;
begin
  Result := TComplex.Create(A.FReal + B.Value, A.FImag);
end;

operator + (A: TFloat; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A.Value + B.FReal, B.FImag);
end;

operator - (A: TComplex; B: TFloat): TComplex;
begin
  Result := TComplex.Create(A.FReal - B.Value, A.FImag);
end;

operator - (A: TFloat; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A.Value - B.FReal, -B.FImag);
end;

operator * (A: TComplex; B: TFloat): TComplex;
begin
  Result := TComplex.Create(A.FReal * B.Value, A.FImag * B.Value);
end;

operator * (A: TFloat; B: TComplex): TComplex;
begin
  Result := TComplex.Create(A.Value * B.FReal, A.Value * B.FImag);
end;

operator / (A: TComplex; B: TFloat): TComplex;
begin
  if B.Value = 0.0 then
    raise EComplexError.Create('TComplex operator /: division by zero');
  Result := TComplex.Create(A.FReal / B.Value, A.FImag / B.Value);
end;

operator / (A: TFloat; B: TComplex): TComplex;
var
  Denom: Double;
begin
  Denom := B.FReal * B.FReal + B.FImag * B.FImag;
  if Denom = 0.0 then
    raise EComplexError.Create('TComplex operator /: division by zero');
  Result := TComplex.Create(A.Value * B.FReal / Denom, -A.Value * B.FImag / Denom);
end;

end.
