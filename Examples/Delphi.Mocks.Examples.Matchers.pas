unit Delphi.Mocks.Examples.Matchers;

interface

type
  {$M+}
  /// <summary>The interface the example mocks.</summary>
  IInterfaceToTest = interface
    ['{2AB032A9-ED5B-4FDC-904B-E3F1B2C78978}']
    /// <summary>A function of two parameters.</summary>
    /// <param name="A">A number.</param>
    /// <param name="B">A flag.</param>
    /// <returns>A number.</returns>
    function TakesTwoParams(const A: integer; const B: boolean) : integer;
    /// <summary>A function of four parameters.</summary>
    /// <param name="A">Some text.</param>
    /// <param name="B">A flag.</param>
    /// <param name="C">A number.</param>
    /// <param name="D">More text.</param>
    /// <returns>A number.</returns>
    function TakesFourParams(const A: string; const B: boolean; const C: integer; const D: string) : integer;
  end;
  {$M-}

  {$M+}
  /// <summary>Demonstrates parameter matchers (It0..It9).</summary>
  TExample_MatchersTests = class
  published
    /// <summary>Sets up results for particular argument patterns and shows each call picking the right one.
    /// </summary>
    /// <exception cref="Exception">The demonstration did not behave as described.</exception>
    procedure Match_parameter_values;
  end;
  {$M-}


implementation

uses
  SysUtils,
  Delphi.Mocks;

/// <summary>Raises when a demonstration's result is not the one it describes.</summary>
/// <param name="AExpected">The described result.</param>
/// <param name="AActual">The actual result.</param>
/// <param name="ACall">The call, for the message.</param>
/// <exception cref="Exception">The results differ.</exception>
procedure CheckResult(const AExpected, AActual: Integer; const ACall: string);
begin
  if AExpected <> AActual then
    raise Exception.CreateFmt('Matchers: %s returned %d, expected %d', [ACall, AActual, AExpected]);
  WriteLn(Format('Matchers: %s returned %d', [ACall, AActual]));
end;

{ TExample_MatchersTests }


procedure TExample_MatchersTests.Match_parameter_values;
var
  mockCredit: TMock<IInterfaceToTest>;
begin
  mockCredit := TMock<IInterfaceToTest>.Create;

  mockCredit.Setup.WillReturn(6).When.TakesTwoParams(It(0).IsEqualTo<integer>(1), It(1).IsEqualTo<boolean>(true));
  mockCredit.Setup.WillReturn(12).When.TakesTwoParams(It(0).IsEqualTo<integer>(2), It(1).IsEqualTo<boolean>(true));
  mockCredit.Setup.WillReturn(8).When.TakesTwoParams(It(0).IsAny<integer>(), It(1).IsEqualTo<boolean>(false));

  mockCredit.Setup.WillReturn(1).When.TakesFourParams(It0.IsAny<string>(), It1.IsEqualTo<boolean>(false),
    It2.IsEqualTo<integer>(1), It3.IsEqualTo<string>('hello'));

  CheckResult(6, mockCredit.Instance.TakesTwoParams(1, true), 'TakesTwoParams(1, true)');
  CheckResult(12, mockCredit.Instance.TakesTwoParams(2, true), 'TakesTwoParams(2, true)');
  CheckResult(8, mockCredit.Instance.TakesTwoParams(1, false), 'TakesTwoParams(1, false)');

  CheckResult(1, mockCredit.Instance.TakesFourParams('asdfasfasdf', false, 1, 'hello'), 'TakesFourParams(''asdfasfasdf'', false, 1, ''hello'')');
  CheckResult(1, mockCredit.Instance.TakesFourParams('asdfjkljklsdfjf', false, 1, 'hello'),
    'TakesFourParams(''asdfjkljklsdfjf'', false, 1, ''hello'')');
end;

end.
