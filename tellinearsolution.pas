unit TELLinearSolution;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  TELNumeric, TELFloat, TELInteger, TELComplex, TELRational,
  TELMatrix2D;

type
  ESolutionError = class(EMatrixError);

  //TIntegerArray = array of Integer;

  TLinearSystemKind = (
    lskInconsistent,   // no solutions
    lskUnique,         // exactly one solution
    lskInfinite        // infinitely many solutions (parametric)
  );

  { TLinearSolution - structured result of solving a linear system.

    Ownership:
      * The constructor takes ownership of nothing; it clones the vectors
        it is given.
      * All public getters that return a TMatrix2D return a FRESH object;
        the caller must free it.
      * The destructor frees everything internally. }
  TLinearSolution = class
  private
    FKind: TLinearSystemKind;
    FNumVariables: Integer;
    FNumEquations: Integer;
    FRankA: Integer;
    FRankAug: Integer;

    { For lskUnique or lskInfinite: the particular solution (n x 1). }
    FParticular: TMatrix2D;

    { For lskInfinite: one homogeneous basis vector per free variable. }
    FBasis: array of TMatrix2D;

    { Indices of the free variables (columns of A without pivots). }
    FFreeVars: array of Integer;

    procedure SetKind(const V: TLinearSystemKind);
  public
    constructor Create(const AKind: TLinearSystemKind;
      const ANumVariables, ANumEquations, ARankA, ARankAug: Integer);
    destructor  Destroy; override;

    { -------- Read-only properties -------- }
    property Kind: TLinearSystemKind read FKind;
    property NumVariables: Integer read FNumVariables;
    property NumEquations: Integer read FNumEquations;
    property RankA: Integer read FRankA;
    property RankAug: Integer read FRankAug;
    property FreeVariableIndices: TIntegerArray read FFreeVars;

    { -------- Boolean status queries -------- }
    function IsInconsistent: Boolean;
    function IsCompatible: Boolean;
    function HasUniqueSolution: Boolean;
    function HasInfiniteSolutions: Boolean;

    { -------- Structured solution access -------- }

    { The unique solution vector. Raises if the system is not uniquely
      solvable. Caller owns the returned matrix (n x 1). }
    function Solution: TMatrix2D;

    { A clone of the particular solution, or nil if the system is
      inconsistent. Caller owns it (n x 1). }
    function ParticularSolution: TMatrix2D;

    { Number of free parameters (dimension of the null space). }
    function BasisCount: Integer;

    { A clone of the i-th homogeneous basis vector (n x 1).
      i ranges 0 .. BasisCount-1. Raises if i is out of range. }
    function BasisVector(const AIndex: Integer): TMatrix2D;

    { General solution at parameter values t[0..BasisCount-1]:
        x = x_p + Σ t[i] * h_i
      Returns a new (n x 1) matrix; caller owns it.
      Raises if the number of parameters is wrong or the system is
      inconsistent. }
    function GeneralSolutionAt(const AValues: array of TNumeric): TMatrix2D;

    { Verify that A * X = b (within a tolerance). Useful for sanity
      checks on computed solutions. A is (m x n), b is (m x 1). }
    function VerifySolution(const AA, Ab, AX: TMatrix2D;
      const AEpsilon: Double = 1e-9): Boolean;

    { -------- Diagnostic text -------- }
    function Describe: string;
    function Formula: string;


    function NumericMagnitude(const N: TNumeric): Double;

    { -------- Internal construction methods (called by TLinearSystem) --------
      These are exposed so TLinearSystem can assemble the result.
      A copy of the given vector is stored; the caller retains ownership. }
    procedure SetParticular(const AVector: TMatrix2D);
    procedure AddBasisVector(const AVector: TMatrix2D);
    procedure SetFreeVariables(const AIndices: array of Integer);
  end;

implementation

constructor TLinearSolution.Create(const AKind: TLinearSystemKind;
  const ANumVariables, ANumEquations, ARankA, ARankAug: Integer);
begin
  inherited Create;
  FKind         := AKind;
  FNumVariables := ANumVariables;
  FNumEquations := ANumEquations;
  FRankA        := ARankA;
  FRankAug      := ARankAug;
  FParticular   := nil;
  SetLength(FBasis, 0);
  SetLength(FFreeVars, 0);
end;

destructor TLinearSolution.Destroy;
var
  I: Integer;
begin
  FParticular.Free;
  for I := 0 to High(FBasis) do
    FBasis[I].Free;
  SetLength(FBasis, 0);
  inherited Destroy;
end;

procedure TLinearSolution.SetKind(const V: TLinearSystemKind);
begin
  FKind := V;
end;

{ -------- Boolean status -------- }

function TLinearSolution.IsInconsistent: Boolean;
begin
  Result := FKind = lskInconsistent;
end;

function TLinearSolution.IsCompatible: Boolean;
begin
  Result := FKind <> lskInconsistent;
end;

function TLinearSolution.HasUniqueSolution: Boolean;
begin
  Result := FKind = lskUnique;
end;

function TLinearSolution.HasInfiniteSolutions: Boolean;
begin
  Result := FKind = lskInfinite;
end;

{ -------- Structured solution access -------- }

function TLinearSolution.Solution: TMatrix2D;
begin
  if FKind <> lskUnique then
    raise ESolutionError.Create(
      'TLinearSolution.Solution: system does not have a unique solution');
  if FParticular = nil then
    raise ESolutionError.Create(
      'TLinearSolution.Solution: internal error - no particular solution');
  Result := FParticular.Clone as TMatrix2D;
end;

function TLinearSolution.ParticularSolution: TMatrix2D;
begin
  if FKind = lskInconsistent then
    raise ESolutionError.Create(
      'TLinearSolution.ParticularSolution: system is inconsistent');
  if FParticular = nil then
    raise ESolutionError.Create(
      'TLinearSolution.ParticularSolution: internal error - no vector');
  Result := FParticular.Clone as TMatrix2D;
end;

function TLinearSolution.BasisCount: Integer;
begin
  Result := Length(FBasis);
end;

function TLinearSolution.BasisVector(const AIndex: Integer): TMatrix2D;
begin
  if (AIndex < 0) or (AIndex > High(FBasis)) then
    raise ESolutionError.CreateFmt(
      'TLinearSolution.BasisVector: index %d out of range [0..%d]',
      [AIndex, High(FBasis)]);
  Result := FBasis[AIndex].Clone as TMatrix2D;
end;

function TLinearSolution.GeneralSolutionAt(
  const AValues: array of TNumeric): TMatrix2D;
var
  I, J, N: Integer;
  Acc, Term, Prod: TNumeric;
begin
  if FKind = lskInconsistent then
    raise ESolutionError.Create(
      'TLinearSolution.GeneralSolutionAt: system is inconsistent');
  if Length(AValues) <> BasisCount then
    raise ESolutionError.CreateFmt(
      'TLinearSolution.GeneralSolutionAt: expected %d parameters, got %d',
      [BasisCount, Length(AValues)]);

  N := FNumVariables;

  { Start with a clone of the particular solution. If it is nil (should
    not happen for compatible systems), build a zero vector of the right
    type from the first basis vector. }
  if FParticular <> nil then
    Result := FParticular.Clone as TMatrix2D
  else
    raise ESolutionError.Create(
      'TLinearSolution.GeneralSolutionAt: no particular solution stored');

  try
    for I := 0 to BasisCount - 1 do
    begin
      if AValues[I].IsZero then Continue;
      for J := 0 to N - 1 do
      begin
        Prod := AValues[I].Multiply(FBasis[I].Elements[J, 0]);
        Term := Result.Elements[J, 0].Add(Prod);
        Prod.Free;
        Result.Elements[J, 0] := Term;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TLinearSolution.VerifySolution(const AA, Ab, AX: TMatrix2D;
  const AEpsilon: Double): Boolean;
var
  Prod, Diff: TMatrix2D;
  I: Integer;
  MaxDiff: Double;
begin
  if (AA = nil) or (Ab = nil) or (AX = nil) then
  begin
    Result := False;
    Exit;
  end;
  if (AA.Cols <> AX.Rows) or (AA.Rows <> Ab.Rows) or (Ab.Cols <> 1) then
  begin
    Result := False;
    Exit;
  end;

  Prod := AA.Multiply(AX) as TMatrix2D;
  try
    Diff := Prod.Subtract(Ab) as TMatrix2D;
    try
      MaxDiff := 0.0;
      for I := 0 to Diff.Rows - 1 do
        if NumericMagnitude(Diff.Elements[I, 0]) > MaxDiff then
          MaxDiff := NumericMagnitude(Diff.Elements[I, 0]);
      Result := MaxDiff <= AEpsilon;
    finally
      Diff.Free;
    end;
  finally
    Prod.Free;
  end;
end;

{ -------- Diagnostic text -------- }

function TLinearSolution.Describe: string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('Linear system result:');
    SL.Add('  Equations: ' + IntToStr(FNumEquations));
    SL.Add('  Variables: ' + IntToStr(FNumVariables));
    SL.Add('  rank(A)      = ' + IntToStr(FRankA));
    SL.Add('  rank([A|b])  = ' + IntToStr(FRankAug));
    case FKind of
      lskInconsistent:
        SL.Add('  Status: INCONSISTENT (no solutions)');
      lskUnique:
        SL.Add('  Status: COMPATIBLE, UNIQUE solution');
      lskInfinite:
        SL.Add(Format('  Status: COMPATIBLE, INFINITE solutions ' +
             '(%d free variable(s))', [BasisCount]));
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TLinearSolution.Formula: string;
var
  SL: TStringList;
  I, J: Integer;
  V: TNumeric;
begin
  SL := TStringList.Create;
  try
    if FKind = lskInconsistent then
    begin
      SL.Add('No solution: system is inconsistent.');
      Result := SL.Text;
      Exit;
    end;

    SL.Add('Particular solution x_p:');
    if FParticular <> nil then
      for J := 0 to FParticular.Rows - 1 do
        SL.Add('  x' + IntToStr(J + 1) + ' = ' +
               FParticular.Elements[J, 0].ToString);
    SL.Add('');

    if BasisCount = 0 then
    begin
      SL.Add('Unique solution (no free variables).');
    end
    else
    begin
      SL.Add(Format('Homogeneous basis (%d vector(s)):', [BasisCount]));
      for I := 0 to BasisCount - 1 do
      begin
        SL.Add('  Direction h' + IntToStr(I + 1) + ':');
        for J := 0 to FBasis[I].Rows - 1 do
          SL.Add('    x' + IntToStr(J + 1) + ' = ' +
                 FBasis[I].Elements[J, 0].ToString);
      end;
      SL.Add('');
      SL.Add('General solution: x = x_p + Σ t_i · h_i');
    end;

    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

{ -------- Internal construction -------- }

procedure TLinearSolution.SetParticular(const AVector: TMatrix2D);
begin
  if AVector = nil then
    raise ESolutionError.Create(
      'TLinearSolution.SetParticular: vector is nil');
  FParticular.Free;
  FParticular := AVector.Clone as TMatrix2D;
end;

procedure TLinearSolution.AddBasisVector(const AVector: TMatrix2D);
begin
  if AVector = nil then
    raise ESolutionError.Create(
      'TLinearSolution.AddBasisVector: vector is nil');
  SetLength(FBasis, Length(FBasis) + 1);
  FBasis[High(FBasis)] := AVector.Clone as TMatrix2D;
end;

procedure TLinearSolution.SetFreeVariables(const AIndices: array of Integer);
var
  I: Integer;
begin
  SetLength(FFreeVars, Length(AIndices));
  for I := 0 to High(AIndices) do
    FFreeVars[I] := AIndices[I];
end;

{ Magnitude of a TNumeric as a non-negative Double. }
function TLinearSolution.NumericMagnitude(const N: TNumeric): Double;
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

end.
