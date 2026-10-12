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

unit Delphi.Mocks.ObjectProxy;

interface

uses
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  System.Generics.Collections,
  Delphi.Mocks,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.Proxy;

type
  /// <summary>The proxy behind a TMock&lt;T&gt; or TStub&lt;T&gt; of a class: a real instance whose virtual
  /// methods are intercepted. A method with a behaviour, an abstract method, or any method of a stub is replaced;
  /// any other virtual method of a mock runs for real, and its calls are still counted.</summary>
  TObjectProxy<T> = class(TProxy<T>)
  private
    /// <summary>The intercepted instance.</summary>
    FInstance : T;
    /// <summary>The interceptor that routes the instance's virtual calls to DoBefore.</summary>
    FVMInterceptor : TVirtualMethodInterceptor;
    /// <summary>Whether a method takes part in the instance's construction or destruction, which a mock must
    /// never replace.</summary>
    /// <param name="Method">The method.</param>
    /// <returns>True for a destructor, or an override of AfterConstruction, BeforeDestruction or FreeInstance.
    /// </returns>
    class function IsLifecycleMethod(const Method: TRttiMethod): Boolean; static;
  protected
    /// <summary>Handles an intercepted virtual call: records it, or completes the pending setup, and decides
    /// whether the real method runs.</summary>
    /// <param name="Instance">The intercepted instance.</param>
    /// <param name="Method">The method called.</param>
    /// <param name="Args">The call's arguments, Self excluded; var and out arguments are written back.</param>
    /// <param name="DoInvoke">Set to False to skip the real method.</param>
    /// <param name="Result">The value to return when the real method is skipped.</param>
    procedure DoBefore(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean; out Result: TValue);
    /// <summary>Returns the intercepted instance.</summary>
    /// <returns>The instance.</returns>
    function Proxy : T; override;
  public
    /// <summary>Creates the proxy and its instance.</summary>
    /// <param name="ACreateFunc">Constructs the instance; nil uses the parameterless Create.</param>
    /// <param name="AAutoMocker">The auto mock container, or nil.</param>
    /// <param name="AIsStubOnly">Whether the proxy belongs to a stub.</param>
    /// <exception cref="EMockNoRTTIException">T has no RTTI.</exception>
    /// <exception cref="EMockException">T has no parameterless Create and no ACreateFunc was given.</exception>
    constructor Create( const ACreateFunc: TFunc<T>; const AAutoMocker : IAutoMock = nil; const AIsStubOnly : boolean = false); reintroduce;
    /// <summary>Destroys the instance, then the interceptor.</summary>
    destructor Destroy; override;
  end;

implementation

uses
  Delphi.Mocks.Helpers;

{ TObjectProxy<T> }

constructor TObjectProxy<T>.Create(const ACreateFunc: TFunc<T>; const AAutoMocker : IAutoMock; const AIsStubOnly : boolean);
var
  ctx   : TRttiContext;
  rType : TRttiType;
  ctor : TRttiMethod;
  instance : TValue;
begin
  inherited Create(AAutoMocker, AIsStubOnly);
  ctx := TRttiContext.Create;
  rType := ctx.GetType(TypeInfo(T));
  if rType = nil then
    raise EMockNoRTTIException.Create('No TypeInfo found for T');

  if not Assigned(ACreateFunc) then
  begin
    ctor := rType.FindConstructor;
    if ctor = nil then
      raise EMockException.Create('Could not find constructor Create on type ' + rType.Name);

    instance := ctor.Invoke(rType.AsInstance.MetaclassType, []);
  end
  else
    instance := TValue.From<T>(ACreateFunc);
  FInstance := instance.AsType<T>();
  FVMInterceptor := TVirtualMethodInterceptor.Create(rType.AsInstance.MetaclassType);

  FVMInterceptor.Proxify(instance.AsObject);
  FVMInterceptor.OnBefore := DoBefore;
end;

destructor TObjectProxy<T>.Destroy;
begin
  TObject(Pointer(@FInstance)^).Free;//always destroy the instance before the interceptor.
  FVMInterceptor.Free;
  inherited;
end;

class function TObjectProxy<T>.IsLifecycleMethod(const Method: TRttiMethod): Boolean;
begin
  Result := (Method.MethodKind = mkDestructor)
    or SameText(Method.Name, 'AfterConstruction')
    or SameText(Method.Name, 'BeforeDestruction')
    or SameText(Method.Name, 'FreeInstance');
end;

procedure TObjectProxy<T>.DoBefore(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean; out Result: TValue);
var
  vArgs: TArray<TValue>;
  i, l: Integer;
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  //Don't intercept the TObject methods, nor a class's own destructor or construction and
  //destruction hooks: skipping an overridden Destroy on a stub (or one given a behaviour) left
  //the instance's owned resources, and the instance itself, unfreed.
  DoInvoke := True;
  if (Method.Parent.AsInstance.MetaclassType = TObject) or IsLifecycleMethod(Method) then
    Exit;

  pInfo := TypeInfo(T);
  methodData := GetMethodData(method.Name,pInfo.NameStr);

  //Included instance as first argument because TExpectation.Match
  //deduces that the first argument is the object instance.
  l := Length(Args);
  SetLength(vArgs, l+1);
  vArgs[0] := Instance;

  for i := 1 to l do
  begin
    vArgs[i] := Args[i-1];
  end;

  //Call the original (virtual) method if:
  //-we are not a stub
  //-we have not defined any behavior (of course we count hits)
  //-the actual method is not an abstract method
  //-we are not setting up
  DoInvoke := not (FIsStubOnly or (methodData.FindBestBehavior(vArgs) <> nil) or Method.IsAbstract or (FSetupMode <> TSetupMode.None));

  Self.DoInvoke(Method,vArgs,Result);

  for i := 1 to l do
  begin
    Args[i-1] := vArgs[i];
  end;
end;

function TObjectProxy<T>.Proxy: T;
begin
  result := FInstance;
end;

end.
