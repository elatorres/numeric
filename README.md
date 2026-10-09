# TELNumerics

A numerical computing library for Free Pascal, built around a single polymorphic hierarchy of numeric types. Real, integer, complex, rational, quaternion, matrix, bit-vector, and quantum-state types all share the same virtual interface — so they interoperate through operators, promote cleanly across types, and can be composed into larger structures (vectors, matrices, expressions) without special-casing.

The library is the numeric foundation for a computer-algebra system (CAS) under development.

---

## Design overview

Every numeric type descends from the abstract class `TNumeric`, which defines a small, complete set of operations:

```pascal
function Add     (const Other: TNumeric): TNumeric;  virtual; abstract;
function Subtract(const Other: TNumeric): TNumeric;  virtual; abstract;
function Multiply(const Other: TNumeric): TNumeric;  virtual; abstract;
function Divide  (const Other: TNumeric): TNumeric;  virtual; abstract;
function Negate  :                        TNumeric;  virtual; abstract;
function Clone   :                        TNumeric;  virtual; abstract;
function Inverse :                        TNumeric;  virtual;
function AsFloat :                        Double;     virtual; abstract;
function Zero    :                        TNumeric;  virtual; abstract;
function One     :                        TNumeric;  virtual; abstract;
function IsZero  (const AEpsilon: Double = 1e-12): Boolean; virtual;
function ToString:                        string;     override; abstract;
```

Because every type implements this interface, arithmetic can be expressed through **free operator overloads** that simply dispatch to the virtual method table:

```pascal
operator + (A, B: TNumeric): TNumeric;  begin Result := A.Add(B);      end;
operator - (A, B: TNumeric): TNumeric;  begin Result := A.Subtract(B); end;
operator * (A, B: TNumeric): TNumeric;  begin Result := A.Multiply(B); end;
operator / (A, B: TNumeric): TNumeric;  begin Result := A.Divide(B);   end;
operator - (A: TNumeric): TNumeric;     begin Result := A.Negate;      end;
```

Adding a new numeric type is a self-contained operation: derive from `TNumeric`, implement the operations, and it works with everything else.

### Ownership convention

- **Every arithmetic method returns a newly allocated object. The caller owns it and must free it.**
- Matrices own their elements; assigning to `M.Elements[i,j]` frees the previous element and takes ownership of the new one.
- Serialization helpers (`CreateFromString`) return fresh objects; `ToString` never allocates.

This convention is applied uniformly across the library. It makes composite operations (matrix products, polynomial arithmetic, quantum circuits) straightforward to reason about and free of surprising aliasing.

---

## Types

### `TFloat` — double-precision floating-point (`TELFloat`)

The workhorse real type. Wraps a `Double`.

- Arithmetic: `+ - * /`, unary `-`, inverse, clone
- Mixed operations with `TInteger`, `TRational`, `TComplex`, and `Double`
- `TFloat.CreateFromString(s)` / `ToString` for round-trip serialization

### `TInteger` — 64-bit signed integer (`TELInteger`)

Wraps an `Int64`. Division is truncating (like Pascal's `div`). When the other operand is a `TFloat`, the result of arithmetic is promoted to `TFloat` — preserving the fractional part:

```pascal
I := TInteger.Create(10);
F := TFloat.Create(3.5);
R := I.Add(F);      { returns TFloat(13.5), not TInteger(14) }
```

### `TComplex` — complex numbers (`TELComplex`)

Wraps two `Double`s (`Real`, `Imag`).

- **Properties**: `Real`, `Imag`, `Modulus`, `Angle` (radians). Each is `TFloat`-typed; the caller owns the returned `TFloat`.
- **Direct accessors**: `RealD`, `ImagD` return `Double` without allocation.
- **Polar form**: `CreatePolar(r, θ)`, plus `Modulus` and `Angle` setters.
- **Operations**: `Conjugate`, `Sqrt`, `Exp`, `Ln`, `Power(n)`, `Inverse`
- **Comparison**: `Equals(other, ε)`, `IsReal`, `IsImaginary`, `IsZero(ε)`
- **Full operator overloads**: mixed with `Double`, `Integer`, `TFloat`, `TInteger`, `TRational`

The complex type is a strict superset of the real one — every `TFloat` can be constructed as a `TComplex` with zero imaginary part.

### `TRational` — exact rational numbers (`TELRational`)

Derives from `TInteger`. Stores numerator and denominator in **canonical form**:

- Denominator > 0
- `gcd(|num|, den) = 1`
- Zero is always `0/1`

Every constructor and property setter normalizes automatically.

- **Properties**: `Numerator`, `Denominator` (both `Int64`); typed accessors `NumeratorI`, `DenominatorI` (`TInteger`)
- **Operations**: full rational arithmetic with exact cancellation; `Floor`, `Ceil`, `Round_`, `Abs_`, `Reciprocal`
- **Conversion**: `IsInteger`, `ToInteger` (raises if not exact), `FloatValue`, `AsFloatValue`
- **Interop**: `TRational op TInteger → TRational`; `TRational op TFloat → TFloat`
- `Create(TFloat)` converts a decimal to a rational via continued-fraction-like scaling

### `TQuaternion` — quaternions (`TELQuaternion`)

Wraps four `Double`s (`w + xi + yj + zk`).

- **Construction**: from four doubles, a single double, `TFloat`, or `TComplex` (which embeds as `w + xi`)
- **Properties**: `W`, `X`, `Y`, `Z` (`Double`); `WFloat`, `XFloat`, `YFloat`, `ZFloat` (`TFloat`)
- **Operations**:
  - `Hamilton(q2)` — quaternion multiplication
  - `Conjugate`, `ScalarPart`, `VectorPart`
  - `Norm`, `NormSquared`, `Unity` (unit quaternion)
  - `Exp`, `Ln`, `Power(p)`
  - `Dot`, `GeodesicDistance` (angular distance on the unit 3-sphere)
  - `RotateVector(x, y, z)` — rotate a 3-vector
- **Operators**: full set with `TQuaternion`, `Double`, `TFloat`, `TComplex`

Note: `Unit` is a Pascal keyword, so the normalization method is named `Unity`.

### `TMatrix2D` — 2-dimensional matrices (`TELMatrix2D`)

A matrix of `TNumeric` elements. **Any element type works** — real, complex, rational, integer.

- **Construction**: `Create(rows, cols)`, `Identity(n)`, `IdentityOf(n, seed)`, `Zeros(rows, cols)`
- **Arithmetic**: `Add`, `Subtract`, `Multiply` (matrix product), `Divide` (via inverse), `Negate`
- **Scalar ops**: `MultiplyByScalar`, `DivideByScalar`, `AddScalar`, `SubtractScalar` — with automatic promotion when the scalar is complex but the matrix is real
- **Linear algebra**:
  - `Transpose`, `ConjugateTranspose`, `Adjoint`
  - `Inverse` — generic Gauss-Jordan, works for any `TNumeric` element type
  - `Determinant` — cofactor expansion, works for complex and rational elements
  - `RREF`, `Rank`, `PivotColumns`, `FreeColumns`
  - `FrobeniusNorm`, `Norm1`, `NormInfinity`, `SpectralNorm` (via power iteration)
- **Isometry checks**: `IsHermitian`, `IsSymmetric`
- **Serialization**: `CreateFromStringFloat`, `CreateFromStringComplex`, `CreateFromStringRational` — tolerate arbitrary whitespace, single-line and multi-line formats

Matrix operators cover `+`, `-`, `*`, `/` for matrix–matrix and matrix–scalar products (with `TInteger`, `TFloat`, `TComplex`, `TRational`, native `Integer`, `Int64`, and `Double`).

### `TBits` — 64-bit bit vector (`TELBits`)

Wraps a `UInt64`.

- **Bit operations**: `BitwiseAnd`, `BitwiseOr`, `BitwiseXor`, `BitwiseNot`
- **Shifts**: `ShiftLeft`, `ShiftRight`
- **Bit access**: `SetBit(i, value)`, `GetBit(i)`
- **Numeric interface mapping**: `Add` = OR, `Multiply` = AND, `Divide` = XOR, `Subtract` = AND-NOT, `Negate` = NOT
- `CreateFromString` accepts 1–64 bit strings

### `TBinaryVector` — arbitrary-length bit vector (`TELBinaryVector`)

A dynamic array of `UInt64` words supporting bit vectors of any length.

- **Bit operations**: same set as `TBits`, plus `RotateLeft`, `RotateRight`
- **Bit access**: `SetBit`, `GetBit`, `SetBits`, `GetBits`, `Bits[i]` default property
- **Vector operations**: `HammingWeight`, `HammingDistance`, `Concatenate`
- **Numeric interface mapping**: same as `TBits`
- **Construction**: from a size or a binary string (`'10110010'`)
- `CreateFromString` round-trips the `ToString` format

### `TQuantum` — quantum computing toolkit (`TELQuantum`)

Built on `TMatrix2D`. Constructs and operates on quantum states, gates, and measurements.

- **Dirac notation**: `Bra(p, n)`, `Ket(p, n)`, `Bracket(a, b, n)`, with complex-amplitude variants and seeded variants
- **Single-qubit gates**: `GateI`, `GateX`, `GateY`, `GateZ`, `GateH`, `GateS`, `GateT`, `GatePhase(θ)`, `GateRX(θ)`, `GateRY(θ)`, `GateRZ(θ)`
- **Two-qubit gates**: `GateCNOT`, `GateCZ`, `GateSWAP`
- **Multi-qubit construction**: `TensorPower(G, n)`, `ApplyToQubit(G, n, k)`, `ControlledGate(G, n, control, target)`
- **Composite operators**: `OuterProduct`, `InnerProduct`, `TensorProduct`
- **Measurement**: `Measure(ψ)` (single shot, collapses `ψ`), `MeasureAll(ψ)` (returns a bit string), `MeasurementProbability`, `CollapseTo`
- **Diagnostics**: `StateNorm`, `IsNormalized`, `DensityMatrix(ψ)`

### `TEigen` — eigenvalue solver (`TELEigen`)

- `Eigenvalues(M)` — complex QR algorithm with Wilkinson shift; returns `n × 1` complex eigenvalues
- `EigenvaluesHermitian(M)` — Jacobi algorithm for Hermitian matrices; real eigenvalues wrapped as `TComplex`
- `EigenvectorFor(M, λ)` — nullspace of `A − λI`, normalized
- `EigenvaluesAndVectors(M, Eigs, Vecs)` — full eigen-decomposition

### `TLinearSolution` + `TLinearSystem` — linear solvers (`TELLinearSystem`, `TELLinearSolution`)

- `TLinearSystem.Create(A, b)` — build a system `Ax = b`
- Status queries: `IsCompatible`, `IsInconsistent`, `HasUniqueSolution`, `HasInfiniteSolutions`
- `RankA`, `RankAug`, `NumVariables`, `NumEquations`
- `Solve` — returns a `TLinearSolution` containing:
  - the particular solution (`ParticularSolution`)
  - the homogeneous basis (`BasisVector(i)`)
  - `GeneralSolutionAt(t₁, t₂, …)` — evaluate for specific parameter values
  - `Describe`, `Formula` — human-readable output
  - `VerifySolution(A, b, x)` — sanity check

---

## Installation

Each type lives in its own unit. Add the ones you need to your project's `uses` clause:

```pascal
uses
  TELNumeric, TELFloat, TELInteger, TELComplex, TELRational,
  TELQuaternion, TELMatrix2D, TELBits, TELBinaryVector,
  TELEigen, TELLinearSystem, TELLinearSolution,
  TELQuantum;
```

The compiler directives at the top of each unit are:

```pascal
{$mode objfpc}{$H+}
```

`objfpc` enables OOP extensions; `H+` makes `string` mean `AnsiString` (so `ToString` overrides work without qualification).

---

## Quick examples

### Complex arithmetic with polar form

```pascal
var
  Z, W: TComplex;
  R, Theta: TFloat;
begin
  Z := TComplex.Create(3, 4);
  W := TComplex.CreatePolar(2, Pi / 3);

  R := Z.Modulus;          { 5.0 }
  Theta := Z.Angle;        { atan2(4, 3) ≈ 0.9273 rad }
  WriteLn('z = ', Z.ToString, ', |z| = ', R.ToString,
          ', arg(z) = ', Theta.ToString);

  Z := (Z * W) as TComplex;   { full complex multiplication }
  Z := (Z + TFloat.Create(1)) as TComplex;
  Z := (Z / 2) as TComplex;
  WriteLn('result = ', Z.ToString);

  R.Free; Theta.Free; Z.Free; W.Free;
end;
```

### Exact rational arithmetic

```pascal
var
  R1, R2, R3: TRational;
begin
  R1 := TRational.Create(1, 3);
  R2 := TRational.Create(1, 6);
  R3 := (R1 + R2) as TRational;   { 1/2 exactly }
  WriteLn(R3.ToString);
  R1.Free; R2.Free; R3.Free;
end;
```

### Matrix inversion (any element type)

```pascal
var
  M, Minv, Id: TMatrix2D;
begin
  M := TMatrix2D.Create(3, 3);
  M.Elements[0, 0] := TComplex.Create(1, 1);
  M.Elements[0, 1] := TComplex.Create(0, 2);
  { ... fill the rest ... }

  Minv := M.Inverse as TMatrix2D;
  Id := M * Minv;                 { should be identity }

  M.Free; Minv.Free; Id.Free;
end;
```

### Solving a linear system

```pascal
var
  A, b: TMatrix2D;
  Sys: TLinearSystem;
  Sol: TLinearSolution;
  X: TMatrix2D;
begin
  { ... build A (m x n) and b (m x 1) ... }

  Sys := TLinearSystem.Create(A, b);
  try
    Sol := Sys.Solve;
    try
      WriteLn(Sol.Describe);
      if Sol.HasUniqueSolution then
      begin
        X := Sol.Solution;
        WriteLn('x = '); WriteLn(X.ToString);
        X.Free;
      end
      else if Sol.HasInfiniteSolutions then
        WriteLn(Sol.Formula);
    finally
      Sol.Free;
    end;
  finally
    Sys.Free;
  end;
  A.Free; b.Free;
end;
```

### Building a Bell state

```pascal
var
  Zero, H, H2, CNOT, Result, Bell: TMatrix2D;
  Measured: string;
begin
  Randomize;
  Zero := TQuantum.Ket(0, 4);                       { |00> }
  H    := TQuantum.GateH;
  H2   := TQuantum.ApplyToQubit(H, 2, 0);           { H ⊗ I }
  CNOT := TQuantum.GateCNOT;

  Result := H2 * Zero as TMatrix2D;                 { (|00>+|10>)/√2 }
  Bell   := CNOT * Result as TMatrix2D;             { (|00>+|11>)/√2 }

  WriteLn('Bell state:');
  WriteLn(Bell.ToString);

  Measured := TQuantum.MeasureAll(Bell);
  WriteLn('Measured: |', Measured, '>');

  Zero.Free; H.Free; H2.Free; CNOT.Free;
  Result.Free; Bell.Free;
end;
```

### Eigenvalues of a Hermitian matrix

```pascal
var
  M, Eigs, Vecs: TMatrix2D;
begin
  M := TMatrix2D.Create(3, 3);
  { ... fill with a Hermitian matrix ... }

  TEigen.EigenvaluesAndVectors(M, Eigs, Vecs);
  WriteLn('Eigenvalues:');
  WriteLn(Eigs.ToString);
  WriteLn('Eigenvectors (columns):');
  WriteLn(Vecs.ToString);

  M.Free; Eigs.Free; Vecs.Free;
end;
```

---

## Serialization

Every type supports round-tripping through `ToString` and a corresponding `CreateFromString`:

| Type | Format | Example |
|---|---|---|
| `TFloat` | decimal / scientific | `3.14159` |
| `TInteger` | signed decimal | `-12345` |
| `TComplex` | `re`, `re ± im i`, `±i`, `±im i` | `3 + 4i`, `-2i` |
| `TRational` | `n` or `n/d` (auto-normalized) | `22/7` |
| `TBits` | 1–64 bit string | `11001100` |
| `TBinaryVector` | any-length bit string | `1010101010101010` |
| `TMatrix2D` | `[ [a, b] [c, d] ]` (single or multi-line) | see below |

The matrix format tolerates arbitrary whitespace and both single-line and multi-line layouts:

```
[
 [ 1,  2 ]
 [ 3,  4 ]
]
```

```pascal
M := TMatrix2D.CreateFromStringFloat('[ [1, 2] [3, 4] ]');
```

---

## Mixed-type operations

The library promotes types according to these rules:

| Left | Right | Result |
|---|---|---|
| `TInteger` | `TInteger` | `TInteger` |
| `TInteger` | `TFloat` | `TFloat` |
| `TFloat` | `TComplex` | `TComplex` |
| `TRational` | `TRational` | `TRational` |
| `TRational` | `TInteger` | `TRational` |
| `TRational` | `TFloat` | `TFloat` |
| `TComplex` | `TQuaternion` | `TQuaternion` |
| `TFloat` (matrix) | `TComplex` (scalar) | `TComplex` (matrix) |
| `TFloat` (matrix) | `TFloat` (scalar) | `TFloat` (matrix) |

Promotion is **lazy**: it happens at the point of the operation, so a `TFloat` matrix remains real until the first complex scalar multiplies it.

---

## Project structure

```
TELNumerics/
├── telnumeric.pas          TNumeric           abstract base class
├── telfloat.pas            TFloat             double-precision real
├── telinteger.pas          TInteger           64-bit signed integer
├── telcomplex.pas          TComplex           complex numbers
├── telrational.pas         TRational          exact fractions
├── telquaternion.pas       TQuaternion        quaternions
├── telmatrix2d.pas         TMatrix2D          matrices of TNumeric
├── telbits.pas             TBits              64-bit bit vector
├── telbinaryvector.pas     TBinaryVector      arbitrary-length bit vector
├── teleigen.pas            TEigen             eigenvalue solver
├── tellinearsystem.pas     TLinearSystem      linear system solver
├── tellinearsolution.pas   TLinearSolution    structured solution result
└── telquantum.pas          TQuantum           quantum gate and state toolkit
```

---

## Design principles

1. **One abstract interface.** All types share `TNumeric`. Polymorphism is the rule; no type is special.
2. **Caller owns what it receives.** Arithmetic returns fresh objects; assignment to a container transfers ownership.
3. **Free operator overloads.** Operators route through the VMT, so a new type never requires editing the operator definitions.
4. **Typed constants from elements.** Every type implements `Zero` and `One`, so generic algorithms (matrix inversion, RREF, basis construction) produce elements of the correct concrete type without casting or `AsFloat`.
5. **Serialization round-trips.** Every type's `ToString` is parseable by its `CreateFromString`.
6. **Exact when possible.** Rational and integer arithmetic stays exact; promotion to floating-point happens only when explicitly requested or forced by the operation.
7. **Extensibility without modification.** New numeric types, new gates, new matrix operations can all be added without touching existing code.

---

## Building and testing

The library is designed to be compiled with Free Pascal (`fpc`) or Lazarus. There is no external dependency beyond the FPC RTL and `Math`.

A typical test driver creates objects, exercises arithmetic, and frees them:

```pascal
program TestNumerics;
{$mode objfpc}{$H+}
uses
  SysUtils, TELFloat, TELInteger, TELComplex, TELRational,
  TELMatrix2D, TELEigen;

var
  A, B, C: TComplex;
begin
  A := TComplex.Create(3, 4);
  B := TComplex.Create(1, -2);
  C := (A * B + TFloat.Create(1)) as TComplex;
  WriteLn(C.ToString);
  A.Free; B.Free; C.Free;
end.
```

For a GUI-driven test suite, each test is a method on a `TForm1` that appends results to a `TMemo`. This pattern is used throughout the reference tests to exercise every method in the library.

---

## Extending the library

### Adding a new numeric type

1. Derive from `TNumeric`.
2. Implement the abstract methods (`Add`, `Subtract`, `Multiply`, `Divide`, `Negate`, `Clone`, `AsFloat`, `Zero`, `One`, `ToString`).
3. Override `Inverse` and `IsZero` if you have better implementations than the defaults.
4. Optionally add mixed-type operators with `Double`, `Integer`, `TFloat`, `TComplex`, etc.
5. Add a `CreateFromString` if the type is serializable.

The new type automatically works with `TMatrix2D`, `TLinearSystem`, and any other container that stores `TNumeric`.

### Adding a new matrix operation

Add a method to `TMatrix2D` in `telmatrix2d.pas`, and — if it's a natural operator — an overload in the interface's operator section. It immediately works with any element type that supports the underlying operations.

### Adding a new quantum gate

Add a class method to `TQuantum` in `telquantum.pas`. Composite gates (controlled-U, tensor power, multi-qubit embedding) are already provided by `ControlledGate`, `TensorPower`, and `ApplyToQubit`.

---

## Known limitations

- **Quaternion `Unit` renamed to `Unity`.** `Unit` is a Pascal keyword.
- **Integer division truncates.** Use `TFloat` or `TRational` for exact division.
- **Matrix inverse is O(n³) per pivot.** Fine for small and moderate matrices; for large real matrices, a LU-based inverse would be faster.
- **Eigenvalue QR uses a Wilkinson shift with no deflation.** Correct for all sizes, fast for `n ≤ ~50`. Beyond that, Hessenberg reduction and deflation would be worthwhile.
- **`TRational` uses `Int64` numerators.** Overflow is possible for chains of operations on large fractions. A `TBigInt` back end would lift this.
- **`Randomize` must be called** before using `TQuantum.Measure` for nondeterministic behavior.

---

## Roadmap

Natural extensions for the CAS foundation:

- **`TPolynomial`** — coefficient vector with Horner evaluation, derivative, integral, and root-finding. Reuses the existing numeric types as coefficients.
- **`TSymbol` + `TExpression`** — symbolic AST with simplification. Numeric types become the leaves.
- **Expression parser** — infix notation with implicit multiplication, precedence, and function calls.
- **`TBigInt`** — arbitrary-precision integers, back-ending `TInteger` and `TRational`.
- **Linear algebra completion** — LU-based determinant, `Solve(A, b)`, QR decomposition, SVD, eigenvectors for non-symmetric matrices.
- **Fast paths** — sparse matrices, real-only fast Gauss-Jordan, Hessenberg reduction before QR.

---

## License

Add your preferred license here. The design and implementation are original work; no third-party code is incorporated.

---

## Acknowledgments

The library was developed incrementally, with each type added on top of the previous ones and tested against real examples from complex arithmetic, exact rational computation, quantum circuit simulation, and linear algebra. The uniform `TNumeric` interface is the reason all of them interoperate seamlessly.

If you extend the library — a new type, a new solver, a new gate — the same pattern applies: derive from `TNumeric`, implement the interface, and everything else works with it automatically.
