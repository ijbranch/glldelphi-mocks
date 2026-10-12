unit Delphi.Mocks.Examples.Interfaces;

interface

uses
  SysUtils,
  Delphi.Mocks;

type
  {$M+}
  /// <summary>The interface the example mocks.</summary>
  TSimpleInterface = Interface
    ['{4131D033-2D80-42B8-AAA1-3C2DF0AC3BBD}']
    /// <summary>A procedure the system under test calls.</summary>
    procedure SimpleMethod;
  end;

  /// <summary>The interface of the system under test.</summary>
  TSystemUnderTestInf = Interface
    ['{5E21CA8E-A4BB-4512-BCD4-22D7F10C5A0B}']
    /// <summary>Calls SimpleMethod on the interface it was given.</summary>
    procedure CallsSimpleInterfaceMethod;
  end;
  {$M-}

  /// <summary>The system under test: it depends on a TSimpleInterface.</summary>
  TSystemUnderTest = class(TInterfacedObject, TSystemUnderTestInf)
  private
    /// <summary>The interface it depends on.</summary>
    FInternalInf : TSimpleInterface;
  public
    /// <summary>Creates the system under test.</summary>
    /// <param name="ARequiredInf">The interface it depends on.</param>
    constructor Create(const ARequiredInf: TSimpleInterface);
    /// <summary>Calls SimpleMethod on the interface it was given.</summary>
    procedure CallsSimpleInterfaceMethod;
  end;

  {$M+}
  /// <summary>Demonstrates mocking an interface and verifying an expectation.</summary>
  TMockObjectTests = class
  published
    /// <summary>Expects SimpleMethod to be called, runs the system under test, and verifies.</summary>
    /// <exception cref="EMockVerificationException">SimpleMethod was not called.</exception>
    procedure Simple_Interface_Mock;
  end;
  {$M-}




implementation

{ TMockObjectTests }

procedure TMockObjectTests.Simple_Interface_Mock;
var
  mock : TMock<TSimpleInterface>;
  sutObject : TSystemUnderTestInf;
begin
  //SETUP: Create a mock of the interface that is required by our system under test object.
  mock := TMock<TSimpleInterface>.Create;

  //SETUP: Add a check that SimpleMethod is called atleast once.
  mock.Setup.Expect.AtLeastOnce.When.SimpleMethod;

  //SETUP: Create the system under test object passing an instance of the mock interface it requires.
  sutObject := TSystemUnderTest.Create(mock.Instance);

  //TEST: Call CallsSimpleInterfaceMethod on the system under test.
  sutObject.CallsSimpleInterfaceMethod;

  //VERIFY: That our passed in interface was called at least once when CallsSimpleInterfaceMethod was called.
  mock.Verify('CallsSimpleInterfaceMethod should call SimpleMethod');
  WriteLn('Interfaces: SimpleMethod was called, and Verify passed.');
end;

{ TSystemUnderTest }

procedure TSystemUnderTest.CallsSimpleInterfaceMethod;
begin
  FInternalInf.SimpleMethod;
end;

constructor TSystemUnderTest.Create(const ARequiredInf: TSimpleInterface);
begin
  FInternalInf := ARequiredInf;
end;

end.
