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


unit Delphi.Mocks.Utils;

interface

uses
  System.TypInfo,
  System.Rtti;

/// <summary>Whether an interface has method RTTI, so it can be mocked.</summary>
/// <param name="info">The interface.</param>
/// <returns>True when it has RTTI for at least one method.</returns>
function CheckInterfaceHasRTTI(const info : PTypeInfo) : boolean;

/// <summary>Whether a class declares a virtual method of its own, beyond TObject's, so a mock has something to
/// intercept. Only virtual methods can be intercepted.</summary>
/// <param name="info">The class.</param>
/// <returns>True when the class has more virtual methods than TObject.</returns>
function CheckClassHasRTTI(const info: PTypeInfo): boolean;

/// <summary>Counts a class's virtual methods, inherited ones included.</summary>
/// <param name="AClass">The class.</param>
/// <returns>The number of VMT slots.</returns>
function GetVirtualMethodCount(AClass: TClass): Integer;

/// <summary>Formats arguments for a report.</summary>
/// <param name="Args">The arguments.</param>
/// <param name="OffSet">How many leading arguments to skip.</param>
/// <returns>The arguments, comma separated in parentheses.</returns>
function ArgsToString(const Args: TArray<TValue>; OffSet: Integer = 0): string;

implementation

uses
  System.SysUtils;

type
  /// <summary>A class that adds nothing to TObject: the baseline a mockable class must exceed.</summary>
  TNoVirtualMethods = class
  end;

function CheckInterfaceHasRTTI(const info : PTypeInfo) : boolean;
var
  rType : TRttiType;
  ctx : TRttiContext;
begin
  ctx := TRttiContext.Create;
  rType := ctx.GetType(info);
  result := (rType <> nil) and (Length(rType.GetMethods) > 0);
end;

function CheckClassHasRTTI(const info: PTypeInfo): boolean;
begin
  //Measured against an empty descendant of TObject rather than a hard-coded 12, so it stays right
  //if TObject gains a virtual method. (Not against TObject itself: its class name is not laid out
  //after its VMT the way an ordinary class's is, so the count method does not apply to it.) The
  //unused RTTI method lists this used to fetch have gone.
  result := GetVirtualMethodCount(GetTypeData(info).ClassType) > GetVirtualMethodCount(TNoVirtualMethods);
end;


//courtesy of Allen Bauer on stackoverflow
//http://stackoverflow.com/questions/760513/where-can-i-find-information-on-the-structure-of-the-delphi-vmt
function GetVirtualMethodCount(AClass: TClass): Integer;
begin
  //Note that this returns all virtual methods in the class, including those from the base class.
  //NativeInt, not Integer: on Win64 a class reference does not fit in 32 bits, so the old
  //cast truncated it and the result was sign extended back into an unmapped address. The
  //VMT slot being read is pointer sized too, so PInteger read only half of it.
  Result := (PNativeInt(NativeInt(AClass) + vmtClassName)^ -
    (NativeInt(AClass) + vmtParent) - SizeOf(Pointer)) div SizeOf(Pointer);
end;

function ArgsToString(const Args: TArray<TValue>; OffSet: Integer = 0): string;
var
  i : integer;
begin
  result := EmptyStr;
  for i := Low(Args) + OffSet to High(Args) do
  begin
    if (result <> EmptyStr) then
      result := result + ', ';
    result := result + Args[i].ToString;
  end;
  result := '( ' + result + ' )';
end;

end.
