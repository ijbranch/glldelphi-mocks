program Sample1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  Sample1Main in 'Sample1Main.pas',
  Delphi.Mocks.Example.ProjectSaveCheckVisitor in 'Delphi.Mocks.Example.ProjectSaveCheckVisitor.pas',
  Delphi.Mocks.Examples.Factory in 'Delphi.Mocks.Examples.Factory.pas',
  Delphi.Mocks.Examples.Implement in 'Delphi.Mocks.Examples.Implement.pas',
  Delphi.Mocks.Examples.Interfaces in 'Delphi.Mocks.Examples.Interfaces.pas',
  Delphi.Mocks.Examples.Matchers in 'Delphi.Mocks.Examples.Matchers.pas',
  Delphi.Mocks.Examples.Objects in 'Delphi.Mocks.Examples.Objects.pas';

/// <summary>Runs every example unit's demonstrations; each raises if it does not behave as it describes.
/// </summary>
procedure RunExamples;
var
  factory : TExample_MockFactoryTests;
  implement : TExample_InterfaceImplementTests;
  interfaces : Delphi.Mocks.Examples.Interfaces.TMockObjectTests;
  matchers : TExample_MatchersTests;
  objects : Delphi.Mocks.Examples.Objects.TMockObjectTests;
begin
  factory := TExample_MockFactoryTests.Create;
  try
    factory.Implement_Multiple_Interfaces;
    factory.Create_T_From_TypeInfo;
  finally
    factory.Free;
  end;

  implement := TExample_InterfaceImplementTests.Create;
  try
    implement.Implement_Single_Interface;
    implement.Implement_Multiple_Interfaces;
    implement.SetupAndVerify_Mulitple_Interfaces;
    implement.SetupAndVerify_Object_And_Interfaces;
  finally
    implement.Free;
  end;

  interfaces := Delphi.Mocks.Examples.Interfaces.TMockObjectTests.Create;
  try
    interfaces.Simple_Interface_Mock;
  finally
    interfaces.Free;
  end;

  matchers := TExample_MatchersTests.Create;
  try
    matchers.Match_parameter_values;
  finally
    matchers.Free;
  end;

  objects := Delphi.Mocks.Examples.Objects.TMockObjectTests.Create;
  try
    objects.MockObject_Can_Call_Function;
  finally
    objects.Free;
  end;
end;

begin
  try
    TesTObjectMock;
    Writeln('--------------');
    Test;
    Writeln('--------------');
    RunExamples;
    //Skipped when run with any parameter, so it can run unattended.
    if ParamCount = 0 then
      ReadLn;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      //A demonstration that fails must not exit 0 and read as a success.
      ExitCode := 1;
      if ParamCount = 0 then
        ReadLn;
    end;
  end;
end.
