unit TELMatrix2D;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math,
  TELNumeric, TELFloat, TELInteger, TELComplex;

type
  EMatrixError = class(ENumericError);

  TNumericGrid = array of array of TNumeric;

  TMatrix2D = class(TNumeric)
  private
    FData: TNumericGrid;
    FRows: Integer;
    FCols: Integer;

    procedure AllocateGrid(const ARows, ACols: Integer);
    procedure FreeGrid;
    function  GetElement(const ARow, ACol: Integer): TNumeric;
    procedure SetElement(const ARow, ACol: Integer; AValue: TNumeric);
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

    { Typed convenience wrappers }
    function ScaleByInteger(const Scalar: TInteger): TMatrix2D;
    function ScaleByFloat  (const Scalar: TFloat):   TMatrix2D;
    function ScaleByComplex(const Scalar: TComplex): TMatrix2D;

    { Transpose - new matrix, caller owns }
    function Transpose: TMatrix2D;

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

// ============================================================================
implementation
// ============================================================================

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
begin
  Res := TMatrix2D.Create(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Res.Elements[R, C] := FData[R][C].Multiply(Scalar);
  Result := Res;
end;

function TMatrix2D.DivideByScalar(const Scalar: TNumeric): TMatrix2D;
var
  Res: TMatrix2D;
  R, C: Integer;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Res.Elements[R, C] := FData[R][C].Divide(Scalar);
  Result := Res;
end;

function TMatrix2D.AddScalar(const Scalar: TNumeric): TMatrix2D;
var
  Res: TMatrix2D;
  R, C: Integer;
begin
  Res := TMatrix2D.Create(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Res.Elements[R, C] := FData[R][C].Add(Scalar);
  Result := Res;
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

end.
