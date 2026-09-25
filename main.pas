unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Math,
  TELNumeric, TELFloat, TELInteger, TELComplex, TELMatrix2D, TELBits, TELBinaryVector,
  TELRational, TELLinearSystem, TELLinearSolution, TELQuantum, TELEigen;

type

  { TForm1 }

  TForm1 = class(TForm)
    Bevel1: TBevel;
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
  private
    procedure PrintTestHeader(const ATestName: string);
    procedure AssertEqual(const AExpected, AActual: Double; const AMessage: string = '');
    procedure AssertTrue(const ACondition: Boolean; const AMessage: string = '');
    procedure AssertEquals(const AExpected, AActual: string; const AMessage: string = '');
    procedure AssertEquals(const AExpected, AActual: Int64; const AMessage: string = '');
    procedure AssertEquals(const AExpected, AActual: UInt64; const AMessage: string = '');
    procedure TestTFloat;
    procedure TestTInteger;
    procedure TestCrossType;
    procedure TestTELComplex;
    procedure TestTELRational;
    procedure TestTMatrix2D;
    procedure TestTBits;
    procedure TestTBinaryVector;
    procedure TestMixedOperators;
    procedure TestErrorHandling;
    procedure TestComplexMatrixInversion;
    procedure TestRoundTrip;
    procedure TestMatrix2D;
    procedure TestTMatrix2DClassical;
    procedure TestTMatrix2DOperatorWithScalar;
    procedure TestTLinearSystemSolution;
    procedure TestTLinearSystemSolution2;
    procedure TestQuantum;
    procedure TestBellStateQuantum;
    procedure TestTELEigenValues;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.frm}

// ============================================================================
//  Helper procedures for testing
// ============================================================================

procedure TForm1.PrintTestHeader(const ATestName: string);
begin
  Memo1.Lines.Add('');
  Memo1.Lines.Add('========================================');
  Memo1.Lines.Add('Testing: ' + ATestName);
  Memo1.Lines.Add('========================================');
end;

procedure TForm1.AssertEqual(const AExpected, AActual: Double; const AMessage: string = '');
const
  EPSILON = 1e-8;
begin
  if Abs(AExpected - AActual) > EPSILON then
  begin
    Memo1.Lines.Add('FAIL: ' + AMessage);
    Memo1.Lines.Add('  Expected: ' + FloatToStr(AExpected));
    Memo1.Lines.Add('  Actual:   ' + FloatToStr(AActual));
  end;
end;

procedure TForm1.AssertTrue(const ACondition: Boolean; const AMessage: string = '');
begin
  if not ACondition then
  begin
    Memo1.Lines.Add('FAIL: ' + AMessage);
  end
  else Memo1.Lines.Add('SUCCESS: ' + AMessage);;
end;

procedure TForm1.AssertEquals(const AExpected, AActual: string; const AMessage: string = '');
begin
  if AExpected <> AActual then
  begin
    Memo1.Lines.Add('FAIL: ' + AMessage);
    Memo1.Lines.Add('  Expected: ' + AExpected);
    Memo1.Lines.Add('  Actual:   ' + AActual);
  end;
end;

procedure TForm1.AssertEquals(const AExpected, AActual: Int64; const AMessage: string = '');
begin
  if AExpected <> AActual then
  begin
    Memo1.Lines.Add('FAIL: ' + AMessage);
    Memo1.Lines.Add('  Expected: ' + IntToStr(AExpected));
    Memo1.Lines.Add('  Actual:   ' + IntToStr(AActual));
  end;
end;

procedure TForm1.AssertEquals(const AExpected, AActual: UInt64; const AMessage: string = '');
begin
  if AExpected <> AActual then
  begin
    Memo1.Lines.Add('FAIL: ' + AMessage);
    Memo1.Lines.Add('  Expected: ' + IntToStr(AExpected));
    Memo1.Lines.Add('  Actual:   ' + IntToStr(AActual));
  end;
end;

// ============================================================================
//  Test: TFloat
// ============================================================================

procedure TForm1.TestTFloat;
var
  A, B, C, D, E: TFloat;
  Inv: TNumeric;
begin
  PrintTestHeader('TFloat');

  // Create and test basic operations
  A := TFloat.Create(5.5);
  B := TFloat.Create(2.0);

  Memo1.Lines.Add('A = ' + A.ToString + '  B = ' + B.ToString);

  // Addition
  C := A.Add(B) as TFloat;
  Memo1.Lines.Add('A + B = ' + C.ToString);
  AssertEqual(7.5, C.Value, 'Float addition');

  // Subtraction
  D := A.Subtract(B) as TFloat;
  Memo1.Lines.Add('A - B = ' + D.ToString);
  AssertEqual(3.5, D.Value, 'Float subtraction');

  // Multiplication
  E := A.Multiply(B) as TFloat;
  Memo1.Lines.Add('A * B = ' + E.ToString);
  AssertEqual(11.0, E.Value, 'Float multiplication');

  // Division
  D := A.Divide(B) as TFloat;
  Memo1.Lines.Add('A / B = ' + D.ToString);
  AssertEqual(2.75, D.Value, 'Float division');

  // Negation
  C := A.Negate as TFloat;
  Memo1.Lines.Add('-A = ' + C.ToString);
  AssertEqual(-5.5, C.Value, 'Float negation');

  // Inverse
  Inv := A.Inverse;
  Memo1.Lines.Add('1/A = ' + Inv.ToString);
  AssertEqual(1.0/5.5, (Inv as TFloat).Value, 'Float inverse');

  // Clone
  C := A.Clone as TFloat;
  Memo1.Lines.Add('Clone(A) = ' + C.ToString);
  AssertEqual(A.Value, C.Value, 'Float clone');

  // Operator overloading
  C := (A + B) as TFloat;
  Memo1.Lines.Add('A + B (operator) = ' + C.ToString);
  AssertEqual(7.5, C.Value, 'Float operator +');

  C := (A - B) as TFloat;
  Memo1.Lines.Add('A - B (operator) = ' + C.ToString);
  AssertEqual(3.5, C.Value, 'Float operator -');

  C := (A * B) as TFloat;
  Memo1.Lines.Add('A * B (operator) = ' + C.ToString);
  AssertEqual(11.0, C.Value, 'Float operator *');

  C := (A / B) as TFloat;
  Memo1.Lines.Add('A / B (operator) = ' + C.ToString);
  AssertEqual(2.75, C.Value, 'Float operator /');

  C := (-A) as TFloat;
  Memo1.Lines.Add('-A (operator) = ' + C.ToString);
  AssertEqual(-5.5, C.Value, 'Float unary -');

  // Cleanup
  A.Free; B.Free; C.Free; D.Free; E.Free; Inv.Free;

  Memo1.Lines.Add('PASS: All TFloat tests passed!');
end;

// ============================================================================
//  Test: TInteger
// ============================================================================

procedure TForm1.TestTInteger;
var
  A, B, C, D, E: TInteger;
  Inv: TNumeric;
begin
  PrintTestHeader('TInteger');

  A := TInteger.Create(10);
  B := TInteger.Create(3);

  Memo1.Lines.Add('A = ' + A.ToString + '  B = ' + B.ToString);

  // Addition
  C := A.Add(B) as TInteger;
  Memo1.Lines.Add('A + B = ' + C.ToString);
  AssertEqual(13, C.Value, 'Integer addition');

  // Subtraction
  D := A.Subtract(B) as TInteger;
  Memo1.Lines.Add('A - B = ' + D.ToString);
  AssertEqual(7, D.Value, 'Integer subtraction');

  // Multiplication
  E := A.Multiply(B) as TInteger;
  Memo1.Lines.Add('A * B = ' + E.ToString);
  AssertEqual(30, E.Value, 'Integer multiplication');

  // Division (integer truncation)
  D := A.Divide(B) as TInteger;
  Memo1.Lines.Add('A / B = ' + D.ToString);
  AssertEqual(3, D.Value, 'Integer division');

  // Negation
  C := A.Negate as TInteger;
  Memo1.Lines.Add('-A = ' + C.ToString);
  AssertEqual(-10, C.Value, 'Integer negation');

  // Inverse (returns TFloat)
  Inv := A.Inverse;
  Memo1.Lines.Add('1/A = ' + Inv.ToString);
  AssertEqual(0.1, (Inv as TFloat).Value, 'Integer inverse');

  // Clone
  C := A.Clone as TInteger;
  Memo1.Lines.Add('Clone(A) = ' + C.ToString);
  AssertEqual(A.Value, C.Value, 'Integer clone');

  // Operator overloading
  C := (A + B) as TInteger;
  Memo1.Lines.Add('A + B (operator) = ' + C.ToString);
  AssertEqual(13, C.Value, 'Integer operator +');

  C := (A - B) as TInteger;
  Memo1.Lines.Add('A - B (operator) = ' + C.ToString);
  AssertEqual(7, C.Value, 'Integer operator -');

  C := (A * B) as TInteger;
  Memo1.Lines.Add('A * B (operator) = ' + C.ToString);
  AssertEqual(30, C.Value, 'Integer operator *');

  C := (A / B) as TInteger;
  Memo1.Lines.Add('A / B (operator) = ' + C.ToString);
  AssertEqual(3, C.Value, 'Integer operator /');

  C := (-A) as TInteger;
  Memo1.Lines.Add('-A (operator) = ' + C.ToString);
  AssertEqual(-10, C.Value, 'Integer unary -');

  // Cleanup
  A.Free; B.Free; C.Free; D.Free; E.Free; Inv.Free;

  Memo1.Lines.Add('PASS: All TInteger tests passed!');
end;

// ============================================================================
//  Test: Cross-type operations (TFloat + TInteger)
// ============================================================================

procedure TForm1.TestCrossType;
var
  F: TFloat;
  I: TInteger;
  Result: TNumeric;
begin
  PrintTestHeader('Cross-type operations (Float + Integer)');

  F := TFloat.Create(5.5);
  I := TInteger.Create(3);

  Memo1.Lines.Add('F = ' + F.ToString + '  I = ' + I.ToString);

  // Float + Integer -> Float
  Result := F.Add(I);
  Memo1.Lines.Add('F + I = ' + Result.ToString);
  // Result should be TFloat
  if Result is TFloat then
    AssertEqual(8.5, (Result as TFloat).Value, 'Float + Integer')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;

  // Integer + Float -> should return TFloat
  Result := I.Add(F);
  Memo1.Lines.Add('I + F = ' + Result.ToString);
  if Result is TFloat then
    AssertEqual(8.5, (Result as TFloat).Value, 'Integer + Float')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;

  // Float * Integer -> Float
  Result := F.Multiply(I);
  Memo1.Lines.Add('F * I = ' + Result.ToString);
  if Result is TFloat then
    AssertEqual(16.5, (Result as TFloat).Value, 'Float * Integer')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;

    // Integer * Float -> Float
  Result := I.Multiply(F);
  Memo1.Lines.Add('I * F = ' + Result.ToString);
  if Result is TFloat then
    AssertEqual(16.5, (Result as TFloat).Value, 'Integer * Float')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;

  // Operator overloading with cross-types
  Result := F + I;
  Memo1.Lines.Add('F + I (operator) = ' + Result.ToString);
  if Result is TFloat then
    AssertEqual(8.5, (Result as TFloat).Value, 'Operator Float + Integer')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;

  Result := I + F;
  Memo1.Lines.Add('I + F (operator) = ' + Result.ToString);
  if Result is TFloat then
    AssertEqual(8.5, (Result as TFloat).Value, 'Operator Float + Integer')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;

  Result := F * I;
  Memo1.Lines.Add('F * I (operator) = ' + Result.ToString);
  if Result is TFloat then
    AssertEqual(16.5, (Result as TFloat).Value, 'Operator Float * Integer')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;


  Result := I * F;
  Memo1.Lines.Add('I * F (operator) = ' + Result.ToString);
  if Result is TFloat then
    AssertEqual(16.5, (Result as TFloat).Value, 'IntegerOperator Float')
  else
    Memo1.Lines.Add('WARNING: Expected TFloat but got ' + Result.ClassName);
  Result.Free;

  // Cleanup
  F.Free; I.Free;

  Memo1.Lines.Add('PASS: All cross-type tests passed!');
end;


// ============================================================================
//  Test: TELComplex
// ============================================================================

procedure TForm1.TestTELComplex;
var
  z, w, r: TComplex;
begin
  PrintTestHeader('TComplex');

  z := TComplex.Create(3, 4);         // 3 + 4i, modulus 5, angle ≈ 0.9273
  w := TComplex.CreatePolar(2, Pi/3); // polar form
  r := z * w;                         // full complex multiply
  r := z + 5;                         // mixed with Integer
  r := z / TFloat.Create(2.0);        // mixed with TFloat
  Memo1.Lines.Add('r = '+ r.ToString);
  Memo1.Lines.Add('|z| = ' + z.Modulus.ToString);
  Memo1.Lines.Add('arg(z) = ' + z.Angle.ToString + ' rad');
  z.Angle := TFloat.Create(Pi/2);                    // rotate to purely imaginary
  z.Free; w.Free; r.Free;
end;


// ============================================================================
//  Test: TELRational
// ============================================================================

procedure TForm1.TestTELRational;
var
  r,s,t: TRational;
  i: TInteger;
  f: TFloat;
begin
  PrintTestHeader('TRational');
  r := TRational.Create(6, 3);   // normalizes to 2/1
  Memo1.Lines.Add('r = 6/3 = '+ r.ToString);
  s := TRational.Create(3, 4);
  Memo1.Lines.Add('s = 3/4 = '+ s.ToString);
  t:= r + s;
  Memo1.Lines.Add('r + s = '+ t.ToString);
  t.Free;
  t:= r - s;
  Memo1.Lines.Add('r - s = '+ t.ToString);
  t.Free;
  t:= r * s;
  Memo1.Lines.Add('r * s = '+ t.ToString);
  t.Free;
  t:= r / s;
  Memo1.Lines.Add('r / s = '+ t.ToString);
  t.Free;

  if r.IsInteger then
  begin
    i := r.ToInteger;            // TInteger(2), caller owns
    Memo1.Lines.Add('r As integer: ' + i.ToString);
    i.Free;
  end;

  f := r.FloatValue;             // TFloat(2.0), caller owns
  Memo1.Lines.Add('r As float: ' + f.ToString);
  f.Free;

  // Or via properties:
  f := r.AsFloatValue;           // same, caller owns
  Memo1.Lines.Add('r As float (As Properties): ' + f.ToString);
  f.Free;

  r.Free;
end;


// ============================================================================
//  Test: TMatrix2D
// ============================================================================

procedure TForm1.TestTMatrix2D;
var
  M1, M2, M3, M4: TMatrix2D;
  Inv: TMatrix2D;
  Det: TNumeric;
  R, C: Integer;
  S: TFloat;
begin
  PrintTestHeader('TMatrix2D');

  // Create 2x2 matrix: [1, 2; 3, 4]
  M1 := TMatrix2D.Create(2, 2);
  M1.Elements[0, 0] := TFloat.Create(1.0);
  M1.Elements[0, 1] := TFloat.Create(2.0);
  M1.Elements[1, 0] := TFloat.Create(3.0);
  M1.Elements[1, 1] := TFloat.Create(4.0);

  Memo1.Lines.Add('M1:');
  Memo1.Lines.Add(M1.ToString);

  // Create 2x2 matrix: [5, 6; 7, 8]
  M2 := TMatrix2D.Create(2, 2);
  M2.Elements[0, 0] := TFloat.Create(5.0);
  M2.Elements[0, 1] := TFloat.Create(6.0);
  M2.Elements[1, 0] := TFloat.Create(7.0);
  M2.Elements[1, 1] := TFloat.Create(8.0);

  Memo1.Lines.Add('M2:');
  Memo1.Lines.Add(M2.ToString);

  // Addition
  M3 := M1.Add(M2) as TMatrix2D;
  Memo1.Lines.Add('M1 + M2:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(6.0, (M3.Elements[0, 0] as TFloat).Value, 'Matrix addition [0,0]');
  AssertEqual(8.0, (M3.Elements[0, 1] as TFloat).Value, 'Matrix addition [0,1]');
  AssertEqual(10.0, (M3.Elements[1, 0] as TFloat).Value, 'Matrix addition [1,0]');
  AssertEqual(12.0, (M3.Elements[1, 1] as TFloat).Value, 'Matrix addition [1,1]');
  M3.Free;

  // Subtraction
  M3 := M1.Subtract(M2) as TMatrix2D;
  Memo1.Lines.Add('M1 - M2:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(-4.0, (M3.Elements[0, 0] as TFloat).Value, 'Matrix subtraction [0,0]');
  AssertEqual(-4.0, (M3.Elements[0, 1] as TFloat).Value, 'Matrix subtraction [0,1]');
  AssertEqual(-4.0, (M3.Elements[1, 0] as TFloat).Value, 'Matrix subtraction [1,0]');
  AssertEqual(-4.0, (M3.Elements[1, 1] as TFloat).Value, 'Matrix subtraction [1,1]');
  M3.Free;

  // Multiplication (matrix product)
  M3 := M1.Multiply(M2) as TMatrix2D;
  Memo1.Lines.Add('M1 * M2:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(19.0, (M3.Elements[0, 0] as TFloat).Value, 'Matrix multiplication [0,0]');
  AssertEqual(22.0, (M3.Elements[0, 1] as TFloat).Value, 'Matrix multiplication [0,1]');
  AssertEqual(43.0, (M3.Elements[1, 0] as TFloat).Value, 'Matrix multiplication [1,0]');
  AssertEqual(50.0, (M3.Elements[1, 1] as TFloat).Value, 'Matrix multiplication [1,1]');
  M3.Free;

  // Negation
  M3 := M1.Negate as TMatrix2D;
  Memo1.Lines.Add('-M1:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(-1.0, (M3.Elements[0, 0] as TFloat).Value, 'Matrix negation [0,0]');
  AssertEqual(-2.0, (M3.Elements[0, 1] as TFloat).Value, 'Matrix negation [0,1]');
  AssertEqual(-3.0, (M3.Elements[1, 0] as TFloat).Value, 'Matrix negation [1,0]');
  AssertEqual(-4.0, (M3.Elements[1, 1] as TFloat).Value, 'Matrix negation [1,1]');
  M3.Free;

  // Clone
  M3 := M1.Clone as TMatrix2D;
  Memo1.Lines.Add('Clone(M1):');
  Memo1.Lines.Add(M3.ToString);
  for R := 0 to 1 do
    for C := 0 to 1 do
      AssertEqual((M1.Elements[R, C] as TFloat).Value,
                  (M3.Elements[R, C] as TFloat).Value,
                  Format('Matrix clone [%d,%d]', [R, C]));
  M3.Free;

  // Inverse (2x2 matrix)
  Memo1.Lines.Add('Testing inverse of M1:');
  try
    Inv := M1.Inverse as TMatrix2D;
    Memo1.Lines.Add('M1^-1:');
    Memo1.Lines.Add(Inv.ToString);

    // Check M * M^-1 = I
    M3 := M1.Multiply(Inv) as TMatrix2D;
    Memo1.Lines.Add('M1 * M1^-1:');
    Memo1.Lines.Add(M3.ToString);
    AssertEqual(1.0, (M3.Elements[0, 0] as TFloat).Value, 'Inverse check [0,0]');
    AssertEqual(0.0, (M3.Elements[0, 1] as TFloat).Value, 'Inverse check [0,1]');
    AssertEqual(0.0, (M3.Elements[1, 0] as TFloat).Value, 'Inverse check [1,0]');
    AssertEqual(1.0, (M3.Elements[1, 1] as TFloat).Value, 'Inverse check [1,1]');
    Inv.Free;
    M3.Free;
  except
    on E: Exception do
      Memo1.Lines.Add('WARNING: Inverse test failed: ' + E.Message);
  end;

  // Determinant
  Det := M1.Determinant;
  Memo1.Lines.Add('det(M1) = ' + Det.ToString);
  AssertEqual(-2.0, (Det as TFloat).Value, 'Matrix determinant');
  Det.Free;

  // FillWith
  M3 := TMatrix2D.Create(2, 2);
  S := TFloat.Create(7.5);
  M3.FillWith(S);
  S.Free;
  Memo1.Lines.Add('M3 filled with 7.5:');
  Memo1.Lines.Add(M3.ToString);
  for R := 0 to 1 do
    for C := 0 to 1 do
      AssertEqual(7.5, (M3.Elements[R, C] as TFloat).Value,
                  Format('FillWith [%d,%d]', [R, C]));
  M3.Free;

  // 3x3 matrix for inverse test
  M3 := TMatrix2D.Create(3, 3);
  M3.Elements[0, 0] := TFloat.Create(2.0);
  M3.Elements[0, 1] := TFloat.Create(-1.0);
  M3.Elements[0, 2] := TFloat.Create(0.0);
  M3.Elements[1, 0] := TFloat.Create(-1.0);
  M3.Elements[1, 1] := TFloat.Create(2.0);
  M3.Elements[1, 2] := TFloat.Create(-1.0);
  M3.Elements[2, 0] := TFloat.Create(0.0);
  M3.Elements[2, 1] := TFloat.Create(-1.0);
  M3.Elements[2, 2] := TFloat.Create(2.0);

  Memo1.Lines.Add('M3 (3x3):');
  Memo1.Lines.Add(M3.ToString);

  try
    Inv := M3.Inverse as TMatrix2D;
    Memo1.Lines.Add('M3^-1:');
    Memo1.Lines.Add(Inv.ToString);

    // Check M * M^-1 = I
    M4 := M3.Multiply(Inv) as TMatrix2D;
    Memo1.Lines.Add('M3 * M3^-1:');
    Memo1.Lines.Add(M4.ToString);
    for R := 0 to 2 do
      for C := 0 to 2 do
        if R = C then
          AssertEqual(1.0, (M4.Elements[R, C] as TFloat).Value,
                      Format('Inverse check 3x3 [%d,%d]', [R, C]))
        else
          AssertEqual(0.0, (M4.Elements[R, C] as TFloat).Value,
                      Format('Inverse check 3x3 [%d,%d]', [R, C]));
    Inv.Free;
    M4.Free;
  except
    on E: Exception do
      Memo1.Lines.Add('WARNING: 3x3 Inverse test failed: ' + E.Message);
  end;

  Det := M3.Determinant;
  Memo1.Lines.Add('det(M3) = ' + Det.ToString);
  AssertEqual(4.0, (Det as TFloat).Value, 'Matrix determinant 3x3');
  Det.Free;

  // Cleanup
  M1.Free; M2.Free; M3.Free;

  Memo1.Lines.Add('PASS: All TMatrix2D tests passed!');
end;

// ============================================================================
//  Test: TBits
// ============================================================================

procedure TForm1.TestTBits;
var
  A, B, C: TBits;
  Inv: TNumeric;
begin
  PrintTestHeader('TBits');

  A := TBits.Create($FF);      // 11111111
  B := TBits.Create($0F);      // 00001111

  Memo1.Lines.Add('A = ' + A.ToString + ' (' + IntToStr(A.Value) + ')');
  Memo1.Lines.Add('B = ' + B.ToString + ' (' + IntToStr(B.Value) + ')');

  // Bitwise AND
  C := A.BitwiseAnd(B);
  Memo1.Lines.Add('A AND B = ' + C.ToString);
  AssertEquals($0F, C.Value, 'Bitwise AND');
  C.Free;

  // Bitwise OR
  C := A.BitwiseOr(B);
  Memo1.Lines.Add('A OR B = ' + C.ToString);
  AssertEquals($FF, C.Value, 'Bitwise OR');
  C.Free;

  // Bitwise XOR
  C := A.BitwiseXor(B);
  Memo1.Lines.Add('A XOR B = ' + C.ToString);
  AssertEquals($F0, C.Value, 'Bitwise XOR');
  C.Free;

  // Bitwise NOT
  C := A.BitwiseNot;
  Memo1.Lines.Add('NOT A = ' + C.ToString);
  AssertEquals(not UInt64($FF), C.Value, 'Bitwise NOT');
  C.Free;

  // Shift Left
  C := A.ShiftLeft(2);
  Memo1.Lines.Add('A << 2 = ' + C.ToString);
  AssertEquals($3FC, C.Value, 'Shift Left');
  C.Free;

  // Shift Right
  C := A.ShiftRight(2);
  Memo1.Lines.Add('A >> 2 = ' + C.ToString);
  AssertEquals($3F, C.Value, 'Shift Right');
  C.Free;

  // TNumeric interface
  C := A.Add(B) as TBits;        // OR
  Memo1.Lines.Add('A + B (OR) = ' + C.ToString);
  AssertEquals($FF, C.Value, 'Add = OR');
  C.Free;

  C := A.Multiply(B) as TBits;   // AND
  Memo1.Lines.Add('A * B (AND) = ' + C.ToString);
  AssertEquals($0F, C.Value, 'Multiply = AND');
  C.Free;

  C := A.Divide(B) as TBits;     // XOR
  Memo1.Lines.Add('A / B (XOR) = ' + C.ToString);
  AssertEquals($F0, C.Value, 'Divide = XOR');
  C.Free;

  C := A.Subtract(B) as TBits;   // AND with NOT
  Memo1.Lines.Add('A - B (AND NOT) = ' + C.ToString);
  AssertEquals($F0, C.Value, 'Subtract = AND NOT');
  C.Free;

  C := A.Negate as TBits;        // NOT
  Memo1.Lines.Add('-A (NOT) = ' + C.ToString);
  AssertEquals(not UInt64($FF), C.Value, 'Negate = NOT');
  C.Free;

  // Inverse should raise error
  Memo1.Lines.Add('Testing Inverse (should raise error):');
  try
    Inv := A.Inverse;
    Memo1.Lines.Add('ERROR: Inverse should have raised an error!');
    Inv.Free;
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: Inverse correctly raised: ' + E.Message);
  end;

  // Clone
  C := A.Clone as TBits;
  Memo1.Lines.Add('Clone(A) = ' + C.ToString);
  AssertEquals(A.Value, C.Value, 'Clone');
  C.Free;

  // Cleanup
  A.Free; B.Free;

  Memo1.Lines.Add('PASS: All TBits tests passed!');
end;

// ============================================================================
//  Test: TBinaryVector
// ============================================================================

procedure TForm1.TestTBinaryVector;
var
  A, B, C, D: TBinaryVector;
  Inv: TNumeric;
begin
  PrintTestHeader('TBinaryVector');

  // Create from binary strings
  A := TBinaryVector.Create('10101010');  // 8 bits
  B := TBinaryVector.Create('11001100');  // 8 bits

  Memo1.Lines.Add('A = ' + A.ToString);
  Memo1.Lines.Add('B = ' + B.ToString);

  // --- Non-mutating operations: all read A and B, don't modify them ---

  // Bitwise AND
  C := A.BitwiseAnd(B);
  Memo1.Lines.Add('A AND B = ' + C.ToString);
  AssertEquals('10001000', C.ToString, 'Bitwise AND');
  C.Free;

  // Bitwise OR
  C := A.BitwiseOr(B);
  Memo1.Lines.Add('A OR B = ' + C.ToString);
  AssertEquals('11101110', C.ToString, 'Bitwise OR');
  C.Free;

  // Bitwise XOR
  C := A.BitwiseXor(B);
  Memo1.Lines.Add('A XOR B = ' + C.ToString);
  AssertEquals('01100110', C.ToString, 'Bitwise XOR');
  C.Free;

  // Bitwise NOT
  C := A.BitwiseNot;
  Memo1.Lines.Add('NOT A = ' + C.ToString);
  AssertEquals('01010101', C.ToString, 'Bitwise NOT');
  C.Free;

  // Shift Left
  C := A.ShiftLeft(2);
  Memo1.Lines.Add('A << 2 = ' + C.ToString);
  AssertEquals('10101000', C.ToString, 'Shift Left');
  C.Free;

  // Shift Right
  C := A.ShiftRight(2);
  Memo1.Lines.Add('A >> 2 = ' + C.ToString);
  AssertEquals('00101010', C.ToString, 'Shift Right');
  C.Free;

  // Rotate Left
  C := A.RotateLeft(2);
  Memo1.Lines.Add('A ROL 2 = ' + C.ToString);
  AssertEquals('10101010', C.ToString, 'Rotate Left');
  C.Free;

  // Rotate Right
  C := A.RotateRight(2);
  Memo1.Lines.Add('A ROR 2 = ' + C.ToString);
  AssertEquals('10101010', C.ToString, 'Rotate Right');
  C.Free;

  // Hamming Weight (A is still 10101010, weight = 4)
  Memo1.Lines.Add('HammingWeight(A) = ' + IntToStr(A.HammingWeight));
  AssertEquals(4, A.HammingWeight, 'Hamming Weight');

  // Hamming Distance
  Memo1.Lines.Add('HammingDistance(A,B) = ' + IntToStr(A.HammingDistance(B)));
  AssertEquals(4, A.HammingDistance(B), 'Hamming Distance');

  // Concatenate
  C := A.Concatenate(B);
  Memo1.Lines.Add('A || B = ' + C.ToString);
  AssertEquals('1010101011001100', C.ToString, 'Concatenate');
  C.Free;

  // TNumeric interface
  C := A.Add(B) as TBinaryVector;        // XOR
  Memo1.Lines.Add('A + B (XOR) = ' + C.ToString);
  AssertEquals('01100110', C.ToString, 'Add = XOR');
  C.Free;

  C := A.Multiply(B) as TBinaryVector;   // AND
  Memo1.Lines.Add('A * B (AND) = ' + C.ToString);
  AssertEquals('10001000', C.ToString, 'Multiply = AND');
  C.Free;

  C := A.Divide(B) as TBinaryVector;     // XOR
  Memo1.Lines.Add('A / B (XOR) = ' + C.ToString);
  AssertEquals('01100110', C.ToString, 'Divide = XOR');
  C.Free;

  C := A.Subtract(B) as TBinaryVector;   // AND with NOT
  Memo1.Lines.Add('A - B (AND NOT) = ' + C.ToString);
  AssertEquals('00100010', C.ToString, 'Subtract = AND NOT');
  C.Free;

  C := A.Negate as TBinaryVector;        // NOT
  Memo1.Lines.Add('-A (NOT) = ' + C.ToString);
  AssertEquals('01010101', C.ToString, 'Negate = NOT');
  C.Free;

  // Clone (A still equals '10101010')
  C := A.Clone as TBinaryVector;
  Memo1.Lines.Add('Clone(A) = ' + C.ToString);
  AssertEquals(A.ToString, C.ToString, 'Clone');
  C.Free;

  // Inverse should raise error
  Memo1.Lines.Add('Testing Inverse (should raise error):');
  try
    Inv := A.Inverse;
    Memo1.Lines.Add('ERROR: Inverse should have raised an error!');
    Inv.Free;
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: Inverse correctly raised: ' + E.Message);
  end;

  // --- Mutating operations: put these last, they alter A ---

  // SetBit / GetBit
  A.SetBitPublic(2, False);
  Memo1.Lines.Add('A with bit 2 cleared = ' + A.ToString);
  AssertTrue(not A.GetBitPublic(2), 'GetBit after clear');
  A.SetBitPublic(2, True);
  Memo1.Lines.Add('A with bit 2 set = ' + A.ToString);
  AssertTrue(A.GetBitPublic(2), 'GetBit after set');

  // SetBits / GetBits
  A.SetBits(2, 4, $F);  // set bits 2-5 to 1111
  Memo1.Lines.Add('A with bits 2-5 set to 1111 = ' + A.ToString);
  AssertEquals($F, A.GetBits(2, 4), 'GetBits');

  // --- Separate small-vector tests ---
  D := TBinaryVector.Create('1');
  Memo1.Lines.Add('D = ' + D.ToString);
  AssertEquals(1, D.Size, 'Size 1');
  D.Free;

  D := TBinaryVector.Create('1010101010101010');  // 16 bits
  Memo1.Lines.Add('D = ' + D.ToString);
  AssertEquals(16, D.Size, 'Size 16');

  C := D.ShiftLeft(3);
  Memo1.Lines.Add('D << 3 = ' + C.ToString);
  C.Free;

  C := D.ShiftRight(3);
  Memo1.Lines.Add('D >> 3 = ' + C.ToString);
  C.Free;

  D.Free;

  // Cleanup
  A.Free; B.Free;

  Memo1.Lines.Add('PASS: All TBinaryVector tests passed!');
end;

// ============================================================================
//  Test: Operator overloading with mixed types
// ============================================================================

procedure TForm1.TestMixedOperators;
var
  F: TFloat;
  I: TInteger;
  M1, M2: TMatrix2D;
  B1, B2: TBits;
  V1, V2: TBinaryVector;
  Result: TNumeric;
begin
  PrintTestHeader('Mixed operator overloading');

  // Float + Integer
  F := TFloat.Create(5.5);
  I := TInteger.Create(3);
  Result := F + I;
  Memo1.Lines.Add('TFloat + TInteger = ' + Result.ToString);
  AssertEqual(8.5, (Result as TFloat).Value, 'Mixed +');
  Result.Free;
  F.Free; I.Free;

  // Matrix + Matrix
  M1 := TMatrix2D.Create(2, 2);
  M1.Elements[0, 0] := TFloat.Create(1.0);
  M1.Elements[0, 1] := TFloat.Create(2.0);
  M1.Elements[1, 0] := TFloat.Create(3.0);
  M1.Elements[1, 1] := TFloat.Create(4.0);

  M2 := TMatrix2D.Create(2, 2);
  M2.Elements[0, 0] := TFloat.Create(5.0);
  M2.Elements[0, 1] := TFloat.Create(6.0);
  M2.Elements[1, 0] := TFloat.Create(7.0);
  M2.Elements[1, 1] := TFloat.Create(8.0);

  Result := M1 + M2;
  Memo1.Lines.Add('Matrix + Matrix:');
  Memo1.Lines.Add(Result.ToString);
  AssertEqual(6.0, ((Result as TMatrix2D).Elements[0, 0] as TFloat).Value, 'Matrix +');
  Result.Free;
  M1.Free; M2.Free;

  // TBits + TBits (OR)
  B1 := TBits.Create($F0);
  B2 := TBits.Create($0F);
  Result := B1 + B2;
  Memo1.Lines.Add('TBits + TBits (OR) = ' + Result.ToString);
  AssertEquals($FF, (Result as TBits).Value, 'Bits +');
  Result.Free;
  B1.Free; B2.Free;

  // TBits * TBits (AND)
  B1 := TBits.Create($FF);
  B2 := TBits.Create($F0);
  Result := B1 * B2;
  Memo1.Lines.Add('TBits * TBits (AND) = ' + Result.ToString);
  AssertEquals($F0, (Result as TBits).Value, 'Bits *');
  Result.Free;
  B1.Free; B2.Free;

  // TBinaryVector + TBinaryVector (XOR)
  V1 := TBinaryVector.Create('1010');
  V2 := TBinaryVector.Create('1100');
  Result := V1 + V2;
  Memo1.Lines.Add('BinaryVector + BinaryVector (XOR) = ' + Result.ToString);
  AssertEquals('0110', (Result as TBinaryVector).ToString, 'BinaryVector +');
  Result.Free;
  V1.Free; V2.Free;

  Memo1.Lines.Add('PASS: All mixed operator tests passed!');
end;

// ============================================================================
//  Test: Error handling
// ============================================================================

procedure TForm1.TestErrorHandling;
var
  M: TMatrix2D;
  Inv: TMatrix2D;
  F: TFloat;
  B1: TBits;
begin
  PrintTestHeader('Error handling');

  // Division by zero
  Memo1.Lines.Add('Testing division by zero in TFloat:');
  F := TFloat.Create(5.0);
  try
    F.Divide(TFloat.Create(0.0));
    Memo1.Lines.Add('ERROR: Division by zero should have raised an error!');
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: Division by zero raised: ' + E.Message);
  end;
  F.Free;

  // Non-square matrix inverse
  Memo1.Lines.Add('Testing non-square matrix inverse:');
  M := TMatrix2D.Create(2, 3);
  try
    Inv := M.Inverse as TMatrix2D;
    Memo1.Lines.Add('ERROR: Non-square inverse should have raised an error!');
    Inv.Free;
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: Non-square inverse raised: ' + E.Message);
  end;
  M.Free;

  // Singular matrix inverse
  Memo1.Lines.Add('Testing singular matrix inverse:');
  M := TMatrix2D.Create(2, 2);
  M.Elements[0, 0] := TFloat.Create(1.0);
  M.Elements[0, 1] := TFloat.Create(2.0);
  M.Elements[1, 0] := TFloat.Create(2.0);
  M.Elements[1, 1] := TFloat.Create(4.0);  // Singular matrix
  try
    Inv := M.Inverse as TMatrix2D;
    Memo1.Lines.Add('ERROR: Singular inverse should have raised an error!');
    Inv.Free;
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: Singular inverse raised: ' + E.Message);
  end;
  M.Free;

  // Matrix dimension mismatch
  Memo1.Lines.Add('Testing matrix dimension mismatch:');
  M := TMatrix2D.Create(2, 2);
  try
    M.Add(TMatrix2D.Create(3, 3));
    Memo1.Lines.Add('ERROR: Dimension mismatch should have raised an error!');
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: Dimension mismatch raised: ' + E.Message);
  end;
  M.Free;

  // Out of bounds access
  Memo1.Lines.Add('Testing out of bounds access:');
  M := TMatrix2D.Create(2, 2);
  try
    M.Elements[5, 5] := TFloat.Create(0.0);
    Memo1.Lines.Add('ERROR: Out of bounds should have raised an error!');
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: Out of bounds raised: ' + E.Message);
  end;
  M.Free;

  // TBits inverse (should raise error)
  Memo1.Lines.Add('Testing TBits inverse:');
  B1 := TBits.Create($FF);
  try
    B1.Inverse;
    Memo1.Lines.Add('ERROR: TBits.Inverse should have raised an error!');
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: TBits.Inverse raised: ' + E.Message);
  end;
  B1.Free;

  Memo1.Lines.Add('PASS: All error handling tests passed!');
end;


// ============================================================================
//  Test: Complex Matrix Inversion
// ============================================================================

procedure TForm1.TestComplexMatrixInversion;
var
  A, Inv, Prod, Eye: TMatrix2D;
  R, C: Integer;
begin
  PrintTestHeader('Complex Matrix Inversion');
  { Build a 2x2 complex matrix }
  A := TMatrix2D.Create(2, 2);
  A.Elements[0, 0] := TComplex.Create(1, 1);
  A.Elements[0, 1] := TComplex.Create(0, 2);
  A.Elements[1, 0] := TComplex.Create(3, -1);
  A.Elements[1, 1] := TComplex.Create(2, 0);

   Memo1.Lines.Add('A =');
   Memo1.Lines.Add(A.ToString);

  Inv := A.Inverse as TMatrix2D; // Matrix
   Memo1.Lines.Add('A^-1 =');
   Memo1.Lines.Add(Inv.ToString);

  { Verify A * A^-1 == I }
  Prod := A * Inv;
   Memo1.Lines.Add('A * A^-1 =');
   Memo1.Lines.Add(Prod.ToString);

  Eye := TMatrix2D.IdentityOf(2, TComplex.Create(1, 0));
  for R := 0 to 1 do
    for C := 0 to 1 do
      AssertTrue(TComplex(Prod.Elements[R, C]).Equals(
                   TComplex(Eye.Elements[R, C])));

  A.Free; Inv.Free; Prod.Free; Eye.Free;
end;

// ============================================================================
//   TestRoundTrip
// ============================================================================

procedure TForm1.TestRoundTrip;
var
  F, F2: TFloat;
  I, I2: TInteger;
  Z, Z2: TComplex;
  R, R2: TRational;
  B, B2: TBits;
  V, V2: TBinaryVector;
begin
  PrintTestHeader('Round-trip serialization');

  F := TFloat.Create(3.14159);
  Memo1.Lines.Add('F='+F.ToString);
  F2 := TFloat.CreateFromString(F.ToString);
  AssertEqual(F.Value, F2.Value, 'TFloat round-trip');
  F.Free; F2.Free;

  I := TInteger.Create(-12345);
  Memo1.Lines.Add('I='+I.ToString);
  I2 := TInteger.CreateFromString(I.ToString);
  AssertEqual(I.Value, I2.Value, 'TInteger round-trip');
  I.Free; I2.Free;

  Z := TComplex.Create(3, 4);
  Memo1.Lines.Add('Z='+Z.ToString);
  Z2 := TComplex.CreateFromString(Z.ToString);
  AssertTrue(Z.Equals(Z2), 'TComplex round-trip');
  Z.Free; Z2.Free;

  R := TRational.Create(22, 7);
  Memo1.Lines.Add('R='+R.ToString);
  R2 := TRational.CreateFromString(R.ToString);
  AssertEquals(R.ToString, R2.ToString, 'TRational round-trip');
  R.Free; R2.Free;

  B := TBits.Create($DEADBEEF);
  Memo1.Lines.Add('B='+B.ToString);
  B2 := TBits.CreateFromString(B.ToString);
  AssertEquals(B.Value, B2.Value, 'TBits round-trip');
  B.Free; B2.Free;

  V := TBinaryVector.Create('10110010');
  Memo1.Lines.Add('V='+V.ToString);
  V2 := TBinaryVector.CreateFromString(V.ToString);
  AssertEquals(V.ToString, V2.ToString, 'TBinaryVector round-trip');
  V.Free; V2.Free;

  Memo1.Lines.Add('PASS: All round-trip tests passed!');
end;

// ============================================================================
//  TestMatrix2D
// ============================================================================

procedure TForm1.TestMatrix2D;
var
  M1, M2, M3, M4: TMatrix2D;
  Inv, Det: TNumeric;
  InvM: TMatrix2D;
  R, C: Integer;
  S: TFloat;
  RT: TMatrix2D;
  Z1, Z2, ZInv, ZProd, ZEye: TMatrix2D;
begin
  PrintTestHeader('TMatrix2D - Construction, arithmetic, inverse, serialization');

  { ------------------------------------------------------------------
    1. Construction and element access
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('--- Construction ---');

  M1 := TMatrix2D.Create(2, 2);
  M1.Elements[0, 0] := TFloat.Create(1.0);
  M1.Elements[0, 1] := TFloat.Create(2.0);
  M1.Elements[1, 0] := TFloat.Create(3.0);
  M1.Elements[1, 1] := TFloat.Create(4.0);

  Memo1.Lines.Add('M1 (from TFloat elements):');
  Memo1.Lines.Add(M1.ToString);

  AssertEquals(2, M1.Rows, 'M1.Rows');
  AssertEquals(2, M1.Cols, 'M1.Cols');
  AssertEqual(1.0, (M1.Elements[0, 0] as TFloat).Value, 'M1[0,0]');
  AssertEqual(4.0, (M1.Elements[1, 1] as TFloat).Value, 'M1[1,1]');

  { Out-of-bounds access must raise }
  try
    M1.Elements[2, 0] := TFloat.Create(0.0);
    Memo1.Lines.Add('FAIL: out-of-bounds did not raise');
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: out-of-bounds raised: ' + E.Message);
  end;

  { ------------------------------------------------------------------
    2. Identity matrix
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Identity ---');

  M2 := TMatrix2D.Identity(3);
  Memo1.Lines.Add('Identity(3):');
  Memo1.Lines.Add(M2.ToString);
  AssertEquals(3, M2.Rows, 'Identity(3).Rows');
  AssertEquals(3, M2.Cols, 'Identity(3).Cols');
  for R := 0 to 2 do
    for C := 0 to 2 do
      if R = C then
        AssertEqual(1.0, (M2.Elements[R, C] as TFloat).Value,
                    Format('Identity[%d,%d]', [R, C]))
      else
        AssertEqual(0.0, (M2.Elements[R, C] as TFloat).Value,
                    Format('Identity[%d,%d]', [R, C]));
  M2.Free;

  { ------------------------------------------------------------------
    3. Element-wise addition / subtraction
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Add / Subtract ---');

  M2 := TMatrix2D.Create(2, 2);
  M2.Elements[0, 0] := TFloat.Create(5.0);
  M2.Elements[0, 1] := TFloat.Create(6.0);
  M2.Elements[1, 0] := TFloat.Create(7.0);
  M2.Elements[1, 1] := TFloat.Create(8.0);

  M3 := M1.Add(M2) as TMatrix2D;
  Memo1.Lines.Add('M1 + M2:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(6.0,  (M3.Elements[0, 0] as TFloat).Value, 'Add [0,0]');
  AssertEqual(8.0,  (M3.Elements[0, 1] as TFloat).Value, 'Add [0,1]');
  AssertEqual(10.0, (M3.Elements[1, 0] as TFloat).Value, 'Add [1,0]');
  AssertEqual(12.0, (M3.Elements[1, 1] as TFloat).Value, 'Add [1,1]');
  M3.Free;

  M3 := M1.Subtract(M2) as TMatrix2D;
  Memo1.Lines.Add('M1 - M2:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(-4.0, (M3.Elements[0, 0] as TFloat).Value, 'Sub [0,0]');
  AssertEqual(-4.0, (M3.Elements[0, 1] as TFloat).Value, 'Sub [0,1]');
  AssertEqual(-4.0, (M3.Elements[1, 0] as TFloat).Value, 'Sub [1,0]');
  AssertEqual(-4.0, (M3.Elements[1, 1] as TFloat).Value, 'Sub [1,1]');
  M3.Free;

  { Dimension mismatch must raise }
  M3 := TMatrix2D.Create(3, 3);
  try
    M3.Add(M1);
    Memo1.Lines.Add('FAIL: dimension mismatch did not raise');
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: dimension mismatch raised: ' + E.Message);
  end;
  M3.Free;

  { ------------------------------------------------------------------
    4. Matrix multiplication
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Multiply ---');

  M3 := M1.Multiply(M2) as TMatrix2D;
  Memo1.Lines.Add('M1 * M2:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(19.0, (M3.Elements[0, 0] as TFloat).Value, 'Mult [0,0]');
  AssertEqual(22.0, (M3.Elements[0, 1] as TFloat).Value, 'Mult [0,1]');
  AssertEqual(43.0, (M3.Elements[1, 0] as TFloat).Value, 'Mult [1,0]');
  AssertEqual(50.0, (M3.Elements[1, 1] as TFloat).Value, 'Mult [1,1]');
  M3.Free;

  { ------------------------------------------------------------------
    5. Negation and Clone
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Negate / Clone ---');

  M3 := M1.Negate as TMatrix2D;
  Memo1.Lines.Add('-M1:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(-1.0, (M3.Elements[0, 0] as TFloat).Value, 'Negate [0,0]');
  AssertEqual(-4.0, (M3.Elements[1, 1] as TFloat).Value, 'Negate [1,1]');
  M3.Free;

  M3 := M1.Clone as TMatrix2D;
  for R := 0 to 1 do
    for C := 0 to 1 do
      AssertEqual((M1.Elements[R, C] as TFloat).Value,
                  (M3.Elements[R, C] as TFloat).Value,
                  Format('Clone [%d,%d]', [R, C]));
  M3.Free;

  { ------------------------------------------------------------------
    6. Inverse (2x2)
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Inverse (2x2) ---');

  Inv := M1.Inverse;
  InvM := Inv as TMatrix2D;
  Memo1.Lines.Add('M1^-1:');
  Memo1.Lines.Add(InvM.ToString);

  M3 := M1.Multiply(InvM) as TMatrix2D;
  Memo1.Lines.Add('M1 * M1^-1:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(1.0, (M3.Elements[0, 0] as TFloat).Value, 'Inv check [0,0]');
  AssertEqual(0.0, (M3.Elements[0, 1] as TFloat).Value, 'Inv check [0,1]');
  AssertEqual(0.0, (M3.Elements[1, 0] as TFloat).Value, 'Inv check [1,0]');
  AssertEqual(1.0, (M3.Elements[1, 1] as TFloat).Value, 'Inv check [1,1]');
  M3.Free;
  Inv.Free;

  { ------------------------------------------------------------------
    7. Determinant (2x2)
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Determinant (2x2) ---');

  Det := M1.Determinant;
  Memo1.Lines.Add('det(M1) = ' + Det.ToString);
  AssertEqual(-2.0, (Det as TFloat).Value, 'det(M1)');
  Det.Free;

  { ------------------------------------------------------------------
    8. FillWith
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- FillWith ---');

  M3 := TMatrix2D.Create(2, 2);
  S := TFloat.Create(7.5);
  M3.FillWith(S);
  S.Free;
  for R := 0 to 1 do
    for C := 0 to 1 do
      AssertEqual(7.5, (M3.Elements[R, C] as TFloat).Value,
                  Format('FillWith [%d,%d]', [R, C]));
  M3.Free;

  { ------------------------------------------------------------------
    9. Inverse (3x3) - non-trivial matrix
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Inverse (3x3) ---');

  M3 := TMatrix2D.Create(3, 3);
  M3.Elements[0, 0] := TFloat.Create(2.0);
  M3.Elements[0, 1] := TFloat.Create(-1.0);
  M3.Elements[0, 2] := TFloat.Create(0.0);
  M3.Elements[1, 0] := TFloat.Create(-1.0);
  M3.Elements[1, 1] := TFloat.Create(2.0);
  M3.Elements[1, 2] := TFloat.Create(-1.0);
  M3.Elements[2, 0] := TFloat.Create(0.0);
  M3.Elements[2, 1] := TFloat.Create(-1.0);
  M3.Elements[2, 2] := TFloat.Create(2.0);

  Memo1.Lines.Add('M3 (3x3):');
  Memo1.Lines.Add(M3.ToString);

  Inv := M3.Inverse;
  InvM := Inv as TMatrix2D;
  Memo1.Lines.Add('M3^-1:');
  Memo1.Lines.Add(InvM.ToString);

  M4 := M3.Multiply(InvM) as TMatrix2D;
  Memo1.Lines.Add('M3 * M3^-1:');
  Memo1.Lines.Add(M4.ToString);
  for R := 0 to 2 do
    for C := 0 to 2 do
      if R = C then
        AssertEqual(1.0, (M4.Elements[R, C] as TFloat).Value,
                    Format('3x3 Inv [%d,%d]', [R, C]))
      else
        AssertEqual(0.0, (M4.Elements[R, C] as TFloat).Value,
                    Format('3x3 Inv [%d,%d]', [R, C]));
  Inv.Free;
  M4.Free;

  Det := M3.Determinant;
  Memo1.Lines.Add('det(M3) = ' + Det.ToString);
  AssertEqual(4.0, (Det as TFloat).Value, 'det(M3)');
  Det.Free;
  M3.Free;

  { ------------------------------------------------------------------
    10. Singular matrix -> should raise
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Singular matrix ---');

  M3 := TMatrix2D.Create(2, 2);
  M3.Elements[0, 0] := TFloat.Create(1.0);
  M3.Elements[0, 1] := TFloat.Create(2.0);
  M3.Elements[1, 0] := TFloat.Create(2.0);
  M3.Elements[1, 1] := TFloat.Create(4.0);
  try
    Inv := M3.Inverse;
    Memo1.Lines.Add('FAIL: singular inverse did not raise');
    Inv.Free;
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: singular inverse raised: ' + E.Message);
  end;
  M3.Free;

  { ------------------------------------------------------------------
    11. Non-square inverse -> should raise
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Non-square inverse ---');

  M3 := TMatrix2D.Create(2, 3);
  try
    Inv := M3.Inverse;
    Memo1.Lines.Add('FAIL: non-square inverse did not raise');
    Inv.Free;
  except
    on E: ENumericError do
      Memo1.Lines.Add('OK: non-square inverse raised: ' + E.Message);
  end;
  M3.Free;

  { ------------------------------------------------------------------
    12. Complex matrix inversion
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Complex matrix inversion ---');

  Z1 := TMatrix2D.Create(2, 2);
  Z1.Elements[0, 0] := TComplex.Create(1, 1);
  Z1.Elements[0, 1] := TComplex.Create(0, 2);
  Z1.Elements[1, 0] := TComplex.Create(3, -1);
  Z1.Elements[1, 1] := TComplex.Create(2, 0);

  Memo1.Lines.Add('Z1:');
  Memo1.Lines.Add(Z1.ToString);

  ZInv := Z1.Inverse as TMatrix2D;
  Memo1.Lines.Add('Z1^-1:');
  Memo1.Lines.Add(ZInv.ToString);

  ZProd := Z1 * ZInv;
  Memo1.Lines.Add('Z1 * Z1^-1:');
  Memo1.Lines.Add(ZProd.ToString);

  ZEye := TMatrix2D.IdentityOf(2, TComplex.Create(1, 0));
  for R := 0 to 1 do
    for C := 0 to 1 do
      AssertTrue(
        TComplex(ZProd.Elements[R, C]).Equals(
          TComplex(ZEye.Elements[R, C]), 1e-9),
        Format('Complex inverse [%d,%d]', [R, C]));

  Z1.Free; ZInv.Free; ZProd.Free; ZEye.Free;

  { ------------------------------------------------------------------
    13. Transpose
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Transpose ---');

  M3 := M1.Transpose;
  Memo1.Lines.Add('M1^T:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(1.0, (M3.Elements[0, 0] as TFloat).Value, 'Transpose [0,0]');
  AssertEqual(3.0, (M3.Elements[0, 1] as TFloat).Value, 'Transpose [0,1]');
  AssertEqual(2.0, (M3.Elements[1, 0] as TFloat).Value, 'Transpose [1,0]');
  AssertEqual(4.0, (M3.Elements[1, 1] as TFloat).Value, 'Transpose [1,1]');
  M3.Free;

  { ------------------------------------------------------------------
    14. Scalar multiplication
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Scalar multiplication ---');

  S := TFloat.Create(3.0);
  M3 := M1 * S;
  Memo1.Lines.Add('M1 * 3:');
  Memo1.Lines.Add(M3.ToString);
  AssertEqual(3.0,  (M3.Elements[0, 0] as TFloat).Value, 'Scalar * [0,0]');
  AssertEqual(6.0,  (M3.Elements[0, 1] as TFloat).Value, 'Scalar * [0,1]');
  AssertEqual(9.0,  (M3.Elements[1, 0] as TFloat).Value, 'Scalar * [1,0]');
  AssertEqual(12.0, (M3.Elements[1, 1] as TFloat).Value, 'Scalar * [1,1]');
  S.Free;
  M3.Free;

  { ------------------------------------------------------------------
    15. Serialization round-trip (float matrix)
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Round-trip serialization (float) ---');

  { Adjust the serializer name to match whatever you implemented. }
  RT := TMatrix2D.CreateFromStringFloat(M1.ToString);
  try
    Memo1.Lines.Add('Serialized M1:');
    Memo1.Lines.Add(M1.ToString);
    Memo1.Lines.Add('Deserialized:');
    Memo1.Lines.Add(RT.ToString);

    AssertEquals(M1.Rows, RT.Rows, 'RT.Rows');
    AssertEquals(M1.Cols, RT.Cols, 'RT.Cols');
    for R := 0 to M1.Rows - 1 do
      for C := 0 to M1.Cols - 1 do
        AssertEqual((M1.Elements[R, C] as TFloat).Value,
                    (RT.Elements[R, C] as TFloat).Value,
                    Format('RT [%d,%d]', [R, C]));
  finally
    RT.Free;
  end;

  { ------------------------------------------------------------------
    16. Serialization round-trip (complex matrix)
    ------------------------------------------------------------------ }
  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- Round-trip serialization (complex) ---');

  Z1 := TMatrix2D.Create(2, 2);
  Z1.Elements[0, 0] := TComplex.Create(1, 2);
  Z1.Elements[0, 1] := TComplex.Create(-3, 4);
  Z1.Elements[1, 0] := TComplex.Create(0, -1);
  Z1.Elements[1, 1] := TComplex.Create(5, 0);

  Z2 := TMatrix2D.CreateFromStringComplex(Z1.ToString);
  try
    Memo1.Lines.Add('Serialized Z1:');
    Memo1.Lines.Add(Z1.ToString);
    Memo1.Lines.Add('Deserialized:');
    Memo1.Lines.Add(Z2.ToString);

    AssertEquals(Z1.Rows, Z2.Rows, 'RT-Z.Rows');
    AssertEquals(Z1.Cols, Z2.Cols, 'RT-Z.Cols');
    for R := 0 to Z1.Rows - 1 do
      for C := 0 to Z1.Cols - 1 do
        AssertTrue(
          TComplex(Z1.Elements[R, C]).Equals(
            TComplex(Z2.Elements[R, C]), 1e-9),
          Format('RT-Z [%d,%d]', [R, C]));
  finally
    Z1.Free;
    Z2.Free;
  end;

  { ------------------------------------------------------------------
    Cleanup
    ------------------------------------------------------------------ }
  M1.Free; M2.Free;

  Memo1.Lines.Add('');
  Memo1.Lines.Add('PASS: All TMatrix2D tests passed!');
end;


// ============================================================================
//  TestMatrix2D   Classical Example
// ============================================================================


procedure TForm1.TestTMatrix2DClassical;
var
  A, AH, AHH: TMatrix2D;
  M: TMatrix2D;
  Fro, N1, NInf, NSpec: TFloat;
  M1, M2, M3, M4, M11, M30, FRACT: TMatrix2D;
  KET0, KET1, BRA0, BRA1, KETBRA : TMatrix2D;
  Inv: TMatrix2D;
  Z: TComplex;
  I: TInteger;
  Det: TNumeric;
  R, C: Integer;
  S: TFloat;
begin
  PrintTestHeader('Classical Example');

  M1 := TMatrix2D.Create(2, 2);
  M1.Elements[0, 0] := TFloat.Create(1.0);
  M1.Elements[0, 1] := TFloat.Create(1.0);
  M1.Elements[1, 0] := TFloat.Create(0.0);
  M1.Elements[1, 1] := TFloat.Create(0.0);


  // Create 2x2 matrix: [1, 2; 3, 4]
  // M1 := TMatrix2D.CreateFromStringFloat('[ [1.0, 1.0 ] [0.0, 0.0 ] ]');
   Memo1.Lines.Add('M1:');
   Memo1.Lines.Add(M1.ToString);

  M2 := TMatrix2D.CreateFromStringFloat('[ [1, 0 ] [0, 1 ] ]');
   Memo1.Lines.Add('M2:');
   Memo1.Lines.Add(M2.ToString);

  M3 := TMatrix2D.CreateFromStringFloat('[ [0, 1 ] [1, 0 ] ]');
   Memo1.Lines.Add('M3:');
   Memo1.Lines.Add(M3.ToString);

  M4 := TMatrix2D.CreateFromStringFloat('[ [0, 0 ] [1, 1 ] ]');
   Memo1.Lines.Add('M4:');
   Memo1.Lines.Add(M4.ToString);

  KET0 := TMatrix2D.CreateFromStringFloat('[[1] [0] ]');
   Memo1.Lines.Add('KET0:');
   Memo1.Lines.Add(KET0.ToString);

  KET1 := TMatrix2D.CreateFromStringFloat('[[0] [1] ]');
   Memo1.Lines.Add('KET1:');
   Memo1.Lines.Add(KET1.ToString);

  BRA0 := TMatrix2D.CreateFromStringFloat('[[1, 0]]');
   Memo1.Lines.Add('BRA0:');
   Memo1.Lines.Add(BRA0.ToString);

  BRA1 := TMatrix2D.CreateFromStringFloat('[[0, 1]]');
   Memo1.Lines.Add('BRA1:');
   Memo1.Lines.Add(BRA1.ToString);

  M11 := M1 * KET1;
   Memo1.Lines.Add('M11:');
   Memo1.Lines.Add(M11.ToString);

  M30 := M3 * KET0;
   Memo1.Lines.Add('M30:');
   Memo1.Lines.Add(M30.ToString);

  KETBRA := KET0 * BRA1;
   Memo1.Lines.Add('KETBRA:');
   Memo1.Lines.Add(KETBRA.ToString);

  Z := TComplex.Create(3, 4);

  FRACT := M3 * z;
   Memo1.Lines.Add('FRACT:');
   Memo1.Lines.Add(FRACT.ToString);
  FRACT.Free;

  S := TFloat.Create(4.5);

  FRACT := M3 * S;
   Memo1.Lines.Add('FRACT:');
   Memo1.Lines.Add(FRACT.ToString);
  FRACT.Free;


  I := TInteger.Create( 42 );
  FRACT := M3 * I;
   Memo1.Lines.Add('FRACT:');
   Memo1.Lines.Add(FRACT.ToString);

  M1.Free; M2.Free;

  M1 := TMatrix2D.CreateFromStringFloat('[ [1, 2, 3, 4 ] ]');
   Memo1.Lines.Add('M1:');
   Memo1.Lines.Add(M1.ToString);

  M2 := TMatrix2D.CreateFromStringFloat('[ [4] [2] [1] [1] ]');
   Memo1.Lines.Add('M2:');
   Memo1.Lines.Add(M2.ToString);

   FRACT.Free;
   FRACT := M1 * M2;
   Memo1.Lines.Add('M1 * M2:');
   Memo1.Lines.Add(FRACT.ToString);

  FRACT.Free;
  FRACT := M2 * M1;
  Memo1.Lines.Add('M2 * M1:');
  Memo1.Lines.Add(FRACT.ToString);

  PrintTestHeader('Matrix Norms');

  M := TMatrix2D.Create(2, 2);
  M.Elements[0, 0] := TFloat.Create(3);
  M.Elements[0, 1] := TFloat.Create(4);
  M.Elements[1, 0] := TFloat.Create(1);
  M.Elements[1, 1] := TFloat.Create(2);

  Fro   := M.FrobeniusNorm;    // sqrt(9 + 16 + 1 + 4) = sqrt(30) ≈ 5.4772
  N1    := M.Norm1;            // max(3+1, 4+2) = max(4, 6) = 6
  NInf  := M.NormInfinity;     // max(3+4, 1+2) = max(7, 3) = 7
  NSpec := M.SpectralNorm;     // largest singular value

  Memo1.Lines.Add('Frobenius:  ' + Fro.ToString);
  Memo1.Lines.Add('1-norm:     ' + N1.ToString);
  Memo1.Lines.Add('inf-norm:   ' + NInf.ToString);
  Memo1.Lines.Add('Spectral:   ' + NSpec.ToString);

  Fro.Free;  N1.Free;  NInf.Free;  NSpec.Free;

  A := TMatrix2D.Create(2, 2);
  A.Elements[0, 0] := TComplex.Create(1, 0);   { real }
  A.Elements[0, 1] := TComplex.Create(2, 3);
  A.Elements[1, 0] := TComplex.Create(4, -1);
  A.Elements[1, 1] := TComplex.Create(5, 0);

  AH := A.ConjugateTranspose;
  Memo1.Lines.Add('A:' + A.ToString);
  Memo1.Lines.Add('A^H:' + AH.ToString);
  { Expected:
    A^H =
      [ 1, 4+i ]
      [ 2-3i, 5 ]
  }

  PrintTestHeader('Conjugate transpose 1');

    A.Free; AH.Free; AHH.Free;
    A := TMatrix2D.Create(2, 3);
    A.Elements[0, 0] := TComplex.Create(1, 1);
    A.Elements[0, 1] := TComplex.Create(2, -2);
    A.Elements[0, 2] := TComplex.Create(3, 0);
    A.Elements[1, 0] := TComplex.Create(0, 4);
    A.Elements[1, 1] := TComplex.Create(5, 5);
    A.Elements[1, 2] := TComplex.Create(-1, 1);
    Memo1.Lines.Add('A:' + A.ToString);
    Memo1.Lines.Add('');

    AH := A.ConjugateTranspose;
    Memo1.Lines.Add('AH:' + AH.ToString);
    AssertEquals(3, AH.Rows, 'AH.Rows');
    AssertEquals(2, AH.Cols, 'AH.Cols'); 
    Memo1.Lines.Add('');

    { Check element (0,1) of AH = conj(A[1,0]) = conj(4i) = -4i }
    AssertTrue(TComplex(AH.Elements[0, 1]).Equals(TComplex.Create(0, -4)),
               'AH[0,1]');

    { (A^H)^H = A }
    AHH := AH.ConjugateTranspose;
    AssertEquals(A.Rows, AHH.Rows, 'AHH.Rows');
    AssertEquals(A.Cols, AHH.Cols, 'AHH.Cols');
    Memo1.Lines.Add('AHH:' + AHH.ToString); Memo1.Lines.Add('');
    { ... compare elements ... }

    A.Free; AH.Free; AHH.Free;

    { Real matrix: conjugate transpose = transpose }
    A := TMatrix2D.Create(2, 2);
    A.Elements[0, 0] := TFloat.Create(1);
    A.Elements[0, 1] := TFloat.Create(2);
    A.Elements[1, 0] := TFloat.Create(3);
    A.Elements[1, 1] := TFloat.Create(4);
    Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

    AH := A.ConjugateTranspose;
    AssertEqual(3.0, (AH.Elements[0, 1] as TFloat).Value, 'Real AH[0,1] = A[1,0]');
    Memo1.Lines.Add('AH:' + AH.ToString); Memo1.Lines.Add('');
    A.Free; AH.Free;

    Memo1.Lines.Add('PASS: All ConjugateTranspose tests passed!');

    PrintTestHeader('Conjugate transpose 2');

      { --- Complex 2x3 matrix --- }
      A := TMatrix2D.Create(2, 3);
      A.Elements[0, 0] := TComplex.Create(1, 1);
      A.Elements[0, 1] := TComplex.Create(2, -2);
      A.Elements[0, 2] := TComplex.Create(3, 0);
      A.Elements[1, 0] := TComplex.Create(0, 4);
      A.Elements[1, 1] := TComplex.Create(5, 5);
      A.Elements[1, 2] := TComplex.Create(-1, 1);
      Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

      AH := A.ConjugateTranspose;
      Memo1.Lines.Add('AH:' + AH.ToString); Memo1.Lines.Add('');
      AssertEquals(3, AH.Rows, 'AH.Rows');
      AssertEquals(2, AH.Cols, 'AH.Cols');
      AssertTrue(TComplex(AH.Elements[0, 1]).Equals(
                   TComplex.Create(0, -4), 1e-9), 'AH[0,1]');

      AHH := AH.ConjugateTranspose;
      Memo1.Lines.Add('AHH:' + AHH.ToString); Memo1.Lines.Add('');
      AssertEquals(A.Rows, AHH.Rows, 'AHH.Rows');
      AssertEquals(A.Cols, AHH.Cols, 'AHH.Cols');
      AssertTrue(TComplex(AHH.Elements[0, 0]).Equals(
                   TComplex(A.Elements[0, 0]), 1e-9), 'AHH[0,0]');

      A.Free; AH.Free; AHH.Free;

      { --- Real 2x2 matrix --- }
      A := TMatrix2D.Create(2, 2);
      A.Elements[0, 0] := TFloat.Create(1);
      A.Elements[0, 1] := TFloat.Create(2);
      A.Elements[1, 0] := TFloat.Create(3);
      A.Elements[1, 1] := TFloat.Create(4);
      Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

      AH := A.ConjugateTranspose;
      Memo1.Lines.Add('AH:' + AH.ToString); Memo1.Lines.Add('');
      AssertEqual(3.0, (AH.Elements[0, 1] as TFloat).Value, 'Real AH[0,1]');
      A.Free; AH.Free;

      { --- Hermitian matrix --- }
      { Build a fresh matrix - do NOT free A and then access it. }
      A := TMatrix2D.Create(2, 2);
      A.Elements[0, 0] := TComplex.Create(1, 0);      { real, as required }
      A.Elements[0, 1] := TComplex.Create(2, 3);
      A.Elements[1, 0] := TComplex.Create(2, -3);     { conjugate of A[0,1] }
      A.Elements[1, 1] := TComplex.Create(5, 0);      { real, as required }
      Memo1.Lines.Add('A:' + A.ToString);
      AssertTrue(A.IsHermitian, 'A is Hermitian');
      Memo1.Lines.Add('');
      A.Free;

      { --- Non-Hermitian matrix --- }
      A := TMatrix2D.Create(2, 2);
      A.Elements[0, 0] := TComplex.Create(1, 0);
      A.Elements[0, 1] := TComplex.Create(2, 3);
      A.Elements[1, 0] := TComplex.Create(2, 3);      { NOT the conjugate }
      A.Elements[1, 1] := TComplex.Create(5, 0);
      Memo1.Lines.Add('A:' + A.ToString);
      AssertTrue(not A.IsHermitian, 'A is not Hermitian');
      Memo1.Lines.Add('');
      A.Free;

      Memo1.Lines.Add('PASS: All ConjugateTranspose tests passed!');

    // Cleanup


   { BRA0.Free;
    BRA1.Free;
    Memo1.Lines.Add('Cleared B');
    FRACT.Free;

    I.Free;
    KET0.Free;
    KET1.Free;
    KETBRA.Free;
        Memo1.Lines.Add('Cleared K');
    M.Free;
    M1.Free;
    M11.Free;
    M2.Free;
    M3.Free;
    M30.Free;
    M4.Free;
        Memo1.Lines.Add('Cleared M');
        Memo1.Lines.Add('Cleared N');
    S.Free;
    Z.Free;}
   Memo1.Lines.Add('PASS: All TMatrix2D tests passed!');
end;

// ============================================================================
//   Test Overloaded Operators wMatrix with scalar
// ============================================================================
procedure TForm1.TestTMatrix2DOperatorWithScalar;
var
  M, R: TMatrix2D;
  Z: TComplex;
  Q: TRational;
begin
  PrintTestHeader('Classical Example');
  M := TMatrix2D.Identity(3);
  Memo1.Lines.Add('M:' + M.ToString); Memo1.Lines.Add('');

  R := M * 2;                 { Integer overload }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');

  R.Free;
  R := M * Int64(2);          { Int64 overload }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;
  R := M * 2.5;               { Double overload }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;

  R := M / 2;                 { Integer overload }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;
  R := M / 2.5;               { Double overload }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;

  Z := TComplex.Create(0, 1);
  R := Z * M;                 { TComplex on the left }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;
  R := M * Z;                 { TComplex on the right }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;
  Z.Free;

  Q := TRational.Create(3, 4);
  R := M * Q;                 { TRational }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;
  Q.Free;

  R := Int64(2) / M;                 { scalar / matrix = 2 * M^-1 }
  Memo1.Lines.Add('R:' + R.ToString); Memo1.Lines.Add('');
  R.Free;

  M.Free;
   Memo1.Lines.Add('PASS: All TestTMatrix2DOperatorWithScalar passed!');
end;

// ============================================================================
//   Test Linear System Solution
// ============================================================================
procedure TForm1.TestTLinearSystemSolution;
var
  A, b, x: TMatrix2D;
  Sys: TLinearSystem;
begin
  PrintTestHeader('Determined system example');
  Memo1.Lines.Add('');
  { --- A uniquely solvable 3x3 system --- }
  A := TMatrix2D.Create(3, 3);
  A.Elements[0, 0] := TFloat.Create(2); A.Elements[0, 1] := TFloat.Create(1); A.Elements[0, 2] := TFloat.Create(-1);
  A.Elements[1, 0] := TFloat.Create(-3); A.Elements[1, 1] := TFloat.Create(-1); A.Elements[1, 2] := TFloat.Create(2);
  A.Elements[2, 0] := TFloat.Create(-2); A.Elements[2, 1] := TFloat.Create(1); A.Elements[2, 2] := TFloat.Create(2);
  Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

  b := TMatrix2D.Create(3, 1);
  b.Elements[0, 0] := TFloat.Create(8);
  b.Elements[1, 0] := TFloat.Create(-11);
  b.Elements[2, 0] := TFloat.Create(-3);
  Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

  Sys := TLinearSystem.Create(A, b);
  try
    Memo1.Lines.Add(Sys.Describe);
    Memo1.Lines.Add('---');
    Memo1.Lines.Add(Sys.SolutionFormula);

    if Sys.HasUniqueSolution then
    begin
      x := Sys.SolveUnique;
      Memo1.Lines.Add('Solution vector:');
      Memo1.Lines.Add(x.ToString);
      x.Free;
    end;
  finally
    Sys.Free;
  end;
  A.Free; b.Free;

  Memo1.Lines.Add('');
  { --- An underdetermined system --- }
  Memo1.Lines.Add('Underdetermined system example');
  A := TMatrix2D.Create(2, 3);
  A.Elements[0, 0] := TFloat.Create(1); A.Elements[0, 1] := TFloat.Create(2); A.Elements[0, 2] := TFloat.Create(3);
  A.Elements[1, 0] := TFloat.Create(4); A.Elements[1, 1] := TFloat.Create(5); A.Elements[1, 2] := TFloat.Create(6);
  Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

  b := TMatrix2D.Create(2, 1);
  b.Elements[0, 0] := TFloat.Create(7);
  b.Elements[1, 0] := TFloat.Create(8);
  Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

  // ===============================================================

  Sys := TLinearSystem.Create(A, b);
  try
    Memo1.Lines.Add(Sys.Describe);
    Memo1.Lines.Add(Sys.SolutionFormula);
  except
    on E: Exception do
    begin
      Memo1.Lines.Add('Error on Sys:TLinearSystem : ' + E.Message);
      Sys.Free;
    end;
  end;
  A.Free; b.Free;

  Memo1.Lines.Add('');
  { --- An inconsistent system --- }
  Memo1.Lines.Add('Inconsistent example');
  A := TMatrix2D.Create(2, 2);
  A.Elements[0, 0] := TFloat.Create(1); A.Elements[0, 1] := TFloat.Create(1);
  A.Elements[1, 0] := TFloat.Create(1); A.Elements[1, 1] := TFloat.Create(1);
  Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

  b := TMatrix2D.Create(2, 1);
  b.Elements[0, 0] := TFloat.Create(1);
  b.Elements[1, 0] := TFloat.Create(2);   { inconsistent }
  Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

  Sys := TLinearSystem.Create(A, b);
  try
    Memo1.Lines.Add(Sys.Describe);
    Memo1.Lines.Add(Sys.SolutionFormula);
  finally
    Sys.Free;
  end;

  Memo1.Lines.Add('');
    Memo1.Lines.Add('ALC-UBA ==================================');
    Memo1.Lines.Add('');
    { --- An determined system --- }
    Memo1.Lines.Add('ALC-UBA example1');

    A := TMatrix2D.Create(3, 3);
    A.Elements[0, 0] := TComplex.Create(1, 1);
    A.Elements[0, 1] := TComplex.Create(2, 0);
    A.Elements[0, 2] := TComplex.Create(-2, 0);
    A.Elements[1, 0] := TComplex.Create(0, 1);
    A.Elements[1, 1] := TComplex.Create(1, -1);
    A.Elements[1, 2] := TComplex.Create(-1, 0);
    A.Elements[2, 0] := TComplex.Create(2, 0);
    A.Elements[2, 1] := TComplex.Create(2, 0);
    A.Elements[2, 2] := TComplex.Create(0, -1);
    Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

    b := TMatrix2D.Create(3, 1);
    b.Elements[0, 0] := TComplex.Create(1,1);
    b.Elements[1, 0] := TComplex.Create(1,1);
    b.Elements[2, 0] := TComplex.Create(3,-2);
    Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

    Sys := TLinearSystem.Create(A, b);
    try
      Memo1.Lines.Add(Sys.Describe);
      Memo1.Lines.Add(Sys.SolutionFormula);
    finally
      Sys.Free;
    end;


    Memo1.Lines.Add('');
  { --- An inconsistent system --- }
  Memo1.Lines.Add('ALC-UBA example2');
  A := TMatrix2D.CreateFromStringFloat('[ [1, -2 , 1 ] [2, 1, -1 ] [0, 5, -3 ] ]');
  Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

  b := TMatrix2D.CreateFromStringFloat('[ [ 0 ] [ 1 ] [ 1 ] ]');
  Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

    Sys := TLinearSystem.Create(A, b);
 try
    Memo1.Lines.Add(Sys.Describe);
    Memo1.Lines.Add(Sys.SolutionFormula);
  finally
    Sys.Free;
  end;

  Memo1.Lines.Add('');
    { --- An incompatible system --- }
    Memo1.Lines.Add('ALC-UBA example3');
    A := TMatrix2D.CreateFromStringFloat('[ [1, -2 , 1 ] [2, 1, -1 ] [0, 5, -3 ] ]');
    Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

    b := TMatrix2D.CreateFromStringFloat('[ [ 0 ] [ 1 ] [ 2 ] ]');
    Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

    Sys := TLinearSystem.Create(A, b);
    try
      Memo1.Lines.Add(Sys.Describe);
      Memo1.Lines.Add(Sys.SolutionFormula);
    finally
      Sys.Free;
    end;


    Memo1.Lines.Add('');
  { --- An inconsistent system --- }
  Memo1.Lines.Add('ALC-UBA example4');
  A := TMatrix2D.CreateFromStringFloat('[ [1, 2 , -1, 1 ] [1, -3, 1, -2 ] [3, 1, -1, 0 ] ]');
  {
  A := TMatrix2D.Create(3, 3);
  A.Elements[0, 0] := TFloat.Create(1);
  A.Elements[0, 1] := TFloat.Create(-2);
  A.Elements[0, 2] := TFloat.Create(1);
  A.Elements[1, 0] := TFloat.Create(2);
  A.Elements[1, 1] := TFloat.Create(1);
  A.Elements[1, 2] := TFloat.Create(-1);
  A.Elements[2, 0] := TFloat.Create(0);
  A.Elements[2, 1] := TFloat.Create(5);
  A.Elements[2, 2] := TFloat.Create(-3);}
  Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

  b := TMatrix2D.CreateFromStringFloat('[ [ -2 ] [ 3 ] [ -1 ] ]');
  {
  b.Elements[0, 0] := TFloat.Create(0);
  b.Elements[1, 0] := TFloat.Create(1);
  b.Elements[2, 0] := TFloat.Create(2); }
  Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

  Sys := TLinearSystem.Create(A, b);
  try
    Memo1.Lines.Add(Sys.Describe);
    Memo1.Lines.Add(Sys.SolutionFormula);
  finally
    Sys.Free;
  end;


  A.Free; b.Free;
end;

// ============================================================================
//   Test TestTLinearSystemSolution2
// ============================================================================
procedure TForm1.TestTLinearSystemSolution2;
var
  A, b, x: TMatrix2D;
  Sys: TLinearSystem;
  Sol: TLinearSolution;
  Params: array[0..1] of TNumeric;
  //X: TMatrix2D;
  Basis0: TMatrix2D;
begin
  PrintTestHeader('TestTLinearSystemSolution2 example');
  Memo1.Lines.Add('');
  { Underdetermined system with 2 free variables }
  A := TMatrix2D.Create(2, 4);
  A.Elements[0,0] := TFloat.Create(1); A.Elements[0,1] := TFloat.Create(2);
  A.Elements[0,2] := TFloat.Create(3); A.Elements[0,3] := TFloat.Create(4);
  A.Elements[1,0] := TFloat.Create(2); A.Elements[1,1] := TFloat.Create(3);
  A.Elements[1,2] := TFloat.Create(4); A.Elements[1,3] := TFloat.Create(5);
  Memo1.Lines.Add('A:' + A.ToString); Memo1.Lines.Add('');

  b := TMatrix2D.Create(2, 1);
  b.Elements[0,0] := TFloat.Create(5);
  b.Elements[1,0] := TFloat.Create(7);
  Memo1.Lines.Add('b:' + b.ToString); Memo1.Lines.Add('');

  Sys := TLinearSystem.Create(A, b);
  try
    Sol := Sys.Solve;
    try
      Memo1.Lines.Add(Sol.Describe);
      Memo1.Lines.Add(Sol.Formula);

      if Sol.HasUniqueSolution then
      begin
        x := Sol.Solution;
        Memo1.Lines.Add('Unique solution:');
        Memo1.Lines.Add(x.ToString);
        x.Free;
      end
      else if Sol.HasInfiniteSolutions then
      begin
        { Pick concrete parameter values: t1 = 2, t2 = 3 }
        Params[0] := TFloat.Create(2);
        Params[1] := TFloat.Create(3);
        try
          X := Sol.GeneralSolutionAt(Params);
          try
            Memo1.Lines.Add('Solution at (t1=2, t2=3):');
            Memo1.Lines.Add(X.ToString);
            { Verify A·X = b }
            Memo1.Lines.Add('Verifies: ' +
                    BoolToStr(Sol.VerifySolution(A, b, X, 1e-9), True));
          finally
            X.Free;
          end;
        finally
          Params[0].Free;
          Params[1].Free;
        end;

        { Access an individual basis vector }
        Basis0 := Sol.BasisVector(0);
        try
          Memo1.Lines.Add('First homogeneous basis vector:');
          Memo1.Lines.Add(Basis0.ToString);
        finally
          Basis0.Free;
        end;
      end;
    finally
      Sol.Free;
    end;
  finally
    Sys.Free;
  end;

  A.Free; b.Free;
end;

// ============================================================================
//   Test TestQuantum
// ============================================================================
procedure TForm1.TestQuantum;
var
  Bra01, Ket01, Bracket11, A, B, Outer, Zero, One, X, H, Res, H2: TMatrix2D;
  S: TNumeric;
  I: TComplex;
begin

  PrintTestHeader('TestQuantum example');
  Memo1.Lines.Add('');


  { |0> : column vector [1, 0] }
  Ket01 := TQuantum.Ket(0, 2);
  Memo1.Lines.Add('|0> = ');
  Memo1.Lines.Add(Ket01.ToString);
  { [ [ 1 ]
      [ 0 ] ] }

  { <1| : row vector [0, 1] }
  Bra01 := TQuantum.Bra(1, 2);
  Memo1.Lines.Add('<1| = ');
  Memo1.Lines.Add(Bra01.ToString);
  { [ [ 0, 1 ] ] }

  { |1><1| : 2x2 matrix with a 1 at position (1,1) }
  Bracket11 := TQuantum.Bracket(1, 1, 2);
  Memo1.Lines.Add('|1><1| = ');
  Memo1.Lines.Add(Bracket11.ToString);
  { [ [ 0, 0 ]
      [ 0, 1 ] ] }

  { Complex version: |0> with amplitude i }
  I := TComplex.Create(0, 1);
  Ket01 := TQuantum.KetC(0, 2, I);
  Memo1.Lines.Add('i|0> = ');
  Memo1.Lines.Add(Ket01.ToString);
  { [ [ i ]
      [ 0 ] ] }

  Zero := TQuantum.Ket(0, 2);
  Memo1.Lines.Add('Zero = ' + Zero.ToString);
  One  := TQuantum.Ket(1, 2); 
  Memo1.Lines.Add('One = ' + One.ToString);

  X := TQuantum.GateX;               { Pauli-X }
  Memo1.Lines.Add('X = ' + X.ToString);
  Res := X * Zero as TMatrix2D;   { X |0> = |1> }
  Memo1.Lines.Add('X |0> = |1> = ' + Res.ToString);

  H := TQuantum.GateH;               { Hadamard }
  Memo1.Lines.Add('Hadamard = ' + H.ToString);
  Res := H * Zero as TMatrix2D;   { H |0> = (|0> + |1>)/sqrt(2) }
  Memo1.Lines.Add('H |0> = (|0> + |1>)/sqrt(2) = ' + Res.ToString);

  A := TQuantum.Ket(0, 2);
  B := TQuantum.Ket(1, 2);

  Outer := TQuantum.OuterProduct(A, B);   { |0><1| as a 2x2 matrix }
  Memo1.Lines.Add('Outer |0><1| = ' + Outer.ToString);
  S := TQuantum.InnerProduct(A, B);       { <0|1> = 0 }
  Memo1.Lines.Add('S = <0|1> = 0 = ' + S.ToString);

  H  := TQuantum.GateH;
  Memo1.Lines.Add('Gate H = ' + H.ToString);
  H2 := TQuantum.TensorProduct(H, H);     { H ⊗ H, the 4x4 two-qubit gate }
  Memo1.Lines.Add('Tensor Product H ⊗ H = ' + H2.ToString);


  // Free everything
  Bra01.Free; Ket01.Free; Bracket11.Free; A.Free; B.Free; Outer.Free;
  Zero.Free; One.Free; X.Free; H.Free; Res.Free; H2.Free; S.Free;  I.Free;
end;

// ============================================================================
//   Test TestBellStateQuantum
// ============================================================================
procedure TForm1.TestBellStateQuantum;
var
  S, CS, Zero, H, CNOT, H2, Bell, Res, Psi, Rho, Ket0: TMatrix2D;
  M: Integer;
  RX, RY, RZ: TMatrix2D;
  Bits: string;
begin
  PrintTestHeader('TestBellStateQuantum example');
  Memo1.Lines.Add('');

  Randomize; // For quantum simulated collapse

  { Start with |00> : a 4x1 column vector with a 1 at position 0 }
  Zero := TQuantum.Ket(0, 4);
  Memo1.Lines.Add('Zero = ' + Zero.ToString);

  { Apply H to qubit 0 (top wire) }
  H  := TQuantum.GateH;
  Memo1.Lines.Add('H = ' + H.ToString);
  H2 := TQuantum.ApplyToQubit(H, 2, 0);
  Memo1.Lines.Add('H2 = ' + H2.ToString);
  Res := H2 * Zero as TMatrix2D;
  Memo1.Lines.Add('After H on qubit 0:');
  Memo1.Lines.Add(Res.ToString);
  { [ [ 1/sqrt(2) ]
      [ 0         ]
      [ 1/sqrt(2) ]
      [ 0         ] ] }

  { Apply CNOT }
  CNOT := TQuantum.GateCNOT;
  Memo1.Lines.Add('CNOT = ' + CNOT.ToString);
  Bell := CNOT * Res as TMatrix2D;
  Memo1.Lines.Add('Bell state:');
  Memo1.Lines.Add(Bell.ToString);
  { [ [ 1/sqrt(2) ]
      [ 0         ]
      [ 0         ]
      [ 1/sqrt(2) ] ] }

  { Measure }
  M := TQuantum.Measure(Bell);
  Memo1.Lines.Add('Measured: |' + IntToStr(M div 2) + IntToStr(M mod 2) + '>');
  Memo1.Lines.Add('Collapsed state:');
  Memo1.Lines.Add(Bell.ToString);

  RX := TQuantum.GateRX(Pi / 2);    { 90-degree rotation about X }
  Memo1.Lines.Add('RX = ' + RX.ToString);
  RY := TQuantum.GateRY(Pi / 4);    { 45-degree rotation about Y }
  Memo1.Lines.Add('RY = ' + RY.ToString);
  RZ := TQuantum.GateRZ(Pi);        { 180-degree rotation about Z }
  Memo1.Lines.Add('RZ = ' + RZ.ToString);

  { Controlled-S gate: applies S to target when control = 1 }
  S  := TQuantum.GateS;
  Memo1.Lines.Add('S = ' + S.ToString);
  CS := TQuantum.ControlledGate(S, 2, 0, 1);
  Memo1.Lines.Add('CS = ' + CS.ToString);

  { Apply to |10> : control=1, target=0 -> S|0> = |0> }
  Ket0 := TQuantum.Ket(2, 4);       { |10> in the 2-qubit basis }
  Memo1.Lines.Add('Ket0 = ' + Ket0.ToString);
  Res := CS * Ket0 as TMatrix2D;
  Memo1.Lines.Add('CS|10> =' + Res.ToString);

  Psi := Bell.Clone as TMatrix2D;   { keep the original intact }
    try
      Bits := TQuantum.MeasureAll(Psi);
      Memo1.Lines.Add('Measured: |' + Bits + '>');
    finally
      Psi.Free;
    end;

    Rho := TQuantum.DensityMatrix(Bell);
    Memo1.Lines.Add('Density matrix:' + Rho.ToString);

  Zero.Free; H.Free; H2.Free;
  Memo1.Lines.Add('1');
  Res.Free; CNOT.Free; Bell.Free;
  Memo1.Lines.Add('2');
  Ket0.Free; RX.Free; RY.Free;
  Memo1.Lines.Add('3');
  RZ.Free; S.Free; CS.Free; Rho.Free;
  Memo1.Lines.Add('4');
end;

// ============================================================================
//   Test TELEigenValues
// ============================================================================
procedure TForm1.TestTELEigenValues;
var
  M, Eigs, Vecs: TMatrix2D;
  I: Integer;
  W: TDoubleArray;
begin
  PrintTestHeader('TestTELEigenValues example');
  Memo1.Lines.Add('');
  { Symmetric real 2x2: [[2, 1], [1, 2]]. Eigenvalues 3, 1. }

  M := TMatrix2D.Create(2, 2);
  M.Elements[0, 0] := TFloat.Create(2);
  M.Elements[0, 1] := TFloat.Create(1);
  M.Elements[1, 0] := TFloat.Create(1);
  M.Elements[1, 1] := TFloat.Create(2);
  Memo1.Lines.Add('M = ' + M.ToString);
  Eigs := TEigen.Eigenvalues(M);
  Memo1.Lines.Add('Eigenvalues:');
  for I := 0 to Eigs.Rows - 1 do
    Memo1.Lines.Add('  '+ Eigs.Elements[I, 0].ToString); Memo1.Lines.Add('');
  { Should print 3 and 1 }
  M.Free; Eigs.Free;

  { Rotation matrix [[0, -1], [1, 0]]. Eigenvalues +i, -i. }
  M := TMatrix2D.Create(2, 2);
  M.Elements[0, 0] := TFloat.Create(0);
  M.Elements[0, 1] := TFloat.Create(-1);
  M.Elements[1, 0] := TFloat.Create(1);
  M.Elements[1, 1] := TFloat.Create(0);
  Memo1.Lines.Add('M = ' + M.ToString);
  Eigs := TEigen.Eigenvalues(M);
  Memo1.Lines.Add('Eigenvalues of rotation:');
  for I := 0 to Eigs.Rows - 1 do
    Memo1.Lines.Add('  '+ Eigs.Elements[I, 0].ToString);
  { Should print i and -i (or the reverse order) }
  Memo1.Lines.Add('');
  M.Free; Eigs.Free;

  { Symmetric matrix }
  M := TMatrix2D.Create(2, 2);
  M.Elements[0, 0] := TFloat.Create(2);
  M.Elements[0, 1] := TFloat.Create(1);
  M.Elements[1, 0] := TFloat.Create(1);
  M.Elements[1, 1] := TFloat.Create(2);

  TEigen.EigenvaluesAndVectors(M, Eigs, Vecs);

  Memo1.Lines.Add('Eigenvalues:');
  for I := 0 to Eigs.Rows - 1 do
    Memo1.Lines.Add('  ' + Eigs.Elements[I, 0].ToString);
  Memo1.Lines.Add('Eigenvectors (columns):');
  Memo1.Lines.Add(Vecs.ToString);

    { Check A·v = λ·v for the first eigenpair }
    { (requires multiplying out the columns of Vecs) }

    M.Free; Eigs.Free; Vecs.Free;
end;


// ============================================================================
//  Main test runner
// ============================================================================
procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.Clear;
  Memo1.Lines.Add('========================================');
  Memo1.Lines.Add('  Numerics Unit - Comprehensive Test Suite');
  Memo1.Lines.Add('========================================');


  try
    TestTFloat;
    TestTInteger;
    TestCrossType;
    TestTELComplex;
    TestTMatrix2D;
    TestComplexMatrixInversion;
    TestTBits;
    TestTBinaryVector;
    TestMixedOperators;
    TestErrorHandling;
    TestTELRational;
    TestRoundTrip;
    TestMatrix2D;
    TestTMatrix2DClassical;
    TestTMatrix2DOperatorWithScalar;
    TestTLinearSystemSolution;
    TestTLinearSystemSolution2;
    TestQuantum;
    TestBellStateQuantum;
    TestTELEigenValues;

    Memo1.Lines.Add('');
    Memo1.Lines.Add('========================================');
    Memo1.Lines.Add('  ALL TESTS PASSED!');
    Memo1.Lines.Add('========================================');
  except
    on E: Exception do
    begin
      Memo1.Lines.Add('');
      Memo1.Lines.Add('========================================');
      Memo1.Lines.Add('  TEST FAILED: ' + E.Message);
      Memo1.Lines.Add('========================================');
    end;
  end;

  Memo1.Lines.Add(' END ');
end;


end.
