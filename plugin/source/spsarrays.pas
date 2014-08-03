unit spsArrays;

{$mode objfpc}{$H+}
{$Inline on}
{$macro on}
{$define Callconv:=
    {$IFDEF WINDOWS}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
    {$IFDEF LINUX}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
}

interface

uses
  Classes, SysUtils, MufasaTypes, spsTypes;

function SPS_GetMaxValue(const Mat: T2DSingleArray): TPoint; Callconv
procedure SPS_GetMaxValues(const Mat: T2DSingleArray; const Count: Integer; var Res: TPointArray); Callconv
procedure SPS_CombineMatrix(const Mat1, Mat2: T2DSingleArray; var Res: T2DSingleArray); Callconv

implementation

// Heap stuff, super fast MaxA
procedure _movedownHI(var heap:THeapArrayF; startpos, pos:Int32); Inline;
var
  parentpos: Int32;
  parent,newitem:THeapItemF;
begin
  newitem := heap[pos];
  while (pos > startpos) do begin
    parentpos := (pos - 1) shr 1;
    parent := heap[parentpos];
    if (newitem.value < parent.value) then
    begin
      heap[pos] := parent;
      pos := parentpos;
      continue;
    end;
    break;
  end;
  heap[pos] := newitem;
end;

procedure _moveupHI(var heap:THeapArrayF; pos:Int32); Inline;
var
  endpos,startpos,childpos,rightpos:Int32;
  newitem: THeapItemF;
begin
  endpos := length(heap);
  startpos := pos;
  newitem := heap[pos];

  childpos := 2 * pos + 1;
  while childpos < endpos do begin
      rightpos := childpos + 1;
      if (rightpos < endpos) and not(heap[childpos].value < heap[rightpos].value) then
          childpos := rightpos;
      heap[pos] := heap[childpos];
      pos := childpos;
      childpos := 2 * pos + 1;
  end;
  heap[pos] := newitem;
  _movedownHI(heap, startpos, pos)
end;

procedure _movedownLO(var heap:THeapArrayF; startpos, pos:Int32); Inline;
var
  parentpos: Int32;
  parent,newitem:THeapItemF;
begin
  newitem := heap[pos];
  while (pos > startpos) do begin
    parentpos := (pos - 1) shr 1;
    parent := heap[parentpos];
    if (newitem.value > parent.value) then
    begin
      heap[pos] := parent;
      pos := parentpos;
      continue;
    end;
    break;
  end;
  heap[pos] := newitem;
end;

procedure _moveupLO(var heap:THeapArrayF; pos:Int32); Inline;
var endpos,startpos,childpos,rightpos:Int32;
    newitem: THeapItemF;
begin
  endpos := length(heap);
  startpos := pos;
  newitem := heap[pos];

  childpos := 2 * pos + 1;
  while childpos < endpos do begin
      rightpos := childpos + 1;
      if (rightpos < endpos) and not(heap[childpos].value > heap[rightpos].value) then
          childpos := rightpos;
      heap[pos] := heap[childpos];
      pos := childpos;
      childpos := 2 * pos + 1;
  end;
  heap[pos] := newitem;
  _movedownLO(heap, startpos, pos)
end;

procedure hPush(var h:THeapArrayF; item:Single; idx:Int32; HiLo:Boolean=True); Inline;
var hi:Int32;
begin
  hi := Length(h);
  SetLength(h,hi+1);

  h[hi].value := item;
  h[hi].index := idx;
  case HiLo of
    True: _movedownHI(h, 0, hi);
    False:_movedownLO(h, 0, hi);
  end;
end;

function hPop(var h:THeapArrayF; HiLo:Boolean=True): THeapItemF; Inline;
var m:THeapItemF;
begin
  m := h[High(h)];
  SetLength(h, high(h));
  if (High(h) >= 0) then begin
    Result := h[0];
    h[0] := m;
    case HiLo of
      True: _moveupHI(h, 0);
      False:_moveupLO(h, 0);
    end;
  end else
    Exit(m);
end;

// Extracts the largest point from the array.
function SPS_GetMaxValue(const Mat: T2DSingleArray): TPoint; Callconv
var
  X,Y,W,H:Integer;
begin
  Result := Point(0,0);
  H := High(Mat);
  W := High(Mat[0]);
  for Y:=0 to H do
    for X:=0 to W do
      if Mat[Y][X] > Mat[Result.y][Result.x] then
      begin
        Result.x := x;
        Result.y := y;
      end;
end;

// Extracts the 'count' largest points from the array
procedure SPS_GetMaxValues(const Mat: T2DSingleArray; const Count: Integer; var Res: TPointArray); Callconv
var
  W,H,i,y,x,width: Int32;
  data:THeapArrayF;
begin
  H := High(Mat);
  if (Length(Mat) = 0) then
    Exit();

  W := High(Mat[0]);
  width := w + 1;
  SetLength(Data, 0);

  for y:=0 to H do
    for x:=0 to W do
      if (length(data) < count) or (mat[y,x] > Data[0].value) then
      begin
        if (length(data) = count) then
          hPop(data, True);
        hPush(data, mat[y,x], y*width+x, True);
      end;

  W += 1;
  H += 1;
  SetLength(Res, Length(data));
  for i:=0 to High(Data) do
  begin
    Res[i].y := Data[i].index div W;
    Res[i].x := Data[i].index mod W;
  end;
end;

procedure SPS_CombineMatrix(const Mat1, Mat2: T2DSingleArray; var Res: T2DSingleArray); Callconv
var
  Wl,Hl,Wr,Hr,i,j: Integer;
begin
  Hl := High(Mat1);
  Hr := High(Mat2);
  if (Hl = -1) or (HR = -1) then
    Exit();
  Wl := High(Mat1[0]);
  Wr := High(Mat2[0]);
  if (Hl<>Hr) or (Wl<>Wr) then
    Exit();
  SetLength(Res, Hl+1,Wl+1);
  for i:=0 to Hl do
    for j:=0 to Wl do
      Res[i][j] := Mat1[i][j] + Mat2[i][j];
end;

end.

