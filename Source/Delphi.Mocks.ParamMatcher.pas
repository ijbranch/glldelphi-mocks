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

unit Delphi.Mocks.ParamMatcher;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.TypInfo,
  System.Rtti;


type
  /// <summary>A test applied to one argument of a mocked call.</summary>
  IMatcher = interface
    ['{C0F66756-F6DF-44D2-B3FC-E6B60F843D23}']
    /// <summary>Tests an argument.</summary>
    /// <param name="value">The argument.</param>
    /// <returns>True when the argument is accepted.</returns>
    function Match(const value : TValue) : boolean;
  end;

  /// <summary>A matcher that applies a predicate to an argument of type T.</summary>
  TMatcher<T> = class(TInterfacedObject, IMatcher)
  private
    /// <summary>The test applied to the argument.</summary>
    FPredicate : TPredicate<T>;
  protected
    /// <summary>Tests an argument; an argument that is not a T is rejected rather than raising.</summary>
    /// <param name="value">The argument.</param>
    /// <returns>True when the argument is a T and the predicate accepts it.</returns>
    function Match(const value : TValue) : boolean;
  public
    /// <summary>Creates the matcher.</summary>
    /// <param name="predicate">The test applied to the argument.</param>
    constructor Create(const predicate : TPredicate<T>);
  end;

  /// <summary>Collects the matchers an It0..It9 expression registers while the arguments of a When call are
  /// evaluated, per thread, until the proxy picks them up.</summary>
  TMatcherFactory = class
  private
    class var
       /// <summary>Each thread's pending matchers, indexed by parameter.</summary>
       FMatchers : TObjectDictionary<TThreadID,TList<IMatcher>>;
       /// <summary>Guards FMatchers.</summary>
       FLock     : TObject;
  protected
    /// <summary>Creates the per-thread store.</summary>
    class constructor Create;
    /// <summary>Frees the per-thread store.</summary>
    class destructor Destroy;
    /// <summary>Registers a matcher for one parameter of the current thread's pending setup.</summary>
    /// <param name="paramIndex">The zero-based parameter index, Self excluded.</param>
    /// <param name="matcher">The matcher.</param>
    /// <exception cref="EMockSetupException">The parameter already has a matcher. The pending matchers are
    /// discarded, so the next setup starts clean.</exception>
    class procedure AddMatcher(const paramIndex : integer;  const matcher : IMatcher);
  public
    /// <summary>Registers a predicate as the matcher for one parameter.</summary>
    /// <param name="paramIndex">The zero-based parameter index, Self excluded.</param>
    /// <param name="predicate">The test applied to the argument.</param>
    /// <exception cref="EMockSetupException">The parameter already has a matcher.</exception>
    class procedure Create<T>(const paramIndex : integer; const predicate: TPredicate<T>);
    /// <summary>Takes the current thread's pending matchers, leaving none behind.</summary>
    /// <returns>The matchers by parameter index; an index with no matcher holds nil.</returns>
    class function  GetMatchers : TArray<IMatcher>;
    /// <summary>Discards the current thread's pending matchers. Called for every ordinary (non-setup) call, so
    /// an It expression evaluated outside a When cannot attach itself to a later setup.</summary>
    class procedure ClearMatchers;
  end;


implementation

uses
  System.Classes,
  System.SyncObjs,
  Delphi.Mocks;


{ TMatcherFactory }

class procedure TMatcherFactory.Create<T>(const paramIndex : integer; const predicate: TPredicate<T>);
var
  matcher : IMatcher;
begin
  matcher := TMatcher<T>.Create(predicate);
  AddMatcher(paramIndex, matcher);
end;

{ TMatcher<T> }

constructor TMatcher<T>.Create(const predicate: TPredicate<T>);
begin
  FPredicate := predicate;
end;

function TMatcher<T>.Match(const value: TValue): boolean;
begin
  try
    result := FPredicate(value.AsType<T>);
  except
    on EInvalidCast do
      Result := False
    else
      raise;
  end;
end;

class constructor TMatcherFactory.Create;
begin
  FMatchers := TObjectDictionary<TThreadID,TList<IMatcher>>.Create([doOwnsValues]);
  FLock     := TObject.Create;
end;

class destructor TMatcherFactory.Destroy;
begin
  // FMatchers owns its values (doOwnsValues), so freeing them here as well was a double free.
  FMatchers.Free;
  FLock.Free;
end;

class function TMatcherFactory.GetMatchers : TArray<IMatcher>;
var
  threadMatchers : TList<IMatcher>;
begin
  SetLength(result,0);
  MonitorEnter(FLock);
  try
    if FMatchers.TryGetValue(TThread.CurrentThread.ThreadID,threadMatchers) then
    begin
      result := threadMatchers.ToArray;
      FMatchers.Remove(TThread.CurrentThread.ThreadID);
    end;
  finally
    MonitorExit(FLock);
  end;
end;

class procedure TMatcherFactory.ClearMatchers;
begin
  MonitorEnter(FLock);
  try
    FMatchers.Remove(TThread.CurrentThread.ThreadID);
  finally
    MonitorExit(FLock);
  end;
end;

class procedure TMatcherFactory.AddMatcher(const paramIndex : integer; const matcher : IMatcher);
var
  threadMatchers : TList<IMatcher>;
begin
  MonitorEnter(FLock);
  try
    if not FMatchers.TryGetValue(TThread.CurrentThread.ThreadID,threadMatchers) then
    begin
      threadMatchers := TList<IMatcher>.Create;
      FMatchers.Add(TThread.CurrentThread.ThreadID,threadMatchers);
    end;

    while paramIndex > threadMatchers.Count - 1 do
      threadMatchers.Add(nil);

    //A second matcher for the same parameter was inserted, which silently shifted every later
    //parameter's matcher one place along. It is a mistake (It0 used twice) or a leftover from a
    //setup that never completed; either way the setup cannot be trusted, so start clean and say so.
    if threadMatchers[paramIndex] <> nil then
    begin
      FMatchers.Remove(TThread.CurrentThread.ThreadID);
      raise EMockSetupException.CreateFmt('A matcher was already given for parameter %d. Use It0 for the first '
        + 'parameter, It1 for the second and so on, once each.', [paramIndex]);
    end;

    threadMatchers[paramIndex] := matcher;

  finally
    MonitorExit(FLock);
  end;
end;

end.
