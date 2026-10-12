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

unit Delphi.Mocks.Behavior;

interface

uses
  System.Rtti,
  System.SysUtils,
  Delphi.Mocks,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.ParamMatcher;

type
  /// <summary>One behaviour defined for a mocked method: return a value, raise, or execute a function, optionally
  /// only for particular arguments.</summary>
  TBehavior = class(TInterfacedObject,IBehavior)
  private
    /// <summary>The function a WillExecute / WillExecuteWhen behaviour runs.</summary>
    FAction : TExecuteFunc;
    /// <summary>The exception class a WillRaise / WillRaiseAlways behaviour raises; nil raises nothing.</summary>
    FExceptClass : ExceptClass;
    /// <summary>The message given to the raised exception; empty means a generic message.</summary>
    FExceptionMessage : string;
    /// <summary>The value a WillReturn / ReturnDefault behaviour returns.</summary>
    FReturnValue : TValue;
    /// <summary>The arguments the behaviour was defined with, excluding Self.</summary>
    FArgs : TArray<TValue>;
    /// <summary>What kind of behaviour this is.</summary>
    FBehaviorType : TBehaviorType;
    /// <summary>Parameter matchers, one per argument; empty when the behaviour matches literal arguments.</summary>
    FMatchers : TArray<IMatcher>;
    /// <summary>Compares the call's arguments with the stored literal arguments.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>True when every argument equals the stored one.</returns>
    function MatchArgs(const Args: TArray<TValue>): Boolean;
    /// <summary>Runs every matcher against its argument.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>True when every matcher accepts its argument.</returns>
    function MatchWithMatchers(const Args: TArray<TValue>): Boolean;
  protected
    /// <summary>Returns the kind of behaviour.</summary>
    /// <returns>The behaviour type.</returns>
    function GetBehaviorType: TBehaviorType;
    /// <summary>Decides whether this behaviour applies to a call. Never raises: raising is Execute's job.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <returns>True when the behaviour applies to these arguments.</returns>
    function Match(const Args: TArray<TValue>): Boolean;
    /// <summary>Decides whether a new setup describes this same behaviour, so it is a redefinition.</summary>
    /// <param name="Args">The new setup's arguments; Args[0] is Self.</param>
    /// <param name="matchers">The new setup's matchers.</param>
    /// <returns>True when neither side uses matchers and the literal arguments are equal. Matchers cannot be
    /// compared, so a setup that uses them is never a redefinition.</returns>
    function SameDefinition(const Args: TArray<TValue>; const matchers: TArray<IMatcher>): Boolean;
    /// <summary>Performs the behaviour.</summary>
    /// <param name="Args">The call's arguments; Args[0] is Self.</param>
    /// <param name="returnType">The method's return type, or nil for a procedure.</param>
    /// <returns>The value to return from the mocked call.</returns>
    /// <exception cref="Exception">The configured exception class, for a WillRaise / WillRaiseAlways behaviour.
    /// </exception>
    function Execute(const Args: TArray<TValue>; const returnType: TRttiType): TValue;
    /// <summary>Copies the arguments, skipping Args[0] (Self), so no reference to the proxy is kept.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    procedure CopyArgs(const Args: TArray<TValue>);
  public
    //disable warnings about c++ compatibility, since we don't intend to support it.
    {$WARN DUPLICATE_CTOR_DTOR OFF}
    /// <summary>Creates a behaviour that always runs a function.</summary>
    /// <param name="AAction">The function to run.</param>
    constructor CreateWillExecute(const AAction: TExecuteFunc);
    /// <summary>Creates a behaviour that runs a function for matching arguments.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="AAction">The function to run.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateWillExecuteWhen(const Args: TArray<TValue>; const AAction: TExecuteFunc; const matchers : TArray<IMatcher>);
    /// <summary>Creates a behaviour that returns a value for matching arguments.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="ReturnValue">The value to return.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateWillReturnWhen(const Args: TArray<TValue>; const ReturnValue: TValue; const matchers : TArray<IMatcher>);
    /// <summary>Creates the behaviour that returns the method's default value whatever the arguments.</summary>
    /// <param name="ReturnValue">The default value.</param>
    constructor CreateReturnDefault(const ReturnValue: TValue);
    /// <summary>Creates a behaviour that always raises.</summary>
    /// <param name="AExceptClass">The exception class to raise.</param>
    /// <param name="message">The exception message; empty for a generic one.</param>
    constructor CreateWillRaise(const AExceptClass : ExceptClass; const message : string);
    /// <summary>Creates a behaviour that raises for matching arguments.</summary>
    /// <param name="Args">The setup call's arguments.</param>
    /// <param name="AExceptClass">The exception class to raise.</param>
    /// <param name="message">The exception message; empty for a generic one.</param>
    /// <param name="matchers">The parameter matchers, or empty for literal matching.</param>
    constructor CreateWillRaiseWhen(const Args: TArray<TValue>; const AExceptClass : ExceptClass; const message : string; const matchers : TArray<IMatcher>);
  end;

implementation

uses
  Delphi.Mocks.Helpers;

{ TBehavior }

procedure TBehavior.CopyArgs(const Args: TArray<TValue>);
var
  l : integer;
begin
  //Note : Args[0] is the Self Ptr for the proxy, we do not want to keep
  //a reference to it so it is ignored here.
  l := Length(Args) -1;
  if l > 0  then
  begin
    SetLength(FArgs,l);
    CopyArray(@FArgs[0],@args[1],TypeInfo(TValue),l);
  end;
end;

constructor TBehavior.CreateReturnDefault(const ReturnValue: TValue);
begin
  FBehaviorType := TBehaviorType.ReturnDefault;
  FReturnValue := ReturnValue;
end;

constructor TBehavior.CreateWillExecute(const AAction: TExecuteFunc);
begin
  FBehaviorType := TBehaviorType.WillExecute;
  FAction := AAction;
end;

constructor TBehavior.CreateWillExecuteWhen(const Args: TArray<TValue>; const AAction: TExecuteFunc; const matchers : TArray<IMatcher>);
begin
  FBehaviorType := TBehaviorType.WillExecuteWhen;
  CopyArgs(Args);
  FAction := AAction;
  FMatchers := matchers;
end;

constructor TBehavior.CreateWillRaise(const AExceptClass: ExceptClass; const message : string);
begin
  FBehaviorType := TBehaviorType.WillRaiseAlways;
  FExceptClass := AExceptClass;
  FExceptionMessage := message;
end;

constructor TBehavior.CreateWillRaiseWhen(const Args: TArray<TValue>; const AExceptClass: ExceptClass; const message : string; const matchers : TArray<IMatcher>);
begin
  FBehaviorType := TBehaviorType.WillRaise;
  FExceptClass := AExceptClass;
  FExceptionMessage := message;
  CopyArgs(Args);
  FMatchers := matchers;
end;

constructor TBehavior.CreateWillReturnWhen(const Args: TArray<TValue>; const ReturnValue: TValue; const matchers : TArray<IMatcher>);
begin
  FBehaviorType := TBehaviorType.WillReturn;
  CopyArgs(Args);
  FReturnValue := ReturnValue;
  FMatchers := matchers;
end;

function TBehavior.Execute(const Args: TArray<TValue>; const returnType: TRttiType): TValue;
var
  msg : string;
begin
  result := TValue.Empty;
  case FBehaviorType of
    WillReturn: result := FReturnValue;
    ReturnDefault: result := FReturnValue;
    WillRaise,WillRaiseAlways:
    begin
       if FExceptClass <> nil then
       begin
         if FExceptionMessage <> '' then
           msg := FExceptionMessage
         else
           msg := 'raised by mock';
         raise FExceptClass.Create(msg);
       end;
    end;
    WillExecute,WillExecuteWhen:
    begin
      if Assigned(FAction) then
        result := FAction(args,returnType);
    end;
  end;
end;

function TBehavior.GetBehaviorType: TBehaviorType;
begin
  Result := FBehaviorType;
end;

function TBehavior.MatchArgs(const Args: TArray<TValue>): Boolean;
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

function TBehavior.MatchWithMatchers(const Args: TArray<TValue>): Boolean;
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

function TBehavior.Match(const Args: TArray<TValue>): Boolean;
begin
  //Match only answers whether this behaviour applies. It used to raise for WillRaise, which
  //fired the exception for every call whatever its arguments - and during setup as well.
  if Length(FMatchers) > 0 then
    Exit(MatchWithMatchers(Args));

  case FBehaviorType of
    WillReturn,
    WillRaise,
    WillExecuteWhen : result := MatchArgs(Args);
  else
    //ReturnDefault, WillRaiseAlways and WillExecute apply whatever the arguments.
    result := True;
  end;
end;

function TBehavior.SameDefinition(const Args: TArray<TValue>; const matchers: TArray<IMatcher>): Boolean;
begin
  if (Length(FMatchers) > 0) or (Length(matchers) > 0) then
    Exit(False);

  case FBehaviorType of
    WillReturn,
    WillRaise,
    WillExecuteWhen : result := MatchArgs(Args);
  else
    result := True;
  end;
end;

end.
