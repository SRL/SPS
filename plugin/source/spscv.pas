unit spsCv;

(**
 * Copyright (c) 2014, Jarl K. Holta || https://github.com/WarPie
 * All rights reserved.
 *)

{$mode objfpc}{$H+}
{$macro on}
{$define Callconv:=
    {$IFDEF WINDOWS}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
    {$IFDEF LINUX}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
}

interface


uses
  SysUtils, MufasaTypes, Dynlibs, spsTypes;

function SPS_LoadCV(const Path: String): Boolean; Callconv
procedure SPS_FindMapInMap_CV(LargeMap, SmallMap: T2DIntegerArray; const Method: Byte; var Corr: T2DSingleArray); Callconv

const
  libName = 'libMatchTempl';

type
  TImgFromData = procedure(Data: Pointer; Width, Height: Integer; var Mat: Pointer); Callconv
  TFreeImg = procedure(var Mat: Pointer); Callconv
  TMatchTemplate = function(var Img, Templ: Pointer; MatchMethod: Int32; Normed: Boolean; var Mat: Pointer): Pointer; Callconv

var
  cvHandle: TLibHandle = NilHandle;
  cvImgFromData: TImgFromData;
  cvFreeImg: TFreeImg;
  cvMatchTemplate: TMatchTemplate;
  cvLibLoaded: Boolean = False;

implementation

function SPS_LoadCV(const Path: String): Boolean; Callconv
var
  vLibName: String;
  FilePath: String;
begin
  if (cvLibLoaded) then
  begin
    Writeln('SPS_LoadCV(): Already loaded!');
    Exit(True);
  end;

  {$IFDEF CPU32}
    vLibName := libName + '32';
  {$ELSE}
    vLibName := libName + '64';
  {$ENDIF}

  FilePath := Path + vLibName + '.' + SharedSuffix;
  Result := FileExists(FilePath);

  if (Result) then
  begin
    cvHandle := LoadLibrary(FilePath);
    if (cvHandle = NilHandle) then
    begin
      Writeln('SPS_LoadCV(): Found library but failed to load (bit differences?)');
      Exit(False);
    end;

    cvImgFromData := TImgFromData(GetProcedureAddress(cvHandle, 'MatFromData'));
    cvFreeImg := TFreeImg(GetProcedureAddress(cvHandle, 'freeImage'));
    cvMatchTemplate := TMatchTemplate(GetProcedureAddress(cvHandle, 'matchTempl'));

    Writeln('SPS:');
    Writeln('ImgFromData: $' + hexStr(@cvImgFromData));
    Writeln('FreeImg: $' + hexStr(@cvFreeImg));
    Writeln('MatchTemplate: $' + hexStr(@cvMatchTemplate));

    cvLibLoaded := (@cvImgFromData <> nil) and (@cvFreeImg <> nil) and (@cvMatchTemplate <> nil);

    case cvLibLoaded of
      True: Writeln('SPS_LoadCV(): Succesfully loaded!');
      False: Writeln('SPS_LoadCV(): ERROR: Failed to load');
    end;
  end else
    Writeln('SPS_LoadCV(): Failed to find library @ "' + FilePath + '"');
end;

function cvLoadFromMatrix(var Mat:T2DIntegerArray): CVMat;
var
  w,h,y:Integer;
  Data:TIntegerArray;
begin
  SetLength(Data, Length(Mat[0]) * Length(Mat));
  W := Length(Mat[0]);
  H := Length(Mat);
  for y:=0 to H-1 do
    Move(Mat[y][0], Data[y*W], 4*W);

  Result.Data := nil;

  cvImgFromData(PChar(Data), w, h, Result.Data);

  Result.Cols := W;
  Result.Rows := H;
  SetLength(Data, 0);
end;

procedure cvFreeMatrix(var Matrix:CVMat);
begin
  cvFreeImg(Matrix.data);
  Matrix.cols := 0;
  Matrix.rows := 0;
end;

procedure SPS_FindMapInMap_CV(LargeMap, SmallMap: T2DIntegerArray; const Method: Byte; var Corr: T2DSingleArray); Callconv
var
  res: Pointer;
  Ptr: PFloat;
  i,W,H: Integer;
  Img, Templ: CVMat;
begin
  Img := cvLoadFromMatrix(LargeMap);
  Templ := cvLoadFromMatrix(SmallMap);

   if (templ.rows > img.rows) or (templ.cols > templ.cols) then
   begin
    Writeln('SPS: Large map is larger than small map!');
    Exit();
  end;

  W := img.cols - templ.cols + 1;
  H := img.rows - templ.rows + 1;
  SetLength(Corr, H, W);

  try
    Ptr := PFloat(cvMatchTemplate(img.Data, templ.Data, Method, True, Res));
    if (Ptr <> nil) then
      for i:=0 to H-1 do
        Move(Ptr[i*W], Corr[i][0], 4*W);
  finally
    cvFreeImg(Res);
    cvFreeMatrix(Img);
    cvFreeMatrix(Templ);
  end;
end;

end.


