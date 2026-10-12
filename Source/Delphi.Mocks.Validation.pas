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

unit Delphi.Mocks.Validation;

interface

uses
  System.TypInfo;

type
  /// <summary>Checks that a type can be mocked before a proxy is built for it.</summary>
  TMocksValidation = class(TObject)
    /// <summary>Checks that a type is an interface with RTTI, or a class with something to intercept.</summary>
    /// <param name="ATypeInfo">The type.</param>
    /// <exception cref="EMockException">The type is neither an interface nor a class.</exception>
    /// <exception cref="EMockNoRTTIException">The type cannot be mocked.</exception>
    class procedure CheckMockType(const ATypeInfo : PTypeInfo); static;
    /// <summary>Checks that an interface has RTTI.</summary>
    /// <param name="ATypeInfo">The interface.</param>
    /// <exception cref="EMockNoRTTIException">The interface has no method RTTI.</exception>
    class procedure CheckMockInterface(const ATypeInfo : PTypeInfo); static;
    /// <summary>Checks that a class declares a virtual method to intercept.</summary>
    /// <param name="ATypeInfo">The class.</param>
    /// <exception cref="EMockNoRTTIException">The class declares no virtual method of its own.</exception>
    class procedure CheckMockObject(const ATypeInfo : PTypeInfo); static;
  end;

implementation

uses
  Delphi.Mocks.Utils,
  Delphi.Mocks;

{ MocksValidation }

class procedure TMocksValidation.CheckMockInterface(const ATypeInfo : PTypeInfo);
begin
  //Check to make sure we have
  if not CheckInterfaceHasRTTI(ATypeInfo) then
    raise EMockNoRTTIException.Create(ATypeInfo.NameStr + ' does not have RTTI, specify {$M+} for the interface to enabled RTTI');
end;

class procedure TMocksValidation.CheckMockObject(const ATypeInfo: PTypeInfo);
begin
  //Only virtual methods can be intercepted, and that - not RTTI - is what the check measures; the
  //old message sent people looking for a missing {$M+}.
  if not CheckClassHasRTTI(ATypeInfo) then
    raise EMockNoRTTIException.Create(ATypeInfo.NameStr + ' declares no virtual methods, so there is nothing a mock '
      + 'can intercept');
end;

class procedure TMocksValidation.CheckMockType(const ATypeInfo: PTypeInfo);
begin
  if ATypeInfo.Kind not in [tkInterface,tkClass] then
    raise EMockException.Create(ATypeInfo.NameStr + ' is not an Interface or Class. TMock<T> supports interfaces and classes only');

  case ATypeInfo.Kind of
    //NOTE: We have a weaker requirement for an object proxy opposed to an interface proxy.
    //NOTE: Object proxy doesn't require more than zero methods on the object.
    tkClass : CheckMockObject(ATypeInfo);
    tkInterface : CheckMockInterface(ATypeInfo);
  else
    raise EMockException.Create('Invalid type kind T');
  end;
end;


end.
