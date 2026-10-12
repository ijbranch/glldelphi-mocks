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

unit Delphi.Mocks.Proxy.TypeInfo;

interface

uses
  System.Rtti,
  System.SysUtils,
  System.Generics.Collections,
  System.TypInfo,
  Delphi.Mocks,
  Delphi.Mocks.Proxy,
  Delphi.Mocks.WeakReference,
  Delphi.Mocks.Interfaces;

type
  /// <summary>A proxy for an interface known only by its type info, which the auto mock container creates for an
  /// interface returned from a mocked method. It has no setup interface - nothing can configure it - so it only
  /// records calls and supplies default (or further auto mocked) results.</summary>
  TProxy = class(TWeakReferencedObject, IWeakReferenceableObject, IInterface, IProxy, IVerify)
  private
    /// <summary>The mocked interface's type info.</summary>
    FTypeInfo               : PTypeInfo;
    /// <summary>The proxy this one was added to by Implement, held weakly; nil for a top-level proxy.</summary>
    FParentProxy            : IWeakReference<IProxy>;
    /// <summary>The proxies of the extra interfaces added by Implement, keyed by interface GUID.</summary>
    FInterfaceProxies       : TDictionary<TGUID, IProxy>;
    /// <summary>Whether a definition may replace an existing one.</summary>
    FAllowRedefineBehaviorDefinitions  : Boolean;

    /// <summary>The virtual interface that implements the mocked interface; nil for a non-interface type.
    /// </summary>
    FVirtualInterface       : IProxyVirtualInterface;
    /// <summary>The mocked type's name.</summary>
    FName : string;

    /// <summary>Each method's data, keyed by lower-cased method name.</summary>
    FMethodData             : TDictionary<string, IMethodData>;
    /// <summary>The order in which this proxy's methods were first called.</summary>
    FCallLog                : ICallLog;
    /// <summary>Whether a call to a method with no behaviour must raise.</summary>
    FBehaviorMustBeDefined  : Boolean;
    /// <summary>Whether the proxy belongs to a stub.</summary>
    FIsStubOnly             : boolean;

    /// <summary>Guards QueryInterface against re-entry.</summary>
    FQueryingInterface      : boolean;
    /// <summary>Guards QueryImplementedInterface against re-entry.</summary>
    FQueryingInternalInterface : boolean;

    /// <summary>The auto mock container, held weakly: it owns this proxy via IProxy, so a strong reference back
    /// would form a cycle and neither would ever be destroyed.</summary>
    FAutoMocker             : IWeakReference<IAutoMock>;
    /// <summary>Resolves the weakly held auto mock container.</summary>
    /// <returns>The container, or nil when there is none or it has gone.</returns>
    function GetAutoMocker : IAutoMock;

  protected type
    /// <summary>The virtual interface that implements the mocked interface, and asks its owning proxy for the
    /// other interfaces the mock implements.</summary>
    TProxyVirtualInterface = class(TVirtualInterface, IInterface, IProxyVirtualInterface)
    private
      /// <summary>The owning proxy, held weakly.</summary>
      FProxy : IWeakReference<IProxy>;
      /// <summary>Asks the owning proxy whether this interface should answer for IInterface.</summary>
      /// <returns>True when it should, or when the owner has gone.</returns>
      function SupportsIInterface: Boolean;
    protected
      //IProxyVirtualInterface
      /// <summary>Queries for an interface, optionally asking the owning proxy.</summary>
      /// <param name="IID">The interface wanted.</param>
      /// <param name="Obj">Receives the interface.</param>
      /// <param name="ACheckOwner">Whether to ask the owning proxy as well.</param>
      /// <returns>S_OK, or E_NOINTERFACE.</returns>
      function QueryInterfaceWithOwner(const IID: TGUID; out Obj; const ACheckOwner : Boolean): HRESULT; overload;
      /// <summary>Tests for an interface, optionally asking the owning proxy.</summary>
      /// <param name="IID">The interface wanted.</param>
      /// <param name="ACheckOwner">Whether to ask the owning proxy as well.</param>
      /// <returns>S_OK, or E_NOINTERFACE.</returns>
      function QueryInterfaceWithOwner(const IID: TGUID; const ACheckOwner : Boolean): HRESULT; overload;
      /// <summary>Makes every later call raise EMockException, because the owning proxy is being destroyed.
      /// </summary>
      /// <param name="ATypeName">The mocked type's name, for the message.</param>
      procedure Orphan(const ATypeName : string);
    public
      //TVirtualInterface overrides
      /// <summary>Creates the virtual interface.</summary>
      /// <param name="AProxy">The owning proxy.</param>
      /// <param name="AInterface">The type info of the interface to implement.</param>
      /// <param name="InvokeEvent">The handler every call is routed to.</param>
      constructor Create(const AProxy : IProxy; const AInterface: Pointer; const InvokeEvent: TVirtualInterfaceInvokeEvent);
      /// <summary>Queries for an interface, asking the owning proxy when this one does not support it.</summary>
      /// <param name="IID">The interface wanted.</param>
      /// <param name="Obj">Receives the interface.</param>
      /// <returns>S_OK, or E_NOINTERFACE.</returns>
      function QueryInterface(const IID: TGUID; out Obj): HRESULT; override; stdcall;
    end;

  protected
    /// <summary>Records the proxy this one was added to by Implement.</summary>
    /// <param name="AProxy">The parent proxy.</param>
    procedure SetParentProxy(const AProxy : IProxy);
    /// <summary>Whether this proxy's interface answers for IInterface: only a top-level proxy does.</summary>
    /// <returns>True for a proxy that has no parent.</returns>
    function SupportsIInterface: Boolean;

    /// <summary>Looks for an interface among the interfaces this proxy and its relatives implement.</summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="Obj">Receives the interface.</param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryImplementedInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    /// <summary>Queries for one of the proxy's own interfaces.</summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="Obj">Receives the interface.</param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; virtual; stdcall;

    //IProxy
    /// <summary>Returns the mocked interface.</summary>
    /// <returns>The virtual interface, as IInterface.</returns>
    /// <exception cref="EMockNoProxyException">The proxy has no virtual interface for the type.</exception>
    function ProxyInterface : IInterface;

    /// <summary>Whether this proxy's own virtual interface supports an interface.</summary>
    /// <param name="Instance">Unused; kept for the interface's signature.</param>
    /// <param name="IID">The interface wanted.</param>
    /// <returns>True when supported.</returns>
    function ProxySupports(const Instance: IInterface; const IID: TGUID) : boolean; virtual;
    /// <summary>Finds the proxy, this one or an implemented child, that implements a type.</summary>
    /// <param name="ATypeInfo">The interface type.</param>
    /// <returns>The proxy.</returns>
    /// <exception cref="EMockNoProxyException">No proxy implements the type.</exception>
    function ProxyFromType(const ATypeInfo : PTypeInfo) : IProxy; virtual;
    /// <summary>Adds the proxy of an extra interface the mock implements.</summary>
    /// <param name="AProxy">The interface's proxy.</param>
    /// <param name="ATypeInfo">The interface type.</param>
    /// <exception cref="EMockProxyAlreadyImplemented">The interface is already implemented.</exception>
    procedure AddImplement(const AProxy : IProxy; const ATypeInfo : PTypeInfo); virtual;

    /// <summary>Handles every call on the mocked instance by recording it.</summary>
    /// <param name="Method">The method called.</param>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <param name="Result">The value to return.</param>
    /// <exception cref="EMockException">No return value is available.</exception>
    procedure DoInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);

    /// <summary>Sets whether a call to a method with no behaviour must raise.</summary>
    /// <param name="AValue">The setting.</param>
    procedure SetBehaviorMustBeDefined(const AValue : Boolean);

    //IVerify
    /// <summary>Checks this proxy's expectations.</summary>
    /// <param name="message">Text placed before the detail of a failure.</param>
    /// <exception cref="EMockVerificationException">An expectation is not met.</exception>
    procedure Verify(const message : string = '');
    /// <summary>Checks this proxy's expectations and those of every interface it implements.</summary>
    /// <param name="message">Text placed before the detail of a failure.</param>
    /// <exception cref="EMockVerificationException">An expectation is not met.</exception>
    procedure VerifyAll(const message : string = '');
    /// <summary>Forgets every recorded call, here and in every interface the proxy implements.</summary>
    procedure ResetCalls;
    /// <summary>Removes every expectation, here and in every interface the proxy implements.</summary>
    procedure ClearExpectations;

    /// <summary>Describes every unmet expectation of this proxy.</summary>
    /// <returns>The description, or an empty string.</returns>
    function CheckExpectations: string;

    /// <summary>Returns a method's data, creating it on first use.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="ATypeName">Unused; the proxy's own type name is used.</param>
    /// <returns>The method's data; never nil.</returns>
    function GetMethodData(const AMethodName : string; const ATypeName: string) : IMethodData; overload;
  public
    /// <summary>Creates the proxy.</summary>
    /// <param name="ATypeInfo">The type to mock; only an interface gets a virtual interface.</param>
    /// <param name="AAutoMocker">The auto mock container, or nil.</param>
    /// <param name="AIsStubOnly">Whether the proxy belongs to a stub.</param>
    constructor Create(const ATypeInfo : PTypeInfo; const AAutoMocker : IAutoMock = nil; const AIsStubOnly : boolean = false); virtual;
    /// <summary>Destroys the proxy, orphaning any mocked instance a test still holds.</summary>
    destructor Destroy; override;
  end;

implementation

uses
  Delphi.Mocks.MethodData,
  Delphi.Mocks.ParamMatcher;

{TProxy}

procedure TProxy.AddImplement(const AProxy: IProxy; const ATypeInfo : PTypeInfo);
begin

  if FInterfaceProxies.ContainsKey(GetTypeData(ATypeInfo).Guid) then
    raise EMockProxyAlreadyImplemented.Create('The mock already implements ' + ATypeInfo.NameStr);

  FInterfaceProxies.Add(GetTypeData(ATypeInfo).Guid, AProxy);
  AProxy.SetParentProxy(Self);
end;

function TProxy.CheckExpectations: string;
var
  methodData : IMethodData;
  report : string;
begin
  Result := '';
  for methodData in FMethodData.Values do
  begin
    report := '';
    if not methodData.Verify(report) then
    begin
      if Result <> '' then
        Result := Result + #13#10;
      Result := Result + report ;
    end;
  end;
end;

procedure TProxy.ClearExpectations;
var
  methodData : IMethodData;
  proxy : IProxy;
  interfaceV : IVerify;
begin
  for methodData in FMethodData.Values do
    methodData.ClearExpectations;

  for proxy in FInterfaceProxies.Values.ToArray do
    if Supports(proxy, IVerify, interfaceV) then
      interfaceV.ClearExpectations;
end;

function TProxy.GetAutoMocker : IAutoMock;
begin
  if FAutoMocker <> nil then
    Result := FAutoMocker.Data
  else
    Result := nil;
end;

constructor TProxy.Create(const ATypeInfo : PTypeInfo; const AAutoMocker : IAutoMock; const AIsStubOnly : boolean);
var
  selfProxy : IProxy;
begin
  inherited Create;

  FName := ATypeInfo.NameStr;

  if AAutoMocker <> nil then
    FAutoMocker := TWeakReference<IAutoMock>.Create(AAutoMocker)
  else
    FAutoMocker := nil;
  FParentProxy := nil;
  FVirtualInterface := nil;

  FBehaviorMustBeDefined := False;
  FMethodData := TDictionary<string, IMethodData>.Create;
  FCallLog := TCallLog.Create;
  FIsStubOnly := AIsStubOnly;

  FInterfaceProxies := TDictionary<TGUID, IProxy>.Create;

  FTypeInfo := ATypeInfo;

  case FTypeInfo.Kind of
    //Create our proxy interface object, which will implement our interface T
    tkInterface :
    begin
      selfProxy := Self;
      FVirtualInterface := TProxyVirtualInterface.Create(selfProxy, FTypeInfo, Self.DoInvoke);

    end;
  end;
end;

destructor TProxy.Destroy;
begin
  //A test can still hold the mocked instance; make a later call on it raise a clear error
  //instead of running in this freed object.
  if FVirtualInterface <> nil then
    FVirtualInterface.Orphan(FName);
  FVirtualInterface := nil;

  FMethodData.Clear;
  FMethodData.Free;
  FInterfaceProxies.Clear;
  FInterfaceProxies.Free;

  FParentProxy := nil;

  inherited;
end;

procedure TProxy.DoInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
var
  methodData : IMethodData;
begin
  //This proxy has no setup interface, so every call is an ordinary one. Its Behavior and
  //Expectation branches could never run, and have gone.
  TMatcherFactory.ClearMatchers;
  methodData := GetMethodData(method.Name, FTypeInfo.NameStr);
  methodData.RecordHit(Args, Method.ReturnType, Method, Result);
end;

function TProxy.GetMethodData(const AMethodName: string; const ATypeName: string): IMethodData;
var
  methodName : string;
  setupParams: TSetupMethodDataParameters;
begin
  methodName := LowerCase(AMethodName);
  if FMethodData.TryGetValue(methodName, Result) then
    exit;

  setupParams := TSetupMethodDataParameters.Create(FIsStubOnly, FBehaviorMustBeDefined, FAllowRedefineBehaviorDefinitions);
  Result := TMethodData.Create(string(FTypeInfo.Name), AMethodName, setupParams, GetAutoMocker, FCallLog);
  FMethodData.Add(methodName, Result);
end;

function TProxy.QueryImplementedInterface(const IID: TGUID; out Obj): HRESULT;
var
  virtualProxy : IProxy;
  parent : IProxy;
begin
  Result := E_NOINTERFACE;

  if FQueryingInternalInterface then
    Exit;

  FQueryingInternalInterface := True;
  try
    //Otherwise look in the list of interface proxies that might have been implemented
    if (FInterfaceProxies.ContainsKey(IID)) then
    begin
      virtualProxy := FInterfaceProxies.Items[IID];
      Result := virtualProxy.ProxyInterface.QueryInterface(IID, Obj);

      if result = S_OK then
        Exit;
    end;

    //Call the parent, which is held weakly and may already be gone.
    if FParentProxy <> nil then
    begin
      parent := FParentProxy.Data;
      if parent <> nil then
        Result := parent.QueryInterface(IID, obj);
    end;
  finally
    FQueryingInternalInterface := False;
  end;
end;

function TProxy.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  Result := E_NOINTERFACE;

  //If we are already querying this interface, leave.
  if FQueryingInterface then
    Exit;

  FQueryingInterface := True;
  try
    //The interface requested might be one of this classes interfaces. E.g. IProxy
    Result := inherited QueryInterface(IID, Obj);
  finally
    FQueryingInterface := False;
  end;
end;

procedure TProxy.ResetCalls;
var
  methodData : IMethodData;
  proxy : IProxy;
  interfaceV : IVerify;
begin
  for methodData in FMethodData.Values do
    methodData.ResetCalls;
  FCallLog.Clear;

  for proxy in FInterfaceProxies.Values.ToArray do
    if Supports(proxy, IVerify, interfaceV) then
      interfaceV.ResetCalls;
end;

procedure TProxy.SetBehaviorMustBeDefined(const AValue: boolean);
begin
  FBehaviorMustBeDefined := AValue;
end;

procedure TProxy.SetParentProxy(const AProxy : IProxy);
begin
  FParentProxy := TWeakReference<IProxy>.Create(AProxy);
end;

function TProxy.SupportsIInterface: Boolean;
begin
  Result := (FParentProxy = nil);
end;

function TProxy.ProxyFromType(const ATypeInfo: PTypeInfo): IProxy;
var
  interfaceID : TGUID;
begin
  //Get the GUID of the type the proxy needs to support
  interfaceID := GetTypeData(ATypeInfo).Guid;

  //If we support the passed in type then return ourselves.
  if ProxySupports(FVirtualInterface, interfaceID) then
  begin
    Result := Self;
    Exit;
  end;

  //Are our children the proxy for this type?
  if FInterfaceProxies.ContainsKey(interfaceID) then
  begin
    //Remember that the virtual interface will be of the passed in type, therefore
    //return its proxy.
    Result := FInterfaceProxies.Items[interfaceID].ProxyFromType(ATypeInfo);
    Exit;
  end;

  raise EMockNoProxyException.CreateFmt('Error - No Proxy of type [%s] was found.', [ATypeInfo.NameStr]);
end;

function TProxy.ProxySupports(const Instance: IInterface; const IID: TGUID): boolean;
begin
  //We support the proxy if we have a virtual interface, which supports the passed in
  //interface. As the virtual interface is built to support mulitple interfaces we
  //need to ask it not check the other implementations.
  Result := (FVirtualInterface <> nil) and Supports(FVirtualInterface, IID, False);
end;

function TProxy.ProxyInterface: IInterface;
begin
  if FVirtualInterface = nil then
    raise EMockNoProxyException.CreateFmt('Error casting to interface [%s], proxy does not appear to implement T', [FTypeInfo.NameStr]);

  if FVirtualInterface.QueryInterface(GetTypeData(FTypeInfo).Guid, result) <> 0 then
    raise EMockNoProxyException.CreateFmt('Error casting to interface [%s], proxy does not appear to implement T', [FTypeInfo.NameStr]);
end;

procedure TProxy.Verify(const message: string);
var
  msg : string;
begin
  msg := CheckExpectations;
  if msg <> '' then
    raise EMockVerificationException.Create(message + #13#10 + msg);
end;

{ TProxy.TProxyVirtualInterface }

constructor TProxy.TProxyVirtualInterface.Create(const AProxy : IProxy;
  const AInterface: Pointer; const InvokeEvent: TVirtualInterfaceInvokeEvent);
begin
  //Create a weak reference to our owner proxy. This is the proxy who implements
  //all the mocking interfaces required to setup, and verify us.
  FProxy := TWeakReference<IProxy>.Create(AProxy);

  inherited Create(Ainterface, InvokeEvent);
end;

procedure TProxy.TProxyVirtualInterface.Orphan(const ATypeName: string);
begin
  OnInvoke :=
    procedure(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue)
    begin
      raise EMockException.CreateFmt('[%s].%s was called after the mock that created it was freed.', [ATypeName, Method.Name]);
    end;
end;

function TProxy.TProxyVirtualInterface.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  //The default query interface will ask the owner for the implementing virtual
  //interface for the type being queried for. This allows a virtual interface of
  //IInterfaceOne to support IInterfaceTwo when asked.
  Result := QueryInterfaceWithOwner(IID, Obj, True);
end;

function TProxy.TProxyVirtualInterface.QueryInterfaceWithOwner(const IID: TGUID; out Obj; const ACheckOwner: Boolean): HRESULT;
var
  owner : IProxy;
begin
  //See if we support the passed in interface.
  if IsEqualGUID(IID, IInterface) and not SupportsIInterface then
    Result := E_NOINTERFACE
  else
    Result := inherited QueryInterface(IID, Obj);

  //If we don't support the interface, then we need to look to our owner to see
  //who does implement it. FProxy outlives the proxy, so test what it points at.
  if (ACheckOwner) and (Result <> 0) and (FProxy <> nil) then
  begin
    owner := FProxy.Data;
    if owner <> nil then
      Result := owner.QueryImplementedInterface(IID, Obj);
  end;
end;

function TProxy.TProxyVirtualInterface.QueryInterfaceWithOwner(const IID: TGUID; const ACheckOwner: Boolean): HRESULT;
var
  dud : IInterface;
begin
  Result := QueryInterfaceWithOwner(IID, dud, ACheckOwner);
end;

function TProxy.TProxyVirtualInterface.SupportsIInterface: Boolean;
var
  owner : IProxy;
begin
  Result := True;
  if FProxy <> nil then
  begin
    owner := FProxy.Data;
    if owner <> nil then
      Result := owner.SupportsIInterface;
  end;
end;

procedure TProxy.VerifyAll(const message: string);
var
  proxy : IProxy;
  interfaceV : IVerify;
begin
  //Verify ourselves.
  Verify(message);

  //Now verify all our children.
  for proxy in FInterfaceProxies.Values.ToArray do
    if Supports(proxy, IVerify, interfaceV) then
      interfaceV.Verify(message);
end;

end.
