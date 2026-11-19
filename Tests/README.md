# DelphiMocksTests

The DUnitX suite of `glldelphi-mocks` ( `Delphi.Mocks.Tests.dpr`, GITLAKMCP target `DelphiMocksTests` ).  It runs
under FastMM5 through `GllDUnitX.SuiteRunner`, which checks every test for memory leaks; change history is in
`CHANGELOG.md` beside this file.

## Product bugs / ignored tests

| Test | Why it is ignored |
|---|---|
| `TestIOpenArray.TestOpenArraySetupsMatchByContents`, `TestIOpenArray.TestOpenArrayExpectationMatchesByContents`, `TestIOpenArray.TestMyMethodDynamicArray` | **BUG outside our code: `System.Rtti` ( RAD Studio 37.0 ).**  `TMethodImplementation.TInvokeInfo.LoadArguments` writes each call's open array type info into the method's shared `FParams` ( cached on the `TRttiMethod` for the whole process ), and `Intercept` frees it when the call returns.  From the second call of a method on, on any mock, the element type is read from the freed block, so the argument reaches the mock with its length but no elements: open arrays match by length only.  The old memory manager left the freed block intact and hid it.  The proper fix is a GITLAKRTL `System.Rtti` patch, which Ian decides on; un-ignore all three when it lands.  `TestMyMethodDynamicArray` is ignored too: it can pass only by length, and fails whenever its setup is the first open array call of the process ( the setup keeps real elements, the call brings none ), as the runner's warm-up pass showed. |
| `TTestMock.CreateMock_With_Object_Which_Has_RTTI_But_No_Exposed_Functions_Raises_Exception` | By design: `CheckClassHasRTTI` counts VMT slots, which cannot tell an empty class from one with only static methods, so the refusal is not asserted. |

`TTestTValue.Test_CompareValue_InterfaceNotEquals_AddressesFarApart` reports itself ignored ( `Assert.Ignore` ) only when
the two addresses 4 GB apart cannot be reserved.
