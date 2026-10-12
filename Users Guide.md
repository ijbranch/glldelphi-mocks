# Users Guide — glldelphi-mocks

This is the **narrative** document: how to get the library into a test project and how to write
tests with it, one task at a time, simplest first. For a member, an exception message or a failure
by symptom, go to [Help.md](Help.md) instead.

What it is for, in one sentence: when the thing you want to test depends on something awkward — a
database, a service, a component you cannot easily construct — you hand it a **mock** instead, say
in advance what the mock should do, and afterwards check that it was used the way you said it
would be.

Everything is built on **RTTI**, which is why an interface you want to mock must be compiled with
`{$M+}` and carry a GUID. That is the one thing to get right before anything else works.

---

## 1. Get it into a project

There are two ways, and they suit different situations.

### By source path — what the test project here does, and the simpler option

Add `D:\glldelphi-mocks\Source` to the project's unit search path and `uses Delphi.Mocks`. Nothing
to install, nothing to build first, and a change to the library is picked up by your next build.

This is what `Tests\Delphi.Mocks.Tests.dproj` does:

```xml
<DCC_UnitSearchPath>..\Source;$(DUNITX);$(DCC_UnitSearchPath)</DCC_UnitSearchPath>
```

### By package — when several projects share it

Build `packages\RAD Studio 13.0\VSoft.DelphiMocksR.dproj` in **all four modes** (Win32 + Win64 ×
Debug + Release). It is a **runtime** package (`{$RUNONLY}`) requiring `rtl` alone, so there is
nothing to install into the IDE — a design-time install is neither needed nor possible.

On RAD Studio 37.0 the output is `VSoft.DelphiMocksR370.bpl`; Release goes to
`$(BDSCOMMONDIR)\Bpl\Win64` and Debug to `…\Bpl\Win64\Debug`. Then put
`$(BDSCOMMONDIR)\Dcp\$(Platform)` on the consuming project's search path as usual, or link the
package with **Project > Options > Packages > Runtime packages**.

### Whichever you choose, you also need DUnitX

The library does not depend on a test framework — but the tests you write with it do, and the
example code in this guide is DUnitX. The estate's DUnitX is the `gllDUnitX` fork, consumed as
**source from a sibling checkout**. The test project here declares it:

```xml
<DUNITX Condition="'$(DUNITX)'==''">..\..\gllDUnitX\Source</DUNITX>
```

and refuses to build without it:

> `DUnitX was not found at '<path>'. Clone https://github.com/ijbranch/gllDUnitX as a sibling of
> this repository, or set the DUNITX property or environment variable to its Source folder.`

---

## 2. Prepare the interface you want to mock

This step is not optional and there is no way round it:

```pascal
{$M+}
  ISimpleInterface = interface
    ['{4131D033-2D80-42B8-AAA1-3C2DF0AC3BBD}']
    procedure SimpleMethod;
  end;
{$M-}
```

- **`{$M+}`** emits the RTTI the proxy needs. Without it every `TMock<ISimpleInterface>.Create`
  fails with `ISimpleInterface does not have RTTI, specify {$M+} for the interface to enabled
  RTTI`.
- **The GUID** is needed because the proxy resolves the interface through `QueryInterface`.

Mocking a **class** works the same way — `{$M+}` around the declaration, and the methods you
intend to mock must be `virtual`:

```pascal
{$M+}
  TSimpleMockedObject = class( TObject )
  public
    procedure SimpleMethod; virtual;
  end;
{$M-}
```

The class must also have a `Create` constructor, or you get
`Could not find constructor Create on type <T>`. A class with no virtual method at all is refused
with `<T> declares no virtual methods, so there is nothing a mock can intercept`. Destructors and
overrides of `AfterConstruction`, `BeforeDestruction` and `FreeInstance` are never intercepted —
they always run the class's own code.

---

## 3. The smallest test that works

Taken from `Examples\Delphi.Mocks.Examples.Interfaces.pas`, which is a complete compiling unit.

```pascal
uses
  SysUtils,
  Delphi.Mocks;

procedure TMockObjectTests.Simple_Interface_Mock;
var
  mock      : TMock<TSimpleInterface>;
  sutObject : TSystemUnderTestInf;
begin
  // SETUP: a mock of the interface our system under test requires.
  mock := TMock<TSimpleInterface>.Create;

  // SETUP: say that SimpleMethod must be called at least once.
  mock.Setup.Expect.AtLeastOnce.When.SimpleMethod;

  // SETUP: build the system under test on the mock's instance.
  sutObject := TSystemUnderTest.Create( mock.Instance );

  // TEST
  sutObject.CallsSimpleInterfaceMethod;

  // VERIFY: the expectation was met.
  mock.Verify( 'CallsSimpleInterfaceMethod should call SimpleMethod' );
end;
```

Four steps, and they are the shape of every test you will write with this library:

1. **`TMock<T>.Create`** — build the mock.
2. **`mock.Setup…`** — say what it should do and what you expect of it.
3. **`mock.Instance`** — hand it to the system under test, and exercise that.
4. **`mock.Verify`** — fail the test if an expectation was not met.

`TMock<T>` is a **record**, not a class, so there is nothing to free and no `try..finally` around
it. That is deliberate: the `Implicit` operator lets it stand in for a `T` without anything
holding a reference to the mock outside the record.

---

## 4. Read the grammar

Every setup line reads the same way:

```
mock.Setup . <what should happen> . When . <the call it applies to>
```

Everything before `.When` says *what*; the method call written after it says *which call*. That
is why `IWhen<T>` has exactly one member — `When: T` returns the mock typed as `T`, so the next
thing you write is an ordinary-looking method call that is in fact a description.

```pascal
mock.Setup.WillReturn( 3 ).When.SimpleFunction( 'hello' );
mock.Setup.Expect.Once.When.SimpleMethod( 42 );
```

Most setup members also have a **method-name** form that applies to *every* call of that method,
whatever the arguments:

```pascal
mock.Setup.WillReturnDefault( 'DoSomething', 'hello' );     // any arguments
mock.Setup.WillRaise( 'SimpleMethod', ESimpleException );   // any arguments, always
mock.Setup.Expect.Once( 'SimpleMethod' );                   // any arguments
```

---

## 5. Make the mock return something

```pascal
mock.Setup.WillReturn( 3 ).When.SimpleFunction( 'hello' );
```

The value is a `TValue`, so anything assignable to one works. A few variations:

| You want | Write |
|---|---|
| a value for one specific call | `WillReturn( v ).When.Method( args )` |
| a value for every other call | `WillReturnDefault( 'Method', v )` — nil or empty is allowed, and on a class mock it stops the real virtual method running |
| nil, deliberately | `WillReturnNil.When.Method( args )` |
| nil, and nil is a legitimate answer | `WillReturn( v, True ).When.Method( args )` |
| to compute the answer | `WillExecute( func ).When.Method( args )` |
| to compute it for every call | `WillExecute( 'Method', func )` |

`WillExecute` takes:

```pascal
TExecuteFunc = reference to function ( const args: TArray<TValue>;
                                       const ReturnType: TRttiType ): TValue;
```

`args` holds the arguments the mock was actually called with, and `ReturnType` is passed in so
you can return something of the right type. If the method returns a value, your function must
return one.

**`WillReturn` on a procedure is an error**, not a no-op:
`Setup.WillReturn called on [<kind>] method [<M>] which does not have a return value.` Use
`WillExecute`.

**Where two setups overlap, the later one wins.** A general setup first and a specific one after
it reads naturally and works:

```pascal
mock.Setup.WillReturn( 0 ).When.Foo( It0.IsAny<Integer> );
mock.Setup.WillReturn( 1 ).When.Foo( 3 );   // Foo(3) returns 1, any other value 0
```

That is not an "already defines" error: only a setup that repeats an earlier one exactly — same
kind, literal arguments, equal values — is a redefinition, and a matcher-based setup never is.
Between *kinds* the order is fixed, whatever order you wrote them in: `WillRaise( 'Method', … )`,
then `WillRaise…When`, `WillExecute( 'Method', … )`, `WillExecute…When`, `WillReturn…When`, and
last the `WillReturnDefault` value.

---

## 6. Make the mock raise

```pascal
mock.Setup.WillRaise( ESimpleException, 'boom' ).When.DoSomething( 'x' );
mock.Setup.WillRaise( 'SimpleMethod', ESimpleException );   // always, any arguments
```

The method-name form **trumps every other behaviour defined for that method** — that is stated in
the source and is the intended semantic, not a quirk. It is how you test the failure path of a
dependency without being able to make the real thing fail.

The `When` form (and `WillRaiseWhen`) raises only for a call whose arguments match, and raises with
the message you gave it; any other call falls through to the next behaviour.

---

## 7. Expect calls, and verify

Behaviour says what the mock *does*. Expectations say what the test *requires*, and `Verify` is
what turns an unmet one into a failure.

| Expectation | Function form (this argument list) | Method-name form (any arguments) |
|---|---|---|
| exactly once | `Expect.Once.When.M( a )` | `Expect.Once( 'M' )` |
| not at all | `Expect.Never.When.M( a )` | `Expect.Never( 'M' )` |
| one or more | `Expect.AtLeastOnce.When.M( a )` | `Expect.AtLeastOnce( 'M' )` |
| *n* or more | `Expect.AtLeast( n ).When.M( a )` | `Expect.AtLeast( 'M', n )` |
| *n* or fewer | `Expect.AtMost( n ).When.M( a )` | `Expect.AtMost( 'M', n )` |
| between *a* and *b* | `Expect.Between( a, b ).When.M( x )` | `Expect.Between( 'M', a, b )` |
| exactly *n* | `Expect.Exactly( n ).When.M( a )` | `Expect.Exactly( 'M', n )` |

There are also two **ordering** expectations, which are what you reach for when the sequence is
the behaviour under test:

```pascal
mock.Setup.Expect.Before( 'Commit' ).When.Prepare;
mock.Setup.Expect.After( 'Open' ).When.Read;
```

The first is met when both `Prepare` and `Commit` were called and `Prepare`'s first matching call
came before `Commit`'s first call; `After` is the mirror image. The method-name forms
`Before( 'Prepare', 'Commit' )` and `After( 'Read', 'Open' )` do the same for any arguments. Order
is tracked per proxy, so it does not compare calls made on an interface added with
`Implement<I>` against calls on the main one.

The method-name and `When` forms are separate expectations: `Expect.Once( 'M' )` alongside
`Expect.Once.When.M( 1 )` is two expectations, not a clash. `Between( a, b )` with `b < a` can never
be met and raises `EMockSetupException` at setup.

Then:

```pascal
mock.Verify( 'the message shown when an expectation fails' );
```

`Verify` raises `EMockVerificationException` whose message is yours, a CRLF, and the detail. If
you would rather assert than catch, `CheckExpectations` returns the same detail as a string and
`''` when everything was satisfied:

```pascal
Assert.AreEqual( '', mock.CheckExpectations, False );
```

`VerifyAll` verifies across every interface the mock implements; `ResetCalls` forgets the calls
recorded so far, which lets one mock serve two phases of a test. `ResetCalls` and `Expect.Clear`
both reach the interfaces added with `Implement<I>` too, as `VerifyAll` does.

---

## 8. Match arguments instead of naming them

Listing literal arguments only works when you know them. `ItN` matchers describe them instead —
and they are **positional**: `It0` is parameter 0, `It1` is parameter 1.

```pascal
mock.Setup.Expect.Once.When.SimpleMethod( It0.IsAny<Integer>, It1.IsAny<String> );
mock.Setup.WillReturn( 3 ).When.SimpleFunction( It0.IsEqualTo<String>( 'hello' ) );
```

The full matcher list is in [Help.md](Help.md#parameter-matchers--itrec-and-it0--it9). The ones
worth knowing early:

| Matcher | Use for |
|---|---|
| `IsAny<T>` | "I do not care what was passed" |
| `IsEqualTo<T>( v )` | a specific value, optionally with your own `IEqualityComparer<T>` |
| `Matches<T>( predicate )` | anything you can express as a `TPredicate<T>` |
| `IsInRange<T>( a, b )` | an inclusive range, in `TComparer<T>.Default` order |
| `IsIn<T>` / `IsNotIn<T>` | membership of an array or an `IEnumerable<T>` |
| `IsRegex( pattern )` | a string parameter |
| `AreSameFieldsThat<T>` / `AreSamePropertiesThat<T>` | an object equal field-by-field or property-by-property rather than by identity |

### Two traps, both real

**Matchers are all-or-nothing per call.** Mix a matcher and a literal in the same call and the
setup raises `EMockSetupException` —
`Setup of [<Method>] used matchers for <n> of its <m> parameters. Use a matcher (It0..It9) for every parameter, or for none.`
This holds for behaviour and expectation setups alike. Wrap the literal:

```pascal
// wrong
mock.Setup.Expect.Once.When.M( It0.IsAny<Integer>, 'literal' );
// right
mock.Setup.Expect.Once.When.M( It0.IsAny<Integer>, It1.IsEqualTo<string>( 'literal' ) );
```

**Each `ItN` once per setup, numbered by position.** Using the same index twice — `It0` copied
onto the second parameter — raises `EMockSetupException`:
`A matcher was already given for parameter 0. …`. A matcher evaluated anywhere other than inside
a `When` call is discarded at the next ordinary call, so it cannot leak into a later setup.

Upstream had a third trap here — two `Never.When.ExtendedMethod( It0.IsAny<…> )` setups for
different classes failing on the second line as an "already defined" behaviour. **This fork
accepts both**: a matcher-based setup is never a redefinition. `IsAny<T>` still returns `nil` for a
class, and `IsNotNil<T>` is still the matcher to use when a nil argument must not match:

```pascal
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsNotNil<TMyClass> );
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsNotNil<TMyOtherClass> );
```

**How literal arguments compare.** Strings ordinally (case matters), floats exactly, records
without an `=` operator field by field, interfaces by COM identity; sets, pointers, class
references and method pointers by value. The full list is in [Help.md](Help.md#how-literal-arguments-are-compared).

---

## 9. Use a stub when you do not want a test to fail

`TStub<T>` is `TMock<T>` with verification removed. It answers calls and records nothing you can
assert on. Reach for it when a dependency has to be *present* but is not what the test is about.

From `Tests\Delphi.Mocks.Tests.Stubs.pas`, complete and compiling:

```pascal
procedure TStubTests.Test_WillReturnDefault;
var
  stub   : TStub<ITestable>;
  intf   : ITestable;
  actual : string;
begin
  stub := TStub<ITestable>.Create;
  stub.Setup.WillReturnDefault( 'DoSomething', 'hello' );
  intf := stub.Instance;
  actual := intf.DoSomething( 'world' );
  Assert.AreEqual( 'hello', actual );
end;
```

A stub can also wrap a real class you did not write, as long as the methods are virtual:

```pascal
procedure TStubTests.Test_CanStubInheritedMethods;
var
  stub : TStub<TStringList>;
begin
  stub := TStub<TStringList>.Create;
  stub.Setup.BehaviorMustBeDefined := False;
  stub.Setup.WillReturnDefault( 'Add', 7 );
  // the real Add on an empty list returns 0 and adds a line; the stub must do neither
  Assert.AreEqual( 7, stub.Instance.Add( '2' ) );
  Assert.AreEqual( 0, stub.Instance.Count );
end;
```

**`BehaviorMustBeDefined`** is the switch to know about. Leave it true and any call to a method
you did not set up makes `Verify` fail — strict, and useful when you want to know exactly what the
system under test touches. Set it false and unconfigured calls are tolerated.

---

## 10. One mock, several interfaces

When the system under test asks a single collaborator for two interfaces:

```pascal
mock.Implement<IAlso>;
mock.Setup<IAlso>.WillReturn( 1 ).When.Something;
...
sut := TSystemUnderTest.Create( mock.Instance, mock.Instance<IAlso> );
...
mock.VerifyAll;
```

`Implement<I>` twice for the same interface raises `EMockProxyAlreadyImplemented` —
`The mock already implements <I>`. Only a mock of an **interface** can implement further
interfaces: on a mock of a class, `Implement<I>` raises `ENotSupportedException` naming both
types. `Verify<I>` for an `I` never added raises `EMockNoProxyException`.

When there are simply **many** dependencies, `TAutoMockContainer` creates and owns them for you:

```pascal
var container := TAutoMockContainer.Create;
var mockA := container.Mock<IA>;
var mockB := container.Mock<IB>;
```

A mock the container created also answers a method that returns an **interface**, when nothing is
set up for that call, with a mock of that interface — the same instance for the same arguments.
Classes and records are not auto mocked. A container used before `Create` raises `EMockException`.

---

## 11. Practical notes

### Two DUnitX defaults will let a mock test pass when it should not

Both are in the `gllDUnitX` fork and neither is visible at the call site.

**`Assert.AreEqual( string, string )` ignores case.** `fIgnoreCaseDefault` is `True`, and the
two-argument string overload forwards it, so `Assert.AreEqual( 'hello', actual )` passes for
`'HELLO'`. `StartsWith`, `EndsWith`, `Contains` and `AreNotEqual` share the default. When the
casing is the point — and with a mock returning a canned string it often is — pass `False`:

```pascal
Assert.AreEqual( 'hello', actual, False );
```

`Tests\Delphi.Mocks.Tests.dpr` sets `Assert.IgnoreCaseDefault := False`, so in this suite
`Test_WillReturnDefault` above does compare case-sensitively. A suite of your own carries the weak
default unless its `.dpr` does the same.

**`Assert.WillNotRaise( proc, SomeClass, msg )` swallows everything that is not exactly that
class.** The fork's body is `if e.ClassType = exceptionClass then Fail` — an `=` on `ClassType`,
not an `is` — so passing a class means the assertion fails only on that exact class and does
*nothing* for any other exception, `EAccessViolation` included. The test then passes while the
fault it was written to catch happens on every run.

Use **`Assert.WillNotRaiseAny( proc, msg )`** when the point is "this must not blow up", which is
almost always what it is. `Assert.WillNotRaiseDescendant` covers the narrower case, and passing
**no** class is also safe because that takes the `else` branch and fails on anything.

### Lifetime

`TMock<T>` and `TStub<T>` are **records**. Nothing needs freeing and there is no `try..finally`
around them. `Free` exists on both, but the source's own comment beside it reads "Not sure if we
really need this." Calling it twice is harmless; any other use of the record before `Create` or
after `Free` raises `EMockException` — `TMock<T> was used before Create, or after Free.`

If the system under test keeps the mocked instance and calls it after the mock has been released,
the call raises `EMockException` — `[<T>].<M> was called after the mock that created it was
freed.` — rather than an access violation. Keep the mock alive as long as the instance is used.

The one place ownership is not what you expect: **a mock of a class frees the wrapped instance
unconditionally**, even when you supplied it through `TMock<T>.Create( ACreateObjectFunc )`. Do
not free it yourself as well. This is deliberate and left alone — changing it would be an
ownership-contract change.

### After a RAD Studio update, suspect `ReturnTypePatch` first

`Source\Delphi.Mocks.ReturnTypePatch.pas` shadow-declares private `System.Rtti` fields in order to
patch RTTI. The layout still matches RAD Studio 37.0, but if Embarcadero reorders those fields it
**breaks silently** — no compile error, wrong behaviour.

### Run the tests

Build `Tests\Delphi.Mocks.Tests.dproj` and run the executable. It is a DUnitX console runner that
sets `runner.UseRTTI := True` **and** the fixtures also register themselves explicitly with
`TDUnitX.RegisterTestFixture` — 21 `[TestFixture]` attributes across 19 units, and 23 explicit
registrations. **Keep both mechanisms.** Turning `UseRTTI` off does not prevent a double run — our
fork dedupes a fixture registered both ways — it silently *deletes* the fixtures that have only the
attribute.

The runner sets `runner.FailsOnNoAsserts := False` and exits `EXIT_ERRORS` when anything failed,
so the process exit code is usable in a pipeline. Pass an XML output file through DUnitX's own
options to get an NUnit-format report.

### Run the examples

`Examples\Sample1.dproj` is a console program that runs every example unit — `Factory`,
`Implement`, `Interfaces`, `Matchers` and `Objects` — and each checks its own result. It pauses on
`ReadLn` at the end; pass any command-line parameter to skip the pauses and run it unattended. A
failure prints the exception and exits 1.

---

## 12. Where to go next

| You want | Read |
|---|---|
| a member, an exception message, or a symptom | [Help.md](Help.md) |
| upstream's description and the full matcher list | [README.md](README.md) |
| what this fork fixed, and what it refused from upstream | [CHANGELOG.md](CHANGELOG.md) |
| worked examples that compile | `Examples\` and `Tests\` |
