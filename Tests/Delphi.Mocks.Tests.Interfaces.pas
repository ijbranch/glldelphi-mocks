unit Delphi.Mocks.Tests.Interfaces;

interface

uses
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  {$M+}
  /// <summary>The mock's own interface.</summary>
  IA = interface
    ['{551FA8FF-E038-49BB-BCBC-E1F82544CA97}']
    /// <summary>A procedure.</summary>
    procedure Method1;
  end;

  /// <summary>An interface added with Implement.</summary>
  IB = interface
    ['{956B7421-7F45-4E22-BD5F-E5898EC186F4}']
    /// <summary>A procedure.</summary>
    procedure Method2;
  end;

  /// <summary>An interface added with Implement.</summary>
  IC = interface
    ['{4B52C6FE-43EE-44B5-AC01-B4371944322D}']
    /// <summary>A procedure.</summary>
    procedure Method3;
  end;

  /// <summary>An interface added with Implement.</summary>
  ID = interface
    ['{E222BB8F-6E89-4E54-B2DC-E54C5F280E86}']
    /// <summary>A procedure.</summary>
    procedure Method4;
  end;
  {$M-}


  {$M+}
  /// <summary>An interface of safecall methods.</summary>
  ISafeCallInterface = interface
    ['{50960499-4347-421A-B28B-3C05AE9CB351}']
    /// <summary>A safecall function.</summary>
    /// <param name="value">An argument.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function DoSomething(const value : WideString) : integer;safecall;
    /// <summary>A safecall function returning a string.</summary>
    /// <param name="value">An argument.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function Foo2(const value : WideString): string; safecall;
    /// <summary>A safecall procedure.</summary>
    procedure Foo; safecall;
  end;

  /// <summary>An interface with a procedure and a function.</summary>
  ISimpleInterface = interface
    ['{35DA1428-5183-43FE-BEE8-1010C75EF4D6}']
    /// <summary>A procedure.</summary>
    /// <param name="value">An argument.</param>
    procedure SimpleProcedure(const value: widestring);
    /// <summary>A function.</summary>
    /// <returns>Whatever the mock is set up to return.</returns>
    function SimpleFunction: Integer;
  end;

  /// <summary>An interface taking a Variant.</summary>
  IVariant = interface
    /// <summary>Takes a Variant.</summary>
    /// <param name="Value">The argument.</param>
    procedure VariantParam(Value: Variant);
  end;
  {$M-}

  {$M+}
  /// <summary>Tests mocking safecall methods, procedures and Variant arguments.</summary>
  [TestFixture]
  TSafeCallTest = class
  published
    /// <summary>Proves a safecall function returns its set-up value.</summary>
    [Test]
    procedure CanMockSafecallFunction;
    /// <summary>Proves calls to a safecall procedure are counted and a safecall string function returns its
    /// set-up value.</summary>
    [Test]
    procedure CanMockSafecallProc;
    /// <summary>Proves a procedure call is counted and its argument reaches a WillExecute function.</summary>
    [Test]
    procedure CanMockSimpleProcedureCall;
    /// <summary>Proves an expectation on a Variant argument counts only a matching Variant.</summary>
    [Test]
    procedure CanMockProcedureWithVariantParam;
    /// <summary>Proves a WillReturn on a parameterless function is returned.</summary>
    [Test]
    procedure CanMockSimpleFunctionCallBehavior;
    /// <summary>Proves a WillReturnDefault on a parameterless function is returned.</summary>
    [Test]
    procedure CanMockSimpleFunctionCallDefault;
  end;
  {$M-}

  {$M+}
  /// <summary>Tests moving between the interfaces a mock implements, by cast and by Instance&lt;I&gt;.</summary>
  TInterfaceTests = class
    published
    /// <summary>Proves calls made through casts between every implemented interface are counted on the right
    /// interface: VerifyAll is met at two calls each and fails at a third.</summary>
    [Test]
    procedure Cast_Mock_As_Interfaces_It_Implements;
    /// <summary>Proves the same starting from the mock's Instance.</summary>
    [Test]
    procedure Cast_MockInstance_As_Interfaces_It_Implements;
    /// <summary>Proves Instance&lt;I&gt; reaches each implemented interface, whose calls are counted on it.
    /// </summary>
    [Test]
    procedure MockInstance_As_Interfaces_It_Implements;
  end;
  {$M-}

implementation
uses
  Rtti,
  System.Variants;


{ TValueTests }

procedure TSafeCallTest.CanMockProcedureWithVariantParam;
var
  mock : TMock<IVariant>;
begin
  mock := TMock<IVariant>.Create;

  mock.Setup.Expect.Once.When.VariantParam(Null);

  mock.Instance.VariantParam(1);
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.VariantParam(Null);
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

procedure TSafeCallTest.CanMockSafecallFunction;
var
  mock : TMock<ISafeCallInterface>;
  value: Integer;
begin
  mock := TMock<ISafeCallInterface>.Create;
  mock.Setup.WillReturn(123).When.DoSomething('hello');

  value := mock.Instance.DoSomething('hello');

  Assert.AreEqual(123, value);
end;

procedure TSafeCallTest.CanMockSafecallProc;
var
  mock : TMock<ISafeCallInterface>;
begin
  mock := TMock<ISafeCallInterface>.Create;
  mock.Setup.Expect.Once('Foo');
  mock.Setup.WillReturn('bar').When.Foo2('x');

  mock.Instance.Foo;
  Assert.AreEqual('bar', mock.Instance.Foo2('x'), False);
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Foo;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;


procedure TSafeCallTest.CanMockSimpleFunctionCallBehavior;
var
  mock : TMock<ISimpleInterface>;
begin
  mock := TMock<ISimpleInterface>.Create;
  mock.Setup.WillReturn(2).When.SimpleFunction;
  Assert.AreEqual(2, mock.Instance.SimpleFunction);
end;

procedure TSafeCallTest.CanMockSimpleFunctionCallDefault;
var
  mock : TMock<ISimpleInterface>;
begin
  mock := TMock<ISimpleInterface>.Create;
  mock.Setup.WillReturnDefault('SimpleFunction', 2);
  Assert.AreEqual(2, mock.Instance.SimpleFunction);
end;

procedure TSafeCallTest.CanMockSimpleProcedureCall;
var
  mock : TMock<ISimpleInterface>;
  received : string;
begin
  mock := TMock<ISimpleInterface>.Create;
  received := '';
  mock.Setup.Expect.Once('SimpleProcedure');
  mock.Setup.WillExecute('SimpleProcedure',
    function(const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      received := args[1].AsString;
    end);

  mock.Instance.SimpleProcedure('hello');

  Assert.AreEqual('hello', received, False);
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

procedure TInterfaceTests.Cast_Mock_As_Interfaces_It_Implements;
var
  mock : TMock<IA>;
  a : IA;
  b : IB;
  c : IC;
  d : ID;
  i : IInterface;
begin
  mock := TMock<IA>.Create;
  mock.Setup.Expect.Exactly(2).When.Method1;

  mock.Implement<IB>;
  mock.Setup<IB>.Expect.Exactly(2).When.Method2;

  mock.Implement<IC>;
  mock.Setup<IC>.Expect.Exactly(2).When.Method3;

  mock.Implement<ID>;
  mock.Setup<ID>.Expect.Exactly(2).When.Method4;

  //Transfer through mock references.
  a := mock;
  a.Method1;

  b := a as IB;
  b.Method2;

  c := a as IC;
  c.Method3;

  d := a as ID;
  d.Method4;

  i := a as IInterface;


  //Transfer through interfaces references.
  a := mock;
  a.Method1;

  b := a as IB;
  b.Method2;

  c := b as IC;
  c.Method3;

  d := c as ID;
  d.Method4;

  i := d as IInterface;
  Assert.IsNotNull(i);

  Assert.WillNotRaiseAny(procedure begin mock.VerifyAll() end);
  d.Method4;
  Assert.WillRaise(procedure begin mock.VerifyAll() end, EMockVerificationException);
end;

procedure TInterfaceTests.MockInstance_As_Interfaces_It_Implements;
var
  mock : TMock<IA>;
  a : IA;
  b : IB;
  c : IC;
  d : ID;
  i : IInterface;
begin
  mock := TMock<IA>.Create;
  mock.Setup.Expect.Exactly(1).When.Method1;

  mock.Implement<IB>;
  mock.Setup<IB>.Expect.Exactly(1).When.Method2;

  mock.Implement<IC>;
  mock.Setup<IC>.Expect.Exactly(1).When.Method3;

  mock.Implement<ID>;
  mock.Setup<ID>.Expect.Exactly(1).When.Method4;

  //Transfer through mock instance.
  a := mock.Instance;
  a.Method1;

  b := mock.Instance<IB>;
  b.Method2;

  c := mock.Instance<IC>;
  c.Method3;

  d := mock.Instance<ID>;
  d.Method4;

  i := a as IInterface;
  Assert.IsNotNull(i);

  Assert.WillNotRaiseAny(procedure begin mock.VerifyAll() end);
  c.Method3;
  Assert.WillRaise(procedure begin mock.VerifyAll() end, EMockVerificationException);
end;

procedure TInterfaceTests.Cast_MockInstance_As_Interfaces_It_Implements;
var
  mock : TMock<IA>;
  a : IA;
  b : IB;
  c : IC;
  d : ID;
  i : IInterface;
begin
  mock := TMock<IA>.Create;
  mock.Setup.Expect.Exactly(2).When.Method1;

  mock.Implement<IB>;
  mock.Setup<IB>.Expect.Exactly(2).When.Method2;

  mock.Implement<IC>;
  mock.Setup<IC>.Expect.Exactly(2).When.Method3;

  mock.Implement<ID>;
  mock.Setup<ID>.Expect.Exactly(2).When.Method4;

  //Transfer through mock instance.
  a := mock.Instance;
  a.Method1;

  b := a as IB;
  b.Method2;

  c := a as IC;
  c.Method3;

  d := a as ID;
  d.Method4;

  i := a as IInterface;

  a := mock.Instance;
  a.Method1;

  b := a as IB;
  b.Method2;

  c := b as IC;
  c.Method3;

  d := c as ID;
  d.Method4;

  i := d as IInterface;
  Assert.IsNotNull(i);

  Assert.WillNotRaiseAny(procedure begin mock.VerifyAll() end);
  b.Method2;
  Assert.WillRaise(procedure begin mock.VerifyAll() end, EMockVerificationException);
end;

initialization
  TDUnitX.RegisterTestFixture(TSafeCallTest);
  TDUnitX.RegisterTestFixture(TInterfaceTests);

end.
