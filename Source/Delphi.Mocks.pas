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

unit Delphi.Mocks;

interface

{$I 'Delphi.Mocks.inc'}

uses
  System.TypInfo,
  System.Rtti,
  System.Sysutils,
  System.RegularExpressions,
  System.Generics.Defaults,
  System.Generics.Collections,
  Delphi.Mocks.WeakReference;

type
  IWhen<T> = interface;

  //Records the expectations we have when our Mock is used. We can then verify
  //our expectations later.
  /// <summary>Sets the expectations of a mock: how often its methods are called, optionally with particular
  /// arguments, and in what order. Each function form returns a When step naming the method by calling it; each
  /// procedure form names the method as a string and ignores its arguments.</summary>
  IExpect<T> = interface
    ['{8B9919F1-99AB-4526-AD90-4493E9343083}']
    /// <summary>Expects exactly one call with the When call's arguments.</summary>
    /// <returns>The When step.</returns>
    function Once : IWhen<T>;overload;
    /// <summary>Expects exactly one call, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure Once(const AMethodName : string);overload;

    /// <summary>Expects no call with the When call's arguments.</summary>
    /// <returns>The When step.</returns>
    function Never : IWhen<T>;overload;
    /// <summary>Expects no call, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure Never(const AMethodName : string);overload;

    /// <summary>Expects one or more calls with the When call's arguments.</summary>
    /// <returns>The When step.</returns>
    function AtLeastOnce : IWhen<T>;overload;
    /// <summary>Expects one or more calls, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <exception cref="EMockException">An at-least expectation is already defined.</exception>
    procedure AtLeastOnce(const AMethodName : string);overload;

    /// <summary>Expects a minimum number of calls with the When call's arguments.</summary>
    /// <param name="times">The minimum.</param>
    /// <returns>The When step.</returns>
    function AtLeast(const times : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects a minimum number of calls, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="times">The minimum.</param>
    /// <exception cref="EMockException">An at-least expectation is already defined.</exception>
    procedure AtLeast(const AMethodName : string; const times : Cardinal);overload;

    /// <summary>Expects a maximum number of calls with the When call's arguments.</summary>
    /// <param name="times">The maximum.</param>
    /// <returns>The When step.</returns>
    function AtMost(const times : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects a maximum number of calls, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="times">The maximum.</param>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure AtMost(const AMethodName : string; const times : Cardinal);overload;

    /// <summary>Expects an inclusive range of calls with the When call's arguments.</summary>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum; must not be less than a.</param>
    /// <returns>The When step.</returns>
    function Between(const a, b : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects an inclusive range of calls, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum; must not be less than a.</param>
    /// <exception cref="EMockSetupException">b is less than a.</exception>
    procedure Between(const AMethodName : string; const a,b : Cardinal);overload;

    /// <summary>Expects an exact number of calls with the When call's arguments.</summary>
    /// <param name="times">The number of calls.</param>
    /// <returns>The When step.</returns>
    function Exactly(const times : Cardinal) : IWhen<T>;overload;
    /// <summary>Expects an exact number of calls, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="times">The number of calls.</param>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure Exactly(const AMethodName : string; const times : Cardinal);overload;

    /// <summary>Expects the When method, with the When call's arguments, to be first called before the first call
    /// of another method. Both must be called for the expectation to be met.</summary>
    /// <param name="AMethodName">The method the When method must precede.</param>
    /// <returns>The When step.</returns>
    function Before(const AMethodName : string) : IWhen<T>;overload;
    /// <summary>Expects one method to be first called before the first call of another. Both must be called.
    /// </summary>
    /// <param name="AMethodName">The method that must come first.</param>
    /// <param name="ABeforeMethodName">The method it must precede.</param>
    procedure Before(const AMethodName : string; const ABeforeMethodName : string);overload;

    /// <summary>Expects the When method, with the When call's arguments, to be first called after the first call
    /// of another method. Both must be called for the expectation to be met.</summary>
    /// <param name="AMethodName">The method the When method must follow.</param>
    /// <returns>The When step.</returns>
    function After(const AMethodName : string) : IWhen<T>;overload;
    /// <summary>Expects one method to be first called after the first call of another. Both must be called.
    /// </summary>
    /// <param name="AMethodName">The method that must come later.</param>
    /// <param name="AAfterMethodName">The method it must follow.</param>
    procedure After(const AMethodName : string; const AAfterMethodName : string);overload;

    /// <summary>Removes every expectation, including those of the interfaces the mock implements.</summary>
    procedure Clear;
  end;

  /// <summary>The step of a setup that names the method: call the method on When's result, with the arguments
  /// (or It0..It9 matchers) the setup applies to.</summary>
  IWhen<T> = interface
    ['{A8C2E07B-A5C1-463D-ACC4-BA2881E8419F}']
    /// <summary>Returns the mocked instance in setup mode; the next call on it completes the setup.</summary>
    /// <returns>The mocked instance.</returns>
    function When : T;
  end;

  ///  This is the definition for an anonymous function you can pass into
  ///  WillExecute. The args array will be the arguments passed to the method
  ///  called on the Mock. If the method returns a value then your anon func must
  ///  return that.. and the return type must match. The return type is passed in
  ///  so that you can ensure tha.
  /// <summary>A function a WillExecute behaviour runs in place of the mocked method.</summary>
  /// <param name="args">The call's arguments; args[0] is Self, the first real argument is args[1].</param>
  /// <param name="ReturnType">The method's return type, or nil for a procedure.</param>
  /// <returns>The value the mocked method returns; it must match ReturnType.</returns>
  TExecuteFunc = reference to function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue;

  /// <summary>Configures what a stub (or mock) does when its methods are called.</summary>
  IStubSetup<T> = interface
    ['{3E6AD69A-11EA-47F1-B5C3-63F7B8C265B1}']
    /// <summary>Returns whether a call to a method with no behaviour raises.</summary>
    /// <returns>The setting.</returns>
    function GetBehaviorMustBeDefined : boolean;
    /// <summary>Sets whether a call to a method with no behaviour raises.</summary>
    /// <param name="value">The setting.</param>
    procedure SetBehaviorMustBeDefined(const value : boolean);
    /// <summary>Returns whether a definition may replace an existing one.</summary>
    /// <returns>The setting.</returns>
    function GetAllowRedefineBehaviorDefinitions : boolean;
    /// <summary>Sets whether a definition may replace an existing one.</summary>
    /// <param name="value">The setting.</param>
    procedure SetAllowRedefineBehaviorDefinitions(const value : boolean);

    //set the return value for a method when called with the parameters specified on the When
    /// <summary>Returns a value when the method is called with the When call's arguments. Where definitions
    /// overlap, the most recent one wins.</summary>
    /// <param name="value">The value to return; must not be empty.</param>
    /// <returns>The When step.</returns>
    function WillReturn(const value : TValue) : IWhen<T>; overload;

    //set the return value for a method when called with the parameters specified on the When
    //AllowNil flag allow to define: returning nil value is allowed or not.
    /// <summary>Returns a value, possibly nil, when the method is called with the When call's arguments.</summary>
    /// <param name="value">The value to return.</param>
    /// <param name="AllowNil">Whether nil is an acceptable value.</param>
    /// <returns>The When step.</returns>
    function WillReturn(const value : TValue; const AllowNil: Boolean) : IWhen<T>; overload;

    //set the nil as return value for a method when called with the parameters specified on the When
    /// <summary>Returns nil when the method is called with the When call's arguments.</summary>
    /// <returns>The When step.</returns>
    function WillReturnNil : IWhen<T>;

    //Will exedute the func when called with the specified parameters
    /// <summary>Runs a function when the method is called with the When call's arguments.</summary>
    /// <param name="func">The function to run.</param>
    /// <returns>The When step.</returns>
    function WillExecute(const func : TExecuteFunc) : IWhen<T>;overload;

    //will always execute the func no matter what parameters are specified.
    /// <summary>Runs a function on every call of a method, whatever the arguments.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="func">The function to run.</param>
    /// <exception cref="EMockSetupException">The behaviour is already defined.</exception>
    procedure WillExecute(const AMethodName : string; const func : TExecuteFunc);overload;

    //set the default return value for a method when it is called with parameter values we
    //haven't specified
    /// <summary>Sets the value a method returns when no other behaviour applies. On a class mock this also stops
    /// the real method running.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="value">The default value; nil and empty values are allowed.</param>
    /// <exception cref="EMockSetupException">A default is already defined and redefinition is not allowed.
    /// </exception>
    procedure WillReturnDefault(const AMethodName : string; const value : TValue);

    //set the Exception class that will be raised when the method is called with the parmeters specified
    /// <summary>Raises on every call of the When method, whatever the arguments.</summary>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message; empty for a generic one.</param>
    /// <returns>The When step.</returns>
    function WillRaise(const exceptionClass : ExceptClass; const message : string = '') : IWhen<T>;overload;

    //This method will always raise an exception.. this behavior will trump any other defined behaviors
    /// <summary>Raises on every call of a method; this trumps every other behaviour.</summary>
    /// <param name="AMethodName">The method.</param>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message; empty for a generic one.</param>
    /// <exception cref="EMockSetupException">The behaviour is already defined.</exception>
    procedure WillRaise(const AMethodName : string; const exceptionClass : ExceptClass; const message : string = '');overload;

    //set the Exception class that will be raised when the method is called with the parmeters specified
    /// <summary>Raises when the method is called with the When call's arguments.</summary>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message; empty for a generic one.</param>
    /// <returns>The When step.</returns>
    function WillRaiseWhen(const exceptionClass: ExceptClass; const message: string = ''): IWhen<T>;

    //If true, calls to methods for which we have not defined a behavior will cause verify to fail.
    /// <summary>If True, a call to a method with no behaviour, default or expectation raises.</summary>
    property BehaviorMustBeDefined : boolean read GetBehaviorMustBeDefined write SetBehaviorMustBeDefined;

    //If true, it is possible to overwrite a already defined behaviour.
    /// <summary>If True, defining a behaviour or expectation again replaces the old one instead of raising.
    /// </summary>
    property AllowRedefineBehaviorDefinitions: boolean read GetAllowRedefineBehaviorDefinitions write SetAllowRedefineBehaviorDefinitions;
  end;

  //We use the Setup to configure our expected behaviour rules and to verify
  //that those expectations were met.
  /// <summary>Configures a mock: its behaviours, as for a stub, and its expectations.</summary>
  IMockSetup<T> = interface(IStubSetup<T>)
    ['{D6B21933-BF51-4937-877E-51B59A3B3268}']
    //Set Expectations for methods
    /// <summary>Returns the expectation setup.</summary>
    /// <returns>The expectation setup.</returns>
    function Expect : IExpect<T>;
  end;

  /// <summary>The proxy behind a TStub&lt;T&gt;.</summary>
  IStubProxy<T> = interface
    ['{578BAF90-4155-4C0F-AAED-407057C6384F}']
    /// <summary>Returns the stub's setup.</summary>
    /// <returns>The setup.</returns>
    function Setup : IStubSetup<T>;
    /// <summary>Returns the stubbed instance.</summary>
    /// <returns>The instance.</returns>
    function Proxy : T;
  end;

  {$IFOPT M+}
    {$M-}
    {$DEFINE ENABLED_M+}
  {$ENDIF}
  /// <summary>The type-independent face of a mock's proxy.</summary>
  IProxy = interface(IWeakReferenceableObject)
    ['{C97DC7E8-BE99-46FE-8488-4B356DD4AE29}']
    /// <summary>Returns the mocked interface.</summary>
    /// <returns>The mocked instance, as IInterface.</returns>
    /// <exception cref="EMockNoProxyException">The proxy mocks no interface.</exception>
    function ProxyInterface : IInterface;
    /// <summary>Finds the proxy, this one or one added by Implement, that implements a type.</summary>
    /// <param name="ATypeInfo">The interface type.</param>
    /// <returns>The proxy.</returns>
    /// <exception cref="EMockNoProxyException">No proxy implements the type.</exception>
    function ProxyFromType(const ATypeInfo : PTypeInfo) : IProxy;
    /// <summary>Adds the proxy of an extra interface the mock implements.</summary>
    /// <param name="AProxy">The interface's proxy.</param>
    /// <param name="ATypeInfo">The interface type.</param>
    /// <exception cref="EMockProxyAlreadyImplemented">The interface is already implemented.</exception>
    procedure AddImplement(const AProxy : IProxy; const ATypeInfo : PTypeInfo);
    /// <summary>Looks for an interface among those the proxy and its relatives implement.</summary>
    /// <param name="IID">The interface wanted.</param>
    /// <param name="Obj">Receives the interface.</param>
    /// <returns>S_OK, or E_NOINTERFACE.</returns>
    function QueryImplementedInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    /// <summary>Records the proxy this one was added to by Implement.</summary>
    /// <param name="AProxy">The parent proxy.</param>
    procedure SetParentProxy(const AProxy : IProxy);
    /// <summary>Whether the proxy's interface answers for IInterface: only a top-level proxy's does.</summary>
    /// <returns>True for a proxy that has no parent.</returns>
    function SupportsIInterface: Boolean;
  end;
  {$IFDEF ENABLED_M+}
    {$M+}
  {$ENDIF}

  //used by the mock - need to find another place to put this.. circular references
  //problem means we need it here for now.
  /// <summary>The proxy behind a TMock&lt;T&gt;. Every IProxy&lt;X&gt; shares one GUID, so Supports cannot tell
  /// one X from another; reach a particular interface's proxy through ProxyFromType instead.</summary>
  IProxy<T> = interface(IProxy)
    ['{1E3A98C5-78BA-4D65-A4BA-B6992B8B4783}']
    /// <summary>Returns the mock's setup.</summary>
    /// <returns>The setup.</returns>
    function Setup : IMockSetup<T>;
    /// <summary>Returns the mocked instance.</summary>
    /// <returns>The instance.</returns>
    function Proxy : T;
  end;

  /// <summary>Creates and keeps the mocks an auto mock container hands out, including those it creates for the
  /// interfaces mocked methods return.</summary>
  IAutoMock = interface
    ['{9C7113DF-6F93-496D-A223-61D30782C7D8}']
    /// <summary>Creates and keeps a mock of an interface.</summary>
    /// <param name="ATypeInfo">The interface type.</param>
    /// <returns>The mock's proxy.</returns>
    /// <exception cref="EMockException">The type is not an interface with RTTI.</exception>
    function Mock(const ATypeInfo : PTypeInfo) : IProxy;
    /// <summary>Keeps a mock created elsewhere.</summary>
    /// <param name="ATypeName">The mocked type's name.</param>
    /// <param name="AMock">The mock's proxy.</param>
    procedure Add(const ATypeName : string; const AMock: IProxy);
  end;

  /// <summary>A stub: a fake implementation of an interface or class whose methods return set values, with no
  /// expectations to verify. A record, so it needs no freeing.</summary>
  TStub<T> = record
  private
    /// <summary>The stub's proxy; nil until Create, and after Free.</summary>
    FProxy : IStubProxy<T>;
    /// <summary>Unused by stubs; kept for symmetry with TMock&lt;T&gt;.</summary>
    FAutomocker : IAutoMock;
    /// <summary>Checks that the stub has been created and not freed.</summary>
    /// <exception cref="EMockException">Create was not called, or Free has been.</exception>
    procedure CheckCreated;
  public
    /// <summary>Converts the stub to the stubbed instance.</summary>
    /// <param name="Value">The stub.</param>
    /// <returns>The instance.</returns>
    /// <exception cref="EMockException">The stub has not been created, or has been freed.</exception>
    class operator Implicit(const Value: TStub<T>): T;
    /// <summary>Returns the stub's setup.</summary>
    /// <returns>The setup.</returns>
    /// <exception cref="EMockException">The stub has not been created, or has been freed.</exception>
    function Setup : IStubSetup<T>;
    /// <summary>Returns the stubbed instance.</summary>
    /// <returns>The instance.</returns>
    /// <exception cref="EMockException">The stub has not been created, or has been freed.</exception>
    function Instance : T;
    /// <summary>Returns the stubbed instance as a TValue.</summary>
    /// <returns>The instance.</returns>
    /// <exception cref="EMockException">The stub has not been created, or has been freed.</exception>
    function InstanceAsValue : TValue;
    /// <summary>Creates a stub; a class is constructed with its parameterless Create.</summary>
    /// <returns>The stub.</returns>
    /// <exception cref="EMockNoRTTIException">T has no RTTI to stub.</exception>
    /// <exception cref="EMockException">T is not an interface or a class.</exception>
    class function Create: TStub<T>; overload; static;
    /// <summary>Creates a stub of a class from an instance the caller constructs.</summary>
    /// <param name="ACreateObjectFunc">Constructs the instance; nil uses the parameterless Create.</param>
    /// <returns>The stub.</returns>
    /// <exception cref="EMockNoRTTIException">T has no RTTI to stub.</exception>
    /// <exception cref="EMockException">T is not an interface or a class.</exception>
    class function Create(const ACreateObjectFunc: TFunc<T>): TStub<T>; overload; static;
    // explicit cleanup. Not sure if we really need this.
    /// <summary>Releases the stub early. Calling it again does nothing.</summary>
    procedure Free;
  end;

  //We use a record here to take advantage of operator overloading, the Implicit
  //operator allows us to use the mock as the interface without holding a reference
  //to the mock interface outside of the mock.
  /// <summary>A mock: a fake implementation of an interface or class whose behaviour is set up, and whose use is
  /// verified afterwards against expectations. A record, so it needs no freeing.</summary>
  TMock<T> = record
  private
    /// <summary>The mock's proxy; nil until Create, and after Free. Being managed it starts nil even in an
    /// uninitialised local, so it alone says whether the mock is usable.</summary>
    FProxy : IProxy<T>;
    /// <summary>The auto mock container the mock belongs to, or nil.</summary>
    FAutomocker : IAutoMock;

    /// <summary>Checks that the mock has been created and not freed.</summary>
    /// <exception cref="EMockException">Create was not called, or Free has been.</exception>
    procedure CheckCreated;

  public
    /// <summary>Converts the mock to the mocked instance.</summary>
    /// <param name="Value">The mock.</param>
    /// <returns>The instance.</returns>
    /// <exception cref="EMockException">The mock has not been created, or has been freed.</exception>
    class operator Implicit(const Value: TMock<T>): T;
    /// <summary>Creates a mock that belongs to an auto mock container.</summary>
    /// <param name="AAutoMock">The container, or nil.</param>
    /// <param name="ACreateObjectFunc">For a class, constructs the instance; nil uses the parameterless Create.
    /// </param>
    /// <returns>The mock.</returns>
    /// <exception cref="EMockNoRTTIException">T has no RTTI to mock.</exception>
    /// <exception cref="EMockException">T is not an interface or a class.</exception>
    class function Create(const AAutoMock: IAutoMock; const ACreateObjectFunc: TFunc<T>): TMock<T>; overload; static;

    /// <summary>Returns the mock's setup.</summary>
    /// <returns>The setup.</returns>
    /// <exception cref="EMockException">The mock has not been created, or has been freed.</exception>
    function Setup : IMockSetup<T>; overload;
    /// <summary>Returns the setup of an interface added with Implement.</summary>
    /// <returns>The setup.</returns>
    /// <exception cref="EMockNoProxyException">The mock does not implement I.</exception>
    function Setup<I : IInterface> : IMockSetup<I>; overload;

    //Verify that our expectations were met.
    /// <summary>Checks the mock's own expectations.</summary>
    /// <param name="message">Text placed before the detail of a failure.</param>
    /// <exception cref="EMockVerificationException">An expectation is not met.</exception>
    procedure Verify(const message : string = ''); overload;
    /// <summary>Checks the expectations of an interface added with Implement.</summary>
    /// <param name="message">Text placed before the detail of a failure.</param>
    /// <exception cref="EMockNoProxyException">The mock does not implement I.</exception>
    /// <exception cref="EMockVerificationException">An expectation is not met.</exception>
    procedure Verify<I : IInterface>(const message : string = ''); overload;
    /// <summary>Checks the expectations of the mock and of every interface added with Implement.</summary>
    /// <param name="message">Text placed before the detail of a failure.</param>
    /// <exception cref="EMockVerificationException">An expectation is not met.</exception>
    procedure VerifyAll(const message : string = '');
    /// <summary>Forgets every recorded call, including those of the interfaces added with Implement.</summary>
    procedure ResetCalls;

    /// <summary>Describes every unmet expectation of the mock itself.</summary>
    /// <returns>The description, or an empty string.</returns>
    function CheckExpectations: string;
    /// <summary>Makes the mock implement a further interface.</summary>
    /// <exception cref="ENotSupportedException">The mock is of a class; only interface mocks can.</exception>
    /// <exception cref="EMockProxyAlreadyImplemented">The interface is already implemented.</exception>
    procedure Implement<I : IInterface>; overload;
    /// <summary>Returns the mocked instance.</summary>
    /// <returns>The instance.</returns>
    function Instance : T; overload;
    /// <summary>Returns the mock as an interface added with Implement.</summary>
    /// <returns>The instance, as I.</returns>
    /// <exception cref="EMockNoProxyException">The mock does not implement I.</exception>
    function Instance<I : IInterface> : I; overload;
    /// <summary>Returns the mocked instance as a TValue.</summary>
    /// <returns>The instance.</returns>
    function InstanceAsValue : TValue; overload;
    /// <summary>Returns the mock, as an interface added with Implement, as a TValue.</summary>
    /// <returns>The instance.</returns>
    /// <exception cref="EMockNoProxyException">The mock does not implement I.</exception>
    function InstanceAsValue<I : IInterface> : TValue; overload;

    /// <summary>Creates a mock; a class is constructed with its parameterless Create.</summary>
    /// <returns>The mock.</returns>
    /// <exception cref="EMockNoRTTIException">T has no RTTI to mock.</exception>
    /// <exception cref="EMockException">T is not an interface or a class.</exception>
    class function Create: TMock<T>; overload; static;
    /// <summary>Creates a mock of a class from an instance the caller constructs.</summary>
    /// <param name="ACreateObjectFunc">Constructs the instance; nil uses the parameterless Create.</param>
    /// <returns>The mock.</returns>
    /// <exception cref="EMockNoRTTIException">T has no RTTI to mock.</exception>
    /// <exception cref="EMockException">T is not an interface or a class.</exception>
    class function Create(const ACreateObjectFunc: TFunc<T>): TMock<T>; overload; static;

    //Explicit cleanup. Not sure if we really need this.
    /// <summary>Releases the mock early. Calling it again does nothing; any other use afterwards raises.
    /// </summary>
    procedure Free;
  end;

  /// <summary>A container that creates mocks and, for every interface their methods return, a further mock.
  /// </summary>
  TAutoMockContainer = record
  private
    /// <summary>The container's auto mocker; nil until Create.</summary>
    FAutoMocker : IAutoMock;
    /// <summary>Checks that Create was called.</summary>
    /// <exception cref="EMockException">Create was not called.</exception>
    procedure CheckCreated;
  public
    /// <summary>Creates a mock that belongs to the container.</summary>
    /// <returns>The mock.</returns>
    /// <exception cref="EMockException">Create was not called, or T cannot be mocked.</exception>
    function Mock<T> : TMock<T>; overload;
    /// <summary>Creates a mock of an interface known only by its type info.</summary>
    /// <param name="ATypeInfo">The interface type.</param>
    /// <returns>The mock's proxy, whose ProxyInterface is the mocked instance.</returns>
    /// <exception cref="EMockException">Create was not called, or the type is not an interface with RTTI.
    /// </exception>
    function Mock(const ATypeInfo : PTypeInfo) : IProxy; overload;

    /// <summary>Creates the container.</summary>
    /// <returns>The container.</returns>
    class function Create : TAutoMockContainer; static;
  end;

  ///  Used for defining permissable parameter values during method setup.
  ///  Inspired by Moq
  /// <summary>Describes the arguments a setup applies to. Get one with It0..It9 (or It(n)) for the parameter at
  /// that zero-based index, Self excluded, and pass its result in that parameter's place in the When call. Once one
  /// parameter has a matcher, every parameter needs one.</summary>
  ItRec = record
  private
    /// <summary>The zero-based parameter index, Self excluded.</summary>
    ParamIndex : cardinal;

    /// <summary>Returns T's equality comparer: a record's = operator if it has one, otherwise the RTL default.
    /// </summary>
    /// <returns>The comparer.</returns>
    function DefaultComparer<T>: IEqualityComparer<T>;
  public
    /// <summary>Creates the descriptor for one parameter.</summary>
    /// <param name="AParamIndex">The zero-based parameter index, Self excluded.</param>
    constructor Create(const AParamIndex : Integer);

    /// <summary>Accepts any argument.</summary>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsAny<T>() : T ;
    /// <summary>Accepts an argument the predicate accepts.</summary>
    /// <param name="predicate">The test.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function Matches<T>(const predicate: TPredicate<T>) : T;
    /// <summary>Accepts any argument other than Default(T).</summary>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsNotNil<T> : T; overload;
    /// <summary>Accepts any argument the comparer finds unequal to Default(T).</summary>
    /// <param name="comparer">The comparer.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsNotNil<T>(const comparer: IEqualityComparer<T>) : T; overload;
    /// <summary>Accepts an argument equal to a value.</summary>
    /// <param name="value">The value.</param>
    /// <returns>The value, to pass in the parameter's place.</returns>
    function IsEqualTo<T>(const value : T) : T; overload;
    /// <summary>Accepts an argument the comparer finds equal to a value.</summary>
    /// <param name="value">The value.</param>
    /// <param name="comparer">The comparer.</param>
    /// <returns>The value, to pass in the parameter's place.</returns>
    function IsEqualTo<T>(const value : T; const comparer: IEqualityComparer<T>) : T; overload;
    /// <summary>Accepts an argument within an inclusive range, ordered by T's default comparer.</summary>
    /// <param name="fromValue">The lowest accepted value.</param>
    /// <param name="toValue">The highest accepted value.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsInRange<T>(const fromValue : T; const toValue : T) : T;
    /// <summary>Accepts an argument equal to one of the values.</summary>
    /// <param name="values">The values.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsIn<T>(const values : TArray<T>) : T; overload;
    /// <summary>Accepts an argument the comparer finds equal to one of the values.</summary>
    /// <param name="values">The values.</param>
    /// <param name="comparer">The comparer.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsIn<T>(const values : TArray<T>; const comparer: IEqualityComparer<T>) : T; overload;
    /// <summary>Accepts an argument equal to one of the values.</summary>
    /// <param name="values">The values, enumerated at each call.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsIn<T>(const values : IEnumerable<T>) : T; overload;
    /// <summary>Accepts an argument the comparer finds equal to one of the values.</summary>
    /// <param name="values">The values, enumerated at each call.</param>
    /// <param name="comparer">The comparer.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsIn<T>(const values : IEnumerable<T>; const comparer: IEqualityComparer<T>) : T; overload;
    /// <summary>Accepts an argument equal to none of the values.</summary>
    /// <param name="values">The values.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsNotIn<T>(const values : TArray<T>) : T; overload;
    /// <summary>Accepts an argument the comparer finds equal to none of the values.</summary>
    /// <param name="values">The values.</param>
    /// <param name="comparer">The comparer.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsNotIn<T>(const values : TArray<T>; const comparer: IEqualityComparer<T>) : T; overload;
    /// <summary>Accepts an argument equal to none of the values.</summary>
    /// <param name="values">The values, enumerated at each call.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsNotIn<T>(const values : IEnumerable<T>) : T; overload;
    /// <summary>Accepts an argument the comparer finds equal to none of the values.</summary>
    /// <param name="values">The values, enumerated at each call.</param>
    /// <param name="comparer">The comparer.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsNotIn<T>(const values : IEnumerable<T>; const comparer: IEqualityComparer<T>) : T; overload;
    /// <summary>Accepts a string argument the regular expression matches.</summary>
    /// <param name="regex">The pattern.</param>
    /// <param name="options">The match options.</param>
    /// <returns>A placeholder value to pass in the parameter's place.</returns>
    function IsRegex(const regex : string; const options : TRegExOptions = []) : string;
    /// <summary>Accepts an argument whose public and published properties equal the value's.</summary>
    /// <param name="Value">The value to compare with.</param>
    /// <returns>The value, to pass in the parameter's place.</returns>
    function AreSamePropertiesThat<T>(const Value: T): T;
    /// <summary>Accepts an argument whose public and published fields equal the value's.</summary>
    /// <param name="Value">The value to compare with.</param>
    /// <returns>The value, to pass in the parameter's place.</returns>
    function AreSameFieldsThat<T>(const Value: T): T;
    /// <summary>Accepts an argument whose public and published fields and properties equal the value's.</summary>
    /// <param name="Value">The value to compare with.</param>
    /// <returns>The value, to pass in the parameter's place.</returns>
    function AreSameFieldsAndPropertiedThat<T>(const Value: T): T;
  end;

  /// <summary>Member-by-member comparison of objects and records, for the AreSame matchers.</summary>
  TComparer = class
  private type
    /// <summary>One pair of instances already being compared, so a cyclic object graph is not followed for ever.
    /// </summary>
    TComparedPair = record
      /// <summary>The first instance.</summary>
      Left : Pointer;
      /// <summary>The second instance.</summary>
      Right : Pointer;
    end;
  private
    /// <summary>Compares the given members of two instances of one type, recursing into object members.</summary>
    /// <param name="Members">The fields or properties to compare.</param>
    /// <param name="Instance1">The first instance.</param>
    /// <param name="Instance2">The second instance.</param>
    /// <param name="Visited">The pairs already being compared; a pair met again is taken as equal.</param>
    /// <returns>True when every public and published member is equal.</returns>
    class function CompareMemberValues(const Members: TArray<TRttiMember>; const Instance1, Instance2: TValue;
      const Visited: TList<TComparedPair>): Boolean; static;
  public
    /// <summary>Compares the public and published fields of two values, recursing into object fields.</summary>
    /// <param name="Param1">The first value.</param>
    /// <param name="Param2">The second value.</param>
    /// <returns>True when every field is equal.</returns>
    class function CompareFields<T>(Param1, Param2: T): Boolean;
    /// <summary>Compares the given public and published members of two values, recursing into object members. An
    /// object graph that refers back to itself is compared once per pair of instances.</summary>
    /// <param name="Members">The fields or properties to compare.</param>
    /// <param name="Param1">The first value.</param>
    /// <param name="Param2">The second value.</param>
    /// <returns>True when every member is equal.</returns>
    class function CompareMembers<T: TRttiMember; T2>(Members: TArray<T>; Param1, Param2: T2): Boolean;
    /// <summary>Compares the public and published readable properties of two values, recursing into object
    /// properties.</summary>
    /// <param name="Param1">The first value.</param>
    /// <param name="Param2">The second value.</param>
    /// <returns>True when every property is equal.</returns>
    class function CompareProperties<T>(Param1, Param2: T): Boolean;
  end;

  //Exception Types that the mocks will raise.
  /// <summary>The base of every exception the mocks raise.</summary>
  EMockException = class(Exception);
  /// <summary>Implement was called for an interface the mock already implements.</summary>
  EMockProxyAlreadyImplemented = class(EMockException);
  /// <summary>A setup is invalid.</summary>
  EMockSetupException = class(EMockException);
  /// <summary>The type to mock has no RTTI, or nothing that can be intercepted.</summary>
  EMockNoRTTIException = class(EMockException);
  /// <summary>The mock does not implement a requested interface.</summary>
  EMockNoProxyException = class(EMockException);
  /// <summary>Verify found an expectation that was not met.</summary>
  EMockVerificationException = class(EMockException);

  /// <summary>Type info conveniences.</summary>
  TTypeInfoHelper = record helper for TTypeInfo
    /// <summary>Returns the type's name as a string.</summary>
    /// <returns>The name.</returns>
    function NameStr : string; inline;
  end;

  /// <summary>Describes the arguments a setup applies to for the parameter at a zero-based index, Self excluded.
  /// </summary>
  /// <param name="AParamIndx">The parameter index.</param>
  /// <returns>The descriptor.</returns>
  function It(const AParamIndx : Integer) : ItRec;
  /// <summary>Describes the first parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It0 : ItRec;
  /// <summary>Describes the second parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It1 : ItRec;
  /// <summary>Describes the third parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It2 : ItRec;
  /// <summary>Describes the fourth parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It3 : ItRec;
  /// <summary>Describes the fifth parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It4 : ItRec;
  /// <summary>Describes the sixth parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It5 : ItRec;
  /// <summary>Describes the seventh parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It6 : ItRec;
  /// <summary>Describes the eighth parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It7 : ItRec;
  /// <summary>Describes the ninth parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It8 : ItRec;
  /// <summary>Describes the tenth parameter's argument.</summary>
  /// <returns>The descriptor.</returns>
  function It9 : ItRec;

implementation

uses
  System.Classes,
  Delphi.Mocks.Utils,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.Proxy,
  Delphi.Mocks.ObjectProxy,
  Delphi.Mocks.ParamMatcher,
  Delphi.Mocks.AutoMock,
  Delphi.Mocks.Validation,
  Delphi.Mocks.Helpers;

procedure TMock<T>.CheckCreated;
var
  pInfo : PTypeInfo;
begin
  //FProxy is managed, so it is nil in a record that was never created, and Free sets it back to
  //nil. The old FCreated flag was not managed: in an uninitialised local it was stack garbage,
  //and after Free it stayed True, so both cases got a misleading "Internal Error".
  if FProxy = nil then
  begin
    pInfo := TypeInfo(T);
    raise EMockException.CreateFmt('TMock<%s> was used before Create, or after Free.', [pInfo.NameStr]);
  end;
end;

function TMock<T>.CheckExpectations: string;
var
  v : IVerify;
begin
  CheckCreated;

  if Supports(FProxy.Setup,IVerify,v) then
    Result := v.CheckExpectations
  else
    raise EMockException.Create('Could not cast Setup to IVerify interface!');
end;

class function TMock<T>.Create: TMock<T>;
begin
  Result := Create(nil);
end;

class function TMock<T>.Create(const ACreateObjectFunc: TFunc<T>): TMock<T>;
begin
  Result := Create(nil, ACreateObjectFunc);
end;


class function TMock<T>.Create(const AAutoMock: IAutoMock; const ACreateObjectFunc: TFunc<T>): TMock<T>;
var
  proxy : IInterface;
  pInfo : PTypeInfo;
begin
  //Make sure that we start off with a clean mock
  //NOTE: Do NOT use FillChar here! Due to return value optimization,
  //Result may be the same memory as the caller's variable, and FillChar
  //would bypass finalization of managed fields (causing memory leaks).
  //Use Default() which properly handles managed types.
  Result := Default(TMock<T>);

  //By default we don't auto mock TMock<T>. It changes when TAutoMock is used.
  Result.FAutomocker := AAutoMock;

  pInfo := TypeInfo(T);

  //Raise exceptions if the mock doesn't meet the requirements.
  TMocksValidation.CheckMockType(pInfo);

  case pInfo.Kind of
    //Create our proxy object, which will implement our object T
    tkClass : proxy := TObjectProxy<T>.Create(ACreateObjectFunc, Result.FAutomocker, false);
    //Create our proxy interface object, which will implement our interface T
    tkInterface : proxy := TProxy<T>.Create(Result.FAutomocker, false);
  end;

  //Push the proxy into the result we are returning. Every proxy created above implements
  //IProxy<T>, so failing here means an internal error rather than a user mistake.
  if proxy.QueryInterface(GetTypeData(TypeInfo(IProxy<T>)).Guid, Result.FProxy) <> 0 then
    raise EMockNoProxyException.Create('Error casting to interface ' + pInfo.NameStr + ' , proxy does not appear to implement IProxy<T>');
end;

procedure TMock<T>.Free;
begin
  //Idempotent: freeing twice is harmless, and any other use afterwards says so plainly.
  FProxy := nil;
  FAutomocker := nil;
end;

procedure TMock<T>.Implement<I>;
var
  proxy : IProxy<I>;
  pInfo : PTypeInfo;
begin
  CheckCreated;

  if FProxy is TObjectProxy<T> then
    raise ENotSupportedException.CreateFmt('Implement<%s> is not supported on a mock of the class %s; only a mock of '
      + 'an interface can implement further interfaces.', [PTypeInfo(TypeInfo(I)).NameStr, PTypeInfo(TypeInfo(T)).NameStr]);

  pInfo := TypeInfo(I);

  TMocksValidation.CheckMockInterface(pInfo);

  proxy := TProxy<I>.Create;

  FProxy.AddImplement(proxy, pInfo);
end;

class operator TMock<T>.Implicit(const Value: TMock<T>): T;
begin
  Value.CheckCreated;

  result := Value.FProxy.Proxy;
end;

function TMock<T>.Instance : T;
begin
  CheckCreated;

  result := FProxy.Proxy;
end;

function TMock<T>.Instance<I>: I;
var
  prox : IInterface;
  proxyI : IProxy<I>;
  pInfo : PTypeInfo;
begin
  CheckCreated;

  //Does the proxy we have, or any of its children support a proxy for the passed
  //in interface type?
  pInfo := TypeInfo(I);
  prox := FProxy.ProxyFromType(pInfo);

  if prox = nil then
    raise EMockException.CreateFmt('Mock does not implement [%s]', [pInfo.NameStr]);

  if not Supports(prox, IProxy<I>, proxyI) then
    raise EMockException.CreateFmt('Proxy for [%s] does not support [IProxy<T>].', [pInfo.NameStr]);

  //Return the interface for the requested implementation.
  result := proxyI.Proxy;
end;

function TMock<T>.InstanceAsValue: TValue;
begin
  CheckCreated;

  result := TValue.From<T>(Self);
end;

function TMock<T>.InstanceAsValue<I>: TValue;
begin
  CheckCreated;

  result := TValue.From<I>(Self.Instance<I>);
end;

procedure TMock<T>.ResetCalls;
var
  interfaceV : IVerify;
begin
  CheckCreated;

  if Supports(FProxy.Setup, IVerify, interfaceV) then
    interfaceV.ResetCalls
  else
    raise EMockException.Create('Could not cast Setup to IVerify interface!');
end;

function TMock<T>.Setup: IMockSetup<T>;
begin
  CheckCreated;

  result := FProxy.Setup;
end;

//Optimisation is switched off for these two methods only, and restored to whatever it was.
//The old bare {$O+} after them forced optimisation on for the rest of the unit in Debug too.
{$IFOPT O+}
  {$DEFINE DELPHI_MOCKS_OPTIMISATION_WAS_ON}
{$ENDIF}
{$O-}
function TMock<T>.Setup<I>: IMockSetup<I>;
var
  setup : IProxy;
  pInfo : PTypeInfo;
  pMockSetupInfo : PTypeInfo;
begin
  CheckCreated;
  //We have to ask for the proxy who owns the implementation of the interface/object
  //in question. The reason for this it that all proxies implement IProxy<T> and
  //therefore we will just get the first proxy always.
  //E.g. IProxy<IInterfaceOne> and IProxy<IInterfaceTwo> have the same GUID. Makes
  //generic interfaces hard to use.
  pInfo := TypeInfo(I);

  //Get the proxy which implements
  setup := FProxy.ProxyFromType(pInfo);

  //If nill is returned then we don't implement the defined type.
  if setup = nil then
    raise EMockNoProxyException.CreateFmt('[%s] is not implement.', [pInfo.NameStr]);

  //Now get it as the mocksetup that we requrie. Note that this doesn't ensure
  //that I is actually implemented as all proxies implment IMockSetup<I>. This
  //is what we only return the error that IMockSetup isn't implemented.
  if not Supports(setup, IMockSetup<I>, result) then
  begin
    pMockSetupInfo := TypeInfo(IMockSetup<I>);
    raise EMockNoProxyException.CreateFmt('[%s] Proxy does not implement [%s]', [pInfo.NameStr, pMockSetupInfo.NameStr]);
  end;
end;

procedure TMock<T>.Verify(const message: string);
var
  v : IVerify;
begin
  CheckCreated;

  if Supports(FProxy.Setup, IVerify, v) then
    v.Verify(message)
  else
    raise EMockException.Create('Could not cast Setup to IVerify interface!');
end;

procedure TMock<T>.Verify<I>(const message: string);
var
  prox : IInterface;
  interfaceV : IVerify;
  pInfo : PTypeInfo;
begin
  CheckCreated;

  //Does the proxy we have, or any of its children support a proxy for the passed
  //in interface type? ProxyFromType raises EMockNoProxyException when none does.
  pInfo := TypeInfo(I);

  prox := FProxy.ProxyFromType(pInfo);

  if (prox = nil) or (not Supports(prox, IVerify, interfaceV)) then
    raise EMockNoProxyException.CreateFmt('The mock does not implement [%s], so it has nothing to verify for it.', [pInfo.NameStr]);

  interfaceV.Verify(message);
end;
{$IFDEF DELPHI_MOCKS_OPTIMISATION_WAS_ON}
  {$O+}
  {$UNDEF DELPHI_MOCKS_OPTIMISATION_WAS_ON}
{$ENDIF}

procedure TMock<T>.VerifyAll(const message: string);
var
  interfaceV : IVerify;
begin
  CheckCreated;

  if Supports(FProxy.Setup, IVerify, interfaceV) then
    interfaceV.VerifyAll(message)
  else
    raise EMockException.Create('Could not cast Setup to IVerify interface!');
end;

{ TStub<T> }

procedure TStub<T>.CheckCreated;
var
  pInfo : PTypeInfo;
begin
  //Every member dereferenced FProxy unchecked, so an uncreated or freed stub raised an AV.
  if FProxy = nil then
  begin
    pInfo := TypeInfo(T);
    raise EMockException.CreateFmt('TStub<%s> was used before Create, or after Free.', [pInfo.NameStr]);
  end;
end;

class function TStub<T>.Create(): TStub<T>;
begin
  result := TStub<T>.Create(nil);
end;


class function TStub<T>.Create(const ACreateObjectFunc: TFunc<T>): TStub<T>;
var
  proxy : IInterface;
  pInfo : PTypeInfo;
begin
  //Make sure that we start off with a clean stub
  //NOTE: Do NOT use FillChar here! Due to return value optimization,
  //Result may be the same memory as the caller's variable, and FillChar
  //would bypass finalization of managed fields (causing memory leaks).
  Result := Default(TStub<T>);

  //By default we don't auto mock TMock<T>. It changes when TAutoMock is used.
  Result.FAutomocker := nil;

  pInfo := TypeInfo(T);

  if pInfo.Kind not in [tkInterface,tkClass] then
    raise EMockException.Create(pInfo.NameStr + ' is not an Interface or Class. TStub<T> supports interfaces and classes only');

  case pInfo.Kind of
    //NOTE: We have a weaker requirement for an object proxy opposed to an interface proxy.
    //NOTE: Object proxy doesn't require more than zero methods on the object.
    tkClass :
    begin
      //Check to make sure we have
      if not CheckClassHasRTTI(pInfo) then
          raise EMockNoRTTIException.Create(pInfo.NameStr + ' declares no virtual methods, so there is nothing a stub '
            + 'can intercept');

      //Create our proxy object, which will implement our object T
      proxy := TObjectProxy<T>.Create(ACreateObjectFunc, Result.FAutomocker, true);
    end;
    tkInterface :
    begin
      //Check to make sure we have
      if not CheckInterfaceHasRTTI(pInfo) then
        raise EMockNoRTTIException.Create(pInfo.NameStr + ' does not have RTTI, specify {$M+} for the interface to enabled RTTI');

      //Create our proxy interface object, which will implement our interface T
      proxy := TProxy<T>.Create(Result.FAutomocker, true);
    end;
  else
    raise EMockException.Create('Invalid type kind T');
  end;

  //Push the proxy into the result we are returning. Every proxy created above implements
  //IStubProxy<T>, so failing here means an internal error rather than a user mistake.
  if proxy.QueryInterface(GetTypeData(TypeInfo(IStubProxy<T>)).Guid, Result.FProxy) <> 0 then
    raise EMockNoProxyException.Create('Error casting to interface ' + pInfo.NameStr + ' , proxy does not appear to implement IProxy<T>');
end;

procedure TStub<T>.Free;
begin
  FProxy := nil;
end;

class operator TStub<T>.Implicit(const Value: TStub<T>): T;
begin
  Value.CheckCreated;
  result := Value.FProxy.Proxy;
end;

function TStub<T>.Instance: T;
begin
  CheckCreated;
  result := FProxy.Proxy;
end;

function TStub<T>.InstanceAsValue: TValue;
begin
  CheckCreated;
  result := TValue.From<T>(Self);
end;

function TStub<T>.Setup: IStubSetup<T>;
begin
  CheckCreated;
  result := FProxy.Setup;
end;

{ TTypeInfoHelper }

function TTypeInfoHelper.NameStr: string;
begin
  result := string(Self.Name);
end;

{ TAutoMockContainer }

procedure TAutoMockContainer.CheckCreated;
begin
  if FAutoMocker = nil then
    raise EMockException.Create('TAutoMockContainer was used before Create.');
end;

class function TAutoMockContainer.Create: TAutoMockContainer;
begin
  //NOTE: Do NOT use FillChar here! Due to return value optimization,
  //Result may be the same memory as the caller's variable, and FillChar
  //would bypass finalization of managed fields (causing memory leaks).
  Result := Default(TAutoMockContainer);

  Result.FAutoMocker := TAutoMock.Create;
end;

function TAutoMockContainer.Mock(const ATypeInfo: PTypeInfo): IProxy;
begin
  //Returned now: it used to be thrown away, leaving the caller no way to reach the mock.
  CheckCreated;
  Result := FAutoMocker.Mock(ATypeInfo);
end;

function TAutoMockContainer.Mock<T>: TMock<T>;
var
  pInfo : PTypeInfo;
begin
  CheckCreated;
  pInfo := TypeInfo(T);

  result := TMock<T>.Create(FAutoMocker, nil);
  FAutoMocker.Add(pInfo.NameStr, result.FProxy);
end;
{ It }

function ItRec.AreSameFieldsAndPropertiedThat<T>(const Value: T): T;
begin
  Result := Value;

  TMatcherFactory.Create<T>(ParamIndex,
    function(Param: T): Boolean
    begin
      Result := TComparer.CompareFields<T>(Param, Value) and TComparer.CompareProperties<T>(Param, Value);
    end);
end;

function ItRec.AreSameFieldsThat<T>(const Value: T): T;
begin
  Result := Value;

  TMatcherFactory.Create<T>(ParamIndex,
    function(Param: T): Boolean
    begin
      Result := TComparer.CompareFields<T>(Param, Value);
    end);
end;

function ItRec.AreSamePropertiesThat<T>(const Value: T): T;
begin
  Result := Value;

  TMatcherFactory.Create<T>(ParamIndex,
    function(Param: T): Boolean
    begin
      Result := TComparer.CompareProperties<T>(Param, Value);
    end);
end;

constructor ItRec.Create(const AParamIndex : Integer);
begin
  ParamIndex := AParamIndex;
end;

function ItRec.DefaultComparer<T>: IEqualityComparer<T>;
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  Result := TEqualityComparer<T>.Default;

  LType := LCtx.GetType(TypeInfo(T));
  if (LType <> nil) and LType.IsRecord and LType.TryGetMethod('&op_Equality', LMethod) then
    Result := TEqualityComparer<T>.Construct(
      function(const Left, Right: T): Boolean
      begin
        //Resolve the operator through the captured context when the comparison runs. The
        //TRttiMethod found above belongs to a context that ended with this function, and the
        //comparer is used later, at call time.
        Result := LCtx.GetType(TypeInfo(T)).GetMethod('&op_Equality').Invoke(nil,
          [TValue.From<T>(Left), TValue.From<T>(Right)]).AsBoolean;
      end,
      function(const Value: T): Integer
      begin
        //A constant hash is consistent with any equality. Hashing the record's bytes was not:
        //two records equal by their operator could hash differently (string fields are pointers).
        Result := 0;
      end);
end;

function ItRec.IsAny<T>: T;
begin
  result := Default(T);
  TMatcherFactory.Create<T>(ParamIndex,
    function(value : T) : boolean
    begin
      result := true;
    end);
end;

function ItRec.IsEqualTo<T>(const value: T;
  const comparer: IEqualityComparer<T>): T;
begin
  Result := Value;

  TMatcherFactory.Create<T>(ParamIndex,
    function(param : T) : boolean
    begin
      result := comparer.Equals(param,value);
    end);
end;

function ItRec.IsEqualTo<T>(const value : T) : T;
begin
  Result := IsEqualTo<T>(value, DefaultComparer<T>);
end;

function ItRec.IsIn<T>(const values: TArray<T>): T;
begin
  Result := IsIn<T>(values, DefaultComparer<T>);
end;

function ItRec.IsIn<T>(const values: IEnumerable<T>): T;
begin
  Result := IsIn<T>(values, DefaultComparer<T>);
end;

function ItRec.IsIn<T>(const values: IEnumerable<T>;
  const comparer: IEqualityComparer<T>): T;
begin
  result := Default(T);
  TMatcherFactory.Create<T>(ParamIndex,
    function(param : T) : boolean
    var
      value : T;
    begin
      result := false;
      for value in values do
      begin
        result := comparer.Equals(param,value);
        if result then
          exit;
      end;
    end);
end;

function ItRec.IsIn<T>(const values: TArray<T>;
  const comparer: IEqualityComparer<T>): T;
begin
  result := Default(T);
  TMatcherFactory.Create<T>(ParamIndex,
    function(param : T) : boolean
    var
      value : T;
    begin
      result := false;
      for value in values do
      begin
        result := comparer.Equals(param, value);
        if result then
          exit;
      end;
    end);
end;

function ItRec.IsInRange<T>(const fromValue, toValue: T): T;
var
  comparer : IComparer<T>;
begin
  //This returned Default(T) and registered nothing, so the setup quietly became a literal match
  //on Default(T) - or, beside other matchers, shifted theirs into the wrong parameters.
  result := Default(T);
  comparer := System.Generics.Defaults.TComparer<T>.Default;
  TMatcherFactory.Create<T>(ParamIndex,
    function(value : T) : boolean
    begin
      result := (comparer.Compare(value, fromValue) >= 0) and (comparer.Compare(value, toValue) <= 0);
    end);
end;
function ItRec.IsNotIn<T>(const values: TArray<T>): T;
begin
  Result := IsNotIn<T>(values, DefaultComparer<T>);
end;

function ItRec.IsNotIn<T>(const values: IEnumerable<T>): T;
begin
  Result := IsNotIn<T>(values, DefaultComparer<T>);
end;

function ItRec.IsNotIn<T>(const values: IEnumerable<T>;
  const comparer: IEqualityComparer<T>): T;
begin
  result := Default(T);
  TMatcherFactory.Create<T>(ParamIndex,
    function(param : T) : boolean
    var
      value : T;
    begin
      result := true;
      for value in values do
      begin
        if comparer.Equals(param, value) then
          exit(false);
      end;
    end);
end;

function ItRec.IsNotIn<T>(const values: TArray<T>;
  const comparer: IEqualityComparer<T>): T;
begin
  result := Default(T);
  TMatcherFactory.Create<T>(ParamIndex,
    function(param : T) : boolean
    var
      value : T;
    begin
      result := true;
      for value in values do
      begin
        if comparer.Equals(param, value) then
          exit(false);
      end;
    end);
end;

function ItRec.IsNotNil<T>: T;
begin
  Result := IsNotNil<T>(DefaultComparer<T>);
end;

function ItRec.IsNotNil<T>(const comparer: IEqualityComparer<T>): T;
begin
  result := Default(T);
  TMatcherFactory.Create<T>(ParamIndex,
    function(param : T) : boolean
    begin
      result := not comparer.Equals(param, Default(T));
    end);
end;

function ItRec.Matches<T>(const predicate: TPredicate<T>): T;
begin
  result := Default(T);
  TMatcherFactory.Create<T>(ParamIndex, predicate);
end;

//class function It.ParamIndex: integer;
//begin
//  result := 0;
//end;

function ItRec.IsRegex(const regex : string; const options : TRegExOptions) : string;
begin
  result := '';
  TMatcherFactory.Create<string>(ParamIndex,
    function(param : string) : boolean
    begin
      result := TRegEx.IsMatch(param, regex, options)
    end);
end;

function It(const AParamIndx : Integer) : ItRec;
begin
  result := ItRec.Create(AParamIndx);
end;

function It0 : ItRec;
begin
  result := ItRec.Create(0);
end;

function It1 : ItRec;
begin
  result := ItRec.Create(1);
end;

function It2 : ItRec;
begin
  result := ItRec.Create(2);
end;

function It3 : ItRec;
begin
  result := ItRec.Create(3);
end;

function It4 : ItRec;
begin
  result := ItRec.Create(4);
end;

function It5 : ItRec;
begin
  result := ItRec.Create(5);
end;

function It6 : ItRec;
begin
  result := ItRec.Create(6);
end;

function It7 : ItRec;
begin
  result := ItRec.Create(7);
end;

function It8 : ItRec;
begin
  result := ItRec.Create(8);
end;

function It9 : ItRec;
begin
  result := ItRec.Create(9);
end;

{ TComparer }

/// <summary>Returns the address of the data a value holds: the instance for an object, the record itself for a
/// record.</summary>
/// <param name="Value">The value.</param>
/// <returns>The address, or nil for a nil object.</returns>
function InstanceAddress(const Value: TValue): Pointer;
begin
  if Value.Kind = tkClass then
    Result := Value.AsObject
  else
    //AsPointer raised EInvalidCast for a record, so AreSameFieldsThat<TSomeRecord> always failed.
    Result := Value.GetReferenceToRawData;
end;

class function TComparer.CompareMemberValues(const Members: TArray<TRttiMember>; const Instance1, Instance2: TValue;
  const Visited: TList<TComparedPair>): Boolean;
var
  PublicMember: TRttiMember;
  MemberValue1, MemberValue2: TValue;
  MemberType: TRttiType;
  Address1, Address2: Pointer;
  Pair: TComparedPair;
  Child1, Child2: TObject;
  ChildType: TRttiType;
begin
  Result := SameValue(Instance1, Instance2);
  if Result or Instance1.IsEmpty or Instance2.IsEmpty then
    Exit;

  Address1 := InstanceAddress(Instance1);
  Address2 := InstanceAddress(Instance2);
  for Pair in Visited do
    if (Pair.Left = Address1) and (Pair.Right = Address2) then
      Exit(True);
  Pair.Left := Address1;
  Pair.Right := Address2;
  Visited.Add(Pair);

  Result := True;
  for PublicMember in Members do
  begin
    if not (PublicMember.Visibility in [mvPublic, mvPublished]) then
      Continue;

    if PublicMember is TRttiProperty then
    begin
      //A write-only property has nothing to compare, and reading it raised.
      if not TRttiProperty(PublicMember).IsReadable then
        Continue;
      MemberValue1 := TRttiProperty(PublicMember).GetValue(Address1);
      MemberValue2 := TRttiProperty(PublicMember).GetValue(Address2);
      MemberType := TRttiProperty(PublicMember).PropertyType;
    end
    else
    begin
      MemberValue1 := TRttiField(PublicMember).GetValue(Address1);
      MemberValue2 := TRttiField(PublicMember).GetValue(Address2);
      MemberType := TRttiField(PublicMember).FieldType;
    end;

    if (MemberType <> nil) and (MemberType.TypeKind = tkClass) then
    begin
      Child1 := MemberValue1.AsObject;
      Child2 := MemberValue2.AsObject;
      if (Child1 = nil) or (Child2 = nil) then
        Result := Child1 = Child2
      else
      begin
        ChildType := MemberValue1.RttiType;
        Result := CompareMemberValues(TArray<TRttiMember>(ChildType.GetFields), MemberValue1, MemberValue2, Visited)
          and CompareMemberValues(TArray<TRttiMember>(ChildType.GetProperties), MemberValue1, MemberValue2, Visited);
      end;
    end
    else
      Result := SameValue(MemberValue1, MemberValue2);

    if not Result then
      Exit;
  end;
end;

class function TComparer.CompareFields<T>(Param1, Param2: T): Boolean;
var
  RTTI: TRttiContext;

begin
  RTTI := TRttiContext.Create;
  Result := CompareMembers<TRttiField, T>(RTTI.GetType(TypeInfo(T)).GetFields, Param1, Param2);
end;

class function TComparer.CompareMembers<T, T2>(Members: TArray<T>; Param1, Param2: T2): Boolean;
var
  Visited: TList<TComparedPair>;
begin
  Visited := TList<TComparedPair>.Create;
  try
    Result := CompareMemberValues(TArray<TRttiMember>(Members), TValue.From<T2>(Param1), TValue.From<T2>(Param2), Visited);
  finally
    Visited.Free;
  end;
end;

class function TComparer.CompareProperties<T>(Param1, Param2: T): Boolean;
var
  RTTI: TRttiContext;

begin
  RTTI := TRttiContext.Create;
  Result := CompareMembers<TRttiProperty, T>(RTTI.GetType(TypeInfo(T)).GetProperties, Param1, Param2);
end;

end.

