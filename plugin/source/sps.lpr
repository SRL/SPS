library sps;

{$mode objfpc}{$H+}

uses
  classes, sysutils, fileutil, math, interfaces, mufasatypes, bitmaps,
  colour_conv
  { you can add units after this };

type
  T3DIntegerArray = array of T2DIntegerArray;
  T4DIntegerArray = array of T3DIntegerArray;

(**
 * Retruns true if the color boxes (B1 and B2) match within the tolerance (tol).
 *)
function SPS_ColorBoxesMatchInline(B1, B2: TIntegerArray; tol: extended): boolean; inline;
begin
  Result := False;

  // B[0] = Red; B[1] = Green, B[2] = Blue (see SPS_MakeColorBox)

  if ((B2[0] + B2[1] + B2[2]) = 0) then
    Exit;

  // if the difference between the two 'color boxes' RGB values are less than the tolerance
  if (abs(B1[0] - B2[0]) < tol) then
    if (abs(B1[1] - B2[1]) < tol) then
      if (abs(B1[2] - B2[2]) < tol) then
        Result := True;
end;

(**
 * Returns the TOTAL RGB values of each pixel in a box (starting at x1, y1 with
 * side lengths 'SideLength') on the bitmap (bmp).
 *
 *    Result[0] = Red
 *    Result[1] = Green
 *    Result[2] = Blue
 *)
function SPS_MakeColorBox(bmp: TMufasaBitmap; x1, y1, SideLength: integer): TIntegerArray; register;
var
  x, y, C, R, G, B: integer;
begin
  SetLength(Result, 3);

  for x := (x1 + SideLength - 1) downto x1 do
    for y := (y1 + SideLength - 1) downto y1 do
    begin
      C := bmp.fastGetPixel(x, y);
      ColorToRGB(C, R, G, B);

      Result[0] := Result[0] + R;
      Result[1] := Result[1] + G;
      Result[2] := Result[2] + B;
    end;
end;

(**
 * Filters the edges of the minimap so only the circle appears as colors.
 *)
procedure SPS_FilterMinimap(var Minimap: TMufasaBitmap); register;
var
  W, H, x, y: integer;
begin
  W := Minimap.width;
  H := Minimap.height;

  for x := W - 1 downto 0 do
    for y := H - 1 downto 0 do
      if hypot(abs(75.0 - x), abs(75.0 - y)) > 75 then
      begin
        Minimap.FastSetPixel(x, y, 0);
        continue;
      end;
end;

(**
 * Converts the bitmap (bmp) to a 'grid' of color boxes.
 *)
function SPS_BitmapToMap(bmp: TMufasaBitmap; SideLength: integer): T3DIntegerArray; register;
var
  X, Y, HighX, HighY: integer;
begin
  HighX := Trunc(bmp.Width / (SideLength * 1.0));
  HighY := Trunc(bmp.Height / (SideLength * 1.0));

  SetLength(Result, HighX);
  for X := 0 to HighX - 1 do
  begin
    SetLength(Result[X], HighY);
    for Y := 0 to HighY - 1 do
    begin
      Result[X][Y] := SPS_MakeColorBox(bmp, X * SideLength, Y * SideLength, SideLength);
    end;
  end;
end;

(**
 * Returns 4 variables:
 *    fx, fy: The X and Y of the grid piece in SmallMap that best matches the LargeMap.
 *    FoundMatches: The number of color box matches found.
 *    Result: The index of the SPS_Area with the best match.
 *)
function SPS_FindMapInMap(out fx, fy: integer; LargeMap: T4DIntegerArray; SmallMap: T3DIntegerArray; tol: extended; out FoundMatches: integer): integer; register;
var
  x, y, HighX, HighY, cm, L: integer;
  xx, yy: integer;
  Matching: integer;
  BoxesInViewX, BoxesInViewY: integer;
begin
  fX := -1;
  fY := -1;
  Result := -1;
  FoundMatches := 0;
  L := Length(LargeMap);
  BoxesInViewX := Length(SmallMap);    // columns in the grid
  BoxesInViewY := Length(SmallMap[0]); // rows in the grid

  //writeln('SPS_FindMapInMap: BoxesInViewX: '+intToStr(BoxesInViewX));
  //writeln('SPS_FindMapInMap: BoxesInViewY: '+intToStr(BoxesInViewY));

  for cm := 0 to (L - 1) do // loop through each SPS area (i.e. map piece)
  begin
    HighX := High(LargeMap[cm]) - BoxesInViewX;
    HighY := High(LargeMap[cm][0]) - BoxesInViewY;

    //writeln('SPS_FindMapInMap: HighX: '+intToStr(HighX));
    //writeln('SPS_FindMapInMap: HighY: '+intToStr(HighY));

    for x := 0 to HighX do
      for y := 0 to HighY do
      begin
        Matching := 0;

        // compares the minimap to a chunch of the SPS_Area
        for xx := BoxesInViewX - 1 downto 0 do
          for yy := BoxesInViewY - 1 downto 0 do
            if (SPS_ColorBoxesMatchInline(LargeMap[cm][x+xx][y+yy], SmallMap[xx][yy], tol)) then
              Matching := (Matching + 1);

        if (Matching > FoundMatches) then
        begin
          FoundMatches := Matching;
          Result := cm;
          fX := x;
          fY := y;
        end;
      end;
  end;
end;

(**
 * EXPORTING
 *)

procedure SetPluginMemoryManager(MemMgr : TMemoryManager); stdcall; export;
begin
  SetMemoryManager(MemMgr);
end;

function GetTypeCount(): Integer; stdcall; export;
begin
  Result := 3;
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

    2: begin
         sType := 'TMufasaBitmapArray';
         sTypeDef := 'array of TMufasaBitmap';
       end;

    else
      x := -1;
  end;

  Result := x;
end;

function GetFunctionCount(): Integer; stdcall; export;
begin
  Result := 4;
end;

function GetFunctionCallingConv(x : Integer) : Integer; stdcall; export;
begin
  Result := 0;

  case x of
    0..3: Result := 1;
  end;
end;

function GetFunctionInfo(x: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; stdcall; export;
begin
  case x of
    0:
      begin
        ProcAddr := @SPS_FindMapInMap;
        StrPCopy(ProcDef, 'function SPS_FindMapInMap(out fx, fy: integer; LargeMap: T4DIntegerArray; SmallMap: T3DIntegerArray; tol: extended; out FoundMatches: integer): integer;');
      end;
    1:
      begin
        ProcAddr := @SPS_BitmapToMap;
        StrPCopy(ProcDef, 'function SPS_BitmapToMap(bmp: TMufasaBitmap; SideLength: integer): T3DIntegerArray;');
      end;
    2:
      begin
        ProcAddr := @SPS_MakeColorBox;
        StrPCopy(ProcDef, 'function SPS_MakeColorBox(bmp: TMufasaBitmap; x1, y1, SideLength: integer): TIntegerArray;');
      end;
    3:
      begin
        ProcAddr := @SPS_FilterMinimap;
        StrPCopy(ProcDef, 'procedure SPS_FilterMinimap(var Minimap: TMufasaBitmap);');
      end;

    else
      x := -1;
  end;

  Result := x;
end;

exports SetPluginMemoryManager;
exports GetTypeCount;
exports GetTypeInfo;
exports GetFunctionCount;
exports GetFunctionInfo;
exports GetFunctionCallingConv;

begin
end.

