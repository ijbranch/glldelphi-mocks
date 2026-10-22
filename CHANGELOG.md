# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [In-Service]

> Changes below are live as soon as the project is Release-built and installed - there is no separate release step, so there is no `[Unreleased]` backlog (Ian, 2026-10-19: "As soon as these are Release built they are Released").

### Added
- **Regression suites for every fix, proved red on the old code** (2026-10-13) - `Tests\Delphi.Mocks.Tests.Regression.pas` (34 tests, original API), `Tests\Delphi.Mocks.Tests.RegressionNewApi.pas` (6 tests: call log, `IVerify.ClearExpectations`, `TAutoMockContainer.Mock(PTypeInfo)`, auto mock refusing a class, `TMatcherFactory.ClearMatchers`, `ResetCalls` clearing the call order). Built in a worktree against the previous `Source\`: 32 of the 34 failed or errored there. The one that passed (`Stub_Of_Class_Runs_Overridden_Destructor`) is kept as a guard for a defensive fix; the other was ignored at the time and found a defect in the new comparison (method pointers), fixed before release. Every test unit now has full DocInsight; each `[Test]` says what it proves.
- **`Expect.Before` / `Expect.After` implemented** (2026-10-13) - `Source\Delphi.Mocks.Interfaces.pas`, `Source\Delphi.Mocks.MethodData.pas`, `Source\Delphi.Mocks.Expectation.pas`, `Source\Delphi.Mocks.Proxy.pas`, `Source\Delphi.Mocks.Proxy.TypeInfo.pas`. They were published, documented in `Users Guide.md`, and raised `not implemented` (the `MethodData` messages even said "implented"). Each proxy now keeps an `ICallLog` (`TCallLog`) of the order in which its methods are first called; an ordering expectation is met when both methods were called and the When method's first matching call precedes (`Before`) or follows (`After`) the other method's first call. It is evaluated at `Verify` time, because the other method can be called after the last hit. `ResetCalls` clears the log.
- **Full DocInsight on the library and the examples** (2026-10-13) - every unit in `Source\` and `Examples\`. Every interface-section type, field, constant and method now has a `<summary>`, with `<param>`, `<returns>` and `<exception>` where they apply; the six exception classes say when each is raised.
- **`Sample1` runs every example, and each example checks itself** (2026-10-13) - `Examples\Sample1.dpr`, `Examples\Sample1.dproj`, all `Examples\*.pas`. The `Matchers` and `Objects` examples were compiled by nothing; the others had their checks commented out, empty bodies, or `try ... except end` around the very failure they described. Each demonstration now raises if it does not behave as it says, `Sample1` exits 1 on a failure, and any command-line parameter skips the `ReadLn` pauses so it can run unattended. The class-mock `Implement` demonstration uses a class with a virtual method (`TElement` has none, so it could not be mocked at all), and the `QueryInterface` demonstration runs its doomed setup in a nested routine, because the setup's temporaries - and so the report - are released when the routine that made them ends.
- **Version information with build auto-increment** (2026-10-13) - `packages\RAD Studio 13.0\VSoft.DelphiMocksR.dproj`, `Examples\Sample1.dproj`. The package had none; `Sample1` had contradictory placeholders (`1.2.3.4` in Base, `4.3.2.1` and "VSoft" in Debug, included in one group and excluded in the next). Both now carry 0.3.2 (the `.dspec` version) with `VerInfo_AutoIncVersion`, and the package gained the `Cfg_1_Win32` / `Cfg_2_Win32` groups so all four modes bump - checked: each mode moved `VerInfo_Build` from 0 to 1.
- **Attribution and a fork README, ahead of making the repository public** (2026-10-13) - 21 changed source files, `Tests\Delphi.Mocks.Tests.ReturnTypePatch.pas`, `README.md`. Ian, 2026-10-13: "make glldelphi-mocks public too" (its consumer, gllDUnitX, went public the same day and its test project needs this repository). Each source file this fork changed now carries "Modified (C) 2026 Ian Branch (GITLAK Software)" beneath its intact upstream copyright notice (10 inserted into the existing header; 11 that never had one given a header crediting "Delphi Mocks, by Vincent Parrett & Contributors" without inventing a copyright year), as Apache 2.0 §4(b) requires before distribution; only 2 of 21 had been marked, and only incidentally. The test unit this fork added carries its own header: (C) 2026 Ian Branch (GITLAK Software), Apache 2.0. The README opens with the fork's scope (Delphi 13, Win32/Win64), that it is not affiliated with or endorsed by VSoft Technologies, and that it comes without support and takes no pull requests; upstream's "Delphi XE2 or later" now says this fork needs Delphi 13; a closing *Licence* section credits upstream and states the fork's copyright, and credits **Claude Code** (Anthropic), which wrote much of the fork's code, tests and documentation under Ian Branch's direction (20 of the fork's 21 commits carry its `Co-Authored-By: Claude` trailer). Checked first: no credentials in the tree or the history, no other licence in the tree, no Embarcadero source.

- **`Test_CanStubMethodDeclaredOnlyInAncestor`, and a real assertion in `Test_CanStubInheritedMethods`**
  (2026-10-02) - `Tests\Delphi.Mocks.Tests.Stubs.pas`. The upstream test stubbed `TStringList.Add` and
  asserted nothing, so it could not fail. It now asserts the stubbed value comes back (7, where the real
  `Add` on an empty list returns 0) and that the list stays empty. `TStringList` overrides `Add`, so a
  second test stubs `Answer` on `TStubDescendant`, which inherits it from `TStubAncestor` without
  overriding it. **Mutation-proved twice** in `Delphi.Mocks.ObjectProxy.pas`: intercepting only methods
  whose RTTI parent is `T` turns both red, and ignoring the stubbed behaviour turns both red (plus the
  existing `VirtualMethodNotCalledIfBehaviorMatches`). Suite 169 -> 170.
- **`Tests\Delphi.Mocks.Tests.ReturnTypePatch.pas` - three tests over `Delphi.Mocks.ReturnTypePatch`**
  (2026-10-02). That unit shadows private `System.Rtti` fields to patch RTTI, and had no test and no
  consumer, so an Embarcadero layout change would have broken it with nothing to notice. Now one test
  proves the input reaches the code (a method returning a gapped enumeration, which has no type
  information, really does report a nil return type) and two prove each patch route makes RTTI report
  the patched type, the by-name one also checking the parameters it walks past are intact.
  **Mutation-proved:** swapping the shadow `FParameters`/`FReturnType` declarations, which is exactly
  the silent break the Known Issue describes, turns both patch tests red. Suite 166 -> 169, diffed by
  test name: the three new tests and nothing else.
- **`Help.md` and `Users Guide.md`, to the estate documentation standard** (2026-09-18).
  `Help.md` is predominantly an API reference — this is a library people write test code
  against — with member tables for `TMock<T>`, `TStub<T>`, `IStubSetup<T>`, `IMockSetup<T>`,
  `IExpect<T>`, `ItRec`, `TAutoMockContainer` and `TComparer`, plus the six exception classes
  with their verbatim messages, and a problem-reference section beside it.
  `Users Guide.md` is task-ordered: mock an interface, set expectations, verify, stub a class.

### Fixed

- **The test suite was declared Win64-only, so the IDE and a default build never produced or ran a Win32 binary** (2026-10-23) - `Tests/Delphi.Mocks.Tests.dproj`.  Win32 is now enabled beside Win64 (`<Platform value="Win32">True</Platform>`, `TargetedPlatforms` 3).  Found by the 2026-10-23 Win32 pass over every gll* fork (Ian: "all our forks should be usable/up-to-date in Win32 and Win64"); it already built and passed with `/p:Platform=Win32`, so nothing else changed.  Win32 Release: **212 passed, 1 ignored (as on Win64)**; Win64 builds clean.
- **Tests that could not fail, and other test-suite defects** (2026-10-13) - every unit in `Tests\`. Five tests passed without checking anything (`Assert.Pass` bodies, an `Expect` never verified, a `WillRaise` on a non-virtual method, an RTL-only baseline, now deleted); about twenty were weak (`Assert.IsTrue(True)` endings, messages never checked, `SameText` where casing mattered, base-class or class-less `WillRaise`, a "different GUID" test using identical GUIDs). `ESimpleException` was an alias of `Exception`; two test interfaces shared a GUID; one test leaked six objects; `Test_CompareValue_RecordNoEqualsOperator` asserted that different records are equal and now asserts the opposite. The `Before`/`After`, safecall, simple-procedure and auto-mock-returned-interface tests are un-ignored; the one still ignored carries its reason. `ProxyBase` had no tests and has two. Now 213 tests: 212 pass, 1 ignored, 0 leaks.
- **Orphaned and dead test-project content removed** (2026-10-13) - `Tests\Delphi.Mocks.Examples.Factory.pas`, `Tests\Delphi.Mocks.Examples.Implement.pas`, `Tests\Delphi.Mocks.Examples.Objects.pas` (deleted: in neither the `.dpr` nor the `.dproj`, drifted from `Examples\`, and holding fakes), `Tests\Delphi.Mocks.Tests.dpr` (the commented-out classic DUnit runner, dead `{.$DEFINE}` / `ISCONSOLE` lines, `Forms`, `Sample1Main`, and a `{$WARN}` replaced by `DCC_DUPLICATE_CTOR_DTOR=false` in the `.dproj`), `Tests\Delphi.Mocks.Tests.dproj` (Android / iOS / OSX `ProjectRoot` deployment entries; version 0.3.2 with auto-increment and `Cfg_1_Win64` / `Cfg_2_Win64` groups; re-laid from tab-indented LF to the IDE's 4-space CRLF form).
- **`WillRaise(...).When` raised for every call, whatever its arguments, and with the wrong message** (2026-10-13) - `Source\Delphi.Mocks.Behavior.pas`. `TBehavior.Match` raised instead of answering, with the fixed text 'Raised by Mock'; it ran before any `WillReturn`, inside class-mock interception before the hit was counted, and during setup when a second `WillRaiseWhen` was defined. `Match` now only matches; `Execute` raises with the user's message.
- **Records with no `=` operator, and any value of an unhandled kind, compared equal** (2026-10-13) - `Source\Delphi.Mocks.Helpers.pas`. `CompareValue_Record` and the catch-all in `CompareValue` returned 0, so `When.Foo(RecA)` matched every record, and sets, pointers, class references, method pointers, `OleVariant` and mixed kinds matched anything. Records now compare by `=` or field by field; pointers and class references by address; the rest byte for byte when the type is unmanaged, otherwise unequal. Method pointers compare by code and instance (the byte comparison refuses them as managed). Also: incomparable Variants raised out of matching and are now unequal; floats used a platform-dependent tolerance (1E-19 on Win32, 1E-15 on Win64) and are now exact; strings used locale-aware `AnsiCompareStr`, which ignores some characters, and are now ordinal; interfaces compare by COM identity rather than raw pointer.
- **`It.IsInRange<T>` did nothing** (2026-10-13) - `Source\Delphi.Mocks.pas`. It returned `Default(T)` and registered no matcher, so the setup became a literal match on `Default(T)` or shifted the other parameters' matchers. It now matches the inclusive range by `TComparer<T>.Default`.
- **A matcher gap raised an access violation at call time; a mixed literal was silently ignored** (2026-10-13) - `Source\Delphi.Mocks.Proxy.pas`, `Source\Delphi.Mocks.ParamMatcher.pas`, `Source\Delphi.Mocks.Behavior.pas`, `Source\Delphi.Mocks.Expectation.pas`. `When.Foo(5, It1.IsAny<Integer>)` left a nil matcher that passed the arity check and was dereferenced on the first real call; the expectation path had no check, so a literal beside a matcher was dropped. Both setup paths now raise `EMockSetupException` unless every parameter has a matcher or none does. A second matcher for one parameter was inserted, shifting every later parameter's matcher; it now raises and leaves the next setup clean. Matchers left by an `It` evaluated outside a `When` attached to the next unrelated setup; they are now discarded at the next ordinary call.
- **Setup de-duplication matched the new setup's placeholder arguments against existing matchers** (2026-10-13) - `Source\Delphi.Mocks.MethodData.pas`. After `WillReturn(0).When.Foo(It0.IsAny<Integer>)`, `WillReturn(1).When.Foo(3)` raised "already defines" (or, with redefinition allowed, deleted the general rule). Setup now compares definitions; a matcher-based setup is never a redefinition.
- **A non-When expectation collided with its When counterpart** (2026-10-13) - `Source\Delphi.Mocks.MethodData.pas`. `Expect.Once('Foo')` looked for `[Once, OnceWhen]`, so it raised after an `OnceWhen` (or removed it); likewise `Never`, `AtLeast`, `AtMost`, `Between`, `Exactly`. Each now looks only for its own kind.
- **`WillReturnDefault` was ignored on a class mock's concrete virtual method, and could not be nil** (2026-10-13) - `Source\Delphi.Mocks.MethodData.pas`. The default was stored but not added as a behaviour, so the real method ran; and `TValue.IsEmpty` is true for a nil object, nil interface and empty array, so such a default "had no default return value". It is now a `ReturnDefault` behaviour, with a separate defined flag.
- **The auto mock container leaked, and auto mocking of return values did not work** (2026-10-13) - `Source\Delphi.Mocks.MethodData.pas`, `Source\Delphi.Mocks.AutoMock.pas`, `Source\Delphi.Mocks.pas`. `TMethodData` held the container strongly, closing a cycle through the proxies it owns; it is now weak. A method returning an interface got an `IProxy` instead of that interface, and records were sent to a mocker that rejects them; it now returns the mocked interface itself (the same one on later calls) and auto mocks interfaces only. `TAutoMockContainer.Mock(ATypeInfo)` threw away the mock it created and is now a function returning it; a container used before `Create` raised an AV and now raises `EMockException`.
- **A mocked instance used after its mock was released raised an AV or ran in freed memory** (2026-10-13) - `Source\Delphi.Mocks.Proxy.pas`, `Source\Delphi.Mocks.Proxy.TypeInfo.pas`. The owner and parent were held by weak references whose `Data` is nil once the proxy has gone, but only the reference object was tested. Both are now checked, and a destroyed proxy re-points its virtual interface's invoke handler at one that raises `EMockException`.
- **`ResetCalls` and `Expect.Clear` skipped the interfaces added with `Implement`** (2026-10-13) - `Source\Delphi.Mocks.Proxy.pas`, `Source\Delphi.Mocks.Proxy.TypeInfo.pas`, `Source\Delphi.Mocks.Interfaces.pas`. `VerifyAll` checks them, so calls made before a reset still failed it. Both now reach the children (`IVerify.ClearExpectations` added).
- **An abandoned setup was reported for transient reference counting** (2026-10-13) - `Source\Delphi.Mocks.Proxy.pas`. `_Release` reported "non-virtual method" for any release while a setup was pending, including an AddRef/Release pair made while the When arguments were evaluated. It now reports only once the count falls below where it stood when the setup began, and the message says why a When call can miss the mock.
- **Class mocks never replace lifecycle methods** (2026-10-13) - `Source\Delphi.Mocks.ObjectProxy.pas`. `DoBefore` excluded only `TObject`'s own methods, so on paper an overridden `Destroy`, `BeforeDestruction`, `AfterConstruction` or `FreeInstance` on a stub would have been skipped. Defensive only: the regression test passes on the old code too, because `TVirtualMethodInterceptor` does not route these methods to `OnBefore` in RAD Studio 37.0. The guard stops a future RTL change from turning that into a leak.
- **`PatchMethodReturnType` could write a pointer to an arbitrary address** (2026-10-13) - `Source\Delphi.Mocks.ReturnTypePatch.pas`. It hard-cast any method to the interface-method shadow class, did not check `GetType` for nil, ignored `WriteProcessMemory`'s result, matched names case-sensitively, and disposed the slots the patched RTTI points at in finalization. It now refuses non-interface types and methods (`EArgumentException`), raises `EOSError` when the write fails or does not take, matches names case-insensitively, and keeps the slots in static storage guarded by a lock.
- **Weak references could write into freed memory under contention** (2026-10-13) - `Source\Delphi.Mocks.WeakReference.pas`. `TWeakReference.Destroy` used `TryEnter` on the target's monitor and, if it failed, left its slot registered for the target to nil later; `Data` read the slot unlocked and could revive an object being destroyed. One process-wide spin lock now guards registration, removal, clearing and reading, and `Data` takes a strong reference only while the count is above zero.
- **`TMock` / `TStub` misuse gave misleading errors or AVs** (2026-10-13) - `Source\Delphi.Mocks.pas`. `TMock.Free` left `FCreated` set, so later use (or a second `Free`) reported an "Internal Error", and `FCreated` was garbage in an uninitialised local; `TStub` checked nothing and raised AVs. Both now test the managed `FProxy` alone (`FCreated` is gone), `Free` is idempotent, and misuse raises `EMockException` "... was used before Create, or after Free."
- **`{$O+}` after `TMock<T>.Verify<I>` switched optimisation on for the rest of the unit, Debug included** (2026-10-13) - `Source\Delphi.Mocks.pas`. The `{$O-}` sections now restore the state they found.
- **Smaller defects** (2026-10-13) - `MethodKindToStr` passed an Integer to `%s`, so its error path raised `EConvertError` (`Source\Delphi.Mocks.Proxy.pas`); `AtMostOnceWhen` was mapped to `AtLeastOnceWhen` (`Proxy.pas`, `Proxy.TypeInfo.pas`); `Between(a, b)` with b &lt; a could never be met and now raises `EMockSetupException` (`MethodData.pas`); `TRttiMethodHelper.IsAbstract` read the flags of methods whose handle is not a `PVmtMethodExEntry` (`Helpers.pas`); `ItRec.DefaultComparer` kept an RTTI method from a context that had ended, and hashed string pointers (`Delphi.Mocks.pas`); `TComparer.CompareMembers` raised on records, recursed for ever on cyclic graphs and read write-only properties (`Delphi.Mocks.pas`); `FReturnValueNilAllowed` survived `WillReturnNil` (`Proxy.pas`); reports of matcher-based expectations printed placeholder values (`Expectation.pas`).
- **An in-IDE build re-saved the package `.dproj` without its Release output paths** (2026-10-07) — `packages/RAD
  Studio 13.0/VSoft.DelphiMocksR.dproj`. The output standard was two `Condition`-ed `DCC_BplOutput` / `DCC_DcpOutput`
  lines in the Base group, and the IDE keeps one value per property per group when it re-saves the project on a build,
  so it wrote back only the active config's: a committed re-save sent Release builds to the root `Bpl` / `Dcp`
  folders. Now one plain value per group, the form the IDE writes itself: Base
  `$(BDSCOMMONDIR)\Bpl\$(Platform)\$(Config)` (and `Dcp`), overridden in the Release config group by
  `$(BDSCOMMONDIR)\Bpl\$(Platform)`. Same output; built in all four modes with the `dcc` `-LE`/`-LN` paths checked per
  mode.
- **Pre-D13 and non-Windows conditionals resolved away** (2026-10-02) - `Source\Delphi.Mocks.inc`,
  `Source\Delphi.Mocks.pas`, `Source\Delphi.Mocks.Proxy.TypeInfo.pas`, `Source\Delphi.Mocks.WeakReference.pas`.
  `HAS_SYSTEM_HASH` (`CompilerVersion > 28.0`) is constant on D13 Win32 and Win64: its `{$DEFINE}` is gone
  from the include, `System.Hash` is used unconditionally, and the `BobJenkinsHash` fallback is deleted.
  `NEXTGEN` is never defined for Windows, so its three blocks keep the non-NEXTGEN branch. The include's
  XE2 `{$IF}` guard stays: a header guard is exactly what this kind of sweep must leave. Verified by
  compiling, all four package modes clean.
- **Stale `TestInsight` build configuration removed; Debug is the default** (2026-10-02) -
  `Tests\Delphi.Mocks.Tests.dproj`, `Tests\Delphi.Mocks.Tests.dpr`. TestInsight was removed from the IDE on
  2026-09-29, and this config never defined `TESTINSIGHT`, so it was Debug under another name and sent
  IDE builds to `Win64\TestInsight`. The dead `{$IFDEF TESTINSIGHT}` runner block went with it.
  Win32 is now deactivated (`TargetedPlatforms` 3 -> 2), as for every DUnitX suite in the estate: a Win32
  build fails `F2613 Unit 'DUnitX.TestFramework' not found`, because the IDE's Win32 library path carries
  no DUnitX. The project's own `DUNITX` fallback (`..\..\gllDUnitX\Source`) cannot rescue it: it is set
  at the END of the file, after `DCC_UnitSearchPath` has already expanded `$(DUNITX)`, so command-line
  builds resolve DUnitX only through the IDE's `DUNITX` environment variable and Win64 library path.
- **Every hint and warning in the package, the test suite and `Sample1` cleared** (2026-10-02) -
  `Source\Delphi.Mocks.pas`, `Source\Delphi.Mocks.Proxy.pas`, `Source\Delphi.Mocks.Proxy.TypeInfo.pas`,
  `Examples\Delphi.Mocks.Examples.Factory.pas`, `Tests\Delphi.Mocks.Examples.Factory.pas`,
  `Tests\Delphi.Mocks.Examples.Matchers.pas`, `Tests\Delphi.Mocks.Tests.Utils.pas`,
  `packages\RAD Studio 13.0\VSoft.DelphiMocksR.dproj`. Each build printed 24 warnings and 4 hints.
  - `H2077` in `TMock<T>.Instance<I>`: a `result := nil` every path overwrites or raises past. Deleted.
  - `H2164` in `TProxy<T>.DoInvoke`: the local `behavior` was never used. Deleted.
  - `H1054` x3: `{$Message 'TODO ...'}` turned each reminder into a hint on every build. Kept as
    `// TODO` comments, so the note survives without the noise.
  - `W1029` x24 (duplicate constructors "inaccessible from C++"): `DCC_DUPLICATE_CTOR_DTOR=false` in the
    package project, the estate's one sanctioned suppression, as C++Builder is never in scope. The test
    runner already carried `{$WARN DUPLICATE_CTOR_DTOR OFF}`.
  - `W1000` `BobJenkinsHash` deprecated: the test guarded the modern call with `DELPHI_XE8_UP`, which
    nothing defines (`Delphi.Mocks.inc` defines `HAS_SYSTEM_HASH`), so the deprecated branch was
    always the one compiled. Resolved to `THashBobJenkins.GetHashValue` unconditionally.
  - `W1020` x4: the comparison tests constructed `TMyClass`, which keeps an abstract method for the
    `IsAbstract` RTTI tests. They now construct a new concrete descendant, `TMyConcreteClass`.
  Verified with clean builds: package four modes, test suite Win64 Debug and Release, `Sample1`.
- **A test run that died before reporting exited 0** (2026-10-02) - `Tests\Delphi.Mocks.Tests.dpr`.
  The runner's `except` printed the exception and left `ExitCode` alone, so a crash in setup or
  discovery read as a pass to anything gating on the exit code. It now sets `EXIT_ERRORS`.
- **`AllowRedefineBehaviorDefinitions_IsTrue_NoExceptionIsThrown_WhenMatcherAreDifferent` leaked its
  `TObjectToTest`** (2026-10-02) - `Tests\Delphi.Mocks.Tests.MethodData.pas`. Its `finally` freed two
  of the three objects it created; its sibling test frees all three.
- **Duplicate `Generics.Defaults` in `Delphi.Mocks.pas`'s implementation `uses`** (2026-10-02) - taken
  from upstream `53cd36b` (#156) by `git cherry-pick -x`; the interface section already names
  `System.Generics.Defaults`. A scan of every `.pas`/`.dpr` in the repository for the same shape (one
  unit named both qualified and unqualified in one unit's `uses` clauses) found no other instance.
- **Two `Assert.WillNotRaise` sites pass an exception class, which makes them unable to fail on
  anything else** (2026-09-18; **fixed 2026-10-02**: both are now `Assert.WillNotRaiseAny`) —
  `Tests\Delphi.Mocks.Tests.MethodData.pas:91` and `:184`, both
  `Assert.WillNotRaise( ..., EMockSetupException )`.
  Our `gllDUnitX` fork tests `e.ClassType = exceptionClass` — an exact match, not `is` — so the
  assertion **swallows** anything that is not precisely that class, an `EAccessViolation`
  included. These two happen to behave, because the five mock exception classes all descend
  **directly** from `EMockException` and none is a descendant of another; the correct form is
  `Assert.WillNotRaiseAny`.
  **The wider point is about the sweep, not these two sites.** The estate record states that a
  2026-09-16 sweep found all 19 `WillNotRaise` sites passing no class and therefore correct —
  that sweep covered four repositories and this was not one of them.
- **`Tests\Delphi.Mocks.Tests.dpr` does not set `Assert.IgnoreCaseDefault := False`**
  (2026-09-18), so this suite carries the fork's weak default and every two-argument string
  comparison in it is case-insensitive. `Test_WillReturnDefault` in
  `Delphi.Mocks.Tests.Stubs.pas` is a live example.
  **Fixed 2026-10-02:** the runner now sets it before the run. No test went red: 156 passed before
  and after, so nothing here had been relying on the weak default.
- **`CHANGELOG.md`'s "Known Issues" contradicts its own "Removed" entry and the tree**
  (2026-09-18). It says the repository "still carries 15 RAD Studio package folders, legacy
  packages under `Source`, and Win32/OSX/mobile targets", and that it "has not been scoped down
  the way `gllDUnitX` was". The same file records those fourteen folders and the legacy `Source`
  packages as deleted, and the tree agrees: only `packages\RAD Studio 13.0\` exists, `Source\`
  holds 16 `.pas` and one `.inc` with no packages, and both `.dproj` declare Win32+Win64 only.
  The other two Known Issues — the `ReturnTypePatch` shadow fields and the `ObjectProxy`
  unconditional free — were re-checked and are still true.
  **Fixed 2026-10-02:** the stale bullet is deleted from Known Issues.

### Reviewed and deliberately NOT taken from upstream, so they are not re-derived later

- **Upstream swept 2026-10-02: watermark `53cd36b` (2026-10-01, `upstream/master`).** The one new
  commit, `53cd36b`, was TAKEN (see `### Fixed`); real shared history exists, so it went in by
  cherry-pick. This fork is again 0 commits behind `upstream/master`.
- **Upstream swept 2026-09-18: `AutoMockV2` reviewed, nothing taken.** This fork is **0 commits
  behind both `upstream/master` and `upstream/Development`**; `AutoMockV2` is an abandoned **2015**
  feature branch, eleven years behind upstream's own tip.
  - `928ca09` "removed param matchers which was copied by accident" - **REFUSED, and it would
    break the build.** Its only source content removes `Delphi.Mocks.ParamMatcher` from four
    `uses` clauses, but that unit is LIVE here and referenced by eight units
    (`Delphi.Mocks.pas`, `.Behavior`, `.Expectation`, `.Interfaces`, `.MethodData`, `.Proxy`,
    `.Proxy.TypeInfo`). We have also fixed a real defect inside it - `TMatcherFactory` freeing
    matcher lists the dictionary already owns (`doOwnsValues`), a double free on any aborted
    `Setup`. Upstream itself reversed the "copied by accident" judgement when Development was
    merged back. The remainder is XE8-era `.dproj` churn, pre-D13.
  - `2cbaae6` - a merge whose unique content is exactly `928ca09`'s three deletions. REFUSED.
  **Condition to reopen:** none. The branch is abandoned and its one idea was reversed upstream.

### Fixed

- `TargetedPlatforms` brought into line with the `<Platforms>` block in 5 `.dproj` (2026-09-10)
  The earlier platform sweep removed the non-Windows `<Platform>` entries but left the
  `<TargetedPlatforms>` bitmask untouched, so projects still advertised targets they no
  longer declared — values such as `1048579` and `135171` encode Android/Linux/iOS, and
  several Win32+Win64 projects still read `2` (Win64 only) or `1` (Win32 only).
  Now `3` for Win32+Win64, `2` where only Win64 is declared.
  **Why:** the mask is what the IDE reads for the Project Manager's platform list, so a
  stale one puts dead platforms back in front of the reader.

### Changed

- **Within a behaviour type, the most recently defined matching behaviour wins** (2026-10-13) - `Source\Delphi.Mocks.MethodData.pas`. Overlapping definitions could only coexist once setup stopped comparing calls (see Fixed), and a general rule followed by a specific one is the common case, so the later definition is now found first. The precedence between types is unchanged.
- **Messages made accurate** (2026-10-13) - `Source\Delphi.Mocks.Validation.pas`, `Source\Delphi.Mocks.pas`, `Source\Delphi.Mocks.Utils.pas`. A class with no virtual method of its own is reported as having nothing to intercept (it said to add `{$M+}`, which was never what the check measured); `CheckClassHasRTTI` now measures against an empty class rather than a hard-coded 12. `Implement<I>` on a class mock names both types; `Verify<I>` for an unimplemented `I` raises `EMockNoProxyException`.
- **Dead code removed** (2026-10-13) - `Source\Delphi.Mocks.Utils.pas` (`GetDefaultValue`, never called and wrong for sets), `Source\Delphi.Mocks.Proxy.pas` and `Proxy.TypeInfo.pas` (`QueryProxy`, inverted and never called; the type-info proxy's setup branches, which nothing could reach, and its commented-out copies), `Source\Delphi.Mocks.Behavior.pas` (a hit count nothing read).
- **Compiler floor raised to Delphi 13** (2026-10-13) - `Source\Delphi.Mocks.inc`. The guard said XE2 (`CompilerVersion < 23`); the fork has had no pre-D13 code since 2026-10-02.
- **D13 language features adopted** (2026-10-08) - `Source/Delphi.Mocks.Validation.pas`, `Source/Delphi.Mocks.pas`. 2 `not ( X in S )` / `not ( X is T )` rewritten as `X not in S` / `X is not T` (generated code byte-identical: every project that built before was rebuilt and compared). **Divergence accepted:** upstream was reviewed first (nothing pending was lost), and Ian's ruling for the gll* forks is that they "are our forks now", to be made "as correct as possible/practical"; these lines will need re-applying or resolving in any later upstream port.
- Project platforms normalised to Win32 + Win64 only in 3 `.dproj` files (2026-09-10)
  Non-Windows targets (`Android`, `Android64`, `iOS*`, `OSX*`, `Linux64`) and the
  `Win64x` / `WinARM64EC` variants were removed together with their `Base_<Plat>` and
  `Cfg_N_<Plat>` property groups, `<Deployment>` platform nodes and `<ProjectRoot>`
  entries; a deactivated `Win32` or `Win64` was switched on.
  **Why:** standing suite rule — every gll* project is Delphi 13, Win32 + Win64, nothing
  else, so the four-mode package sweep is always possible.

- Codeberg is retired; every repository URL points at GitHub again (2026-09-05).
  **Why:** hosting consolidated back on GitHub. `origin` is the GitHub URL, the stale
  `codeberg` remote has been removed from the working checkout, and the documentation that
  says where to clone from was updated to match. The Codeberg entry below is superseded;
  its URLs are left as written because rewriting them would falsify the record.

- Repository moved to the `GITLAK-forks` Codeberg organisation: `origin` is now `https://codeberg.org/GITLAK-forks/glldelphi-mocks.git`, and the documentation references were updated to match. **Why:** the `GITLAK` account had reached Codeberg's hard limit of 100 repositories, and an organisation carries its own allowance (2026-09-03) — `Tests/Delphi.Mocks.Tests.dproj`, `VSoft.DelphiMocks.dspec.yaml`
  **Superseded 2026-09-05:** Codeberg is no longer used; see the entry above.

## [In-Service]

### Changed

- **C++Builder output turned off** (2026-08-26). `DCC_CBuilderOutput` was `All`, so every build emitted `.hpp` / `.bpi` / `.a` / `.obj` files for a compiler that is **never in scope here** (standing rule: "I dont use C++ at all"). Across the estate that was 616 files and 90 MB of output nobody consumes, regenerated on every build; `gllSynEdit` alone accounted for 560. Now `None`. The `DCC_HppOutput` / `DCC_BpiOutput` / `DCC_ObjOutput` properties are left in place deliberately - they only say *where* such files would go, so with generation off they are inert, and removing them would enlarge the diff without changing behaviour. Verified: the affected packages rebuilt clean in every enabled mode, emitted no C++ artefacts, and rebuilt clean again after the existing ones were deleted (so nothing was load-bearing).

- The DPM package id is now `GITLAK.DelphiMocks`, not `VSoft.DelphiMocks`, so this fork cannot shadow upstream in a package feed. Description records the upstream baseline (0.3.2) and the Delphi 13 / Win64 scope; GITLAK Software added to `authors`, with Vincent Parrett's authorship and copyright retained as Apache-2.0 requires (2026-08-24) - `VSoft.DelphiMocks.dspec.yaml`

> Libraries and packages are continuously deployed: changes below are live as soon as the package is rebuilt and installed - there is no separate release step, so no `[Unreleased]` backlog. Tagged version snapshots are listed beneath.

### Fixed

- Corrected the Debug/Release package output split (2026-08-24)
  **Why:** the first attempt diverted both configurations to a `$(Config)` subfolder, which broke package loading - `$(BDSCOMMONDIR)\Bpl\$(Platform)` is on the machine `PATH` and is where a design package resolves the runtime packages it requires. Release now stays in the shared `Bpl`/`Dcp` folders and only Debug is diverted, which still stops a Debug build replacing the installed Release package.

### Fixed

- The entire object-proxy feature crashed on Win64, taking out 24 of 166 tests with access violations reading a sign-extended address (2026-08-24) - `Source/Delphi.Mocks.Utils.pas`
  **Why:** `GetVirtualMethodCount` cast a class reference with `Integer(AClass)`, truncating a 64 bit pointer to 32 bits so it was sign extended back into unmapped memory, and read the pointer-sized VMT slot through a `PInteger`, getting half of it. Both are now `NativeInt`. The suite went from 132 passed / 1 failed / 23 errored to 156 passed / 0 failed / 0 errored.
- The test project did not compile on Delphi 13: seven `Assert.AreEqual(n, Length(...))` calls could no longer infer a single generic argument now that `Length` returns `NativeInt` (2026-08-24) - `Tests/Delphi.Mocks.Tests.InterfaceProxy.pas`, `Tests/Delphi.Mocks.Tests.ObjectProxy.pas`, `Tests/Delphi.Mocks.Examples.Matchers.pas`
- The test project wrote its `.dcu` files into the project directory itself, which is why stale DUnitX units accumulated in `Tests\` (2026-08-24) - `Tests/Delphi.Mocks.Tests.dproj`
- `.res` and `.rc` are no longer ignored; three `.dpk`/`.dpr` files pull them in with `{$R *.res}` (2026-08-24) - `.gitignore`, `packages/RAD Studio 13.0/VSoft.DelphiMocksR.res`

### Changed

- Scoped the fork to Delphi 13 (Florence), 64 bit Windows only, matching `gllDUnitX` (2026-08-24)
- The test project now resolves DUnitX from a sibling `gllDUnitX` checkout via the `DUNITX` property, with a `CheckDUnitX` target that fails with an actionable message (2026-08-24) - `Tests/Delphi.Mocks.Tests.dproj`

### Removed

- The fourteen pre-D13 package folders, the legacy `DelphiMocks`/`DelphiMocksXE5`/`DelphiMocks104` packages under `Source`, `Tests/MemoryLeakTest` (Win32, classic DUnit, vendored FastMM4), the FinalBuilder projects with hard-coded `I:\` paths, and the stale JSON `.dspec` superseded by the `.yaml` (2026-08-24)
- Debug and Release package artefacts no longer overwrite each other (2026-08-24) - `packages/RAD Studio 13.0/VSoft.DelphiMocksR.dproj`
  **Why:** RAD Studio defaults the .bpl and .dcp output paths to `$(BDSCOMMONDIR)\Bpl\$(Platform)` and `\Dcp\$(Platform)`, neither carrying `$(Config)`, so a Debug build silently replaced the Release artefacts. **Debug only** now goes to a `$(Config)` subfolder; Release stays in the shared `Bpl`/`Dcp` folders, which are on `PATH` and are how dependent packages resolve their `requires`. See the follow-up entry above - an initial attempt that moved Release as well broke package loading.
- The 12 `W1029` "Duplicate constructor ... will be inaccessible from C++" warnings that `TExpectation`
  emitted into every consuming build (2026-08-24) - `Source/Delphi.Mocks.Expectation.pas`
  **Why:** the unit told callers to put `{$WARN DUPLICATE_CTOR_DTOR OFF}` in their `.dpr`, but a `{$WARN}`
  there does not affect how a separate unit is compiled, so the advice never worked. The directive now sits
  in the unit that emits the warnings. A consuming build went from 13 warnings to 1.

### Changed

- Normalised the test sources to CRLF line endings (2026-08-24) - `Tests/Delphi.Mocks.Tests.Base.pas`,
  `Tests/Delphi.Mocks.Tests.dpr`

- `TAutoMock.Destroy` never freed `FMocks`, leaking a `TList<IProxy>` per container (2026-08-24) - `Source/Delphi.Mocks.AutoMock.pas`
- Broke the reference cycle between `TAutoMockContainer` and its proxies. The container held each proxy strongly via `IProxy` while every proxy held the container strongly via `IAutoMock`, so neither was ever destroyed and the proxies, their `TVirtualInterface`s and all method data leaked. The proxy now holds the container through `IWeakReference<IAutoMock>` - `TAutoMock` already descended from `TWeakReferencedObject`, so this is the design that was intended (2026-08-24) - `Source/Delphi.Mocks.Proxy.pas`, `Source/Delphi.Mocks.Proxy.TypeInfo.pas`
- `TProxy<T>._Release` raised before calling `inherited`, so the reference count was never decremented and the proxy leaked. It now decrements first and reports afterwards (2026-08-24) - `Source/Delphi.Mocks.Proxy.pas`
- `TMatcherFactory` freed its matcher lists by hand although the dictionary owns them (`doOwnsValues`), a double free on any aborted `Setup` (2026-08-24) - `Source/Delphi.Mocks.ParamMatcher.pas`
- Object and interface comparison truncated a 64 bit pointer difference into an `Integer`, so two instances exactly 4GiB apart compared equal. Now compared by sign (2026-08-24) - `Source/Delphi.Mocks.Helpers.pas`
- Removed a stray `=======` merge-conflict marker from `.gitignore`, and `.gitmodules`, which declared a `DUnitXML` submodule with no gitlink and no directory whose relative URL now resolved to a non-existent Codeberg repo, breaking `clone --recursive` (2026-08-24)

### Known Issues

- `Delphi.Mocks.ReturnTypePatch.pas` shadow-declares private `System.Rtti` fields to patch RTTI. The layout still matches RAD Studio 37.0. Since 2026-10-02 a reorder no longer breaks silently: `Tests\Delphi.Mocks.Tests.ReturnTypePatch.pas` goes red (mutation-proved).
- `Delphi.Mocks.ObjectProxy.pas` frees the wrapped instance unconditionally, even when the caller supplied it. Changing that is an ownership contract change, so it is left alone deliberately.
