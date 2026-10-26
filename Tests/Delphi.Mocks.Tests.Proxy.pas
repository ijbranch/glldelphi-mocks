unit Delphi.Mocks.Tests.Proxy;

interface

uses
  System.Rtti,
  System.SysUtils,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  {$M+}
  /// <summary>Tests verification, ResetCalls, Clear and ordering through TMock&lt;T&gt; of a class.</summary>
  [TestFixture]
  TTestMock = class
  published
    /// <summary>Proves Expect.Before through a mock: met when the When method is first called before the named
    /// method, and VerifyAll raises when the order is reversed.</summary>
    [Test]
    procedure Expectation_Before_Verifies_To_True_When_Prior_Method_Called_Atleast_Once;
    /// <summary>Proves VerifyAll's failure message starts with the caller's message.</summary>
    [Test]
    procedure VerifyAllRespectsMessage;
    /// <summary>Proves ResetCalls forgets the recorded calls, so a met Once expectation is unmet again.</summary>
    [Test]
    procedure ResetCallsWorks;
    /// <summary>Proves Expect.Clear removes the expectations, so VerifyAll no longer fails.</summary>
    [Test]
    procedure ClearExpectationsWorks;
  end;
  {$M-}

implementation

uses
  Delphi.Mocks.Helpers,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.MethodData,
  System.Classes;

type
  /// <summary>A class to mock, with two abstract procedures.</summary>
  TSimpleClass = class
  public
    /// <summary>An abstract procedure.</summary>
    procedure DoTest; virtual; abstract;
    /// <summary>Another abstract procedure.</summary>
    procedure DoOther; virtual; abstract;
  end;

{ TTestMock }

procedure TTestMock.ClearExpectationsWorks;
var
  m: TMock<TSimpleClass>;
begin
  m := TMock<TSimpleClass>.Create;
  m.Setup.Expect.Once.When.DoTest;
  Assert.WillRaise(procedure begin m.VerifyAll() end, EMockVerificationException);
  m.Setup.Expect.Clear;
  Assert.WillNotRaiseAny(procedure begin m.VerifyAll() end);
end;

procedure TTestMock.Expectation_Before_Verifies_To_True_When_Prior_Method_Called_Atleast_Once;
var
  inOrder, outOfOrder: TMock<TSimpleClass>;
begin
  inOrder := TMock<TSimpleClass>.Create;
  inOrder.Setup.Expect.Before('DoOther').When.DoTest;
  inOrder.Instance.DoTest;
  inOrder.Instance.DoOther;
  Assert.WillNotRaiseAny(procedure begin inOrder.VerifyAll() end);

  outOfOrder := TMock<TSimpleClass>.Create;
  outOfOrder.Setup.Expect.Before('DoOther').When.DoTest;
  outOfOrder.Instance.DoOther;
  outOfOrder.Instance.DoTest;
  Assert.WillRaise(procedure begin outOfOrder.VerifyAll() end, EMockVerificationException);
end;

procedure TTestMock.ResetCallsWorks;
var
  m: TMock<TSimpleClass>;
begin
  m := TMock<TSimpleClass>.Create;
  m.Setup.Expect.Once.When.DoTest;
  m.Instance.DoTest;
  Assert.WillNotRaiseAny(procedure begin m.VerifyAll() end);
  m.ResetCalls;
  Assert.WillRaise(procedure begin m.VerifyAll() end, EMockVerificationException);
end;

procedure TTestMock.VerifyAllRespectsMessage;
var
  m: TMock<TSimpleClass>;
begin
  m := TMock<TSimpleClass>.Create;
  m.Setup.Expect.Once.When.DoTest;
  try
    m.VerifyAll('test');
  except
    on E: EMockVerificationException do begin
      Assert.IsTrue(E.Message.StartsWith('test'));
      Exit;
    end;
  end;
  Assert.Fail('Verifyall does not respect message');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMock);
end.
