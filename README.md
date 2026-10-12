# glldelphi-mocks

GITLAK Software's fork of [Delphi Mocks](https://github.com/VSoftTechnologies/Delphi-Mocks), Vincent Parrett's
RTTI-based mocking framework for Delphi.

> **Scope.** This fork targets **Delphi 13 (Florence), Windows only - Win32 and Win64**; pre-D13 and non-Windows
> code has been removed. Use [upstream Delphi Mocks](https://github.com/VSoftTechnologies/Delphi-Mocks) for anything
> else. Its main consumer is [gllDUnitX](https://github.com/ijbranch/gllDUnitX), whose test project builds against it.
>
> **Not affiliated with VSoft Technologies.** This is an independent fork; credit for Delphi Mocks belongs to
> Vincent Parrett and its contributors - see *Licence* at the foot of this file.
>
> **Without support.** Maintained for GITLAK Software's own use; it does not take pull requests. A fix to Delphi
> Mocks itself belongs upstream.

What this fork changed - fixes, tests that can now fail when they should, the return-type patch and its
tests - is in [CHANGELOG.md](CHANGELOG.md); [Help.md](Help.md) is the reference and
[Users Guide.md](Users%20Guide.md) walks through a first test. The rest of this file is upstream's own
description, kept as it was apart from its version note.

# Delphi Mocks

Delphi Mocks is a simple mocking framework for Delphi. It makes use of RTTI features first available in Delphi
XE2 (this fork requires Delphi 13). See the example at the bottom of the page for a complete explanation.

# Parameter matching

To match expectations or behavior there is extended parameter matching.

```Pascal
    function IsAny<T>() : T ;
    function Matches<T>(const predicate: TPredicate<T>) : T;
    function IsNotNil<T> : T; overload;
    function IsNotNil<T>(const comparer: IEqualityComparer<T>) : T; overload;
    function IsEqualTo<T>(const value : T) : T; overload;
    function IsEqualTo<T>(const value : T; const comparer: IEqualityComparer<T>) : T; overload;
    function IsInRange<T>(const fromValue : T; const toValue : T) : T;
    function IsIn<T>(const values : TArray<T>) : T; overload;
    function IsIn<T>(const values : TArray<T>; const comparer: IEqualityComparer<T>) : T; overload;
    function IsIn<T>(const values : IEnumerable<T>) : T; overload;
    function IsIn<T>(const values : IEnumerable<T>; const comparer: IEqualityComparer<T>) : T; overload;
    function IsNotIn<T>(const values : TArray<T>) : T; overload;
    function IsNotIn<T>(const values : TArray<T>; const comparer: IEqualityComparer<T>) : T; overload;
    function IsNotIn<T>(const values : IEnumerable<T>) : T; overload;
    function IsNotIn<T>(const values : IEnumerable<T>; const comparer: IEqualityComparer<T>) : T; overload;
    function IsRegex(const regex : string; const options : TRegExOptions = []) : string;
    function AreSamePropertiesThat<T>(const Value: T): T;
    function AreSameFieldsThat<T>(const Value: T): T;
    function AreSameFieldsAndPropertiedThat<T>(const Value: T): T;
```

Usage is easy:

```Pascal
  mock.Setup.Expect.Once.When.SimpleMethod(It0.IsAny<Integer>, It1.IsAny<String>);
  mock.Setup.WillReturn(3).When.SimpleFunction(It0.IsEqualTo<String>('hello'));
```

## Documentation

| For | Read |
|---|---|
| The API reference — TMock<T>, TStub<T>, the setup and expectation interfaces, and the six exception classes with their messages | [Help.md](Help.md) |
| Doing a job — mock an interface, set expectations, verify, stub a class | [Users Guide.md](Users%20Guide.md) |
| What changed and when | [CHANGELOG.md](CHANGELOG.md) |

## Class matching
Some more attention should be payed for matching classes. Usage of `.IsAny<TMyClass>` will not work as might be expected, because `nil` (which is the default return value of `IsAny<T>`) is always a good match. Therefore the following setup will fail on the second line, because the framework will think that there is already behavior defined (in the first line).

```Pascal
  mock.Setup.Expect.Never.When.ExtendedMethod(It0.IsAny<TMyClass>);
  mock.Setup.Expect.Never.When.ExtendedMethod(It0.IsAny<TMyOtherClass>);
```

This can easily be solved by using `.IsNotNil<TMyClass>`:

```Pascal
  mock.Setup.Expect.Never.When.ExtendedMethod(It0.IsNotNil<TMyClass>);
  mock.Setup.Expect.Never.When.ExtendedMethod(It0.IsNotNil<TMyOtherClass>);
```

# Example

```Pascal
unit Delphi.Mocks.Examples.Interfaces;

interface

uses
  SysUtils,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  {$M+}
  TSimpleInterface = Interface
    ['{4131D033-2D80-42B8-AAA1-3C2DF0AC3BBD}']
    procedure SimpleMethod;
  end;

  TSystemUnderTestInf = Interface
    ['{5E21CA8E-A4BB-4512-BCD4-22D7F10C5A0B}']
    procedure CallsSimpleInterfaceMethod;
  end;
  {$M-}

  TSystemUnderTest = class(TInterfacedObject, TSystemUnderTestInf)
  private
    FInternalInf : TSimpleInterface;
  public
    constructor Create(const ARequiredInf: TSimpleInterface);
    procedure CallsSimpleInterfaceMethod;
  end;

  TMockObjectTests = class
  published
    procedure Simple_Interface_Mock;
  end;

implementation

uses
  System.Rtti;

{ TMockObjectTests }

procedure TMockObjectTests.Simple_Interface_Mock;
var
  mock : TMock<TSimpleInterface>;
  sutObject : TSystemUnderTestInf;
begin
  //SETUP: Create a mock of the interface that is required by our system under test object.
  mock := TMock<TSimpleInterface>.Create;

  //SETUP: Add a check that SimpleMethod is called atleast once.
  mock.Setup.Expect.AtLeastOnce.When.SimpleMethod;

  //SETUP: Create the system under test object passing an instance of the mock interface it requires.
  sutObject := TSystemUnderTest.Create(mock.Instance);

  //TEST: Call CallsSimpleInterfaceMethod on the system under test.
  sutObject.CallsSimpleInterfaceMethod;

  //VERIFY: That our passed in interface was called at least once when CallsSimpleInterfaceMethod was called.
  mock.Verify('CallsSimpleInterfaceMethod should call SimpleMethod');
end;

{ TSystemUnderTest }

procedure TSystemUnderTest.CallsSimpleInterfaceMethod;
begin
  FInternalInf.SimpleMethod;
end;

constructor TSystemUnderTest.Create(const ARequiredInf: TSimpleInterface);
begin
  FInternalInf := ARequiredInf;
end;

end.
```

# Licence

Apache License 2.0 - see [LICENSE.txt](LICENSE.txt). Delphi Mocks: Copyright (C) 2011+ Vincent Parrett and
contributors; their commits keep their authors in this fork's history.

**This fork.** Changes made in glldelphi-mocks are Copyright (C) 2026 Ian Branch (GITLAK Software) and are licensed
under the same Apache License 2.0. Every source file this fork changed carries a
"Modified (C) 2026 Ian Branch (GITLAK Software)" line beneath its original copyright notice, which is kept intact;
a unit the fork added carries its own header. The changes were developed with
[Claude Code](https://claude.com/claude-code), Anthropic's AI coding assistant, which wrote much of the fork's code,
tests and documentation under Ian Branch's direction; commits it contributed to carry a `Co-Authored-By: Claude`
trailer. glldelphi-mocks is an independent fork and is not affiliated with or endorsed by VSoft Technologies;
"Delphi Mocks" refers to the upstream project it derives from.
