# Help — glldelphi-mocks

`glldelphi-mocks` is the GITLAK fork of **Delphi Mocks**, Vincent Parrett's RTTI-based mocking
framework. You write test code against it: `TMock<T>` and `TStub<T>` build a stand-in for an
interface or a class, you say what it should do, and you verify afterwards that it was used the
way you said it would be.

Target: **Delphi 13 / RAD Studio 37.0**, VCL-free (the runtime package requires `rtl` only),
**Win32 + Win64** declared on every project. `Source\Delphi.Mocks.inc` refuses to compile on
anything older (`CompilerVersion < 37.0`: "Delphi 13 or later required!"). Apache-2.0, upstream copyright retained.

This file is the **lookup** document: the public surface unit by unit, the exception messages,
and the failures by symptom. For a walked-through first test, read
[Users Guide.md](Users%20Guide.md). Upstream's own description and the parameter-matcher list
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
| `InstanceAsValue<I>` | `function InstanceAsValue<I: IInterface>: TValue` | The additional interface's instance boxed as a `TValue`. |
| `Implement<I>` | `procedure Implement<I: IInterface>` | Make one mock implement a second interface. A mock of an **interface** only: on a mock of a class it raises `ENotSupportedException`. |
| `Verify` | `procedure Verify( const message: string = '' )` | Raise `EMockVerificationException` if any expectation was not met. |
| `Verify<I>` | `procedure Verify<I: IInterface>( const message: string = '' )` | The same, for an implemented interface. Raises `EMockNoProxyException` if the mock does not implement `I`. |
| `VerifyAll` | `procedure VerifyAll( const message: string = '' )` | Verify across every interface the mock implements. |
| `CheckExpectations` | `function CheckExpectations: string` | The failure text `Verify` would raise, or `''`. Use it to assert without an exception. |
| `ResetCalls` | `procedure ResetCalls` | Forget the calls recorded so far — on the mock and on every interface added with `Implement<I>`. |
| `Free` | `procedure Free` | Explicit cleanup; calling it twice is harmless. Any other use afterwards (or before `Create`) raises `EMockException`. The comment in the source says "Not sure if we really need this." |
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

As with `TMock<T>`, using a stub before `Create` or after `Free` raises `EMockException`.

### `IStubSetup<T>` — declaring behaviour

Available on both `TStub<T>.Setup` and `TMock<T>.Setup`.

| Member | Effect |
|---|---|
| `WillReturn( const value: TValue ): IWhen<T>` | Return `value` for the call described by the following `.When`. |
| `WillReturn( const value: TValue; const AllowNil: Boolean ): IWhen<T>` | The same, stating whether a nil return is legitimate. |
| `WillReturnNil: IWhen<T>` | Return nil for the call described by the following `.When`. |
| `WillReturnDefault( const AMethodName: string; const value: TValue )` | The value returned when the method is called with arguments you did **not** describe. A nil or empty value is allowed. On a class mock it also stops the real virtual method running. |
| `WillExecute( const func: TExecuteFunc ): IWhen<T>` | Run `func` for the call described by the following `.When`. |
| `WillExecute( const AMethodName: string; const func: TExecuteFunc )` | Run `func` for **every** call to that method, whatever the arguments. |
| `WillRaise( const exceptionClass: ExceptClass; const message: string = '' ): IWhen<T>` | Raise for **every** call of the method named by the following `.When`, whatever its arguments: the `When` call's arguments only name the method. Use `WillRaiseWhen` to raise for particular arguments. A nil class raises `EMockSetupException`. |
| `WillRaise( const AMethodName: string; const exceptionClass: ExceptClass; const message: string = '' )` | Always raise for that method. **This trumps any other behaviour defined for it.** |
| `WillRaiseWhen( const exceptionClass: ExceptClass; const message: string = '' ): IWhen<T>` | Raise for the call described by the following `.When`: only a call whose arguments match. A nil class raises `EMockSetupException`. |
| `BehaviorMustBeDefined: Boolean` | When true, a call to a method with no behaviour, default or expectation raises `EMockException` **at the call** ( it does not make `Verify` fail, so code under test that catches exceptions hides it ). Applies to auto mocked mocks too, except for an interface result the container supplies, and a change applies to methods already used. |
| `AllowRedefineBehaviorDefinitions: Boolean` | When true, a behaviour may be defined a second time for the same call. A change applies to methods already used. |

`WillRaise` and `WillRaiseWhen` raise with **your** message, through the exception class's own
`Create( const Msg: string )` constructor when it declares one, so a descendant's constructor runs.

**Setups by method name** ( `WillReturnDefault( 'Foo', … )`, `Expect.Once( 'Foo' )`, `Before( 'Foo', 'Bar' )`
and the rest ) check the name against the mocked type, case-insensitively, and raise `EMockSetupException`
for a name it does not have: an expectation on a misspelt or renamed method could otherwise never fail. They
also raise `EMockSetupException` when a `When` setup is still pending ( its `Setup` reference held in a
variable and `When` never called ), rather than silently discarding it. A name stands for **every overload**
of that name: `Expect.Once( 'Foo' )` counts `Foo( Integer )` and `Foo( Boolean )` alike. The `When` forms
tell overloads apart ( see *How literal arguments are compared* ).

**Which behaviour answers a call.** The behaviour *types* are tried in a fixed order: `WillRaise`
for the method (always), then `WillRaise…When`, `WillExecute` for the method, `WillExecute…When`,
`WillReturn…When`, and finally the `WillReturnDefault` value. Within one type, where definitions
overlap, the **most recently defined** one wins:

```pascal
mock.Setup.WillReturn( 0 ).When.Foo( It0.IsAny<Integer> );
mock.Setup.WillReturn( 1 ).When.Foo( 3 );   // Foo(3) returns 1, any other value 0
```

A setup counts as a *redefinition* (the `already defines` error) only when it repeats an earlier
definition: same type, no matchers on either, and equal arguments. A matcher-based setup is never
a redefinition.

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
| — | `Clear` | discard the expectations recorded so far — on the mock and on every interface added with `Implement<I>` |

- **Ordering.** `Before( 'X' ).When.M` / `Before( 'M', 'X' )` is met when both methods were called
  and M's first (matching) call came before X's first call; `After` is met when it came after. The
  order is tracked per proxy, so it does not compare calls across interfaces added with
  `Implement<I>`.
- **`Between( a, b )` with `b < a`** can never be met and raises `EMockSetupException` at setup.
- **The two forms are separate kinds.** `Once( 'M' )` and `Once.When.M( … )` on the same method do
  not collide, and likewise for `Never`, `AtLeast`, `AtMost`, `Between` and `Exactly`.

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

Matchers are **all or none**: once one parameter of a setup uses a matcher, every parameter must,
or the setup raises `EMockSetupException` — behaviour and expectation setups alike. Each index may
be used once per setup; a second matcher for the same index raises `EMockSetupException`, as does a negative
index ( `It( -1 )` ). A matcher evaluated outside a `When` is discarded at the next ordinary call made while no
setup is pending on that thread, and the matchers of a setup that is abandoned ( its `When` arguments raised, or
the call never came ) are discarded with it, so neither can attach itself to the next setup. A call on another
mock made while a `When`'s arguments are evaluated, after the setup began, leaves the matchers already given
alone. ( Nothing is cleared when a setup begins: on Win32 the arguments passed on the stack are evaluated before
the `Setup` chain, so a call on another mock evaluated there too, such as in `WillReturn`'s own argument, still
clears matchers registered before it. Take such a value into a variable first. )

| Matcher | Matches |
|---|---|
| `IsAny<T>: T` | anything |
| `Matches<T>( const predicate: TPredicate<T> ): T` | whatever your predicate accepts |
| `IsNotNil<T>: T` | any non-nil value |
| `IsNotNil<T>( const comparer: IEqualityComparer<T> ): T` | the same, with your comparer |
| `IsEqualTo<T>( const value: T ): T` | that value |
| `IsEqualTo<T>( const value: T; const comparer: IEqualityComparer<T> ): T` | that value, by your comparer |
| `IsInRange<T>( const fromValue, toValue: T ): T` | a value in the closed range, ordered by `TComparer<T>.Default` |
| `IsIn<T>( const values: TArray<T> ): T` | membership of an array |
| `IsIn<T>( const values: TArray<T>; const comparer: IEqualityComparer<T> ): T` | the same, with your comparer |
| `IsIn<T>( const values: IEnumerable<T> ): T` | membership of an enumerable |
| `IsIn<T>( const values: IEnumerable<T>; const comparer: IEqualityComparer<T> ): T` | the same, with your comparer |
| `IsNotIn<T>` | the four `IsIn` overloads, negated |
| `IsRegex( const regex: string; const options: TRegExOptions = [] ): string` | a string matching the pattern |
| `AreSamePropertiesThat<T>( const Value: T ): T` | an instance whose readable **public and published properties** all compare equal |
| `AreSameFieldsThat<T>( const Value: T ): T` | an instance whose **public and published fields** all compare equal |
| `AreSameFieldsAndPropertiedThat<T>( const Value: T ): T` | both. The spelling is upstream's and is part of the API. |

The three `AreSame…` matchers compare **public and published members only**, and an object member by its
runtime class: instances of different classes never match, and a descendant's own members are compared too. A
class mock's `Instance` counts as an instance of its own class ( the interception's generated class is seen
through ).
For a class or record with nothing public or published to compare they raise `EMockSetupException` at setup:
comparing nothing, they used to accept any instance. A class that keeps its state private needs a
`Matches<T>` predicate instead.

`IsEqualTo`, `IsIn`, `IsNotIn` and `IsNotNil` without a comparer compare records, arrays and interfaces as a
literal argument is ( below ), not by their bytes or references.

### How literal arguments are compared

When a setup names literal arguments rather than matchers, a call matches when each argument
compares equal (`Delphi.Mocks.Helpers.pas`):

- **of the same type**: an argument of another parameter type never matches, so `WillReturn( 5 ).When.Foo( 1 )`
  does not answer `Foo( True )` when `Foo( Integer )` and `Foo( Boolean )` are overloads ( arrays excepted, as
  a kept array is stored in a form of its own );
- **strings** ordinally (`CompareStr`), so case and every character count;
- **floats** exactly — no tolerance; **NaN equals NaN**, so a setup made with NaN matches a call with NaN;
- **records** with an `=` operator taking two of the record by that operator, otherwise **field by field**;
- **sets, pointers, class references** by value; **method pointers** by code, then instance;
- **interfaces** by COM identity (the `IInterface` of the object), so two interface references to
  the same object compare equal;
- **Variants / OleVariants**: a string only with a string, ordinally ( `'1'` does not match `1` ); otherwise
  by `VarCompareValue`; two that cannot be compared are simply unequal.

### `TAutoMockContainer`

| Member | Signature |
|---|---|
| `Create` | `class function Create: TAutoMockContainer; static` |
| `Mock<T>` | `function Mock<T>: TMock<T>` |
| `Mock` | `function Mock( const ATypeInfo: PTypeInfo ): IProxy` |

A container that creates and owns mocks on demand, so a system under test with many dependencies
does not need one variable per dependency. Using a container before `Create` raises
`EMockException`.

Auto mocking covers **interfaces only**: on a mock the container created, a method that returns an
interface and has no behaviour set up for the call returns a mock of that interface — the same
instance when it is called again with the same arguments. Classes and records are not auto mocked
(they get the `WillReturnDefault` value), and `Mock( ATypeInfo )` on a non-interface raises
`EMockException`.

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

### `EMockNoRTTIException` — `Delphi.Mocks.Validation.pas`, `Delphi.Mocks.pas`

| Message | Cause |
|---|---|
| `<T> does not have RTTI, specify {$M+} for the interface to enabled RTTI` | the interface is not compiled with `{$M+}` |
| `<T> declares no virtual methods, so there is nothing a mock can intercept` | the class has no virtual method to intercept (`TStub<T>` says `… nothing a stub can intercept`) |

(The interface wording is upstream's, typo included.)

### `EMockException` — `Delphi.Mocks.pas`, `.Validation.pas`, `.ObjectProxy.pas`, `.MethodData.pas`, `.Proxy*.pas`, `.AutoMock.pas`

| Message | Cause |
|---|---|
| `<T> is not an Interface or Class. TMock<T> supports interfaces and classes only` | `T` is a record, an enum, … |
| `Invalid type kind T` | the type kind is neither interface nor class |
| `Could not find constructor Create on type <T>` | mocking a class with no `Create` |
| `TMock<T> was used before Create, or after Free.` | a `TMock<T>` used before `Create` or after `Free` (`TStub<T>` says `TStub<T> …`) |
| `TAutoMockContainer was used before Create.` | a container used before `Create` |
| `[<T>].<M> was called after the mock that created it was freed.` | the system under test kept the mocked instance and called it after the mock was released |
| `The auto mocked [<T>] cannot implement [<I>]` | `AddImplement` on an auto mocked interface ( an internal path; nothing public reaches it ) |
| `<T> is not an interface. Auto mocking supports interfaces only` | `TAutoMockContainer.Mock( ATypeInfo )` on a class or record |
| `[<T>] has no behaviour or expectation defined for method [<M>]` | the method was called and nothing was set up for it |
| `[<T>] has no default return value or return type was defined for method [<M>]` | a function was called with no `WillReturn`/`WillReturnDefault` |
| `[<T>] already defines Expectation <Kind> for method [<M>]` | the same expectation kind declared twice — `Once`, `Never`, `Exactly`, `At Least`, `At Most`, `Between`, and the `When` variants of each. The method-name and `When` forms are separate kinds, and a matcher-based `When` is never a redefinition |

### `EMockSetupException` — `Delphi.Mocks.Proxy.pas`, `.ParamMatcher.pas`, `.MethodData.pas`

| Message | Cause |
|---|---|
| `Setup of [<Method>] used matchers for <n> of its <m> parameters. Use a matcher (It0..It9) for every parameter, or for none.` | some parameters used `ItN` matchers and some did not. **Use matchers on every parameter or on none.** |
| `Setup of [<Method>] used matchers for some parameters but not others. Use a matcher (It0..It9) for every parameter, or for none.` | the same, where the count happened to agree but an index was skipped |
| `A matcher was already given for parameter <n>. Use It0 for the first parameter, It1 for the second and so on, once each.` | the same `ItN` used twice in one setup |
| `Setup called on non-virtual method: the method named after When never reached the mock, because it is not virtual, the mock answers it itself (QueryInterface, _AddRef, _Release), or, on a class mock, it is a method TObject declares and the class does not override (ToString, Equals, GetHashCode and the rest) or a construction or destruction method` | a setup was begun and the call after `.When` never arrived; also a setup by method name made while a `When` setup is pending |
| `[<T>] has no method named [<M>]` | a setup by method name ( or the other method of `Before` / `After` ) names a method the type does not have |
| `WillRaise needs an exception class: nil would make the call return a default instead of raising` | `WillRaise( nil )` or `WillRaiseWhen( nil )` |
| `<Matcher><<T>> has nothing to compare: <Matcher> compares public and published members only, and <T> has none, so any instance would match.` | `AreSameFieldsThat`, `AreSamePropertiesThat` or `AreSameFieldsAndPropertiedThat` on a type with nothing public or published of that kind |
| `It(<n>) is not a parameter: use It0 for the first parameter, It1 for the second and so on.` | a negative matcher index |
| `Setup.WillReturn called on [<kind>] method [<Method>] which does not have a return value.` | `WillReturn` on a procedure |
| `Setup.WillReturn call on method [<Method>] was not passed a return value.` | `WillReturn` with nothing to return |
| `[<T>] Between(<a>, <b>) for method [<M>] can never be met: the maximum is less than the minimum.` | `Between` with `b < a` |
| `[<T>] already defines Will Return When for method [<M>]` | the same argument list set up twice, without matchers — also `Will Return Default`, `WillExecute`, `WillExecute When`, `Will Raise Always`, `Will Raise When` |

### `EMockNoProxyException` — `Delphi.Mocks.pas`, `.Proxy*.pas`, `.AutoMock.pas`

| Message |
|---|
| `Error casting to interface [<T>], proxy does not appear to implement T` |
| `Error - No Proxy of type [<T>] was found.` |
| `Error casting to interface <T> , proxy does not appear to implement IProxy` |
| `The mock does not implement [<I>], so it has nothing to verify for it.` — `Verify<I>` for an `I` never added with `Implement<I>` |

### `EMockProxyAlreadyImplemented`

`The mock already implements <T>` — `Implement<I>` called twice for the same interface.

### `ENotSupportedException` — `Delphi.Mocks.pas`

`Implement<I> is not supported on a mock of the class <T>; only a mock of an interface can implement
further interfaces.` — `Implement<I>` on a mock of a class.

### `EMockVerificationException`

Raised by `Verify` / `VerifyAll`. The message is **your** message and a CRLF ( both left out when your message
is empty ), then `[<T>] has unmet expectations:` naming the mocked type, a CRLF, and the text
`CheckExpectations` produced, methods in name order, string arguments quoted ( `( '' )` for an empty string ). If you want the detail without an exception, call
`CheckExpectations` yourself — it returns `''` when everything was satisfied.

---

## 4. Scope of this fork

`origin` is `https://github.com/ijbranch/glldelphi-mocks.git`; `upstream` is
[`VSoftTechnologies/Delphi-Mocks`](https://github.com/VSoftTechnologies/Delphi-Mocks) and is kept
as a remote. **There is shared history** — `git merge-base HEAD upstream/master` resolves — so
ancestry comparisons are meaningful here. At the last fetch in this checkout the fork was **15
commits ahead and 0 behind** both `upstream/master` and `upstream/Development` (re-measured
2026-10-13 against the same, unfetched tracking refs: 23 ahead / 1 behind `upstream/master`,
112 ahead / 0 behind `upstream/Development`).

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
| **Mocks were not safe across threads** — `Delphi.Mocks.Proxy.pas`, `.MethodData.pas`, `.Utils.pas` | four threads making 40,000 calls lost 512 of them, and a call from another thread could complete a pending setup. A shared lock now guards the bookkeeping only, and a setup belongs to its thread. |
| **`AreSameFieldsThat` matched any instance of a class with private fields** — `Delphi.Mocks.pas` | it compared nothing and answered equal; objects of different classes compared equal too. |
| **A class mock of a `TInterfacedObject` descendant was freed twice** — `Delphi.Mocks.ObjectProxy.pas` | the code under test releasing an interface freed it, and the mock freed it again. |
| **Matchers from a failed setup attached to the next one; a call on another mock in a `When` lost them** — `Delphi.Mocks.ParamMatcher.pas`, `.Proxy.pas` | a later literal setup answered calls it was never set up for, or a valid setup was refused. |
| **Overloads answered each other's setups; settings changed after first use were ignored; `IsEqualTo` compared records by bytes; NaN never matched** — `Delphi.Mocks.Helpers.pas`, `.MethodData.pas`, `.pas` | see `CHANGELOG.md`, 2026-11-21, for these and the smaller fixes of the same review. |
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
  RTTI. The layout still matches RAD Studio 37.0. If Embarcadero reorders them it no longer breaks
  silently (since 2026-10-02): `Tests\Delphi.Mocks.Tests.ReturnTypePatch.pas` goes red
  (mutation-proved). It is the first thing to suspect after a RAD Studio update. `PatchMethodReturnType`
  now reads the patched return type back and raises `EOSError` (`PatchMethodReturnType could not
  patch <M>: System.Rtti's layout has changed`) when the write fails or does not take, and
  `EArgumentException` for a type or method that is not an interface's; method names match
  case-insensitively.
- **Open array arguments match by length only, from the second call of a method on (a `System.Rtti` defect,
  RAD Studio 37.0).**  `TMethodImplementation.TInvokeInfo.LoadArguments` writes each call's open array type
  information into the method's shared, cached `FParams` (`GetOpenArrayArg` assigns `FTypeInfo`), and `Intercept`
  frees it when the call returns.  The next call of that method, on any mock in the process, reads the element
  type from the freed block: the argument then arrives with its length but no elements, so `[1, 3]` matches a
  setup for `[1, 2]`.  The old memory manager left the freed block intact, which hid it; FastMM5 does not.
  `TestOpenArraySetupsMatchByContents` and `TestOpenArrayExpectationMatchesByContents` are ignored as BUG tests
  until a GITLAKRTL `System.Rtti` patch, which Ian decides on ( `Tests\README.md` ).
- **`Delphi.Mocks.ObjectProxy.pas` frees the wrapped instance unconditionally**, even when the
  caller supplied it. Changing that is an ownership-contract change, so it is left alone on
  purpose. **Except a reference-counted instance** ( a `TInterfacedObject` descendant, since 2026-11-21 ): the
  mock holds an interface reference to it, so the code under test taking and releasing an interface no longer
  frees it under the mock ( which then freed it again ). When the mock goes, the instance is freed with the
  mock's reference, or, if the code under test still holds one, handed back to its own class and left to that
  reference.
- **A `WillExecute` function that captures its own `TMock` variable makes a reference cycle**: the mock holds
  the function and the function holds the mock, so neither is ever freed ( FastMM5 reports it ). Capture
  `mock.Instance` instead, or call `mock.Free` when the test is done with it, which breaks the cycle
  ( `TReviewTests.WillExecute_Capturing_Its_Mock_Is_Released_By_Free` ).
- **Threads.** The code under test may call mocks from several threads at once: each call's bookkeeping ( the
  call log, the expectation counts, the behaviour search ), a setup's completion, `Verify` and interface queries
  take one lock that all mocks share, so every call is counted. The behaviour itself ( a `WillExecute` function,
  an exception's constructor, an auto mock ) runs **outside** the lock, so it may wait for another thread that
  calls a mock. **Matcher predicates run under the lock** ( while the behaviour and expectations are matched ):
  a `Matches<T>` predicate must not wait for such a thread. A setup belongs to the thread that began it: a call
  from another thread while it is pending is an ordinary call. Set a mock up on one thread. Measured: the suite,
  40,000 calls on four threads included, runs in the same time as before the lock ( about 0.5 s ).

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

**`Tests\Delphi.Mocks.Tests.dpr` sets `Assert.IgnoreCaseDefault := False`**, so this suite's
two-argument string assertions compare case-sensitively; a test that does not care passes `True`.
A suite of your own does not inherit that — it carries the weak default unless its `.dpr` sets it.

### `Assert.WillNotRaise( proc, SomeClass, msg )` **swallows everything else**

Our fork's body is `if e.ClassType = exceptionClass then Fail` — an `=` on `ClassType`, not an
`is`. So passing a class means the assertion fails **only** on that exact class and does nothing
at all for any other exception, including an `EAccessViolation`. The test passes while the fault
it was written to detect happens on every run.

Passing **no** class takes the `else` branch, `FailFmt( SUnexpectedException, … )`, which fails on
anything — so a bare `Assert.WillNotRaise( proc )` is safe. `Assert.WillNotRaiseAny( proc, msg )`
is the explicit form and is what new tests should use. `Assert.WillNotRaiseDescendant` exists for
the narrower case.

**This repository no longer has any `Assert.WillNotRaise` call.** The two that passed a class —
`Assert.WillNotRaise( …, EMockSetupException )` in `Tests\Delphi.Mocks.Tests.MethodData.pas` —
are gone; they would have passed had the code under test raised anything else at all. Because the
five mock exception classes all descend *directly* from `EMockException` and not from one another,
`Assert.WillNotRaise( proc, EMockException )` does not even catch an `EMockSetupException`.

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
output standard, one plain value per property group (no `Condition=` on the property, so an IDE
re-save keeps both):

```xml
<!-- Base group -->
<DCC_BplOutput>$(BDSCOMMONDIR)\Bpl\$(Platform)\$(Config)</DCC_BplOutput>
<DCC_DcpOutput>$(BDSCOMMONDIR)\Dcp\$(Platform)\$(Config)</DCC_DcpOutput>
<!-- Release (Cfg_2) group -->
<DCC_BplOutput>$(BDSCOMMONDIR)\Bpl\$(Platform)</DCC_BplOutput>
<DCC_DcpOutput>$(BDSCOMMONDIR)\Dcp\$(Platform)</DCC_DcpOutput>
```

Release stays in the shared platform folder because that folder is on `PATH` and is where a
dependent package resolves its `requires`; only Debug is diverted. **An earlier attempt that
diverted Release as well broke package loading** — do not "tidy" it back.

DCUs are `.\$(Platform)\$(Config)`, project-local and split both ways.

### Using it from another project

Either put `Source\` on the project's unit search path and `uses Delphi.Mocks` ( nothing to build or install;
a library change is picked up by the next build ), or, when several projects share it, build the package in all
four modes and put `$(BDSCOMMONDIR)\Dcp\$(Platform)` on the search path, or link it as a runtime package. It is
runtime only, so there is nothing to install into the IDE.

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

The unit search path is `$(DUNITX)\Gll;..\Source;$(DUNITX)` ( `Gll` holds the fork's suite runner,
`GllDUnitX.SuiteRunner` ) — relative throughout, so a clone builds where its sibling `gllDUnitX` is. The
**source** of both the library and DUnitX is compiled into the test executable. Building the package is not a prerequisite for running the
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

### `<T> declares no virtual methods, so there is nothing a mock can intercept`

A class mock works by intercepting virtual methods, and `T` has none. Make the methods you mean to
mock `virtual`. Destructors and overrides of `AfterConstruction`, `BeforeDestruction` and
`FreeInstance` are never intercepted: they always run the class's own code.

### `Setup of [<Method>] used matchers for <n> of its <m> parameters. …`

Matchers are all-or-nothing per call. If any parameter uses `ItN`, **every** parameter must. Pass
`It1.IsEqualTo<string>( 'x' )` rather than a bare `'x'` alongside an `It0.IsAny<Integer>`. The
check applies to behaviour and expectation setups alike.

### `A matcher was already given for parameter <n>. …`

The same `ItN` was used twice in one setup — typically `It0` copied onto the second parameter.
Number them by position, once each.

### A `Never` expectation on two different classes: the second setup used to fail

Documented upstream: `IsAny<T>` returns the **default** value of `T`, which for a class is `nil`,
so upstream took the second of these setups for a redefinition of the first:

```pascal
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsAny<TMyClass> );
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsAny<TMyOtherClass> );
```

**In this fork both are accepted**: setup compares definitions, and a matcher-based setup is never
a redefinition. `IsNotNil<T>` remains the matcher to use when a nil argument must not match:

```pascal
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsNotNil<TMyClass> );
mock.Setup.Expect.Never.When.ExtendedMethod( It0.IsNotNil<TMyOtherClass> );
```

### `TMock<T> was used before Create, or after Free.`

The record was declared but never assigned from `TMock<T>.Create`, or `Free` was called on it and
it was used again. `TStub<T>` says the same with `TStub<T>`; upstream gave an access violation.

### `[<T>].<M> was called after the mock that created it was freed.`

Something kept the mocked instance — a field of the system under test, a captured reference — and
called it after the `TMock<T>` was released. Keep the mock alive for as long as the instance is used.

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
so a field reordering by Embarcadero breaks it **silently** rather than with a compile error. An
`EOSError` reading `PatchMethodReturnType could not patch <M>: System.Rtti's layout has changed`
is that breakage caught at run time.

### A mock of a class frees an instance you still own

Known and deliberate: `Delphi.Mocks.ObjectProxy.pas` frees the wrapped instance unconditionally,
even when you supplied it through `TMock<T>.Create( ACreateObjectFunc )`. Do not free it yourself
as well. A reference-counted instance ( a `TInterfacedObject` descendant ) is the exception: it is released, not
freed, so an interface reference you still hold keeps it alive.

---

## 8. Dependencies

The runtime package requires **`rtl` only**. There is nothing to acquire, no VCL dependency, and
no third-party code in `Source\`.

The **test** project needs a sibling `gllDUnitX` checkout — source, not a package. That is the
only external dependency in the repository, and it is a test-time one.

---
*Version: 1.0 – 21 November 2026 10:28*
*Version: 1.1 – 21 November 2026 11:47*
