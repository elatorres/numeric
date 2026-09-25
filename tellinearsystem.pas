unit TELLinearSystem;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  TELNumeric, TELFloat, TELInteger, TELComplex, TELRational, TELLinearSolution,
  TELMatrix2D;

type
  ELinearSystemError = class(EMatrixError);

  { How the solution space looks }
  TSolutionKind = (
    skInconsistent,    // no solutions: rank(A) < rank([A|b])
    skUnique,          // exactly one solution
    skInfinite         // infinitely many solutions (parametric)
  );

  TLinearSystem = class
  private
    FA: TMatrix2D;       { m x n coefficient matrix }
    Fb: TMatrix2D;       { m x 1 right-hand side (column vector) }
    FAug: TMatrix2D;     { m x (n+1) augmented matrix [A|b] }
    FComputed: Boolean;
    FKind: TSolutionKind;
    FRankA: Integer;
    FRankAug: Integer;
    FFreeVars: TIntegerArray;

    procedure EnsureComputed;
    function  GetRankA: Integer;
    function  GetRankAug: Integer;
    function  GetKind: TSolutionKind;
    function  GetIsCompatible: Boolean;
    function  GetHasUniqueSolution: Boolean;
    function  GetHasInfiniteSolutions: Boolean;
    function  GetIsInconsistent: Boolean;
    function  GetNumVariables: Integer;
    function  GetNumEquations: Integer;
    function  GetFreeVariableIndices: TIntegerArray;
  public
    { Build a linear system from a coefficient matrix and a column vector.
      FAug is built internally as [ A | b ].
      Both A and b are COPIED (cloned); the caller retains ownership. }
    constructor Create(const AA: TMatrix2D; const Ab: TMatrix2D);
    destructor  Destroy; override;

    { --- Rank / consistency queries --- }
    property RankA: Integer read GetRankA;
    property RankAug: Integer read GetRankAug;
    property Kind: TSolutionKind read GetKind;
    property IsCompatible: Boolean read GetIsCompatible;
    property IsInconsistent: Boolean read GetIsInconsistent;
    property HasUniqueSolution: Boolean read GetHasUniqueSolution;
    property HasInfiniteSolutions: Boolean read GetHasInfiniteSolutions;
    property NumVariables: Integer read GetNumVariables;
    property NumEquations: Integer read GetNumEquations;
    property FreeVariableIndices: TIntegerArray read GetFreeVariableIndices;

    { --- The workhorse: solve, returning a parametric formula as text --- }
    function SolveToString: string;

    { --- The solution vector (only valid when HasUniqueSolution).
           Returns a new TMatrix2D (n x 1); caller owns it.
           Raises ELinearSystemError if the system is not uniquely solvable. }
    function SolveUnique: TMatrix2D;

    { --- The particular solution plus the homogeneous basis, for
           parametric systems. Returns a string formula. }
    function SolutionFormula: string;

    { --- Serialization helpers for the diagnostic text --- }
    function Describe: string;

    function Solve: TLinearSolution;
  end;

implementation

constructor TLinearSystem.Create(const AA: TMatrix2D; const Ab: TMatrix2D);
begin
  inherited Create;
  if AA = nil then
    raise ELinearSystemError.Create('TLinearSystem.Create: A is nil');
  if Ab = nil then
    raise ELinearSystemError.Create('TLinearSystem.Create: b is nil');
  if Ab.Cols <> 1 then
    raise ELinearSystemError.CreateFmt(
      'TLinearSystem.Create: b must be a column vector, got %dx%d',
      [Ab.Rows, Ab.Cols]);
  if AA.Rows <> Ab.Rows then
    raise ELinearSystemError.CreateFmt(
      'TLinearSystem.Create: A has %d rows, b has %d rows',
      [AA.Rows, Ab.Rows]);

  { Clone A and b to preserve ownership discipline }
  FA := AA.Clone as TMatrix2D;
  Fb := Ab.Clone as TMatrix2D;

  { Build the augmented matrix [A | b] as an m x (n+1) matrix. }
  FAug := TMatrix2D.Create(FA.Rows, FA.Cols + 1);
  FAug.CopyBlockFrom(FA, 0, 0);        { see note below - we need this helper }
  FAug.CopyBlockFrom(Fb, 0, FA.Cols);  { copy b into the last column }

  FComputed := False;
end;

destructor TLinearSystem.Destroy;
begin
  FA.Free;
  Fb.Free;
  FAug.Free;
  inherited Destroy;
end;

procedure TLinearSystem.EnsureComputed;
var
  RREFA, RREFAug: TMatrix2D;
  I: Integer;
  NonZero: Boolean;
begin
  if FComputed then Exit;

  { Rank of A }
  FRankA := FA.Rank(False);
  { Rank of [A|b] }
  FRankAug := FAug.Rank(False);

  { Free variable columns of A = columns not in the pivot set }
  FFreeVars := FA.FreeColumns(False);

  { Classify }
  if FRankAug > FRankA then
    FKind := skInconsistent
  else if FRankA = FA.Cols then
    FKind := skUnique
  else
    FKind := skInfinite;

  FComputed := True;
end;

function TLinearSystem.GetRankA: Integer;
begin EnsureComputed; Result := FRankA; end;

function TLinearSystem.GetRankAug: Integer;
begin EnsureComputed; Result := FRankAug; end;

function TLinearSystem.GetKind: TSolutionKind;
begin EnsureComputed; Result := FKind; end;

function TLinearSystem.GetIsCompatible: Boolean;
begin EnsureComputed; Result := FKind <> skInconsistent; end;

function TLinearSystem.GetIsInconsistent: Boolean;
begin EnsureComputed; Result := FKind = skInconsistent; end;

function TLinearSystem.GetHasUniqueSolution: Boolean;
begin EnsureComputed; Result := FKind = skUnique; end;

function TLinearSystem.GetHasInfiniteSolutions: Boolean;
begin EnsureComputed; Result := FKind = skInfinite; end;

function TLinearSystem.GetNumVariables: Integer;
begin Result := FA.Cols; end;

function TLinearSystem.GetNumEquations: Integer;
begin Result := FA.Rows; end;

function TLinearSystem.GetFreeVariableIndices: TIntegerArray;
begin EnsureComputed; Result := FFreeVars; end;

function TLinearSystem.SolveUnique: TMatrix2D;
var
  Sol: TLinearSolution;
begin
  Sol := Solve;
  try
    Result := Sol.Solution;
  finally
    Sol.Free;
  end;
end;

function TLinearSystem.SolutionFormula: string;
var
  Sol: TLinearSolution;
begin
  Sol := Solve;
  try
    Result := Sol.Formula;
  finally
    Sol.Free;
  end;
end;

function TLinearSystem.Describe: string;
var
  Sol: TLinearSolution;
begin
  Sol := Solve;
  try
    Result := Sol.Describe;
  finally
    Sol.Free;
  end;
end;

{function TLinearSystem.Describe: string;
var
  SL: TStringList;
begin
  EnsureComputed;
  SL := TStringList.Create;
  try
    SL.Add('Linear system:');
    SL.Add('  Equations: ' + IntToStr(NumEquations));
    SL.Add('  Variables: ' + IntToStr(NumVariables));
    SL.Add('  rank(A)      = ' + IntToStr(FRankA));
    SL.Add('  rank([A|b])  = ' + IntToStr(FRankAug));
    case FKind of
      skInconsistent:
        SL.Add('  Status: INCONSISTENT (no solutions)');
      skUnique:
        SL.Add('  Status: COMPATIBLE, UNIQUE solution');
      skInfinite:
        SL.Add(Format('  Status: COMPATIBLE, INFINITE solutions ' +
             '(%d free variable(s))',
             [NumVariables - FRankA]));
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TLinearSystem.SolveUnique: TMatrix2D;
var
  R: TMatrix2D;
  I, N: Integer;
begin
  EnsureComputed;
  if FKind <> skUnique then
    raise ELinearSystemError.Create(
      'TLinearSystem.SolveUnique: system does not have a unique solution');

  N := FA.Cols;
  R := FAug.RREF(False);
  try
    Result := TMatrix2D.Create(N, 1);
    for I := 0 to N - 1 do
      Result.Elements[I, 0] := R.Elements[I, N].Clone;
  finally
    R.Free;
  end;
end;

function TLinearSystem.SolutionFormula: string;
var
  R: TMatrix2D;
  SL: TStringList;
  Pivots: TIntegerArray;
  N, M, I, J, PivotIdx, FreeIdx: Integer;
  IsPivot: Boolean;
  PivotCols: array of Integer;   { pivot column of row I, or -1 }
  FreeColsArr: array of Integer;
  Coef: TNumeric;
  Sign: string;
  Term: string;
  First: Boolean;
  PivotRow: Integer;

  function VarName(K: Integer): string;
  begin
    Result := 'x' + IntToStr(K + 1);
  end;

begin
  EnsureComputed;

  if FKind = skInconsistent then
  begin
    Result := 'No solution: the system is inconsistent ' +
              '(rank(A) < rank([A|b])).';
    Exit;
  end;

  N := FA.Cols;

  if FKind = skUnique then
  begin
    Result := 'Unique solution: x = ' + SolveUnique.ToString;
    Exit;
  end;

  { Infinite solutions: build a parametric formula }
  R := FAug.RREF(False);
  try
    M := R.Rows;
    SetLength(PivotCols, N);
    for I := 0 to N - 1 do
      PivotCols[I] := -1;

    PivotRow := 0;
    for J := 0 to N - 1 do
    begin
      if PivotRow >= M then Break;
      if not R.Elements[PivotRow, J].IsZero then
      begin
        PivotCols[J] := PivotRow;
        Inc(PivotRow);
      end;
    end;

    { Build the list of free columns }
    SetLength(FreeColsArr, 0);
    for J := 0 to N - 1 do
      if PivotCols[J] < 0 then
      begin
        SetLength(FreeColsArr, Length(FreeColsArr) + 1);
        FreeColsArr[High(FreeColsArr)] := J;
      end;

    SL := TStringList.Create;
    try
      SL.Add('Infinite solutions - parametric form:');
      SL.Add('');

      { --- Particular solution (set all free vars to 0) --- }
      SL.Add('Particular solution (free variables set to 0):');
      for J := 0 to N - 1 do
      begin
        if PivotCols[J] >= 0 then
          SL.Add('  ' + VarName(J) + ' = ' +
                 R.Elements[PivotCols[J], N].ToString)
        else
          SL.Add('  ' + VarName(J) + ' = 0');
      end;
      SL.Add('');

      { --- Homogeneous basis --- }
      SL.Add('Homogeneous basis (one vector per free variable):');
      for FreeIdx := 0 to High(FreeColsArr) do
      begin
        J := FreeColsArr[FreeIdx];
        SL.Add('  Direction ' + IntToStr(FreeIdx + 1) +
               ' (parameter t' + IntToStr(FreeIdx + 1) +
               ' = ' + VarName(J) + '):');
        for I := 0 to N - 1 do
        begin
          if PivotCols[I] >= 0 then
          begin
            Coef := R.Elements[PivotCols[I], J].Negate;
            SL.Add('    ' + VarName(I) + ' = ' +
                   Coef.ToString + ' * t' + IntToStr(FreeIdx + 1));
            Coef.Free;
          end
          else if I = J then
            SL.Add('    ' + VarName(I) + ' = t' + IntToStr(FreeIdx + 1))
          else
            SL.Add('    ' + VarName(I) + ' = 0');
        end;
        SL.Add('');
      end;

      SL.Add('General solution: x = x_particular + ' +
             'Σ t_i * direction_i');
      Result := SL.Text;
    finally
      SL.Free;
    end;
  finally
    R.Free;
  end;
end; }

function TLinearSystem.SolveToString: string;
begin
  Result := SolutionFormula;
end;

function TLinearSystem.Solve: TLinearSolution;
var
  R: TMatrix2D;
  N, M, I, J, PivotRow, FreeIdx: Integer;
  PivotColsOfRow: array of Integer;   { for row I: its pivot column, or -1 }
  FreeCols: array of Integer;
  Vec: TMatrix2D;
  Coef: TNumeric;
begin
  EnsureComputed;

  N := FA.Cols;
  M := FA.Rows;

  { Map each row of RREF to its pivot column }
  SetLength(PivotColsOfRow, N);
  for I := 0 to N - 1 do
    PivotColsOfRow[I] := -1;

  if FKind = skInconsistent then
  begin
    Result := TLinearSolution.Create(lskInconsistent, N, M, FRankA, FRankAug);
    Exit;
  end;

  R := FAug.RREF(False);
  try
    { Determine pivot columns from the RREF }
    PivotRow := 0;
    for J := 0 to N - 1 do
    begin
      if PivotRow >= M then Break;
      if not R.Elements[PivotRow, J].IsZero then
      begin
        PivotColsOfRow[PivotRow] := J;
        Inc(PivotRow);
      end;
    end;

    { Collect free columns }
    SetLength(FreeCols, 0);
    for J := 0 to N - 1 do
    begin
      { Is column J a pivot column? }
      FreeIdx := -1;
      for I := 0 to M - 1 do
        if PivotColsOfRow[I] = J then
        begin
          FreeIdx := I;
          Break;
        end;
      if FreeIdx < 0 then
      begin
        SetLength(FreeCols, Length(FreeCols) + 1);
        FreeCols[High(FreeCols)] := J;
      end;
    end;

    { Create the result object with the appropriate kind }
    if FRankA = N then
      Result := TLinearSolution.Create(lskUnique, N, M, FRankA, FRankAug)
    else
      Result := TLinearSolution.Create(lskInfinite, N, M, FRankA, FRankAug);

    try
      Result.SetFreeVariables(FreeCols);
      { --- Particular solution: free variables stay at 0 (default), pivot variables take their values from the RREF's last column --- } 
      { --- Particular solution: set every free variable to 0 --- }
      Vec := TMatrix2D.Create(N, 1);
      try
        //for J := 0 to N - 1 do Vec.Elements[J, 0] := TFloat.Create(0.0); { <-- redundant, cells are pre-filled with TFloat(0) }
        { For each pivot row, copy the constant term from the last column }
        for I := 0 to M - 1 do
          if PivotColsOfRow[I] >= 0 then
            Vec.Elements[PivotColsOfRow[I], 0] := R.Elements[I, N].Clone;
        Result.SetParticular(Vec);
      finally
        Vec.Free;
      end;
      
            { --- Homogeneous basis vectors, one per free variable --- }
      for FreeIdx := 0 to High(FreeCols) do
      begin
        J := FreeCols[FreeIdx];
        Vec := TMatrix2D.Create(N, 1);
        try
          { Set the free variable itself to 1, everything else to 0 }
          for I := 0 to N - 1 do
            Vec.Elements[I, 0] := TFloat.Create(0.0);
          { The setter frees the previous cell for us - do NOT free manually. }
          Vec.Elements[J, 0] := TFloat.Create(1.0);

          { For each pivot row, the pivot variable equals -R[I, J] * (t_J) }
          for I := 0 to M - 1 do
            if PivotColsOfRow[I] >= 0 then
            begin
              Coef := R.Elements[I, J].Negate;
              { Again: assignment alone does the cleanup. }
              Vec.Elements[PivotColsOfRow[I], 0] := Coef;
            end;

          Result.AddBasisVector(Vec);
        finally
          Vec.Free;
        end;
      end;
      { // --- Homogeneous basis vectors, one per free variable --- 
      for FreeIdx := 0 to High(FreeCols) do
      begin
        J := FreeCols[FreeIdx];
        Vec := TMatrix2D.Create(N, 1);
        try
          // Set the free variable itself to 1, everything else to 0 
          for I := 0 to N - 1 do
            Vec.Elements[I, 0] := TFloat.Create(0.0);
          Vec.Elements[J, 0].Free;
          Vec.Elements[J, 0] := TFloat.Create(1.0);

          // For each pivot row, the pivot variable equals -R[I, J] * (t_J) 
          for I := 0 to M - 1 do
            if PivotColsOfRow[I] >= 0 then
            begin
              Coef := R.Elements[I, J].Negate;
              Vec.Elements[PivotColsOfRow[I], 0].Free;
              Vec.Elements[PivotColsOfRow[I], 0] := Coef;
            end;

          Result.AddBasisVector(Vec);
        finally
          Vec.Free;
        end;
      end;}
    except
      Result.Free;
      raise;
    end;
  finally
    R.Free;
  end;
end;


end.



















