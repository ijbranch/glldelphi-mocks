{***************************************************************************}
{                                                                           }
{           Delphi Mocks - Taken from DUnitX Project                        }
{                                                                           }
{           Copyright (C) 2013 Vincent Parrett                              }
{           Modified (C) 2026 Ian Branch (GITLAK Software)                  }
{                                                                           }
{           vincent@finalbuilder.com                                        }
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

unit Delphi.Mocks.WeakReference;


interface

{$I 'Delphi.Mocks.inc'}
uses
  System.Generics.Collections;

type
  /// Implemented by our weak referenced object base class
  /// <summary>An object that weak references can point at: it clears them when it is destroyed.</summary>
  IWeakReferenceableObject = interface
    ['{3D7F9CB5-27F2-41BF-8C5F-F6195C578755}']
    /// <summary>Registers a weak reference's slot, to be cleared when the object is destroyed.</summary>
    /// <param name="value">The address of the slot.</param>
    procedure AddWeakRef(value : Pointer);
    /// <summary>Unregisters a weak reference's slot.</summary>
    /// <param name="value">The address of the slot.</param>
    /// <exception cref="Exception">In a DEBUG build, no slot was ever registered.</exception>
    procedure RemoveWeakRef(value : Pointer);
    /// <summary>Returns the object's reference count.</summary>
    /// <returns>The count.</returns>
    function GetRefCount : integer;
  end;

  ///  This is our base class for any object that can have a weak reference to
  ///  it. It implements IInterface so the object can also be used just like
  ///  any normal reference counted objects in Delphi.
  /// <summary>A reference-counted object that weak references can point at. Every weak reference operation in the
  /// process is serialised by one lock, so a reference cannot be read, added or removed while its target is
  /// clearing the slots that point at it.</summary>
  TWeakReferencedObject = class(TObject, IInterface, IWeakReferenceableObject)
  private const
    /// <summary>Set in FRefCount once the count has reached zero and the object is being destroyed.</summary>
    objDestroyingFlag = Integer($80000000);
  private class var
    /// <summary>The state of the one lock every weak reference operation takes: 0 free, 1 held. A spin lock on
    /// a plain Integer needs no creation or freeing, so it is safe in any unit's initialization or finalization;
    /// the sections it guards are a handful of instructions and never call out.</summary>
    FWeakRefLockState : Integer;
  private
    /// <summary>Takes the weak reference lock, waiting for it if necessary.</summary>
    class procedure WeakRefLock; static;
    /// <summary>Releases the weak reference lock.</summary>
    class procedure WeakRefUnlock; static;
    /// <summary>Registers a slot; the caller holds the weak reference lock.</summary>
    /// <param name="value">The address of the slot.</param>
    procedure AddWeakRefLocked(value : Pointer);
    /// <summary>Unregisters a slot; the caller holds the weak reference lock.</summary>
    /// <param name="value">The address of the slot.</param>
    /// <exception cref="Exception">In a DEBUG build, no slot was ever registered.</exception>
    procedure RemoveWeakRefLocked(value : Pointer);
    /// <summary>Takes a strong reference only if the object is still alive, atomically, so a weak reference
    /// cannot revive an object whose count has already reached zero.</summary>
    /// <returns>True when a reference was taken; the caller must release it.</returns>
    function TryAcquire : Boolean;
  protected
  {$IFNDEF AUTOREFCOUNT}
    /// <summary>The reference count, with objDestroyingFlag set once destruction has begun.</summary>
    FRefCount: Integer;
  {$ENDIF}
    /// <summary>The addresses of the weak reference slots that point at this object.</summary>
    FWeakReferences : TList<Pointer>;
    /// <summary>Queries for an interface the class implements.</summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="Obj">Receives the interface.</param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    /// <summary>Adds a reference.</summary>
    /// <returns>The new count.</returns>
    function _AddRef: Integer; virtual; stdcall;
    /// <summary>Releases a reference, destroying the object when the count reaches zero.</summary>
    /// <returns>The new count.</returns>
    function _Release: Integer; virtual;stdcall;
    /// <summary>Registers a weak reference's slot.</summary>
    /// <param name="value">The address of the slot.</param>
    procedure AddWeakRef(value : Pointer);
    /// <summary>Unregisters a weak reference's slot.</summary>
    /// <param name="value">The address of the slot.</param>
    /// <exception cref="Exception">In a DEBUG build, no slot was ever registered.</exception>
    procedure RemoveWeakRef(value : Pointer);
    /// <summary>Returns the reference count, without the destroying flag.</summary>
    /// <returns>The count.</returns>
    function GetRefCount : integer; inline;
  public
    /// <summary>Drops the implicit reference NewInstance added for construction.</summary>
    procedure AfterConstruction; override;
    /// <summary>Clears every weak reference slot that points at the object.</summary>
    procedure BeforeDestruction; override;
    /// <summary>Allocates the object with an implicit reference, so reference counting during construction
    /// cannot destroy it.</summary>
    /// <returns>The new instance.</returns>
    class function NewInstance: TObject; override;
  {$IFNDEF AUTOREFCOUNT}
    /// <summary>The reference count.</summary>
    property RefCount: Integer read GetRefCount;
  {$ENDIF}
  end;

  // This is our generic WeakReference interface
  /// <summary>A reference that does not keep its target alive.</summary>
  IWeakReference<T : IInterface> = interface
    /// <summary>Whether the target still exists.</summary>
    /// <returns>True until the target is destroyed.</returns>
    function IsAlive : boolean;
    /// <summary>Returns a strong reference to the target.</summary>
    /// <returns>The target, or nil when it has gone.</returns>
    function Data : T;
  end;

  //The actual WeakReference implementation.
  /// <summary>A weak reference to an object derived from TWeakReferencedObject.</summary>
  TWeakReference<T: IInterface> = class(TInterfacedObject, IWeakReference<T>)
  private
    /// <summary>The target object; cleared by the target when it is destroyed.</summary>
    FData : Pointer;
  protected
    /// <summary>Whether the target still exists.</summary>
    /// <returns>True until the target is destroyed.</returns>
    function IsAlive : boolean;
    /// <summary>Returns a strong reference to the target.</summary>
    /// <returns>The target, or nil when it has gone or is being destroyed.</returns>
    function Data : T;
  public
    /// <summary>Creates a weak reference.</summary>
    /// <param name="data">The target.</param>
    /// <exception cref="Exception">data is nil, or does not support IWeakReferenceableObject.</exception>
    constructor Create(const data : T);
    /// <summary>Unregisters the reference from its target, if the target still exists.</summary>
    destructor Destroy;override;
  end;

//only here to work around compiler limitation.
/// <summary>Tries to enter an object's monitor, allowing for a nil object.</summary>
/// <param name="AObject">The object, or nil.</param>
/// <returns>True when the monitor was entered.</returns>
function SafeMonitorTryEnter(const AObject: TObject): Boolean;

const
 /// <summary>The message raised when a weak reference is made to an unsuitable object.</summary>
 SWeakReferenceError = 'TWeakReference can only be used with objects derived from TWeakReferencedObject';


implementation

uses
  System.TypInfo,
  System.Classes,
  System.SysUtils,
  System.SyncObjs;

//MonitorTryEnter doesn't do a nil check!
function SafeMonitorTryEnter(const AObject: TObject): Boolean;
begin
  if AObject <> nil then
    Result := TMonitor.TryEnter(AObject)
  else
    result := False;
end;


constructor TWeakReference<T>.Create(const data: T);
var
  target : IWeakReferenceableObject;
begin
  if data = nil then
    raise Exception.Create(format('[%s] passed to TWeakReference was nil', [PTypeInfo(TypeInfo(T)).Name]));

  inherited Create;

  if Supports(IInterface(data),IWeakReferenceableObject,target) then
  begin
    FData := IInterface(data) as TObject;
    target.AddWeakRef(@FData);
  end
  else
    raise Exception.Create(SWeakReferenceError);
end;

function TWeakReference<T>.Data: T;
var
  target : TObject;
  acquired : Boolean;
begin
  result := Default(T); /// can't assign nil to T
  target := nil;
  acquired := False;

  //Read the slot and take a strong reference under the lock, so the target cannot clear the
  //slot and be freed in between. TryAcquire refuses a target whose count has reached zero.
  TWeakReferencedObject.WeakRefLock;
  try
    if FData <> nil then
    begin
      target := TObject(FData);
      acquired := (target is TWeakReferencedObject) and TWeakReferencedObject(target).TryAcquire;
    end;
  finally
    TWeakReferencedObject.WeakRefUnlock;
  end;

  if not acquired then
    exit;

  try
    //Make sure that the object supports the interface which is our generic type if we
    //simply pass in the interface base type, the method table doesn't work correctly
    Supports(target, GetTypeData(TypeInfo(T))^.Guid, result);
  finally
    TWeakReferencedObject(target)._Release;
  end;
end;

destructor TWeakReference<T>.Destroy;
begin
  //Under the lock the target cannot be part-way through clearing its slots, so FData is either
  //nil (the target has gone) or a live object to unregister from. The old TryEnter on the
  //target's monitor could fail under contention, leave the slot registered, and let the target
  //later write nil into this freed object.
  TWeakReferencedObject.WeakRefLock;
  try
    if (FData <> nil) and (TObject(FData) is TWeakReferencedObject) then
      TWeakReferencedObject(FData).RemoveWeakRefLocked(@FData);
    FData := nil;
  finally
    TWeakReferencedObject.WeakRefUnlock;
  end;
  inherited;
end;

function TWeakReference<T>.IsAlive: boolean;
begin
  result := FData <> nil;
end;

{ TWeakReferencedObject }

class procedure TWeakReferencedObject.WeakRefLock;
begin
  while TInterlocked.CompareExchange(FWeakRefLockState, 1, 0) <> 0 do
    TThread.Yield;
end;

class procedure TWeakReferencedObject.WeakRefUnlock;
begin
  TInterlocked.Exchange(FWeakRefLockState, 0);
end;

procedure TWeakReferencedObject.AddWeakRef(value: Pointer);
begin
  TWeakReferencedObject.WeakRefLock;
  try
    AddWeakRefLocked(value);
  finally
    TWeakReferencedObject.WeakRefUnlock;
  end;
end;

procedure TWeakReferencedObject.AddWeakRefLocked(value: Pointer);
begin
  if FWeakReferences = nil then
    FWeakReferences := TList<Pointer>.Create;
  FWeakReferences.Add(value);
end;

procedure TWeakReferencedObject.RemoveWeakRef(value: Pointer);
begin
  TWeakReferencedObject.WeakRefLock;
  try
    RemoveWeakRefLocked(value);
  finally
    TWeakReferencedObject.WeakRefUnlock;
  end;
end;

procedure TWeakReferencedObject.RemoveWeakRefLocked(value: Pointer);
begin
  if FWeakReferences = nil then // should never happen
    {$IFDEF DEBUG}
    raise Exception.Create('FWeakReferences = nil');
    {$ELSE}
    exit;
    {$ENDIF}
  FWeakReferences.Remove(value);
  if FWeakReferences.Count = 0 then
    FreeAndNil(FWeakReferences);
end;

function TWeakReferencedObject.TryAcquire: Boolean;
var
  current : Integer;
begin
  repeat
    current := FRefCount;
    if (current and objDestroyingFlag <> 0) or (current and not objDestroyingFlag = 0) then
      Exit(False);
  until TInterlocked.CompareExchange(FRefCount, current + 1, current) = current;
  Result := True;
end;

procedure TWeakReferencedObject.AfterConstruction;
begin
{$IFNDEF AUTOREFCOUNT}
  TInterlocked.Decrement(FRefCount);
{$ENDIF}
end;

procedure TWeakReferencedObject.BeforeDestruction;
var
  value : PPointer;
  i: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  if RefCount <> 0 then
    System.Error(reInvalidPtr);
{$ELSE}
  inherited BeforeDestruction;
{$ENDIF}
  TWeakReferencedObject.WeakRefLock;
  try
    if FWeakReferences <> nil then
    begin
      for i := 0 to FWeakReferences.Count -1 do
      begin
        value := FWeakReferences.Items[i];
        value^ := nil;
      end;
      FreeAndNil(FWeakReferences);
    end;
  finally
    TWeakReferencedObject.WeakRefUnlock;
  end;
end;

function TWeakReferencedObject.GetRefCount: integer;
begin
  Result := FRefCount and not objDestroyingFlag;
end;

class function TWeakReferencedObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
{$IFNDEF AUTOREFCOUNT}
  // Set an implicit refcount so that refcounting
  // during construction won't destroy the object.
  TWeakReferencedObject(Result).FRefCount := 1;
{$ENDIF}
end;

function TWeakReferencedObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TWeakReferencedObject._AddRef: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  Result := TInterlocked.Increment(FRefCount);
{$ELSE}
  Result := __ObjAddRef;
{$ENDIF}
end;

function TWeakReferencedObject._Release: Integer;

{$IFNDEF AUTOREFCOUNT}
  procedure __MarkDestroying(const Obj);
  var
    LRef: Integer;
  begin
    repeat
      LRef := TWeakReferencedObject(Obj).FRefCount;
    until TInterlocked.CompareExchange(TWeakReferencedObject(Obj).FRefCount, LRef or objDestroyingFlag, LRef) = LRef;
  end;
{$ENDIF}

begin
{$IFNDEF AUTOREFCOUNT}
  Result := TInterlocked.Decrement(FRefCount);
  if Result = 0 then
  begin
    __MarkDestroying(Self);
    Destroy;
  end;
{$ELSE}
  Result := __ObjRelease;
{$ENDIF}
end;

end.
