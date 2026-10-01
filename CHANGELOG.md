# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

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

### Changed- **C++Builder output turned off** (2026-08-26). `DCC_CBuilderOutput` was `All`, so every build emitted `.hpp` / `.bpi` / `.a` / `.obj` files for a compiler that is **never in scope here** (standing rule: "I dont use C++ at all"). Across the estate that was 616 files and 90 MB of output nobody consumes, regenerated on every build; `gllSynEdit` alone accounted for 560. Now `None`. The `DCC_HppOutput` / `DCC_BpiOutput` / `DCC_ObjOutput` properties are left in place deliberately - they only say *where* such files would go, so with generation off they are inert, and removing them would enlarge the diff without changing behaviour. Verified: the affected packages rebuilt clean in every enabled mode, emitted no C++ artefacts, and rebuilt clean again after the existing ones were deleted (so nothing was load-bearing).

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
