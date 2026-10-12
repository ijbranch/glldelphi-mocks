unit Delphi.Mocks.Tests.Objects;

interface

uses
  SysUtils,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  /// <summary>The exception the mock is told to raise. A class of its own: it used to be an alias of Exception
  /// (ESimpleException = exception), so a test expecting it was satisfied by any exception at all.</summary>
  ESimpleException = class(Exception);

  /// <summary>A class to mock: one non-virtual method, one virtual method and one abstract virtual function.
  /// </summary>
  TSimpleMockedObject = class(TObject)
  public
    /// <summary>A non-virtual method, which a mock cannot intercept.</summary>
    procedure SimpleMethod;
    /// <summary>A virtual method, which a mock can intercept.</summary>
    procedure SimpleVirtualMethod; virtual;
    /// <summary>An abstract virtual function, which only a mock can answer.</summary>
    /// <returns>Whatever the mock is set up to return.</returns>
    function VirtualAbstract: Integer; virtual; abstract;
  end;

  /// <summary>The code under test: it calls methods of the mocked object it is given.</summary>
  TSystemUnderTest = class(TObject)
  private
    /// <summary>The mocked object; not owned.</summary>
    FMocked : TSimpleMockedObject;
  public
    /// <summary>Creates the system under test.</summary>
    /// <param name="AMock">The mocked object to call.</param>
    constructor Create(const AMock: TSimpleMockedObject);
    /// <summary>Calls the mocked object's non-virtual method.</summary>
    procedure CallsSimpleMethodOnMock;
    /// <summary>Calls the mocked object's virtual method.</summary>
    procedure CallsSimpleVirtualMethodOnMock;
  end;

  {$M+}
  /// <summary>Tests mocks of classes.</summary>
  [TestFixture]
  TMockObjectTests = class
  published
    /// <summary>Proves a WillRaise set up on a virtual method raises the chosen class when the code under test calls
    /// it, while a WillRaise named for a non-virtual method cannot take effect, because only virtual methods are
    /// intercepted.</summary>
    procedure MockObject_Can_Call_Function;
    /// <summary>Proves a WillReturn on an abstract virtual function is what the call returns.</summary>
    [Test]
    procedure CanMockVirtualAbstractCallBehavior;
    /// <summary>Proves a WillReturnDefault on an abstract virtual function is what the call returns.</summary>
    [Test]
    procedure CanMockVirtualAbstractCallDefault;
  end;
  {$M-}


implementation

uses
  Rtti;

{ TMockObjectTests }

procedure TMockObjectTests.CanMockVirtualAbstractCallBehavior;
var
  Mock: TMock<TSimpleMockedObject>;
begin
  Mock := TMock<TSimpleMockedObject>.Create;
  Mock.Setup.WillReturn(2).When.VirtualAbstract;
  Assert.AreEqual(2, Mock.Instance.VirtualAbstract);
end;

procedure TMockObjectTests.CanMockVirtualAbstractCallDefault;
var
  Mock: TMock<TSimpleMockedObject>;
begin
  Mock := TMock<TSimpleMockedObject>.Create;
  Mock.Setup.WillReturnDefault('VirtualAbstract', 2);
  Assert.AreEqual(2, Mock.Instance.VirtualAbstract);
end;

procedure TMockObjectTests.MockObject_Can_Call_Function;
var
  mock : TMock<TSimpleMockedObject>;
  systemUnderTest : TSystemUnderTest;
begin
  mock := TMock<TSimpleMockedObject>.Create;

  mock.Setup.WillRaise('SimpleVirtualMethod', ESimpleException);
  mock.Setup.WillRaise('SimpleMethod', ESimpleException);

  systemUnderTest := TSystemUnderTest.Create(mock.Instance);
  try
    Assert.WillRaise(procedure
    begin
      systemUnderTest.CallsSimpleVirtualMethodOnMock;
    end, ESimpleException);

    //Non-virtual: the real (empty) method runs, so nothing is raised.
    Assert.WillNotRaiseAny(procedure
    begin
      systemUnderTest.CallsSimpleMethodOnMock;
    end);
  finally
    systemUnderTest.Free;
  end;
end;

{ TSimpleObject }

procedure TSimpleMockedObject.SimpleMethod;
begin
 //Does nothing;
end;

procedure TSimpleMockedObject.SimpleVirtualMethod;
begin
 //Does nothing;
end;

{ TSystemUnderTest }

procedure TSystemUnderTest.CallsSimpleMethodOnMock;
begin
  FMocked.SimpleMethod;
end;

procedure TSystemUnderTest.CallsSimpleVirtualMethodOnMock;
begin
  FMocked.SimpleVirtualMethod;
end;

constructor TSystemUnderTest.Create(const AMock: TSimpleMockedObject);
begin
  FMocked := AMock;
end;

initialization
  TDUnitX.RegisterTestFixture(TMockObjectTests);
end.
