# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- Debug and Release package artefacts no longer overwrite each other (2026-08-24) - `packages/RAD Studio 13.0/VSoft.DelphiMocksR.dproj`
  **Why:** RAD Studio defaults the .bpl and .dcp output paths to `$(BDSCOMMONDIR)\Bpl\$(Platform)` and `\Dcp\$(Platform)`, neither carrying `$(Config)`, so a Debug build silently replaced the Release artefacts. Both now include `$(Config)`, matching the `.dcu` output that was already separated.
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
