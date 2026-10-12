unit Delphi.Mocks.Tests.ProxyBase;

interface

uses
  Rtti,
  SysUtils,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  {$M+}
  /// <summary>A plain class, which the interface proxy cannot implement.</summary>
  TSimpleTestObject = class(TObject);
  {$M-}

  {$M+}
  /// <summary>Tests the interface proxy base class directly, outside TMock&lt;T&gt;.</summary>
  [TestFixture]
  TTestProxyBase = class
  published
    /// <summary>Proves an interface proxy built for a class type has no virtual interface and says so with
    /// EMockNoProxyException, rather than handing out a nil or invalid instance.</summary>
    procedure Interface_Proxy_Of_A_Class_Type_Raises_EMockNoProxyException;
    /// <summary>Proves an interface proxy's instance is the mocked interface, and that a call on it is recorded
    /// against the proxy's expectations.</summary>
    procedure Interface_Proxy_Records_Calls_Made_Through_Its_Instance;
  end;
  {$M-}

implementation

uses
  Delphi.Mocks.Helpers,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.Proxy,
  classes;

type
  {$M+}
  /// <summary>An interface for the proxy to implement.</summary>
  IProxyBaseSubject = interface
    ['{5B8E2F4A-91C3-4D6E-A0B7-3C9D1E2F4A56}']
    /// <summary>A procedure.</summary>
    procedure Ping;
  end;
  {$M-}

{ TTestProxyBase }

procedure TTestProxyBase.Interface_Proxy_Of_A_Class_Type_Raises_EMockNoProxyException;
var
  proxy : IProxy<TSimpleTestObject>;
begin
  proxy := TProxy<TSimpleTestObject>.Create;
  Assert.WillRaise(procedure
  begin
    proxy.ProxyInterface;
  end, EMockNoProxyException);
end;

procedure TTestProxyBase.Interface_Proxy_Records_Calls_Made_Through_Its_Instance;
var
  proxy : IProxy<IProxyBaseSubject>;
  verify : IVerify;
begin
  proxy := TProxy<IProxyBaseSubject>.Create;
  proxy.Setup.Expect.Once('Ping');
  Assert.IsTrue(Supports(proxy, IVerify, verify));

  Assert.WillRaise(procedure begin verify.Verify end, EMockVerificationException);
  proxy.Proxy.Ping;
  Assert.WillNotRaiseAny(procedure begin verify.Verify end);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProxyBase);

end.
