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

unit Delphi.Mocks.Tests.Stubs;

interface

uses
  DUnitX.TestFramework;
type
  {$M+}
  [TestFixture]
  TStubTests = class
  published
    procedure Test_WillReturnDefault;
    procedure Test_CanStubInheritedMethods;
    /// <summary>GITLAK: proves a stub intercepts a virtual method the class does not declare at all, only its
    /// ancestor does. TStringList overrides Add, so the test above cannot tell that case apart.</summary>
    procedure Test_CanStubMethodDeclaredOnlyInAncestor;
  end;
  {$M-}

  {$M+}
  /// <summary>GITLAK: declares the virtual method the ancestor-only stub test intercepts.</summary>
  TStubAncestor = class
  public
    /// <summary>The real implementation; a stub must never let this value through.</summary>
    /// <returns>Always 1.</returns>
    function Answer : Integer; virtual;
  end;

  /// <summary>GITLAK: inherits Answer without overriding it, so the method's RTTI parent is TStubAncestor.</summary>
  TStubDescendant = class(TStubAncestor)
  end;

  ITestable = interface
    function DoSomething(const value : string) : string;
  end;
  {$M-}


implementation

uses
  Classes,
  Delphi.Mocks;
{ TUtilsTests }
{ TStubTests }

procedure TStubTests.Test_CanStubInheritedMethods;
var
  stub : TStub<TStringList>;
begin
  stub := TStub<TStringList>.Create;
  stub.Setup.BehaviorMustBeDefined := false;
  stub.Setup.WillReturnDefault('Add', 7);
//  stub.Setup.WillReturn(1).When.Add(It(0).IsAny<string>);
  //GITLAK: the real Add on an empty list returns 0 and adds a line; the stub must do neither
  Assert.AreEqual(7, stub.Instance.Add('2'));
  Assert.AreEqual(0, stub.Instance.Count);
end;

procedure TStubTests.Test_CanStubMethodDeclaredOnlyInAncestor;
var
  stub : TStub<TStubDescendant>;
begin
  stub := TStub<TStubDescendant>.Create;
  stub.Setup.WillReturnDefault('Answer', 42);
  Assert.AreEqual(42, stub.Instance.Answer);
end;

{ TStubAncestor }

function TStubAncestor.Answer : Integer;
begin
  Result := 1;
end;

procedure TStubTests.Test_WillReturnDefault;
var
  stub : TStub<ITestable>;
  intf : ITestable;
  actual : string;
begin
  stub := TStub<ITestable>.Create;
  stub.Setup.WillReturnDefault('DoSomething','hello');
  intf := stub.Instance;
  actual := intf.DoSomething('world');
  Assert.AreEqual('hello', actual);
end;

initialization
  TDUnitX.RegisterTestFixture(TStubTests);


end.
