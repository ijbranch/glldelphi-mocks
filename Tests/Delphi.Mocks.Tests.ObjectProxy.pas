{***************************************************************************}
{                                                                           }
{           Delphi Mocks                                                    }
{                                                                           }
{           From Delphi Mocks, by Vincent Parrett & Contributors            }
{           Modified (C) 2026 Ian Branch (GITLAK Software)                  }
{                                                                           }
{           Licensed under the Apache License, Version 2.0                  }
{           http://www.apache.org/licenses/LICENSE-2.0                      }
{                                                                           }
{***************************************************************************}

unit Delphi.Mocks.Tests.ObjectProxy;

interface

uses
  System.Rtti,
  System.SysUtils,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  /// <summary>A class whose constructor leaves a mark, to prove the proxy constructed it.</summary>
  TSimpleObject = class(TObject)
  private
    /// <summary>Set by the constructor.</summary>
    FCreateCalled: Cardinal;
  public
    /// <summary>Records that it ran.</summary>
    constructor Create;
    /// <summary>The constructor's mark.</summary>
    property CreateCalled: Cardinal read FCreateCalled;
  end;

  /// <summary>A class with two constructors, only the parameterless one leaving a mark.</summary>
  TMultipleConstructor = class
  private
    /// <summary>Set by the parameterless constructor.</summary>
    FCreateCalled: Cardinal;
  public
    /// <summary>Leaves no mark.</summary>
    /// <param name="Dummy">Unused.</param>
    constructor Create(Dummy: Integer);overload;
    /// <summary>Records that it ran.</summary>
    constructor Create;overload;
    /// <summary>The constructor's mark.</summary>
    property CreateCalled: Cardinal read FCreateCalled;
  end;

  /// <summary>A class to mock: abstract procedures, virtual functions that record being run, and a static one.
  /// </summary>
  TCommand = class
  private
    /// <summary>Set when a real VirtualMethod runs.</summary>
    FVirtualMethodCalled: Boolean;
  public
    /// <summary>Creates the command.</summary>
    constructor Create;

    /// <summary>An abstract procedure.</summary>
    procedure Execute;virtual;abstract;
    /// <summary>An abstract procedure with an argument.</summary>
    /// <param name="value">The argument.</param>
    procedure Run(value: Integer);virtual;abstract;
    /// <summary>An abstract procedure with a var parameter.</summary>
    /// <param name="msg">The parameter.</param>
    procedure TestVarParam(var msg : string);virtual;abstract;
    /// <summary>An abstract procedure with an out parameter.</summary>
    /// <param name="msg">The parameter.</param>
    procedure TestOutParam(out msg : string);virtual;abstract;
    /// <summary>A virtual function that records it ran.</summary>
    /// <returns>1.</returns>
    function VirtualMethod: Integer; overload; virtual;
    /// <summary>A virtual function with an argument that records it ran.</summary>
    /// <param name="Arg">The argument.</param>
    /// <returns>1.</returns>
    function VirtualMethod(const Arg: String): Integer; overload; virtual;
    /// <summary>A static function, which a mock cannot intercept.</summary>
    /// <returns>1.</returns>
    function NonVirtualMethod: Integer;

    /// <summary>Whether a real VirtualMethod has run.</summary>
    property VirtualMethodCalled: Boolean read FVirtualMethodCalled;
  end;

  {$M+}
  /// <summary>Tests the object proxy behind a mock of a class.</summary>
  [TestFixture]
  TTestObjectProxy = class
  published
    /// <summary>Proves the proxy uses the instance the create function returns.</summary>
    [Test]
    procedure ProxyObject_Calls_The_Create_Of_The_Object_Type;
    /// <summary>Proves the proxy uses the instance the create function returns, whichever constructor made it.
    /// </summary>
    [Test]
    procedure ProxyObject_MultipleConstructor;
    /// <summary>Proves Expect.Once.When with an argument counts only calls with that argument.</summary>
    [Test]
    procedure MockWithArgProcedureUsingOnce;
    /// <summary>Proves Expect.Once('Execute') on a class mock is met by one call and fails Verify after a second.
    /// It used to end in Assert.Pass and never verify.</summary>
    [Test]
    procedure MockNoArgProcedureUsingOnce;
    /// <summary>Proves Expect.Once.When on a class mock is met by one call and fails Verify after a second.
    /// </summary>
    [Test]
    procedure MockNoArgProcedureUsingOnceWhen;
    /// <summary>Proves Expect.Never.When on a class mock is met with no call and fails Verify with
    /// EMockVerificationException after one.</summary>
    [Test]
    procedure MockNoArgProcedureUsingNeverWhen;
    /// <summary>Proves Expect.AtLeastOnce.When fails Verify with no call and is met after calls.</summary>
    [Test]
    procedure MockNoArgProcedureUsingAtLeastOnceWhen;
    /// <summary>Proves Expect.AtLeast(3).When fails Verify after two calls and is met after three.</summary>
    [Test]
    procedure MockNoArgProcedureUsingAtLeastWhen;
    /// <summary>Proves Expect.AtMost(2).When is met after two calls and fails Verify after a third.</summary>
    [Test]
    procedure MockNoArgProcedureUsingAtMostBetweenWhen;
    /// <summary>Proves Expect.Exactly(2).When fails Verify after one call, is met after two, and fails after three.
    /// </summary>
    [Test]
    procedure MockNoArgProcedureUsingExactlyWhen;
    /// <summary>Proves a WillExecute function can write an out parameter back through a class mock.</summary>
    [Test]
    procedure TestOutParam;
    /// <summary>Proves a WillExecute function can write a var parameter back through a class mock.</summary>
    [Test]
    procedure TestVarParam;
    /// <summary>Proves a virtual method with an expectation but no behaviour runs for real and is counted.
    /// </summary>
    [Test]
    procedure MockNoBehaviorDefined;
    /// <summary>Proves setting up a non-virtual method raises EMockSetupException, because it can never be
    /// intercepted.</summary>
    [Test]
    procedure WillRaiseMockNonVirtualMethod;
    /// <summary>Proves setup calls do not run the real virtual method.</summary>
    [Test]
    procedure VirtualMethodNotCalledDuringMockSetup;
    /// <summary>Proves a virtual method with no behaviour runs for real.</summary>
    [Test]
    procedure VirtualMethodCalledIfNoBehaviorDefined;
    /// <summary>Proves a matching behaviour replaces the real virtual method.</summary>
    [Test]
    procedure VirtualMethodNotCalledIfBehaviorMatches;
    /// <summary>Proves a behaviour for other arguments leaves the real virtual method to run.</summary>
    [Test]
    procedure VirtualMethodCalledIfBehaviorNotMatches;
  end;
  {$M-}

implementation

uses
  Delphi.Mocks.ObjectProxy;

const
  /// <summary>The mark the constructors leave.</summary>
  G_CREATE_CALLED_UNIQUE_ID = 909090;

{ TTestObjectProxy }

procedure TTestObjectProxy.ProxyObject_Calls_The_Create_Of_The_Object_Type;
var
  objectProxy: IProxy<TSimpleObject>;
begin
  objectProxy := TObjectProxy<TSimpleObject>.Create(function: TSimpleObject
                                                    begin
                                                      result := TSimpleObject.Create;
                                                    end);

  Assert.AreEqual(G_CREATE_CALLED_UNIQUE_ID, objectProxy.Proxy.CreateCalled);
end;

procedure TTestObjectProxy.ProxyObject_MultipleConstructor;
var
  objectProxy: IProxy<TMultipleConstructor>;
begin
  objectProxy := TObjectProxy<TMultipleConstructor>.Create(function: TMultipleConstructor
                                                           begin
                                                             result := TMultipleConstructor.Create;
                                                           end);

  Assert.AreEqual(G_CREATE_CALLED_UNIQUE_ID, objectProxy.Proxy.CreateCalled);
end;

procedure TTestObjectProxy.TestOutParam;
const
  RETURN_MSG = 'hello Delphi Mocks! - With out Param';
var
  mock : TMock<TCommand>;
  msg: string;
begin
  mock := TMock<TCommand>.Create;

  mock.Setup.WillExecute(
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      Assert.AreEqual<NativeInt>(2, Length(Args), 'Args Length');
      //Argument Zero is Self Instance
      args[1] := RETURN_MSG;
    end
    ).When.TestOutParam(msg);

  msg := EmptyStr;
  mock.Instance.TestOutParam(msg);

  Assert.AreEqual(RETURN_MSG, msg, False);
end;

procedure TTestObjectProxy.TestVarParam;
const
  RETURN_MSG = 'hello Delphi Mocks!';
var
  mock : TMock<TCommand>;
  msg: string;
begin
  mock := TMock<TCommand>.Create;

  mock.Setup.WillExecute(
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      Assert.AreEqual<NativeInt>(2, Length(Args), 'Args Length');
      //Argument Zero is Self Instance
      args[1] := RETURN_MSG;
    end
    ).When.TestVarParam(msg);

  msg := EmptyStr;
  mock.Instance.TestVarParam(msg);

  Assert.AreEqual(RETURN_MSG, msg, False);
end;

procedure TTestObjectProxy.VirtualMethodCalledIfBehaviorNotMatches;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.WillReturn(2).When.VirtualMethod('test');

  Assert.AreEqual(1, mock.Instance.VirtualMethod('test2'));
  Assert.IsTrue(mock.Instance.VirtualMethodCalled);
end;

procedure TTestObjectProxy.VirtualMethodCalledIfNoBehaviorDefined;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;

  Assert.AreEqual(1, mock.Instance.VirtualMethod('test'));
  Assert.IsTrue(mock.Instance.VirtualMethodCalled);
end;

procedure TTestObjectProxy.VirtualMethodNotCalledDuringMockSetup;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.AtLeastOnce.When.VirtualMethod;
  mock.Setup.WillReturn(1).When.VirtualMethod;
  mock.Setup.WillReturnDefault('VirtualMethod', 1);

  Assert.IsFalse(mock.Instance.VirtualMethodCalled);
end;

procedure TTestObjectProxy.VirtualMethodNotCalledIfBehaviorMatches;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.WillReturn(2).When.VirtualMethod('test');
  Assert.AreEqual(2, mock.Instance.VirtualMethod('test'));

  Assert.IsFalse(mock.Instance.VirtualMethodCalled);
end;

procedure TTestObjectProxy.MockNoArgProcedureUsingAtLeastOnceWhen;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.AtLeastOnce.When.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Execute;
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

procedure TTestObjectProxy.MockNoArgProcedureUsingAtLeastWhen;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.AtLeast(3).When.Execute;
  mock.Instance.Execute;
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

procedure TTestObjectProxy.MockNoArgProcedureUsingAtMostBetweenWhen;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.AtMost(2).When.Execute;
  mock.Instance.Execute;
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestObjectProxy.MockNoArgProcedureUsingExactlyWhen;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.Exactly(2).When.Execute;
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestObjectProxy.MockNoArgProcedureUsingNeverWhen;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.Never.When.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure
    begin
      mock.Verify;
    end, EMockVerificationException);
end;

procedure TTestObjectProxy.MockNoArgProcedureUsingOnce;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.Once('Execute');
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestObjectProxy.MockNoArgProcedureUsingOnceWhen;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.Once.When.Execute;
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestObjectProxy.MockNoBehaviorDefined;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.Once.When.VirtualMethod;
  Assert.AreEqual(1, mock.Instance.VirtualMethod);
  Assert.IsTrue(mock.Instance.VirtualMethodCalled, 'With no behaviour the real virtual method must run');
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

procedure TTestObjectProxy.WillRaiseMockNonVirtualMethod;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  Assert.WillRaise(procedure begin mock.Setup.Expect.Once.When.NonVirtualMethod; end, EMockSetupException);
  Assert.WillRaise(procedure begin mock.Setup.WillReturn(2).When.NonVirtualMethod; end, EMockSetupException);
end;

procedure TTestObjectProxy.MockWithArgProcedureUsingOnce;
var
  mock : TMock<TCommand>;
begin
  mock := TMock<TCommand>.Create;
  mock.Setup.Expect.Once.When.Run(3);
  mock.Instance.Run(4);
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Run(3);
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

{ TSimpleObject }

constructor TSimpleObject.Create;
begin
  FCreateCalled := G_CREATE_CALLED_UNIQUE_ID;
end;

{ TMultipleConstructor }

constructor TMultipleConstructor.Create(Dummy: Integer);
begin

end;

constructor TMultipleConstructor.Create;
begin
  FCreateCalled := G_CREATE_CALLED_UNIQUE_ID;
end;


{ TCommand }

constructor TCommand.Create;
begin
  FVirtualMethodCalled := False;
end;

function TCommand.NonVirtualMethod: Integer;
begin
  Result := 1;
end;

function TCommand.VirtualMethod(const Arg: String): Integer;
begin
  FVirtualMethodCalled := True;
  Result := 1;
end;

function TCommand.VirtualMethod: Integer;
begin
  FVirtualMethodCalled := True;
  Result := 1;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestObjectProxy);

end.
