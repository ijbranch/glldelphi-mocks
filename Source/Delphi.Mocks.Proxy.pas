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

unit Delphi.Mocks.Proxy;

interface

uses
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  System.Generics.Collections,
  Delphi.Mocks,
  Delphi.Mocks.WeakReference,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.ParamMatcher,
  Delphi.Mocks.Behavior;

  {$I 'Delphi.Mocks.inc'}

type
  /// <summary>The signature of a proxy's method-invocation handler.</summary>
  /// <param name="Method">The method called.</param>
  /// <param name="Args">The call's arguments; Args[0] is Self.</param>
  /// <param name="Result">The value to return from the call.</param>
  TProxyBaseInvokeEvent = procedure (Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue) of object;

  /// <summary>What the next call on a proxy means: an ordinary call, or the target of a behaviour or expectation
  /// being set up.</summary>
  TSetupMode = (None, Behavior, Expectation);

  {$IFOPT M+}
    {$M-}
    {$DEFINE ENABLED_M+}
  {$ENDIF}
  /// <summary>The virtual interface that implements a mocked interface on behalf of its proxy.</summary>
  IProxyVirtualInterface = interface
    ['{A0394EB0-245E-4AE6-AD71-3BC9815CD173}']
    /// <summary>Queries for an interface, optionally asking the owning proxy for the interfaces it implements.
    /// </summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="Obj">Receives the interface.</param>
    /// <param name="ACheckOwner">Whether to ask the owning proxy when this virtual interface does not support it.
    /// </param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryInterfaceWithOwner(const IID: TGUID; out Obj; const ACheckOwner : Boolean): HRESULT; overload;
    /// <summary>Tests for an interface, optionally asking the owning proxy.</summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="ACheckOwner">Whether to ask the owning proxy when this virtual interface does not support it.
    /// </param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryInterfaceWithOwner(const IID: TGUID; const ACheckOwner : Boolean): HRESULT; overload;
    /// <summary>Detaches the virtual interface from its proxy, which is being destroyed. A test can still hold the
    /// mocked instance; from now on any call on it raises EMockException instead of running code in a freed proxy.
    /// </summary>
    /// <param name="ATypeName">The mocked type's name, for the message.</param>
    procedure Orphan(const ATypeName : string);
  end;
  {$IFDEF ENABLED_M+}
    {$M+}
  {$ENDIF}

  /// <summary>The proxy behind a TMock&lt;T&gt; or TStub&lt;T&gt; of an interface: it implements the interface through
  /// a virtual interface, records the behaviours and expectations set up on it, and records the calls made to it.
  /// TObjectProxy&lt;T&gt; extends it for classes.</summary>
  TProxy<T> = class(TWeakReferencedObject, IWeakReferenceableObject, IInterface, IProxy, IProxy<T>, IStubProxy<T>, IMockSetup<T>,
    IStubSetup<T>, IExpect<T>, IVerify)
  private
    //Implements members.
    //Can't define TProxy<T> or any other generic type as that type will be defined at runtime.
    /// <summary>The proxy this one was added to by Implement, held weakly; nil for a top-level proxy.</summary>
    FParentProxy            : IWeakReference<IProxy>;
    /// <summary>The proxies of the extra interfaces added by Implement, keyed by interface GUID.</summary>
    FInterfaceProxies       : TDictionary<TGUID, IProxy>;

    /// <summary>The virtual interface that implements T; nil for a class proxy.</summary>
    FVirtualInterface       : IProxyVirtualInterface;
    /// <summary>The mocked type's name.</summary>
    FName : string;

    /// <summary>Each method's data, keyed by lower-cased method name.</summary>
    FMethodData             : TDictionary<string, IMethodData>;
    /// <summary>The order in which this proxy's methods were first called, for Before / After.</summary>
    FCallLog                : ICallLog;
    /// <summary>Whether a call to a method with no behaviour must raise.</summary>
    FBehaviorMustBeDefined  : Boolean;
    /// <summary>Whether a definition may replace an existing one.</summary>
    FAllowRedefineBehaviorDefinitions : Boolean;
    //behavior setup
    /// <summary>The behaviour the pending setup will define.</summary>
    FNextBehavior           : TBehaviorType;
    /// <summary>The value the pending WillReturn setup will return.</summary>
    FReturnValue            : TValue;
    /// <summary>Whether the pending WillReturn setup may return nil.</summary>
    FReturnValueNilAllowed  : Boolean;
    /// <summary>The function the pending WillExecute setup will run.</summary>
    FNextFunc               : TExecuteFunc;
    /// <summary>The exception class the pending WillRaise setup will raise.</summary>
    FExceptClass            : ExceptClass;
    /// <summary>The message the pending WillRaise setup will use.</summary>
    FExceptionMessage       : string;
    //expectation setup
    /// <summary>The expectation the pending setup will define.</summary>
    FNextExpectation        : TExpectationType;
    /// <summary>The call count of the pending AtLeast / AtMost / Exactly setup.</summary>
    FTimes                  : Cardinal;
    /// <summary>The bounds of the pending Between setup.</summary>
    FBetween                : array[0..1] of Cardinal;
    /// <summary>The other method of the pending Before / After setup.</summary>
    FBeforeAfterMethodName  : string;
    /// <summary>The reference count when the pending setup began. The setup is abandoned - its When call never
    /// reached the proxy, because the method is not virtual - once the count falls below this, which only happens
    /// when the statement's temporary references are released.</summary>
    FSetupRefCount          : Integer;

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
    /// <summary>Puts the proxy into setup mode, so the next call through When defines a behaviour or expectation.
    /// </summary>
    /// <param name="AMode">The kind of setup.</param>
    procedure BeginSetup(const AMode : TSetupMode);
    /// <summary>Checks the matchers a When call registered.</summary>
    /// <param name="matchers">The matchers, by parameter index.</param>
    /// <param name="Args">The When call's arguments; Args[0] is Self.</param>
    /// <param name="Method">The method set up.</param>
    /// <exception cref="EMockSetupException">Matchers were used, but not for every parameter.</exception>
    procedure CheckMatchers(const matchers : TArray<IMatcher>; const Args: TArray<TValue>; const Method: TRttiMethod);

  protected type
    /// <summary>The virtual interface that implements T, and asks its owning proxy for the other interfaces
    /// the mock implements.</summary>
    TProxyVirtualInterface = class(TVirtualInterface, IInterface, IProxyVirtualInterface)
    private
      /// <summary>The owning proxy, held weakly.</summary>
      FProxy : IWeakReference<IProxy<T>>;
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
      constructor Create(const AProxy : IProxy<T>; const AInterface: Pointer; const InvokeEvent: TVirtualInterfaceInvokeEvent);
      /// <summary>Queries for an interface, asking the owning proxy when this one does not support it.</summary>
      /// <param name="IID">The interface wanted.</param>
      /// <param name="Obj">Receives the interface.</param>
      /// <returns>S_OK, or E_NOINTERFACE.</returns>
      function QueryInterface(const IID: TGUID; out Obj): HRESULT; override; stdcall;
    end;

  protected
    /// <summary>What the next call on the proxy means.</summary>
    FSetupMode              : TSetupMode;
    /// <summary>Whether the proxy belongs to a stub.</summary>
    FIsStubOnly             : boolean;

    /// <summary>Records the proxy this one was added to by Implement.</summary>
    /// <param name="AProxy">The parent proxy.</param>
    procedure SetParentProxy(const AProxy : IProxy);
    /// <summary>Whether this proxy's interface answers for IInterface: only a top-level proxy does, so the
    /// parent's identity is used for an implemented interface.</summary>
    /// <returns>True for a proxy that has no parent.</returns>
    function SupportsIInterface: Boolean;

    /// <summary>Looks for an interface among the interfaces this proxy and its relatives implement.</summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="Obj">Receives the interface.</param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryImplementedInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    /// <summary>Queries for one of the proxy's own interfaces (IProxy, IVerify and the setup interfaces).</summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="Obj">Receives the interface.</param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; virtual; stdcall;
    /// <summary>Releases a reference, reporting a setup abandoned on a method that is not virtual.</summary>
    /// <returns>The new reference count.</returns>
    /// <exception cref="EMockSetupException">The setup begun on this statement never reached the proxy.</exception>
    function _Release: Integer; override; stdcall;

    //IProxy
    /// <summary>Returns the mocked interface.</summary>
    /// <returns>The virtual interface, as IInterface.</returns>
    /// <exception cref="EMockNoProxyException">The proxy has no virtual interface for T.</exception>
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

    //IProxy<T>
    /// <summary>Returns the proxy as its mock setup interface.</summary>
    /// <returns>The setup interface.</returns>
    function MockSetup : IMockSetup<T>;
    /// <summary>Returns the proxy as its stub setup interface.</summary>
    /// <returns>The setup interface.</returns>
    function StubSetup : IStubSetup<T>;

    function IProxy<T>.Setup = MockSetup;
    function IStubProxy<T>.Setup = StubSetup;

    /// <summary>Returns the mocked instance.</summary>
    /// <returns>The instance, as T.</returns>
    /// <exception cref="EMockNoProxyException">The proxy has no virtual interface for T.</exception>
    function Proxy : T; virtual;

    //ISetup<T>
    /// <summary>Returns whether a call to a method with no behaviour must raise.</summary>
    /// <returns>The setting.</returns>
    function GetBehaviorMustBeDefined : boolean;
    /// <summary>Sets whether a call to a method with no behaviour must raise.</summary>
    /// <param name="value">The setting.</param>
    procedure SetBehaviorMustBeDefined(const value : boolean);
    /// <summary>Returns whether a definition may replace an existing one.</summary>
    /// <returns>The setting.</returns>
    function GetAllowRedefineBehaviorDefinitions : boolean;
    /// <summary>Sets whether a definition may replace an existing one.</summary>
    /// <param name="value">The setting.</param>
    procedure SetAllowRedefineBehaviorDefinitions(const value : boolean);

    /// <summary>Returns the expectation setup interface.</summary>
    /// <returns>The proxy, as IExpect&lt;T&gt;.</returns>
    function Expect : IExpect<T>;

    /// <summary>Begins a WillReturn setup.</summary>
    /// <param name="value">The value to return; must not be empty.</param>
    /// <returns>The When step.</returns>
    function WillReturn(const value : TValue) : IWhen<T>; overload;
    /// <summary>Begins a WillReturn setup that may return nil.</summary>
    /// <param name="value">The value to return.</param>
    /// <param name="AllowNil">Whether nil is an acceptable value.</param>
    /// <returns>The When step.</returns>
    function WillReturn(const value : TValue; const AllowNil: Boolean) : IWhen<T>; overload;
    /// <summary>Sets the value a method returns when no other behaviour applies.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="value">The default value.</param>
    /// <exception cref="EMockSetupException">A default is already defined and redefinition is not allowed.
    /// </exception>
    procedure WillReturnDefault(const AMethodName : string; const value : TValue);
    /// <summary>Begins a setup that returns nil.</summary>
    /// <returns>The When step.</returns>
    function WillReturnNil: IWhen<T>;
    /// <summary>Begins a setup that always raises, whatever the arguments.</summary>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message.</param>
    /// <returns>The When step.</returns>
    function WillRaise(const exceptionClass : ExceptClass; const message : string = '') : IWhen<T>; overload;
    /// <summary>Makes a method always raise.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message.</param>
    /// <exception cref="EMockSetupException">The behaviour is already defined.</exception>
    procedure WillRaise(const AMethodName : string; const exceptionClass : ExceptClass; const message : string = ''); overload;

    /// <summary>Begins a setup that raises for particular arguments.</summary>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message.</param>
    /// <returns>The When step.</returns>
    function WillRaiseWhen(const exceptionClass : ExceptClass; const message : string = '') : IWhen<T>;

    /// <summary>Begins a setup that runs a function for particular arguments.</summary>
    /// <param name="func">The function to run.</param>
    /// <returns>The When step.</returns>
    function WillExecute(const func : TExecuteFunc) : IWhen<T>; overload;
    /// <summary>Makes a method always run a function.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="func">The function to run.</param>
    /// <exception cref="EMockSetupException">The behaviour is already defined.</exception>
    procedure WillExecute(const AMethodName : string; const func : TExecuteFunc); overload;

    /// <summary>Handles every call on the mocked instance: records it, or completes the pending setup.</summary>
    /// <param name="Method">The method called.</param>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <param name="Result">The value to return.</param>
    /// <exception cref="EMockSetupException">The setup is invalid.</exception>
    /// <exception cref="EMockException">A behaviour raised, or no return value is available.</exception>
    procedure DoInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);

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
    /// <param name="ATypeName">The mocked type's name, for messages.</param>
    /// <returns>The method's data; never nil.</returns>
    function GetMethodData(const AMethodName : string; const ATypeName: string) : IMethodData; overload;

    /// <summary>Ends the pending setup.</summary>
    procedure ClearSetupState;

    //IExpect<T>
    /// <summary>Begins an expectation of exactly one call with particular arguments.</summary>
    /// <returns>The When step.</returns>
    function Once : IWhen<T>;overload;
    /// <summary>Expects exactly one call.</summary>
    /// <param name="AMethodName">The method.</param>
    procedure Once(const AMethodName : string);overload;

    /// <summary>Begins an expectation of no call with particular arguments.</summary>
    /// <returns>The When step.</returns>
    function Never : IWhen<T>;overload;
    /// <summary>Expects no call.</summary>
    /// <param name="AMethodName">The method.</param>
    procedure Never(const AMethodName : string);overload;

    /// <summary>Begins an expectation of one or more calls with particular arguments.</summary>
    /// <returns>The When step.</returns>
    function AtLeastOnce : IWhen<T>;overload;
    /// <summary>Expects one or more calls.</summary>
    /// <param name="AMethodName">The method.</param>
    procedure AtLeastOnce(const AMethodName : string);overload;

    /// <summary>Begins an expectation of a minimum number of calls with particular arguments.</summary>
    /// <param name="times">The minimum.</param>
    /// <returns>The When step.</returns>
    function AtLeast(const times : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects a minimum number of calls.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="times">The minimum.</param>
    procedure AtLeast(const AMethodName : string; const times : Cardinal);overload;

    /// <summary>Begins an expectation of a maximum number of calls with particular arguments.</summary>
    /// <param name="times">The maximum.</param>
    /// <returns>The When step.</returns>
    function AtMost(const times : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects a maximum number of calls.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="times">The maximum.</param>
    procedure AtMost(const AMethodName : string; const times : Cardinal);overload;

    /// <summary>Begins an expectation of an inclusive range of calls with particular arguments.</summary>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum.</param>
    /// <returns>The When step.</returns>
    function Between(const a, b : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects an inclusive range of calls.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum.</param>
    /// <exception cref="EMockSetupException">b is less than a.</exception>
    procedure Between(const AMethodName : string; const a, b : Cardinal);overload;

    /// <summary>Begins an expectation of an exact number of calls with particular arguments.</summary>
    /// <param name="times">The number of calls.</param>
    /// <returns>The When step.</returns>
    function Exactly(const times : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects an exact number of calls.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="times">The number of calls.</param>
    procedure Exactly(const AMethodName : string; const times : Cardinal);overload;

    /// <summary>Begins an expectation that the When method is first called before the first call of another.
    /// </summary>
    /// <param name="AMethodName">The method the When method must precede.</param>
    /// <returns>The When step.</returns>
    function Before(const AMethodName : string) : IWhen<T>;overload;
    /// <summary>Expects one method first called before the first call of another.</summary>
    /// <param name="AMethodName">The method that must come first.</param>
    /// <param name="ABeforeMethodName">The method it must precede.</param>
    procedure Before(const AMethodName : string; const ABeforeMethodName : string);overload;

    /// <summary>Begins an expectation that the When method is first called after the first call of another.
    /// </summary>
    /// <param name="AMethodName">The method the When method must follow.</param>
    /// <returns>The When step.</returns>
    function After(const AMethodName : string) : IWhen<T>;overload;
    /// <summary>Expects one method first called after the first call of another.</summary>
    /// <param name="AMethodName">The method that must come later.</param>
    /// <param name="AAfterMethodName">The method it must follow.</param>
    procedure After(const AMethodName : string; const AAfterMethodName : string);overload;

    /// <summary>Removes every expectation, here and in every interface the proxy implements.</summary>
    procedure Clear;
  public
    /// <summary>Creates the proxy.</summary>
    /// <param name="AAutoMocker">The auto mock container, or nil.</param>
    /// <param name="AIsStubOnly">Whether the proxy belongs to a stub.</param>
    constructor Create(const AAutoMocker : IAutoMock = nil; const AIsStubOnly : boolean = false); virtual;
    /// <summary>Destroys the proxy, orphaning any mocked instance a test still holds.</summary>
    destructor Destroy; override;
  end;

/// <summary>Tests a virtual interface for an interface, optionally asking its owning proxy.</summary>
/// <param name="Instance">The virtual interface; may be nil.</param>
/// <param name="IID">The interface wanted.</param>
/// <param name="Intf">Receives the interface.</param>
/// <param name="ACheckOwner">Whether to ask the owning proxy as well.</param>
/// <returns>True when supported.</returns>
function Supports(const Instance: IProxyVirtualInterface; const IID: TGUID; out Intf; const ACheckOwner: Boolean): Boolean; overload;
/// <summary>Tests a virtual interface for an interface, optionally asking its owning proxy.</summary>
/// <param name="Instance">The virtual interface; may be nil.</param>
/// <param name="IID">The interface wanted.</param>
/// <param name="ACheckOwner">Whether to ask the owning proxy as well.</param>
/// <returns>True when supported.</returns>
function Supports(const Instance: IProxyVirtualInterface; const IID: TGUID; const ACheckOwner: Boolean): Boolean; overload;
/// <summary>Names a method kind for a message.</summary>
/// <param name="AMethodKind">The method kind.</param>
/// <returns>The name.</returns>
/// <exception cref="Exception">The method kind is not one Delphi defines.</exception>
function MethodKindToStr(const AMethodKind : TMethodKind) : string;

implementation

uses
  Delphi.Mocks.Utils,
  Delphi.Mocks.When,
  Delphi.Mocks.MethodData;

function Supports(const Instance: IProxyVirtualInterface; const IID: TGUID; out Intf; const ACheckOwner: Boolean): Boolean;
begin
  //See if we support the passed in interface. Passed on whether we need to check
  //the owner for the implementation as well.
  Result := (Instance <> nil) and (Instance.QueryInterfaceWithOwner(IID, Intf, ACheckOwner) = 0);
end;

function Supports(const Instance: IProxyVirtualInterface; const IID: TGUID; const ACheckOwner: Boolean): Boolean; overload;
begin
  //See if we support the passed in interface. Passed on whether we need to check
  //the owner for the implementation as well.
  Result := (Instance <> nil) and (Instance.QueryInterfaceWithOwner(IID, ACheckOwner) = 0);
end;

function MethodKindToStr(const AMethodKind : TMethodKind) : string;
begin
  case AMethodKind of
    mkProcedure: Result := 'Procedure';
    mkFunction: Result := 'Function';
    mkConstructor: Result := 'Constructor';
    mkDestructor: Result := 'Destructor';
    mkClassProcedure: Result := 'Class Procedure';
    mkClassFunction: Result := 'Class Function';
    mkClassConstructor: Result := 'Class Constructor';
    mkClassDestructor: Result := 'Class Destructor';
    mkOperatorOverload: Result := 'Operator Overload';
    mkSafeProcedure: Result := 'Safe Procedure';
    mkSafeFunction: Result := 'Safe Function';
  else
    //%d: the argument is an Integer, and %s made this error path raise EConvertError instead.
    raise Exception.CreateFmt('Unexpected method kind passed to [%d]', [Ord(AMethodKind)]);
  end;
end;
{ TProxyBase }

procedure TProxy<T>.AddImplement(const AProxy: IProxy; const ATypeInfo : PTypeInfo);
begin

  if FInterfaceProxies.ContainsKey(GetTypeData(ATypeInfo).Guid) then
    raise EMockProxyAlreadyImplemented.Create('The mock already implements ' + ATypeInfo.NameStr);

  FInterfaceProxies.Add(GetTypeData(ATypeInfo).Guid, AProxy);
  AProxy.SetParentProxy(Self);
end;

procedure TProxy<T>.After(const AMethodName, AAfterMethodName: string);
var
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  GetMethodData(AMethodName, pInfo.NameStr).After(AAfterMethodName);
  ClearSetupState;
end;

function TProxy<T>.After(const AMethodName: string): IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.AfterWhen;
  FBeforeAfterMethodName := AMethodName;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.AtLeast(const AMethodName: string; const times: Cardinal);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.AtLeast(times);
  ClearSetupState;
end;

function TProxy<T>.AtLeast(const times: Cardinal): IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.AtLeastWhen;
  FTimes := times;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.AtLeastOnce(const AMethodName: string);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.AtLeastOnce;
  ClearSetupState;
end;

function TProxy<T>.AtLeastOnce: IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.AtLeastOnceWhen;
  FTimes := 1;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.AtMost(const AMethodName: string; const times: Cardinal);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.AtMost(times);
  ClearSetupState;
end;

function TProxy<T>.AtMost(const times: Cardinal): IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.AtMostWhen;
  FTimes := times;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.Before(const AMethodName, ABeforeMethodName: string);
var
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  GetMethodData(AMethodName, pInfo.NameStr).Before(ABeforeMethodName);
  ClearSetupState;
end;

function TProxy<T>.Before(const AMethodName: string): IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.BeforeWhen;
  FBeforeAfterMethodName := AMethodName;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.BeginSetup(const AMode: TSetupMode);
begin
  FSetupMode := AMode;
  FSetupRefCount := RefCount;
end;

procedure TProxy<T>.CheckMatchers(const matchers: TArray<IMatcher>; const Args: TArray<TValue>; const Method: TRttiMethod);
var
  matcher : IMatcher;
begin
  if Length(matchers) = 0 then
    exit;

  //Every parameter needs a matcher once any has one. A gap (It1 without It0) left a nil
  //matcher that raised an access violation on the first real call, and the expectation path
  //never checked at all, so a literal next to a matcher was silently ignored.
  if Length(matchers) <> Length(Args) - 1 then
    raise EMockSetupException.CreateFmt('Setup of [%s] used matchers for %d of its %d parameters. Use a matcher '
      + '(It0..It9) for every parameter, or for none.', [Method.Name, Length(matchers), Length(Args) - 1]);

  for matcher in matchers do
    if matcher = nil then
      raise EMockSetupException.CreateFmt('Setup of [%s] used matchers for some parameters but not others. Use a '
        + 'matcher (It0..It9) for every parameter, or for none.', [Method.Name]);
end;

procedure TProxy<T>.Between(const AMethodName: string; const a, b: Cardinal);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.Between(a, b);
  ClearSetupState;
end;

function TProxy<T>.Between(const a, b: Cardinal): IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.BetweenWhen;
  FBetween[0] := a;
  FBetween[1] := b;
  result := TWhen<T>.Create(Self.Proxy);

end;

function TProxy<T>.CheckExpectations: string;
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

procedure TProxy<T>.Clear;
begin
  ClearExpectations;
end;

procedure TProxy<T>.ClearExpectations;
var
  methodData : IMethodData;
  proxy : IProxy;
  interfaceV : IVerify;
begin
  for methodData in FMethodData.Values do
  begin
    methodData.ClearExpectations;
  end;

  //Implemented interfaces too, as VerifyAll checks them.
  for proxy in FInterfaceProxies.Values.ToArray do
    if Supports(proxy, IVerify, interfaceV) then
      interfaceV.ClearExpectations;
end;

procedure TProxy<T>.ClearSetupState;
begin
  FSetupMode := TSetupMode.None;
  FReturnValue := TValue.Empty;
  FReturnValueNilAllowed := False;
  FExceptClass := nil;
  FNextFunc := nil;
  FBeforeAfterMethodName := '';
end;

function TProxy<T>.GetAutoMocker : IAutoMock;
begin
  if FAutoMocker <> nil then
    Result := FAutoMocker.Data
  else
    Result := nil;
end;

constructor TProxy<T>.Create(const AAutoMocker : IAutoMock; const AIsStubOnly : boolean);
var
  pInfo : PTypeInfo;
begin
  inherited Create;

  if AAutoMocker <> nil then
    FAutoMocker := TWeakReference<IAutoMock>.Create(AAutoMocker)
  else
    FAutoMocker := nil;
  FParentProxy := nil;
  FVirtualInterface := nil;

  FSetupMode := TSetupMode.None;
  FBehaviorMustBeDefined := False;
  FMethodData := TDictionary<string, IMethodData>.Create;
  FCallLog := TCallLog.Create;
  FIsStubOnly := AIsStubOnly;

  FInterfaceProxies := TDictionary<TGUID, IProxy>.Create;

  pInfo := TypeInfo(T);

  case pInfo.Kind of
    //Create our proxy interface object, which will implement our interface T
    tkInterface :
    begin
      FVirtualInterface := TProxyVirtualInterface.Create(Self, TypeInfo(T), Self.DoInvoke);

    end;
  end;

  FName := pInfo.NameStr;
end;

destructor TProxy<T>.Destroy;
begin
  //A test can still hold the mocked instance. Its invoke handler is bound to this object, so
  //a later call would run in freed memory; make it raise a clear error instead.
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

procedure TProxy<T>.DoInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
  matchers : TArray<IMatcher>;
begin
  pInfo := TypeInfo(T);

  case FSetupMode of
    TSetupMode.None:
    begin
      //An ordinary call has no use for matchers. Any pending here came from an It expression
      //evaluated outside a When, and would otherwise attach themselves to the next setup.
      TMatcherFactory.ClearMatchers;

      //record actual behavior
      methodData := GetMethodData(method.Name, pInfo.NameStr);
      methodData.RecordHit(Args, Method.ReturnType, Method, Result);
    end;
    TSetupMode.Behavior:
    begin
      try
        matchers := TMatcherFactory.GetMatchers;
        CheckMatchers(matchers, Args, Method);
        //record desired behavior
        //first see if we know about this method
        methodData := GetMethodData(method.Name, pInfo.NameStr);
        case FNextBehavior of
          TBehaviorType.WillReturn:
          begin
            case Method.MethodKind of
              mkProcedure,
              mkDestructor,
              mkClassProcedure,
              mkClassDestructor,
              mkSafeProcedure : raise EMockSetupException.CreateFmt('Setup.WillReturn called on [%s] method [%s] which does '
                + 'not have a return value.', [MethodKindToStr(Method.MethodKind), Method.Name]);

              //Method kinds which have a return value.
              mkFunction, mkConstructor, mkClassFunction,
              mkClassConstructor, mkOperatorOverload, mkSafeFunction: ;
            end;

            //We don't test for the return type being valid as XE5 and below have a RTTI bug which does not return
            //a return type for function which reference their own class/interface. Even when RTTI is specified on
            //the declaration and forward declaration.
            if (FReturnValue.IsEmpty and not FReturnValueNilAllowed) or
              (FReturnValueNilAllowed and ((FReturnValue.TypeInfo = nil) or (FReturnValue.TypeData = nil))) then
              raise EMockSetupException.CreateFmt('Setup.WillReturn call on method [%s] was not passed a return value.', [Method.Name]);

            methodData.WillReturnWhen(Args, FReturnValue, matchers);
          end;
          TBehaviorType.WillRaise:
          begin
            methodData.WillRaiseWhen(FExceptClass, FExceptionMessage, Args, matchers);
          end;
          TBehaviorType.WillRaiseAlways:
          begin
            methodData.WillRaiseAlways(FExceptClass, FExceptionMessage);
          end;
          TBehaviorType.WillExecuteWhen :
          begin
            methodData.WillExecuteWhen(FNextFunc, Args, matchers);
          end;
        end;
      finally
        ClearSetupState;
      end;
    end;
    TSetupMode.Expectation:
    begin
      try
        matchers := TMatcherFactory.GetMatchers;
        CheckMatchers(matchers, Args, Method);
        //record expectations
        //first see if we know about this method
        methodData := GetMethodData(method.Name, pInfo.NameStr);

        case FNextExpectation of
          OnceWhen        : methodData.OnceWhen(Args, matchers);
          NeverWhen       : methodData.NeverWhen(Args, matchers) ;
          AtLeastOnceWhen : methodData.AtLeastOnceWhen(Args, matchers);
          AtLeastWhen     : methodData.AtLeastWhen(FTimes, args, matchers);
          AtMostOnceWhen  : methodData.AtMostWhen(1, Args, matchers);
          AtMostWhen      : methodData.AtMostWhen(FTimes, args, matchers);
          BetweenWhen     : methodData.BetweenWhen(FBetween[0], FBetween[1], Args, matchers);
          ExactlyWhen     : methodData.ExactlyWhen(FTimes, Args, matchers);
          BeforeWhen      : methodData.BeforeWhen(FBeforeAfterMethodName, Args, matchers);
          AfterWhen       : methodData.AfterWhen(FBeforeAfterMethodName, Args, matchers);
        end;

      finally
        ClearSetupState;
      end;
    end;
  end;

end;

procedure TProxy<T>.Exactly(const AMethodName: string; const times: Cardinal);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.Exactly(times);
  ClearSetupState;
end;

function TProxy<T>.Exactly(const times: Cardinal): IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.ExactlyWhen;
  FTimes := times;
  result := TWhen<T>.Create(Self.Proxy);
end;

function TProxy<T>.Expect: IExpect<T>;
begin
  result := Self as IExpect<T> ;
end;

function TProxy<T>.GetBehaviorMustBeDefined: boolean;
begin
  Result := FBehaviorMustBeDefined;
end;

function TProxy<T>.GetAllowRedefineBehaviorDefinitions : boolean;
begin
  result := FAllowRedefineBehaviorDefinitions;
end;

function TProxy<T>.GetMethodData(const AMethodName: string; const ATypeName: string): IMethodData;
var
  methodName : string;
  setupParams: TSetupMethodDataParameters;
begin
  methodName := LowerCase(AMethodName);
  if FMethodData.TryGetValue(methodName, Result) then
    exit;
  
  setupParams := TSetupMethodDataParameters.Create(FIsStubOnly, FBehaviorMustBeDefined, FAllowRedefineBehaviorDefinitions);
  Result := TMethodData.Create(ATypeName, AMethodName, setupParams, GetAutoMocker, FCallLog);
  FMethodData.Add(methodName, Result);
end;

function TProxy<T>.QueryImplementedInterface(const IID: TGUID; out Obj): HRESULT;
var
  virtualProxy : IProxy;
  parent : IProxy;
begin
  Result := E_NOINTERFACE;

  if FQueryingInternalInterface then
    Exit;

  FQueryingInternalInterface := True;
  try
    Result := FVirtualInterface.QueryInterface(IID, obj);
    if Result = S_OK then
      Exit;

    //Otherwise look in the list of interface proxies that might have been implemented
    if (FInterfaceProxies.ContainsKey(IID)) then
    begin
      virtualProxy := FInterfaceProxies.Items[IID];
      Result := virtualProxy.ProxyInterface.QueryInterface(IID, Obj);

      if Result = S_OK then
        Exit;
    end;

    //Call the parent. FQueryingInternalInterface stops the parent's search coming back here.
    //The parent is held weakly and may already be gone: answer E_NOINTERFACE, not an AV.
    if FParentProxy <> nil then
    begin
      parent := FParentProxy.Data;
      if parent = nil then
        Exit;

      Result := parent.QueryInterface(IID, obj);
      if Result = S_OK then
        Exit;

      Result := parent.QueryImplementedInterface(IID, obj);
    end;
  finally
    FQueryingInternalInterface := False;
  end;
end;

procedure TProxy<T>.Never(const AMethodName: string);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.Never;
  ClearSetupState;
end;

function TProxy<T>.Never: IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.NeverWhen;
  result := TWhen<T>.Create(Self.Proxy);
end;

function TProxy<T>.Once: IWhen<T>;
begin
  BeginSetup(TSetupMode.Expectation);
  FNextExpectation := TExpectationType.OnceWhen;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.Once(const AMethodName: string);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);

  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.Once;
  ClearSetupState;
end;


function TProxy<T>.Proxy: T;
var
  pInfo : PTypeInfo;
//  virtualProxy : IInterface;
begin
  pInfo := TypeInfo(T);

  if FVirtualInterface = nil then
    raise EMockNoProxyException.Create('Error casting to interface ' + pInfo.NameStr + ' , proxy does not appear to implement T');

  if FVirtualInterface.QueryInterface(GetTypeData(pInfo).Guid, result) <> 0 then
    raise EMockNoProxyException.Create('Error casting to interface ' + pInfo.NameStr + ' , proxy does not appear to implement T');
end;

function TProxy<T>.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  Result := E_NOINTERFACE;

  //If we are already querying this interface, leave.
  if FQueryingInterface then
    Exit;

  FQueryingInterface := True;
  try
    //The interface requested might be one of this classes interfaces. E.g. IProxy
    if not (IID = IInterface) then
      Result := inherited QueryInterface(IID, Obj);

    //If we have found the interface then return it.
    if Result = S_OK then
      Exit;
  finally
    FQueryingInterface := False;
  end;
end;

procedure TProxy<T>.ResetCalls;
var
  methodData : IMethodData;
  proxy : IProxy;
  interfaceV : IVerify;
begin
  for methodData in FMethodData.Values do
  begin
    methodData.ResetCalls;
  end;
  FCallLog.Clear;

  //Implemented interfaces too: VerifyAll checks them, so calls recorded on them before the
  //reset still failed it.
  for proxy in FInterfaceProxies.Values.ToArray do
    if Supports(proxy, IVerify, interfaceV) then
      interfaceV.ResetCalls;
end;

procedure TProxy<T>.SetBehaviorMustBeDefined(const value: boolean);
begin
  FBehaviorMustBeDefined := value;
end;

procedure TProxy<T>.SetAllowRedefineBehaviorDefinitions(const value : boolean);
begin
  FAllowRedefineBehaviorDefinitions := value;
end;

procedure TProxy<T>.SetParentProxy(const AProxy : IProxy);
begin
  FParentProxy := TWeakReference<IProxy>.Create(AProxy);
end;

function TProxy<T>.ProxyFromType(const ATypeInfo: PTypeInfo): IProxy;
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

  raise EMockNoProxyException.Create('Error - No Proxy of type [' + ATypeInfo.NameStr + '] was found');
end;

function TProxy<T>.ProxySupports(const Instance: IInterface; const IID: TGUID): boolean;
begin
  //We support the proxy if we have a virtual interface, which supports the passed in
  //interface. As the virtual interface is built to support mulitple interfaces we
  //need to ask it not check the other implementations.
  Result := (FVirtualInterface <> nil) and Supports(FVirtualInterface, IID, False);
end;

function TProxy<T>.StubSetup: IStubSetup<T>;
begin
  result := Self;
end;

function TProxy<T>.SupportsIInterface: Boolean;
begin
  Result := (FParentProxy = nil);
end;

function TProxy<T>.MockSetup: IMockSetup<T>;
begin
  result := Self;
end;

function TProxy<T>.ProxyInterface: IInterface;
var
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(T);

  if FVirtualInterface = nil then
    raise EMockNoProxyException.Create('Error casting to interface ' + pInfo.NameStr + ' , proxy does not appear to implement T');

  if FVirtualInterface.QueryInterface(GetTypeData(pInfo).Guid, result) <> 0 then
    raise EMockNoProxyException.Create('Error casting to interface ' + pInfo.NameStr + ' , proxy does not appear to implement T');
end;

procedure TProxy<T>.Verify(const message: string);
var
  msg : string;
begin
  msg := CheckExpectations;
  if msg <> '' then
    raise EMockVerificationException.Create(message + #13#10 + msg);

end;

function TProxy<T>.WillExecute(const func: TExecuteFunc): IWhen<T>;
begin
  BeginSetup(TSetupMode.Behavior);
  FNextBehavior := TBehaviorType.WillExecuteWhen;
  FNextFunc := func;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.WillExecute(const AMethodName: string; const func: TExecuteFunc);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  //actually record the behaviour here!
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.WillExecute(func);
  ClearSetupState;
end;

function TProxy<T>.WillRaise(const exceptionClass: ExceptClass;const message : string): IWhen<T>;
begin
  BeginSetup(TSetupMode.Behavior);
  FNextBehavior := TBehaviorType.WillRaiseAlways;
  FExceptClass := exceptionClass;
  FExceptionMessage := message;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.WillRaise(const AMethodName: string; const exceptionClass: ExceptClass;const message : string);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  //actually record the behaviour here!
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.WillRaiseAlways(exceptionClass, message);
  ClearSetupState;
end;

function TProxy<T>.WillRaiseWhen(const exceptionClass: ExceptClass; const message: string): IWhen<T>;
begin
  BeginSetup(TSetupMode.Behavior);
  FNextBehavior := TBehaviorType.WillRaise;
  FExceptClass := exceptionClass;
  FExceptionMessage := message;
  result := TWhen<T>.Create(Self.Proxy);
end;

function TProxy<T>.WillReturn(const value: TValue): IWhen<T>;
begin
  BeginSetup(TSetupMode.Behavior);
  FReturnValue := value;
  FNextBehavior := TBehaviorType.WillReturn;
  result := TWhen<T>.Create(Self.Proxy);
end;

function TProxy<T>.WillReturn(const value: TValue; const AllowNil: Boolean): IWhen<T>;
begin
  BeginSetup(TSetupMode.Behavior);
  FReturnValue := value;
  FReturnValueNilAllowed := AllowNil;
  FNextBehavior := TBehaviorType.WillReturn;
  result := TWhen<T>.Create(Self.Proxy);
end;

procedure TProxy<T>.WillReturnDefault(const AMethodName : string; const value : TValue);
var
  methodData : IMethodData;
  pInfo : PTypeInfo;
begin
  //actually record the behaviour here!
  pInfo := TypeInfo(T);
  methodData := GetMethodData(AMethodName, pInfo.NameStr);
  methodData.WillReturnDefault(value);
  ClearSetupState;
end;

function TProxy<T>.WillReturnNil: IWhen<T>;
begin
  BeginSetup(TSetupMode.Behavior);
  FReturnValue := TValue.From<Pointer>(nil);
  FReturnValueNilAllowed := True;
  FNextBehavior := TBehaviorType.WillReturn;
  result := TWhen<T>.Create(Self.Proxy);
end;

function TProxy<T>._Release: Integer;
var
  setupAbandoned : boolean;
begin
  //A setup is abandoned when its When call never reached the proxy (a non-virtual method). The
  //statement's temporary references are then released, taking the count below where it stood
  //when the setup began. Any release used to count, so a transient AddRef/Release pair made
  //while the When arguments were evaluated was reported as a non-virtual method.
  setupAbandoned := (FSetupMode <> TSetupMode.None) and (RefCount <= FSetupRefCount);
  if setupAbandoned then
    ClearSetupState;

  // Decrement first, then report. Raising before the inherited call left the reference
  // count permanently high, so the proxy and everything it owns leaked.
  result := inherited;

  if setupAbandoned then
    raise EMockSetupException.Create('Setup called on non-virtual method: the method named after When never reached '
      + 'the mock, because it is not virtual or the mock answers it itself (QueryInterface, _AddRef, _Release)');
end;

{ TProxy<T>.TProxyVirtualInterface }

constructor TProxy<T>.TProxyVirtualInterface.Create(const AProxy : IProxy<T>;
  const AInterface: Pointer; const InvokeEvent: TVirtualInterfaceInvokeEvent);
begin
  //Create a weak reference to our owner proxy. This is the proxy who implements
  //all the mocking interfaces required to setup, and verify us.
  FProxy := TWeakReference<IProxy<T>>.Create(AProxy);

  inherited Create(Ainterface, InvokeEvent);
end;

function TProxy<T>.TProxyVirtualInterface.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  //The default query interface will ask the owner for the implementing virtual
  //interface for the type being queried for. This allows a virtual interface of
  //IInterfaceOne to support IInterfaceTwo when asked.
  Result := QueryInterfaceWithOwner(IID, Obj, True);
end;

function TProxy<T>.TProxyVirtualInterface.QueryInterfaceWithOwner(const IID: TGUID; out Obj; const ACheckOwner: Boolean): HRESULT;
var
  owner : IProxy<T>;
begin
  //See if we support the passed in interface.

  if IsEqualGUID(IID, IInterface) and not SupportsIInterface then
    Result := E_NOINTERFACE
  else
    Result := inherited QueryInterface(IID, Obj);

  //If we don't support the interface, then we need to look to our owner to see
  //who does implement it. This allows for a single proxy to implement multiple
  //interfaces at once.
  //FProxy is the weak reference object, which outlives the proxy, so test what it points at:
  //Data is nil once the mock has been released, and dereferencing it raised an AV.
  if (ACheckOwner) and (Result <> 0) and (FProxy <> nil) then
  begin
    owner := FProxy.Data;
    if owner <> nil then
      Result := owner.QueryImplementedInterface(IID, Obj);
  end;
end;

function TProxy<T>.TProxyVirtualInterface.QueryInterfaceWithOwner(const IID: TGUID; const ACheckOwner: Boolean): HRESULT;
var
  dud : IInterface;
begin
  Result := QueryInterfaceWithOwner(IID, dud, ACheckOwner);
end;

procedure TProxy<T>.TProxyVirtualInterface.Orphan(const ATypeName: string);
begin
  OnInvoke :=
    procedure(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue)
    begin
      raise EMockException.CreateFmt('[%s].%s was called after the mock that created it was freed.', [ATypeName, Method.Name]);
    end;
end;

function TProxy<T>.TProxyVirtualInterface.SupportsIInterface: Boolean;
var
  owner : IProxy<T>;
begin
  Result := True;
  if FProxy <> nil then
  begin
    owner := FProxy.Data;
    if owner <> nil then
      Result := owner.SupportsIInterface;
  end;
end;

procedure TProxy<T>.VerifyAll(const message: string);
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
