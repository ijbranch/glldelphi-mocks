unit Sample1Main;

interface

uses
  Delphi.Mocks;


/// <summary>Demonstrates a mock and a stub of an interface: behaviours, var and out parameters, matchers,
/// expectations, and a Verify that passes followed by one that fails on purpose.</summary>
procedure Test;

/// <summary>Demonstrates a mock of a class, including an abstract method.</summary>
procedure TesTObjectMock;


type
  {$M+}
  /// <summary>The interface the demonstration mocks.</summary>
  IFoo = interface
  ['{69162E72-8C1E-421B-B970-15230BBB3B2B}']
    /// <summary>Getter of MyProp.</summary>
    /// <returns>The property's value.</returns>
    function GetProp : string;
    /// <summary>Setter of MyProp.</summary>
    /// <param name="value">The new value.</param>
    procedure SetProp(const value : string);
    /// <summary>Getter of IndexedProp.</summary>
    /// <param name="index">The index.</param>
    /// <returns>The value at the index.</returns>
    function GetIndexProp(index : integer) : string;
    /// <summary>Setter of IndexedProp.</summary>
    /// <param name="index">The index.</param>
    /// <param name="value">The new value.</param>
    procedure SetIndexedProp(index : integer; const value : string);
    /// <summary>A function with one parameter.</summary>
    /// <param name="param">A number.</param>
    /// <returns>Some text.</returns>
    function Bar(const param : integer) : string;overload;
    /// <summary>A function with two parameters, overloading Bar. Both overloads share the name, so expectations
    /// set by name count calls to either.</summary>
    /// <param name="param">A number.</param>
    /// <param name="param2">Some text.</param>
    /// <returns>Some text.</returns>
    function Bar(const param : integer; const param2 : string) : string;overload;
    /// <summary>A function that returns an object the caller owns.</summary>
    /// <returns>The object.</returns>
    function ReturnObject : TObject;
    /// <summary>A procedure with no parameters.</summary>
    procedure TestMe;
    /// <summary>A procedure that sets a var parameter.</summary>
    /// <param name="msg">Receives a message.</param>
    procedure TestVarParam(var msg : string);
    /// <summary>A procedure that sets an out parameter.</summary>
    /// <param name="msg">Receives a message.</param>
    procedure TestOutParam(out msg : string);
    /// <summary>A read-write property.</summary>
    property MyProp : string read GetProp write SetProp;
    /// <summary>An indexed property.</summary>
    property IndexedProp[index : integer] : string read GetIndexProp write SetIndexedProp;
  end;
  {$M-} //important because otherwise the code below will fail!


implementation

uses
  System.SysUtils,
  System.Rtti;


procedure Test;
var
  mock : TMock<IFoo>; //our mock object
  stub : TStub<IFoo>; //our stub object;
  failing : TMock<IFoo>;
  msg  : string;
  obj  : TObject;


  procedure TestImplicit(value : IFoo);
  begin
    WriteLn('Calling Bar(1234567) : ' + value.Bar(1234567));
  end;

begin
  //Create our mock
  mock := TMock<IFoo>.Create;
  stub := TStub<IFoo>.Create;

  //Setup our stub.
  stub.Setup.WillReturnDefault('Bar', 'You called Bar on the stub and this is the default return value.' );

  //Setup the behavior of our mock.

  //setup a default return value for method Bar
  mock.Setup.WillReturnDefault('Bar','hello world');
  //A general rule first, then a specific one: where definitions overlap the most recent wins,
  //so Bar(2,'sdfsd') returns 'goodbye world' and any other two-argument call 'helloooooooo'.
  mock.Setup.WillReturn('helloooooooo').When.Bar(It(0).IsAny<integer>,It(1).IsAny<string>);
  //setup explicit return values when parameters are matched
  mock.Setup.WillReturn('blah blah').When.Bar(1);
  mock.Setup.WillReturn('goodbye world').When.Bar(2,'sdfsd');
  //method TestMe will raise an exception
  mock.Setup.WillRaise(EMockException,'You called me when I told you not to!').When.TestMe;

  //MyProp return value - note it really sets up the return value
  //for the getter method
  mock.Setup.WillReturn('hello').When.MyProp;

  mock.Setup.WillExecute(
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      //Note - args[0] is the Self interface reference for the anon method, our first arg is [1]
      result := 'The result is ' + IntToStr(args[1].AsOrdinal);
    end
    ).When.Bar(200);

  mock.Setup.WillExecute(
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      args[1] := 'hello Delphi Mocks!';
    end
    ).When.TestVarParam(msg);

  mock.Setup.WillExecute(
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      args[1] := 'hello Delphi Mocks! - With out Param';
    end
    ).When.TestOutParam(msg);


  mock.Setup.WillExecute(
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      //A new object each call; the caller owns it.
      result := TObject.Create;
    end
    ).When.ReturnObject;

  //Define our expectations - mostly about how many times we expect a method to be called.

  //we expect the TestMe method to be called exactly once
  mock.Setup.Expect.Once.When.TestMe;

  //we expect Bar to be called at least once with a param value of 1
  mock.Setup.Expect.AtLeastOnce.When.Bar(1);

  mock.Setup.Expect.AtLeastOnce.When.Bar(99);
  mock.Setup.Expect.Between(2,4).When.Bar(23);

  //Both Bar overloads share the name, so all nine Bar calls below count.
  mock.Setup.Expect.Exactly('Bar',9);


 //Now use our mock object
  mock.Instance.MyProp := 'hello';
  mock.Instance.IndexedProp[1] := 'hello';

  mock.Instance.TestVarParam(msg);
  WriteLn('Calling TestVarParam set msg to : ' + msg);

  mock.Instance.TestOutParam(msg);
  WriteLn('Calling TestOutParam set msg to : ' + msg);


  WriteLn('Calling Bar(1) : ' + mock.Instance.Bar(1));
  WriteLn('Calling Bar(2) : ' + mock.Instance.Bar(2));
  WriteLn('Calling Bar(999,sdfsd) : ' + mock.Instance.Bar(999,'sdfsd'));
  WriteLn('Calling Bar(2,sdfsd) : ' + mock.Instance.Bar(2,'sdfsd'));
  WriteLn('Calling Bar(200) : ' + mock.Instance.Bar(200));
  WriteLn('Calling Bar(99) : ' + mock.Instance.Bar(99));
  WriteLn('Calling Bar(23) : ' + mock.Instance.Bar(23));
  WriteLn('Calling Bar(23) : ' + mock.Instance.Bar(23));

  obj := mock.Instance.ReturnObject;
  try
    WriteLn('Calling1 ReturnObject : ' + obj.ClassName);
  finally
    obj.Free;
  end;


  WriteLn(stub.Instance.Bar(1234));


  //Test the implicit operator by calling a method that expects IFoo
  TestImplicit(mock);
  try
    // test a method that we have setup to throw an exception
    mock.Instance.TestMe;
  except
    on e : EMockException do
    begin
      WriteLn('We caught an exception : ' + e.Message);
    end;
  end;

  //Every expectation above is met, so this passes.
  mock.Verify('did it work???');
  WriteLn('Verify passed: every expectation was met.');

  //And one that fails on purpose, to show what Verify reports.
  failing := TMock<IFoo>.Create;
  failing.Setup.Expect.Once('TestMe');
  try
    failing.Verify('TestMe was never called');
  except
    on e : EMockVerificationException do
      WriteLn('Verify failed, as intended : ' + e.Message);
  end;
end;

type
  TFoo = class
  public
    function Bar(const param : integer) : string;overload;virtual;
    function Bar(const param : integer; const param2 : string) : string;overload;virtual;
    procedure TestMe;virtual;
    function ReadString(const AName: string): string; virtual; abstract;
  end;

procedure TesTObjectMock;
var
  mock : TMock<TFoo>;
begin
  mock := TMock<TFoo>.Create;
  try
    mock.Setup.WillReturn('hello world').When.Bar(99);
    mock.Setup.WillReturn('hello world2').When.Bar(99,'abc');
    mock.Setup.WillReturn('..\datadefinitions\').When.ReadString('DefinitionPath');
    mock.Setup.WillReturn('test\').When.ReadString('Path');
    WriteLn('Bar(99) returned : ' +  mock.Instance.Bar(99));
    WriteLn('Bar(99,abc) returned : ' +  mock.Instance.Bar(99,'abc'));
    Writeln('ReadString(''DefinitionPath'') returned : ' + mock.Instance.ReadString('DefinitionPath'));
    Writeln('ReadString(''Path'') returned : ' + mock.Instance.ReadString('Path'));
  finally
    mock.Free;
  end;
end;

{ TFoo }

function TFoo.Bar(const param: integer): string;
begin
  result := IntToStr(param);
end;

function TFoo.Bar(const param: integer; const param2: string): string;
begin
  result := IntToStr(param) + '-' + param2;
end;



procedure TFoo.TestMe;
begin
  //do nothing
end;

end.
