unit Delphi.Mocks.Tests.AutoMock;

interface

uses
  SysUtils,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  {$M+}
  /// <summary>A class an auto-mocked method returns.</summary>
  TReturnedObject = class(TObject)
  end;
  {$M-}

  {$M+}
  /// <summary>An interface an auto-mocked method returns.</summary>
  IReturnedInterface = interface
    ['{8C9AA0D8-5788-4B40-986A-46422BB05E9A}']
    /// <summary>A procedure.</summary>
    procedure Dud;
  end;
  {$M-}

  {$M+}
  /// <summary>Another interface an auto-mocked method returns.</summary>
  IReturnedInterfaceWhichAlsoReturns = interface
    ['{8E3D166F-ED6A-40D9-8C0A-4EC8FF969AF9}']
    /// <summary>A procedure.</summary>
    procedure Dud;
  end;
  {$M-}

  {$M+}
  /// <summary>The interface the container mocks; its functions return an interface, a class and an interface.
  /// </summary>
  IAutoMockedInterface = interface
    ['{CC254E0F-63D0-49CB-9918-63AE5D388842}']
    /// <summary>Returns an interface.</summary>
    /// <returns>An auto mock of IReturnedInterface.</returns>
    function FuncToReturnInterface : IReturnedInterface;
    /// <summary>Returns an object.</summary>
    /// <returns>nil: classes are not auto mocked.</returns>
    function FuncToReturnClass : TReturnedObject;
    /// <summary>Returns another interface.</summary>
    /// <returns>An auto mock of IReturnedInterfaceWhichAlsoReturns.</returns>
    function FuncToReturnInterfaceWhichAlsoReturn : IReturnedInterfaceWhichAlsoReturns;
  end;
  {$M-}

  {$M+}
  /// <summary>Tests TAutoMockContainer.</summary>
  [TestFixture]
  TAutoMockTests = class
  published
    /// <summary>Proves a mock from the container is a working mock: its instance exists and its expectations are
    /// verified.</summary>
    procedure AutoMock_Can_Mock_Interface;
    /// <summary>Proves a function returning an interface hands back a usable auto mock of that interface - the same
    /// one on every call - while a function returning a class returns nil, because only interfaces are auto
    /// mocked.</summary>
    procedure AutoMock_Automatically_Mocks_Contained_Returned_Interface;
  end;
  {$M-}

implementation

{ TAutoMockTests }

procedure TAutoMockTests.AutoMock_Automatically_Mocks_Contained_Returned_Interface;
var
  automockSUT : TAutoMockContainer;
  mock : TMock<IAutoMockedInterface>;
  mockInterface, secondCall : IReturnedInterface;
  otherInterface : IReturnedInterfaceWhichAlsoReturns;
begin
  automockSUT := TAutoMockContainer.Create;

  mock := automockSUT.Mock<IAutoMockedInterface>;

  mockInterface := mock.Instance.FuncToReturnInterface;
  Assert.IsNotNull(mockInterface, 'Expected the interface off the mock to be automatically created and the instance returned.');
  Assert.WillNotRaiseAny(procedure begin mockInterface.Dud end);

  secondCall := mock.Instance.FuncToReturnInterface;
  Assert.IsTrue(mockInterface = secondCall, 'The same auto mock must be returned on every call');

  otherInterface := mock.Instance.FuncToReturnInterfaceWhichAlsoReturn;
  Assert.IsNotNull(otherInterface);
  Assert.WillNotRaiseAny(procedure begin otherInterface.Dud end);

  Assert.IsNull(mock.Instance.FuncToReturnClass, 'Classes are not auto mocked');
end;

procedure TAutoMockTests.AutoMock_Can_Mock_Interface;
var
  automockSUT : TAutoMockContainer;
  mock : TMock<IAutoMockedInterface>;
begin
  automockSUT := TAutoMockContainer.Create;

  mock := automockSUT.Mock<IAutoMockedInterface>;

  Assert.IsNotNull(mock.Instance, 'Expect the interface returned from mock is not null');
  mock.Setup.Expect.Once('FuncToReturnInterface');
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.FuncToReturnInterface;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

initialization
  TDUnitX.RegisterTestFixture(TAutoMockTests);

end.
