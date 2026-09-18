# Help — glldelphi-mocks

`glldelphi-mocks` is the GITLAK fork of **Delphi Mocks**, Vincent Parrett's RTTI-based mocking
framework. You write test code against it: `TMock<T>` and `TStub<T>` build a stand-in for an
interface or a class, you say what it should do, and you verify afterwards that it was used the
way you said it would be.

Target: **Delphi 13 / RAD Studio 37.0**, VCL-free (the runtime package requires `rtl` only),
**Win32 + Win64** declared on every project. Apache-2.0, upstream copyright retained.

This file is the **lookup** document: the public surface unit by unit, the exception messages,
and the failures by symptom. For a walked-through first test, read
[Users%20Guide.md](Users%20Guide.md). Upstream's own description and the parameter-matcher list
are in [README.md](README.md); what this fork changed is in [CHANGELOG.md](CHANGELOG.md).

---

## 1. What you `uses`

One unit. `Delphi.Mocks` is the entire public surface; the other fifteen units in `Source\` are
implementation and you should not need to name any of them in a test.

```pascal
uses
  DUnitX.TestFramework,
  Delphi.Mocks;
```

---

## 2. API reference — `Delphi.Mocks`

### `TMock<T>` — the full mock

A **record**, deliberately: the `Implicit` operator lets it be passed where a `T` is expected
without holding a reference to the mock interface outside the record.

| Member | Signature | Purpose |
|---|---|---|
| `Create` | `class function Create: TMock<T>; static` | Build a mock of `T`. |
| `Create` | `class function Create( const ACreateObjectFunc: TFunc<T> ): TMock<T>; static` | Build a mock whose underlying object comes from your factory. |
| `Create` | `class function Create( const AAutoMock: IAutoMock; const ACreateObjectFunc: TFunc<T> ): TMock<T>; static` | Used by `TAutoMockContainer`. |
| `Setup` | `function Setup: IMockSetup<T>` | Where behaviour and expectations are declared. |
| `Setup<I>` | `function Setup<I: IInterface>: IMockSetup<I>` | The same, for an additional interface added with `Implement<I>`. |
| `Instance` | `function Instance: T` | The thing to hand to the system under test. |
| `Instance<I>` | `function Instance<I: IInterface>: I` | The additional interface's instance. |
| `InstanceAsValue` | `function InstanceAsValue: TValue` | The instance boxed as a `TValue`. |
| `Implement<I>` | `procedure Implement<I: IInterface>` | Make one mock implement a second interface. |
| `Verify` | `procedure Verify( const message: string = '' )` | Raise `EMockVerificationException` if any expectation was not met. |
| `Verify<I>` | `procedure Verify<I: IInterface>( const message: string = '' )` | The same, for an implemented interface. |
| `VerifyAll` | `procedure VerifyAll( const message: string = '' )` | Verify across every interface the mock implements. |
| `CheckExpectations` | `function CheckExpectations: string` | The failure text `Verify` would raise, or `''`. Use it to assert without an exception. |
| `ResetCalls` | `procedure ResetCalls` | Forget the calls recorded so far. |
| `Free` | `procedure Free` | Explicit cleanup. The comment in the source says "Not sure if we really need this." |
| `Implicit` | `class operator Implicit( const Value: TMock<T> ): T` | Lets the mock be used directly as a `T`. |

### `TStub<T>` — behaviour without expectations

The same shape, minus everything to do with verification. A stub says *what a call returns*; it
never fails a test.

| Member | Signature |
|---|---|
| `Create` | `class function Create: TStub<T>; static` |
| `Create` | `class function Create( const ACreateObjectFunc: TFunc<T> ): TStub<T>; static` |
| `Setup` | `function Setup: IStubSetup<T>` |
| `Instance` | `function Instance: T` |
| `InstanceAsValue` | `function InstanceAsValue: TValue` |
| `Free` | `procedure Free` |
| `Implicit` | `class operator Implicit( const Value: TStub<T> ): T` |

### `IStubSetup<T>` — declaring behaviour

Available on both `TStub<T>.Setup` and `TMock<T>.Setup`.

| Member | Effect |
|---|---|
| `WillReturn( const value: TValue ): IWhen<T>` | Return `value` for the call described by the following `.When`. |
| `WillReturn( const value: TValue; const AllowNil: Boolean ): IWhen<T>` | The same, stating whether a nil return is legitimate. |
| `WillReturnNil: IWhen<T>` | Return nil for the call described by the following `.When`. |
| `WillReturnDefault( const AMethodName: string; const value: TValue )` | The value returned when the method is called with arguments you did **not** describe. |
| `WillExecute( const func: TExecuteFunc ): IWhen<T>` | Run `func` for the call described by the following `.When`. |
| `WillExecute( const AMethodName: string; const func: TExecuteFunc )` | Run `func` for **every** call to that method, whatever the arguments. |
| `WillRaise( const exceptionClass: ExceptClass; const message: string = '' ): IWhen<T>` | Raise for the call described by the following `.When`. |
| `WillRaise( const AMethodName: string; const exceptionClass: ExceptClass; const message: string = '' )` | Always raise for that method. **This trumps any other behaviour defined for it.** |
| `WillRaiseWhen( const exceptionClass: ExceptClass; const message: string = '' ): IWhen<T>` | As `WillRaise`, in the `When` form. |
| `BehaviorMustBeDefined: Boolean` | When true, a call to a method with no defined behaviour makes `Verify` fail. |
| `AllowRedefineBehaviorDefinitions: Boolean` | When true, a behaviour may be defined a second time for the same call. |

```pascal
TExecuteFunc = reference to function ( const args: TArray<TValue>;
                                       const ReturnType: TRttiType ): TValue;
```

`args` holds the arguments the mock was called with. If the method returns a value, the function
must return one **of the matching type** — `ReturnType` is passed in so you can check.

### `IMockSetup<T>` — adds expectations

`IMockSetup<T>` descends from `IStubSetup<T>` and adds exactly one member:

| Member | Effect |
|---|---|
| `Expect: IExpect<T>` | Begin an expectation. |

### `IExpect<T>` — how many times, and in what order

Every member comes in **two** forms: a function returning `IWhen<T>`, which applies to a
*specific argument list* described by the `.When` that follows; and a procedure taking a method
name, which applies to **every** call of that method.

| Member | Function form | Procedure form |
|---|---|---|
| Once | `Once: IWhen<T>` | `Once( const AMethodName: string )` |
| Never | `Never: IWhen<T>` | `Never( const AMethodName: string )` |
| At least once | `AtLeastOnce: IWhen<T>` | `AtLeastOnce( const AMethodName: string )` |
| At least *n* | `AtLeast( const times: Cardinal ): IWhen<T>` | `AtLeast( const AMethodName: string; const times: Cardinal )` |
| At most *n* | `AtMost( const times: Cardinal ): IWhen<T>` | `AtMost( const AMethodName: string; const times: Cardinal )` |
| Between *a* and *b* | `Between( const a, b: Cardinal ): IWhen<T>` | `Between( const AMethodName: string; const a, b: Cardinal )` |
| Exactly *n* | `Exactly( const times: Cardinal ): IWhen<T>` | `Exactly( const AMethodName: string; const times: Cardinal )` |
| Ordering | `Before( const AMethodName: string ): IWhen<T>` | `Before( const AMethodName, ABeforeMethodName: string )` |
| Ordering | `After( const AMethodName: string ): IWhen<T>` | `After( const AMethodName, AAfterMethodName: string )` |
| — | `Clear` | discard the expectations recorded so far |

### `IWhen<T>`

```pascal
IWhen<T> = interface
  function When: T;
end;
```

One member. `When` returns the mock typed as `T`, so the *next call you write* is the one being
described. That is the whole grammar: everything before `.When` says what should happen, and the
method call after it says which call it applies to.

### Parameter matchers — `ItRec`, and `It0` … `It9`

Matchers are positional. `ItN` is the matcher for **parameter index N**, so a two-argument method
is described with `It0` and `It1`:

```pascal
mock.Setup.Expect.Once.When.SimpleMethod( It0.IsAny<Integer>, It1.IsAny<String> );
```

`It( const AParamIndx: Integer ): ItRec` gives an arbitrary index; `It0` … `It9` are shorthands.

| Matcher | Matches |
|---|---|
| `IsAny<T>: T` | anything |
| `Matches<T>( const predicate: TPredicate<T> ): T` | whatever your predicate accepts |
| `IsNotNil<T>: T` | any non-nil value |
| `IsNotNil<T>( const comparer: IEqualityComparer<T> ): T` | the same, with your comparer |
| `IsEqualTo<T>( const value: T ): T` | that value |
| `IsEqualTo<T>( const value: T; const comparer: IEqualityComparer<T> ): T` | that value, by your comparer |
| `IsInRange<T>( const fromValue, toValue: T ): T` | a value in the closed range |
| `IsIn<T>( const values: TArray<T> ): T` | membership of an array |
| `IsIn<T>( const values: TArray<T>; const comparer: IEqualityComparer<T> ): T` | the same, with your comparer |
| `IsIn<T>( const values: IEnumerable<T> ): T` | membership of an enumerable |
| `IsIn<T>( const values: IEnumerable<T>; const comparer: IEqualityComparer<T> ): T` | the same, with your comparer |
| `IsNotIn<T>` | the four `IsIn` overloads, negated |
| `IsRegex( const regex: string; const options: TRegExOptions = [] ): string` | a string matching the pattern |
| `AreSamePropertiesThat<T>( const Value: T ): T` | an instance whose **published properties** all compare equal |
| `AreSameFieldsThat<T>( const Value: T ): T` | an instance whose **fields** all compare equal |
| `AreSameFieldsAndPropertiedThat<T>( const Value: T ): T` | both. The spelling is upstream's and is part of the API. |

### `TAutoMockContainer`

| Member | Signature |
|---|---|
| `Create` | `class function Create: TAutoMockContainer; static` |
| `Mock<T>` | `function Mock<T>: TMock<T>` |
| `Mock` | `procedure Mock( const ATypeInfo: PTypeInfo )` |

A container that creates and owns mocks on demand, so a system under test with many dependencies
does not need one variable per dependency.

### `TComparer`

| Member | Purpose |
|---|---|
| `class function CompareFields<T>( Param1, Param2: T ): Boolean` | compare two instances by field |
| `class function CompareProperties<T>( Param1, Param2: T ): Boolean` | compare by published property |
| `class function CompareMembers<T: TRttiMember; T2>( Members: TArray<T>; Param1, Param2: T2 ): Boolean` | compare by an explicit member list |

These are what `AreSameFieldsThat` and `AreSamePropertiesThat` use, exposed for direct use.

### Exception classes

```pascal
EMockException = class( Exception );
  EMockProxyAlreadyImplemented = class( EMockException );
  EMockSetupException          = class( EMockException );
  EMockNoRTTIException         = class( EMockException );
  EMockNoProxyException        = class( EMockException );
  EMockVerificationException   = class( EMockException );
```

**All five descend directly from `EMockException`**, not from one another. That matters when you
assert on them — see section 5.

---

## 3. Exception messages

Verbatim from `Source\`, so they are greppable. `%s` placeholders are shown as `[…]` the way the
source formats them.

### `EMockNoRTTIException` — `Delphi.Mocks.Validation.pas`

| Message | Cause |
|---|---|
| `<T> does not have RTTI, specify {$M+} for the interface to enabled RTTI` | the interface is not compiled with `{$M+}` |
| `<T> does not have RTTI, specify {$M+} for the object to enabled RTTI` | the class is not compiled with `{$M+}` |

(The wording is upstream's, typo included.)

### `EMockException` — `Delphi.Mocks.Validation.pas`, `.ObjectProxy.pas`, `.MethodData.pas`

| Message | Cause |
|---|---|
| `<T> is not an Interface or Class. TMock<T> supports interfaces and classes only` | `T` is a record, an enum, … |
| `Invalid type kind T` | the type kind is neither interface nor class |
| `Could not find constructor Create on type <T>` | mocking a class with no `Create` |
| `[<T>] has no behaviour or expectation defined for method [<M>]` | the method was called and nothing was set up for it |
| `[<T>] has no default return value or return type was defined for method [<M>]` | a function was called with no `WillReturn`/`WillReturnDefault` |
| `[<T>] already defines Expectation <Kind> for method [<M>]` | the same expectation kind declared twice — `Once`, `Never`, `Exactly`, `At Least`, `At Most`, `Between`, and the `When` variants of each |

### `EMockSetupException` — `Delphi.Mocks.Proxy.pas`, `.Proxy.TypeInfo.pas`, `.MethodData.pas`

| Message | Cause |
|---|---|
| `Setup called with Matchers but on all parameters : <Method>` | some parameters used `ItN` matchers and some did not. **Use matchers on every parameter or on none.** |
| `Setup.WillReturn called on [<kind>] method [<Method>] which does not have a return value.` | `WillReturn` on a procedure |
| `Setup.WillReturn call on method [<Method>] was not passed a return value.` | `WillReturn` with nothing to return |
| `[<T>] already defines Will Return When for method [<M>]` | the same argument list set up twice — also `Will Return Default`, `WillExecute`, `WillExecute When`, `Will Raise Always`, `Will Raise When` |

### `EMockNoProxyException` — `Delphi.Mocks.Proxy*.pas`, `.AutoMock.pas`

| Message |
|---|
| `Error casting to interface [<T>], proxy does not appear to implement T` |
| `Error - No Proxy of type [<T>] was found.` |
| `Error casting to interface <T> , proxy does not appear to implement IProxy` |

### `EMockProxyAlreadyImplemented`

`The mock already implements <T>` — `Implement<I>` called twice for the same interface.

### `EMockVerificationException`

Raised by `Verify` / `VerifyAll`. The message is **your** message, then CRLF, then the text
`CheckExpectations` produced. If you want the detail without an exception, call
`CheckExpectations` yourself — it returns `''` when everything was satisfied.

---

## 4. Scope of this fork

`origin` is `https://github.com/ijbranch/glldelphi-mocks.git`; `upstream` is
[`VSoftTechnologies/Delphi-Mocks`](https://github.com/VSoftTechnologies/Delphi-Mocks) and is kept
as a remote. **There is shared history** — `git merge-base HEAD upstream/master` resolves — so
ancestry comparisons are meaningful here. At the last fetch in this checkout the fork was **15
commits ahead and 0 behind** both `upstream/master` and `upstream/Development`.

The DPM package id is **`GITLAK.DelphiMocks`**, not `VSoft.DelphiMocks`, so this fork cannot
shadow upstream in a package feed. `VSoft.DelphiMocks.dspec.yaml` records the upstream baseline
(0.3.2), targets `delphi13.0` / `win64`, and keeps Vincent Parrett's authorship and copyright as
Apache-2.0 requires.

### Bugs fixed here that upstream still has

These are the reason to prefer this fork, and each one is a real defect rather than housekeeping:

| Fix | What it was |
|---|---|
| **Win64 object proxy** — `Source\Delphi.Mocks.Utils.pas` | `GetVirtualMethodCount` cast a class reference with `Integer(AClass)`, truncating a 64-bit pointer to 32 bits so it sign-extended back into unmapped memory, and read the pointer-sized VMT slot through a `PInteger`. Both are now `NativeInt`. The suite went from **132 passed / 1 failed / 23 errored** to **156 passed / 0 failed / 0 errored**. |
| **`TAutoMock.Destroy` never freed `FMocks`** — `Delphi.Mocks.AutoMock.pas` | a leaked `TList<IProxy>` per container. |
| **Reference cycle between `TAutoMockContainer` and its proxies** — `Delphi.Mocks.Proxy.pas`, `.Proxy.TypeInfo.pas` | the container held each proxy strongly and every proxy held the container strongly, so neither was ever destroyed and the proxies, their `TVirtualInterface`s and all method data leaked. The proxy now holds the container through `IWeakReference<IAutoMock>` — `TAutoMock` already descended from `TWeakReferencedObject`, so this is the design that was intended. |
| **`TProxy<T>._Release` raised before calling `inherited`** — `Delphi.Mocks.Proxy.pas` | the reference count was never decremented, so the proxy leaked. It now decrements first and reports afterwards. |
| **`TMatcherFactory` double free** — `Delphi.Mocks.ParamMatcher.pas` | it freed matcher lists by hand although the dictionary owns them (`doOwnsValues`) — a double free on any aborted `Setup`. |
| **Pointer comparison truncated to `Integer`** — `Delphi.Mocks.Helpers.pas` | two instances exactly 4 GiB apart compared equal. Now compared by sign. |
| **12 × `W1029` in every consuming build** — `Delphi.Mocks.Expectation.pas` | the unit told callers to put `{$WARN DUPLICATE_CTOR_DTOR OFF}` in their `.dpr`, but a `{$WARN}` there does not affect how a separate unit is compiled, so the advice never worked. The directive now sits in the unit that emits the warnings; a consuming build went from 13 warnings to 1. |
| **`.gitmodules` broke `clone --recursive`** | it declared a `DUnitXML` submodule with no gitlink and no directory. Removed, along with a stray `=======` merge-conflict marker in `.gitignore`. |

### What was removed

Fourteen pre-D13 package folders, the legacy `DelphiMocks` / `DelphiMocksXE5` / `DelphiMocks104`
packages under `Source`, `Tests\MemoryLeakTest` (Win32, classic DUnit, vendored FastMM4), the
FinalBuilder projects with hard-coded `I:\` paths, and the stale JSON `.dspec` superseded by the
`.yaml`. **Only `packages\RAD Studio 13.0\` remains.**

### Reviewed and deliberately NOT taken

`upstream/AutoMockV2` was swept on 2026-09-18 and nothing was taken. It is an abandoned **2015**
feature branch. Its one content commit, `928ca09` "removed param matchers which was copied by
accident", removes `Delphi.Mocks.ParamMatcher` from four `uses` clauses — **and it would break
the build**, because that unit is live here and referenced by eight units (`Delphi.Mocks.pas`,
`.Behavior`, `.Expectation`, `.Interfaces`, `.MethodData`, `.Proxy`, `.Proxy.TypeInfo`, and
itself), and we have since fixed a real defect inside it. Upstream itself reversed the judgement
when `Development` was merged back. `2cbaae6` is a merge whose unique content is exactly those
three deletions. **There is no condition under which this is reopened.**

### Known issues, deliberately left

- **`Delphi.Mocks.ReturnTypePatch.pas` shadow-declares private `System.Rtti` fields** to patch
  RTTI. The layout still matches RAD Studio 37.0, but this **breaks silently** if Embarcadero
  reorders them. It is the first thing to suspect after a RAD Studio update.
- **`Delphi.Mocks.ObjectProxy.pas` frees the wrapped instance unconditionally**, even when the
  caller supplied it. Changing that is an ownership-contract change, so it is left alone on
  purpose.

---

## 5. Using it with our DUnitX fork — two defaults that make a test unable to fail

`gllDUnitX` is the DUnitX this estate uses, and two of its assertion defaults are weaker than they
read. Neither is specific to mocking, but both bite hardest in mock tests, where the assertion is
usually the only thing standing between a green run and a silent regression.

### `Assert.AreEqual( string, string )` **ignores case**

In `D:\gllDUnitX\Source\DUnitX.Assert.pas` the class constructor sets
`fIgnoreCaseDefault := True`, and the two-argument string overload forwards it. So:

```pascal
Assert.AreEqual( 'McDonald', mock.Instance.Name );   // passes for 'MCDONALD', 'mcdonald', …
```

`Assert.StartsWith`, `EndsWith`, `Contains` and `AreNotEqual` take the same default. When the
casing is the point, pass `False` as the third argument:

```pascal
Assert.AreEqual( 'McDonald', mock.Instance.Name, False );
```

**`Tests\Delphi.Mocks.Tests.dpr` does not set `Assert.IgnoreCaseDefault := False`**, so this
suite carries the weak default.

### `Assert.WillNotRaise( proc, SomeClass, msg )` **swallows everything else**

Our fork's body is `if e.ClassType = exceptionClass then Fail` — an `=` on `ClassType`, not an
`is`. So passing a class means the assertion fails **only** on that exact class and does nothing
at all for any other exception, including an `EAccessViolation`. The test passes while the fault
it was written to detect happens on every run.

Passing **no** class takes the `else` branch, `FailFmt( SUnexpectedException, … )`, which fails on
anything — so a bare `Assert.WillNotRaise( proc )` is safe. `Assert.WillNotRaiseAny( proc, msg )`
is the explicit form and is what new tests should use. `Assert.WillNotRaiseDescendant` exists for
the narrower case.

**This repository has two sites that pass a class** — `Assert.WillNotRaise( …, EMockSetupException )`
in `Tests\Delphi.Mocks.Tests.MethodData.pas`. Because the five mock exception classes all descend
*directly* from `EMockException` and not from one another, the exact-match behaviour happens to
catch what those two tests are aiming at; but they will also pass if the code under test raises
anything else at all.

---

## 6. Building

### The runtime package

`packages\RAD Studio 13.0\VSoft.DelphiMocksR.dproj` — **the only package folder in the
repository**, and the only one there should be.

| Fact | Value |
|---|---|
| Kind | `{$RUNONLY}` — a runtime package. There is no design-time package and nothing registers into the IDE. |
| `requires` | `rtl` only |
| `contains` | 16 units — every `.pas` in `Source\` |
| Suffix | `{$LIBSUFFIX AUTO}`, which on RAD Studio 37.0 produces `VSoft.DelphiMocksR370.bpl` |
| `ProjectVersion` | 20.5 |
| Platforms | `Win32=True`, `Win64=True`; `TargetedPlatforms` 3 |
| `DCC_CBuilderOutput` | `None` |

**Build all four modes** — Win32 + Win64 × Debug + Release. The `.dproj` carries the estate
output standard:

```xml
<DCC_BplOutput Condition="'$(Config)'=='Release'">$(BDSCOMMONDIR)\Bpl\$(Platform)</DCC_BplOutput>
<DCC_BplOutput Condition="'$(Config)'!='Release'">$(BDSCOMMONDIR)\Bpl\$(Platform)\$(Config)</DCC_BplOutput>
<DCC_DcpOutput Condition="'$(Config)'=='Release'">$(BDSCOMMONDIR)\Dcp\$(Platform)</DCC_DcpOutput>
<DCC_DcpOutput Condition="'$(Config)'!='Release'">$(BDSCOMMONDIR)\Dcp\$(Platform)\$(Config)</DCC_DcpOutput>
```

Release stays in the shared platform folder because that folder is on `PATH` and is where a
dependent package resolves its `requires`; only Debug is diverted. **An earlier attempt that
diverted Release as well broke package loading** — do not "tidy" it back.

DCUs are `.\$(Platform)\$(Config)`, project-local and split both ways.

### The test project

`Tests\Delphi.Mocks.Tests.dproj`, a DUnitX console runner. Output and DCUs both go to
`.\$(Platform)\$(Config)`.

**DUnitX comes from a sibling `gllDUnitX` checkout**, not from a package:

```xml
<DUNITX Condition="'$(DUNITX)'==''">..\..\gllDUnitX\Source</DUNITX>
```

and a `CheckDUnitX` target runs `BeforeTargets="Build"`, failing with:

> `DUnitX was not found at '<path>'. Clone https://github.com/ijbranch/gllDUnitX as a sibling of
> this repository, or set the DUNITX property or environment variable to its Source folder.`

The unit search path is `..\Source;$(DUNITX)` — so the **source** of both the library and DUnitX
is compiled into the test executable. Building the package is not a prerequisite for running the
tests, and a change to `Source\` is picked up by the next test build without any package rebuild.

---

## 7. Troubleshooting

### `<T> does not have RTTI, specify {$M+} for the interface to enabled RTTI`

The interface was not compiled with `{$M+}`. RTTI for interfaces is not on by default, and this
framework is built entirely on RTTI. Wrap the declaration:

```pascal
{$M+}
  ISomething = interface
    ['{4131D033-2D80-42B8-AAA1-3C2DF0AC3BBD}']
    procedure DoIt;
  end;
{$M-}
```

The GUID matters too: the proxy resolves the interface through `QueryInterface`.

### `Setup called with Matchers but on all parameters : <Method>`

Matchers are all-or-nothing per call. If any parameter uses `ItN`, **every** parameter must. Pass
`It1.IsEqualTo<string>( 'x' )` rather than a bare `'x'` alongside an `It0.IsAny<Integer>`.

(The message is upstream's and reads oddly — it means "matchers were used, but not on all
parameters".)

### A `Never` expectation on two different classes: the second setup fails

Documented upstream and worth repeating because the cause is not obvious. `IsAny<T>` returns the
**default** value of `T`, which for a class is `nil` — and `nil` matches everything. So:

```pascal
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsAny<TMyClass> );
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsAny<TMyOtherClass> );  // fails
```

The framework believes behaviour is already defined for that call. Use `IsNotNil<T>` for class
parameters:

```pascal
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsNotNil<TMyClass> );
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsNotNil<TMyOtherClass> );
```

### `[<T>] has no behaviour or expectation defined for method [<M>]`

The system under test called a method you did not set up. Either set it up, or — if the call is
genuinely irrelevant to this test — give the method a `WillReturnDefault`.

### `Setup.WillReturn called on [<kind>] method [<M>] which does not have a return value.`

`WillReturn` on a procedure. Use `WillExecute` instead.

### `E2003 Undeclared identifier` on `TMock` after a package rebuild

The DCU the compiler found is not the one you just built. Check the DCU and DCP output folders:
this package writes DCUs to `.\$(Platform)\$(Config)` and its DCP to
`$(BDSCOMMONDIR)\Dcp\$(Platform)` (Release) or `…\$(Platform)\$(Config)` (Debug). A stale
`VSoft.DelphiMocksR.dcp` in the **root** `Dcp` folder shadows the platform-split one for **Win32
builds only** — the root folder is on the compiler search path and `Dcp\Win32` is not, so a
Win32-format leftover wins while Win64 falls through. Check the root folder's date before
believing the error.

### `F2039 Could not create output file …\VSoft.DelphiMocksR370.bpl`

The IDE has the package loaded. The compile itself succeeded — this is a file lock, not a code
error. Close `bds.exe` or untick the package, and **never pass `clean` in that state**:
`CleanOutputs` deletes the `.dcp` first and only then finds it cannot delete the loaded `.bpl`,
leaving the DCP gone and unregenerable until the IDE closes.

### The test project will not build: `DUnitX was not found at '…'`

Exactly what it says. Clone `gllDUnitX` as a sibling of this repository, or set the `DUNITX`
property or environment variable to its `Source` folder. The check is `CheckDUnitX`, which runs
before `Build` and looks for `DUnitX.TestFramework.pas`.

### Odd behaviour immediately after a RAD Studio update

Suspect `Delphi.Mocks.ReturnTypePatch.pas` first. It shadow-declares private `System.Rtti` fields,
so a field reordering by Embarcadero breaks it **silently** rather than with a compile error.

### A mock of a class frees an instance you still own

Known and deliberate: `Delphi.Mocks.ObjectProxy.pas` frees the wrapped instance unconditionally,
even when you supplied it through `TMock<T>.Create( ACreateObjectFunc )`. Do not free it yourself
as well.

---

## 8. Dependencies

The runtime package requires **`rtl` only**. There is nothing to acquire, no VCL dependency, and
no third-party code in `Source\`.

The **test** project needs a sibling `gllDUnitX` checkout — source, not a package. That is the
only external dependency in the repository, and it is a test-time one.
