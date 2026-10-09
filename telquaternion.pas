unit TELQuaternion;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math,
  TELNumeric, TELFloat, TELInteger, TELComplex, TELRational;

type
  EQuaternionError = class(ENumericError);

  { TQuaternion - a quaternion q = w + xi + yj + zk.

    Storage: four Double components (Fw, Fx, Fy, Fz).
    Public access is via TFloat-typed properties for interoperability
    with the numeric hierarchy, plus direct Double accessors (W, X, Y, Z)
    for speed. }
  TQuaternion = class(TNumeric)
  private
    Fw, Fx, Fy, Fz: Double;

    function  GetW: TFloat;
    function  GetX: TFloat;
    function  GetY: TFloat;
    function  GetZ: TFloat;
    procedure SetW(const V: TFloat);
    procedure SetX(const V: TFloat);
    procedure SetY(const V: TFloat);
    procedure SetZ(const V: TFloat);
    function  GetConjugate: TQuaternion;
    function  GetNormF: TFloat;
    function  GetUnit: TQuaternion;
    function  GetVectorPart: TQuaternion;
    function  GetScalarPart: TFloat;
  public
    constructor Create(const AW, AX, AY, AZ: Double); overload;
    constructor Create(const AValue: Double); overload;              { w only }
    constructor Create(const ARealPart: TFloat); overload;           { w only }
    constructor Create(const ARealPart: TComplex); overload;         { w + x i, imag → i }
    constructor Create(const AW: TFloat; const AX, AY, AZ: TFloat); overload;

    { TNumeric interface }
    function Add     (const Other: TNumeric): TNumeric; override;
    function Subtract(const Other: TNumeric): TNumeric; override;
    function Multiply(const Other: TNumeric): TNumeric; override;
    function Divide  (const Other: TNumeric): TNumeric; override;
    function Negate  :                        TNumeric; override;
    function Clone   :                        TNumeric; override;
    function Inverse :                        TNumeric; override;
    function AsFloat :                        Double;   override;   { raises if not real }
    function ToString:                        string;   override;

    { Additional numeric-hierarchy methods }
    function Zero: TNumeric; override;
    function One:  TNumeric; override;
    function IsZero(const AEpsilon: Double = 1e-12): Boolean; override;

    { --- Quaternion-specific operations (return TQuaternion) --- }

    { Hamilton product: q1 * q2 }
    function Hamilton(const Other: TQuaternion): TQuaternion;

    { Conjugate: w - xi - yj - zk }
    function Conjugate: TQuaternion;

    { Scalar (real) part: w }
    function ScalarPart: TFloat;

    { Vector (imaginary) part: xi + yj + zk as a quaternion with w = 0 }
    function VectorPart: TQuaternion;

    { Euclidean norm: sqrt(w² + x² + y² + z²) }
    function Norm: TFloat;

    { Norm² = w² + x² + y² + z² }
    function NormSquared: Double;

    { Unit quaternion q / |q|. Raises if |q| = 0. }
    function Unity: TQuaternion;

    { Exponential: exp(q) = exp(w) * (cos|v| + (v/|v|) sin|v|) }
    function Exp: TQuaternion;

    { Natural logarithm: ln(q) = ln|q| + (v/|v|) * arccos(w/|q|) }
    function Ln: TQuaternion;

    { Power: q^p = exp(p * ln(q)) }
    function Power(const AP: Double): TQuaternion; overload;
    function Power(const AP: TFloat): TQuaternion; overload;

    { Dot product of the 4-vectors (as Doubles) }
    function Dot(const Other: TQuaternion): Double;

    { Geodesic distance on the 3-sphere of unit quaternions:
        d(q1, q2) = 2 * arccos(|<q1, q2>|)
      Both are normalized internally. Returns the angle in radians. }
    function GeodesicDistance(const Other: TQuaternion): Double;

    { Rotate a 3-vector (x,y,z) by this quaternion (assumed unit).
      Returns the rotated vector as a quaternion with w = 0. }
    function RotateVector(const AX, AY, AZ: Double): TQuaternion;

    { Direct Double accessors (no allocation). }
    property W: Double read Fw write Fw;
    property X: Double read Fx write Fx;
    property Y: Double read Fy write Fy;
    property Z: Double read Fz write Fz;

    { TFloat-typed properties for hierarchy interoperability.
      Reading allocates a fresh TFloat; caller owns it. }
    property WFloat: TFloat read GetW write SetW;
    property XFloat: TFloat read GetX write SetX;
    property YFloat: TFloat read GetY write SetY;
    property ZFloat: TFloat read GetZ write SetZ;

    { Read-only computed values }
    property ConjugateQ: TQuaternion read GetConjugate;
    property NormF: TFloat read GetNormF;
    property UnitQ: TQuaternion read GetUnit;
    property VectorQ: TQuaternion read GetVectorPart;
    property ScalarF: TFloat read GetScalarPart;
  end;

// ============================================================================
//  Operator overloads
// ============================================================================

operator + (A, B: TQuaternion): TQuaternion;
operator - (A, B: TQuaternion): TQuaternion;
operator * (A, B: TQuaternion): TQuaternion;      { Hamilton product }
operator / (A, B: TQuaternion): TQuaternion;
operator - (A: TQuaternion): TQuaternion;

{ Mixed with Double }
operator + (A: TQuaternion; B: Double): TQuaternion;
operator + (A: Double; B: TQuaternion): TQuaternion;
operator - (A: TQuaternion; B: Double): TQuaternion;
operator - (A: Double; B: TQuaternion): TQuaternion;
operator * (A: TQuaternion; B: Double): TQuaternion;
operator * (A: Double; B: TQuaternion): TQuaternion;
operator / (A: TQuaternion; B: Double): TQuaternion;
operator / (A: Double; B: TQuaternion): TQuaternion;

{ Mixed with TFloat }
operator + (A: TQuaternion; B: TFloat): TQuaternion;
operator + (A: TFloat; B: TQuaternion): TQuaternion;
operator - (A: TQuaternion; B: TFloat): TQuaternion;
operator - (A: TFloat; B: TQuaternion): TQuaternion;
operator * (A: TQuaternion; B: TFloat): TQuaternion;
operator * (A: TFloat; B: TQuaternion): TQuaternion;
operator / (A: TQuaternion; B: TFloat): TQuaternion;
operator / (A: TFloat; B: TQuaternion): TQuaternion;

{ Mixed with TComplex - treated as w + xi }
operator + (A: TQuaternion; B: TComplex): TQuaternion;
operator + (A: TComplex; B: TQuaternion): TQuaternion;
operator - (A: TQuaternion; B: TComplex): TQuaternion;
operator - (A: TComplex; B: TQuaternion): TQuaternion;
operator * (A: TQuaternion; B: TComplex): TQuaternion;
operator * (A: TComplex; B: TQuaternion): TQuaternion;
operator / (A: TQuaternion; B: TComplex): TQuaternion;
operator / (A: TComplex; B: TQuaternion): TQuaternion;

// ============================================================================
implementation
// ============================================================================

// ----------------------------------------------------------------------------
//  Constructors
// ----------------------------------------------------------------------------

constructor TQuaternion.Create(const AW, AX, AY, AZ: Double);
begin
  inherited Create;
  Fw := AW; Fx := AX; Fy := AY; Fz := AZ;
end;

constructor TQuaternion.Create(const AValue: Double);
begin
  inherited Create;
  Fw := AValue; Fx := 0; Fy := 0; Fz := 0;
end;

constructor TQuaternion.Create(const ARealPart: TFloat);
begin
  inherited Create;
  Fw := ARealPart.Value; Fx := 0; Fy := 0; Fz := 0;
end;

constructor TQuaternion.Create(const ARealPart: TComplex);
begin
  inherited Create;
  { Complex number w + x i maps to quaternion w + x i + 0 j + 0 k }
  Fw := ARealPart.RealD;
  Fx := ARealPart.ImagD;
  Fy := 0; Fz := 0;
end;

constructor TQuaternion.Create(const AW: TFloat;
  const AX, AY, AZ: TFloat);
begin
  inherited Create;
  Fw := AW.Value; Fx := AX.Value; Fy := AY.Value; Fz := AZ.Value;
end;

// ----------------------------------------------------------------------------
//  Property accessors
// ----------------------------------------------------------------------------

function TQuaternion.GetW: TFloat; begin Result := TFloat.Create(Fw); end;
function TQuaternion.GetX: TFloat; begin Result := TFloat.Create(Fx); end;
function TQuaternion.GetY: TFloat; begin Result := TFloat.Create(Fy); end;
function TQuaternion.GetZ: TFloat; begin Result := TFloat.Create(Fz); end;

procedure TQuaternion.SetW(const V: TFloat); begin Fw := V.Value; end;
procedure TQuaternion.SetX(const V: TFloat); begin Fx := V.Value; end;
procedure TQuaternion.SetY(const V: TFloat); begin Fy := V.Value; end;
procedure TQuaternion.SetZ(const V: TFloat); begin Fz := V.Value; end;

function TQuaternion.GetConjugate: TQuaternion;
begin
  Result := TQuaternion.Create(Fw, -Fx, -Fy, -Fz);
end;

function TQuaternion.GetNormF: TFloat;
begin
  Result := TFloat.Create(Sqrt(Fw * Fw + Fx * Fx + Fy * Fy + Fz * Fz));
end;

function TQuaternion.GetUnit: TQuaternion;
begin
  Result := Unity;
end;

function TQuaternion.GetVectorPart: TQuaternion;
begin
  Result := TQuaternion.Create(0, Fx, Fy, Fz);
end;

function TQuaternion.GetScalarPart: TFloat;
begin
  Result := TFloat.Create(Fw);
end;

// ----------------------------------------------------------------------------
//  TNumeric interface
// ----------------------------------------------------------------------------

function TQuaternion.Add(const Other: TNumeric): TNumeric;
var
  Q: TQuaternion;
begin
  if Other is TQuaternion then
    Q := TQuaternion(Other)
  else if Other is TComplex then
    Q := TQuaternion.Create(TComplex(Other))
  else
    Q := TQuaternion.Create(Other.AsFloat);
  try
    Result := TQuaternion.Create(
      Fw + Q.Fw, Fx + Q.Fx, Fy + Q.Fy, Fz + Q.Fz);
  finally
    if not (Other is TQuaternion) then Q.Free;
  end;
end;

function TQuaternion.Subtract(const Other: TNumeric): TNumeric;
var
  Q: TQuaternion;
begin
  if Other is TQuaternion then
    Q := TQuaternion(Other)
  else if Other is TComplex then
    Q := TQuaternion.Create(TComplex(Other))
  else
    Q := TQuaternion.Create(Other.AsFloat);
  try
    Result := TQuaternion.Create(
      Fw - Q.Fw, Fx - Q.Fx, Fy - Q.Fy, Fz - Q.Fz);
  finally
    if not (Other is TQuaternion) then Q.Free;
  end;
end;

function TQuaternion.Multiply(const Other: TNumeric): TNumeric;
var
  Q: TQuaternion;
begin
  if Other is TQuaternion then
    Q := TQuaternion(Other)
  else if Other is TComplex then
    Q := TQuaternion.Create(TComplex(Other))
  else
    Q := TQuaternion.Create(Other.AsFloat);
  try
    Result := Hamilton(Q);
  finally
    if not (Other is TQuaternion) then Q.Free;
  end;
end;

function TQuaternion.Divide(const Other: TNumeric): TNumeric;
var
  Q: TQuaternion;
  QInv: TQuaternion;
begin
  if Other is TQuaternion then
    Q := TQuaternion(Other)
  else if Other is TComplex then
    Q := TQuaternion.Create(TComplex(Other))
  else
    Q := TQuaternion.Create(Other.AsFloat);
  try
    QInv := Q.Inverse as TQuaternion;
    try
      Result := Hamilton(QInv);
    finally
      QInv.Free;
    end;
  finally
    if not (Other is TQuaternion) then Q.Free;
  end;
end;

function TQuaternion.Negate: TNumeric;
begin
  Result := TQuaternion.Create(-Fw, -Fx, -Fy, -Fz);
end;

function TQuaternion.Clone: TNumeric;
begin
  Result := TQuaternion.Create(Fw, Fx, Fy, Fz);
end;

function TQuaternion.Inverse: TNumeric;
var
  N2: Double;
begin
  N2 := Fw * Fw + Fx * Fx + Fy * Fy + Fz * Fz;
  if N2 < 1e-300 then
    raise EQuaternionError.Create('TQuaternion.Inverse: zero quaternion');
  Result := TQuaternion.Create(Fw / N2, -Fx / N2, -Fy / N2, -Fz / N2);
end;

function TQuaternion.AsFloat: Double;
begin
  if (Abs(Fx) > 1e-12) or (Abs(Fy) > 1e-12) or (Abs(Fz) > 1e-12) then
    raise EQuaternionError.Create(
      'TQuaternion.AsFloat: cannot coerce non-real quaternion to Double');
  Result := Fw;
end;

function TQuaternion.ToString: string;
begin
  Result := Format('%s + %si + %sj + %sk',
    [FloatToStr(Fw), FloatToStr(Fx), FloatToStr(Fy), FloatToStr(Fz)]);
end;

function TQuaternion.Zero: TNumeric;
begin
  Result := TQuaternion.Create(0, 0, 0, 0);
end;

function TQuaternion.One: TNumeric;
begin
  Result := TQuaternion.Create(1, 0, 0, 0);
end;

function TQuaternion.IsZero(const AEpsilon: Double): Boolean;
begin
  Result := (Abs(Fw) <= AEpsilon) and (Abs(Fx) <= AEpsilon) and
            (Abs(Fy) <= AEpsilon) and (Abs(Fz) <= AEpsilon);
end;

// ----------------------------------------------------------------------------
//  Quaternion-specific operations
// ----------------------------------------------------------------------------

function TQuaternion.Hamilton(const Other: TQuaternion): TQuaternion;
begin
  { (w1 + x1 i + y1 j + z1 k) * (w2 + x2 i + y2 j + z2 k) }
  Result := TQuaternion.Create(
    Fw * Other.Fw - Fx * Other.Fx - Fy * Other.Fy - Fz * Other.Fz,
    Fw * Other.Fx + Fx * Other.Fw + Fy * Other.Fz - Fz * Other.Fy,
    Fw * Other.Fy - Fx * Other.Fz + Fy * Other.Fw + Fz * Other.Fx,
    Fw * Other.Fz + Fx * Other.Fy - Fy * Other.Fx + Fz * Other.Fw);
end;

function TQuaternion.Conjugate: TQuaternion;
begin
  Result := TQuaternion.Create(Fw, -Fx, -Fy, -Fz);
end;

function TQuaternion.ScalarPart: TFloat;
begin
  Result := TFloat.Create(Fw);
end;

function TQuaternion.VectorPart: TQuaternion;
begin
  Result := TQuaternion.Create(0, Fx, Fy, Fz);
end;

function TQuaternion.Norm: TFloat;
begin
  Result := TFloat.Create(Sqrt(Fw * Fw + Fx * Fx + Fy * Fy + Fz * Fz));
end;

function TQuaternion.NormSquared: Double;
begin
  Result := Fw * Fw + Fx * Fx + Fy * Fy + Fz * Fz;
end;

function TQuaternion.Unity: TQuaternion;
var
  N: Double;
begin
  N := Sqrt(Fw * Fw + Fx * Fx + Fy * Fy + Fz * Fz);
  if N < 1e-300 then
    raise EQuaternionError.Create('TQuaternion.Unit: zero quaternion');
  Result := TQuaternion.Create(Fw / N, Fx / N, Fy / N, Fz / N);
end;

function TQuaternion.Exp: TQuaternion;
var
  VLen, EW: Double;
  S, C: Double;
begin
  { exp(q) = exp(w) * (cos|v| + (v/|v|) sin|v|) }
  VLen := Sqrt(Fx * Fx + Fy * Fy + Fz * Fz);
  EW := System.Exp(Fw);
  if VLen < 1e-300 then
    Result := TQuaternion.Create(EW, 0, 0, 0)
  else
  begin
    S := Sin(VLen) / VLen;
    C := Cos(VLen);
    Result := TQuaternion.Create(EW * C, EW * S * Fx, EW * S * Fy, EW * S * Fz);
  end;
end;

function TQuaternion.Ln: TQuaternion;
var
  QNorm, VLen, Theta: Double;
begin
  { ln(q) = ln|q| + (v/|v|) * arccos(w/|q|) }
  QNorm := Sqrt(Fw * Fw + Fx * Fx + Fy * Fy + Fz * Fz);
  if QNorm < 1e-300 then
    raise EQuaternionError.Create('TQuaternion.Ln: logarithm of zero');
  VLen := Sqrt(Fx * Fx + Fy * Fy + Fz * Fz);
  if VLen < 1e-300 then
    Result := TQuaternion.Create(System.Ln(QNorm), 0, 0, 0)
  else
  begin
    Theta := ArcCos(Fw / QNorm);   { in [0, pi] }
    Result := TQuaternion.Create(
      System.Ln(QNorm),
      Theta * Fx / VLen,
      Theta * Fy / VLen,
      Theta * Fz / VLen);
  end;
end;

function TQuaternion.Power(const AP: Double): TQuaternion;
var
  L: TQuaternion;
begin
  { q^p = exp(p * ln(q)) }
  L := Ln;
  try
    Result := TQuaternion.Create(
      AP * L.Fw, AP * L.Fx, AP * L.Fy, AP * L.Fz).Exp;
  finally
    L.Free;
  end;
end;

function TQuaternion.Power(const AP: TFloat): TQuaternion;
begin
  Result := Power(AP.Value);
end;

function TQuaternion.Dot(const Other: TQuaternion): Double;
begin
  Result := Fw * Other.Fw + Fx * Other.Fx + Fy * Other.Fy + Fz * Other.Fz;
end;

function TQuaternion.GeodesicDistance(const Other: TQuaternion): Double;
var
  U1, U2: TQuaternion;
  D: Double;
begin
  U1 := Unity;
  try
    U2 := Other.Unity;
    try
      D := U1.Dot(U2);
      if D < 0 then D := -D;
      if D > 1 then D := 1;
      Result := 2.0 * ArcCos(D);
    finally
      U2.Free;
    end;
  finally
    U1.Free;
  end;
end;

function TQuaternion.RotateVector(const AX, AY, AZ: Double): TQuaternion;
var
  P, Q, QC, Tmp: TQuaternion;
begin
  { Standard formula: p' = q p q^-1 where p = (0, x, y, z) }
  P := TQuaternion.Create(0, AX, AY, AZ);
  try
    Q := Unity;
    try
      QC := Q.Conjugate;
      try
        Tmp := Q.Hamilton(P);
        try
          Result := Tmp.Hamilton(QC);
        finally
          Tmp.Free;
        end;
      finally
        QC.Free;
      end;
    finally
      Q.Free;
    end;
  finally
    P.Free;
  end;
end;

// ============================================================================
//  Operator overloads
// ============================================================================

operator + (A, B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion(A.Add(B));
end;

operator - (A, B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion(A.Subtract(B));
end;

operator * (A, B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion(A.Multiply(B));
end;

operator / (A, B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion(A.Divide(B));
end;

operator - (A: TQuaternion): TQuaternion;
begin
  Result := TQuaternion(A.Negate);
end;

// --- Mixed with Double ---

operator + (A: TQuaternion; B: Double): TQuaternion;
begin Result := TQuaternion.Create(A.Fw + B, A.Fx, A.Fy, A.Fz); end;

operator + (A: Double; B: TQuaternion): TQuaternion;
begin Result := TQuaternion.Create(A + B.Fw, B.Fx, B.Fy, B.Fz); end;

operator - (A: TQuaternion; B: Double): TQuaternion;
begin Result := TQuaternion.Create(A.Fw - B, A.Fx, A.Fy, A.Fz); end;

operator - (A: Double; B: TQuaternion): TQuaternion;
begin Result := TQuaternion.Create(A - B.Fw, -B.Fx, -B.Fy, -B.Fz); end;

operator * (A: TQuaternion; B: Double): TQuaternion;
begin
  Result := TQuaternion.Create(A.Fw * B, A.Fx * B, A.Fy * B, A.Fz * B);
end;

operator * (A: Double; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A * B.Fw, A * B.Fx, A * B.Fy, A * B.Fz);
end;

operator / (A: TQuaternion; B: Double): TQuaternion;
begin
  if B = 0.0 then
    raise EQuaternionError.Create('TQuaternion /: division by zero');
  Result := TQuaternion.Create(A.Fw / B, A.Fx / B, A.Fy / B, A.Fz / B);
end;

operator / (A: Double; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A).Divide(B) as TQuaternion;
end;

// --- Mixed with TFloat ---

operator + (A: TQuaternion; B: TFloat): TQuaternion;
begin Result := TQuaternion.Create(A.Fw + B.Value, A.Fx, A.Fy, A.Fz); end;

operator + (A: TFloat; B: TQuaternion): TQuaternion;
begin Result := TQuaternion.Create(A.Value + B.Fw, B.Fx, B.Fy, B.Fz); end;

operator - (A: TQuaternion; B: TFloat): TQuaternion;
begin Result := TQuaternion.Create(A.Fw - B.Value, A.Fx, A.Fy, A.Fz); end;

operator - (A: TFloat; B: TQuaternion): TQuaternion;
begin Result := TQuaternion.Create(A.Value - B.Fw, -B.Fx, -B.Fy, -B.Fz); end;

operator * (A: TQuaternion; B: TFloat): TQuaternion;
begin
  Result := TQuaternion.Create(A.Fw * B.Value, A.Fx * B.Value,
                               A.Fy * B.Value, A.Fz * B.Value);
end;

operator * (A: TFloat; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A.Value * B.Fw, A.Value * B.Fx,
                               A.Value * B.Fy, A.Value * B.Fz);
end;

operator / (A: TQuaternion; B: TFloat): TQuaternion;
begin
  if B.Value = 0.0 then
    raise EQuaternionError.Create('TQuaternion /: division by zero');
  Result := TQuaternion.Create(A.Fw / B.Value, A.Fx / B.Value,
                               A.Fy / B.Value, A.Fz / B.Value);
end;

operator / (A: TFloat; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A.Value).Divide(B) as TQuaternion;
end;

// --- Mixed with TComplex - treated as w + xi ---

operator + (A: TQuaternion; B: TComplex): TQuaternion;
begin
  Result := TQuaternion.Create(A.Fw + B.RealD, A.Fx + B.ImagD, A.Fy, A.Fz);
end;

operator + (A: TComplex; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A.RealD + B.Fw, A.ImagD + B.Fx, B.Fy, B.Fz);
end;

operator - (A: TQuaternion; B: TComplex): TQuaternion;
begin
  Result := TQuaternion.Create(A.Fw - B.RealD, A.Fx - B.ImagD, A.Fy, A.Fz);
end;

operator - (A: TComplex; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A.RealD - B.Fw, A.ImagD - B.Fx, -B.Fy, -B.Fz);
end;

operator * (A: TQuaternion; B: TComplex): TQuaternion;
begin
  Result := A.Hamilton(TQuaternion.Create(B));
end;

operator * (A: TComplex; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A).Hamilton(B);
end;

operator / (A: TQuaternion; B: TComplex): TQuaternion;
begin
  Result := A.Hamilton(TQuaternion.Create(B).Inverse as TQuaternion);
end;

operator / (A: TComplex; B: TQuaternion): TQuaternion;
begin
  Result := TQuaternion.Create(A).Hamilton(B.Inverse as TQuaternion);
end;

end.
