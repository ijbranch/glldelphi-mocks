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

unit Delphi.Mocks.Expectation;

interface


uses
  System.Rtti,
  Delphi.Mocks,
  Delphi.Mocks.ParamMatcher,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.Utils;

// TExpectation deliberately declares name-only overloaded constructors. C++ constructors
// are unnamed, so they collide there, but they are valid in Delphi. The directive must sit
// in this unit: {$WARN} in a consuming .dpr does not affect how this unit is compiled.
{$WARN DUPLICATE_CTOR_DTOR OFF}

type
  /// <summary>One expectation defined for a mocked method: how often it is called, optionally with particular
  /// arguments, or in what order relative to another method.</summary>
  TExpectation = class(TInterfacedObject,IExpectation)
  private
    /// <summary>What kind of expectation this is.</summary>
    FExpectationType        : TExpectationType;
    /// <summary>The arguments the expectation was defined with, excluding Self.</summary>
    FArgs                   : TArray<TValue>;
    /// <summary>Whether a counting expectation is currently met; ordering expectations are evaluated on demand.
    /// </summary>
    FExpectationMet         : boolean;
    /// <summary>For Before / After, the method this one must precede or follow.</summary>
    FBeforeAfterMethodName  : string;
    /// <summary>For Between, the inclusive minimum and maximum.</summary>
    FBetween                : array[0..1] of Cardinal;
    /// <summary>For AtLeast / AtMost / Exactly, the number of calls.</summary>
    FTimes                  : Cardinal;
    /// <summary>How many matching calls have been counted.</summary>
    FHitCount               : Cardinal;
    /// <summary>The name of the method the expectation belongs to.</summary>
    FMethodName             : string;
    /// <summary>Parameter matchers, one per argument; empty when the expectation matches literal arguments.</summary>
    FMatchers               : TArray<IMatcher>;
    /// <summary>The proxy's call log, which Before / After are verified against; nil for counting expectations.
    /// </summary>
    FCallLog                : ICallLog;
    /// <summary>The sequence number of the first matching call, or 0 before one is made.</summary>
    FFirstHitSequence       : Int64;
    /// <summary>Decides whether an ordering expectation is met, from the call log.</summary>
    /// <returns>True when this method's first matching call came before (Before) or after (After) the first call
    /// of the other method.</returns>
    function OrderingMet : boolean;
    /// <summary>Describes where the calls of an ordering expectation actually fell.</summary>
    /// <returns>Text such as " - first call #3, Commit first called #2".</returns>
    function OrderingReport : string;
    /// <summary>Compares the call's arguments with the stored literal arguments.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>True when every argument equals the stored one.</returns>
    function MatchArgs(const Args : TArray<TValue>) : boolean;
    /// <summary>Runs every matcher against its argument.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>True when every matcher accepts its argument.</returns>
    function MatchWithMatchers(const Args : TArray<TValue>) : boolean;
  protected
    /// <summary>Returns the kind of expectation.</summary>
    /// <returns>The expectation type.</returns>
    function GetExpectationType : TExpectationType;
    /// <summary>Returns whether the expectation is currently met.</summary>
    /// <returns>True when met.</returns>
    function GetExpectationMet : boolean;
    /// <summary>Decides whether a call counts towards this expectation.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>True when the call counts.</returns>
    function Match(const Args : TArray<TValue>) : boolean;
    /// <summary>Decides whether a new setup describes this same expectation.</summary>
    /// <param name="Args">The new setup's arguments; Args[0] is Self.</param>
    /// <param name="matchers">The new setup's matchers.</param>
    /// <returns>True when neither side uses matchers and the literal arguments are equal. Matchers cannot be
    /// compared, so a setup that uses them is never a redefinition.</returns>
    function SameDefinition(const Args: TArray<TValue>; const matchers: TArray<IMatcher>) : boolean;
    /// <summary>Counts a matching call.</summary>
    procedure RecordHit;
    /// <summary>Recomputes whether a counting expectation is met.</summary>
    procedure CheckExpectationMet;
    /// <summary>Describes the unmet expectation.</summary>
    /// <returns>The description, or an empty string when the expectation is met.</returns>
    function Report : string;
    /// <summary>Formats the expectation's arguments for a report.</summary>
    /// <returns>The arguments, or one "&lt;matcher&gt;" per argument when matchers were used.</returns>
    function ArgsToString : string;
    /// <summary>Copies the arguments, skipping Args[0] (Self).</summary>
    /// <param name="Args">The setup call's arguments.</param>
    procedure CopyArgs(const Args: TArray<TValue>);
    /// <summary>Forgets every counted call.</summary>
    procedure ResetCalls;
    /// <summary>Initialises an expectation that ignores arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    constructor Create(const AMethodName : string);
    /// <summary>Initialises an expectation that applies to particular arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateWhen(const AMethodName : string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
  public
    /// <summary>Creates an expectation of exactly one call with matching arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateOnceWhen(const AMethodName : string; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Creates an expectation of exactly one call.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    constructor CreateOnce(const AMethodName : string);

    /// <summary>Creates an expectation of no call with matching arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateNeverWhen(const AMethodName : string; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Creates an expectation of no call.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    constructor CreateNever(const AMethodName : string);

    /// <summary>Creates an expectation of one or more calls with matching arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateAtLeastOnceWhen(const AMethodName : string; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Creates an expectation of one or more calls.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    constructor CreateAtLeastOnce(const AMethodName : string);

    /// <summary>Creates an expectation of a minimum number of calls with matching arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="times">The minimum.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateAtLeastWhen(const AMethodName : string; const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Creates an expectation of a minimum number of calls.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="times">The minimum.</param>
    constructor CreateAtLeast(const AMethodName : string; const times : Cardinal);

    /// <summary>Creates an expectation of a maximum number of calls with matching arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="times">The maximum.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateAtMostWhen(const AMethodName : string; const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Creates an expectation of a maximum number of calls.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="times">The maximum.</param>
    constructor CreateAtMost(const AMethodName : string; const times : Cardinal);

    /// <summary>Creates an expectation of an inclusive range of calls with matching arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateBetweenWhen(const AMethodName : string; const a,b : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Creates an expectation of an inclusive range of calls.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="a">The minimum.</param>
    /// <param name="b">The maximum.</param>
    constructor CreateBetween(const AMethodName : string; const a,b : Cardinal);

    /// <summary>Creates an expectation of an exact number of calls with matching arguments.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="times">The number of calls.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateExactlyWhen(const AMethodName : string; const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Creates an expectation of an exact number of calls.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="times">The number of calls.</param>
    constructor CreateExactly(const AMethodName : string; const times : Cardinal);

    /// <summary>Creates an expectation that a matching call is first made before the first call of another
    /// method.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="ABeforeMethodName">The method this one must precede.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <param name="ACallLog">The proxy's call log; without one the expectation can never be met.</param>
    constructor CreateBeforeWhen(const AMethodName : string; const ABeforeMethodName : string ; const Args : TArray<TValue>;
      const matchers : TArray<IMatcher>; const ACallLog : ICallLog = nil);
    /// <summary>Creates an expectation that the method is first called before the first call of another method.
    /// </summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="ABeforeMethodName">The method this one must precede.</param>
    /// <param name="ACallLog">The proxy's call log; without one the expectation can never be met.</param>
    constructor CreateBefore(const AMethodName : string; const ABeforeMethodName : string; const ACallLog : ICallLog = nil);

    /// <summary>Creates an expectation that a matching call is first made after the first call of another
    /// method.</summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="AAfterMethodName">The method this one must follow.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <param name="ACallLog">The proxy's call log; without one the expectation can never be met.</param>
    constructor CreateAfterWhen(const AMethodName : string; const AAfterMethodName : string;const Args : TArray<TValue>;
      const matchers : TArray<IMatcher>; const ACallLog : ICallLog = nil);
    /// <summary>Creates an expectation that the method is first called after the first call of another method.
    /// </summary>
    /// <param name="AMethodName">The method the expectation belongs to.</param>
    /// <param name="AAfterMethodName">The method this one must follow.</param>
    /// <param name="ACallLog">The proxy's call log; without one the expectation can never be met.</param>
    constructor CreateAfter(const AMethodName : string; const AAfterMethodName : string; const ACallLog : ICallLog = nil);

    /// <summary>Computes the initial met state once the constructor has set the expectation up.</summary>
    procedure AfterConstruction; override;
  end;


implementation

uses
  System.SysUtils,
  Delphi.Mocks.Helpers;

const
  /// <summary>The expectation kinds verified against the call order rather than a call count.</summary>
  ORDERING_EXPECTATIONS = [TExpectationType.Before, TExpectationType.BeforeWhen,
                           TExpectationType.After, TExpectationType.AfterWhen];

{ TExpectation }

procedure TExpectation.AfterConstruction;
begin
  inherited;
  CheckExpectationMet;
end;

function TExpectation.ArgsToString: string;
var
  i : integer;
begin
  if Length(FMatchers) = 0 then
    Exit(Delphi.Mocks.Utils.ArgsToString(FArgs));

  //The stored arguments are only placeholders (Default(T)) when matchers were used; printing
  //them made a report claim the expectation was about values it never tested.
  result := '';
  for i := 0 to High(FMatchers) do
  begin
    if result <> '' then
      result := result + ', ';
    result := result + '<matcher>';
  end;
  result := '( ' + result + ' )';
end;

procedure TExpectation.CopyArgs(const Args: TArray<TValue>);
var
  l : integer;
begin
  l := Length(Args) -1;
  if l > 0  then
  begin
    SetLength(FArgs,l);
    CopyArray(@FArgs[0],@args[1],TypeInfo(TValue),l);
  end;
end;

constructor TExpectation.Create(const AMethodName : string);
begin
  SetLength(FMatchers, 0);

  FExpectationMet := False;
  FHitCount := 0;
  FMethodName := AMethodName;
end;

constructor TExpectation.CreateWhen(const AMethodName: string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  FExpectationMet := False;
  FHitCount := 0;
  FMethodName := AMethodName;
  CopyArgs(Args);
  FMatchers := matchers;
end;

constructor TExpectation.CreateAfter(const AMethodName : string; const AAfterMethodName: string; const ACallLog : ICallLog);
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.After;
  FBeforeAfterMethodName := AAfterMethodName;
  FCallLog := ACallLog;
end;

constructor TExpectation.CreateAfterWhen(const AMethodName : string; const AAfterMethodName: string;  const Args: TArray<TValue>;
  const matchers : TArray<IMatcher>; const ACallLog : ICallLog);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.AfterWhen;
  FBeforeAfterMethodName := AAfterMethodName;
  FCallLog := ACallLog;
end;

constructor TExpectation.CreateAtLeast(const AMethodName : string; const times: Cardinal);
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.AtLeast;
  FTimes := times;
end;

constructor TExpectation.CreateAtLeastOnce(const AMethodName : string);
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.AtLeastOnce;
  FTimes := 1;
end;

constructor TExpectation.CreateAtLeastOnceWhen(const AMethodName : string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.AtLeastOnceWhen;
  FTimes := 1;
end;

constructor TExpectation.CreateAtLeastWhen(const AMethodName : string; const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.AtLeastWhen;
  FTimes := times;
end;

constructor TExpectation.CreateAtMost(const AMethodName : string; const times: Cardinal);
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.AtMost;
  FTimes := times;
end;

constructor TExpectation.CreateAtMostWhen(const AMethodName : string; const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.AtMostWhen;
  FTimes := times;
end;

constructor TExpectation.CreateBefore(const AMethodName : string; const ABeforeMethodName: string; const ACallLog : ICallLog);
begin
  Create(AMethodName);
  FExpectationType  := TExpectationType.Before;
  FBeforeAfterMethodName  := ABeforeMethodName;
  FCallLog := ACallLog;
end;

constructor TExpectation.CreateBeforeWhen(const AMethodName : string; const ABeforeMethodName: string; const Args: TArray<TValue>;
  const matchers : TArray<IMatcher>; const ACallLog : ICallLog);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.BeforeWhen;
  FBeforeAfterMethodName := ABeforeMethodName;
  FCallLog := ACallLog;
end;

constructor TExpectation.CreateBetween(const AMethodName : string; const a, b: Cardinal);
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.Between;
  FBetween[0] := a;
  FBetween[1] := b;
end;

constructor TExpectation.CreateBetweenWhen(const AMethodName : string; const a, b: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.BetweenWhen;
  FBetween[0] := a;
  FBetween[1] := b;
end;

constructor TExpectation.CreateExactly(const AMethodName : string; const times: Cardinal);
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.Exactly;
  FTimes := times;
end;

constructor TExpectation.CreateExactlyWhen(const AMethodName : string; const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.ExactlyWhen;
  FTimes := times;
end;

constructor TExpectation.CreateNever(const AMethodName : string) ;
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.Never;
end;

constructor TExpectation.CreateNeverWhen(const AMethodName : string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.NeverWhen;
end;

constructor TExpectation.CreateOnce(const AMethodName : string );
begin
  Create(AMethodName);
  FExpectationType := TExpectationType.Once;
  FTimes := 1;
end;

constructor TExpectation.CreateOnceWhen(const AMethodName : string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  CreateWhen(AMethodName, Args, matchers);
  FExpectationType := TExpectationType.OnceWhen;
  FTimes := 1;
end;

function TExpectation.GetExpectationMet: boolean;
begin
  //An ordering expectation depends on calls to another method, which can happen after the last
  //hit on this one, so it is decided when asked rather than when a hit is recorded.
  if FExpectationType in ORDERING_EXPECTATIONS then
    result := OrderingMet
  else
    result := FExpectationMet;
end;

function TExpectation.GetExpectationType: TExpectationType;
begin
  result := FExpectationType;
end;

function TExpectation.MatchArgs(const Args: TArray<TValue>): boolean;
var
  i : integer;
begin
  result := False;
  if Length(Args) <> (Length(FArgs) + 1 ) then
    exit;
  //start at 1 as we don't care about matching the first arg (self)
  for i := 1 to Length(args) -1 do
  begin
    if not FArgs[i -1].Equals(args[i]) then
      exit;
  end;
  result := True;
end;

function TExpectation.MatchWithMatchers(const Args: TArray<TValue>): boolean;
var
  i : integer;
begin
  result := False;
  //One matcher per argument, Self excluded; anything else cannot be matched safely.
  if Length(Args) <> (Length(FMatchers) + 1) then
    exit;
  for i := 0 to High(FMatchers) do
  begin
    if (FMatchers[i] = nil) or (not FMatchers[i].Match(Args[i+1])) then
      exit;
  end;
  result := True;
end;

function TExpectation.Match(const Args: TArray<TValue>): boolean;
begin
  result := False;
  case FExpectationType of
    Once,
    Never,
    AtLeastOnce,
    AtLeast,
    AtMostOnce,
    AtMost,
    Between,
    Exactly,
    Before,
    After: result := True ;

    OnceWhen,
    NeverWhen,
    AtLeastOnceWhen,
    AtLeastWhen,
    AtMostOnceWhen,
    AtMostWhen,
    BetweenWhen,
    ExactlyWhen,
    BeforeWhen,
    AfterWhen:
    begin
      if Length(FMatchers) > 0 then
        result := MatchWithMatchers(Args)
      else
        result := MatchArgs(Args);
    end;
  end;
end;

function TExpectation.SameDefinition(const Args: TArray<TValue>; const matchers: TArray<IMatcher>): boolean;
begin
  if (Length(FMatchers) > 0) or (Length(matchers) > 0) then
    Exit(False);

  case FExpectationType of
    OnceWhen,
    NeverWhen,
    AtLeastOnceWhen,
    AtLeastWhen,
    AtMostOnceWhen,
    AtMostWhen,
    BetweenWhen,
    ExactlyWhen,
    BeforeWhen,
    AfterWhen: result := MatchArgs(Args);
  else
    result := True;
  end;
end;

function TExpectation.OrderingMet: boolean;
var
  otherFirstCall : Int64;
begin
  result := False;
  if (FCallLog = nil) or (FFirstHitSequence = 0) then
    exit;

  otherFirstCall := FCallLog.FirstCall(FBeforeAfterMethodName);
  if otherFirstCall = 0 then
    exit;

  case FExpectationType of
    Before, BeforeWhen : result := FFirstHitSequence < otherFirstCall;
    After, AfterWhen   : result := FFirstHitSequence > otherFirstCall;
  end;
end;

function TExpectation.OrderingReport: string;
var
  otherFirstCall : Int64;
begin
  if FCallLog = nil then
    Exit(' - no call log to verify the order against');

  if FFirstHitSequence = 0 then
    result := ' - was never called'
  else
    result := ' - first call #' + IntToStr(FFirstHitSequence);

  otherFirstCall := FCallLog.FirstCall(FBeforeAfterMethodName);
  if otherFirstCall = 0 then
    result := result + ', ' + FBeforeAfterMethodName + ' was never called'
  else
    result := result + ', ' + FBeforeAfterMethodName + ' first called #' + IntToStr(otherFirstCall);
end;

procedure TExpectation.RecordHit;
begin
  Inc(FHitCount);
  //The method data records the call in the log before it counts hits, so the log's last
  //sequence number is this call's.
  if (FFirstHitSequence = 0) and (FCallLog <> nil) then
    FFirstHitSequence := FCallLog.LastSequence;
  CheckExpectationMet;
end;

procedure TExpectation.CheckExpectationMet;
begin
  case FExpectationType of
    Once,
    OnceWhen: FExpectationMet := FHitCount = 1;
    Never,
    NeverWhen: FExpectationMet := FHitCount = 0;
    AtLeastOnce,
    AtLeastOnceWhen: FExpectationMet := FHitCount >= 1;
    AtLeast,
    AtLeastWhen: FExpectationMet := FHitCount >= FTimes;
    AtMostOnce,
    AtMostOnceWhen: FExpectationMet := FHitCount <= 1;
    AtMost,
    AtMostWhen: FExpectationMet := FHitCount <= FTimes;
    Between,
    BetweenWhen: FExpectationMet := (FHitCount >= FBetween[0]) and (FHitCount <= FBetween[1]);
    Exactly,
    ExactlyWhen: FExpectationMet := FHitCount = FTimes;

    //Ordering expectations are decided by GetExpectationMet from the call log.
    Before,
    BeforeWhen,
    After,
    AfterWhen: FExpectationMet := False;
  end;

end;

function TExpectation.Report: string;
begin
  result := '';
  if not GetExpectationMet then
  begin
     case FExpectationType of
       Once: result := 'Once - Was ' + IntToStr(FHitCount);
       Never: result := 'Never - Was ' + IntToStr(FHitCount);
       AtLeastOnce: result := 'At Least Once - Was ' + IntToStr(FHitCount);
       AtLeast: result := 'At Least ' + IntToStr(FTimes) + ' Times - Was ' + IntToStr(FHitCount);
       AtMost: result := 'At Most ' + IntToStr(FTimes) + ' Times - Was ' + IntToStr(FHitCount);
       AtMostOnce: result := 'At Most Once - Was ' + IntToStr(FHitCount);
       Between: result := 'Between ' + IntToStr(FBetween[0]) + ' and ' + IntToStr(FBetween[1]) + ' Times - Was ' + IntToStr(FHitCount);
       Exactly: result := 'Exactly ' + IntToStr(FTimes) + ' Times - Was ' + IntToStr(FHitCount);
       Before: result := 'Before Method : ' + FBeforeAfterMethodName + OrderingReport;
       After: result := 'After Method : ' + FBeforeAfterMethodName + OrderingReport;

       OnceWhen: result := 'Once When' + ArgsToString + ' - Was ' + IntToStr(FHitCount);
       NeverWhen: result := 'Never When' + ArgsToString + ' - Was ' + IntToStr(FHitCount);
       AtLeastOnceWhen: result := 'At Least Once When' + ArgsToString + ' - Was ' + IntToStr(FHitCount);
       AtLeastWhen: result := 'At Least ' + IntToStr(FTimes) + ' Times When ' + ArgsToString + ' - Was ' + IntToStr(FHitCount);
       AtMostOnceWhen: result := 'At Most Once When' + ArgsToString + ' - Was ' + IntToStr(FHitCount);
       AtMostWhen: result := 'At Most ' + IntToStr(FTimes) + ' Times When ' + ArgsToString + ' - Was ' + IntToStr(FHitCount);
       BetweenWhen: result := 'Between ' + IntToStr(FBetween[0]) + ' and ' + IntToStr(FBetween[1]) + ' Times When' + ArgsToString
         + ' - Was ' + IntToStr(FHitCount);
       ExactlyWhen: result := 'Exactly ' + IntToStr(FTimes) + ' Times When' + ArgsToString + ' - Was ' + IntToStr(FHitCount);
       BeforeWhen: result := 'Before Method : ' + FBeforeAfterMethodName + ' When ' + ArgsToString + OrderingReport;
       AfterWhen: result := 'After Method : ' + FBeforeAfterMethodName + ' When ' + ArgsToString + OrderingReport;
     end;
    result := 'Expectation [ ' + result + ' ] was not met.';
  end;

end;

procedure TExpectation.ResetCalls;
begin
  FHitCount := 0;
  FFirstHitSequence := 0;
  CheckExpectationMet;
end;

end.
