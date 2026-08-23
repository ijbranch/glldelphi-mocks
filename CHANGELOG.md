# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- The 12 `W1029` "Duplicate constructor ... will be inaccessible from C++" warnings that `TExpectation`
  emitted into every consuming build (2026-08-24) - `Source/Delphi.Mocks.Expectation.pas`
  **Why:** the unit told callers to put `{$WARN DUPLICATE_CTOR_DTOR OFF}` in their `.dpr`, but a `{$WARN}`
  there does not affect how a separate unit is compiled, so the advice never worked. The directive now sits
  in the unit that emits the warnings. A consuming build went from 13 warnings to 1.

### Changed

- Normalised the test sources to CRLF line endings (2026-08-24) - `Tests/Delphi.Mocks.Tests.Base.pas`,
  `Tests/Delphi.Mocks.Tests.dpr`

### Known Issues

Found by audit on 2026-08-24, all inherited from upstream and none yet fixed:

- `Delphi.Mocks.AutoMock.pas` - `TAutoMock.Destroy` never frees `FMocks`, and `TAutoMockContainer` forms a
  reference cycle with `TProxy` (`Proxy.pas` holds `IAutoMock` strongly while the container holds `IProxy`
  strongly). Everything reachable from a `TAutoMockContainer` leaks. Plain `TMock<T>` is unaffected.
- `Delphi.Mocks.Proxy.pas` - `TProxy<T>._Release` raises without calling `inherited`, so the refcount is
  never decremented and the raise happens during interface finalisation. The non-generic twin in
  `Proxy.TypeInfo.pas` does not do this.
- `Delphi.Mocks.ParamMatcher.pas` - the matcher dictionary is created with `doOwnsValues` and its values are
  also freed manually, a double free on any aborted `Setup`.
- `Delphi.Mocks.ReturnTypePatch.pas` shadow-declares private `System.Rtti` fields to patch RTTI. The layout
  still matches RAD Studio 37.0, but this breaks silently if Embarcadero reorders those fields.
- The repo still carries 15 RAD Studio package folders, legacy packages under `Source`, and Win32/OSX/mobile
  targets. It has not been scoped down the way `gllDUnitX` was.
