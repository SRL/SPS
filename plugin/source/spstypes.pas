unit spsTypes;

{$mode objfpc}{$H+}

interface

uses
  MufasaTypes;

// Exported
type
  TSingleArray  = array of Single;
  T2DSingleArray = array of TSingleArray;
// Internal
type
  THeapItemF = record Value: Single; index: Int32; end;
  THeapArrayF = array of THeapItemF;
  T3DIntegerArray = array of T2DIntegerArray;
  CVMat = record Data:Pointer; cols, rows: Integer; end;
  PFloat = ^Single;

implementation

end.

