{***************************************************************************}
{                                                                           }
{           glldelphi-mocks                                                 }
{                                                                           }
{           Copyright (C) 2026 Ian Branch (GITLAK Software)                 }
{           Added in the glldelphi-mocks fork of Delphi Mocks               }
{                                                                           }
{           Licensed under the Apache License, Version 2.0                  }
{           http://www.apache.org/licenses/LICENSE-2.0                      }
{                                                                           }
{***************************************************************************}

unit Delphi.Mocks.Tests.RegressionNewApi;

{ GITLAK addition (2026-10-13). Tests of what the 2026-10-13 fixes added to the API: the call log
  behind Before / After, IVerify.ClearExpectations, TAutoMockContainer.Mock(PTypeInfo) returning
  the proxy, and TMatcherFactory.ClearMatchers. They cannot compile against the old source, so
  they live apart from Delphi.Mocks.Tests.Regression. }

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
{$M+}
  /// <summary>An interface to mock.</summary>
  IRegNewApi = interface
    [ '{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A21}' ]
    /// <summary>A procedure.</summary>
    procedure Ping;
    /// <summary>Another procedure.</summary>
    procedure Pong;
  end;

  /// <summary>A second interface, added with Implement.</summary>
  IRegNewApiChild = interface
    [ '{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A22}' ]
    /// <summary>A procedure.</summary>
    procedure Child;
  end;

  /// <summary>A class, which the auto mocker refuses.</summary>
  TRegNewApiClass = class
  public
    /// <summary>A virtual function.</summary>
    /// <returns>Always 1.</returns>
    function Value: Integer; virtual;
  end;
{$M-}

{$M+}
  /// <summary>Tests of the API the 2026-10-13 fixes introduced.</summary>
  [ TestFixture ]
  TRegressionNewApiTests = class
  published
    /// <summary>Proves the call log numbers calls from 1, keeps each method's first call only, ignores case, and
    /// forgets everything on Clear.</summary>
    procedure CallLog_Records_First_Calls_Case_Insensitively_And_Clears;
    /// <summary>Proves IVerify.ClearExpectations removes the expectations of the mock and of its implemented
    /// interfaces.</summary>
    procedure IVerify_ClearExpectations_Clears_Mock_And_Children;
    /// <summary>Proves TAutoMockContainer.Mock(PTypeInfo) returns the proxy, whose ProxyInterface is a usable
    /// instance of the interface; it used to throw the proxy away.</summary>
    procedure AutoMockContainer_Mock_By_TypeInfo_Returns_Usable_Proxy;
    /// <summary>Proves the auto mocker refuses a class with EMockException naming it, rather than failing later
    /// with a misleading "no proxy" error.</summary>
    procedure AutoMock_Of_Class_Raises_EMockException;
    /// <summary>Proves ClearMatchers discards the current thread's pending matchers.</summary>
    procedure MatcherFactory_ClearMatchers_Discards_Pending_Matchers;
    /// <summary>Proves ResetCalls forgets the call order as well as the counts: calls made out of order before the
    /// reset do not stop the same order being met after it.</summary>
    procedure ResetCalls_Clears_Call_Order;
  end;
{$M-}

implementation

uses
  System.TypInfo,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.MethodData,
  Delphi.Mocks.ParamMatcher;

{ TRegNewApiClass }

function TRegNewApiClass.Value: Integer;
begin
  Result            := 1;
end;

{ TRegressionNewApiTests }

procedure TRegressionNewApiTests.CallLog_Records_First_Calls_Case_Insensitively_And_Clears;
begin
  var intfLog: ICallLog := TCallLog.Create;
  Assert.AreEqual<Int64>( 0, intfLog.LastSequence );
  Assert.AreEqual<Int64>( 0, intfLog.FirstCall( 'Open' ) );

  Assert.AreEqual<Int64>( 1, intfLog.RecordCall( 'Open' ) );
  Assert.AreEqual<Int64>( 2, intfLog.RecordCall( 'Read' ) );
  Assert.AreEqual<Int64>( 3, intfLog.RecordCall( 'OPEN' ) );

  Assert.AreEqual<Int64>( 1, intfLog.FirstCall( 'open' ), 'The first call is kept, whatever the case' );
  Assert.AreEqual<Int64>( 2, intfLog.FirstCall( 'Read' ) );
  Assert.AreEqual<Int64>( 3, intfLog.LastSequence );

  intfLog.Clear;
  Assert.AreEqual<Int64>( 0, intfLog.LastSequence );
  Assert.AreEqual<Int64>( 0, intfLog.FirstCall( 'Open' ) );
  Assert.AreEqual<Int64>( 1, intfLog.RecordCall( 'Read' ), 'Numbering restarts after Clear' );
end;

procedure TRegressionNewApiTests.IVerify_ClearExpectations_Clears_Mock_And_Children;
var
  intfVerify        : IVerify;
begin
  var rMock: TMock<IRegNewApi> := TMock<IRegNewApi>.Create;
  rMock.Implement<IRegNewApiChild>;
  rMock.Setup.Expect.Once( 'Ping' );
  rMock.Setup<IRegNewApiChild>.Expect.Once( 'Child' );
  Assert.WillRaise( procedure
    begin
      rMock.VerifyAll
    end, EMockVerificationException );

  Assert.IsTrue( Supports( rMock.Setup, IVerify, intfVerify ) );
  intfVerify.ClearExpectations;
  intfVerify        := nil;
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.VerifyAll
    end );
end;

procedure TRegressionNewApiTests.AutoMockContainer_Mock_By_TypeInfo_Returns_Usable_Proxy;
var
  intfInstance      : IRegNewApi;
begin
  var rContainer: TAutoMockContainer := TAutoMockContainer.Create;
  var intfProxy: IProxy := rContainer.Mock( TypeInfo( IRegNewApi ) );
  Assert.IsNotNull( intfProxy );
  Assert.IsTrue( Supports( intfProxy.ProxyInterface, IRegNewApi, intfInstance ) );
  Assert.WillNotRaiseAny( procedure
    begin
      intfInstance.Ping
    end );
end;

procedure TRegressionNewApiTests.AutoMock_Of_Class_Raises_EMockException;
begin
  var rContainer: TAutoMockContainer := TAutoMockContainer.Create;
  Assert.WillRaise( procedure
    begin
      rContainer.Mock( TypeInfo( TRegNewApiClass ) )
    end, EMockException );
end;

procedure TRegressionNewApiTests.MatcherFactory_ClearMatchers_Discards_Pending_Matchers;
begin
  It0.IsAny<Integer>;
  It1.IsAny<string>;
  TMatcherFactory.ClearMatchers;
  Assert.AreEqual<NativeInt>( 0, Length( TMatcherFactory.GetMatchers ) );
end;

procedure TRegressionNewApiTests.ResetCalls_Clears_Call_Order;
begin
  var rMock: TMock<IRegNewApi> := TMock<IRegNewApi>.Create;
  rMock.Setup.Expect.Before( 'Ping', 'Pong' );
  rMock.Instance.Pong;
  rMock.Instance.Ping;
  Assert.WillRaise( procedure
    begin
      rMock.Verify
    end, EMockVerificationException );

  rMock.ResetCalls;
  rMock.Instance.Ping;
  rMock.Instance.Pong;
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Verify
    end );
end;

initialization
  TDUnitX.RegisterTestFixture( TRegressionNewApiTests );

end.

