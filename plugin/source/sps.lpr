library sps;

{$mode objfpc}{$H+}

uses
  Classes, sysutils, FileUtil, Interfaces, mufasatypes, bitmaps;

type
  T3DIntegerArray = array of T2DIntegerArray;
  T4DIntegerArray = array of T3DIntegerArray;

function SPS_ColorBoxesMatchInline(B1, B2: TIntegerArray; tol: extended): boolean; inline;
var
  oneMinusTol, tolPlusOne: extended;
begin
  oneMinusTol := 1 - tol;
  tolPlusOne := tol + 1;
  Result := ((B1[0] >= Round(B2[0] * oneMinusTol)) and
             (B1[0] <= Round(B2[0] * tolPlusOne))) and
            ((B1[1] >= Round(B2[1] * oneMinusTol)) and
             (B1[1] <= Round(B2[1] * tolPlusOne))) and
            ((B1[2] >= Round(B2[2] * oneMinusTol)) and
             (B1[2] <= Round(B2[2] * tolPlusOne)));
end;

function SPS_ColorBoxesMatch(B1, B2: TIntegerArray; tol: extended): boolean; register;
begin
  Result := SPS_ColorBoxesMatchInline(B1, B2, tol);
end;

function SPS_MakeColorBoxEx(bmp: TMufasaBitmap; x1, y1: integer): TIntegerArray;
var
  x, y, width: integer;
  C: TRGB32;
begin
  SetLength(Result, 3);
  width := bmp.Width; // may not be necessary, but should help a bit.

  for x := (x1 + 4) downto x1 do    // flipped these to downto since order is irrelevant
    for y := (y1 + 4) downto y1 do  // downto will calc the initial only once rather than each time.
    begin
      try
        C := bmp.FData[y * width + x];
        Result[0] := Result[0] + C.R;
        Result[1] := Result[1] + C.G;
        Result[2] := Result[2] + C.B;
      except end;
    end;
end;

function SPS_BitmapToMap(bmp: TMufasaBitmap): T3DIntegerArray; register;
var
  X, Y, HighX, HighY: integer;
begin
  HighX := Trunc(bmp.Width / (5.0));
  HighY := Trunc(bmp.Height / (5.0));

  SetLength(Result, HighX);
  for X := 0 to HighX - 1 do
  begin
    SetLength(Result[X], HighY);
    for Y := 0 to HighY - 1 do
    begin
      Result[X][Y] := SPS_MakeColorBoxEx(bmp, X * 5, Y * 5);
    end;
  end;
end;

function SPS_FindMapInMapEx(out fx, fy: integer; LargeMap: T4DIntegerArray; SmallMap: T3DIntegerArray; tol: extended): integer; register;
var
  x, y, HighX, HighY, cm, L: integer;
  xx, yy: integer;
  Matching, BestMatch: integer;
  b: Boolean;
begin
  fX := -1;
  fY := -1;
  BestMatch := 0;

  L := Length(LargeMap);
  Result := -1;

  for cm := 0 to L-1 do
  begin
    HighX := High(LargeMap[cm]) - 19;
    HighY := High(LargeMap[cm][0]) - 19;
    for x := 0 to HighX do
      for y := 0 to HighY do
      begin
        Matching := 0;
        for xx := 0 to 19 do
          for yy := 0 to 19 do
          begin
            b:= SPS_ColorBoxesMatchInline(LargeMap[cm][x+xx][y+yy], SmallMap[xx][yy], tol);
            if (b) then Inc(Matching);
          end;

        if (Matching > BestMatch) then
        begin
          BestMatch := Matching;
          Result := cm;
          fX := x;
          fY := y;
        end;
      end;
  end;

  if (Result > -1) then
  begin
    // moved outside to remove uncessary calculations in interations.
    fX := fX * 5 + 50;  // cause we want the center
    fy := fY * 5 + 50;
  end;
end;

procedure SetPluginMemManager(manager: TMemoryManager);
begin
  SetMemoryManager(manager);
end;

//////  EXPORTING  /////////////////////////////////////////////////////////////

function GetTypeCount(): Integer; stdcall; export;
begin
  Result := 2;
end;

function GetTypeInfo(x: Integer; var sType, sTypeDef: string): integer; stdcall; export;
begin
  case x of
    0: begin
        sType := 'T3DIntegerArray';
        sTypeDef := 'array of T2DIntegerArray;';
      end;
    1: begin
        sType := 'T4DIntegerArray';
        sTypeDef := 'array of T3DIntegerArray;';
      end;
    else
      x := -1;
  end;
  Result := x;
end;

function GetFunctionCount(): Integer; stdcall; export;
begin
  Result := 3;
end;

function GetFunctionCallingConv(x : Integer) : Integer; stdcall; export;
begin
  Result := 0;
  case x of
     0..2: Result := 1;
  end;
end;

function GetFunctionInfo(x: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; stdcall; export;
begin
  case x of
    0: begin
        ProcAddr := @SPS_ColorBoxesMatch;
        StrPCopy(ProcDef, 'function SPS_ColorBoxesMatch(B1, B2: TIntegerArray; tol: extended): boolean;');
      end;
    1:
      begin
        ProcAddr := @SPS_FindMapInMapEx;
        StrPCopy(ProcDef, 'function SPS_FindMapInMapEx(var fx, fy: integer; LargeMap: T4DIntegerArray; SmallMap: T3DIntegerArray; tol: extended): integer;');
      end;
    2:
      begin
        ProcAddr := @SPS_BitmapToMap;
        StrPCopy(ProcDef, 'function SPS_BitmapToMap(bmp: TMufasaBitmap): T3DIntegerArray;');
      end;
  else
    x := -1;
  end;
  Result := x;
end;

exports GetTypeCount;
exports GetTypeInfo;
exports GetFunctionCount;
exports GetFunctionInfo;
exports GetFunctionCallingConv;

begin
end.

