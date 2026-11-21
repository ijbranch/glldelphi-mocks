unit Delphi.Mocks.Utils.Tests;

interface
uses
  DUnitX.TestFramework;
type
  {$M+}
  /// <summary>Tests the RTTI checks made before a mock is created.</summary>
  [TestFixture]
  TUtilsTests = class
  published
    /// <summary>Proves an interface without method RTTI is reported as having none.</summary>
    procedure CheckInterfaceHasRTTIWithoutRTTI;
    /// <summary>Pins that CheckInterfaceHasRTTI does not check the type's kind: TObject, a class with methods, is
    /// reported as having RTTI too, despite the routine's name.  Its callers check the kind first
    /// ( TMocksValidation.CheckMockType ), so a class never reaches it there.</summary>
    procedure CheckInterfaceHasRTTIWithNonInterface;
    /// <summary>Proves an interface with method RTTI is reported as having it.</summary>
    procedure CheckInterfaceHasRTTIWithInterfaceRTTI;
  end;
  {$M-}

  {$M+}
  /// <summary>An interface with method RTTI.</summary>
  ITestable = interface
    /// <summary>A procedure.</summary>
    procedure DoSomething;
  end;
  {$M-}


implementation
uses
  Delphi.Mocks.Utils;
{ TUtilsTests }

procedure TUtilsTests.CheckInterfaceHasRTTIWithInterfaceRTTI;

begin
  Assert.IsTrue(CheckInterfaceHasRTTI(TypeInfo(ITestable)));
end;

procedure TUtilsTests.CheckInterfaceHasRTTIWithNonInterface;
begin
  Assert.IsTrue(CheckInterfaceHasRTTI(TypeInfo(TObject)));
end;

procedure TUtilsTests.CheckInterfaceHasRTTIWithoutRTTI;
begin
  Assert.IsFalse(CheckInterfaceHasRTTI(TypeInfo(IInterface)));
end;


initialization
  TDUnitX.RegisterTestFixture(TUtilsTests);
end.
