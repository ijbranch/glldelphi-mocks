{***************************************************************************}
{                                                                           }
{           Delphi.Mocks                                                    }
{                                                                           }
{           Copyright (C) 2011 Vincent Parrett                              }
{           Modified (C) 2026 Ian Branch (GITLAK Software)                  }
{                                                                           }
{           http://www.finalbuilder.com                                     }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

(*
  SameValue/CompareValue Copyright (c) 2011, Stefan Glienke
  Used with permission.
*)

unit Delphi.Mocks.Helpers;

interface

uses
  System.Rtti;

type
  //TValue really needs to have an Equals operator overload!
  /// <summary>Comparison and type tests for TValue, used to match mocked-call arguments.</summary>
  TValueHelper = record helper for TValue
    private
    /// <summary>Returns the value's RTTI type.</summary>
    /// <returns>The type, or nil when the value has no type info.</returns>
    function GetRttiType: TRttiType;
  public
    /// <summary>Compares with another value.</summary>
    /// <param name="value">The other value.</param>
    /// <returns>True when the values are equal, as SameValue decides.</returns>
    function Equals(const value : TValue) : boolean;
    /// <summary>Whether the value is a floating-point number.</summary>
    /// <returns>True for any float kind.</returns>
    function IsFloat: Boolean;
    /// <summary>Whether the value is a number, character or enumeration.</summary>
    /// <returns>True for the numeric kinds.</returns>
    function IsNumeric: Boolean;
    /// <summary>Whether the value is a pointer.</summary>
    /// <returns>True for tkPointer.</returns>
    function IsPointer: Boolean;
    /// <summary>Whether the value is a string or character.</summary>
    /// <returns>True for the string and character kinds.</returns>
    function IsString: Boolean;
    /// <summary>Whether the value is a Boolean.</summary>
    /// <returns>True for exactly Boolean.</returns>
    function IsBoolean: Boolean;
    /// <summary>Whether the value is a Byte.</summary>
    /// <returns>True for exactly Byte.</returns>
    function IsByte: Boolean;
    /// <summary>Whether the value is a Cardinal.</summary>
    /// <returns>True for exactly Cardinal.</returns>
    function IsCardinal: Boolean;
    /// <summary>Whether the value is a Currency.</summary>
    /// <returns>True for exactly Currency.</returns>
    function IsCurrency: Boolean;
    /// <summary>Whether the value is a TDate.</summary>
    /// <returns>True for exactly TDate.</returns>
    function IsDate: Boolean;
    /// <summary>Whether the value is a TDateTime.</summary>
    /// <returns>True for exactly TDateTime.</returns>
    function IsDateTime: Boolean;
    /// <summary>Whether the value is a Double.</summary>
    /// <returns>True for exactly Double.</returns>
    function IsDouble: Boolean;
    /// <summary>Whether the value is an Integer.</summary>
    /// <returns>True for exactly Integer.</returns>
    function IsInteger: Boolean;
    /// <summary>Whether the value is an Int64.</summary>
    /// <returns>True for exactly Int64.</returns>
    function IsInt64: Boolean;
    /// <summary>Whether the value is a ShortInt.</summary>
    /// <returns>True for exactly ShortInt.</returns>
    function IsShortInt: Boolean;
    /// <summary>Whether the value is a Single.</summary>
    /// <returns>True for exactly Single.</returns>
    function IsSingle: Boolean;
    /// <summary>Whether the value is a SmallInt.</summary>
    /// <returns>True for exactly SmallInt.</returns>
    function IsSmallInt: Boolean;
    /// <summary>Whether the value is a TTime.</summary>
    /// <returns>True for exactly TTime.</returns>
    function IsTime: Boolean;
    /// <summary>Whether the value is a UInt64.</summary>
    /// <returns>True for exactly UInt64.</returns>
    function IsUInt64: Boolean;
    /// <summary>Whether the value is a Variant (not an OleVariant; test Kind = tkVariant for both).</summary>
    /// <returns>True for exactly Variant.</returns>
    function IsVariant: Boolean;
    /// <summary>Whether the value is a Word.</summary>
    /// <returns>True for exactly Word.</returns>
    function IsWord: Boolean;
    /// <summary>Whether the value is a TGUID.</summary>
    /// <returns>True for exactly TGUID.</returns>
  	function IsGuid: Boolean;
    /// <summary>Whether the value is an interface.</summary>
    /// <returns>True for tkInterface.</returns>
    function IsInterface : Boolean;
    /// <summary>Whether the value is a record, managed or not.</summary>
    /// <returns>True for tkRecord and tkMRecord.</returns>
    function IsRecord : Boolean;
    /// <summary>Whether the value is a static or dynamic array.</summary>
    /// <returns>True for tkArray and tkDynArray.</returns>
    function IsArray : Boolean;
    /// <summary>Returns the value as a Double.</summary>
    /// <returns>The value.</returns>
    /// <exception cref="EInvalidCast">The value cannot be converted.</exception>
    function AsDouble: Double;
    /// <summary>Returns the value as an Extended.</summary>
    /// <returns>The value.</returns>
    /// <exception cref="EInvalidCast">The value cannot be converted.</exception>
    function AsFloat: Extended;
    /// <summary>Returns the value as a Single.</summary>
    /// <returns>The value.</returns>
    /// <exception cref="EInvalidCast">The value cannot be converted.</exception>
    function AsSingle: Single;
    /// <summary>Returns the value's first pointer-sized bytes as a pointer.</summary>
    /// <returns>The pointer.</returns>
    function AsPointer: Pointer;
    /// <summary>The value's RTTI type, or nil.</summary>
    property RttiType: TRttiType read GetRttiType;
  end;


  /// <summary>RTTI type lookups used by the proxies.</summary>
  TRttiTypeHelper = class helper for TRttiType
    /// <summary>Looks up a method by name.</summary>
    /// <param name="AName">The method's name.</param>
    /// <param name="AMethod">Receives the method, or nil.</param>
    /// <returns>True when found.</returns>
    function TryGetMethod(const AName: string; out AMethod: TRttiMethod): Boolean;
    /// <summary>Finds a parameterless constructor named Create.</summary>
    /// <returns>The constructor, or nil.</returns>
    function FindConstructor : TRttiMethod;
  end;

  /// <summary>RTTI method tests used by the proxies.</summary>
  TRttiMethodHelper = class helper for TRttiMethod
    /// <summary>Whether the method has no implementation: an interface method, or an abstract method with extended
    /// RTTI.</summary>
    /// <returns>True when abstract.</returns>
    function IsAbstract: Boolean;
    /// <summary>Whether the method is dispatched through the VMT, so it can be intercepted.</summary>
    /// <returns>True for a virtual method.</returns>
    function IsVirtual: Boolean;
  end;

/// <summary>Compares two arrays element by element.</summary>
/// <param name="Left">The first array.</param>
/// <param name="Right">The second array.</param>
/// <returns>0 when equal; otherwise non-zero.</returns>
function CompareValue_Array(const Left, Right: TValue): Integer;
/// <summary>Compares two records with their = operator, or field by field when they have none.</summary>
/// <param name="Left">The first record.</param>
/// <param name="Right">The second record.</param>
/// <returns>0 when equal; otherwise non-zero.</returns>
function CompareValue_Record(const Left, Right: TValue): Integer;
/// <summary>Compares two values of any kind.</summary>
/// <param name="Left">The first value.</param>
/// <param name="Right">The second value.</param>
/// <returns>0 when equal; for ordered kinds negative or positive by order, otherwise -1 when unequal.</returns>
function CompareValue(const Left, Right: TValue): Integer;
/// <summary>Decides whether two values are equal.</summary>
/// <param name="Left">The first value.</param>
/// <param name="Right">The second value.</param>
/// <returns>True when equal.</returns>
function SameValue(const Left, Right: TValue): Boolean;


implementation

uses
  System.SysUtils,
  System.Math,
  System.TypInfo,
  System.Variants,
  System.StrUtils;

var
  Context : TRttiContext;

//adapted from Spring4D

/// <summary>Compares two values of one unmanaged type byte for byte.</summary>
/// <param name="Left">The first value.</param>
/// <param name="Right">The second value.</param>
/// <returns>0 when the type and the bytes are the same, otherwise -1. Managed types are never compared this way,
/// because their bytes are references, not content.</returns>
function CompareRaw(const Left, Right: TValue): Integer;
begin
  Result := -1;
  if (Left.TypeInfo <> Right.TypeInfo) or IsManaged(Left.TypeInfo) or (Left.DataSize <> Right.DataSize) then
    Exit;

  if CompareMem(Left.GetReferenceToRawData, Right.GetReferenceToRawData, Left.DataSize) then
    Result := 0;
end;

/// <summary>Returns the COM identity of an interface: its IInterface pointer, which is the same whichever of an
/// object's interfaces it was reached through.</summary>
/// <param name="Value">A value holding an interface.</param>
/// <returns>The identity, or the raw interface pointer when the object will not give its IInterface.</returns>
function InterfaceIdentity(const Value: TValue): Pointer;
var
  intf : IInterface;
  identity : IInterface;
begin
  intf := Value.AsInterface;
  Result := Pointer(intf);
  if (intf <> nil) and (intf.QueryInterface(IInterface, identity) = S_OK) then
    Result := Pointer(identity);
end;

function CompareValue(const Left, Right: TValue): Integer;
const
  EmptyResults: array[Boolean, Boolean] of Integer = ((0, -1), (1, 0));
var
  leftIsEmpty, rightIsEmpty: Boolean;
  leftFloat, rightFloat: Extended;
  leftMethod, rightMethod: TMethod;
begin
  leftIsEmpty := left.IsEmpty;
  rightIsEmpty := right.IsEmpty;
  if leftIsEmpty or rightIsEmpty then
    Result := EmptyResults[leftIsEmpty, rightIsEmpty]
  else if left.IsOrdinal and right.IsOrdinal then
    Result := System.Math.CompareValue(left.AsOrdinal, right.AsOrdinal)
  else if left.IsFloat and right.IsFloat then
  begin
    //Exact. Math.CompareValue with no epsilon applies a tolerance scaled by ExtendedResolution,
    //which is 1E-19 on Win32 and 1E-15 on Win64, so the same test matched on one and not the other.
    leftFloat := left.AsExtended;
    rightFloat := right.AsExtended;
    if leftFloat = rightFloat then
      Result := 0
    else if leftFloat < rightFloat then
      Result := -1
    else
      Result := 1;
  end
  else if left.IsString and right.IsString then
    //Ordinal. AnsiCompareStr goes through the locale's CompareString, which ignores some
    //characters entirely (soft hyphen, zero-width), so different strings compared equal.
    Result := System.SysUtils.CompareStr(left.AsString, right.AsString)
  else if left.IsObject and right.IsObject then begin
    //Compare by sign, not by raw difference: a 64 bit difference truncated into an Integer
    //made two instances exactly 4GiB apart compare equal.
    Result := System.Math.CompareValue(NativeInt(left.AsObject), NativeInt(right.AsObject));
    if Result <> 0 then begin
      if left.AsObject.Equals(right.AsObject) then
        Result := 0;
    end;
  end else if Left.IsInterface and Right.IsInterface then
    Result := System.Math.CompareValue(NativeInt(InterfaceIdentity(left)), NativeInt(InterfaceIdentity(right)))
  else if Left.IsRecord and Right.IsRecord then
    Result := CompareValue_Record(Left, Right)
  else if Left.IsArray and Right.IsArray then
    Result := CompareValue_Array(Left, Right)
  else if (left.Kind = tkVariant) and (right.Kind = tkVariant) then
  begin
    //tkVariant covers OleVariant as well as Variant. Variants that cannot be compared (a
    //string with an integer) raised out of argument matching; they are simply unequal.
    try
      case VarCompareValue(left.AsVariant, right.AsVariant) of
        vrEqual: Result := 0;
        vrLessThan: Result := -1;
        vrGreaterThan: Result := 1;
      else
        Result := -1;
      end;
    except
      on EVariantError do
        Result := -1;
    end;
  end
  else if (left.Kind = tkPointer) and (right.Kind = tkPointer) then
    Result := System.Math.CompareValue(NativeInt(left.AsPointer), NativeInt(right.AsPointer))
  else if (left.Kind = tkClassRef) and (right.Kind = tkClassRef) then
    Result := System.Math.CompareValue(NativeInt(left.AsClass), NativeInt(right.AsClass))
  else if (left.Kind = tkMethod) and (right.Kind = tkMethod) then
  begin
    //An event: equal when it names the same method of the same instance. Not left to CompareRaw,
    //which refuses managed types, and the RTL counts method pointers as managed.
    left.ExtractRawDataNoCopy(@leftMethod);
    right.ExtractRawDataNoCopy(@rightMethod);
    if (leftMethod.Code = rightMethod.Code) and (leftMethod.Data = rightMethod.Data) then
      Result := 0
    else
      Result := -1;
  end
  else
    //Sets, method pointers (events), procedure pointers and anything else: equal only when the
    //bytes of one unmanaged type agree. This used to return 0, so any two such values matched.
    Result := CompareRaw(left, right);
end;

function CompareValue_Array(const Left, Right: TValue): Integer;
var
  i: Integer;
begin
  Result := Left.GetArrayLength - Right.GetArrayLength;

  if Result = 0 then begin
    for i := 0 to Left.GetArrayLength - 1 do begin
      Result := CompareValue(Left.GetArrayElement(i), Right.GetArrayElement(i));
      if Result <> 0 then
        Exit;
    end;
  end;
end;

function CompareValue_Record(const Left, Right: TValue): Integer;
var
  LMethod: TRttiMethod;
  LType: TRttiType;
  LField: TRttiField;
  LFields: TArray<TRttiField>;
begin
  if Left.TypeInfo <> Right.TypeInfo then
    Exit(-1);

  LType := Left.RttiType;
  if LType = nil then
    Exit(CompareRaw(Left, Right));

  if LType.TryGetMethod('&op_Equality', LMethod) then begin
    if LMethod.Invoke(nil, [Left, Right]).AsBoolean then
      Result := 0
    else
      Result := -1;
    Exit;
  end;

  //No equality operator: compare field by field. This used to return 0, so any two records of
  //a type without one matched each other.
  LFields := LType.GetFields;
  if Length(LFields) = 0 then
    Exit(CompareRaw(Left, Right));

  for LField in LFields do
  begin
    if LField.FieldType = nil then
      Exit(CompareRaw(Left, Right));

    Result := CompareValue(LField.GetValue(Left.GetReferenceToRawData), LField.GetValue(Right.GetReferenceToRawData));
    if Result <> 0 then
      Exit;
  end;
  Result := 0;
end;

function SameValue(const Left, Right: TValue): Boolean;
begin
  if Left.IsGuid and Right.IsGuid then
    Result := IsEqualGuid( Left.AsType<TGUID>, Right.AsType<TGUID> )
  else
    result := CompareValue(left, right) = 0;
end;

{ TValueHelper }

function TValueHelper.AsDouble: Double;
begin
  Result := AsType<Double>;
end;

function TValueHelper.AsFloat: Extended;
begin
  Result := AsType<Extended>;
end;

function TValueHelper.AsPointer: Pointer;
begin
  ExtractRawDataNoCopy(@Result);
end;

function TValueHelper.AsSingle: Single;
begin
  Result := AsType<Single>;
end;

function TValueHelper.Equals(const value : TValue) : boolean;
begin
  result := SameValue(Self, value);
end;

function TValueHelper.GetRttiType: TRttiType;
begin
   Result := Context.GetType(TypeInfo);

end;

function TValueHelper.IsArray: Boolean;
begin
  Result := Kind in [tkArray, tkDynArray];
end;

function TValueHelper.IsBoolean: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Boolean);
end;

function TValueHelper.IsByte: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Byte);
end;

function TValueHelper.IsCardinal: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Cardinal);
end;

function TValueHelper.IsCurrency: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Currency);
end;

function TValueHelper.IsDate: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(TDate);
end;

function TValueHelper.IsDateTime: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(TDateTime);
end;

function TValueHelper.IsDouble: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Double);
end;

function TValueHelper.IsFloat: Boolean;
begin
  Result := Kind = tkFloat;
end;

function TValueHelper.IsInt64: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Int64);
end;

function TValueHelper.IsInteger: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Integer);
end;

function TValueHelper.IsInterface: Boolean;
begin
  Result := Kind = tkInterface;
end;

function TValueHelper.IsNumeric: Boolean;
begin
  Result := Kind in [tkInteger, tkChar, tkEnumeration, tkFloat, tkWChar, tkInt64];
end;

function TValueHelper.IsPointer: Boolean;
begin
  Result := Kind = tkPointer;
end;

function TValueHelper.IsRecord: Boolean;
begin
  Result := Kind in [tkRecord, tkMRecord];
end;

function TValueHelper.IsShortInt: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(ShortInt);
end;

function TValueHelper.IsSingle: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Single);
end;

function TValueHelper.IsSmallInt: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(SmallInt);
end;

function TValueHelper.IsString: Boolean;
begin
  Result := Kind in [tkChar, tkString, tkWChar, tkLString, tkWString, tkUString];
end;

function TValueHelper.IsTime: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(TTime);
end;

function TValueHelper.IsUInt64: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(UInt64);
end;

function TValueHelper.IsVariant: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Variant);
end;

function TValueHelper.IsWord: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Word);
end;


function TValueHelper.IsGuid: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(TGUID);
end;



{ TRttiTypeHelper }

function TRttiTypeHelper.FindConstructor: TRttiMethod;
var
  candidateCtor: TRttiMethod;
begin
  Result := nil;
  for candidateCtor in GetMethods('Create') do
  begin
    if Length(candidateCtor.GetParameters) = 0 then
    begin
      Result := candidateCtor;
      Break;
    end;
  end;
end;

function TRttiTypeHelper.TryGetMethod(const AName: string; out AMethod: TRttiMethod): Boolean;
begin
  AMethod := GetMethod(AName);
  Result := Assigned(AMethod);
end;

{ TRttiMethodHelper }

function TRttiMethodHelper.IsAbstract: Boolean;
const
  //The class of an extended-RTTI instance method; it is private to System.Rtti, so it can only
  //be recognised by name.
  INSTANCE_METHOD_EX = 'TRttiInstanceMethodEx';
begin
  //An interface method has no implementation at all.
  if Parent is TRttiInterfaceType then
    Exit(True);

  //Only an extended-RTTI instance method's Handle is a PVmtMethodExEntry, which carries the
  //abstract flag. Reading it through any other method's Handle read unrelated memory.
  Result := (ClassName = INSTANCE_METHOD_EX) and (PVmtMethodExEntry(Handle).Flags and (1 shl 7) <> 0);
end;

function TRttiMethodHelper.IsVirtual: Boolean;
begin
  Result := DispatchKind = dkVtable;
end;

initialization
  Context := TRttiContext.Create;

finalization
  Context.Free;

end.
