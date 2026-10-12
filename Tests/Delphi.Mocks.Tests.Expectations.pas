unit Delphi.Mocks.Tests.Expectations;

interface

uses
  DUnitX.TestFramework,
  Delphi.Mocks.ParamMatcher,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.Expectation;


type
  {$M+}
  /// <summary>Tests TExpectation on its own: what each constructor makes, and when each kind is met.</summary>
  [TestFixture]
  TTestExpectations = class
  protected
    /// <summary>An empty matcher list, for expectations that match literal arguments.</summary>
    FMatchers : TArray<IMatcher>;
  published
    //Created with correct exception type set
    /// <summary>Proves CreateOnceWhen makes a OnceWhen expectation, which counts only matching calls.</summary>
    procedure CreateOnceWhen_Expectation_Type_Set_To_OnceWhen;
    /// <summary>Proves CreateOnce makes a Once expectation.</summary>
    procedure CreateOnce_Expectation_Type_Set_To_Once;
    /// <summary>Proves CreateNeverWhen makes a NeverWhen expectation.</summary>
    procedure CreateNeverWhen_Expectation_Type_Set_To_NeverWhen;
    /// <summary>Proves CreateNever makes a Never expectation.</summary>
    procedure CreateNever_Expectation_Type_Set_To_Never;
    /// <summary>Proves CreateAtLeastOnceWhen makes an AtLeastOnceWhen expectation.</summary>
    procedure CreateAtLeastOnceWhen_Expectation_Type_Set_To_AtLeastOnceWhen;
    /// <summary>Proves CreateAtLeastOnce makes an AtLeastOnce expectation.</summary>
    procedure CreateAtLeastOnce_Expectation_Type_Set_To_AtLeastOnce;
    /// <summary>Proves CreateAtLeastWhen makes an AtLeastWhen expectation.</summary>
    procedure CreateAtLeastWhen_Expectation_Type_Set_To_AtLeastWhen;
    /// <summary>Proves CreateAtLeast makes an AtLeast expectation.</summary>
    procedure CreateAtLeast_Expectation_Type_Set_To_AtLeast;
    /// <summary>Proves CreateAtMostWhen makes an AtMostWhen expectation.</summary>
    procedure CreateAtMostWhen_Expectation_Type_Set_To_AtMostWhen;
    /// <summary>Proves CreateAtMost makes an AtMost expectation.</summary>
    procedure CreateAtMost_Expectation_Type_Set_To_AtMost;
    /// <summary>Proves CreateBetweenWhen makes a BetweenWhen expectation.</summary>
    procedure CreateBetweenWhen_Expectation_Type_Set_To_BetweenWhen;
    /// <summary>Proves CreateBetween makes a Between expectation.</summary>
    procedure CreateBetween_Expectation_Type_Set_To_Between;
    /// <summary>Proves CreateExactlyWhen makes an ExactlyWhen expectation.</summary>
    procedure CreateExactlyWhen_Expectation_Type_Set_To_ExactlyWhen;
    /// <summary>Proves CreateExactly makes an Exactly expectation.</summary>
    procedure CreateExactly_Expectation_Type_Set_To_Exactly;
    /// <summary>Proves CreateBeforeWhen makes a BeforeWhen expectation.</summary>
    procedure CreateBeforeWhen_Expectation_Type_Set_To_BeforeWhen;
    /// <summary>Proves CreateBefore makes a Before expectation.</summary>
    procedure CreateBefore_Expectation_Type_Set_To_Before;
    /// <summary>Proves CreateAfterWhen makes an AfterWhen expectation.</summary>
    procedure CreateAfterWhen_Expectation_Type_Set_To_AfterWhen;
    /// <summary>Proves CreateAfter makes an After expectation.</summary>
    procedure CreateAfter_Expectation_Type_Set_To_After;

    //ExpectationMet after record hit tests
    /// <summary>Proves OnceWhen is met by exactly one hit.</summary>
    procedure ExpectationMet_With_OnceWhen_CalledOnce;
    /// <summary>Proves OnceWhen is not met with no hit.</summary>
    procedure ExpectationNotMet_With_OnceWhen_CalledNever;
    /// <summary>Proves ResetCalls forgets the hit, so OnceWhen is unmet again.</summary>
    procedure ExpectationNotMet_With_OnceWhen_CalledOnceAndResetCalls;

    /// <summary>Proves Never is met with no hit.</summary>
    procedure ExpectationMet_With_Never_CalledNever;
    /// <summary>Proves Never is broken by one hit.</summary>
    procedure ExpectationNotMet_With_Never_CalledOnce;

    /// <summary>Proves AtLeastOnce is met by one hit and still by two.</summary>
    procedure ExpectationMet_With_AtLeastOnce_CalledOnceAndTwoTimes;
    /// <summary>Proves AtLeastOnce is unmet with no hit.</summary>
    procedure ExpectationNotMet_With_AtLeastOnce_CalledNever;

    /// <summary>Proves AtLeast(2) is met at the boundary and above it.</summary>
    procedure ExpectationMet_With_AtLeast2_CalledTwoTimeAndThreeTimes;
    /// <summary>Proves AtLeast(2) is unmet below the boundary.</summary>
    procedure ExpectationNotMet_With_AtLeast2_CalledNeverAndOnce;

    /// <summary>Proves AtMost(2) is met from no hit up to the boundary.</summary>
    procedure ExpectationMet_With_AtMost2_CalledNeverOnceAndTwoTimes;
    /// <summary>Proves AtMost(2) is broken above the boundary.</summary>
    procedure ExpectationNotMet_With_AtMost2_CalledThreeTimes;

    /// <summary>Proves Between(0, 4) is met with no hit: the lower bound is inclusive.</summary>
    procedure ExpectationMet_With_Between_0to4_CalledNever;
    /// <summary>Proves Between(1, 4) is met by one hit.</summary>
    procedure ExpectationMet_With_Between_1to4_CalledOnce;
    /// <summary>Proves Between(1, 4) is unmet with no hit.</summary>
    procedure ExpectationNotMet_With_Between_1to4_CalledNever;

    /// <summary>Proves Exactly(2) is met by two hits.</summary>
    procedure ExpectationMet_With_Exactly2_Called2Times;
    /// <summary>Proves Exactly(2) is unmet with no hit.</summary>
    procedure ExpectationMet_With_Exactly2_CalledNever;
    /// <summary>Proves Exactly(2) is unmet below and above the count.</summary>
    procedure ExpectationMet_With_Exactly2_CalledOnceAnd3Times;

    /// <summary>Proves After is met when the method is first called after the other method's first call.</summary>
    procedure ExpectationMet_With_After;
    /// <summary>Proves After is unmet when the method is first called before the other method, or the other is never called.</summary>
    procedure ExpectationNotMet_With_After;

    /// <summary>Proves Before is met when the method is first called before the other method's first call.</summary>
    procedure ExpectationMet_With_Before;
    /// <summary>Proves Before is unmet when the method is first called after the other method, or the other is never called.</summary>
    procedure ExpectationNotMet_With_Before;
  end;
  {$M-}


implementation

uses
  Delphi.Mocks.MethodData;

{ TTestExpectations }


{ TTestExpectations }

procedure TTestExpectations.CreateAfterWhen_Expectation_Type_Set_To_AfterWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAfterWhen('', '', nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.AfterWhen, 'CreateAfterWhen expectation type isn''t set to AfterWhen');
end;

procedure TTestExpectations.CreateAfter_Expectation_Type_Set_To_After;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAfter('', '');

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.After, 'CreateAfter expectation type isn''t set to After');

end;

procedure TTestExpectations.CreateAtLeastOnceWhen_Expectation_Type_Set_To_AtLeastOnceWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeastOnceWhen('', nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.AtLeastOnceWhen, 'CreateAtLeastOnceWhen expectation type isn''t set to AtLeastOnceWhen');

end;

procedure TTestExpectations.CreateAtLeastOnce_Expectation_Type_Set_To_AtLeastOnce;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeastOnce('');

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.AtLeastOnce, 'CreateAtLeastOnce expectation type isn''t set to AtLeastOnce');

end;

procedure TTestExpectations.CreateAtLeastWhen_Expectation_Type_Set_To_AtLeastWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeastWhen('', 0, nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.AtLeastWhen, 'CreateAtLeastWhen expectation type isn''t set to AtLeastWhen');

end;

procedure TTestExpectations.CreateAtLeast_Expectation_Type_Set_To_AtLeast;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeast('', 0);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.AtLeast, 'CreateAtLeast expectation type isn''t set to AtLeast');


end;

procedure TTestExpectations.CreateAtMostWhen_Expectation_Type_Set_To_AtMostWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtMostWhen('', 0, nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.AtMostWhen, 'CreateAtMostWhen expectation type isn''t set to AtMostWhen');


end;

procedure TTestExpectations.CreateAtMost_Expectation_Type_Set_To_AtMost;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtMost('', 0);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.AtMost, 'CreateAtMost expectation type isn''t set to AtMost');

end;

procedure TTestExpectations.CreateBeforeWhen_Expectation_Type_Set_To_BeforeWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateBeforeWhen('', '', nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.BeforeWhen, 'CreateBeforeWhen expectation type isn''t set to BeforeWhen');

end;

procedure TTestExpectations.CreateBefore_Expectation_Type_Set_To_Before;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateBefore('', '');

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.Before, 'CreateBefore expectation type isn''t set to Before');

end;

procedure TTestExpectations.CreateBetweenWhen_Expectation_Type_Set_To_BetweenWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateBetweenWhen('', 0, 0, nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.BetweenWhen, 'CreateBetweenWhen expectation type isn''t set to BetweenWhen');
end;

procedure TTestExpectations.CreateBetween_Expectation_Type_Set_To_Between;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateBetween('', 0, 0);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.Between, 'CreateBetween expectation type isn''t set to Between');
end;

procedure TTestExpectations.CreateExactlyWhen_Expectation_Type_Set_To_ExactlyWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateExactlyWhen('', 0, nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.ExactlyWhen, 'CreateExactlyWhen expectation type isn''t set to ExactlyWhen');
end;

procedure TTestExpectations.CreateExactly_Expectation_Type_Set_To_Exactly;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateExactly('', 0);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.Exactly, 'CreateExactly expectation type isn''t set to Exactly');
end;

procedure TTestExpectations.CreateNeverWhen_Expectation_Type_Set_To_NeverWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateNeverWhen('', nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.NeverWhen, 'CreateNeverWhen expectation type isn''t set to NeverWhen');
end;

procedure TTestExpectations.CreateNever_Expectation_Type_Set_To_Never;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateNever('');

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.Never, 'CreateNever expectation type isn''t set to Never');
end;

procedure TTestExpectations.CreateOnceWhen_Expectation_Type_Set_To_OnceWhen;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateOnceWhen('', nil, FMatchers);

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.OnceWhen, 'CreateOnceWhen expectation type isn''t set to OnceWhen');
end;

procedure TTestExpectations.CreateOnce_Expectation_Type_Set_To_Once;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateOnce('');

  Assert.IsTrue(expectation.ExpectationType = TExpectationType.Once, 'CreateOnce expectation type isn''t set to Once');
end;

procedure TTestExpectations.ExpectationMet_With_OnceWhen_CalledOnce;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateOnceWhen('', nil, FMatchers);

  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for OnceWhen being called once');
end;

procedure TTestExpectations.ExpectationNotMet_With_OnceWhen_CalledNever;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateOnceWhen('', nil, nil);

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for OnceWhen being not called');
end;

procedure TTestExpectations.ExpectationNotMet_With_OnceWhen_CalledOnceAndResetCalls;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateOnceWhen('', nil, FMatchers);

  expectation.RecordHit;
  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for OnceWhen being called once');
  expectation.ResetCalls;
  Assert.IsFalse(expectation.ExpectationMet, 'Exception not met for OnceWhen being called once, after ResetCalls');
end;

procedure TTestExpectations.ExpectationNotMet_With_Between_1to4_CalledNever;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateBetween('', 1, 4);

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for Between 1 to 4 being not called');
end;


procedure TTestExpectations.ExpectationMet_With_Between_0to4_CalledNever;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateBetween('', 0, 4);

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for Between 0 to 4 being not called');
end;


procedure TTestExpectations.ExpectationMet_With_Between_1to4_CalledOnce;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateBetween('', 1, 4);

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for Between 1 to 4 being not called');

  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for Between 1 to 4 being called once');
end;

procedure TTestExpectations.ExpectationMet_With_Never_CalledNever;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateNever('');

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for Never being not called');
end;

procedure TTestExpectations.ExpectationNotMet_With_Never_CalledOnce;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateNever('');

  expectation.RecordHit;

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for Never being called once');
end;

procedure TTestExpectations.ExpectationMet_With_Exactly2_Called2Times;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateExactly('', 2);

  expectation.RecordHit;
  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for Exaclty 2 being called 2 times');
end;

procedure TTestExpectations.ExpectationMet_With_Exactly2_CalledNever;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateExactly('', 2);

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for Exaclty 2 being not called');
end;

procedure TTestExpectations.ExpectationMet_With_Exactly2_CalledOnceAnd3Times;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateExactly('', 2);

  expectation.RecordHit;

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for Exaclty 2 being called once');

  expectation.RecordHit;
  expectation.RecordHit;

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for Exaclty 2 being called 3 times');
end;


procedure TTestExpectations.ExpectationMet_With_AtLeastOnce_CalledOnceAndTwoTimes;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeastOnce('');

  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for AtLeastOnce being called once');

  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for AtLeastOnce being called once');
end;

procedure TTestExpectations.ExpectationNotMet_With_AtLeastOnce_CalledNever;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeastOnce('');

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for AtLeastOnce being not called');
end;

procedure TTestExpectations.ExpectationMet_With_AtLeast2_CalledTwoTimeAndThreeTimes;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeast('', 2);

  expectation.RecordHit;
  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for AtLeast2 being called two times');

  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for AtLeast2 being called three times');
end;

procedure TTestExpectations.ExpectationNotMet_With_AtLeast2_CalledNeverAndOnce;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtLeast('', 2);

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for AtLeast2 being never called');

  expectation.RecordHit;

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for AtLeast2 being called once');
end;


procedure TTestExpectations.ExpectationMet_With_AtMost2_CalledNeverOnceAndTwoTimes;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtMost('', 2);

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for AtMost2 being called never');

  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for AtMost2 being called once');

  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, 'Exception not met for AtMost2 being called two times');
end;

procedure TTestExpectations.ExpectationNotMet_With_AtMost2_CalledThreeTimes;
var
  expectation : IExpectation;
begin
  expectation := TExpectation.CreateAtMost('', 2);

  expectation.RecordHit;
  expectation.RecordHit;
  expectation.RecordHit;

  Assert.IsFalse(expectation.ExpectationMet, 'Exception met for AtMost2 being called three times');
end;

procedure TTestExpectations.ExpectationMet_With_After;
var
  callLog : ICallLog;
  expectation : IExpectation;
begin
  callLog := TCallLog.Create;
  expectation := TExpectation.CreateAfter('Read', 'Open', callLog);
  Assert.IsFalse(expectation.ExpectationMet, 'Unmet before any call');

  callLog.RecordCall('Open');
  callLog.RecordCall('Read');
  expectation.RecordHit;

  Assert.IsTrue(expectation.ExpectationMet, expectation.Report);
end;

procedure TTestExpectations.ExpectationNotMet_With_After;
var
  callLog : ICallLog;
  expectation : IExpectation;
begin
  callLog := TCallLog.Create;
  expectation := TExpectation.CreateAfter('Read', 'Open', callLog);
  callLog.RecordCall('Read');
  expectation.RecordHit;
  Assert.IsFalse(expectation.ExpectationMet, 'Open never called');

  callLog.RecordCall('Open');
  Assert.IsFalse(expectation.ExpectationMet, 'Read was first called before Open');
  Assert.AreNotEqual('', expectation.Report);
end;

procedure TTestExpectations.ExpectationMet_With_Before;
var
  callLog : ICallLog;
  expectation : IExpectation;
begin
  callLog := TCallLog.Create;
  expectation := TExpectation.CreateBefore('Prepare', 'Commit', callLog);

  callLog.RecordCall('Prepare');
  expectation.RecordHit;
  Assert.IsFalse(expectation.ExpectationMet, 'Unmet while Commit has not been called');
  callLog.RecordCall('Commit');

  Assert.IsTrue(expectation.ExpectationMet, expectation.Report);
end;

procedure TTestExpectations.ExpectationNotMet_With_Before;
var
  callLog : ICallLog;
  expectation : IExpectation;
begin
  callLog := TCallLog.Create;
  expectation := TExpectation.CreateBefore('Prepare', 'Commit', callLog);

  callLog.RecordCall('Commit');
  callLog.RecordCall('Prepare');
  expectation.RecordHit;

  Assert.IsFalse(expectation.ExpectationMet, 'Prepare was first called after Commit');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestExpectations);

end.
