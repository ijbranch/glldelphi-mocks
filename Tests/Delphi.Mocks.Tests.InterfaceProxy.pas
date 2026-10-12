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

unit Delphi.Mocks.Tests.InterfaceProxy;

interface

uses
  DUnitX.TestFramework;

type
  {$M+}
  /// <summary>The first interface a proxy implements.</summary>
  IInterfaceOne = Interface
    ['{F1731F12-2453-4818-A785-997AF7A3D51F}']
    /// <summary>A procedure.</summary>
    procedure Execute1;
  End;

  {$M+}
  /// <summary>A second interface, added with AddImplement.</summary>
  IInterfaceTwo = Interface
    ['{C7191239-2E89-4D3A-9D1B-F894BACBBB39}']
    /// <summary>A procedure.</summary>
    procedure Execute2;
  End;

  {$M+}
  /// <summary>A third interface, never implemented.</summary>
  IInterfaceThree = interface
    ['{E3BE68FA-E318-49CA-B93F-DAB02C07B3A3}']
    /// <summary>A procedure.</summary>
    procedure Execute3;
  end;

  {$M+}
  /// <summary>An interface with a parameterless procedure and var / out parameters.</summary>
  ICommand = interface
    ['{9742A11D-69A4-422E-A2F3-CCEC4934DFC0}']
    /// <summary>A parameterless procedure.</summary>
    procedure Execute;
    /// <summary>Takes a var parameter.</summary>
    /// <param name="msg">The parameter.</param>
    procedure TestVarParam(var msg : string);
    /// <summary>Takes an out parameter.</summary>
    /// <param name="msg">The parameter.</param>
    procedure TestOutParam(out msg : string);
  end;
  {$M-}

  {$M+}
  /// <summary>Tests the interface proxy: implementing extra interfaces, counting expectations on a parameterless
  /// procedure, and writing var / out parameters.</summary>
  [TestFixture]
  TTestInterfaceProxy = class
  published
    /// <summary>Proves the proxy still answers for its own interface after another is added.</summary>
    procedure After_Proxy_AddImplement_ProxyProxy_Implements_Original_Interface;
    /// <summary>Proves the proxy's instance answers a query for an added interface.</summary>
    procedure After_Proxy_AddImplement_ProxyProxy_Implements_New_Interface;
    /// <summary>Proves ProxyFromType finds the child proxy of an added interface.</summary>
    procedure After_Proxy_AddImplement_ProxyFromType_Returns_Proxy_For_Implemented_Interface;
    /// <summary>Proves Expect.Once('Execute') is met by one call and fails Verify after a second.</summary>
    procedure MockNoArgProcedureUsingOnce;
    /// <summary>Proves Expect.Once.When is met by one call and fails Verify after a second.</summary>
    procedure MockNoArgProcedureUsingOnceWhen;
    /// <summary>Proves Expect.Never.When is met while the method is not called and fails Verify once it is.
    /// </summary>
    procedure MockNoArgProcedureUsingNeverWhen;
    /// <summary>Proves Expect.AtLeastOnce.When fails Verify with no call and is met after calls.</summary>
    procedure MockNoArgProcedureUsingAtLeastOnceWhen;
    /// <summary>Proves Expect.AtLeast(3).When fails Verify after two calls and is met after three.</summary>
    procedure MockNoArgProcedureUsingAtLeastWhen;
    /// <summary>Proves Expect.AtMost(2).When is met after two calls and fails Verify after a third.</summary>
    procedure MockNoArgProcedureUsingAtMostBetweenWhen;
    /// <summary>Proves Expect.Exactly(2).When fails Verify after one call, is met after two, and fails after three.
    /// </summary>
    procedure MockNoArgProcedureUsingExactlyWhen;
    /// <summary>Proves a WillExecute function can write an out parameter back to the caller.</summary>
    procedure TestOuParam;
    /// <summary>Proves a WillExecute function can write a var parameter back to the caller.</summary>
    procedure TestVarParam;
  end;
  {$M-}

implementation

uses
  SysUtils,
  Delphi.Mocks,
  Delphi.Mocks.Proxy,
  System.Rtti;

{ TTestInterfaceProxy }

procedure TTestInterfaceProxy.After_Proxy_AddImplement_ProxyFromType_Returns_Proxy_For_Implemented_Interface;
var
  proxySUT : IProxy<IInterfaceOne>;
  newInterface : IInterfaceTwo;
  newProxy : IProxy;
begin
  //SETUP
  proxySUT := TProxy<IInterfaceOne>.Create;

  //SETUP - Added the implementation of Interface
  proxySUT.AddImplement(TProxy<IInterfaceTwo>.Create, TypeInfo(IInterfaceTwo));

  newProxy := proxySUT.ProxyFromType(TypeInfo(IInterfaceTwo));

  //TEST - Make sure proxy value implements IInterfaceTwo
  Assert.IsTrue(Supports(newProxy.ProxyInterface, IInterfaceTwo, newInterface));
end;

procedure TTestInterfaceProxy.After_Proxy_AddImplement_ProxyProxy_Implements_New_Interface;
var
  proxySUT : IProxy<IInterfaceOne>;
  newInterface : IInterfaceTwo;
  absentInterface : IInterfaceThree;
begin
  //SETUP
  proxySUT := TProxy<IInterfaceOne>.Create;

  //SETUP - Added the implementation of Interface
  proxySUT.AddImplement(TProxy<IInterfaceTwo>.Create, TypeInfo(IInterfaceTwo));

  //TEST - Make sure proxy value implements IInterfaceTwo
  Assert.IsTrue(Supports(proxySUT.Proxy, IInterfaceTwo, newInterface));
  Assert.IsFalse(Supports(proxySUT.Proxy, IInterfaceThree, absentInterface), 'An interface never added must not be found');
end;

procedure TTestInterfaceProxy.After_Proxy_AddImplement_ProxyProxy_Implements_Original_Interface;
var
  proxySUT : IProxy<IInterfaceOne>;
  originalInterface : IInterfaceOne;
begin
  //SETUP
  proxySUT := TProxy<IInterfaceOne>.Create;

  //SETUP - Added the implementation of Interface
  proxySUT.AddImplement(TProxy<IInterfaceTwo>.Create, TypeInfo(IInterfaceTwo));

  //TEST - Make sure proxy value implements IInterfaceOne
  Assert.IsTrue(Supports(proxySUT.Proxy, IInterfaceOne, originalInterface));
  Assert.IsNotNull(originalInterface);
  Assert.IsTrue(originalInterface = proxySUT.Proxy);
end;

procedure TTestInterfaceProxy.MockNoArgProcedureUsingAtLeastOnceWhen;
var
  mock : TMock<ICommand>;
begin
  mock := TMock<ICommand>.Create;
  mock.Setup.Expect.AtLeastOnce.When.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Execute;
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

procedure TTestInterfaceProxy.MockNoArgProcedureUsingAtLeastWhen;
var
  mock : TMock<ICommand>;
begin
  mock := TMock<ICommand>.Create;
  mock.Setup.Expect.AtLeast(3).When.Execute;
  mock.Instance.Execute;
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
end;

procedure TTestInterfaceProxy.MockNoArgProcedureUsingAtMostBetweenWhen;
var
  mock : TMock<ICommand>;
begin
  mock := TMock<ICommand>.Create;
  mock.Setup.Expect.AtMost(2).When.Execute;
  mock.Instance.Execute;
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestInterfaceProxy.MockNoArgProcedureUsingExactlyWhen;
var
  mock : TMock<ICommand>;
begin
  mock := TMock<ICommand>.Create;
  mock.Setup.Expect.Exactly(2).When.Execute;
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestInterfaceProxy.MockNoArgProcedureUsingNeverWhen;
var
  mock : TMock<ICommand>;
begin
  mock := TMock<ICommand>.Create;
  mock.Setup.Expect.Never.When.Execute;

  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestInterfaceProxy.MockNoArgProcedureUsingOnce;
var
  mock : TMock<ICommand>;
begin
  mock := TMock<ICommand>.Create;
  mock.Setup.Expect.Once('Execute');
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestInterfaceProxy.MockNoArgProcedureUsingOnceWhen;
var
  mock : TMock<ICommand>;
begin
  mock := TMock<ICommand>.Create;
  mock.Setup.Expect.Once.When.Execute;
  mock.Instance.Execute;
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Execute;
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TTestInterfaceProxy.TestOuParam;
const
  RETURN_MSG = 'hello Delphi Mocks! - With out Param';
var
  mock : TMock<ICommand>;
  msg: string;
begin
  mock := TMock<ICommand>.Create;

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

procedure TTestInterfaceProxy.TestVarParam;
const
  RETURN_MSG = 'hello Delphi Mocks!';
var
  mock : TMock<ICommand>;
  msg: string;
begin
  mock := TMock<ICommand>.Create;

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


initialization
  TDUnitX.RegisterTestFixture(TTestInterfaceProxy);


end.
