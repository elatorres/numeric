unit TELNumeric;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  ENotImplemented = class(Exception);
  ENumericError   = class(Exception);

  // ============================================================================
  //  TNumeric  -  Abstract base class
  // ============================================================================

  TNumeric = class abstract
  public
    function Add     (const Other: TNumeric): TNumeric; virtual; abstract;
    function Subtract(const Other: TNumeric): TNumeric; virtual; abstract;
    function Multiply(const Other: TNumeric): TNumeric; virtual; abstract;
    function Divide  (const Other: TNumeric): TNumeric; virtual; abstract;
    function Negate  :                        TNumeric; virtual; abstract;
    function Clone   :                        TNumeric; virtual; abstract;
    function Zero    :                        TNumeric; virtual; abstract;
    function One     :                        TNumeric; virtual; abstract;


    { Inverse operation - default raises ENotImplemented }
    function Inverse :                        TNumeric; virtual;

    { Coerces any numeric to Double; used for cross-type operations. }
    function AsFloat: Double; virtual; abstract;

    { New: element-zero test used by generic algorithms. }
    function IsZero(const AEpsilon: Double = 1e-12): Boolean; virtual;

    { Human-readable representation; overrides TObject.ToString. }
    function ToString: string; override; abstract;
  end;

// ============================================================================
//  Operator overloads for TNumeric
// ============================================================================

operator + (A, B: TNumeric): TNumeric;
operator - (A, B: TNumeric): TNumeric;
operator * (A, B: TNumeric): TNumeric;
operator / (A, B: TNumeric): TNumeric;
operator - (A: TNumeric): TNumeric;

  // ============================================================================
  //  TNumeric  -  ENDS
  // ============================================================================



implementation


// ----------------------------------------------------------------------------
//  TNumeric Operators
// ----------------------------------------------------------------------------

operator + (A, B: TNumeric): TNumeric;
begin
  Result := A.Add(B);
end;

operator - (A, B: TNumeric): TNumeric;
begin
  Result := A.Subtract(B);
end;

operator * (A, B: TNumeric): TNumeric;
begin
  Result := A.Multiply(B);
end;

operator / (A, B: TNumeric): TNumeric;
begin
  Result := A.Divide(B);
end;

operator - (A: TNumeric): TNumeric;
begin
  Result := A.Negate;
end;

// ----------------------------------------------------------------------------
//  TNumeric - default implementation
// ----------------------------------------------------------------------------

function TNumeric.IsZero(const AEpsilon: Double): Boolean;
begin
  Result := Abs(AsFloat) <= AEpsilon;
end;

function TNumeric.Inverse: TNumeric;
begin
  raise ENotImplemented.Create(
    'TNumeric.Inverse: not implemented for this numeric type');
  Result := nil;
end;


end.

