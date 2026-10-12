{***************************************************************************}
{                                                                           }
{           Delphi Mocks                                                    }
{                                                                           }
{           From Delphi Mocks, by Vincent Parrett & Contributors            }
{           Modified (C) 2026 Ian Branch (GITLAK Software)                  }
{                                                                           }
{           Licensed under the Apache License, Version 2.0                  }
{           http://www.apache.org/licenses/LICENSE-2.0                      }
{                                                                           }
{***************************************************************************}

program Delphi.Mocks.Tests;

uses
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Windows.Console,
  DUnitX.Loggers.XML.NUnit,
  SysUtils,
  Delphi.Mocks.Tests.AutoMock in 'Delphi.Mocks.Tests.AutoMock.pas',
  Delphi.Mocks.Tests.Base in 'Delphi.Mocks.Tests.Base.pas',
  Delphi.Mocks.Tests.Behavior in 'Delphi.Mocks.Tests.Behavior.pas',
  Delphi.Mocks.Tests.Expectations in 'Delphi.Mocks.Tests.Expectations.pas',
  Delphi.Mocks.Tests.InterfaceProxy in 'Delphi.Mocks.Tests.InterfaceProxy.pas',
  Delphi.Mocks.Tests.Interfaces in 'Delphi.Mocks.Tests.Interfaces.pas',
  Delphi.Mocks.Tests.MethodData in 'Delphi.Mocks.Tests.MethodData.pas',
  Delphi.Mocks.Tests.ObjectProxy in 'Delphi.Mocks.Tests.ObjectProxy.pas',
  Delphi.Mocks.Tests.Objects in 'Delphi.Mocks.Tests.Objects.pas',
  Delphi.Mocks.Tests.OpenArrayIntf in 'Delphi.Mocks.Tests.OpenArrayIntf.pas',
  Delphi.Mocks.Tests.Proxy in 'Delphi.Mocks.Tests.Proxy.pas',
  Delphi.Mocks.Tests.ProxyBase in 'Delphi.Mocks.Tests.ProxyBase.pas',
  Delphi.Mocks.Tests.TValue in 'Delphi.Mocks.Tests.TValue.pas',
  Delphi.Mocks.Tests.Utils in 'Delphi.Mocks.Tests.Utils.pas',
  Delphi.Mocks.Utils.Tests in 'Delphi.Mocks.Utils.Tests.pas',
  Delphi.Mocks.Examples.Matchers in 'Delphi.Mocks.Examples.Matchers.pas',
  Delphi.Mocks.Tests.Stubs in 'Delphi.Mocks.Tests.Stubs.pas',
  Delphi.Mocks.Tests.ReturnTypePatch in 'Delphi.Mocks.Tests.ReturnTypePatch.pas',
  Delphi.Mocks.Tests.Regression in 'Delphi.Mocks.Tests.Regression.pas',
  Delphi.Mocks.Tests.RegressionNewApi in 'Delphi.Mocks.Tests.RegressionNewApi.pas';

{$R *.RES}


var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Two-argument string assertions compare case-sensitively; a test that does not care passes True
    Assert.IgnoreCaseDefault := False;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    if (TDUnitX.Options.XMLOutputFile <> '') then
    begin
      nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
      runner.AddLogger(nunitLogger);
    end;
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      //A run that dies before reporting must not exit 0 and read as a pass
      System.ExitCode := EXIT_ERRORS;
    end;
  end;



end.

