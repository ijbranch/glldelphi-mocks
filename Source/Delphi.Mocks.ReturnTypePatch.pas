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
  This unit courtesy of Stefen Glienke.

  This unit is a work around for QC98687 where RTTI is not generated for
  return types which are alias's of a generic type.

  http://qc.embarcadero.com/wc/qcmain.aspx?d=98687

  Usage :

  TOnFinalizedEvent = TMulticastEvent<TEventArgs>;

type // <- mandatory otherwise you get: E2086 Type 'TMulticastEvent<T>' is not yet completely defined
  {$M+}
  ISomeInterface = interface
    ['{7620908B-6DB7-4616-9A6F-AB2934F67077}']
    [ReturnTypePatch(TypeInfo(TOnFinalizedEvent))] //<<<
    function GetOnFinalized: TOnFinalizedEvent;
    property OnFinalized: TOnFinalizedEvent read GetOnFinalized;
  end;

initialization
  PatchMethodReturnType(TypeInfo(ISomeInterface));

*)

unit Delphi.Mocks.ReturnTypePatch;

interface

uses
  System.Rtti,
  System.TypInfo;

type
  /// <summary>Names the return type of an interface method whose RTTI lacks one (QC98687: a return type that is an
  /// alias of a generic type). PatchMethodReturnType(TypeInfo(TheInterface)) applies every such attribute.
  /// </summary>
  ReturnTypePatchAttribute = class(TCustomAttribute)
  private
    /// <summary>The return type to write into the method's RTTI.</summary>
    FReturnType: PTypeInfo;
  public
    /// <summary>Creates the attribute.</summary>
    /// <param name="ATypeInfo">The method's real return type.</param>
    constructor Create(ATypeInfo: PTypeInfo);
  end;

/// <summary>Patches every method of an interface that carries a ReturnTypePatch attribute and has no return type.
/// </summary>
/// <param name="ATypeInfo">The interface.</param>
/// <exception cref="EArgumentException">ATypeInfo is not an interface with RTTI.</exception>
/// <exception cref="EOSError">The RTTI could not be written.</exception>
procedure PatchMethodReturnType(ATypeInfo: PTypeInfo); overload;
/// <summary>Patches one method of an interface, found by name without regard to case, if it has no return type.
/// </summary>
/// <param name="ATypeInfo">The interface.</param>
/// <param name="AMethodName">The method.</param>
/// <param name="AReturnType">The method's real return type.</param>
/// <exception cref="EArgumentException">ATypeInfo is not an interface with RTTI.</exception>
/// <exception cref="EOSError">The RTTI could not be written.</exception>
procedure PatchMethodReturnType(const ATypeInfo: PTypeInfo; const AMethodName : string; const AReturnType: PTypeInfo); overload;
/// <summary>Patches one interface method, if it has no return type.</summary>
/// <param name="AMethod">The method; it must belong to an interface.</param>
/// <param name="AReturnType">The method's real return type.</param>
/// <exception cref="EArgumentException">AMethod is not an interface method.</exception>
/// <exception cref="EOSError">The RTTI could not be written, or did not take the new value.</exception>
procedure PatchMethodReturnType(AMethod: TRttiMethod; AReturnType: PTypeInfo); overload;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  Winapi.Windows;

type
  //A shadow of System.Rtti's private TRttiIntfMethod, to reach its fields. It must match that
  //class's field layout; the ReturnTypePatch tests prove it still does after an RTL update.
  TRttiIntfMethod = class(TRttiMethod)
  public
    FTail: PIntfMethodEntryTail;
    FParameters: TArray<TRttiParameter>;
    FReturnType: PTypeInfo;
  end;

const
  /// <summary>How many distinct return types can be patched in one process.</summary>
  MAX_RETURN_TYPES = 256;

var
  //The patched RTTI points at these slots, so they must live as long as the module: static
  //storage, never freed. They used to be heap cells disposed in finalization while the RTTI
  //still pointed at them.
  ReturnTypes: array[0..MAX_RETURN_TYPES - 1] of PTypeInfo;
  ReturnTypeCount: Integer;
  //Guards ReturnTypes / ReturnTypeCount; patching may be done from more than one thread.
  PatchLock: TCriticalSection;

function NeedsPatch(AMethod: TRttiMethod): Boolean;
begin
  Result := (AMethod.MethodKind = mkFunction) and (AMethod.ReturnType = nil);
end;

/// <summary>Returns the RTTI of an interface, refusing anything else.</summary>
/// <param name="AContext">The context to look it up in.</param>
/// <param name="ATypeInfo">The type.</param>
/// <returns>The interface's RTTI.</returns>
/// <exception cref="EArgumentException">ATypeInfo is nil, not an interface, or has no RTTI.</exception>
function InterfaceType(var AContext: TRttiContext; ATypeInfo: PTypeInfo): TRttiType;
begin
  if (ATypeInfo = nil) or (ATypeInfo^.Kind <> tkInterface) then
    raise EArgumentException.Create('PatchMethodReturnType applies to interfaces only');

  Result := AContext.GetType(ATypeInfo);
  if Result = nil then
    raise EArgumentException.CreateFmt('%s has no RTTI to patch', [string(ATypeInfo^.Name)]);
end;

procedure PatchMethodReturnType(const ATypeInfo: PTypeInfo; const AMethodName : string; const AReturnType: PTypeInfo); overload;
var
  LContext: TRttiContext;
  LMethod: TRttiMethod;
begin
  LContext := TRttiContext.Create;
  try
    for LMethod in InterfaceType(LContext, ATypeInfo).GetDeclaredMethods do
    begin
      //Pascal names are not case sensitive; a caller's different casing silently patched nothing.
      if SameText(LMethod.Name, AMethodName) and NeedsPatch(LMethod) then
        PatchMethodReturnType(LMethod, AReturnType);
    end;
  finally
    LContext.Free;
  end;
end;


procedure PatchMethodReturnType(ATypeInfo: PTypeInfo);
var
  LContext: TRttiContext;
  LMethod: TRttiMethod;
  LAttribute: TCustomAttribute;
begin
  LContext := TRttiContext.Create;
  try
    for LMethod in InterfaceType(LContext, ATypeInfo).GetDeclaredMethods do
    begin
      if NeedsPatch(LMethod) then
      begin
        for LAttribute in LMethod.GetAttributes do
        begin
          if LAttribute is ReturnTypePatchAttribute then
            PatchMethodReturnType(LMethod, ReturnTypePatchAttribute(LAttribute).FReturnType);
        end;
      end;
    end;
  finally
    LContext.Free;
  end;
end;

/// <summary>Returns the static slot holding a return type, adding one for a type not seen before.</summary>
/// <param name="AReturnType">The return type.</param>
/// <returns>The slot's address.</returns>
/// <exception cref="EOSError">Every slot is in use.</exception>
function ReturnTypeSlot(AReturnType: PTypeInfo): PPTypeInfo;
var
  i: Integer;
begin
  PatchLock.Acquire;
  try
    for i := 0 to ReturnTypeCount - 1 do
      if ReturnTypes[i] = AReturnType then
        Exit(@ReturnTypes[i]);

    if ReturnTypeCount = MAX_RETURN_TYPES then
      raise EOSError.CreateFmt('PatchMethodReturnType supports at most %d distinct return types', [MAX_RETURN_TYPES]);

    ReturnTypes[ReturnTypeCount] := AReturnType;
    Result := @ReturnTypes[ReturnTypeCount];
    Inc(ReturnTypeCount);
  finally
    PatchLock.Release;
  end;
end;

procedure PatchMethodReturnType(AMethod: TRttiMethod; AReturnType: PTypeInfo);
var
  p: PByte;
  i: Integer;
  LByteCount: NativeUInt;
  LReturnType: PPTypeInfo;

  procedure SkipShortString(var p: PByte);
  begin
    Inc(p, p[0] + 1);
  end;

begin
  //The shadow-class cast below is only valid for an interface method; on anything else it read
  //an unrelated field and wrote a pointer to wherever that led.
  if (AMethod = nil) or not (AMethod.Parent is TRttiInterfaceType) then
    raise EArgumentException.Create('PatchMethodReturnType applies to interface methods only');

  if not NeedsPatch(AMethod) then
    Exit;

  Pointer(p) := TRttiIntfMethod(AMethod).FTail;
  Inc(p, SizeOf(TIntfMethodEntryTail));

  for i := 0 to TRttiIntfMethod(AMethod).FTail.ParamCount - 1 do
  begin
    Inc(p);                     // Flags
    SkipShortString(p);         // ParamName
    SkipShortString(p);         // TypeName
    Inc(p, SizeOf(PTypeInfo));  // ParamType
    Inc(p, PWord(p)^);          // AttrData
  end;

  LReturnType := ReturnTypeSlot(AReturnType);

  SkipShortString(p);
  LByteCount := 0;
  if not WriteProcessMemory(GetCurrentProcess, p, @LReturnType, SizeOf(Pointer), LByteCount)
    or (LByteCount <> SizeOf(Pointer)) then
    RaiseLastOSError;
  TRttiIntfMethod(AMethod).FReturnType := LReturnType^;

  //Prove the patch took; a silent failure here would surface much later as a mock that cannot
  //return the method's value.
  if (AMethod.ReturnType = nil) or (AMethod.ReturnType.Handle <> AReturnType) then
    raise EOSError.CreateFmt('PatchMethodReturnType could not patch %s: System.Rtti''s layout has changed',
      [AMethod.Name]);
end;

constructor ReturnTypePatchAttribute.Create(ATypeInfo: PTypeInfo);
begin
  FReturnType := ATypeInfo;
end;

initialization
  PatchLock := TCriticalSection.Create;

finalization
  PatchLock.Free;

end.
