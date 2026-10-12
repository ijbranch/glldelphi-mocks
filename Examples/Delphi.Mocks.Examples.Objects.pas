unit Delphi.Mocks.Examples.Objects;

interface

uses
  SysUtils,
  Delphi.Mocks;

type
  /// <summary>The exception the example makes the mock raise. A class of its own: it used to be declared as
  /// "= exception", an alias, so expecting it really meant expecting any Exception.</summary>
  ESimpleException = class(Exception);
  {$M+}
  /// <summary>The class the example mocks; SimpleMethod is virtual, so it can be intercepted.</summary>
  TSimpleMockedObject = class(TObject)
  public
    /// <summary>Does nothing in the real class.</summary>
    procedure SimpleMethod;virtual;
  end;
  {$M-}

  /// <summary>The code under test: it calls SimpleMethod on the object it is given.</summary>
  TSystemUnderTest = class(TObject)
  private
    /// <summary>The object it calls; not owned.</summary>
    FMocked : TSimpleMockedObject;
  public
    /// <summary>Creates the system under test.</summary>
    /// <param name="AMock">The object to call; not owned.</param>
    constructor Create(const AMock: TSimpleMockedObject);
    /// <summary>Calls SimpleMethod on the object.</summary>
    procedure CallsSimpleMethodOnMock;virtual;
  end;

  {$M+}
  /// <summary>Demonstrates mocking a class.</summary>
  TMockObjectTests = class
  published
    /// <summary>Makes the mocked SimpleMethod raise, and shows the system under test receiving that exception.
    /// </summary>
    /// <exception cref="Exception">The demonstration did not behave as described.</exception>
    procedure MockObject_Can_Call_Function;virtual;
  end;
  {$M-}

implementation

{ TMockObjectTests }

procedure TMockObjectTests.MockObject_Can_Call_Function;
var
  mock : TMock<TSimpleMockedObject>;
  systemUnderTest : TSystemUnderTest;
  raised : Boolean;
begin
  //var mock = new Mock<IFoo>();
  //mock.Setup(foo => foo.DoSomething("ping")).Returns(true);
  mock := TMock<TSimpleMockedObject>.Create;

  mock.Setup.WillRaise('SimpleMethod', ESimpleException);

  raised := False;
  systemUnderTest := TSystemUnderTest.Create(mock.Instance);
  try
    try
      systemUnderTest.CallsSimpleMethodOnMock;
    except
      on ESimpleException do
        raised := True;
    end;
  finally
   systemUnderTest.Free;
  end;

  if not raised then
    raise Exception.Create('The mocked SimpleMethod did not raise ESimpleException');
  WriteLn('Objects: the mocked SimpleMethod raised ESimpleException, as set up.');
end;

{ TSimpleObject }

procedure TSimpleMockedObject.SimpleMethod;
begin
 //Does nothing;
end;

{ TSystemUnderTest }

procedure TSystemUnderTest.CallsSimpleMethodOnMock;
begin
  FMocked.SimpleMethod;
end;

constructor TSystemUnderTest.Create(const AMock: TSimpleMockedObject);
begin
  FMocked := AMock;
end;

end.
