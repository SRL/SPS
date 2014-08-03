library sps;

{$mode objfpc}{$H+}

{$macro on}
{$define callconv:=
    {$IFDEF WINDOWS}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
    {$IFDEF LINUX}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
}

uses
  classes, sysutils, dynlibs, {$IFDEF WINDOWS} interfaces, {$ENDIF} // Yeah.. try it.
  spsTypes, spsArrays, spsLegacy, spsCv;

var
  OldMemoryManager: TMemoryManager;
  memisset: Boolean = False;

function GetPluginABIVersion: Integer; callconv export;
begin
  Result := 2;
end;

procedure SetPluginMemManager(MemMgr : TMemoryManager); callconv export;
begin
  if memisset then
    exit;
  GetMemoryManager(OldMemoryManager);
  SetMemoryManager(MemMgr);
  memisset := true;
end;

procedure OnDetach; callconv export;
begin
  if (cvLibLoaded) then
    FreeLibrary(cvHandle);
  SetMemoryManager(OldMemoryManager);
end;

function GetTypeCount(): Integer; callconv export;
begin
  Result := 2;
end;

function GetTypeInfo(x: Integer; var sType, sTypeDef: PChar): integer; callconv export;
begin
  case x of
    0: begin
         StrPCopy(sType, 'TSingleArray');
         StrPCopy(sTypeDef, 'array of Single');
       end;
    1: begin
         StrPCopy(sType, 'T2DSingleArray');
         StrPCopy(sTypeDef, 'array of TSingleArray');
       end;
    else
      x := -1;
  end;

  Result := x;
end;

function GetFunctionCount(): Integer; callconv export;
begin
  Result := 8;
end;

function GetFunctionInfo(x: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; callconv export;
begin
  case x of
    0:
      begin
        ProcAddr := @SPS_FindMapInMap;
        StrPCopy(ProcDef, 'function SPS_FindMapInMap(out fx, fy: integer; LargeMap, SmallMap: T3DIntegerArray; tol: extended): integer;');
      end;
    1:
      begin
        ProcAddr := @SPS_BitmapToMap;
        StrPCopy(ProcDef, 'procedure SPS_BitmapToMap(bmp: TMufasaBitmap; SideLength: integer; var res: T3DIntegerArray);');
      end;
    2:
      begin
        ProcAddr := @SPS_MakeColorBox;
        StrPCopy(ProcDef, 'procedure SPS_MakeColorBox(bmp: TMufasaBitmap; x1, y1, SideLength: integer; var res: TIntegerArray);');
      end;
    3:
      begin
        ProcAddr := @SPS_GetMaxValue;
        StrPCopy(ProcDef, 'function SPS_GetMaxValue(const Mat: T2DSingleArray): TPoint;');
      end;
    4:
      begin
        ProcAddr := @SPS_GetMaxValues;
        StrPCopy(ProcDef, 'procedure SPS_GetMaxValues(const Mat: T2DSingleArray; const Count: Integer; var Res: TPointArray);');
      end;
    5:
      begin
        ProcAddr := @SPS_CombineMatrix;
        StrPCopy(ProcDef, 'procedure SPS_CombineMatrix(const Mat1, Mat2: T2DSingleArray; var Res: T2DSingleArray);');
      end;
    6:
      begin
        ProcAddr := @SPS_LoadCV;
        StrPCopy(ProcDef, 'function SPS_LoadCV(const Path: String): Boolean;');
      end;
    7:
      begin
        ProcAddr := @SPS_FindMapInMap_CV;
        StrPCopy(ProcDef, 'procedure SPS_FindMapInMap_CV(LargeMap, SmallMap: T2DIntegerArray; const Method: Byte; var Corr: T2DSingleArray);');
      end;
    else
      x := -1;
  end;

  Result := x;
end;

exports GetPluginABIVersion;
exports SetPluginMemManager;
exports GetTypeCount;
exports GetTypeInfo;
exports GetFunctionCount;
exports GetFunctionInfo;
exports OnDetach;

begin
end.
