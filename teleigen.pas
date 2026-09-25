unit TELEigen;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math,
  TELNumeric, TELFloat, TELInteger, TELComplex, TELRational,
  TELMatrix2D;

type
  EEigenError = class(EMatrixError);

  TDoubleArray = array of Double;
  TDoubleMatrix = array of array of Double;
  TDoubleMatrixArray = array of TDoubleMatrix;
  TDoubleVector      = array of Double;
  TDoubleVectorArray = array of TDoubleVector;   { <-- this is what BasisRe needs }

  { Eigenvalue computation for TMatrix2D.

    All routines return a fresh N x 1 TMatrix2D of TComplex values;
    the caller owns the result. Input matrices may have any element type
    (TInteger, TFloat, TComplex, TRational); the algorithm promotes
    everything to floating-point internally. }
  TEigen = class
  public
    { Full eigenvalue solver. Works for any square real or complex matrix.
      Returns N complex eigenvalues (N x 1 column vector).
      The order of eigenvalues is unspecified. }
    class function Eigenvalues(const AM: TMatrix2D): TMatrix2D;
 //   class function Eigenvalues(const AM: TMatrix2D): TMatrix2D; static;

    { Fast path for Hermitian (self-adjoint) matrices. Uses the Jacobi
      algorithm, which is numerically robust and yields real eigenvalues
      for Hermitian input. The returned eigenvalues are still TComplex
      with zero imaginary part, for uniformity. Raises if AM is not
      Hermitian. }
    class function EigenvaluesHermitian(const AM: TMatrix2D): TMatrix2D; static;

    class procedure EigenvaluesAndVectors(const AM: TMatrix2D; out AEigs, AVecs: TMatrix2D); static;

    // class function EigenvectorFor(const AM: TMatrix2D;  static;

  end;

implementation

{ ================================================================
  Internal helpers
  ================================================================ }

{ Copy a TMatrix2D into a matrix of Double. If any cell is complex with
  non-zero imaginary part, we store the real part in RePart and the
  imaginary part in ImPart. This is the representation we work with
  throughout the algorithms. }
// type
  // TDoubleMatrix = array of array of Double;

  { Compute one eigenvalue of the 2x2 complex block
      [[a, b], [c, d]]
    using the quadratic formula with complex arithmetic.
    Returns the eigenvalue closer to d. }
  procedure WilkinsonShift(const ARe, AIm: TDoubleMatrix; const N: Integer;
    out MuRe, MuIm: Double);
  var
    ARe_, AIm_, BRe_, BIm_, CRe_, CIm_, DRe_, DIm_: Double;
    TraceRe, TraceIm: Double;   { (a+d)/2 }
    HalfDiffRe, HalfDiffIm: Double;   { (a-d)/2 }
    DiscRe, DiscIm: Double;    { (a-d)^2/4 + bc }
    SqrtRe, SqrtIm: Double;
    Lam1Re, Lam1Im, Lam2Re, Lam2Im: Double;
    D1, D2: Double;

    { Complex multiplication: (a+bi)*(c+di) }
    procedure CMul(ar, ai, br, bi: Double; out rr, ri: Double);
    begin
      rr := ar * br - ai * bi;
      ri := ar * bi + ai * br;
    end;

    { Complex square root: principal branch.
      sqrt(z) where z = re + i*im, using the standard formula
        r = |z|
        sqrt(z) = sqrt((r + re)/2) + i * sign(im) * sqrt((r - re)/2) }
    procedure CSqrt(re, im: Double; out sr, si: Double);
    var
      R, T: Double;
    begin
      if (re = 0.0) and (im = 0.0) then
      begin
        sr := 0.0; si := 0.0; Exit;
      end;
      R := Sqrt(re * re + im * im);
      T := Sqrt((R + re) / 2.0);
      if im >= 0 then
        si := Sqrt((R - re) / 2.0)
      else
        si := -Sqrt((R - re) / 2.0);
      sr := T;
    end;

  begin
    ARe_ := ARe[N - 2, N - 2]; AIm_ := AIm[N - 2, N - 2];
    BRe_ := ARe[N - 2, N - 1]; BIm_ := AIm[N - 2, N - 1];
    CRe_ := ARe[N - 1, N - 2]; CIm_ := AIm[N - 1, N - 2];
    DRe_ := ARe[N - 1, N - 1]; DIm_ := AIm[N - 1, N - 1];

    { trace/2 }
    TraceRe := 0.5 * (ARe_ + DRe_);
    TraceIm := 0.5 * (AIm_ + DIm_);

    { half-difference (a - d)/2 }
    HalfDiffRe := 0.5 * (ARe_ - DRe_);
    HalfDiffIm := 0.5 * (AIm_ - DIm_);

    { discriminant = halfDiff^2 + b*c }
    CMul(HalfDiffRe, HalfDiffIm, HalfDiffRe, HalfDiffIm, DiscRe, DiscIm);
    CMul(BRe_, BIm_, CRe_, CIm_, BRe_, BIm_);   { reuse BRe_, BIm_ as tmp }
    DiscRe := DiscRe + BRe_;
    DiscIm := DiscIm + BIm_;

    { complex sqrt of discriminant }
    CSqrt(DiscRe, DiscIm, SqrtRe, SqrtIm);

    { The two eigenvalues of the block: }
    Lam1Re := TraceRe + SqrtRe;  Lam1Im := TraceIm + SqrtIm;
    Lam2Re := TraceRe - SqrtRe;  Lam2Im := TraceIm - SqrtIm;

    { Pick the one closer to d }
    D1 := Sqr(Lam1Re - DRe_) + Sqr(Lam1Im - DIm_);
    D2 := Sqr(Lam2Re - DRe_) + Sqr(Lam2Im - DIm_);
    if D1 < D2 then
    begin
      MuRe := Lam1Re; MuIm := Lam1Im;
    end
    else
    begin
      MuRe := Lam2Re; MuIm := Lam2Im;
    end;
  end;

  procedure SortEigenvalues(const Eigs: TMatrix2D);
  var
    I, J: Integer;
    Zi, Zj: TComplex;
  begin
    for I := 0 to Eigs.Rows - 2 do
      for J := I + 1 to Eigs.Rows - 1 do
      begin
        Zi := TComplex(Eigs.Elements[I, 0]);
        Zj := TComplex(Eigs.Elements[J, 0]);
        if (Zi.RealD > Zj.RealD) or
           ((Zi.RealD = Zj.RealD) and (Zi.ImagD > Zj.ImagD)) then
          Eigs.SwapRows(I, J);    { TMatrix2D already has SwapRows }
      end;
  end;


procedure ToDoubleMatrices(const AM: TMatrix2D;
  out ARe, AIm: TDoubleMatrix);
var
  I, J: Integer;
  Cell: TNumeric;
  Z: TComplex;
begin
  SetLength(ARe, AM.Rows, AM.Cols);
  SetLength(AIm, AM.Rows, AM.Cols);
  for I := 0 to AM.Rows - 1 do
    for J := 0 to AM.Cols - 1 do
    begin
      Cell := AM.Elements[I, J];
      if Cell is TComplex then
      begin
        Z := TComplex(Cell);
        ARe[I, J] := Z.RealD;
        AIm[I, J] := Z.ImagD;
      end
      else
      begin
        ARe[I, J] := Cell.AsFloat;
        AIm[I, J] := 0.0;
      end;
    end;
end;

{ Is the matrix complex-typed? Used for choosing a real vs. complex
  QR path (we go complex if any cell is complex). }
function IsComplexMatrix(const AM: TMatrix2D): Boolean;
var
  I, J: Integer;
begin
  Result := False;
  for I := 0 to AM.Rows - 1 do
    for J := 0 to AM.Cols - 1 do
      if AM.Elements[I, J] is TComplex then
      begin
        Result := True;
        Exit;
      end;
end;

{ Is the matrix Hermitian? (A = A^H). Tolerances in float. }
function IsHermitian(const AM: TMatrix2D; const AEps: Double): Boolean;
var
  I, J: Integer;
  Aij, Aji: TNumeric;
  AjiConj: TNumeric;
  Diff: TNumeric;
  Z: TComplex;
  Re, Im: Double;
begin
  if AM.Rows <> AM.Cols then
  begin
    Result := False;
    Exit;
  end;
  for I := 0 to AM.Rows - 1 do
    for J := I to AM.Cols - 1 do
    begin
      Aij := AM.Elements[I, J];
      { Compute conj(A[j, i]) }
      if AM.Elements[J, I] is TComplex then
        AjiConj := TComplex(AM.Elements[J, I]).Conjugate
      else
        AjiConj := AM.Elements[J, I].Clone;
      try
        Diff := Aij.Subtract(AjiConj);
        try
          if Diff is TComplex then
          begin
            Z := TComplex(Diff);
            Re := Z.RealD;
            Im := Z.ImagD;
          end
          else
          begin
            Re := Diff.AsFloat;
            Im := 0.0;
          end;
          if (Abs(Re) > AEps) or (Abs(Im) > AEps) then
          begin
            Result := False;
            Exit;
          end;
        finally
          Diff.Free;
        end;
      finally
        AjiConj.Free;
      end;
    end;
  Result := True;
end;

{ ================================================================
  Jacobi eigenvalue algorithm for real symmetric matrices.
  Input: symmetric n x n real matrix A (double).
  Output: eigenvalues in W (length n).
  ================================================================ }

function JacobiEigenvalues(const A: TDoubleMatrix): TDoubleArray;
const
  MAX_ITER = 100;
var
  N, I, J, Ip, Iq: Integer;
  B: TDoubleMatrix;
  Sm, Thresh, Theta, T, C, S, Tau, G, H: Double;
  Iter: Integer;
  Done: Boolean;
begin
  N := Length(A);
  SetLength(B, N, N);
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      B[I, J] := A[I, J];

  SetLength(Result, N);

  Done := False;
  for Iter := 1 to MAX_ITER do
  begin
    Sm := 0.0;
    for Ip := 0 to N - 2 do
      for Iq := Ip + 1 to N - 1 do
        Sm := Sm + Abs(B[Ip, Iq]);
    if Sm = 0.0 then
    begin
      Done := True;
      Break;
    end;

    if Iter < 4 then
      Thresh := 0.2 * Sm / (N * N)
    else
      Thresh := 0.0;

    for Ip := 0 to N - 2 do
      for Iq := Ip + 1 to N - 1 do
      begin
        G := 100.0 * Abs(B[Ip, Iq]);
        if (Iter > 4) and
           (Abs(B[Ip, Ip]) + G = Abs(B[Ip, Ip])) and
           (Abs(B[Iq, Iq]) + G = Abs(B[Iq, Iq])) then
          B[Ip, Iq] := 0.0
        else if Abs(B[Ip, Iq]) > Thresh then
        begin
          H := B[Iq, Iq] - B[Ip, Ip];
          if Abs(H) + G = Abs(H) then
            T := B[Ip, Iq] / H
          else
          begin
            Theta := 0.5 * H / B[Ip, Iq];
            T := 1.0 / (Abs(Theta) + Sqrt(1.0 + Theta * Theta));
            if Theta < 0.0 then T := -T;
          end;

          C := 1.0 / Sqrt(1.0 + T * T);
          S := T * C;
          Tau := S / (1.0 + C);

          H := T * B[Ip, Iq];
          B[Ip, Ip] := B[Ip, Ip] - H;
          B[Iq, Iq] := B[Iq, Iq] + H;
          B[Ip, Iq] := 0.0;

          for J := 0 to Ip - 1 do
          begin
            G := B[J, Ip];
            H := B[J, Iq];
            B[J, Ip] := G - S * (H + G * Tau);
            B[J, Iq] := H + S * (G - H * Tau);
          end;
          for J := Ip + 1 to Iq - 1 do
          begin
            G := B[Ip, J];
            H := B[J, Iq];
            B[Ip, J] := G - S * (H + G * Tau);
            B[J, Iq] := H + S * (G - H * Tau);
          end;
          for J := Iq + 1 to N - 1 do
          begin
            G := B[Ip, J];
            H := B[Iq, J];
            B[Ip, J] := G - S * (H + G * Tau);
            B[Iq, J] := H + S * (G - H * Tau);
          end;
        end;
      end;
  end;

  for I := 0 to N - 1 do
    Result[I] := B[I, I];
end;

class function TEigen.EigenvaluesHermitian(const AM: TMatrix2D): TMatrix2D;
var
  ARe, AIm: TDoubleMatrix;
  W: TDoubleArray;
  I, N: Integer;
begin
  if AM.Rows <> AM.Cols then
    raise EEigenError.CreateFmt(
      'TEigen.EigenvaluesHermitian: matrix must be square (%dx%d)',
      [AM.Rows, AM.Cols]);
  if not IsHermitian(AM, 1e-10) then
    raise EEigenError.Create(
      'TEigen.EigenvaluesHermitian: matrix is not Hermitian');

  N := AM.Rows;
  ToDoubleMatrices(AM, ARe, AIm);

  W := JacobiEigenvalues(ARe);

  Result := TMatrix2D.Create(N, 1);
  for I := 0 to N - 1 do
    Result.Elements[I, 0] := TComplex.Create(W[I], 0.0);
end;

{ Compute QR decomposition of an N x N complex matrix A (in-place).
  Returns Q, R. Both as (Re, Im) pairs of Double arrays. }
procedure ComplexQR(const ARe, AIm: TDoubleMatrix;
  out QRe, QIm, RRe, RIm: TDoubleMatrix);
var
  N, I, J, K: Integer;
  RRe_, RIm_: array of array of Double;
  QRe_, QIm_: array of array of Double;
  XRe, XIm, YRe, YIm: Double;
  Xabs, Rnorm, C: Double;
  SRe, SIm: Double;

  { Complex magnitude |a + bi| }
  function CMag(re, im: Double): Double;
  begin
    Result := Sqrt(re * re + im * im);
  end;

begin
  N := Length(ARe);
  SetLength(RRe_, N, N);
  SetLength(RIm_, N, N);
  SetLength(QRe_, N, N);
  SetLength(QIm_, N, N);

  { Initialize R := A, Q := I }
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      RRe_[I, J] := ARe[I, J];
      RIm_[I, J] := AIm[I, J];
      if I = J then
      begin
        QRe_[I, J] := 1.0; QIm_[I, J] := 0.0;
      end
      else
      begin
        QRe_[I, J] := 0.0; QIm_[I, J] := 0.0;
      end;
    end;

  { For each column J, zero out R[I, J] for I = J+1 .. N-1. }
  for J := 0 to N - 2 do
    for I := J + 1 to N - 1 do
    begin
      XRe := RRe_[J, J]; XIm := RIm_[J, J];
      YRe := RRe_[I, J]; YIm := RIm_[I, J];

      Xabs := CMag(XRe, XIm);
      Rnorm := Sqrt(Xabs * Xabs + CMag(YRe, YIm) * CMag(YRe, YIm));
      if Rnorm = 0.0 then Continue;

      { Complex Givens rotation:
          if X = 0:  c = 0,  s = Y / |Y|
          else:      c = |X| / r,  s = (X/|X|) * conj(Y) / r
        The rotation matrix is
          G = [ c      s    ]
              [ -conj(s)  c ]
        and G^H is its conjugate transpose. }
      if Xabs = 0.0 then
      begin
        C := 0.0;
        SRe := YRe / Rnorm;
        SIm := YIm / Rnorm;
      end
      else
      begin
        C := Xabs / Rnorm;
        { (X / |X|) * conj(Y) / r }
        SRe := (XRe * YRe + XIm * YIm) / (Xabs * Rnorm);
        SIm := (XRe * YIm - XIm * YRe) / (Xabs * Rnorm);
      end;

      { Apply G on the left of R:
          new R[J, :] = c * R[J, :] + s * R[I, :]
          new R[I, :] = -conj(s) * R[J, :] + c * R[I, :]
        Use old row values. }
      for K := 0 to N - 1 do
      begin
        XRe := RRe_[J, K]; XIm := RIm_[J, K];
        YRe := RRe_[I, K]; YIm := RIm_[I, K];

        { new R[J, K] = c * X + s * Y }
        RRe_[J, K] := C * XRe + (SRe * YRe - SIm * YIm);
        RIm_[J, K] := C * XIm + (SRe * YIm + SIm * YRe);

        { new R[I, K] = -conj(s) * X + c * Y }
        RRe_[I, K] := C * YRe - (SRe * XRe + SIm * XIm);
        RIm_[I, K] := C * YIm - (SRe * XIm - SIm * XRe);
      end;

      { Accumulate into Q: Q := Q * G^H.  G^H is
          [ c        -s    ]
          [ conj(s)   c    ]
        Applying to columns J and I of Q:
          new Q[:, J] = c * Q[:, J] + conj(s) * Q[:, I]
          new Q[:, I] = -s * Q[:, J] + c * Q[:, I] }
      for K := 0 to N - 1 do
      begin
        XRe := QRe_[K, J]; XIm := QIm_[K, J];
        YRe := QRe_[K, I]; YIm := QIm_[K, I];

        { new Q[K, J] = c * X + conj(s) * Y }
        QRe_[K, J] := C * XRe + (SRe * YRe + SIm * YIm);
        QIm_[K, J] := C * XIm + (SRe * YIm - SIm * YRe);

        { new Q[K, I] = -s * X + c * Y }
        QRe_[K, I] := C * YRe - (SRe * XRe - SIm * XIm);
        QIm_[K, I] := C * YIm - (SRe * XIm + SIm * XRe);
      end;
    end;

  { Copy working arrays to outputs }
  SetLength(RRe, N, N); SetLength(RIm, N, N);
  SetLength(QRe, N, N); SetLength(QIm, N, N);
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      RRe[I, J] := RRe_[I, J]; RIm[I, J] := RIm_[I, J];
      QRe[I, J] := QRe_[I, J]; QIm[I, J] := QIm_[I, J];
    end;
end;

{ Multiply two complex N x N matrices. }
procedure ComplexMul(const ARe, AIm, BRe, BIm: TDoubleMatrix;
  out CRe, CIm: TDoubleMatrix);
var
  N, I, J, K: Integer;
  SumRe, SumIm: Double;
begin
  N := Length(ARe);
  SetLength(CRe, N, N);
  SetLength(CIm, N, N);
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      SumRe := 0.0;
      SumIm := 0.0;
      for K := 0 to N - 1 do
      begin
        SumRe := SumRe + ARe[I, K] * BRe[K, J] - AIm[I, K] * BIm[K, J];
        SumIm := SumIm + ARe[I, K] * BIm[K, J] + AIm[I, K] * BRe[K, J];
      end;
      CRe[I, J] := SumRe;
      CIm[I, J] := SumIm;
    end;
end;

class function TEigen.Eigenvalues(const AM: TMatrix2D): TMatrix2D;
const
  MAX_ITER = 1000;
  EPS = 1e-12;
var
  N, I, J, Iter: Integer;
  ARe, AIm: TDoubleMatrix;
  QRe, QIm, RRe, RIm, TmpRe, TmpIm: TDoubleMatrix;
  OffDiag, MuRe, MuIm: Double;
  Converged: Boolean;
begin
  if AM.Rows <> AM.Cols then
    raise EEigenError.CreateFmt(
      'TEigen.Eigenvalues: matrix must be square (%dx%d)',
      [AM.Rows, AM.Cols]);

  N := AM.Rows;
  if N = 0 then
    raise EEigenError.Create('TEigen.Eigenvalues: empty matrix');

  { 1x1 case }
  if N = 1 then
  begin
    Result := TMatrix2D.Create(1, 1);
    Result.Elements[0, 0] := AM.Elements[0, 0].Clone;
    Exit;
  end;

  { Fast path: Hermitian matrices }
  if IsHermitian(AM, 1e-10) then
  begin
    Result := EigenvaluesHermitian(AM);
    Exit;
  end;

  ToDoubleMatrices(AM, ARe, AIm);

  Converged := False;
  for Iter := 1 to MAX_ITER do
  begin
    { Check convergence of the subdiagonal }
    OffDiag := 0.0;
    for I := 1 to N - 1 do
      OffDiag := OffDiag + Abs(ARe[I, I - 1]) + Abs(AIm[I, I - 1]);
    if OffDiag <= EPS then
    begin
      Converged := True;
      Break;
    end;

    { --- Complex Wilkinson shift (this is the general fix) --- }
    WilkinsonShift(ARe, AIm, N, MuRe, MuIm);

    { Subtract the shift }
    for I := 0 to N - 1 do
    begin
      ARe[I, I] := ARe[I, I] - MuRe;
      AIm[I, I] := AIm[I, I] - MuIm;
    end;

    { QR factorization of the shifted matrix }
    ComplexQR(ARe, AIm, QRe, QIm, RRe, RIm);

    { A := R * Q + shift * I }
    ComplexMul(RRe, RIm, QRe, QIm, TmpRe, TmpIm);
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
      begin
        ARe[I, J] := TmpRe[I, J];
        AIm[I, J] := TmpIm[I, J];
      end;
    for I := 0 to N - 1 do
    begin
      ARe[I, I] := ARe[I, I] + MuRe;
      AIm[I, I] := AIm[I, I] + MuIm;
    end;
  end;

  { Extract eigenvalues from the diagonal }
  Result := TMatrix2D.Create(N, 1);
  for I := 0 to N - 1 do
    Result.Elements[I, 0] := TComplex.Create(ARe[I, I], AIm[I, I]);
end;




{ Normalize a complex vector to unit Euclidean norm.
  Also applies a phase so that the entry with largest magnitude is real
  and positive, making the result deterministic. }
procedure NormalizeComplexVector(var VRe, VIm: TDoubleVector);
var
  I, MaxIdx: Integer;
  Norm, MaxMag, Mag: Double;
  CosPhi, SinPhi, RotRe, RotIm: Double;
  TempRe, TempIm: Double;
begin
  { Compute Euclidean norm. }
  Norm := 0.0;
  for I := 0 to High(VRe) do
    Norm := Norm + VRe[I] * VRe[I] + VIm[I] * VIm[I];
  Norm := Sqrt(Norm);
  if Norm < 1e-300 then Exit;

  { Divide every entry by the norm. }
  for I := 0 to High(VRe) do
  begin
    VRe[I] := VRe[I] / Norm;
    VIm[I] := VIm[I] / Norm;
  end;

  { Find the entry with largest magnitude. }
  MaxIdx := 0;
  MaxMag := Sqrt(VRe[0] * VRe[0] + VIm[0] * VIm[0]);
  for I := 1 to High(VRe) do
  begin
    Mag := Sqrt(VRe[I] * VRe[I] + VIm[I] * VIm[I]);
    if Mag > MaxMag then
    begin
      MaxMag := Mag;
      MaxIdx := I;
    end;
  end;

  if MaxMag < 1e-300 then Exit;

  { Phase of the largest entry: phi = atan2(Im, Re).
    We want to rotate the whole vector by -phi so that entry becomes real
    and positive. }
  CosPhi := VRe[MaxIdx] / MaxMag;
  SinPhi := VIm[MaxIdx] / MaxMag;

  { Rotate by exp(-i * phi): (re + i*im) * (cos - i*sin) }
  for I := 0 to High(VRe) do
  begin
    TempRe := VRe[I] * CosPhi + VIm[I] * SinPhi;
    TempIm := VIm[I] * CosPhi - VRe[I] * SinPhi;
    VRe[I] := TempRe;
    VIm[I] := TempIm;
  end;
end;






{ Compute a basis for the nullspace of M = A - λI. The matrix M is
  given as ARe, AIm (the original matrix), and lambda as LRe, LIm.

  Returns a set of basis vectors as (VecRe, VecIm), each of length n.
  The caller frees them by simply letting the dynamic arrays go out of
  scope. }
procedure NullspaceOf(const ARe, AIm: TDoubleMatrix;
  const LRe, LIm: Double;
  var BasisRe, BasisIm: TDoubleVectorArray);
var
  N, I, J: Integer;
  M: TMatrix2D;
  RREFM: TMatrix2D;
  PivotCols, FreeCols: TIntegerArray;
  Cell: TNumeric;
  Z: TComplex;
  PivotRow: Integer;
  VecRe, VecIm: TDoubleVector;
  BasisCount, Fi: Integer;
  PivotColIdx: Integer;
begin
  N := Length(ARe);

  { --- Build M = A - λI as TMatrix2D of TComplex. --- }
  M := TMatrix2D.Create(N, N);
  try
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
        if I = J then
          M.Elements[I, J] := TComplex.Create(ARe[I, J] - LRe,
                                              AIm[I, J] - LIm)
        else
          M.Elements[I, J] := TComplex.Create(ARe[I, J], AIm[I, J]);

    RREFM := M.RREF(False);
    try
      PivotCols := RREFM.PivotColumns(False);
      FreeCols  := RREFM.FreeColumns(False);

      SetLength(BasisRe, Length(FreeCols));
      SetLength(BasisIm, Length(FreeCols));

      for Fi := 0 to High(FreeCols) do
      begin
        J := FreeCols[Fi];
        SetLength(VecRe, N);
        SetLength(VecIm, N);

        { Free variable = 1 }
        VecRe[J] := 1.0;
        VecIm[J] := 0.0;

        { For each pivot row I, pivot variable = -RREF[I, J] }
        for I := 0 to High(PivotCols) do
        begin
          PivotColIdx := PivotCols[I];
          Cell := RREFM.Elements[I, J];
          if Cell is TComplex then
          begin
            Z := TComplex(Cell);
            VecRe[PivotColIdx] := -Z.RealD;
            VecIm[PivotColIdx] := -Z.ImagD;
          end
          else
          begin
            VecRe[PivotColIdx] := -Cell.AsFloat;
            VecIm[PivotColIdx] := 0.0;
          end;
        end;

        BasisRe[Fi] := VecRe;
        BasisIm[Fi] := VecIm;
      end;
    finally
      RREFM.Free;
    end;
  finally
    M.Free;
  end;
end;



class function EigenvectorFor(const AM: TMatrix2D;
  const ALambda: TComplex): TMatrix2D;
var
  ARe, AIm: TDoubleMatrix;
  BasisRe, BasisIm: TDoubleVectorArray;
  N, I: Integer;
  LRe, LIm: Double;
begin
  if AM.Rows <> AM.Cols then
    raise EEigenError.CreateFmt(
      'TEigen.EigenvectorFor: matrix must be square (%dx%d)',
      [AM.Rows, AM.Cols]);
  if ALambda = nil then
    raise EEigenError.Create('TEigen.EigenvectorFor: lambda is nil');

  N := AM.Rows;
  ToDoubleMatrices(AM, ARe, AIm);
  LRe := ALambda.RealD;
  LIm := ALambda.ImagD;

    NullspaceOf(ARe, AIm, LRe, LIm, BasisRe, BasisIm);

  if Length(BasisRe) = 0 then
    raise EEigenError.CreateFmt(
      'TEigen.EigenvectorFor: %s is not an eigenvalue of the matrix',
      [ALambda.ToString]);

  { Normalize and return the first basis vector. }
  NormalizeComplexVector(BasisRe[0], BasisIm[0]);

  Result := TMatrix2D.Create(N, 1);
  for I := 0 to N - 1 do
    Result.Elements[I, 0] := TComplex.Create(BasisRe[0][I], BasisIm[0][I]);
end;


class procedure TEigen.EigenvaluesAndVectors(const AM: TMatrix2D;
  out AEigs, AVecs: TMatrix2D);
const
  TOL = 1e-8;
var
  Eigs: TMatrix2D;
  N, I, J, K, BasisCount, Bi, ColIndex: Integer;
  ARe, AIm: TDoubleMatrix;
  BasisRe, BasisIm: TDoubleVectorArray;
  LRe, LIm: Double;
  Processed: array of Boolean;
  LamI: TComplex;
  LamJ: TComplex;
  SameEigenvalue: Boolean;
begin
  if AM.Rows <> AM.Cols then
    raise EEigenError.CreateFmt(
      'TEigen.EigenvaluesAndVectors: matrix must be square (%dx%d)',
      [AM.Rows, AM.Cols]);

  N := AM.Rows;
  Eigs := Eigenvalues(AM);
  AEigs := Eigs;

  AVecs := TMatrix2D.Create(N, N);
  ToDoubleMatrices(AM, ARe, AIm);

  SetLength(Processed, N);
  for I := 0 to N - 1 do
    Processed[I] := False;

  ColIndex := 0;
  for I := 0 to N - 1 do
  begin
    if Processed[I] then Continue;

    LamI := TComplex(Eigs.Elements[I, 0]);
    LRe := LamI.RealD;
    LIm := LamI.ImagD;

    { Mark this and all matching eigenvalues as processed. }
    for J := I to N - 1 do
    begin
      if Processed[J] then Continue;
      LamJ := TComplex(Eigs.Elements[J, 0]);
      SameEigenvalue := (Abs(LamI.RealD - LamJ.RealD) < TOL) and
                        (Abs(LamI.ImagD - LamJ.ImagD) < TOL);
      if SameEigenvalue then
        Processed[J] := True;
    end;

    { Compute the nullspace of A - λI; its dimension is the geometric
      multiplicity of λ (may be less than the algebraic multiplicity if
      the matrix is defective). }
    NullspaceOf(ARe, AIm, LRe, LIm, BasisRe, BasisIm);

    { Fill the corresponding columns of AVecs with the basis vectors,
      each normalized. }
    for Bi := 0 to High(BasisRe) do
    begin
      if ColIndex >= N then Break;
      NormalizeComplexVector(BasisRe[Bi], BasisIm[Bi]);
      for J := 0 to N - 1 do
        AVecs.Elements[J, ColIndex] :=
          TComplex.Create(BasisRe[Bi][J], BasisIm[Bi][J]);
      Inc(ColIndex);
    end;
  end;

  { If the matrix is defective (fewer independent eigenvectors than N),
    the trailing columns of AVecs remain the default TFloat(0) fillers.
    A more elaborate implementation would compute generalised
    eigenvectors here; for now we simply leave those columns as zeros. }
end;


end.




