unit TELQuantum;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math,
  TELNumeric, TELFloat, TELInteger, TELComplex, TELRational,
  TELMatrix2D;

type
  EQuantumError = class(EMatrixError);

  { Quantum-computing toolkit built on TMatrix2D.

    Conventions:
      * All indices are 0-based.
      * A "ket" |p> is a column vector (Dim x 1).
      * A "bra" <p| is a row vector    (1 x Dim).
      * A "bracket" |a><b| is a Dim x Dim matrix with a 1 at (a, b).
      * Element type is TFloat unless a complex variant is requested. }
  TQuantum = class
  public
    { ------------------------------------------------------------------
      Dirac notation - real (TFloat) amplitudes
      ------------------------------------------------------------------ }

    { <p| : 1 x ADim row vector with 1 at column APosition. }
    class function Bra(const APosition, ADim: Integer): TMatrix2D; static;

    { |p> : ADim x 1 column vector with 1 at row APosition. }
    class function Ket(const APosition, ADim: Integer): TMatrix2D; static;

    { |a><b| : ADim x ADim matrix with 1 at (ARow, ACol). }
    class function Bracket(const ARow, ACol, ADim: Integer): TMatrix2D; static;

    { ------------------------------------------------------------------
      Dirac notation - complex amplitudes
      ------------------------------------------------------------------ }

    class function BraC(const APosition, ADim: Integer;
      const AAmplitude: TComplex): TMatrix2D; static;

    class function KetC(const APosition, ADim: Integer;
      const AAmplitude: TComplex): TMatrix2D; static;

    class function BracketC(const ARow, ACol, ADim: Integer;
      const AAmplitude: TComplex): TMatrix2D; static;

    { ------------------------------------------------------------------
      Dirac notation - arbitrary element types (seeded)
      ------------------------------------------------------------------ }

    class function BraLike(const APosition, ADim: Integer;
      const ATypeSeed: TNumeric): TMatrix2D; static;

    class function KetLike(const APosition, ADim: Integer;
      const ATypeSeed: TNumeric): TMatrix2D; static;

    class function BracketLike(const ARow, ACol, ADim: Integer;
      const ATypeSeed: TNumeric): TMatrix2D; static;

    { ------------------------------------------------------------------
      Standard single-qubit gates (2x2, real TFloat matrices).
      All return a fresh TMatrix2D; caller owns it.
      ------------------------------------------------------------------ }

    { Identity: I = [[1,0],[0,1]] }
    class function GateI: TMatrix2D; static;

    { Pauli-X (NOT): X = [[0,1],[1,0]] }
    class function GateX: TMatrix2D; static;

    { Pauli-Y - complex variant because Y has an i. Returns 2x2 complex. }
    class function GateY: TMatrix2D; static;

    { Pauli-Z: Z = [[1,0],[0,-1]] }
    class function GateZ: TMatrix2D; static;

    { Hadamard: H = 1/sqrt(2) * [[1,1],[1,-1]] }
    class function GateH: TMatrix2D; static;

        { ------------------------------------------------------------------
      Single-qubit gates (continued)
      ------------------------------------------------------------------ }

    { Phase gate S = [[1,0],[0,i]] - a 90-degree phase. Complex 2x2. }
    class function GateS: TMatrix2D; static;

    { T gate = [[1,0],[0,exp(i*pi/4)]]. Complex 2x2. }
    class function GateT: TMatrix2D; static;

    { General phase gate: diag(1, exp(i*theta)). Complex 2x2. }
    class function GatePhase(const ATheta: Double): TMatrix2D; static;

    { ------------------------------------------------------------------
          Rotation gates (single-qubit, complex 2x2)
      ------------------------------------------------------------------ }

    { RX(theta) = cos(theta/2) I - i sin(theta/2) X
                = [[ cos(t/2), -i sin(t/2) ],
                   [ -i sin(t/2), cos(t/2) ]] }
     class function GateRX(const ATheta: Double): TMatrix2D; static;

     { RY(theta) = cos(theta/2) I - i sin(theta/2) Y
                 = [[ cos(t/2), -sin(t/2) ],
                    [ sin(t/2),  cos(t/2) ]] }
     class function GateRY(const ATheta: Double): TMatrix2D; static;

     { RZ(theta) = cos(theta/2) I - i sin(theta/2) Z
                 = [[ exp(-i t/2), 0          ],
                    [ 0,           exp(i t/2) ]] }
     class function GateRZ(const ATheta: Double): TMatrix2D; static;

     { ------------------------------------------------------------------
       Controlled gates
       ------------------------------------------------------------------ }

     { General controlled-U gate on an n-qubit register.

       AG must be a 2x2 single-qubit unitary. The result is a 2^n x 2^n
       matrix that:

         - applies AG to the target qubit when the control qubit is |1>
         - leaves the target qubit unchanged when the control is |0>

       Control and target must be distinct and both in [0, n-1]. Qubits
       are ordered left-to-right (qubit 0 is the most significant). }
     class function ControlledGate(const AG: TMatrix2D;
       const AN, AControl, ATarget: Integer): TMatrix2D; static;


    { ------------------------------------------------------------------
      Two-qubit gates (4x4 matrices)
      ------------------------------------------------------------------ }

    { CNOT (controlled-X): identity on the top qubit; X on the
        bottom when the top is 1.
        Basis order: |00>, |01>, |10>, |11>
        CNOT = [[1,0,0,0],
                [0,1,0,0],
                [0,0,0,1],
                [0,0,1,0]] }
    class function GateCNOT: TMatrix2D; static;

    { Controlled-Z: identity except a -1 on |11>.
        CZ = [[1,0,0,0],
              [0,1,0,0],
              [0,0,1,0],
              [0,0,0,-1]] }
    class function GateCZ: TMatrix2D; static;

    { SWAP: exchanges the two qubits.
        SWAP = [[1,0,0,0],
                [0,0,1,0],
                [0,1,0,0],
                [0,0,0,1]] }
    class function GateSWAP: TMatrix2D; static;

{ ------------------------------------------------------------------
    Other Gates
  ------------------------------------------------------------------ }
{ ------------------------------------------------------------------
  Multi-qubit measurement
  ------------------------------------------------------------------ }

{ Measure every qubit of |psi> (2^n x 1 column vector) in the
  computational basis, in a single shot. Returns the resulting bit
  string (most significant bit first) and collapses APsi in place to
  the corresponding basis state. }
class function MeasureAll(const APsi: TMatrix2D): string; static;


{ ------------------------------------------------------------------
  Density matrices
  ------------------------------------------------------------------ }

 { Return the density matrix |psi><psi| of a state |psi> as an
  n x n matrix. Works for real and complex states. Caller owns
  the returned matrix. }
class function DensityMatrix(const APsi: TMatrix2D): TMatrix2D; static;


    { ------------------------------------------------------------------
      Tensor power and embedding
      ------------------------------------------------------------------ }

    { G ⊗ G ⊗ ... ⊗ G (n times). G must be square.
        Result has dimension (G.Rows^n) x (G.Cols^n). }
    class function TensorPower(const AG: TMatrix2D; const AN: Integer): TMatrix2D; static;

    { Embed a single-qubit gate AG into an n-qubit register, acting on
      qubit k (0-based, with qubit 0 being the leftmost/most-significant
      in the tensor product order).

      The result is a 2^n x 2^n matrix. Specifically:

        ApplyToQubit(G, n, k) = I_{2^k} ⊗ G ⊗ I_{2^(n-k-1)}

      when the natural left-to-right tensor order is used, with qubit 0
      on the left. }
    class function ApplyToQubit(const AG: TMatrix2D;
      const AN, AK: Integer): TMatrix2D; static;

    { ------------------------------------------------------------------
      Measurement
      ------------------------------------------------------------------ }

    { Measure a state vector |psi> (must be a column vector of dimension
      Dim) in the computational basis.

      Returns the index m in [0..Dim-1] with probability |psi[m]|^2,
      chosen according to a pseudo-random draw, AND overwrites APsi in
      place with the collapsed state |m>.

      If you want the probability without collapsing, use
      MeasurementProbability below. }
    class function Measure(const APsi: TMatrix2D): Integer; static;

    { Probability of measuring outcome ABasisIndex from state APsi. }
    class function MeasurementProbability(const APsi: TMatrix2D;
      const ABasisIndex: Integer): Double; static;

    { Collapse APsi in place to |ABasisIndex>. }
    class procedure CollapseTo(const APsi: TMatrix2D;
      const ABasisIndex: Integer); static;

    { ------------------------------------------------------------------
      Verification helpers
      ------------------------------------------------------------------ }

    { Return the norm of a state vector |psi> : sqrt( <psi|psi> ). }
    class function StateNorm(const APsi: TMatrix2D): Double; static;

    { Return True if |psi> is normalised (norm ~ 1). }
    class function IsNormalized(const APsi: TMatrix2D;
      const AEpsilon: Double = 1e-9): Boolean; static;

    { ------------------------------------------------------------------
      Outer product |a><b| of two column vectors (both n x 1).
      Returns an n x n TMatrix2D; caller owns it.
      ------------------------------------------------------------------ }
    class function OuterProduct(const AKetA, AKetB: TMatrix2D): TMatrix2D; static;

    { Inner product <a|b> of two column vectors, returned as a fresh
      TNumeric (typically TFloat or TComplex). Caller owns it.
      Both arguments must have the same number of rows. }
    class function InnerProduct(const AKetA, AKetB: TMatrix2D): TNumeric; static;

    { ------------------------------------------------------------------
      Tensor (Kronecker) product A ⊗ B of two matrices.
      If A is m x n and B is p x q, the result is (m*p) x (n*q).
      Useful for composing multi-qubit systems.
      ------------------------------------------------------------------ }
    class function TensorProduct(const AA, AB: TMatrix2D): TMatrix2D; static;
  end;

// =========================================================================
     implementation
// =========================================================================

{ ------------------------------------------------------------------
  Helpers
  ------------------------------------------------------------------ }

procedure CheckPosition(const APosition, ADim: Integer;
  const ARole: string);
begin
  if ADim <= 0 then
    raise EQuantumError.CreateFmt(
      'TQuantum.%s: dimension must be positive, got %d', [ARole, ADim]);
  if (APosition < 0) or (APosition >= ADim) then
    raise EQuantumError.CreateFmt(
      'TQuantum.%s: position %d out of range [0..%d]',
      [ARole, APosition, ADim - 1]);
end;

{ ------------------------------------------------------------------
  Real Dirac constructors
  ------------------------------------------------------------------ }

class function TQuantum.Bra(const APosition, ADim: Integer): TMatrix2D;
begin
  CheckPosition(APosition, ADim, 'Bra');
  Result := TMatrix2D.Create(1, ADim);
  Result.Elements[0, APosition] := TFloat.Create(1.0);
end;

class function TQuantum.Ket(const APosition, ADim: Integer): TMatrix2D;
begin
  CheckPosition(APosition, ADim, 'Ket');
  Result := TMatrix2D.Create(ADim, 1);
  Result.Elements[APosition, 0] := TFloat.Create(1.0);
end;

class function TQuantum.Bracket(const ARow, ACol, ADim: Integer): TMatrix2D;
begin
  CheckPosition(ARow, ADim, 'Bracket (row)');
  CheckPosition(ACol, ADim, 'Bracket (col)');
  Result := TMatrix2D.Create(ADim, ADim);
  Result.Elements[ARow, ACol] := TFloat.Create(1.0);
end;

{ ------------------------------------------------------------------
  Complex Dirac constructors
  ------------------------------------------------------------------ }

class function TQuantum.BraC(const APosition, ADim: Integer;
  const AAmplitude: TComplex): TMatrix2D;
begin
  CheckPosition(APosition, ADim, 'BraC');
  Result := TMatrix2D.Create(1, ADim);
  Result.Elements[0, APosition] := AAmplitude.Clone;
end;

class function TQuantum.KetC(const APosition, ADim: Integer;
  const AAmplitude: TComplex): TMatrix2D;
begin
  CheckPosition(APosition, ADim, 'KetC');
  Result := TMatrix2D.Create(ADim, 1);
  Result.Elements[APosition, 0] := AAmplitude.Clone;
end;

class function TQuantum.BracketC(const ARow, ACol, ADim: Integer;
  const AAmplitude: TComplex): TMatrix2D;
begin
  CheckPosition(ARow, ADim, 'BracketC (row)');
  CheckPosition(ACol, ADim, 'BracketC (col)');
  Result := TMatrix2D.Create(ADim, ADim);
  Result.Elements[ARow, ACol] := AAmplitude.Clone;
end;

{ ------------------------------------------------------------------
  Seeded Dirac constructors
  ------------------------------------------------------------------ }

class function TQuantum.BraLike(const APosition, ADim: Integer;
  const ATypeSeed: TNumeric): TMatrix2D;
var
  C: Integer;
begin
  CheckPosition(APosition, ADim, 'BraLike');
  if ATypeSeed = nil then
    raise EQuantumError.Create('TQuantum.BraLike: type seed is nil');
  Result := TMatrix2D.Create(1, ADim);
  for C := 0 to ADim - 1 do
    Result.Elements[0, C] := ATypeSeed.Zero;
  Result.Elements[0, APosition] := ATypeSeed.One;
end;

class function TQuantum.KetLike(const APosition, ADim: Integer;
  const ATypeSeed: TNumeric): TMatrix2D;
var
  R: Integer;
begin
  CheckPosition(APosition, ADim, 'KetLike');
  if ATypeSeed = nil then
    raise EQuantumError.Create('TQuantum.KetLike: type seed is nil');
  Result := TMatrix2D.Create(ADim, 1);
  for R := 0 to ADim - 1 do
    Result.Elements[R, 0] := ATypeSeed.Zero;
  Result.Elements[APosition, 0] := ATypeSeed.One;
end;

class function TQuantum.BracketLike(const ARow, ACol, ADim: Integer;
  const ATypeSeed: TNumeric): TMatrix2D;
var
  R, C: Integer;
begin
  CheckPosition(ARow, ADim, 'BracketLike (row)');
  CheckPosition(ACol, ADim, 'BracketLike (col)');
  if ATypeSeed = nil then
    raise EQuantumError.Create('TQuantum.BracketLike: type seed is nil');
  Result := TMatrix2D.Create(ADim, ADim);
  for R := 0 to ADim - 1 do
    for C := 0 to ADim - 1 do
      Result.Elements[R, C] := ATypeSeed.Zero;
  Result.Elements[ARow, ACol] := ATypeSeed.One;
end;

{ ------------------------------------------------------------------
  Standard single-qubit gates
  ------------------------------------------------------------------ }

class function TQuantum.GateI: TMatrix2D;
begin
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TFloat.Create(1.0);
  Result.Elements[1, 1] := TFloat.Create(1.0);
end;

class function TQuantum.GateX: TMatrix2D;
begin
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 1] := TFloat.Create(1.0);
  Result.Elements[1, 0] := TFloat.Create(1.0);
end;

class function TQuantum.GateY: TMatrix2D;
begin
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TComplex.Create(0, 0);
  Result.Elements[0, 1] := TComplex.Create(0, -1);   { -i }
  Result.Elements[1, 0] := TComplex.Create(0, 1);    { +i }
  Result.Elements[1, 1] := TComplex.Create(0, 0);
end;

class function TQuantum.GateZ: TMatrix2D;
begin
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TFloat.Create(1.0);
  Result.Elements[1, 1] := TFloat.Create(-1.0);
end;

class function TQuantum.GateH: TMatrix2D;
var
  S: Double;
begin
  S := 1.0 / Sqrt(2.0);
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TFloat.Create(S);
  Result.Elements[0, 1] := TFloat.Create(S);
  Result.Elements[1, 0] := TFloat.Create(S);
  Result.Elements[1, 1] := TFloat.Create(-S);
end;

{ ------------------------------------------------------------------
  Single-qubit gates (continued)
  ------------------------------------------------------------------ }

class function TQuantum.GateS: TMatrix2D;
begin
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TComplex.Create(1, 0);
  Result.Elements[1, 1] := TComplex.Create(0, 1);   { i }
end;

class function TQuantum.GateT: TMatrix2D;
var
  Theta: Double;
begin
  Theta := Pi / 4.0;                                { exp(i*pi/4) }
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TComplex.Create(1, 0);
  Result.Elements[1, 1] := TComplex.Create(Cos(Theta), Sin(Theta));
end;

class function TQuantum.GatePhase(const ATheta: Double): TMatrix2D;
begin
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TComplex.Create(1, 0);
  Result.Elements[1, 1] := TComplex.Create(Cos(ATheta), Sin(ATheta));
end;

class function TQuantum.GateRX(const ATheta: Double): TMatrix2D;
var
  C, S: Double;
begin
  C := Cos(ATheta / 2.0);
  S := Sin(ATheta / 2.0);
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TComplex.Create(C, 0);
  Result.Elements[0, 1] := TComplex.Create(0, -S);
  Result.Elements[1, 0] := TComplex.Create(0, -S);
  Result.Elements[1, 1] := TComplex.Create(C, 0);
end;

class function TQuantum.GateRY(const ATheta: Double): TMatrix2D;
var
  C, S: Double;
begin
  C := Cos(ATheta / 2.0);
  S := Sin(ATheta / 2.0);
  Result := TMatrix2D.Create(2, 2);
  { RY has real entries but we use TComplex for uniformity with the other
    rotation gates so that compositions stay complex throughout. }
  Result.Elements[0, 0] := TComplex.Create(C, 0);
  Result.Elements[0, 1] := TComplex.Create(-S, 0);
  Result.Elements[1, 0] := TComplex.Create(S, 0);
  Result.Elements[1, 1] := TComplex.Create(C, 0);
end;

class function TQuantum.GateRZ(const ATheta: Double): TMatrix2D;
begin
  Result := TMatrix2D.Create(2, 2);
  Result.Elements[0, 0] := TComplex.Create(Cos(-ATheta / 2.0),
                                           Sin(-ATheta / 2.0));
  Result.Elements[1, 1] := TComplex.Create(Cos(ATheta / 2.0),
                                           Sin(ATheta / 2.0));
end;

{ ------------------------------------------------------------------
  General Controlled Gate
  ------------------------------------------------------------------ }
  class function TQuantum.ControlledGate(const AG: TMatrix2D;
    const AN, AControl, ATarget: Integer): TMatrix2D;
  var
    Dim, J, K, OutputRow: Integer;
    JNoTargetBit, JWithTargetBitZero: Integer;
    ControlBitIsOne: Boolean;
    RowBit, ColBit: Integer;
    UCoeff: TNumeric;
    CellTypeSeed: TNumeric;

    { Compute the value of bit K of the integer V, where K ranges 0..AN-1
      with qubit 0 being the most significant bit. }
    function GetBit(const V, K: Integer): Integer;
    var
      Shift: Integer;
    begin
      Shift := AN - 1 - K;
      Result := (V shr Shift) and 1;
    end;

    { Return W with bit K set to the given value. }
    function SetBit(const V, K, Value: Integer): Integer;
    var
      Shift, Mask: Integer;
    begin
      Shift := AN - 1 - K;
      Mask := 1 shl Shift;
      if Value = 1 then
        Result := V or Mask
      else
        Result := V and (not Mask);
    end;

  begin
    if AG = nil then
      raise EQuantumError.Create('TQuantum.ControlledGate: gate is nil');
    if (AG.Rows <> 2) or (AG.Cols <> 2) then
      raise EQuantumError.CreateFmt(
        'TQuantum.ControlledGate: gate must be 2x2, got %dx%d',
        [AG.Rows, AG.Cols]);
    if AN <= 0 then
      raise EQuantumError.CreateFmt(
        'TQuantum.ControlledGate: n must be positive, got %d', [AN]);
    if (AControl < 0) or (AControl >= AN) then
      raise EQuantumError.CreateFmt(
        'TQuantum.ControlledGate: control %d out of range [0..%d]',
        [AControl, AN - 1]);
    if (ATarget < 0) or (ATarget >= AN) then
      raise EQuantumError.CreateFmt(
        'TQuantum.ControlledGate: target %d out of range [0..%d]',
        [ATarget, AN - 1]);
    if AControl = ATarget then
      raise EQuantumError.Create(
        'TQuantum.ControlledGate: control and target must differ');

    Dim := 1 shl AN;
    Result := TMatrix2D.Create(Dim, Dim);

    { Use a typed seed from the gate to preserve element type. }
    CellTypeSeed := AG.Elements[0, 0];

    { Initialise the whole matrix to zero, in the gate's element type. }
    for J := 0 to Dim - 1 do
      for K := 0 to Dim - 1 do
        Result.Elements[J, K] := CellTypeSeed.Zero;

    { Build the matrix column by column. }
    for J := 0 to Dim - 1 do      { J = input basis state }
    begin
      ControlBitIsOne := GetBit(J, AControl) = 1;

      if not ControlBitIsOne then
      begin
        { Identity on this column: row J gets a 1. }
        Result.Elements[J, J] := CellTypeSeed.One;
      end
      else
      begin
        { Row K is determined by U applied to the target bit.
          Let J0 be J with the target bit set to 0, and J1 be J with the
          target bit set to 1.
          Then column J of the controlled gate has:
            row J0 = U[0, K] where K is the target bit of J
            row J1 = U[1, K] where K is the target bit of J
          More precisely: for a given input J with target bit t_in, we sum
          over t_out in {0,1}: output row = J with target bit set to t_out,
          coefficient = U[t_out, t_in]. }
        JNoTargetBit := SetBit(J, ATarget, 0);   { value with target bit = 0 }
        ColBit := GetBit(J, ATarget);            { input target bit, 0 or 1 }

        for RowBit := 0 to 1 do
        begin
          OutputRow := SetBit(JNoTargetBit, ATarget, RowBit);
          UCoeff := AG.Elements[RowBit, ColBit].Clone;
          Result.Elements[OutputRow, J] := UCoeff;
        end;
      end;
    end;
  end;



{ ------------------------------------------------------------------
  Two-qubit gates
  ------------------------------------------------------------------ }

class function TQuantum.GateCNOT: TMatrix2D;
begin
  Result := TMatrix2D.Create(4, 4);
  Result.Elements[0, 0] := TFloat.Create(1.0);
  Result.Elements[1, 1] := TFloat.Create(1.0);
  Result.Elements[2, 3] := TFloat.Create(1.0);
  Result.Elements[3, 2] := TFloat.Create(1.0);
end;

class function TQuantum.GateCZ: TMatrix2D;
begin
  Result := TMatrix2D.Create(4, 4);
  Result.Elements[0, 0] := TFloat.Create(1.0);
  Result.Elements[1, 1] := TFloat.Create(1.0);
  Result.Elements[2, 2] := TFloat.Create(1.0);
  Result.Elements[3, 3] := TFloat.Create(-1.0);
end;

class function TQuantum.GateSWAP: TMatrix2D;
begin
  Result := TMatrix2D.Create(4, 4);
  Result.Elements[0, 0] := TFloat.Create(1.0);
  Result.Elements[1, 2] := TFloat.Create(1.0);
  Result.Elements[2, 1] := TFloat.Create(1.0);
  Result.Elements[3, 3] := TFloat.Create(1.0);
end;

{ ------------------------------------------------------------------
  Tensor power
  ------------------------------------------------------------------ }

  class function TQuantum.TensorPower(const AG: TMatrix2D;
    const AN: Integer): TMatrix2D;
  var
    I: Integer;
    Prev, Next: TMatrix2D;
  begin
    if AG = nil then
      raise EQuantumError.Create('TQuantum.TensorPower: gate is nil');
    if AN <= 0 then
      raise EQuantumError.CreateFmt(
        'TQuantum.TensorPower: exponent must be positive, got %d', [AN]);

    { Iteratively build G^(⊗n) by tensoring on the right. }
    Prev := AG.Clone as TMatrix2D;
    try
      for I := 2 to AN do
      begin
        Next := TensorProduct(Prev, AG);
        Prev.Free;
        Prev := Next;
      end;
      Result := Prev;
      Prev := nil;   { ownership transferred }
    finally
      Prev.Free;
    end;
  end;

  { ------------------------------------------------------------------
    Apply a single-qubit gate to one qubit of an n-qubit register.
    ------------------------------------------------------------------ }

    class function TQuantum.ApplyToQubit(const AG: TMatrix2D;
      const AN, AK: Integer): TMatrix2D;
    var
      Dim, I, J: Integer;
      Ident2: TMatrix2D;
      LeftPart, RightPart, Mid: TMatrix2D;
    begin
      if AG = nil then
        raise EQuantumError.Create('TQuantum.ApplyToQubit: gate is nil');
      if (AG.Rows <> 2) or (AG.Cols <> 2) then
        raise EQuantumError.CreateFmt(
          'TQuantum.ApplyToQubit: gate must be 2x2, got %dx%d',
          [AG.Rows, AG.Cols]);
      if AN <= 0 then
        raise EQuantumError.CreateFmt(
          'TQuantum.ApplyToQubit: n must be positive, got %d', [AN]);
      if (AK < 0) or (AK >= AN) then
        raise EQuantumError.CreateFmt(
          'TQuantum.ApplyToQubit: qubit index %d out of range [0..%d]',
          [AK, AN - 1]);

      Dim := 1 shl AN;

      { Build a 2x2 identity whose element type matches AG's. }
      Ident2 := TMatrix2D.Create(2, 2);
      for I := 0 to 1 do
        for J := 0 to 1 do
          if I = J then
            Ident2.Elements[I, J] := AG.Elements[0, 0].One
          else
            Ident2.Elements[I, J] := AG.Elements[0, 0].Zero;

      try
        { Left part: I_{2^AK} }
        if AK = 0 then
        begin
          LeftPart := TMatrix2D.Create(1, 1);
          LeftPart.Elements[0, 0] := AG.Elements[0, 0].One;
        end
        else
          LeftPart := TensorPower(Ident2, AK);
        try
          { Right part: I_{2^(AN-AK-1)} }
          if AK = AN - 1 then
          begin
            RightPart := TMatrix2D.Create(1, 1);
            RightPart.Elements[0, 0] := AG.Elements[0, 0].One;
          end
          else
            RightPart := TensorPower(Ident2, AN - AK - 1);
          try
            { Compose: LeftPart ⊗ G ⊗ RightPart }
            Mid := TensorProduct(LeftPart, AG);
            try
              Result := TensorProduct(Mid, RightPart);
            finally
              Mid.Free;
            end;
          finally
            RightPart.Free;
          end;
        finally
          LeftPart.Free;
        end;
      finally
        Ident2.Free;
      end;

      { Sanity check }
      if (Result.Rows <> Dim) or (Result.Cols <> Dim) then
        raise EQuantumError.CreateFmt(
          'TQuantum.ApplyToQubit: internal error - result is %dx%d, expected %dx%d',
          [Result.Rows, Result.Cols, Dim, Dim]);
    end;

 { ------------------------------------------------------------------
     Measurement
   ------------------------------------------------------------------ }

      class function TQuantum.MeasurementProbability(const APsi: TMatrix2D;
        const ABasisIndex: Integer): Double;
      var
        Cell: TNumeric;
        Z: TComplex;
        Re, Im: Double;
      begin
        if APsi = nil then
          raise EQuantumError.Create(
            'TQuantum.MeasurementProbability: state is nil');
        if APsi.Cols <> 1 then
          raise EQuantumError.Create(
            'TQuantum.MeasurementProbability: state must be a column vector');
        if (ABasisIndex < 0) or (ABasisIndex >= APsi.Rows) then
          raise EQuantumError.CreateFmt(
            'TQuantum.MeasurementProbability: index %d out of range [0..%d]',
            [ABasisIndex, APsi.Rows - 1]);

        Cell := APsi.Elements[ABasisIndex, 0];
        if Cell is TComplex then
        begin
          Z := TComplex(Cell);
          Re := Z.RealD;
          Im := Z.ImagD;
          Result := Re * Re + Im * Im;
        end
        else
        begin
          Re := Cell.AsFloat;
          Result := Re * Re;
        end;
      end;

      class procedure TQuantum.CollapseTo(const APsi: TMatrix2D;
        const ABasisIndex: Integer);
      var
        I: Integer;
      begin
        if APsi = nil then
          raise EQuantumError.Create('TQuantum.CollapseTo: state is nil');
        if APsi.Cols <> 1 then
          raise EQuantumError.Create(
            'TQuantum.CollapseTo: state must be a column vector');
        if (ABasisIndex < 0) or (ABasisIndex >= APsi.Rows) then
          raise EQuantumError.CreateFmt(
            'TQuantum.CollapseTo: index %d out of range [0..%d]',
            [ABasisIndex, APsi.Rows - 1]);

        { The target cell becomes 1, every other cell becomes 0, in the same
          element type as the original state. }
        for I := 0 to APsi.Rows - 1 do
          if I = ABasisIndex then
            APsi.Elements[I, 0] := APsi.Elements[I, 0].One
          else
            APsi.Elements[I, 0] := APsi.Elements[I, 0].Zero;
      end;

      class function TQuantum.Measure(const APsi: TMatrix2D): Integer;
      var
        N, I, Chosen: Integer;
        R, CumProb, P: Double;
      begin
        if APsi = nil then
          raise EQuantumError.Create('TQuantum.Measure: state is nil');
        if APsi.Cols <> 1 then
          raise EQuantumError.Create(
            'TQuantum.Measure: state must be a column vector');

        N := APsi.Rows;
        if N = 0 then
          raise EQuantumError.Create('TQuantum.Measure: empty state');

        { Draw a uniform random in [0, 1). }
        R := Random;
        CumProb := 0.0;
        Chosen := N - 1;   { fallback for rounding }
        for I := 0 to N - 1 do
        begin
          P := MeasurementProbability(APsi, I);
          CumProb := CumProb + P;
          if R < CumProb then
          begin
            Chosen := I;
            Break;
          end;
        end;

        CollapseTo(APsi, Chosen);
        Result := Chosen;
      end;

      class function TQuantum.StateNorm(const APsi: TMatrix2D): Double;
      var
        I: Integer;
        P: Double;
      begin
        if APsi = nil then
          raise EQuantumError.Create('TQuantum.StateNorm: state is nil');
        if APsi.Cols <> 1 then
          raise EQuantumError.Create(
            'TQuantum.StateNorm: state must be a column vector');
        P := 0.0;
        for I := 0 to APsi.Rows - 1 do
          P := P + MeasurementProbability(APsi, I);
        Result := Sqrt(P);
      end;

      class function TQuantum.IsNormalized(const APsi: TMatrix2D;
        const AEpsilon: Double): Boolean;
      begin
        Result := Abs(StateNorm(APsi) - 1.0) <= AEpsilon;
      end;

      { ------------------------------------------------------------------
         Multi Qubit Measurement
        ------------------------------------------------------------------ }
        class function TQuantum.MeasureAll(const APsi: TMatrix2D): string;
        var
          N, I, NumQubits, Chosen, Bit: Integer;
          R, CumProb, P: Double;
          SB: string;
        begin
          if APsi = nil then
            raise EQuantumError.Create('TQuantum.MeasureAll: state is nil');
          if APsi.Cols <> 1 then
            raise EQuantumError.Create(
              'TQuantum.MeasureAll: state must be a column vector');

          N := APsi.Rows;
          if N = 0 then
            raise EQuantumError.Create('TQuantum.MeasureAll: empty state');
          if (N and (N - 1)) <> 0 then
            raise EQuantumError.CreateFmt(
              'TQuantum.MeasureAll: state length %d is not a power of two', [N]);

          { Number of qubits = log2(N). }
          NumQubits := 0;
          I := N;
          while I > 1 do
          begin
            Inc(NumQubits);
            I := I shr 1;
          end;

          { Draw and select. }
          R := Random;
          CumProb := 0.0;
          Chosen := N - 1;
          for I := 0 to N - 1 do
          begin
            P := MeasurementProbability(APsi, I);
            CumProb := CumProb + P;
            if R < CumProb then
            begin
              Chosen := I;
              Break;
            end;
          end;

          CollapseTo(APsi, Chosen);

          { Build the bit string, MSB first. }
          SetLength(SB, NumQubits);
          for Bit := 0 to NumQubits - 1 do
            if (Chosen shr (NumQubits - 1 - Bit)) and 1 = 1 then
              SB[Bit + 1] := '1'
            else
              SB[Bit + 1] := '0';
          Result := SB;
        end;

{ --------------------------------------------------------------------------
        Density Matrix
  --------------------------------------------------------------------------}
  class function TQuantum.DensityMatrix(const APsi: TMatrix2D): TMatrix2D;
  var
    N, I, J: Integer;
    BraPsi: TMatrix2D;
    Prod: TNumeric;
  begin
    if APsi = nil then
      raise EQuantumError.Create('TQuantum.DensityMatrix: state is nil');
    if APsi.Cols <> 1 then
      raise EQuantumError.Create(
        'TQuantum.DensityMatrix: state must be a column vector');

    N := APsi.Rows;

    { Build <psi| as the conjugate transpose of |psi>. }
    BraPsi := APsi.ConjugateTranspose;
    try
      { ρ = |ψ><ψ| : N x N matrix }
      Result := TMatrix2D.Create(N, N);
      try
        for I := 0 to N - 1 do
          for J := 0 to N - 1 do
          begin
            Prod := APsi.Elements[I, 0].Multiply(BraPsi.Elements[0, J]);
            Result.Elements[I, J] := Prod;
          end;
      except
        Result.Free;
        raise;
      end;
    finally
      BraPsi.Free;
    end;
  end;
{ ------------------------------------------------------------------
  Outer / inner products
  ------------------------------------------------------------------ }

class function TQuantum.OuterProduct(const AKetA, AKetB: TMatrix2D): TMatrix2D;
var
  N, M, I, J: Integer;
  Prod: TNumeric;
begin
  if (AKetA = nil) or (AKetB = nil) then
    raise EQuantumError.Create('TQuantum.OuterProduct: nil argument');
  if (AKetA.Cols <> 1) or (AKetB.Cols <> 1) then
    raise EQuantumError.Create(
      'TQuantum.OuterProduct: both arguments must be column vectors');
  if AKetA.Rows <> AKetB.Rows then
    raise EQuantumError.CreateFmt(
      'TQuantum.OuterProduct: size mismatch (%d vs %d)',
      [AKetA.Rows, AKetB.Rows]);

  N := AKetA.Rows;
  Result := TMatrix2D.Create(N, N);
  try
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
      begin
        Prod := AKetA.Elements[I, 0].Multiply(AKetB.Elements[J, 0]);
        Result.Elements[I, J] := Prod;
      end;
  except
    Result.Free;
    raise;
  end;
end;

class function TQuantum.InnerProduct(const AKetA, AKetB: TMatrix2D): TNumeric;
var
  N, I: Integer;
  Prod, Acc, Tmp: TNumeric;
begin
  if (AKetA = nil) or (AKetB = nil) then
    raise EQuantumError.Create('TQuantum.InnerProduct: nil argument');
  if (AKetA.Cols <> 1) or (AKetB.Cols <> 1) then
    raise EQuantumError.Create(
      'TQuantum.InnerProduct: both arguments must be column vectors');
  if AKetA.Rows <> AKetB.Rows then
    raise EQuantumError.CreateFmt(
      'TQuantum.InnerProduct: size mismatch (%d vs %d)',
      [AKetA.Rows, AKetB.Rows]);

  N := AKetA.Rows;
  if N = 0 then
    raise EQuantumError.Create('TQuantum.InnerProduct: empty vectors');

  { Seed with the first product to preserve element type. }
  Acc := AKetA.Elements[0, 0].Multiply(AKetB.Elements[0, 0]);
  for I := 1 to N - 1 do
  begin
    Prod := AKetA.Elements[I, 0].Multiply(AKetB.Elements[I, 0]);
    Tmp  := Acc.Add(Prod);
    Prod.Free;
    Acc.Free;
    Acc := Tmp;
  end;
  Result := Acc;
end;

{ ------------------------------------------------------------------
  Tensor product A ⊗ B
  ------------------------------------------------------------------ }

class function TQuantum.TensorProduct(const AA, AB: TMatrix2D): TMatrix2D;
var
  MA, NA, MB, NB: Integer;
  I, J, K, L: Integer;
  Prod: TNumeric;
begin
  if (AA = nil) or (AB = nil) then
    raise EQuantumError.Create('TQuantum.TensorProduct: nil argument');

  MA := AA.Rows; NA := AA.Cols;
  MB := AB.Rows; NB := AB.Cols;

  Result := TMatrix2D.Create(MA * MB, NA * NB);
  try
    for I := 0 to MA - 1 do
      for J := 0 to NA - 1 do
        for K := 0 to MB - 1 do
          for L := 0 to NB - 1 do
          begin
            Prod := AA.Elements[I, J].Multiply(AB.Elements[K, L]);
            Result.Elements[I * MB + K, J * NB + L] := Prod;
          end;
  except
    Result.Free;
    raise;
  end;
end;

end.
