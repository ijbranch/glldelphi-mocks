unit Delphi.Mocks.Examples.Implement;

interface

uses
  Delphi.Mocks.Example.ProjectSaveCheckVisitor;

type
  {$M+}
  /// <summary>Demonstrates a mock that implements more than one interface (Implement&lt;I&gt;).</summary>
  TExample_InterfaceImplementTests = class
  published
    /// <summary>Shows that QueryInterface itself cannot be mocked: the mock answers it internally, so the setup
    /// never reaches the mock and is reported as abandoned. Implement&lt;I&gt; is the way to do this.</summary>
    /// <exception cref="Exception">The demonstration did not behave as described.</exception>
    procedure Implement_Single_Interface;
    /// <summary>Gives an element mock the IProject interface, and verifies the visitor saved it.</summary>
    /// <exception cref="EMockVerificationException">The project was not saved.</exception>
    procedure Implement_Multiple_Interfaces;
    /// <summary>Sets up and verifies two implemented interfaces separately.</summary>
    /// <exception cref="EMockVerificationException">An expectation was not met.</exception>
    procedure SetupAndVerify_Mulitple_Interfaces;
    /// <summary>Shows that a mock of a class cannot implement further interfaces.</summary>
    /// <exception cref="Exception">The demonstration did not behave as described.</exception>
    procedure SetupAndVerify_Object_And_Interfaces;
  end;
  {$M-}


implementation

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  Delphi.Mocks;

type
  {$M+}
  /// <summary>An element with a virtual method, so it can be mocked as a class.</summary>
  TVirtualElement = class(TInterfacedObject, IElement)
  public
    /// <summary>Accepts a visitor; does nothing.</summary>
    /// <param name="AVisitor">The visitor.</param>
    procedure Accept(const AVisitor : IVisitor); virtual;
  end;
  {$M-}

procedure TVirtualElement.Accept(const AVisitor: IVisitor);
begin
end;

{ TExample_InterfaceImplementTests }

procedure TExample_InterfaceImplementTests.Implement_Single_Interface;
var
  mockElement : TMock<IElement>;
  mockProject : TMock<IProject>;
  reported : Boolean;

  //The setup's temporary references are released when the routine that made them ends, and
  //that release is when the mock reports the abandoned setup - so make them in a routine of
  //their own, inside the try.
  procedure TryToMockQueryInterface;
  var
    dud : IProject;
  begin
    mockElement.Setup.WillReturn(TValue.From(mockProject.Instance)).When.QueryInterface(
      GetTypeData(TypeInfo(IProject)).GUID, dud);
  end;

begin
  //CREATE - Element mock we require.
  mockElement := TMock<IElement>.Create;
  mockProject := TMock<IProject>.Create;

  //SETUP - try to make QueryInterface return the mock project. QueryInterface is answered by the
  //mock itself, never by a behaviour, so this setup is abandoned and the mock says so.
  reported := False;
  try
    TryToMockQueryInterface;
  except
    on e : EMockSetupException do
    begin
      reported := True;
      WriteLn('Implement: mocking QueryInterface is refused - ' + e.Message);
    end;
  end;

  if not reported then
    raise Exception.Create('Mocking QueryInterface was expected to be refused');
end;

procedure TExample_InterfaceImplementTests.Implement_Multiple_Interfaces;
var
  visitorSUT : IVisitor;
  mockElement : TMock<IElement>;
begin
  //Test that when we visit a project, and its dirty, we save.

  //CREATE - The visitor system under test.
  visitorSUT := TProjectSaveCheck.Create;

  //CREATE - Element mock we require.
  mockElement := TMock<IElement>.Create;

  //SETUP - Add the IProject interface as an implementation for the mock
  mockElement.Implement<IProject>;

  //SETUP - mock project will show as dirty and will expect to be saved.
  mockElement.Setup<IProject>.WillReturn(true).When.IsDirty;
  mockElement.Setup<IProject>.Expect.Once.When.Save;

  //TEST - Visit the mock element with
  visitorSUT.Visit(mockElement);

  //VERIFY - Make sure that save was indeed called.
  mockElement.VerifyAll;
  WriteLn('Implement: the element mock answered as an IProject, and was saved.');
end;

procedure TExample_InterfaceImplementTests.SetupAndVerify_Mulitple_Interfaces;
var
  mockElement : TMock<IElement>;
begin
  mockElement := TMock<IElement>.Create;
  mockElement.Implement<IProject>;
  mockElement.Implement<IVisitor>;

  //SETUP - each implemented interface has its own setup.
  mockElement.Setup<IVisitor>.Expect.Once.When.Visit(It0.IsAny<IElement>);
  mockElement.Setup<IProject>.Expect.Never.When.Save;

  //TEST - use the mock as each interface in turn.
  mockElement.Instance<IVisitor>.Visit(mockElement);

  //VERIFY - each interface on its own, then everything at once.
  mockElement.Verify<IVisitor>('Visit should have been called once');
  mockElement.Verify<IProject>('Save should not have been called');
  mockElement.VerifyAll;
  WriteLn('Implement: two implemented interfaces were set up and verified separately.');
end;

procedure TExample_InterfaceImplementTests.SetupAndVerify_Object_And_Interfaces;
var
  mockElement : TMock<TVirtualElement>;
  refused : Boolean;
begin
  //A class mock is a real instance whose virtual methods are intercepted; it cannot take on
  //further interfaces, and Implement says so.
  mockElement := TMock<TVirtualElement>.Create;
  refused := False;
  try
    mockElement.Implement<IProject>;
  except
    on e : ENotSupportedException do
    begin
      refused := True;
      WriteLn('Implement: a class mock cannot implement IProject - ' + e.Message);
    end;
  end;

  if not refused then
    raise Exception.Create('Implement on a class mock was expected to be refused');
end;

end.
