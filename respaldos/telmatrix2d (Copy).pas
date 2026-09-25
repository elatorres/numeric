unit TELMatrix2D;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math, Classes,
  TELNumeric, TELFloat, TELInteger, TELComplex, TELBits, TELBinaryVector, TELRational;

type
  EMatrixError = class(ENumericError);

  TBinaryNumericOp = function(const A, B: TNumeric): TNumeric of object;

  TNumericGrid = array of array of TNumeric;

  { Parse a matrix whose elements are of a given concrete type.
  AElemParser is a callback that parses one element string into a TNumeric. }
  TElementParser = function(const S: string): TNumeric of object;
  TElementParseFunc = function(const S: string): TNumeric;

  TMatrix2D = class(TNumeric)
  private
    FData: TNumericGrid;
    FRows: Integer;
    FCols: Integer;

    procedure AllocateGrid(const ARows, ACols: Integer);
    procedure FreeGrid;
    function  GetElement(const ARow, ACol: Integer): TNumeric;
    procedure SetElement(const ARow, ACol: Integer; AValue: TNumeric);
    
    function ApplyScalarOp(const Scalar: TNumeric; Op: TBinaryNumericOp): TMatrix2D;
  public
    constructor Create(const ARows, ACols: Integer);
    destructor  Destroy; override;

    { Class functions - build matrices }
    class function Identity(const N: Integer): TMatrix2D; static;
    class function IdentityOf(const N: Integer; const ADiagonal: TNumeric): TMatrix2D; static;
    class function Zeros(const ARows, ACols: Integer): TMatrix2D; static;

    { Arithmetic - works for real, complex, rational, etc. }
    function Add     (const Other: TNumeric): TNumeric; override;
    function Subtract(const Other: TNumeric): TNumeric; override;
    function Multiply(const Other: TNumeric): TNumeric; override;
    function Divide  (const Other: TNumeric): TNumeric; override;
    function Negate  :                        TNumeric; override;
    function Clone   :                        TNumeric; override;
    function Inverse :                        TNumeric; override;
    function AsFloat :                        Double;   override;
    function ToString:                        string;   override;

    { TNumeric identities - not meaningful for a matrix in general,
      but needed because they are abstract in TNumeric.
      Raise if called on a non-square matrix. }
    function Zero: TNumeric; override;
    function One:  TNumeric; override;

    { Scalar operations - return new matrix, caller owns }
    function MultiplyByScalar(const Scalar: TNumeric): TMatrix2D;
    function DivideByScalar  (const Scalar: TNumeric): TMatrix2D;
    function AddScalar       (const Scalar: TNumeric): TMatrix2D;
    function SubtractScalar    (const Scalar: TNumeric): TMatrix2D;   { new }
    
    { Typed convenience wrappers }
    function ScaleByInteger(const Scalar: TInteger): TMatrix2D;
    function ScaleByFloat  (const Scalar: TFloat):   TMatrix2D;
    function ScaleByComplex(const Scalar: TComplex): TMatrix2D;

    { Transpose - new matrix, caller owns }
        { Ordinary transpose: A[i,j] -> A[j,i] }
    function Transpose: TMatrix2D;

    { Conjugate (Hermitian) transpose: A[i,j] -> conj(A[j,i]).
      For real matrices this equals Transpose. }
    function ConjugateTranspose: TMatrix2D;

    { Alias for ConjugateTranspose - common in linear algebra notation. }
    function Adjoint: TMatrix2D;

    function IsHermitian(const AEpsilon: Double = 1e-12): Boolean;
    function IsSymmetric(const AEpsilon: Double = 1e-12): Boolean;

    { Determinant - square matrices only. Newly allocated TNumeric. }
    function Determinant: TNumeric;

    { Fill every element with a Clone of Scalar }
    procedure FillWith(const Scalar: TNumeric);

    { Make this matrix the identity in place (square only) }
    procedure MakeIdentity;

    property Rows: Integer read FRows;
    property Cols: Integer read FCols;
    property Elements[ARow, ACol: Integer]: TNumeric
      read GetElement write SetElement; default;

    class function CreateFromStringEx(const S: string; AElementParser: TElementParseFunc): TMatrix2D; static;
    class function CreateFromStringFloat(const S: string): TMatrix2D; static;
    class function CreateFromStringComplex(const S: string): TMatrix2D; static;
    class function CreateFromStringRational(const S: string): TMatrix2D; static;

        { Norms. All return a newly allocated TFloat; caller owns it. }
    function FrobeniusNorm: TFloat;      { sqrt(sum |aij|^2) }
    function Norm1: TFloat;              { max column sum of |aij| }
    function NormInfinity: TFloat;       { max row sum of |aij| }
    function SpectralNorm(const ATol: Double = 1e-12;
                          const AMaxIter: Integer = 1000): TFloat;

    { Convenience: the "default" matrix norm is the Frobenius norm, which is
      what most callers mean by "the Euclidean norm of a matrix". }
    function EuclideanNorm: TFloat;

  end;

// ============================================================================
//  Operator overloads for TMatrix2D
// ============================================================================

operator + (A, B: TMatrix2D): TMatrix2D;
operator - (A, B: TMatrix2D): TMatrix2D;
operator * (A, B: TMatrix2D): TMatrix2D;
operator - (A: TMatrix2D): TMatrix2D;

{ Matrix * scalar }
operator * (A: TMatrix2D; S: TInteger): TMatrix2D;
operator * (A: TMatrix2D; S: TFloat):   TMatrix2D;
operator * (A: TMatrix2D; S: TComplex): TMatrix2D;
operator * (S: TInteger; A: TMatrix2D): TMatrix2D;
operator * (S: TFloat;   A: TMatrix2D): TMatrix2D;
operator * (S: TComplex; A: TMatrix2D): TMatrix2D;

{ Matrix / scalar }
operator / (A: TMatrix2D; S: TInteger): TMatrix2D;
operator / (A: TMatrix2D; S: TFloat):   TMatrix2D;
operator / (A: TMatrix2D; S: TComplex): TMatrix2D;

{ Matrix + scalar }
 operator + (A: TMatrix2D; S: TInteger): TMatrix2D;
 operator + (A: TMatrix2D; S: TFloat):   TMatrix2D;
 operator + (A: TMatrix2D; S: TComplex): TMatrix2D;

{ Matrix - scalar }
operator - (A: TMatrix2D; S: TInteger): TMatrix2D;
operator - (A: TMatrix2D; S: TFloat):   TMatrix2D;
operator - (A: TMatrix2D; S: TComplex): TMatrix2D;

// ============================================================================
implementation
// ============================================================================

{ --- In the implementation, near the top --- }

{ Magnitude of a TNumeric as a non-negative Double.
  For real types this is Abs(value); for complex it is the modulus. }
function NumericMagnitude(const N: TNumeric): Double;
var
  Z: TComplex;
begin
  if N is TComplex then
  begin
    Z := TComplex(N);
    Result := Sqrt(Z.RealD * Z.RealD + Z.ImagD * Z.ImagD);
  end
  else
    Result := Abs(N.AsFloat);
end;

{ Divide a TNumeric by a Double, returning a new TNumeric. }
function DivideByDouble(const N: TNumeric; const D: Double): TNumeric;
var
  DNum: TFloat;
begin
  DNum := TFloat.Create(D);
  try
    Result := N.Divide(DNum);
  finally
    DNum.Free;
  end;
end;

function ParseFloatElem(const S: string): TNumeric;
begin
  Result := TFloat.CreateFromString(S);
end;

function ParseComplexElem(const S: string): TNumeric;
begin
  Result := TComplex.CreateFromString(S);
end;

function ParseRationalElem(const S: string): TNumeric;
begin
  Result := TRational.CreateFromString(S);
end;

// ----------------------------------------------------------------------------
{ --------------------------------------------------------------------------
  Helper: promote a non-complex numeric to TComplex.

  Returns the ORIGINAL object if it is already TComplex (so the caller must
  not free it in that case). Otherwise returns a freshly allocated TComplex
  that the caller must free.
  -------------------------------------------------------------------------- }
function PromoteToComplex(const N: TNumeric): TComplex;
begin
  if N is TComplex then
    Result := TComplex(N)                 { borrowed reference }
  else
    Result := TComplex.Create(N.AsFloat, 0.0);   { owned }
end;

{ --------------------------------------------------------------------------
  Helper: perform a binary operation (Cell op Scalar) with automatic
  promotion to the complex field when the scalar is complex but the cell
  is not. The callback Op is applied to (Cell, Scalar) after any needed
  promotion. Both operands are guaranteed to be the same type family
  once promotion is done.
  -------------------------------------------------------------------------- }

function TMatrix2D.ApplyScalarOp(const Scalar: TNumeric;
  Op: TBinaryNumericOp): TMatrix2D;
var
  R, C: Integer;
  Cell, PromotedCell: TNumeric;
  Res: TMatrix2D;
  PromoteNeeded: Boolean;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  PromoteNeeded := (Scalar is TComplex);
  try
    for R := 0 to FRows - 1 do
      for C := 0 to FCols - 1 do
      begin
        Cell := FData[R][C];
        if PromoteNeeded and not (Cell is TComplex) then
        begin
          PromotedCell := TComplex.Create(Cell.AsFloat, 0.0);
          try
            Res.Elements[R, C] := Op(PromotedCell, Scalar);
          finally
            PromotedCell.Free;
          end;
        end
        else
          Res.Elements[R, C] := Op(Cell, Scalar);
      end;
    Result := Res;
  except
    Res.Free;
    raise;
  end;
end;



// ----------------------------------------------------------------------------
//  Private helpers
// ----------------------------------------------------------------------------

procedure TMatrix2D.AllocateGrid(const ARows, ACols: Integer);
var
  R: Integer;
begin
  SetLength(FData, ARows);
  for R := 0 to ARows - 1 do
    SetLength(FData[R], ACols);
end;

procedure TMatrix2D.FreeGrid;
var
  R, C: Integer;
begin
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      FreeAndNil(FData[R][C]);
  SetLength(FData, 0);
end;

function TMatrix2D.GetElement(const ARow, ACol: Integer): TNumeric;
begin
  if (ARow < 0) or (ARow >= FRows) or (ACol < 0) or (ACol >= FCols) then
    raise EMatrixError.CreateFmt(
      'TMatrix2D: index (%d, %d) out of bounds [%d x %d]',
      [ARow, ACol, FRows, FCols]);
  Result := FData[ARow][ACol];
end;

procedure TMatrix2D.SetElement(const ARow, ACol: Integer; AValue: TNumeric);
begin
  if (ARow < 0) or (ARow >= FRows) or (ACol < 0) or (ACol >= FCols) then
    raise EMatrixError.CreateFmt(
      'TMatrix2D: index (%d, %d) out of bounds [%d x %d]',
      [ARow, ACol, FRows, FCols]);
  FreeAndNil(FData[ARow][ACol]);
  FData[ARow][ACol] := AValue;
end;

// ----------------------------------------------------------------------------
//  Constructors / class functions
// ----------------------------------------------------------------------------

constructor TMatrix2D.Create(const ARows, ACols: Integer);
var
  R, C: Integer;
begin
  inherited Create;
  if (ARows <= 0) or (ACols <= 0) then
    raise EMatrixError.Create('TMatrix2D.Create: dimensions must be positive');
  FRows := ARows;
  FCols := ACols;
  AllocateGrid(ARows, ACols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      FData[R][C] := TFloat.Create(0.0);
end;

destructor TMatrix2D.Destroy;
begin
  FreeGrid;
  inherited Destroy;
end;

class function TMatrix2D.Identity(const N: Integer): TMatrix2D;
var
  OneF: TFloat;
begin
  OneF := TFloat.Create(1.0);
  try
    Result := IdentityOf(N, OneF);
  finally
    OneF.Free;
  end;
end;

class function TMatrix2D.IdentityOf(const N: Integer; const ADiagonal: TNumeric): TMatrix2D;
var
  R, C: Integer;
begin
  if N <= 0 then
    raise EMatrixError.Create('TMatrix2D.IdentityOf: N must be positive');
  Result := TMatrix2D.Create(N, N);
  for R := 0 to N - 1 do
    for C := 0 to N - 1 do
      if R = C then
        Result.Elements[R, C] := ADiagonal.Clone
      else
        Result.Elements[R, C] := ADiagonal.Zero;
end;

class function TMatrix2D.Zeros(const ARows, ACols: Integer): TMatrix2D;
begin
  Result := TMatrix2D.Create(ARows, ACols);
end;

// ----------------------------------------------------------------------------
//  Arithmetic
// ----------------------------------------------------------------------------

function TMatrix2D.Add(const Other: TNumeric): TNumeric;
var
  B: TMatrix2D;
  Res: TMatrix2D;
  R, C: Integer;
begin
  if not (Other is TMatrix2D) then
    raise EMatrixError.Create('TMatrix2D.Add: both operands must be TMatrix2D');
  B := TMatrix2D(Other);
  if (FRows <> B.FRows) or (FCols <> B.FCols) then
    raise EMatrixError.CreateFmt(
      'TMatrix2D.Add: dimension mismatch (%dx%d) vs (%dx%d)',
      [FRows, FCols, B.FRows, B.FCols]);

  Res := TMatrix2D.Create(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Res.Elements[R, C] := FData[R][C].Add(B.FData[R][C]);
  Result := Res;
end;

function TMatrix2D.Subtract(const Other: TNumeric): TNumeric;
var
  B: TMatrix2D;
  Res: TMatrix2D;
  R, C: Integer;
begin
  if not (Other is TMatrix2D) then
    raise EMatrixError.Create('TMatrix2D.Subtract: both operands must be TMatrix2D');
  B := TMatrix2D(Other);
  if (FRows <> B.FRows) or (FCols <> B.FCols) then
    raise EMatrixError.CreateFmt(
      'TMatrix2D.Subtract: dimension mismatch (%dx%d) vs (%dx%d)',
      [FRows, FCols, B.FRows, B.FCols]);

  Res := TMatrix2D.Create(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Res.Elements[R, C] := FData[R][C].Subtract(B.FData[R][C]);
  Result := Res;
end;

function TMatrix2D.Multiply(const Other: TNumeric): TNumeric;
//
//  Standard matrix product: Self (m x n) * Other (n x p) -> (m x p).
//
//  We seed the accumulator with the FIRST product, not with a TFloat(0),
//  because TFloat(0) would lose information when elements are TComplex
//  (or any other type whose neutral element is not a TFloat).
//
var
  B: TMatrix2D;
  Res: TMatrix2D;
  R, C, K: Integer;
  Acc, Prod, Tmp: TNumeric;
begin
  if not (Other is TMatrix2D) then
    raise EMatrixError.Create('TMatrix2D.Multiply: both operands must be TMatrix2D');
  B := TMatrix2D(Other);
  if FCols <> B.FRows then
    raise EMatrixError.CreateFmt(
      'TMatrix2D.Multiply: inner dimensions must match (%d vs %d)',
      [FCols, B.FRows]);

  Res := TMatrix2D.Create(FRows, B.FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to B.FCols - 1 do
    begin
      Acc := FData[R][0].Multiply(B.FData[0][C]);
      for K := 1 to FCols - 1 do
      begin
        Prod := FData[R][K].Multiply(B.FData[K][C]);
        Tmp  := Acc.Add(Prod);
        Prod.Free;
        Acc.Free;
        Acc := Tmp;
      end;
      Res.Elements[R, C] := Acc;
    end;
  Result := Res;
end;

function TMatrix2D.Divide(const Other: TNumeric): TNumeric;
var
  B: TMatrix2D;
  Inv: TMatrix2D;
begin
  if not (Other is TMatrix2D) then
    raise EMatrixError.Create('TMatrix2D.Divide: both operands must be TMatrix2D');
  B   := TMatrix2D(Other);
  Inv := B.Inverse as TMatrix2D;
  try
    Result := Self.Multiply(Inv);
  finally
    Inv.Free;
  end;
end;

function TMatrix2D.Negate: TNumeric;
var
  Res: TMatrix2D;
  R, C: Integer;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Res.Elements[R, C] := FData[R][C].Negate;
  Result := Res;
end;

function TMatrix2D.Clone: TNumeric;
var
  Res: TMatrix2D;
  R, C: Integer;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Res.Elements[R, C] := FData[R][C].Clone;
  Result := Res;
end;

function TMatrix2D.Inverse: TNumeric;
//
//  Generic Gauss-Jordan inversion.
//
//  Works for any element type that supports:
//    Add / Subtract / Multiply / Divide / Negate / Clone / IsZero / Zero / One
//
//  Partial pivoting uses the element's own IsZero test; no AsFloat needed,
//  so complex matrices are handled correctly.
//
var
  N, I, J, K: Integer;
  Aug: array of array of TNumeric;
  PivotRow: Integer;
  Pivot, Factor, Temp, NewVal: TNumeric;
begin
  if FRows <> FCols then
    raise EMatrixError.CreateFmt(
      'TMatrix2D.Inverse: matrix must be square (%dx%d)', [FRows, FCols]);

  N := FRows;

  { --- Build augmented matrix [A | I] with matching element type --- }
  SetLength(Aug, N, 2 * N);

  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      Aug[I, J] := FData[I, J].Clone;

  { Identity block: use Zero/One of the element type, derived from an
    existing element (FData[0,0]). This preserves the type exactly -
    TComplex matrices get TComplex(1,0) and TComplex(0,0), rational
    matrices get TRational(1,1) and TRational(0,1), and so on. }
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      if I = J then
        Aug[I, N + J] := FData[0, 0].One
      else
        Aug[I, N + J] := FData[0, 0].Zero;

  { --- Gauss-Jordan elimination --- }
  for I := 0 to N - 1 do
  begin
    { Find a pivot row with a non-zero element in column I }
    PivotRow := -1;
    for J := I to N - 1 do
      if not Aug[J, I].IsZero then
      begin
        PivotRow := J;
        Break;
      end;

    if PivotRow < 0 then
      raise EMatrixError.Create(
        'TMatrix2D.Inverse: matrix is singular (no pivot found)');

    { Swap rows I and PivotRow if needed }
    if PivotRow <> I then
      for K := 0 to 2 * N - 1 do
      begin
        Temp := Aug[I, K];
        Aug[I, K] := Aug[PivotRow, K];
        Aug[PivotRow, K] := Temp;
      end;

    { Scale row I - CLONE the pivot before the loop, because the loop
      frees Aug[I, K] cells including Aug[I, I] itself when K = I }
    Pivot := Aug[I, I].Clone;
    try
      if not Pivot.IsZero then
        for K := 0 to 2 * N - 1 do
        begin
          NewVal := Aug[I, K].Divide(Pivot);
          Aug[I, K].Free;
          Aug[I, K] := NewVal;
        end;

      { Eliminate column I from every other row }
      for J := 0 to N - 1 do
        if J <> I then
        begin
          { CLONE Factor too - Aug[J, I] gets freed when K = I below }
          Factor := Aug[J, I].Clone;
          try
            if not Factor.IsZero then
              for K := 0 to 2 * N - 1 do
              begin
                Temp   := Factor.Multiply(Aug[I, K]);
                NewVal := Aug[J, K].Subtract(Temp);
                Temp.Free;
                Aug[J, K].Free;
                Aug[J, K] := NewVal;
              end;
          finally
            Factor.Free;
          end;
        end;
    finally
      Pivot.Free;
    end;
  end;

  { --- Extract inverse from the right half --- }
  Result := TMatrix2D.Create(N, N);
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      TMatrix2D(Result).Elements[I, J] := Aug[I, N + J];
      Aug[I, N + J] := nil;   { ownership transferred }
    end;

  { Free the left half }
  for I := 0 to N - 1 do
    for K := 0 to N - 1 do
      FreeAndNil(Aug[I, K]);
  SetLength(Aug, 0);
end;

function TMatrix2D.AsFloat: Double;
begin
  raise EMatrixError.Create('TMatrix2D.AsFloat: cannot coerce matrix to scalar');
  Result := 0.0;
end;

function TMatrix2D.Zero: TNumeric;
begin
  raise EMatrixError.Create('TMatrix2D.Zero: undefined for matrices');
  Result := nil;
end;

function TMatrix2D.One: TNumeric;
begin
  raise EMatrixError.Create('TMatrix2D.One: undefined for matrices');
  Result := nil;
end;

function TMatrix2D.ToString: string;
var
  R, C: Integer;
  Row: string;
begin
  Result := '[' + LineEnding;
  for R := 0 to FRows - 1 do
  begin
    Row := ' [ ';
    for C := 0 to FCols - 1 do
    begin
      Row := Row + FData[R][C].ToString;
      if C < FCols - 1 then
        Row := Row + ',  ';
    end;
    Row := Row + ' ]';
    if R < FRows - 1 then
      Result := Result + Row + LineEnding
    else
      Result := Result + Row;
  end;
  Result := Result + LineEnding + ']';
end;

// ----------------------------------------------------------------------------
//  Scalar operations
// ----------------------------------------------------------------------------


function TMatrix2D.MultiplyByScalar(const Scalar: TNumeric): TMatrix2D;
var
  Res: TMatrix2D;
  R, C: Integer;
  Cell, PromotedCell, Prod: TNumeric;
  ScalarIsComplex: Boolean;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  ScalarIsComplex := Scalar is TComplex;
  try
    for R := 0 to FRows - 1 do
      for C := 0 to FCols - 1 do
      begin
        Cell := FData[R][C];
      { If the scalar is complex but the cell is not, promote the cell to
        complex first so the multiplication happens in the complex field.
        Otherwise multiply as-is. }        
        if ScalarIsComplex and not (Cell is TComplex) then
        begin
          PromotedCell := TComplex.Create(Cell.AsFloat, 0.0);
          try
            Prod := PromotedCell.Multiply(Scalar);
          finally
            PromotedCell.Free;
          end;
          Res.Elements[R, C] := Prod;
        end
        else
          Res.Elements[R, C] := Cell.Multiply(Scalar);
      end;
    Result := Res;
  except
    Res.Free;
    raise;
  end;
end;

function TMatrix2D.DivideByScalar(const Scalar: TNumeric): TMatrix2D;
var
  Res: TMatrix2D;
  R, C: Integer;
  Cell, PromotedCell, Quot: TNumeric;
  ScalarIsComplex: Boolean;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  ScalarIsComplex := Scalar is TComplex;
  try
    for R := 0 to FRows - 1 do
      for C := 0 to FCols - 1 do
      begin
        Cell := FData[R][C];
        if ScalarIsComplex and not (Cell is TComplex) then
        begin
          PromotedCell := TComplex.Create(Cell.AsFloat, 0.0);
          try
            Quot := PromotedCell.Divide(Scalar);
          finally
            PromotedCell.Free;
          end;
          Res.Elements[R, C] := Quot;
        end
        else
          Res.Elements[R, C] := Cell.Divide(Scalar);
      end;
    Result := Res;
  except
    Res.Free;
    raise;
  end;
end;

function TMatrix2D.AddScalar(const Scalar: TNumeric): TMatrix2D;
var
  Res: TMatrix2D;
  R, C: Integer;
  Cell, PromotedCell, Sum: TNumeric;
  ScalarIsComplex: Boolean;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  ScalarIsComplex := Scalar is TComplex;
  try
    for R := 0 to FRows - 1 do
      for C := 0 to FCols - 1 do
      begin
        Cell := FData[R][C];
        if ScalarIsComplex and not (Cell is TComplex) then
        begin
          PromotedCell := TComplex.Create(Cell.AsFloat, 0.0);
          try
            Sum := PromotedCell.Add(Scalar);
          finally
            PromotedCell.Free;
          end;
          Res.Elements[R, C] := Sum;
        end
        else
          Res.Elements[R, C] := Cell.Add(Scalar);
      end;
    Result := Res;
  except
    Res.Free;
    raise;
  end;
end;

function TMatrix2D.SubtractScalar(const Scalar: TNumeric): TMatrix2D;
var
  Res: TMatrix2D;
  R, C: Integer;
  Cell, PromotedCell, Diff: TNumeric;
  ScalarIsComplex: Boolean;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  ScalarIsComplex := Scalar is TComplex;
  try
    for R := 0 to FRows - 1 do
      for C := 0 to FCols - 1 do
      begin
        Cell := FData[R][C];
        if ScalarIsComplex and not (Cell is TComplex) then
        begin
          PromotedCell := TComplex.Create(Cell.AsFloat, 0.0);
          try
            Diff := PromotedCell.Subtract(Scalar);
          finally
            PromotedCell.Free;
          end;
          Res.Elements[R, C] := Diff;
        end
        else
          Res.Elements[R, C] := Cell.Subtract(Scalar);
      end;
    Result := Res;
  except
    Res.Free;
    raise;
  end;
end;


function TMatrix2D.ScaleByInteger(const Scalar: TInteger): TMatrix2D;
begin
  Result := MultiplyByScalar(Scalar);
end;

function TMatrix2D.ScaleByFloat(const Scalar: TFloat): TMatrix2D;
begin
  Result := MultiplyByScalar(Scalar);
end;

function TMatrix2D.ScaleByComplex(const Scalar: TComplex): TMatrix2D;
begin
  Result := MultiplyByScalar(Scalar);
end;

// ----------------------------------------------------------------------------
//  Transpose / Determinant / Fill / MakeIdentity
// ----------------------------------------------------------------------------

function TMatrix2D.Transpose: TMatrix2D;
var
  R, C: Integer;
begin
  Result := TMatrix2D.Create(FCols, FRows);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Result.Elements[C, R] := FData[R][C].Clone;
end;

function TMatrix2D.ConjugateTranspose: TMatrix2D;
var
  R, C: Integer;
  Cell, Conj: TNumeric;
begin
  Result := TMatrix2D.Create(FCols, FRows);
  try
    for R := 0 to FRows - 1 do
      for C := 0 to FCols - 1 do
      begin
        Cell := FData[R][C];
        if Cell is TComplex then
        begin
          { A^H[C, R] = conj(A[R, C]) }
          Conj := TComplex(Cell).Conjugate;
          Result.Elements[C, R] := Conj;
        end
        else
          { Real elements: conjugate is identity }
          Result.Elements[C, R] := Cell.Clone;
      end;
  except
    Result.Free;
    raise;
  end;
end;

function TMatrix2D.Adjoint: TMatrix2D;
begin
  Result := ConjugateTranspose;
end;

function TMatrix2D.IsHermitian(const AEpsilon: Double): Boolean;
var
  R, C: Integer;
  A_ij, A_ji_conj: TNumeric;
  Diff: TNumeric;
  MaxDiff: Double;
begin
  if FRows <> FCols then
  begin
    Result := False;
    Exit;
  end;
  MaxDiff := 0.0;
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
    begin
      A_ij := FData[R][C];
      if FData[C][R] is TComplex then
        A_ji_conj := TComplex(FData[C][R]).Conjugate
      else
        A_ji_conj := FData[C][R].Clone;
      try
        Diff := A_ij.Subtract(A_ji_conj);
        try
          MaxDiff := Max(MaxDiff, NumericMagnitude(Diff));
        finally
          Diff.Free;
        end;
      finally
        A_ji_conj.Free;
      end;
    end;
  Result := MaxDiff <= AEpsilon;
end;

function TMatrix2D.IsSymmetric(const AEpsilon: Double): Boolean;
begin
  { A real symmetric matrix is exactly a Hermitian matrix with real entries.
    The IsHermitian test also works for real matrices, since conjugate of a
    real number is itself. }
  Result := IsHermitian(AEpsilon);
end;


function TMatrix2D.Determinant: TNumeric;
//
//  Cofactor-expansion determinant that works for any TNumeric element type,
//  including TComplex and TRational. O(n!) but fine for small matrices.
//
var
  Sign: Integer;
  I, J, K, N: Integer;
  Sub: TMatrix2D;
  MinorDet, Term, Sum, Tmp: TNumeric;
  NegOne: TNumeric;
begin
  if FRows <> FCols then
    raise EMatrixError.CreateFmt(
      'TMatrix2D.Determinant: matrix must be square (%dx%d)', [FRows, FCols]);

  N := FRows;
  if N = 1 then
  begin
    Result := FData[0, 0].Clone;
    Exit;
  end;
  if N = 2 then
  begin
    { ad - bc }
    Term := FData[0, 0].Multiply(FData[1, 1]);
    Tmp  := FData[0, 1].Multiply(FData[1, 0]);
    Result := Term.Subtract(Tmp);
    Term.Free;
    Tmp.Free;
    Exit;
  end;

  { General cofactor expansion along row 0 }
  Sign := 1;
  Sum  := nil;
  for J := 0 to N - 1 do
  begin
    { Build (N-1)x(N-1) minor by deleting row 0 and column J }
    Sub := TMatrix2D.Create(N - 1, N - 1);
    for I := 1 to N - 1 do
      for K := 0 to N - 1 do
        if K <> J then
        begin
          if K < J then
            Sub.Elements[I - 1, K] := FData[I, K].Clone
          else
            Sub.Elements[I - 1, K - 1] := FData[I, K].Clone;
        end;

    MinorDet := Sub.Determinant;
    Sub.Free;

    Term := FData[0, J].Multiply(MinorDet);
    MinorDet.Free;

    if Sign < 0 then
    begin
      NegOne := TInteger.Create(-1);
      Tmp := Term.Multiply(NegOne);
      NegOne.Free;
      Term.Free;
      Term := Tmp;
    end;

    if Sum = nil then
      Sum := Term
    else
    begin
      Tmp := Sum.Add(Term);
      Sum.Free;
      Term.Free;
      Sum := Tmp;
    end;

    Sign := -Sign;
  end;
  Result := Sum;
end;

procedure TMatrix2D.FillWith(const Scalar: TNumeric);
var
  R, C: Integer;
begin
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Elements[R, C] := Scalar.Clone;
end;

procedure TMatrix2D.MakeIdentity;
var
  R, C: Integer;
  Seed: TNumeric;
begin
  if FRows <> FCols then
    raise EMatrixError.CreateFmt(
      'TMatrix2D.MakeIdentity: matrix must be square (%dx%d)', [FRows, FCols]);
  { Use an existing element as a type seed }
  Seed := FData[0, 0];
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      if R = C then
        Elements[R, C] := Seed.One
      else
        Elements[R, C] := Seed.Zero;
end;


class function TMatrix2D.CreateFromStringEx(const S: string;
  AElementParser: TElementParseFunc): TMatrix2D;
var
  Body: string;
  Len: Integer;
  P: Integer;

  { Skip over whitespace starting at position P }
  procedure SkipWhitespace;
  begin
    while (P <= Len) and ((Body[P] = ' ') or (Body[P] = #9) or
                          (Body[P] = #10) or (Body[P] = #13)) do
      Inc(P);
  end;

  { Expect and consume a specific character; raise if not found }
  procedure Expect(Ch: Char);
  begin
    SkipWhitespace;
    if (P > Len) or (Body[P] <> Ch) then
      raise EMatrixError.CreateFmt(
        'TMatrix2D.CreateFromString: expected "%s" at position %d',
        [Ch, P]);
    Inc(P);
  end;

  { Parse one row: assumes the leading '[' has already been consumed.
    Reads cells separated by ',' until the closing ']'.
    Fills Cells array; returns the number of cells read. }
  function ParseRow(var Cells: array of TNumeric): Integer;
  var
    Count: Integer;
    StartPos: Integer;
    CellText: string;
    Elem: TNumeric;
  begin
    Count := 0;
    SkipWhitespace;
    { Handle empty row: [] }
    if (P <= Len) and (Body[P] = ']') then
    begin
      Inc(P);
      Result := 0;
      Exit;
    end;
    while True do
    begin
      { Read one cell up to ',' or ']' }
      SkipWhitespace;
      StartPos := P;
      while (P <= Len) and (Body[P] <> ',') and (Body[P] <> ']') do
        Inc(P);
      CellText := Trim(Copy(Body, StartPos, P - StartPos));
      if CellText = '' then
        raise EMatrixError.CreateFmt(
          'TMatrix2D.CreateFromString: empty cell at position %d', [StartPos]);

      if Count > High(Cells) then
        raise EMatrixError.Create(
          'TMatrix2D.CreateFromString: too many cells in row');

      Elem := AElementParser(CellText);
      Cells[Count] := Elem;
      Inc(Count);

      SkipWhitespace;
      if P > Len then
        raise EMatrixError.Create(
          'TMatrix2D.CreateFromString: unterminated row');
      if Body[P] = ',' then
      begin
        Inc(P);
        Continue;
      end
      else if Body[P] = ']' then
      begin
        Inc(P);
        Break;
      end
      else
        raise EMatrixError.CreateFmt(
          'TMatrix2D.CreateFromString: expected "," or "]" at position %d', [P]);
    end;
    Result := Count;
  end;

var
  RowData: array of array of TNumeric;    { dynamic array of rows }
  RowCount, ColCount, ExpectedCols: Integer;
  RowBuf: array of TNumeric;
  I, J: Integer;
begin
  if AElementParser = nil then
    raise EMatrixError.Create('TMatrix2D.CreateFromStringEx: parser is nil');

  Body := S;
  Len := Length(Body);
  P := 1;
  
  { Skip leading whitespace and expect '[' }
  Expect('[');

  { Now repeatedly parse rows until the closing ']' }
  RowCount := 0;
  SetLength(RowData, 0);
  ExpectedCols := -1;

  while True do
  begin
    SkipWhitespace;
    if P > Len then
      raise EMatrixError.Create(
        'TMatrix2D.CreateFromString: unterminated matrix (missing "]")');

    if Body[P] = ']' then
    begin
      Inc(P);
      Break; { end of matrix }
    end;

    if Body[P] <> '[' then
      raise EMatrixError.CreateFmt(
        'TMatrix2D.CreateFromString: expected "[" to start a row at position %d',
        [P]);
    Inc(P);   { consume '[' }

    { Read the row into a temporary buffer - we don't know its size yet,
      so use a generous upper bound and shrink later, or read into a
      dynamic array with reallocation. Simpler: read into a big fixed
      array and slice. }
    SetLength(RowBuf, 64);
    ColCount := ParseRow(RowBuf);

    if ExpectedCols < 0 then
      ExpectedCols := ColCount
    else if ColCount <> ExpectedCols then
      raise EMatrixError.CreateFmt(
        'TMatrix2D.CreateFromString: row %d has %d cells, expected %d',
        [RowCount, ColCount, ExpectedCols]);
        
    { Copy RowBuf into Rows[RowCount] }
    SetLength(RowData, RowCount + 1);
    SetLength(RowData[RowCount], ColCount);
    for J := 0 to ColCount - 1 do
      RowData[RowCount][J] := RowBuf[J];
    { Free the rest of RowBuf that wasn't used }
    for J := ColCount to High(RowBuf) do
      RowBuf[J] := nil;
    SetLength(RowBuf, 0);

    Inc(RowCount);
  end;

  if RowCount = 0 then
    raise EMatrixError.Create('TMatrix2D.CreateFromString: no rows found');
  if ExpectedCols <= 0 then
    raise EMatrixError.Create('TMatrix2D.CreateFromString: no columns found');

  { Build the result }
  Result := TMatrix2D.Create(RowCount, ExpectedCols);
  try
    for I := 0 to RowCount - 1 do
      for J := 0 to ExpectedCols - 1 do
      begin
        Result.Elements[I, J] := RowData[I][J];
        RowData[I][J] := nil;
      end;
  except
    { On failure, free any cells we didn't transfer }
    for I := 0 to High(RowData) do
      for J := 0 to High(RowData[I]) do
        FreeAndNil(RowData[I][J]);
    Result.Free;
    raise;
  end;

  { Free anything left over }
  for I := 0 to High(RowData) do
    for J := 0 to High(RowData[I]) do
      FreeAndNil(RowData[I][J]);
  SetLength(RowData, 0);
end;

class function TMatrix2D.CreateFromStringFloat(const S: string): TMatrix2D;
begin
  Result := CreateFromStringEx(S, @ParseFloatElem);
end;

class function TMatrix2D.CreateFromStringComplex(const S: string): TMatrix2D;
begin
  Result := CreateFromStringEx(S, @ParseComplexElem);
end;

class function TMatrix2D.CreateFromStringRational(const S: string): TMatrix2D;
begin
  Result := CreateFromStringEx(S, @ParseRationalElem);
end;

// ============================================================================
// Matrix Norms
// ============================================================================

function TMatrix2D.FrobeniusNorm: TFloat;
var
  R, C: Integer;
  SumSq: Double;
begin
  SumSq := 0.0;
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
    begin
      { We could call FData[R][C].Multiply(FData[R][C].Clone) but that's
        wasteful. Instead, compute |aij|^2 directly from the magnitude. }
      SumSq := SumSq + Sqr(NumericMagnitude(FData[R][C]));
    end;
  Result := TFloat.Create(Sqrt(SumSq));
end;

function TMatrix2D.Norm1: TFloat;
var
  R, C: Integer;
  ColSum, MaxSum: Double;
begin
  MaxSum := 0.0;
  for C := 0 to FCols - 1 do
  begin
    ColSum := 0.0;
    for R := 0 to FRows - 1 do
      ColSum := ColSum + NumericMagnitude(FData[R][C]);
    if ColSum > MaxSum then
      MaxSum := ColSum;
  end;
  Result := TFloat.Create(MaxSum);
end;

function TMatrix2D.NormInfinity: TFloat;
var
  R, C: Integer;
  RowSum, MaxSum: Double;
begin
  MaxSum := 0.0;
  for R := 0 to FRows - 1 do
  begin
    RowSum := 0.0;
    for C := 0 to FCols - 1 do
      RowSum := RowSum + NumericMagnitude(FData[R][C]);
    if RowSum > MaxSum then
      MaxSum := RowSum;
  end;
  Result := TFloat.Create(MaxSum);
end;

function TMatrix2D.EuclideanNorm: TFloat;
begin
  { The Euclidean norm of a matrix is its Frobenius norm. }
  Result := FrobeniusNorm;
end;

function TMatrix2D.SpectralNorm(const ATol: Double;
  const AMaxIter: Integer): TFloat;
var
  V, W, U, VNew: array of TNumeric;
  I, J, Iter: Integer;
  Sigma, Norm, Delta: Double;
  Tmp, Prod, Sum: TNumeric;
  Converged: Boolean;

  function VecNorm(const Vec: array of TNumeric): Double;
  var
    K: Integer;
    Acc: Double;
  begin
    Acc := 0.0;
    for K := 0 to High(Vec) do
      Acc := Acc + Sqr(NumericMagnitude(Vec[K]));
    Result := Sqrt(Acc);
  end;

begin
  if (FRows = 0) or (FCols = 0) then
  begin
    Result := TFloat.Create(0.0);
    Exit;
  end;

  { Initialise V from the matrix's own element type: [1, 0, ..., 0]. }
  SetLength(V, FCols);
  for I := 0 to FCols - 1 do
    V[I] := FData[0, 0].Zero;
  V[0].Free;
  V[0] := FData[0, 0].One;

  { Normalise V }
  Norm := VecNorm(V);
  if Norm = 0.0 then
  begin
    for I := 0 to FCols - 1 do
      V[I].Free;
    SetLength(V, 0);
    Result := TFloat.Create(0.0);
    Exit;
  end;
  for I := 0 to FCols - 1 do
  begin
    Tmp := DivideByDouble(V[I], Norm);
    V[I].Free;
    V[I] := Tmp;
  end;

  Sigma := 0.0;
  Converged := False;

  for Iter := 1 to AMaxIter do
  begin
    { W := A * V }
    SetLength(W, FRows);
    for I := 0 to FRows - 1 do
    begin
      Sum := nil;
      for J := 0 to FCols - 1 do
      begin
        Prod := FData[I][J].Multiply(V[J]);
        if Sum = nil then
          Sum := Prod
        else
        begin
          Tmp := Sum.Add(Prod);
          Sum.Free;
          Prod.Free;
          Sum := Tmp;
        end;
      end;
      if Sum = nil then
        Sum := FData[0, 0].Zero;
      W[I] := Sum;
    end;

    { U := A^H * W }
    SetLength(U, FCols);
    for J := 0 to FCols - 1 do
    begin
      Sum := nil;
      for I := 0 to FRows - 1 do
      begin
        if FData[I][J] is TComplex then
        begin
          { conj(A[I][J]) * W[I] }
          Tmp := TComplex(FData[I][J]).Conjugate;
          Prod := Tmp.Multiply(W[I]);
          Tmp.Free;
        end
        else
          Prod := FData[I][J].Multiply(W[I]);
        if Sum = nil then
          Sum := Prod
        else
        begin
          Tmp := Sum.Add(Prod);
          Sum.Free;
          Prod.Free;
          Sum := Tmp;
        end;
      end;
      if Sum = nil then
        Sum := FData[0, 0].Zero;
      U[J] := Sum;
    end;

    { Free W }
    for I := 0 to High(W) do
      W[I].Free;
    SetLength(W, 0);

    Sigma := VecNorm(U);

    if Sigma = 0.0 then
    begin
      for J := 0 to High(U) do
        U[J].Free;
      SetLength(U, 0);
      for I := 0 to High(V) do
        V[I].Free;
      SetLength(V, 0);
      Result := TFloat.Create(0.0);
      Exit;
    end;

    { VNew := U / sigma }
    SetLength(VNew, FCols);
    for J := 0 to FCols - 1 do
    begin
      VNew[J] := DivideByDouble(U[J], Sigma);
      U[J].Free;
    end;
    SetLength(U, 0);

    { Delta := ||VNew - V|| }
    Delta := 0.0;
    for J := 0 to FCols - 1 do
    begin
      Tmp := VNew[J].Subtract(V[J]);
      Delta := Delta + Sqr(NumericMagnitude(Tmp));
      Tmp.Free;
    end;
    Delta := Sqrt(Delta);

    { V := VNew }
    for J := 0 to FCols - 1 do
      V[J].Free;
    SetLength(V, 0);
    V := VNew;
    SetLength(VNew, 0);

    if Delta < ATol then
    begin
      Converged := True;
      Break;
    end;
  end;

  for I := 0 to High(V) do
    V[I].Free;
  SetLength(V, 0);

  Result := TFloat.Create(Sqrt(Sigma));
end;


// ============================================================================
//  Operator overloads
// ============================================================================

operator + (A, B: TMatrix2D): TMatrix2D;
begin
  Result := TMatrix2D(A.Add(B));
end;

operator - (A, B: TMatrix2D): TMatrix2D;
begin
  Result := TMatrix2D(A.Subtract(B));
end;

operator * (A, B: TMatrix2D): TMatrix2D;
begin
  Result := TMatrix2D(A.Multiply(B));
end;

operator - (A: TMatrix2D): TMatrix2D;
begin
  Result := TMatrix2D(A.Negate);
end;

// --- Matrix * scalar ---

operator * (A: TMatrix2D; S: TInteger): TMatrix2D;
begin
  Result := A.MultiplyByScalar(S);
end;

operator * (A: TMatrix2D; S: TFloat): TMatrix2D;
begin
  Result := A.MultiplyByScalar(S);
end;

operator * (A: TMatrix2D; S: TComplex): TMatrix2D;
begin
  Result := A.MultiplyByScalar(S);
end;

operator * (S: TInteger; A: TMatrix2D): TMatrix2D;
begin
  Result := A.MultiplyByScalar(S);
end;

operator * (S: TFloat; A: TMatrix2D): TMatrix2D;
begin
  Result := A.MultiplyByScalar(S);
end;

operator * (S: TComplex; A: TMatrix2D): TMatrix2D;
begin
  Result := A.MultiplyByScalar(S);
end;

// --- Matrix / scalar ---

operator / (A: TMatrix2D; S: TInteger): TMatrix2D;
begin
  Result := A.DivideByScalar(S);
end;

operator / (A: TMatrix2D; S: TFloat): TMatrix2D;
begin
  Result := A.DivideByScalar(S);
end;

operator / (A: TMatrix2D; S: TComplex): TMatrix2D;
begin
  Result := A.DivideByScalar(S);
end;



operator - (A: TMatrix2D; S: TInteger): TMatrix2D;
begin Result := A.SubtractScalar(S); end;

operator - (A: TMatrix2D; S: TFloat): TMatrix2D;
begin Result := A.SubtractScalar(S); end;

operator - (A: TMatrix2D; S: TComplex): TMatrix2D;
begin Result := A.SubtractScalar(S); end;




operator + (A: TMatrix2D; S: TInteger): TMatrix2D;
begin Result := A.AddScalar(S); end;

operator + (A: TMatrix2D; S: TFloat): TMatrix2D;
begin Result := A.AddScalar(S); end;

operator + (A: TMatrix2D; S: TComplex): TMatrix2D;
begin Result := A.AddScalar(S); end;

end.
