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

unit Delphi.Mocks.Interfaces;

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  Delphi.Mocks,
  Delphi.Mocks.ParamMatcher;

type
  /// <summary>The kinds of behaviour a mocked method can be given.</summary>
  TBehaviorType = (WillReturn,ReturnDefault,WillRaise,WillRaiseAlways,WillExecute,WillExecuteWhen);

  /// <summary>One behaviour defined for a mocked method.</summary>
  IBehavior = interface
  ['{9F6FE14D-4522-48EE-B564-20E2BECF7992}']
    /// <summary>Returns the kind of behaviour.</summary>
    /// <returns>The behaviour type.</returns>
    function GetBehaviorType : TBehaviorType;
    /// <summary>Decides whether the behaviour applies to a call.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>True when the behaviour applies.</returns>
    function Match(const Args: TArray<TValue>) : boolean;
    /// <summary>Decides whether a new setup describes this same behaviour.</summary>
    /// <param name="Args">The new setup's arguments; Args[0] is Self.</param>
    /// <param name="matchers">The new setup's matchers.</param>
    /// <returns>True when the new setup redefines this behaviour.</returns>
    function SameDefinition(const Args: TArray<TValue>; const matchers: TArray<IMatcher>) : boolean;
    /// <summary>Performs the behaviour.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <param name="returnType">The method's return type, or nil for a procedure.</param>
    /// <returns>The value to return from the call.</returns>
    /// <exception cref="Exception">The configured exception, for a raising behaviour.</exception>
    function Execute(const Args: TArray<TValue>;  const returnType : TRttiType) : TValue;
    /// <summary>The kind of behaviour.</summary>
    property BehaviorType : TBehaviorType read GetBehaviorType;
  end;

  /// <summary>The kinds of expectation a mocked method can be given.</summary>
  TExpectationType = (Once,           //Called once only
                      OnceWhen,       //Called once only with specified params
                      Never,          //Never called
                      NeverWhen,      //Never called with specified params
                      AtLeastOnce,    //1 or more times
                      AtLeastOnceWhen,//1 or more times with specified params
                      AtLeast,       //x or more times
                      AtLeastWhen,   //x or more times with specified params
                      AtMostOnce,     //0 or 1 times
                      AtMostOnceWhen, //0 or 1 times with specified params
                      AtMost,        //0 to X times
                      AtMostWhen,    //0 to X times with specified params
                      Between,        //Between X & Y Inclusive times
                      BetweenWhen,    //Between X & Y Inclusive times with specified params
                      Exactly,        //Exactly X times
                      ExactlyWhen,    //Exactly X times with specified params
                      Before,         //Must be called before Method X is called
                      BeforeWhen,     //Must be called before Method x is called with specified params
                      After,          //Must be called after Method X is called
                      AfterWhen);     //Must be called after Method x is called with specified params
  /// <summary>A set of expectation kinds.</summary>
  TExpectationTypes = set of TExpectationType;

  /// <summary>The order in which a proxy's methods were first called, which the ordering expectations
  /// (Before, After) are verified against. One log is shared by every method of a proxy.</summary>
  ICallLog = interface
  ['{4B0E5D1C-2C7A-4E37-9F58-0D6A1B7C3E21}']
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
  end;

  /// <summary>One expectation defined for a mocked method.</summary>
  IExpectation = interface
  ['{960B95B2-581D-4C18-A320-7E19190F29EF}']
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
    /// <returns>True when the new setup redefines this expectation.</returns>
    function SameDefinition(const Args: TArray<TValue>; const matchers: TArray<IMatcher>) : boolean;
    /// <summary>Counts a matching call.</summary>
    procedure RecordHit;
    /// <summary>Forgets every counted call.</summary>
    procedure ResetCalls;
    /// <summary>Describes the unmet expectation.</summary>
    /// <returns>The description, or an empty string when the expectation is met.</returns>
    function Report : string;
    /// <summary>The kind of expectation.</summary>
    property ExpectationType : TExpectationType read GetExpectationType;
    /// <summary>Whether the expectation is currently met.</summary>
    property ExpectationMet : boolean read GetExpectationMet;
  end;

  /// <summary>Everything recorded for one method of a mock: its behaviours, its expectations and its calls.
  /// </summary>
  IMethodData = interface
  ['{640BFB71-85C2-4ED4-A863-5AF6535BD2E8}']
    /// <summary>Records a call to the method and produces its result.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <param name="returnType">The method's return type, or nil for a procedure.</param>
    /// <param name="method">The method's RTTI, or nil when unknown.</param>
    /// <param name="Result">The value to return from the call.</param>
    /// <exception cref="EMockException">No behaviour, default or automock supplies a required return value, or
    /// BehaviorMustBeDefined is set and nothing was defined.</exception>
    procedure RecordHit(const Args: TArray<TValue>; const returnType : TRttiType; const method : TRttiMethod; out Result: TValue);

    //behaviors
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
    procedure WillRaiseWhen(const exceptionClass : ExceptClass; const message : string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
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

    //expectations
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
    /// <summary>Expects a call with matching arguments, first made before the first call of another method.
    /// </summary>
    /// <param name="ABeforeMethodName">The method this one must precede.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure BeforeWhen(const ABeforeMethodName : string ; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects this method to be first called before the first call of another method.</summary>
    /// <param name="ABeforeMethodName">The method this one must precede.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure Before(const ABeforeMethodName : string);
    /// <summary>Expects a call with matching arguments, first made after the first call of another method.
    /// </summary>
    /// <param name="AAfterMethodName">The method this one must follow.</param>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure AfterWhen(const AAfterMethodName : string;const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    /// <summary>Expects this method to be first called after the first call of another method.</summary>
    /// <param name="AAfterMethodName">The method this one must follow.</param>
    /// <exception cref="EMockException">The same expectation is already defined.</exception>
    procedure After(const AAfterMethodName : string);
    /// <summary>Removes every expectation.</summary>
    procedure ClearExpectations;

    //Verification
    /// <summary>Checks every expectation.</summary>
    /// <param name="report">Receives a description of the unmet expectations, or an empty string.</param>
    /// <returns>True when every expectation is met.</returns>
    function Verify(var report : string) : boolean;
    /// <summary>Forgets every counted call.</summary>
    procedure ResetCalls;

    /// <summary>Finds the behaviour that applies to a call.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>The behaviour, or nil when none applies.</returns>
    function FindBestBehavior(const Args: TArray<TValue>) : IBehavior;
  end;

  /// <summary>Verification of a proxy's expectations.</summary>
  IVerify = interface
  ['{58C05610-4BDA-451E-9D61-17C6376C3B3F}']
    /// <summary>Checks this proxy's expectations.</summary>
    /// <param name="message">Text placed before the detail of a failure.</param>
    /// <exception cref="EMockVerificationException">An expectation is not met.</exception>
    procedure Verify(const message : string = '');
    /// <summary>Checks this proxy's expectations and those of every interface it implements.</summary>
    /// <param name="message">Text placed before the detail of a failure.</param>
    /// <exception cref="EMockVerificationException">An expectation is not met.</exception>
    procedure VerifyAll(const message : string = '');
    /// <summary>Describes every unmet expectation of this proxy.</summary>
    /// <returns>The description, or an empty string when every expectation is met.</returns>
    function CheckExpectations: string;
    /// <summary>Forgets every counted call, here and in every interface the proxy implements.</summary>
    procedure ResetCalls;
    /// <summary>Removes every expectation, here and in every interface the proxy implements.</summary>
    procedure ClearExpectations;
  end;

implementation

end.
