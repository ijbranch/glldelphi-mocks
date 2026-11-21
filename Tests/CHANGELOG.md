# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

> The change record of the `DelphiMocksTests` test suite (`Tests`).  Kept beside the suite since
> 2026-10-25 (Ian: "every test suite should have its own change log"); test-only entries recorded before that in
> the repository's `CHANGELOG.md` were moved here the same day.  Product changes, including those that change a
> product unit together with its tests, stay in the repository's `CHANGELOG.md`.

## [In-Service]

### Added

- (2026-11-21) **Three more review tests, from the adversarial review of the fixes** — `Tests/Delphi.Mocks.Tests.Review.pas`.  `WillExecute_Runs_Outside_The_Shared_Lock` ( a second thread's mock call completes while a `WillExecute` waits; red with the behaviour back under the lock ), `Call_From_Other_Thread_Does_Not_Complete_A_Pending_Setup` ( red without the thread check ) and `AreSameFieldsThat_Matches_A_Class_Mock_Instance` ( red with the plain class check ).  Suite 245 -> 248.
- (2026-11-21) **`Delphi.Mocks.Tests.Review.pas` — 27 tests, one per defect of the 2026-11-21 deep review** — `Tests/Delphi.Mocks.Tests.Review.pas`, `Tests/Delphi.Mocks.Tests.dpr`, `Tests/Delphi.Mocks.Tests.dproj`.  The first 23 were written first and run against the unfixed library: 21 red, each on its own defect, and 2 green by design ( `AreSameFieldsThat_Compares_Public_Fields` guards behaviour kept, `WillRaise_When_Raises_For_Any_Arguments_WillRaiseWhen_Only_For_Matching` pins the documented meaning ).  The 4 written after their fixes are mutation-proved: removing the Variant string rule, the negative-index check or the `=`-overload choice turns each red, and removing the `Free` from `WillExecute_Capturing_Its_Mock_Is_Released_By_Free` makes the leak check report 3928 bytes.  Suite 218 -> 245.
- (2026-11-19) **`TestOpenArraySetupsMatchByContents`, `TestOpenArrayExpectationMatchesByContents`, `TestStaticArraySetupsAndExpectationMatchByContents`, `StoredSetupReportsNonVirtualMethodAtNextSetup`** — `Delphi.Mocks.Tests.OpenArrayIntf.pas`, `Delphi.Mocks.Tests.ObjectProxy.pas`, `README.md`.  The two open array tests set up different contents and must tell them apart; both were red on the old library (a second setup refused as a duplicate), and are marked `[Ignore('BUG: System.Rtti ...')]` because a `System.Rtti` defect still drops open array elements; listed in the new `README.md` § Product bugs / ignored tests (`README.md` added).  The static array test covers the same kept-argument path with a static array, which the RTL passes intact; red with the `TValue` unwrap removed.  The last proves a non-virtual setup through a held `Setup` is reported by the next setup ( a flag between the statements shows which one raised ); mutation-proved red.

- (2026-11-13) **`Test_CompareValue_InterfaceNotEquals_AddressesFarApart`, from upstream `abf2c65` (#157)** — `Delphi.Mocks.Tests.Utils.pas`.  Two fake interfaces (a do-nothing `IInterface` method table) placed with `VirtualAlloc` at `$20000000` and `$120000000`, exactly 4 GB apart, must compare unequal with the right sign and each equal to itself.  The address difference truncated to 32 bits is 0, the exact case the old `NativeInt(left) - NativeInt(right)` got wrong.  This fork had already fixed `CompareValue` its own way (compare by sign, through `InterfaceIdentity`, which falls back to the raw reference when the fake's `QueryInterface` refuses) but had no test at that distance.  Win64 only; Win32 passes as not applicable.  If either address cannot be reserved the test reports itself ignored (`Assert.Ignore`), not passed as upstream's does, so a run that compared nothing shows.
- (2026-10-25) **This change log** — `CHANGELOG.md`.  The suite's own record, per the estate rule that every test
  suite has one; test-only history moved in from `..\CHANGELOG.md` ( 14 entries ).
- (2026-10-13) **Regression suites for every fix, proved red on the old code** - `Tests\Delphi.Mocks.Tests.Regression.pas` (34 tests, original API), `Tests\Delphi.Mocks.Tests.RegressionNewApi.pas` (6 tests: call log, `IVerify.ClearExpectations`, `TAutoMockContainer.Mock(PTypeInfo)`, auto mock refusing a class, `TMatcherFactory.ClearMatchers`, `ResetCalls` clearing the call order). Built in a worktree against the previous `Source\`: 32 of the 34 failed or errored there. The one that passed (`Stub_Of_Class_Runs_Overridden_Destructor`) is kept as a guard for a defensive fix; the other was ignored at the time and found a defect in the new comparison (method pointers), fixed before release. Every test unit now has full DocInsight; each `[Test]` says what it proves.
- (2026-10-02) **`Test_CanStubMethodDeclaredOnlyInAncestor`, and a real assertion in `Test_CanStubInheritedMethods`**
  - `Tests\Delphi.Mocks.Tests.Stubs.pas`. The upstream test stubbed `TStringList.Add` and
  asserted nothing, so it could not fail. It now asserts the stubbed value comes back (7, where the real
  `Add` on an empty list returns 0) and that the list stays empty. `TStringList` overrides `Add`, so a
  second test stubs `Answer` on `TStubDescendant`, which inherits it from `TStubAncestor` without
  overriding it. **Mutation-proved twice** in `Delphi.Mocks.ObjectProxy.pas`: intercepting only methods
  whose RTTI parent is `T` turns both red, and ignoring the stubbed behaviour turns both red (plus the
  existing `VirtualMethodNotCalledIfBehaviorMatches`). Suite 169 -> 170.
- (2026-10-02) **`Tests\Delphi.Mocks.Tests.ReturnTypePatch.pas` - three tests over `Delphi.Mocks.ReturnTypePatch`**
  . That unit shadows private `System.Rtti` fields to patch RTTI, and had no test and no
  consumer, so an Embarcadero layout change would have broken it with nothing to notice. Now one test
  proves the input reaches the code (a method returning a gapped enumeration, which has no type
  information, really does report a nil return type) and two prove each patch route makes RTTI report
  the patched type, the by-name one also checking the parameters it walks past are intact.
  **Mutation-proved:** swapping the shadow `FParameters`/`FReturnType` declarations, which is exactly
  the silent break the Known Issue describes, turns both patch tests red. Suite 166 -> 169, diffed by
  test name: the three new tests and nothing else.

### Fixed

- (2026-11-21) **`Test_CompareValue_InterfaceNotEquals_AddressesFarApart` reported its Win32 skip as a pass** — `Tests/Delphi.Mocks.Tests.Utils.pas`.  `Assert.Pass` became `Assert.Ignore`, so a Win32 run shows the test compared nothing.
- (2026-10-23) **The test suite was declared Win64-only, so the IDE and a default build never produced or ran a Win32 binary** - `Tests/Delphi.Mocks.Tests.dproj`.  Win32 is now enabled beside Win64 (`<Platform value="Win32">True</Platform>`, `TargetedPlatforms` 3).  Found by the 2026-10-23 Win32 pass over every gll* fork (Ian: "all our forks should be usable/up-to-date in Win32 and Win64"); it already built and passed with `/p:Platform=Win32`, so nothing else changed.  Win32 Release: **212 passed, 1 ignored (as on Win64)**; Win64 builds clean.
- (2026-10-13) **Tests that could not fail, and other test-suite defects** - every unit in `Tests\`. Five tests passed without checking anything (`Assert.Pass` bodies, an `Expect` never verified, a `WillRaise` on a non-virtual method, an RTL-only baseline, now deleted); about twenty were weak (`Assert.IsTrue(True)` endings, messages never checked, `SameText` where casing mattered, base-class or class-less `WillRaise`, a "different GUID" test using identical GUIDs). `ESimpleException` was an alias of `Exception`; two test interfaces shared a GUID; one test leaked six objects; `Test_CompareValue_RecordNoEqualsOperator` asserted that different records are equal and now asserts the opposite. The `Before`/`After`, safecall, simple-procedure and auto-mock-returned-interface tests are un-ignored; the one still ignored carries its reason. `ProxyBase` had no tests and has two. Now 213 tests: 212 pass, 1 ignored, 0 leaks.
- (2026-10-13) **Orphaned and dead test-project content removed** - `Tests\Delphi.Mocks.Examples.Factory.pas`, `Tests\Delphi.Mocks.Examples.Implement.pas`, `Tests\Delphi.Mocks.Examples.Objects.pas` (deleted: in neither the `.dpr` nor the `.dproj`, drifted from `Examples\`, and holding fakes), `Tests\Delphi.Mocks.Tests.dpr` (the commented-out classic DUnit runner, dead `{.$DEFINE}` / `ISCONSOLE` lines, `Forms`, `Sample1Main`, and a `{$WARN}` replaced by `DCC_DUPLICATE_CTOR_DTOR=false` in the `.dproj`), `Tests\Delphi.Mocks.Tests.dproj` (Android / iOS / OSX `ProjectRoot` deployment entries; version 0.3.2 with auto-increment and `Cfg_1_Win64` / `Cfg_2_Win64` groups; re-laid from tab-indented LF to the IDE's 4-space CRLF form).
- (2026-10-02) **Stale `TestInsight` build configuration removed; Debug is the default** -
  `Tests\Delphi.Mocks.Tests.dproj`, `Tests\Delphi.Mocks.Tests.dpr`. TestInsight was removed from the IDE on
  2026-09-29, and this config never defined `TESTINSIGHT`, so it was Debug under another name and sent
  IDE builds to `Win64\TestInsight`. The dead `{$IFDEF TESTINSIGHT}` runner block went with it.
  Win32 is now deactivated (`TargetedPlatforms` 3 -> 2), as for every DUnitX suite in the estate: a Win32
  build fails `F2613 Unit 'DUnitX.TestFramework' not found`, because the IDE's Win32 library path carries
  no DUnitX. The project's own `DUNITX` fallback (`..\..\gllDUnitX\Source`) cannot rescue it: it is set
  at the END of the file, after `DCC_UnitSearchPath` has already expanded `$(DUNITX)`, so command-line
  builds resolve DUnitX only through the IDE's `DUNITX` environment variable and Win64 library path.
- (2026-10-02) **A test run that died before reporting exited 0** - `Tests\Delphi.Mocks.Tests.dpr`.
  The runner's `except` printed the exception and left `ExitCode` alone, so a crash in setup or
  discovery read as a pass to anything gating on the exit code. It now sets `EXIT_ERRORS`.
- (2026-10-02) **`AllowRedefineBehaviorDefinitions_IsTrue_NoExceptionIsThrown_WhenMatcherAreDifferent` leaked its
  `TObjectToTest`** - `Tests\Delphi.Mocks.Tests.MethodData.pas`. Its `finally` freed two
  of the three objects it created; its sibling test frees all three.
- (2026-09-18) **`Tests\Delphi.Mocks.Tests.dpr` does not set `Assert.IgnoreCaseDefault := False`**
  , so this suite carries the fork's weak default and every two-argument string
  comparison in it is case-insensitive. `Test_WillReturnDefault` in
  `Delphi.Mocks.Tests.Stubs.pas` is a live example.
  **Fixed 2026-10-02:** the runner now sets it before the run. No test went red: 156 passed before
  and after, so nothing here had been relying on the weak default.
- (2026-08-24) The test project did not compile on Delphi 13: seven `Assert.AreEqual(n, Length(...))` calls could no longer infer a single generic argument now that `Length` returns `NativeInt` - `Tests/Delphi.Mocks.Tests.InterfaceProxy.pas`, `Tests/Delphi.Mocks.Tests.ObjectProxy.pas`, `Tests/Delphi.Mocks.Examples.Matchers.pas`
- (2026-08-24) The test project wrote its `.dcu` files into the project directory itself, which is why stale DUnitX units accumulated in `Tests\` - `Tests/Delphi.Mocks.Tests.dproj`

### Changed

- (2026-11-21) **Tests that rested on one "no exception" or "not nil" assertion now check what they name** — `Tests/Delphi.Mocks.Tests.Base.pas`, `Tests/Delphi.Mocks.Tests.Behavior.pas`, `Tests/Delphi.Mocks.Tests.MethodData.pas`, `Tests/Delphi.Mocks.Tests.ObjectProxy.pas`, `Tests/Delphi.Mocks.Utils.Tests.pas`.  From the 2026-11-21 fake-test audit: a created mock is used, a queried interface's calls reach its setup, a raising behaviour with no class returns nothing, two `Never When` / `WillReturnWhen` definitions with different matchers both survive ( and `AllowRedefineBehaviorDefinitions_IsTrue_…` now sets the option its name says ), the must-be-defined error is matched by message, and a setup recorded during mock setup is shown to fail `Verify`.  `CheckInterfaceHasRTTIWithNonInterface`'s summary now says what it pins.
- (2026-11-21) **The two regression units are in GITLAK style** — `Tests/Delphi.Mocks.Tests.Regression.pas`, `Tests/Delphi.Mocks.Tests.RegressionNewApi.pas`.  Locals take type prefixes ( `rMock`, `intfLog`, `iResult` ), 40 moved to inline declarations at their first assignment with the declared type kept, and the GExperts formatter applied ( `D:\Tools\Format-GExperts.ps1` ).  Formatting and renaming only, no test changed: still 40 tests, all green.  `Tests\` deliberately has no `GXFormatter.ini` ( the generator's policy: test units are full GITLAK style ).
- (2026-11-21) **The open array tests' ignore reason is one constant** — `Tests/Delphi.Mocks.Tests.OpenArrayIntf.pas`.  Three 193-character `[Ignore(...)]` lines, over the 162 limit.
- (2026-11-21) **The search path is relative again, and the project declares DPI unaware and no C++ output** — `Tests/Delphi.Mocks.Tests.dproj`.  `D:\gllDUnitX\Source\Gll` became `$(DUNITX)\Gll`, so a clone of this public repository builds wherever its sibling `gllDUnitX` is; `AppDPIAwarenessMode` unaware and `DCC_CBuilderOutput` None in the Base group.
- (2026-11-19) **The runner is `GllDUnitX.SuiteRunner` under FastMM5, with a leak check on every test** (Ian) — `Delphi.Mocks.Tests.dpr`, `Delphi.Mocks.Tests.dproj`, `Delphi.Mocks.Tests.Interfaces.pas`, `Delphi.Mocks.Tests.MethodData.pas`.  `FastMM5` first in the uses clause; `RunGllSuite` replaces the hand-written runner (warm-up pass, measured pass, re-run of flagged tests, GITLAK exit codes: 0 passed, n failures + errors + confirmed leaks clamped at 249, 250 no tests, 251 the runner raised, which was `EXIT_ERRORS`).  Kept: `Assert.IgnoreCaseDefault := False`, `FailsOnNoAsserts := False`, `UseRTTI`, the `--exit:pause` prompt outside `CI`.  Lost: nothing; the NUnit XML file is now always written (beside the exe unless `--xml` names a folder).  `D:\gllDUnitX\Source\Gll` added to the Base unit search path.  No TestInsight or EurekaLog to remove.  Leaks found: 5.  Test-side, 3: `CanMockSimpleProcedureCall` and the two `*_NoExceptionIsThrown_WhenMatcherAreDifferent` tests kept a closure in the mock / method data that shares the test's frame, which holds the mock: a reference cycle, now broken in a `finally`.  Product-side, 2: see the repository `CHANGELOG.md` § Fixed.  **Divergence weighed** (the gll* cross-use rule): the suite, not the library, gains `gllDUnitX` and `gllFastMM5`, which nothing upstream merges into, so no merge cost.  Result: 214 of 218 pass, 4 ignored: the one ignored before and three open array tests ( the two below, and `TestMyMethodDynamicArray`, which fails whenever its setup is the process's first open array call ), as BUG tests in `README.md`.

- (2026-10-26) **Unit-scope names in every `uses` clause** — `Tests/Delphi.Mocks.Examples.Matchers.pas`, `Tests/Delphi.Mocks.Tests.AutoMock.pas`, `Tests/Delphi.Mocks.Tests.Base.pas`, `Tests/Delphi.Mocks.Tests.Behavior.pas`, `Tests/Delphi.Mocks.Tests.dpr`, `Tests/Delphi.Mocks.Tests.InterfaceProxy.pas`, `Tests/Delphi.Mocks.Tests.Interfaces.pas`, `Tests/Delphi.Mocks.Tests.MethodData.pas`, `Tests/Delphi.Mocks.Tests.ObjectProxy.pas`, `Tests/Delphi.Mocks.Tests.Objects.pas`, `Tests/Delphi.Mocks.Tests.Proxy.pas`, `Tests/Delphi.Mocks.Tests.ProxyBase.pas`, `Tests/Delphi.Mocks.Tests.Stubs.pas`, `Tests/Delphi.Mocks.Tests.Utils.pas`.  31 bare RTL/VCL unit names in `uses` clauses given their unit-scope names; generated code is byte-identical in every mode built.  **Why:** Ian, 2026-10-26: "all the gll* forks are our own code because they have all been modified to suite our needs/preferences/standards".  Divergence from upstream: a later upstream merge conflicts wherever upstream edits a converted `uses` line; resolve by taking upstream's change and keeping the scoped spelling.
- (2026-08-24) The test project now resolves DUnitX from a sibling `gllDUnitX` checkout via the `DUNITX` property, with a `CheckDUnitX` target that fails with an actionable message - `Tests/Delphi.Mocks.Tests.dproj`
- (2026-08-24) Normalised the test sources to CRLF line endings - `Tests/Delphi.Mocks.Tests.Base.pas`,
  `Tests/Delphi.Mocks.Tests.dpr`
