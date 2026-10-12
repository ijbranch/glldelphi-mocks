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

unit Delphi.Mocks.MethodData;

{$I 'Delphi.Mocks.inc'}


interface

uses
  System.Rtti,
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Mocks,
  Delphi.Mocks.WeakReference,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.ParamMatcher;

type
  /// <summary>The proxy-wide settings each method's data is created with.</summary>
  TSetupMethodDataParameters = record
    /// <summary>When True, a call to a method with no behaviour or expectation raises.</summary>
    BehaviorMustBeDefined  : boolean;
    /// <summary>When True, defining a behaviour or expectation again replaces the old one instead of raising.
    /// </summary>
    AllowRedefineBehaviorDefinitions: boolean;
    /// <summary>When True, the proxy is a stub: calls never fail for want of a return value.</summary>
    IsStub: boolean;
    /// <summary>Builds the settings.</summary>
    /// <param name="AIsStub">Whether the proxy is a stub.</param>
    /// <param name="ABehaviorMustBeDefined">Whether a behaviour must be defined for every call.</param>
    /// <param name="AAllowRedefineBehaviorDefinitions">Whether definitions may be replaced.</param>
    /// <returns>The settings.</returns>
    class function Create(const AIsStub: boolean; const ABehaviorMustBeDefined, AAllowRedefineBehaviorDefinitions: boolean): TSetupMethodDataParameters; static;
  end;

  /// <summary>The order in which a proxy's methods were first called. Shared by every method of one proxy.
  /// </summary>
  TCallLog = class(TInterfacedObject, ICallLog)
  private
    /// <summary>The last sequence number handed out.</summary>
    FSequence : Int64;
    /// <summary>The first call's sequence number, keyed by lower-cased method name.</summary>
    FFirstCalls : TDictionary<string, Int64>;
  protected
    /// <summary>Records a call and returns its sequence number.</summary>
    /// <param name="AMethodName">The called method's name; compared without regard to case.</param>
    /// <returns>The call's sequence number, starting at 1.</returns>
    function RecordCall(const AMethodName : string) : Int64;
    /// <summary>Returns the sequence number of a method's first call.</summary>
    /// <param name="AMethodName">The method's name; compared without regard to case.</param>
    /// <returns>The first call's sequence number, or 0 when the method has not been called.</returns>
    function FirstCall(const AMethodName : string) : Int64;
    /// <summary>Returns the sequence number of the most recent call.</summary>
    /// <returns>The last sequence number handed out, or 0 when nothing has been called.</returns>
    function LastSequence : Int64;
    /// <summary>Forgets every recorded call.</summary>
    procedure Clear;
  public
    /// <summary>Creates an empty log.</summary>
    constructor Create;
    /// <summary>Frees the log.</summary>
    destructor Destroy; override;
  end;

  /// <summary>Everything recorded for one method of a mock: its behaviours, its expectations and its calls.
  /// </summary>
  TMethodData = class(TInterfacedObject,IMethodData)
  private
    /// <summary>The mocked type's name, for messages.</summary>
    FTypeName      : string;
    /// <summary>The method's name.</summary>
    FMethodName     : string;
    /// <summary>The behaviours, oldest first.</summary>
    FBehaviors      : TList<IBehavior>;
    /// <summary>The value WillReturnDefault set; meaningful only when FReturnDefaultDefined is True.</summary>
    FReturnDefault  : TValue;
    /// <summary>Whether WillReturnDefault was called. Kept apart from FReturnDefault because a nil object, nil
    /// interface or empty array is a legitimate default, and TValue.IsEmpty is True for all of them.</summary>
    FReturnDefaultDefined : boolean;
    /// <summary>The expectations.</summary>
    FExpectations   : TList<IExpectation>;
    /// <summary>The proxy-wide settings.</summary>
    FSetupParameters: TSetupMethodDataParameters;
    /// <summary>The auto mock container, held weakly: it owns the proxy that owns this method data, so a strong
    /// reference made a cycle and nothing in it was ever freed.</summary>
    FAutoMocker     : IWeakReference<IAutoMock>;
    /// <summary>The proxy's call log, which the ordering expectations are verified against; may be nil.</summary>
    FCallLog        : ICallLog;
    /// <summary>Supplies a result for a call no behaviour handled: an automock, the default, or an error.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <param name="AExpectationHitCtr">How many expectations counted the call.</param>
    /// <param name="returnType">The method's return type, or nil for a procedure.</param>
    /// <param name="Result">The value to return.</param>
    /// <exception cref="EMockException">A return value is needed and none is defined, or BehaviorMustBeDefined is
    /// set and nothing was defined.</exception>
    procedure MockNoBehaviourRecordHit(const Args: TArray<TValue>; const AExpectationHitCtr : Integer; const returnType : TRttiType; out Result : TValue);
    /// <summary>Resolves the weakly held auto mock container.</summary>
    /// <returns>The container, or nil when there is none or it has gone.</returns>
    function GetAutoMocker : IAutoMock;
    /// <summary>Finds a behaviour a new setup would redefine.</summary>
    /// <param name="behaviorType">The new setup's behaviour type.</param>
    /// <param name="Args">The new setup's arguments.</param>
    /// <param name="matchers">The new setup's matchers.</param>
    /// <returns>The behaviour, or nil.</returns>
    function FindBehaviorDefinition(const behaviorType : TBehaviorType; const Args: TArray<TValue>; const matchers : TArray<IMatcher>) : IBehavior;
    /// <summary>Finds an expectation a new setup would redefine.</summary>
    /// <param name="expectationType">The new setup's expectation type.</param>
    /// <param name="Args">The new setup's arguments.</param>
    /// <param name="matchers">The new setup's matchers.</param>
    /// <returns>The expectation, or nil.</returns>
    function FindExpectationDefinition(const expectationType : TExpectationType; const Args: TArray<TValue>; const matchers : TArray<IMatcher>) : IExpectation;
    /// <summary>Adds an expectation, replacing or refusing an existing one of the given kinds.</summary>
    /// <param name="existing">The expectation the new one redefines, or nil.</param>
    /// <param name="expectation">The new expectation.</param>
    /// <param name="description">How the expectation is named in the "already defines" message.</param>
    /// <exception cref="EMockException">existing is assigned and redefinition is not allowed.</exception>
    procedure AddExpectation(const existing, expectation : IExpectation; const description : string);
    /// <summary>Adds a behaviour, replacing or refusing an existing one.</summary>
    /// <param name="existing">The behaviour the new one redefines, or nil.</param>
    /// <param name="behavior">The new behaviour.</param>
    /// <param name="description">How the behaviour is named in the "already defines" message.</param>
    /// <exception cref="EMockSetupException">existing is assigned and redefinition is not allowed.</exception>
    procedure AddBehavior(const existing, behavior : IBehavior; const description : string);
  protected

    //Behaviors
    /// <summary>Sets the value returned when no other behaviour applies.</summary>
    /// <param name="returnValue">The default value; nil and empty values are allowed.</param>
    /// <exception cref="EMockSetupException">A default is already defined and redefinition is not allowed.
    /// </exception>
    procedure WillReturnDefault(const returnValue : TValue);
    /// <summary>Returns a value for matching arguments.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="returnValue">The value to return.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockSetupException">The same behaviour is already defined.</exception>
    procedure WillReturnWhen(const Args: TArray<TValue>; const returnValue : TValue; const matchers : TArray<IMatcher>);
    /// <summary>Raises on every call.</summary>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message.</param>
    /// <exception cref="EMockSetupException">The behaviour is already defined.</exception>
    procedure WillRaiseAlways(const exceptionClass : ExceptClass; const message : string);
    /// <summary>Raises for matching arguments.</summary>
    /// <param name="exceptionClass">The exception class to raise.</param>
    /// <param name="message">The exception message.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockSetupException">The same behaviour is already defined.</exception>
    procedure WillRaiseWhen(const exceptionClass : ExceptClass; const message : string;const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Runs a function on every call.</summary>
    /// <param name="func">The function to run.</param>
    /// <exception cref="EMockSetupException">The behaviour is already defined.</exception>
    procedure WillExecute(const func : TExecuteFunc);
    /// <summary>Runs a function for matching arguments.</summary>
    /// <param name="func">The function to run.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockSetupException">The same behaviour is already defined.</exception>
    procedure WillExecuteWhen(const func : TExecuteFunc; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);

    /// <summary>Finds the most recently defined behaviour of a type that applies to a call.</summary>
    /// <param name="behaviorType">The behaviour type.</param>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>The behaviour, or nil.</returns>
    function FindBehavior(const behaviorType : TBehaviorType; const Args: TArray<TValue>) : IBehavior; overload;
    /// <summary>Finds the behaviour of a type that ignores arguments.</summary>
    /// <param name="behaviorType">The behaviour type.</param>
    /// <returns>The behaviour, or nil.</returns>
    function FindBehavior(const behaviorType : TBehaviorType) : IBehavior; overload;
    /// <summary>Finds the behaviour that applies to a call. Raising behaviours come first, then executing,
    /// returning and finally the default; within a type the most recently defined one wins.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>The behaviour, or nil when none applies.</returns>
    function FindBestBehavior(const Args: TArray<TValue>) : IBehavior;
    /// <summary>Records a call to the method and produces its result.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <param name="returnType">The method's return type, or nil for a procedure.</param>
    /// <param name="method">The method's RTTI, or nil when unknown.</param>
    /// <param name="Result">The value to return from the call.</param>
    /// <exception cref="EMockException">No behaviour, default or automock supplies a required return value, or
    /// BehaviorMustBeDefined is set and nothing was defined.</exception>
    procedure RecordHit(const Args: TArray<TValue>; const returnType : TRttiType; const method : TRttiMethod; out Result : TValue);

    //Expectations
    /// <summary>Finds the first expectation of a type that a call counts towards.</summary>
    /// <param name="expectationType">The expectation type.</param>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>The expectation, or nil.</returns>
    function FindExpectation(const expectationType : TExpectationType; const Args: TArray<TValue>) : IExpectation;overload;
    /// <summary>Finds the first expectation of any of the given types.</summary>
    /// <param name="expectationTypes">The expectation types.</param>
    /// <returns>The expectation, or nil.</returns>
    function FindExpectation(const expectationTypes : TExpectationTypes) : IExpectation;overload;

    /// <summary>Expects exactly one call with matching arguments.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure OnceWhen(const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects exactly one call.</summary>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure Once;
    /// <summary>Expects no call with matching arguments.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure NeverWhen(const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects no call.</summary>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure Never;
    /// <summary>Expects one or more calls with matching arguments.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure AtLeastOnceWhen(const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects one or more calls.</summary>
    /// <exception cref="EMockException">An at-least expectation is already defined.</exception>
    procedure AtLeastOnce;
    /// <summary>Expects a minimum number of calls with matching arguments.</summary>
    /// <param name="times">The minimum.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure AtLeastWhen(const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects a minimum number of calls.</summary>
    /// <param name="times">The minimum.</param>
    /// <exception cref="EMockException">An at-least expectation is already defined.</exception>
    procedure AtLeast(const times : Cardinal);
    /// <summary>Expects a maximum number of calls with matching arguments.</summary>
    /// <param name="times">The maximum.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure AtMostWhen(const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects a maximum number of calls.</summary>
    /// <param name="times">The maximum.</param>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure AtMost(const times : Cardinal);
    /// <summary>Expects an inclusive range of calls with matching arguments.</summary>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum; must not be less than a.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockSetupException">b is less than a.</exception>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure BetweenWhen(const a,b : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects an inclusive range of calls.</summary>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum; must not be less than a.</param>
    /// <exception cref="EMockSetupException">b is less than a.</exception>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure Between(const a,b : Cardinal);
    /// <summary>Expects an exact number of calls with matching arguments.</summary>
    /// <param name="times">The number of calls.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure ExactlyWhen(const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects an exact number of calls.</summary>
    /// <param name="times">The number of calls.</param>
    /// <exception cref="EMockException">The expectation is already defined.</exception>
    procedure Exactly(const times : Cardinal);
    /// <summary>Expects a matching call first made before the first call of another method.</summary>
    /// <param name="ABeforeMethodName">The method this one must precede.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure BeforeWhen(const ABeforeMethodName : string ; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects this method first called before the first call of another method.</summary>
    /// <param name="ABeforeMethodName">The method this one must precede.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure Before(const ABeforeMethodName : string);
    /// <summary>Expects a matching call first made after the first call of another method.</summary>
    /// <param name="AAfterMethodName">The method this one must follow.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure AfterWhen(const AAfterMethodName : string;const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects this method first called after the first call of another method.</summary>
    /// <param name="AAfterMethodName">The method this one must follow.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure After(const AAfterMethodName : string);

    /// <summary>Checks every expectation.</summary>
    /// <param name="report">Receives a description of the unmet expectations, or an empty string.</param>
    /// <returns>True when every expectation is met.</returns>
    function Verify(var report : string) : boolean;
    /// <summary>Forgets every counted call.</summary>
    procedure ResetCalls;
    /// <summary>Removes every expectation.</summary>
    procedure ClearExpectations;
  public
    /// <summary>Creates the data for one method.</summary>
    /// <param name="ATypeName">The mocked type's name, for messages.</param>
    /// <param name="AMethodName">The method's name.</param>
    /// <param name="ASetupParameters">The proxy-wide settings.</param>
    /// <param name="AAutoMocker">The auto mock container that mocks interface return values, or nil.</param>
    /// <param name="ACallLog">The proxy's call log, needed by Before / After; nil disables them.</param>
    constructor Create(const ATypeName : string; const AMethodName : string; const ASetupParameters: TSetupMethodDataParameters;
      const AAutoMocker : IAutoMock = nil; const ACallLog : ICallLog = nil);
    /// <summary>Frees the behaviour and expectation lists.</summary>
    destructor Destroy;override;
  end;

implementation

uses
  System.TypInfo,
  Delphi.Mocks.Utils,
  Delphi.Mocks.Behavior,
  Delphi.Mocks.Expectation, Delphi.Mocks.Helpers;



{ TCallLog }

procedure TCallLog.Clear;
begin
  FSequence := 0;
  FFirstCalls.Clear;
end;

constructor TCallLog.Create;
begin
  inherited Create;
  FFirstCalls := TDictionary<string, Int64>.Create;
end;

destructor TCallLog.Destroy;
begin
  FFirstCalls.Free;
  inherited;
end;

function TCallLog.FirstCall(const AMethodName: string): Int64;
begin
  if not FFirstCalls.TryGetValue(LowerCase(AMethodName), Result) then
    Result := 0;
end;

function TCallLog.LastSequence: Int64;
begin
  Result := FSequence;
end;

function TCallLog.RecordCall(const AMethodName: string): Int64;
var
  key : string;
begin
  Inc(FSequence);
  Result := FSequence;
  key := LowerCase(AMethodName);
  if not FFirstCalls.ContainsKey(key) then
    FFirstCalls.Add(key, Result);
end;

{ TMethodData }


procedure TMethodData.ClearExpectations;
begin
  FExpectations.Clear;
end;

constructor TMethodData.Create(const ATypeName : string; const AMethodName : string; const ASetupParameters: TSetupMethodDataParameters;
  const AAutoMocker : IAutoMock; const ACallLog : ICallLog);
begin
  FTypeName := ATypeName;
  FMethodName := AMethodName;
  FBehaviors := TList<IBehavior>.Create;
  FExpectations := TList<IExpectation>.Create;
  FReturnDefault := TValue.Empty;
  FReturnDefaultDefined := False;
  FSetupParameters := ASetupParameters;
  if AAutoMocker <> nil then
    FAutoMocker := TWeakReference<IAutoMock>.Create(AAutoMocker);
  FCallLog := ACallLog;
end;

destructor TMethodData.Destroy;
begin
  FBehaviors.Free;
  FExpectations.Free;
  inherited;
end;

function TMethodData.GetAutoMocker: IAutoMock;
begin
  if FAutoMocker <> nil then
    Result := FAutoMocker.Data
  else
    Result := nil;
end;

procedure TMethodData.AddExpectation(const existing, expectation: IExpectation; const description: string);
begin
  if (existing <> nil) and (not FSetupParameters.AllowRedefineBehaviorDefinitions) then
    raise EMockException.Create(Format('[%s] already defines Expectation %s for method [%s]', [FTypeName, description, FMethodName]));

  if existing <> nil then
    FExpectations.Remove(existing);

  FExpectations.Add(expectation);
end;

procedure TMethodData.AddBehavior(const existing, behavior: IBehavior; const description: string);
begin
  if (existing <> nil) and (not FSetupParameters.AllowRedefineBehaviorDefinitions) then
    raise EMockSetupException.Create(Format('[%s] already defines %s for method [%s]', [FTypeName, description, FMethodName]));

  if existing <> nil then
    FBehaviors.Remove(existing);

  FBehaviors.Add(behavior);
end;

procedure TMethodData.Exactly(const times: Cardinal);
begin
  AddExpectation(FindExpectation([TExpectationType.Exactly]), TExpectation.CreateExactly(FMethodName,times), 'Exactly');
end;

procedure TMethodData.ExactlyWhen(const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(FindExpectationDefinition(TExpectationType.ExactlyWhen, Args, matchers),
    TExpectation.CreateExactlyWhen(FMethodName, times, Args, matchers), 'Exactly When');
end;

function TMethodData.FindBehavior(const behaviorType: TBehaviorType; const Args: TArray<TValue>): IBehavior;
var
  i : integer;
begin
  //Newest first, so a definition made later overrides an earlier one it overlaps - a specific
  //WillReturn(1).When.Foo(3) after a general WillReturn(0).When.Foo(It0.IsAny<Integer>).
  for i := FBehaviors.Count - 1 downto 0 do
  begin
    result := FBehaviors[i];
    if (result.BehaviorType = behaviorType) and result.Match(Args) then
      exit;
  end;
  result := nil;
end;

function TMethodData.FindBehavior(const behaviorType: TBehaviorType): IBehavior;
var
  behavior : IBehavior;
begin
  result := nil;
  for behavior in FBehaviors do
  begin
    if behavior.BehaviorType = behaviorType then
    begin
      result := behavior;
      exit;
    end;
  end;
end;

function TMethodData.FindBehaviorDefinition(const behaviorType: TBehaviorType; const Args: TArray<TValue>;
  const matchers: TArray<IMatcher>): IBehavior;
var
  behavior : IBehavior;
begin
  //Setup compares definitions, not calls: matching the existing behaviours against the new
  //setup's placeholder arguments made It0.IsAny<Integer> "already define" Foo(3).
  result := nil;
  for behavior in FBehaviors do
  begin
    if (behavior.BehaviorType = behaviorType) and behavior.SameDefinition(Args, matchers) then
    begin
      result := behavior;
      exit;
    end;
  end;
end;

function TMethodData.FindBestBehavior(const Args: TArray<TValue>): IBehavior;
begin
  //First see if we have an always throws;
  result := FindBehavior(TBehaviorType.WillRaiseAlways);
  if Result <> nil then
    exit;

  result := FindBehavior(TBehaviorType.WillRaise, Args);
  if Result <> nil then
    exit;

  //then find an always execute
  result := FindBehavior(TBehaviorType.WillExecute);
  if Result <> nil then
    exit;

  result := FindBehavior(TBehaviorType.WillExecuteWhen,Args);
  if Result <> nil then
    exit;

  result := FindBehavior(TBehaviorType.WillReturn,Args);
  if Result <> nil then
    exit;

  result := FindBehavior(TBehaviorType.ReturnDefault);
end;


function TMethodData.FindExpectation(const expectationType : TExpectationType; const Args: TArray<TValue>): IExpectation;
var
  expectation : IExpectation;
begin
  result := nil;
  for expectation in FExpectations do
  begin
    if expectation.ExpectationType = expectationType then
    begin
      if expectation.Match(Args) then
      begin
        result := expectation;
        exit;
      end;
    end;
  end;
end;

function TMethodData.FindExpectation(const expectationTypes : TExpectationTypes): IExpectation;
var
  expectation : IExpectation;
begin
  result := nil;
  for expectation in FExpectations do
  begin
    if expectation.ExpectationType in expectationTypes then
    begin
      result := expectation;
      exit;
    end;
  end;
end;

function TMethodData.FindExpectationDefinition(const expectationType: TExpectationType; const Args: TArray<TValue>;
  const matchers: TArray<IMatcher>): IExpectation;
var
  expectation : IExpectation;
begin
  result := nil;
  for expectation in FExpectations do
  begin
    if (expectation.ExpectationType = expectationType) and expectation.SameDefinition(Args, matchers) then
    begin
      result := expectation;
      exit;
    end;
  end;
end;

procedure TMethodData.MockNoBehaviourRecordHit(const Args: TArray<TValue>; const AExpectationHitCtr : Integer; const returnType: TRttiType; out Result: TValue);
var
  behavior : IBehavior;
  autoMocker : IAutoMock;
  mock : IProxy;
  mockedInterface : IInterface;
begin
  Result := TValue.Empty;

  //If auto mocking has been turned on and this return type is an interface, mock it.
  autoMocker := GetAutoMocker;
  if autoMocker <> nil then
  begin
    if returnType = nil then
      Exit;

    //Only interfaces can be auto mocked: a class proxy needs an instance, and records were
    //handed to TAutoMock.Mock, which always rejected them.
    if returnType.TypeKind = tkInterface then
    begin
      mock := autoMocker.Mock(returnType.Handle);
      //Return the mocked interface itself, typed as the method's return type. Returning the
      //IProxy handed the caller a proxy where it expected the interface it asked for.
      mockedInterface := mock.ProxyInterface;
      TValue.Make(@mockedInterface, returnType.Handle, Result);

      //Add a behaviour to return the same mock next time.
      behavior := TBehavior.CreateWillReturnWhen(Args, Result, TArray<IMatcher>.Create());
      FBehaviors.Add(behavior);
    end
    else
      Result := FReturnDefault;

    Exit;
  end;

  //If we have no return type defined, and the default return type is empty
  if (returnType <> nil) and (not FReturnDefaultDefined) and (not FSetupParameters.IsStub) then
    //Say we didn't have a default return value
    raise EMockException.Create(Format('[%s] has no default return value or return type was defined for method [%s]', [FTypeName, FMethodName]));

  //If we have either a return type, or a default return value then check whether behaviour must be defined.
  if FSetupParameters.BehaviorMustBeDefined and (AExpectationHitCtr = 0) and (not FReturnDefaultDefined) then
    //If we must have default behaviour defined, and there was nothing defined raise a mock exception.
    raise EMockException.Create(Format('[%s] has no behaviour or expectation defined for method [%s]', [FTypeName, FMethodName]));

  Result := FReturnDefault;
end;

procedure TMethodData.After(const AAfterMethodName: string);
begin
  AddExpectation(nil,
    TExpectation.CreateAfter(FMethodName, AAfterMethodName, FCallLog), 'After');
end;

procedure TMethodData.AfterWhen(const AAfterMethodName: string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(nil,
    TExpectation.CreateAfterWhen(FMethodName, AAfterMethodName, Args, matchers, FCallLog), 'After When');
end;

procedure TMethodData.AtLeast(const times: Cardinal);
begin
  AddExpectation(FindExpectation([TExpectationType.AtLeast,TExpectationType.AtLeastOnce]),
    TExpectation.CreateAtLeast(FMethodName,times), 'At Least');
end;

procedure TMethodData.AtLeastOnce;
begin
  AddExpectation(FindExpectation([TExpectationType.AtLeast,TExpectationType.AtLeastOnce]),
    TExpectation.CreateAtLeastOnce(FMethodName), 'At Least Once');
end;

procedure TMethodData.AtLeastOnceWhen(const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(FindExpectationDefinition(TExpectationType.AtLeastOnceWhen, Args, matchers),
    TExpectation.CreateAtLeastOnceWhen(FMethodName, Args, matchers), 'At Least Once When');
end;

procedure TMethodData.AtLeastWhen(const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(FindExpectationDefinition(TExpectationType.AtLeastWhen, Args, matchers),
    TExpectation.CreateAtLeastWhen(FMethodName, times, Args, matchers), 'At Least When');
end;

procedure TMethodData.AtMost(const times: Cardinal);
begin
  AddExpectation(FindExpectation([TExpectationType.AtMost]), TExpectation.CreateAtMost(FMethodName, times), 'At Most');
end;

procedure TMethodData.AtMostWhen(const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(FindExpectationDefinition(TExpectationType.AtMostWhen, Args, matchers),
    TExpectation.CreateAtMostWhen(FMethodName, times, Args, matchers), 'At Most When');
end;

procedure TMethodData.Before(const ABeforeMethodName: string);
begin
  AddExpectation(nil,
    TExpectation.CreateBefore(FMethodName, ABeforeMethodName, FCallLog), 'Before');
end;

procedure TMethodData.BeforeWhen(const ABeforeMethodName: string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(nil,
    TExpectation.CreateBeforeWhen(FMethodName, ABeforeMethodName, Args, matchers, FCallLog), 'Before When');
end;

procedure TMethodData.Between(const a, b: Cardinal);
begin
  if b < a then
    raise EMockSetupException.CreateFmt('[%s] Between(%d, %d) for method [%s] can never be met: the maximum is less than the minimum.',
      [FTypeName, a, b, FMethodName]);

  AddExpectation(FindExpectation([TExpectationType.Between]), TExpectation.CreateBetween(FMethodName,a,b), 'Between');
end;

procedure TMethodData.BetweenWhen(const a, b: Cardinal;const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  if b < a then
    raise EMockSetupException.CreateFmt('[%s] Between(%d, %d) for method [%s] can never be met: the maximum is less than the minimum.',
      [FTypeName, a, b, FMethodName]);

  AddExpectation(FindExpectationDefinition(TExpectationType.BetweenWhen, Args, matchers),
    TExpectation.CreateBetweenWhen(FMethodName, a, b, Args, matchers), 'Between When');
end;

procedure TMethodData.Never;
begin
  AddExpectation(FindExpectation([TExpectationType.Never]), TExpectation.CreateNever(FMethodName), 'Never');
end;

procedure TMethodData.NeverWhen(const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(FindExpectationDefinition(TExpectationType.NeverWhen, Args, matchers),
    TExpectation.CreateNeverWhen(FMethodName, Args, matchers), 'Never When');
end;

procedure TMethodData.Once;
begin
  AddExpectation(FindExpectation([TExpectationType.Once]), TExpectation.CreateOnce(FMethodName), 'Once');
end;

procedure TMethodData.OnceWhen(const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddExpectation(FindExpectationDefinition(TExpectationType.OnceWhen, Args, matchers),
    TExpectation.CreateOnceWhen(FMethodName, Args, matchers), 'Once When');
end;


procedure TMethodData.RecordHit(const Args: TArray<TValue>; const returnType : TRttiType; const method : TRttiMethod; out Result: TValue);
var
  behavior : IBehavior;
  expectation : IExpectation;
  expectationHitCtr: integer;
  returnValue : TValue;
begin
  //Log the call before counting it, so the ordering expectations can read its sequence number.
  if FCallLog <> nil then
    FCallLog.RecordCall(FMethodName);

  expectationHitCtr := 0;
  for expectation in FExpectations do
  begin
    if expectation.Match(Args) then
    begin
      expectation.RecordHit;
      inc(expectationHitCtr);
    end;
  end;

  returnValue := TValue.Empty;
  behavior := FindBestBehavior(Args);
  if behavior <> nil then
    returnValue := behavior.Execute(Args, returnType)
  else if FSetupParameters.IsStub or (method = nil) or method.IsAbstract or (not method.IsVirtual) then
    MockNoBehaviourRecordHit(Args, expectationHitCtr, returnType, returnValue);

  if returnType <> nil then
    Result := returnValue;
end;

procedure TMethodData.ResetCalls;
var
  expectation : IExpectation;
begin
  for expectation in FExpectations do
  begin
    expectation.ResetCalls;
  end;
end;


function TMethodData.Verify(var report : string) : boolean;
var
  expectation : IExpectation;
begin
  result := true;
  report := '';
  for expectation in FExpectations do
  begin
    if not expectation.ExpectationMet then
    begin
      result := False;
      if report <> '' then
        report := report + #13#10 + '    '
      else
        report :=  '    ';
      report := report +  expectation.Report;
    end;
  end;
  if not result then
    report := '  Method : ' + FMethodName + #13#10 +  report;
end;

//Behaviors

procedure TMethodData.WillExecute(const func: TExecuteFunc);
begin
  AddBehavior(FindBehavior(TBehaviorType.WillExecute), TBehavior.CreateWillExecute(func), 'WillExecute');
end;

procedure TMethodData.WillExecuteWhen(const func: TExecuteFunc;const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddBehavior(FindBehaviorDefinition(TBehaviorType.WillExecuteWhen, Args, matchers),
    TBehavior.CreateWillExecuteWhen(Args, func, matchers), 'WillExecute When');
end;

procedure TMethodData.WillRaiseAlways(const exceptionClass: ExceptClass; const message : string);
begin
  AddBehavior(FindBehavior(TBehaviorType.WillRaiseAlways), TBehavior.CreateWillRaise(exceptionClass, message), 'Will Raise Always');
end;

procedure TMethodData.WillRaiseWhen(const exceptionClass: ExceptClass; const message : string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  AddBehavior(FindBehaviorDefinition(TBehaviorType.WillRaise, Args, matchers),
    TBehavior.CreateWillRaiseWhen(Args,exceptionClass, message, matchers), 'Will Raise When');
end;

procedure TMethodData.WillReturnDefault(const returnValue: TValue);
begin
  if FReturnDefaultDefined and (not FSetupParameters.AllowRedefineBehaviorDefinitions) then
    raise EMockSetupException.Create(Format('[%s] already defines Will Return Default for method [%s]', [FTypeName, FMethodName]));

  FReturnDefault := returnValue;
  FReturnDefaultDefined := True;

  //A behaviour as well as the stored value: on a class mock, only a behaviour stops the real
  //virtual method running, so without it the default was silently ignored there.
  AddBehavior(FindBehavior(TBehaviorType.ReturnDefault), TBehavior.CreateReturnDefault(returnValue), 'Will Return Default');
end;

procedure TMethodData.WillReturnWhen(const Args: TArray<TValue>; const returnValue: TValue; const matchers : TArray<IMatcher>);
begin
  AddBehavior(FindBehaviorDefinition(TBehaviorType.WillReturn, Args, matchers),
    TBehavior.CreateWillReturnWhen(Args, returnValue, matchers), 'Will Return When');
end;

{ TSetupMethodDataParameters }
class function TSetupMethodDataParameters.Create(const AIsStub: boolean; const ABehaviorMustBeDefined, AAllowRedefineBehaviorDefinitions: boolean):
  TSetupMethodDataParameters;
begin
  result.IsStub := AIsStub;
  result.BehaviorMustBeDefined := ABehaviorMustBeDefined;
  result.AllowRedefineBehaviorDefinitions := AAllowRedefineBehaviorDefinitions;
end;

end.
