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

unit Delphi.Mocks.Tests.MethodData;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  System.Rtti,
  Delphi.Mocks,
  Delphi.Mocks.Interfaces;

type
  {$M+}
  /// <summary>An interface with one function.</summary>
  ISimpleInterface = interface
    /// <summary>A function.</summary>
    /// <param name="Value">An argument.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function MissingArg(Value: Integer): Integer;
  end;
  {$M-}

  /// <summary>An object to pass as an argument.</summary>
  TObjectToTest = class
  private
    /// <summary>Backs PropertyToTest.</summary>
    FPropertyToTest: Integer;
  public
    /// <summary>A public field.</summary>
    FieldToTest: Integer;

    /// <summary>A public property.</summary>
    property PropertyToTest: Integer read FPropertyToTest write FPropertyToTest;
  end;

  /// <summary>One descendant of TObjectToTest.</summary>
  TAnotherObject = class(TObjectToTest);

  /// <summary>Another descendant of TObjectToTest.</summary>
  TAndAnotherObject = class(TObjectToTest);

  {$M+}
  /// <summary>Tests TMethodData on its own: redefinition rules, BehaviorMustBeDefined, and ordering expectations.
  /// </summary>
  [TestFixture]
  TTestMethodData = class
  published
    /// <summary>Proves a Before expectation is met when its method's first call precedes the other method's first
    /// call, and not met when the order is reversed, through a shared call log.</summary>
    [Test]
    procedure Expectation_Before_Verifies_To_True_When_Prior_Method_Called_Atleast_Once;
    /// <summary>Proves that, with redefinition allowed, defining the same WillReturnWhen again replaces it: no
    /// exception, and the new value is returned.</summary>
    [Test]
    procedure AllowRedefineBehaviorDefinitions_IsTrue_RedefinedIsAllowed;
    /// <summary>Proves that, with redefinition not allowed, defining the same WillReturnWhen again raises
    /// EMockSetupException.</summary>
    [Test]
    procedure AllowRedefineBehaviorDefinitions_IsFalse_ExceptionIsThrown_WhenRedefining;
    /// <summary>Proves WillReturnWhen for different arguments are separate definitions: no exception, and each
    /// returns its own value.</summary>
    [Test]
    procedure AllowRedefineBehaviorDefinitions_IsFalse_NoExceptionIsThrown_WhenAddingNormal;
    /// <summary>Proves the replaced behaviour is gone: the call returns the new value.</summary>
    [Test]
    procedure AllowRedefineBehaviorDefinitions_IsTrue_OldBehaviorIsDeleted;
    /// <summary>Proves a call with nothing defined does not raise when BehaviorMustBeDefined is off.</summary>
    [Test]
    procedure BehaviourMustBeDefined_IsFalse_AndBehaviourIsNotDefined_RaisesNoException;
    /// <summary>Proves the same call raises EMockException when BehaviorMustBeDefined is on; a procedure is used so
    /// the missing-return-value check cannot raise instead.</summary>
    [Test]
    procedure BehaviourMustBeDefined_IsTrue_AndBehaviourIsNotDefined_RaisesException;
    /// <summary>Proves two setups that differ only in their matchers are not a redefinition.</summary>
    [Test]
    procedure AllowRedefineBehaviorDefinitions_IsTrue_NoExceptionIsThrown_WhenMatcherAreDifferent;
    /// <summary>Proves two expectations that differ only in their matchers are not a redefinition.</summary>
    [Test]
    procedure Expectations_NoExceptionIsThrown_WhenMatcherAreDifferent;
  end;
  {$M-}

implementation

uses
  Delphi.Mocks.Helpers,
  Delphi.Mocks.MethodData,
  System.Classes, System.TypInfo, System.StrUtils, Delphi.Mocks.ParamMatcher;


{ TTestMethodData }

procedure TTestMethodData.Expectations_NoExceptionIsThrown_WhenMatcherAreDifferent;
var
  methodData  : IMethodData;
  someParam,
  someValue1,
  someValue2  : TValue;
  LObjectToTest : TObjectToTest;
  LAnotherObject: TAnotherObject;
  LAndAnotherObject: TAndAnotherObject;
begin
  LObjectToTest := TObjectToTest.Create;
  LAnotherObject := TAnotherObject.Create;
  LAndAnotherObject := TAndAnotherObject.Create;
  try
    someValue1 := TValue.From<TAnotherObject>(LAnotherObject);
    someValue2 := TValue.From<TAndAnotherObject>(LAndAnotherObject);
    someParam := TValue.From<TObjectToTest>(LObjectToTest);

    methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(FALSE, FALSE, FALSE));
    methodData.NeverWhen([nil, someParam], [TMatcher<TAnotherObject>.Create(function(value : TAnotherObject) : boolean
    begin
      result := true;
    end)]);

    Assert.WillNotRaiseAny(procedure
    begin
      methodData.NeverWhen([nil, someParam], [TMatcher<TAndAnotherObject>.Create(function(value : TAndAnotherObject) : boolean
      begin
        result := true;
      end)]);
    end);
  finally
    LObjectToTest.Free;
    LAnotherObject.Free;
    LAndAnotherObject.Free;
  end;
end;

procedure TTestMethodData.Expectation_Before_Verifies_To_True_When_Prior_Method_Called_Atleast_Once;
var
  callLog : ICallLog;
  prepare, commit : IMethodData;
  report : string;
  outValue : TValue;
  params : TSetupMethodDataParameters;
begin
  params := TSetupMethodDataParameters.Create(TRUE, FALSE, FALSE);

  //In order: Prepare, then Commit.
  callLog := TCallLog.Create;
  prepare := TMethodData.Create('x', 'Prepare', params, nil, callLog);
  commit := TMethodData.Create('x', 'Commit', params, nil, callLog);
  prepare.Before('Commit');
  Assert.IsFalse(prepare.Verify(report), 'Unmet before either method is called');
  prepare.RecordHit([nil], nil, nil, outValue);
  Assert.IsFalse(prepare.Verify(report), 'Unmet while Commit has not been called');
  commit.RecordHit([nil], nil, nil, outValue);
  Assert.IsTrue(prepare.Verify(report), report);

  //Out of order: Commit, then Prepare.
  callLog := TCallLog.Create;
  prepare := TMethodData.Create('x', 'Prepare', params, nil, callLog);
  commit := TMethodData.Create('x', 'Commit', params, nil, callLog);
  prepare.Before('Commit');
  commit.RecordHit([nil], nil, nil, outValue);
  prepare.RecordHit([nil], nil, nil, outValue);
  Assert.IsFalse(prepare.Verify(report), 'Prepare first called after Commit must not meet Before');
end;

procedure TTestMethodData.AllowRedefineBehaviorDefinitions_IsTrue_RedefinedIsAllowed;
var
  methodData  : IMethodData;
  someValue1,
  someValue2  : TValue;
  outValue    : TValue;
begin
  someValue1 := TValue.From<Integer>(1);
  someValue2 := TValue.From<Integer>(2);

  methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(FALSE, False, TRUE));
  methodData.WillReturnWhen(TArray<TValue>.Create(someValue1), someValue1, nil);
  Assert.WillNotRaiseAny(procedure
  begin
    methodData.WillReturnWhen(TArray<TValue>.Create(someValue1), someValue2, nil);
  end);

  methodData.RecordHit(TArray<TValue>.Create(someValue1), TRttiContext.Create.GetType(TypeInfo(Integer)), nil, outValue);
  Assert.AreEqual(2, outValue.AsInteger);
end;

procedure TTestMethodData.AllowRedefineBehaviorDefinitions_IsFalse_ExceptionIsThrown_WhenRedefining;
var
  methodData  : IMethodData;
  someValue1,
  someValue2  : TValue;
begin
  someValue1 := TValue.From<Integer>(1);
  someValue2 := TValue.From<Integer>(2);

  methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(FALSE, FALSE, FALSE));
  methodData.WillReturnWhen(TArray<TValue>.Create(someValue1), someValue1, nil);

  Assert.WillRaise(procedure
  begin
    methodData.WillReturnWhen(TArray<TValue>.Create(someValue1), someValue2, nil);
  end, EMockSetupException);
end;

procedure TTestMethodData.AllowRedefineBehaviorDefinitions_IsFalse_NoExceptionIsThrown_WhenAddingNormal;
var
  methodData  : IMethodData;
  someValue1,
  someValue2  : TValue;
  outValue    : TValue;
  intType     : TRttiType;
begin
  someValue1 := TValue.From<Integer>(1);
  someValue2 := TValue.From<Integer>(2);
  methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(FALSE, FALSE, FALSE));
  methodData.WillReturnWhen([nil, someValue1], someValue1, nil);
  Assert.WillNotRaiseAny(procedure
  begin
    methodData.WillReturnWhen([nil, someValue2], someValue2, nil);
  end);

  intType := TRttiContext.Create.GetType(TypeInfo(Integer));
  methodData.RecordHit([nil, someValue1], intType, nil, outValue);
  Assert.AreEqual(1, outValue.AsInteger);
  methodData.RecordHit([nil, someValue2], intType, nil, outValue);
  Assert.AreEqual(2, outValue.AsInteger);
end;

procedure TTestMethodData.AllowRedefineBehaviorDefinitions_IsTrue_NoExceptionIsThrown_WhenMatcherAreDifferent;
var
  methodData  : IMethodData;
  someParam,
  someValue1,
  someValue2  : TValue;
  LObjectToTest : TObjectToTest;
  LAnotherObject: TAnotherObject;
  LAndAnotherObject: TAndAnotherObject;
begin
  LObjectToTest := TObjectToTest.Create;
  LAnotherObject := TAnotherObject.Create;
  LAndAnotherObject := TAndAnotherObject.Create;
  try
    someValue1 := TValue.From<TAnotherObject>(LAnotherObject);
    someValue2 := TValue.From<TAndAnotherObject>(LAndAnotherObject);
    someParam := TValue.From<TObjectToTest>(LObjectToTest);

    methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(FALSE, FALSE, FALSE));
    methodData.WillReturnWhen([nil, someParam], someValue1, [TMatcher<TAnotherObject>.Create(function(value : TAnotherObject) : boolean
    begin
      result := true;
    end)]);

    Assert.WillNotRaiseAny(procedure
    begin
      methodData.WillReturnWhen([nil, someParam], someValue2, [TMatcher<TAndAnotherObject>.Create(function(value : TAndAnotherObject) : boolean
      begin
        result := true;
      end)]);
    end);
  finally
    LObjectToTest.Free;
    LAnotherObject.Free;
    LAndAnotherObject.Free;
  end;
end;

procedure TTestMethodData.AllowRedefineBehaviorDefinitions_IsTrue_OldBehaviorIsDeleted;
var
  methodData  : IMethodData;
  someValue1,
  someValue2  : TValue;
  outValue    : TValue;
begin
  someValue1 := TValue.From<Integer>(1);
  someValue2 := TValue.From<Integer>(2);
  methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(TRUE, TRUE, TRUE));
  methodData.WillReturnWhen(TArray<TValue>.Create(someValue1), someValue1, nil);
  methodData.WillReturnWhen(TArray<TValue>.Create(someValue1), someValue2, nil);

  methodData.RecordHit(TArray<TValue>.Create(someValue1), TrttiContext.Create.GetType(TypeInfo(integer)), nil, outValue);

  Assert.AreEqual(someValue2.AsInteger, outValue.AsInteger );
end;


procedure TTestMethodData.BehaviourMustBeDefined_IsFalse_AndBehaviourIsNotDefined_RaisesNoException;
var
  methodData  : IMethodData;
begin
  methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(FALSE, FALSE, FALSE));
  Assert.WillNotRaiseAny(procedure
  var
    someValue : TValue;
  begin
    methodData.RecordHit(TArray<TValue>.Create(), nil, nil, someValue);
  end);
end;

procedure TTestMethodData.BehaviourMustBeDefined_IsTrue_AndBehaviourIsNotDefined_RaisesException;
var
  methodData  : IMethodData;
begin
  methodData := TMethodData.Create('x', 'x', TSetupMethodDataParameters.Create(FALSE, TRUE, FALSE));

  Assert.WillRaise(procedure
  var
    someValue : TValue;
  begin
    methodData.RecordHit(TArray<TValue>.Create(), nil, nil, someValue);
  end, EMockException);
end;


initialization
  TDUnitX.RegisterTestFixture(TTestMethodData);

end.
