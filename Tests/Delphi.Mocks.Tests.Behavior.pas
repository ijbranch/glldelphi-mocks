unit Delphi.Mocks.Tests.Behavior;

interface

uses
  SysUtils,
  DUnitX.TestFramework,
  Rtti,
  Delphi.Mocks,
  Delphi.Mocks.ParamMatcher;

type
  /// <summary>The exception the behaviours under test are told to raise, so a test can tell it from any other.
  /// </summary>
  ETestBehaviourException = class(Exception);

  {$M+}
  /// <summary>Tests TBehavior on its own: what each constructor sets up, what Match answers and what Execute
  /// returns or raises.</summary>
  [TestFixture]
  TTestBehaviors = class
  private
    /// <summary>Supplies RTTI types for return types.</summary>
    FContext : TRttiContext;
    /// <summary>An empty matcher list, for behaviours that match literal arguments.</summary>
    FMatchers : TArray<IMatcher>;
  public
    /// <summary>Creates the RTTI context.</summary>
    [Setup]
    procedure SetUp;
  published
    /// <summary>Proves a WillReturnWhen behaviour matches a call whose arguments equal the ones it was defined
    /// with, so the defined value is returned for exactly those arguments.</summary>
    procedure Test_WillReturnBehavior_Match;
    /// <summary>Proves a WillReturnWhen behaviour does not match when one argument differs, so it cannot answer
    /// calls it was not defined for.</summary>
    procedure Test_WillReturnBehavior_NoMatch;
    /// <summary>Proves a ReturnDefault behaviour returns its value whatever the arguments.</summary>
    procedure Test_WillReturnBehavior_Default;
    /// <summary>Proves a WillExecute behaviour runs its function and returns that function's result exactly, case
    /// included.</summary>
    procedure Test_WillExecute;

    // WillRaise-Execute tests
    /// <summary>Proves WillRaise raises the class it was given, not a generic one.</summary>
    procedure CreateWillRaise_Execute_Raises_Exception_Of_Our_Choice;
    /// <summary>Proves WillRaise raises with the message it was given, exactly.</summary>
    procedure CreateWillRaise_Execute_Raises_Exception_Message_Of_Our_Choice;
    /// <summary>Proves WillRaise with no exception class raises nothing, rather than an access violation.
    /// </summary>
    procedure CreateWillRaise_Execute_Raises_No_Exception_If_Passed_Nil_For_Exception_Class;
    /// <summary>Proves WillRaise with an empty message uses the documented default message.</summary>
    procedure CreateWillRaise_Execute_Raises_Exception_Of_Our_Choice_With_Default_Message;

    // WillRaiseWhen-Exexute tests
    /// <summary>Proves WillRaiseWhen raises the class it was given.</summary>
    procedure CreateWillRaiseWhen_Execute_Raises_Exception_Of_Our_Choice;
    /// <summary>Proves WillRaiseWhen raises with the message it was given, exactly.</summary>
    procedure CreateWillRaiseWhen_Execute_Raises_Exception_Message_Of_Our_Choice;
    /// <summary>Proves a raise-always behaviour with no exception class raises nothing.</summary>
    procedure CreateWillRaiseWhen_Execute_Raises_No_Exception_If_Passed_Nil_For_Exception_Class;
    /// <summary>Proves WillRaiseWhen with an empty message uses the documented default message.</summary>
    procedure CreateWillRaiseWhen_Execute_Raises_Exception_Of_Our_Choice_With_Default_Message;

    // Test Behavior Types After Construction.
    /// <summary>Proves CreateWillExecute makes a WillExecute behaviour, which FindBestBehavior relies on.</summary>
    procedure CreateWillExecute_Behavior_Type_Set_To_WillExecute;
    /// <summary>Proves CreateWillExecuteWhen makes a WillExecuteWhen behaviour.</summary>
    procedure CreateWillExecuteWhen_Behavior_Type_Set_To_WillExecuteWhen;
    /// <summary>Proves CreateWillReturnWhen makes a WillReturn behaviour that returns its value.</summary>
    procedure CreateWillReturnWhen_Behavior_Type_Set_To_WillReturn;
    /// <summary>Proves CreateReturnDefault makes a ReturnDefault behaviour.</summary>
    procedure CreateReturnDefault_Behavior_Type_Set_To_ReturnDefault;
    /// <summary>Proves CreateWillRaise makes a WillRaiseAlways behaviour, which applies whatever the arguments.
    /// </summary>
    procedure CreateWillRaise_Behavior_Type_Set_To_WillAlwaysRaise;
    /// <summary>Proves CreateWillRaiseWhen makes a WillRaise behaviour.</summary>
    procedure CreateWillRaiseWhen_Behavior_Type_Set_To_WillRaise;
    /// <summary>Proves Match never raises for a WillRaise behaviour, even when the arguments do not match: raising
    /// is Execute's job. Match used to raise for every call, whatever its arguments.</summary>
    procedure WillRaiseWhen_Match_Does_Not_Raise_And_Rejects_Other_Arguments;
  end;
  {$M-}

implementation

uses
  Delphi.Mocks.Helpers,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.Behavior,
  classes;

{ TTestBehaviors }


procedure TTestBehaviors.SetUp;
begin
  FContext := TRttiContext.Create;
end;

procedure TTestBehaviors.Test_WillExecute;
var
  behavior : IBehavior;
  returnValue: TValue;
begin
  behavior := TBehavior.CreateWillExecute(
    function (const args : TArray<TValue>; const returnType : TRttiType) : TValue
    begin
      result := 'Hello World';
    end
    );

  returnValue := behavior.Execute(nil,nil);

  Assert.AreEqual('Hello World', returnValue.AsString, False);
end;

procedure TTestBehaviors.Test_WillReturnBehavior_Default;
var
  behavior : IBehavior;
  args : TArray<TValue>;
  returnValue : TValue;
  rType : TRttiType;
begin
  returnValue := 123;
  behavior := TBehavior.CreateReturnDefault(returnValue);
  SetLength(args,3);
  args[0] := 1;
  args[1] := 2;
  args[2] := 3;
  Assert.IsTrue(behavior.Match(args), 'A default applies whatever the arguments');
  rType := FContext.GetType(TypeInfo(Int64));
  returnValue := behavior.Execute(args,rType);
  Assert.AreEqual<Int64>(123, returnValue.AsInt64);
end;

procedure TTestBehaviors.Test_WillReturnBehavior_Match;
var
  behavior : IBehavior;
  args : TArray<TValue>;
  returnValue : TValue;
begin
  SetLength(args,3);
  args[0] := 1;
  args[1] := 2;
  args[2] :=  'hello';
  behavior := TBehavior.CreateWillReturnWhen(args,returnValue,Fmatchers);
  args[0] := 1;
  args[1] := 2;
  args[2] :=  'hello';
  Assert.IsTrue(behavior.Match(args));
end;

procedure TTestBehaviors.Test_WillReturnBehavior_NoMatch;
var
  behavior : IBehavior;
  args : TArray<TValue>;
  returnValue : TValue;
begin
  SetLength(args,3);
  args[0] := 1;
  args[1] := 2;
  args[2] := 'hello';
  behavior := TBehavior.CreateWillReturnWhen(args,returnValue,FMatchers);
  args[0] := 1;
  args[1] := 2;
  args[2] :=  'hello world';
  Assert.IsFalse(behavior.Match(args));
end;

procedure TTestBehaviors.CreateReturnDefault_Behavior_Type_Set_To_ReturnDefault;
var
  behavior: IBehavior;
begin
  behavior := TBehavior.CreateReturnDefault(nil);

  Assert.IsTrue(behavior.BehaviorType = TBehaviorType.ReturnDefault, 'CreateReturnDefault behavior type isn''t ReturnDefault');
end;

procedure TTestBehaviors.CreateWillExecuteWhen_Behavior_Type_Set_To_WillExecuteWhen;
var
  behavior: IBehavior;
begin
  behavior := TBehavior.CreateWillExecuteWhen(nil, nil,FMatchers);

  Assert.IsTrue(behavior.BehaviorType = TBehaviorType.WillExecuteWhen, 'CreateWillExecuteWhen behavior type isn''t WillExecuteWhen');
end;

procedure TTestBehaviors.CreateWillExecute_Behavior_Type_Set_To_WillExecute;
var
  behavior: IBehavior;
begin
  behavior := TBehavior.CreateWillExecute(nil);

  Assert.IsTrue(behavior.BehaviorType = TBehaviorType.WillExecute, 'CreateWillExecute behavior type isn''t WillExecute');
end;

procedure TTestBehaviors.CreateWillRaiseWhen_Behavior_Type_Set_To_WillRaise;
var
  behavior: IBehavior;
begin
  //What is passed here shouldn't affect the result of the behavior being set. No way to avoid it however.
  behavior := TBehavior.CreateWillRaiseWhen(nil, ETestBehaviourException, '',FMatchers);

  Assert.IsTrue(behavior.BehaviorType = TBehaviorType.WillRaise, 'CreateWillRaiseWhen behavior type isn''t WillRaise');
end;

procedure TTestBehaviors.CreateWillRaiseWhen_Execute_Raises_Exception_Message_Of_Our_Choice;
var
  behavior: IBehavior;
const
  EXCEPTION_STRING = 'Exception!';
begin
  behavior := TBehavior.CreateWillRaiseWhen(nil, ETestBehaviourException, EXCEPTION_STRING,FMatchers);

  //Passing nils as we don't care about these values for the exception
  Assert.WillRaiseWithMessage(procedure
    begin
     behavior.Execute(nil, nil);
    end, ETestBehaviourException, EXCEPTION_STRING);
end;

procedure TTestBehaviors.CreateWillRaiseWhen_Execute_Raises_Exception_Of_Our_Choice;
var
  behavior: IBehavior;
begin
  behavior := TBehavior.CreateWillRaiseWhen(nil, ETestBehaviourException, '',FMatchers);

  Assert.WillRaise(procedure
  begin
    //Passing nils as we don't care about these values for the exception
    behavior.Execute(nil, nil);
  end, ETestBehaviourException);

end;

procedure TTestBehaviors.CreateWillRaiseWhen_Execute_Raises_Exception_Of_Our_Choice_With_Default_Message;
var
  behavior: IBehavior;
const
  EXCEPTION_STRING = 'raised by mock';
begin
  behavior := TBehavior.CreateWillRaiseWhen(nil, ETestBehaviourException, '',FMatchers);

  Assert.WillRaiseWithMessage(procedure
  begin
    //Passing nils as we don't care about these values for the exception
    behavior.Execute(nil, nil);
  end, ETestBehaviourException, EXCEPTION_STRING);

end;

procedure TTestBehaviors.CreateWillRaiseWhen_Execute_Raises_No_Exception_If_Passed_Nil_For_Exception_Class;
var
  behavior: IBehavior;
begin
  behavior := TBehavior.CreateWillRaiseWhen(nil, nil, '', FMatchers);

  //No exception class, therefore no exception
  Assert.WillNotRaiseAny(procedure
  begin
    behavior.Execute(nil, nil);
  end);
end;

procedure TTestBehaviors.CreateWillRaise_Behavior_Type_Set_To_WillAlwaysRaise;
var
  behavior: IBehavior;
  args : TArray<TValue>;
begin
  behavior := TBehavior.CreateWillRaise(ETestBehaviourException, '');

  Assert.IsTrue(behavior.BehaviorType = TBehaviorType.WillRaiseAlways, 'CreateWillRaise behavior type isn''t WillRaiseAlways');
  args := [TValue.From<Integer>(0), TValue.From<Integer>(42)];
  Assert.IsTrue(behavior.Match(args), 'A raise-always behaviour must apply whatever the arguments');
end;

procedure TTestBehaviors.CreateWillRaise_Execute_Raises_Exception_Message_Of_Our_Choice;
var
  behavior: IBehavior;
const
  EXCEPTION_STRING = 'Exception!';
begin
  behavior := TBehavior.CreateWillRaise(ETestBehaviourException, EXCEPTION_STRING);

  Assert.WillRaiseWithMessage(procedure
  begin
    //Passing nils as we don't care about these values for the exception
    behavior.Execute(nil, nil);
  end, ETestBehaviourException, EXCEPTION_STRING);
end;

procedure TTestBehaviors.CreateWillRaise_Execute_Raises_Exception_Of_Our_Choice;
var
  behavior: IBehavior;
begin
  behavior := TBehavior.CreateWillRaise(ETestBehaviourException, '');

  Assert.WillRaise(procedure
  begin
    //Passing nils as we don't care about these values for the exception
    behavior.Execute(nil, nil);
  end, ETestBehaviourException);
end;


procedure TTestBehaviors.CreateWillRaise_Execute_Raises_Exception_Of_Our_Choice_With_Default_Message;
var
  behavior: IBehavior;
const
  EXCEPTION_STRING = 'raised by mock';
begin
  behavior := TBehavior.CreateWillRaise(ETestBehaviourException, '');

  Assert.WillRaiseWithMessage(procedure
  begin
  //Passing nils as we don't care about these values for the exception
  behavior.Execute(nil, nil);
  end, ETestBehaviourException, EXCEPTION_STRING);
end;

procedure TTestBehaviors.CreateWillRaise_Execute_Raises_No_Exception_If_Passed_Nil_For_Exception_Class;
var
  behavior: IBehavior;
begin
  behavior := TBehavior.CreateWillRaise(nil, '');

  //No exception class, therefore no exception
  Assert.WillNotRaiseAny(procedure
  begin
    behavior.Execute(nil, nil);
  end);
end;

procedure TTestBehaviors.CreateWillReturnWhen_Behavior_Type_Set_To_WillReturn;
var
  behavior: IBehavior;
  args : TArray<TValue>;
begin
  args := [TValue.From<Integer>(0), TValue.From<Integer>(7)];
  behavior := TBehavior.CreateWillReturnWhen(args, TValue.From<Integer>(99), FMatchers);

  Assert.IsTrue(behavior.BehaviorType = TBehaviorType.WillReturn, 'CreateWillReturnWhen behavior type isn''t WillReturn');
  Assert.AreEqual(99, behavior.Execute(args, FContext.GetType(TypeInfo(Integer))).AsInteger);
end;

procedure TTestBehaviors.WillRaiseWhen_Match_Does_Not_Raise_And_Rejects_Other_Arguments;
var
  behavior: IBehavior;
  definedArgs, otherArgs : TArray<TValue>;
  matched : Boolean;
begin
  definedArgs := [TValue.From<Integer>(0), TValue.From<Integer>(1)];
  otherArgs := [TValue.From<Integer>(0), TValue.From<Integer>(2)];
  behavior := TBehavior.CreateWillRaiseWhen(definedArgs, ETestBehaviourException, 'raised', FMatchers);

  matched := True;
  Assert.WillNotRaiseAny(procedure
  begin
    matched := behavior.Match(otherArgs);
  end);
  Assert.IsFalse(matched, 'A WillRaise behaviour must not apply to arguments it was not defined for');
  Assert.IsTrue(behavior.Match(definedArgs), 'A WillRaise behaviour must apply to the arguments it was defined for');
end;


initialization
  TDUnitX.RegisterTestFixture(TTestBehaviors);

end.
