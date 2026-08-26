# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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

- `Delphi.Mocks.ReturnTypePatch.pas` shadow-declares private `System.Rtti` fields to patch RTTI. The layout still matches RAD Studio 37.0, but this breaks silently if Embarcadero reorders them.
- `Delphi.Mocks.ObjectProxy.pas` frees the wrapped instance unconditionally, even when the caller supplied it. Changing that is an ownership contract change, so it is left alone deliberately.
- The repo still carries 15 RAD Studio package folders, legacy packages under `Source`, and Win32/OSX/mobile targets. It has not been scoped down the way `gllDUnitX` was.
