{***************************************************************************}
{                                                                           }
{           glldelphi-mocks                                                 }
{                                                                           }
{           Copyright (C) 2026 Ian Branch (GITLAK Software)                 }
{           Added in the glldelphi-mocks fork of Delphi Mocks               }
{                                                                           }
{           Licensed under the Apache License, Version 2.0                  }
{           http://www.apache.org/licenses/LICENSE-2.0                      }
{                                                                           }
{***************************************************************************}

unit Delphi.Mocks.Tests.Review;

{ GITLAK addition (2026-11-21). One test per defect found by the 2026-11-21 deep review, each red on the library
  before its fix. }

interface

uses
  System.Classes,
  System.SysUtils,
  System.Rtti,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  /// <summary>A record argument with a managed field.</summary>
  TRvRec = record
    /// <summary>A string, so two equal records can hold their text in different strings.</summary>
    Name: string;
    /// <summary>A number.</summary>
    Num: Integer;
  end;

  /// <summary>A record with an = operator for another type, declared before its own one.</summary>
  TRvOpRec = record
    /// <summary>The compared value.</summary>
    Value: Integer;
    /// <summary>Compares with an Integer; the comparison of two records must not pick this one.</summary>
    /// <param name="A">The record.</param>
    /// <param name="B">The number.</param>
    /// <returns>True when Value is B.</returns>
    class operator Equal( const A: TRvOpRec; const B: Integer ): Boolean;
    /// <summary>Compares two records.</summary>
    /// <param name="A">The first record.</param>
    /// <param name="B">The second record.</param>
    /// <returns>True when their values are equal.</returns>
    class operator Equal( const A, B: TRvOpRec ): Boolean;
  end;

  /// <summary>A class whose only field is private.</summary>
  TRvPrivateFields = class
  private
    /// <summary>The state, invisible to the public-member comparison.</summary>
    FValue: Integer;
  public
    /// <summary>Creates the instance.</summary>
    /// <param name="AValue">The state.</param>
    constructor Create( const AValue: Integer );
  end;

  /// <summary>The base class of a polymorphic field.</summary>
  TRvAnimal = class
  public
    /// <summary>A field both descendants share.</summary>
    Legs: Integer;
  end;

  /// <summary>One descendant.</summary>
  TRvDog = class( TRvAnimal )
  public
    /// <summary>A field only dogs have.</summary>
    Barks: Integer;
  end;

  /// <summary>Another descendant.</summary>
  TRvCat = class( TRvAnimal )
  public
    /// <summary>A field only cats have.</summary>
    Meows: Integer;
  end;

  /// <summary>A class holding a polymorphic object field.</summary>
  TRvOwner = class
  public
    /// <summary>The pet; a TRvDog or a TRvCat.</summary>
    Pet: TRvAnimal;
    /// <summary>Frees the pet.</summary>
    destructor Destroy; override;
  end;

  /// <summary>An exception whose own constructor does work the base constructor does not.</summary>
  ERvCustom = class( Exception )
  public
    /// <summary>Set to 42 by the constructor.</summary>
    Code: Integer;
    /// <summary>Creates the exception, setting Code.</summary>
    /// <param name="Msg">The message.</param>
    constructor Create( const Msg: string );
  end;

  /// <summary>A class with a public field and a virtual method, so it can be both mocked and compared.</summary>
  TRvMocked = class
  public
    /// <summary>The compared state.</summary>
    Value: Integer;
    /// <summary>A virtual method, so the class can be mocked.</summary>
    /// <returns>Value, unless mocked.</returns>
    function Get: Integer; virtual;
  end;

  /// <summary>The exception a When argument raises.</summary>
  ERvArgument = class( Exception );

{$M+}
  /// <summary>An interface to mock.</summary>
  IRvCalc = interface
    [ '{7C0D3E52-1A6B-4F0E-9B3C-2D4E5F6A7B81}' ]
    /// <summary>A function of one argument.</summary>
    /// <param name="A">The argument.</param>
    /// <returns>Whatever the mock says.</returns>
    function Calc( const A: Integer ): Integer;
    /// <summary>A function of two arguments.</summary>
    /// <param name="A">The first argument.</param>
    /// <param name="B">The second argument.</param>
    /// <returns>Whatever the mock says.</returns>
    function Calc2( const A, B: Integer ): Integer;
    /// <summary>A procedure.</summary>
    procedure Ping;
    /// <summary>A function of a string.</summary>
    /// <param name="S">The argument.</param>
    /// <returns>Whatever the mock says.</returns>
    function Name( const S: string ): Integer;
    /// <summary>A function of a float.</summary>
    /// <param name="D">The argument.</param>
    /// <returns>Whatever the mock says.</returns>
    function Ratio( const D: Double ): Integer;
    /// <summary>Takes a record.</summary>
    /// <param name="R">The argument.</param>
    procedure TakeRec( const R: TRvRec );
    /// <summary>Takes a class with private fields only.</summary>
    /// <param name="O">The argument.</param>
    procedure TakePrivate( const O: TRvPrivateFields );
    /// <summary>Takes a class with a polymorphic field.</summary>
    /// <param name="O">The argument.</param>
    procedure TakeOwner( const O: TRvOwner );
    /// <summary>Takes a mockable class.</summary>
    /// <param name="O">The argument.</param>
    procedure TakeMocked( const O: TRvMocked );
    /// <summary>A function of a Variant.</summary>
    /// <param name="V">The argument.</param>
    /// <returns>Whatever the mock says.</returns>
    function Vary( const V: Variant ): Integer;
  end;

  /// <summary>An interface with overloads that differ only in parameter type.</summary>
  IRvOverloads = interface
    [ '{7C0D3E52-1A6B-4F0E-9B3C-2D4E5F6A7B82}' ]
    /// <summary>The Integer overload.</summary>
    /// <param name="A">The argument.</param>
    /// <returns>Whatever the mock says.</returns>
    function Foo( const A: Integer ): Integer; overload;
    /// <summary>The Boolean overload.</summary>
    /// <param name="A">The argument.</param>
    /// <returns>Whatever the mock says.</returns>
    function Foo( const A: Boolean ): Integer; overload;
  end;

  /// <summary>An interface a reference-counted class implements.</summary>
  IRvPing = interface
    [ '{7C0D3E52-1A6B-4F0E-9B3C-2D4E5F6A7B83}' ]
    /// <summary>A procedure.</summary>
    procedure Ping;
  end;

  /// <summary>A reference-counted class to mock.</summary>
  TRvInterfaced = class( TInterfacedObject, IRvPing )
  public
    /// <summary>Does nothing.</summary>
    procedure Ping; virtual;
    /// <summary>A virtual function.</summary>
    /// <returns>1, unless mocked.</returns>
    function Value: Integer; virtual;
  end;

  /// <summary>A plain class to mock.</summary>
  TRvVirtual = class
  public
    /// <summary>A virtual function.</summary>
    /// <param name="A">The argument.</param>
    /// <returns>A, unless mocked.</returns>
    function Calc( const A: Integer ): Integer; virtual;
  end;
{$M-}

  /// <summary>Tests of the defects the 2026-11-21 review found.</summary>
  [ TestFixture ]
  TReviewTests = class
  public
    /// <summary>Proves AreSameFieldsThat refuses, at setup, a class with no public or published field: it compared
    /// nothing and so matched any instance.</summary>
    [ Test ]
    procedure AreSameFieldsThat_Refuses_Class_With_No_Comparable_Field;
    /// <summary>Proves AreSameFieldsThat still tells apart instances whose public fields differ, and accepts equal
    /// ones.</summary>
    [ Test ]
    procedure AreSameFieldsThat_Compares_Public_Fields;
    /// <summary>Proves two object fields of different runtime classes are unequal even when every field of the
    /// declared class agrees: only the declared class's fields used to be compared.</summary>
    [ Test ]
    procedure AreSameFieldsThat_Object_Fields_Of_Different_Classes_Differ;
    /// <summary>Proves a class mock of a reference-counted class survives the code under test releasing the last
    /// interface reference, and is freed exactly once: it used to be freed by the release and again by the mock.
    /// </summary>
    [ Test ]
    procedure Class_Mock_Of_Interfaced_Class_Owns_Its_Instance;
    /// <summary>Proves a matcher pending from a When whose arguments raised does not attach itself to the next
    /// setup.</summary>
    [ Test ]
    procedure Matcher_From_Failed_When_Does_Not_Attach_To_Next_Setup;
    /// <summary>Proves a call on another mock while the When arguments are evaluated does not discard the
    /// matchers already given.</summary>
    [ Test ]
    procedure Call_On_Other_Mock_In_When_Arguments_Keeps_Matchers;
    /// <summary>Pins the documented meaning of WillRaise(...).When: it raises for every call of the method, while
    /// WillRaiseWhen raises only for matching arguments.</summary>
    [ Test ]
    procedure WillRaise_When_Raises_For_Any_Arguments_WillRaiseWhen_Only_For_Matching;
    /// <summary>Proves concurrent calls from several threads are all counted and none fails.</summary>
    [ Test ]
    procedure Concurrent_Calls_Are_All_Counted;
    /// <summary>Proves AllowRedefineBehaviorDefinitions set after a method was first set up applies to it.</summary>
    [ Test ]
    procedure AllowRedefine_Set_After_First_Setup_Applies;
    /// <summary>Proves BehaviorMustBeDefined set after a method was first called applies to it.</summary>
    [ Test ]
    procedure BehaviorMustBeDefined_Set_After_First_Call_Applies;
    /// <summary>Proves BehaviorMustBeDefined is enforced on a mock made by an auto mock container.</summary>
    [ Test ]
    procedure BehaviorMustBeDefined_Enforced_With_AutoMocker;
    /// <summary>Proves a setup on one overload neither answers nor is counted by a call to another overload with
    /// an argument of the same ordinal value.</summary>
    [ Test ]
    procedure Overloads_Do_Not_Share_Literal_Setups;
    /// <summary>Proves a setup by method name refuses a name the mocked type does not have.</summary>
    [ Test ]
    procedure Setup_By_Name_Refuses_Unknown_Method;
    /// <summary>Proves IsEqualTo matches a record by its contents, as a literal argument does, not by its bytes.
    /// </summary>
    [ Test ]
    procedure IsEqualTo_Record_Compares_Contents;
    /// <summary>Proves a class mock runs a behaviour's matcher once per call, and not at all during a later setup.
    /// </summary>
    [ Test ]
    procedure Class_Mock_Runs_Matcher_Once_Per_Call_And_Not_During_Setup;
    /// <summary>Proves a setup by method name reports a pending When setup rather than silently discarding it.
    /// </summary>
    [ Test ]
    procedure Setup_By_Name_Reports_Pending_When_Setup;
    /// <summary>Proves PatchMethodReturnType by name refuses a method name the interface does not have.</summary>
    [ Test ]
    procedure PatchMethodReturnType_Refuses_Unknown_Method;
    /// <summary>Proves the abandoned-setup message names TObject's methods as a cause, as When.ToString on a class
    /// mock is one of them.</summary>
    [ Test ]
    procedure Abandoned_Setup_Message_Names_TObject_Methods;
    /// <summary>Proves a setup with a NaN argument matches a call with NaN.</summary>
    [ Test ]
    procedure NaN_Argument_Matches_NaN;
    /// <summary>Proves CompareValue orders two different method pointers consistently: swapping them swaps the
    /// sign.</summary>
    [ Test ]
    procedure CompareValue_Method_Pointers_Are_Antisymmetric;
    /// <summary>Proves WillRaise runs the exception class's own constructor.</summary>
    [ Test ]
    procedure WillRaise_Runs_The_Exception_Class_Constructor;
    /// <summary>Proves WillRaise refuses a nil exception class at setup, rather than returning a default later.
    /// </summary>
    [ Test ]
    procedure WillRaise_Refuses_Nil_Exception_Class;
    /// <summary>Proves a Verify report has no leading blank line for an empty message, names the mocked type,
    /// quotes string arguments and lists methods in name order.</summary>
    [ Test ]
    procedure Verify_Report_Is_Clear;
    /// <summary>Proves the documented way out of the reference cycle a WillExecute closure capturing its own mock
    /// makes: Free on the mock releases it, so the suite's leak check finds nothing.  Without the Free the mock,
    /// its proxy and its method data all leak.</summary>
    [ Test ]
    procedure WillExecute_Capturing_Its_Mock_Is_Released_By_Free;
    /// <summary>Proves a setup with It(-1) is refused with EMockSetupException naming the mistake.</summary>
    [ Test ]
    procedure Negative_Matcher_Index_Is_A_Setup_Error;
    /// <summary>Proves a Variant string argument does not match a Variant number of the same text.</summary>
    [ Test ]
    procedure Variant_String_Does_Not_Match_Number;
    /// <summary>Proves a record with an = operator overloaded for another type is compared by its own one.
    /// </summary>
    [ Test ]
    procedure Record_Equality_Uses_The_Overload_For_The_Record;
    /// <summary>Proves AreSameFieldsThat matches a class mock's instance with a plain instance of the same class:
    /// the interception gives the mock's instance a generated class, which the class check took for another.
    /// </summary>
    [ Test ]
    procedure AreSameFieldsThat_Matches_A_Class_Mock_Instance;
    /// <summary>Proves a WillExecute function runs outside the lock every mock shares: while one thread's function
    /// waits, another thread's call on a mock completes.  Under the lock the second call waited for the first, and a
    /// function waiting on that thread deadlocked both.  Timeouts keep a red run from hanging.</summary>
    [ Test ]
    procedure WillExecute_Runs_Outside_The_Shared_Lock;
    /// <summary>Proves a call from another thread while a setup is pending is an ordinary call: it neither
    /// completes the setup nor takes its arguments, and the setup's own When call still completes it.</summary>
    [ Test ]
    procedure Call_From_Other_Thread_Does_Not_Complete_A_Pending_Setup;
  end;

implementation

uses
  System.Math,
  System.SyncObjs,
  Delphi.Mocks.Helpers,
  Delphi.Mocks.ReturnTypePatch;

{ TRvOpRec }

class operator TRvOpRec.Equal( const A: TRvOpRec; const B: Integer ): Boolean;
begin
  Result            := A.Value = B;
end;

class operator TRvOpRec.Equal( const A, B: TRvOpRec ): Boolean;
begin
  Result            := A.Value = B.Value;
end;

{ TRvPrivateFields }

constructor TRvPrivateFields.Create( const AValue: Integer );
begin
  inherited Create;
  FValue            := AValue;
end;

{ TRvOwner }

destructor TRvOwner.Destroy;
begin
  Pet.Free;
  inherited;
end;

{ ERvCustom }

constructor ERvCustom.Create( const Msg: string );
begin
  inherited Create( Msg );
  Code              := 42;
end;

{ TRvInterfaced }

procedure TRvInterfaced.Ping;
begin
end;

function TRvInterfaced.Value: Integer;
begin
  Result            := 1;
end;

{ TRvMocked }

function TRvMocked.Get: Integer;
begin
  Result            := Value;
end;

{ TRvVirtual }

function TRvVirtual.Calc( const A: Integer ): Integer;
begin
  Result            := A;
end;

/// <summary>Raises ERvArgument; used as a When argument.</summary>
/// <returns>Never returns.</returns>
function RaisingArgument: Integer;
begin
  raise ERvArgument.Create( 'argument failed' );
end;

{ TReviewTests }

procedure TReviewTests.AreSameFieldsThat_Refuses_Class_With_No_Comparable_Field;
begin
  var rMock         := TMock<IRvCalc>.Create;
  var oValue        := TRvPrivateFields.Create( 1 );
  try
    Assert.WillRaise(
      procedure
      begin
        rMock.Setup.Expect.Once.When.TakePrivate( It0.AreSameFieldsThat<TRvPrivateFields>( oValue ) );
      end, EMockSetupException );
  finally
    oValue.Free;
  end;
end;

procedure TReviewTests.AreSameFieldsThat_Compares_Public_Fields;
begin
  var rMock         := TMock<IRvCalc>.Create;
  var oExpected     := TRvOwner.Create;
  var oSame         := TRvOwner.Create;
  var oOther        := TRvOwner.Create;
  try
    rMock.Setup.Expect.Once.When.TakeOwner( It0.AreSameFieldsThat<TRvOwner>( oExpected ) );
    oOther.Pet      := TRvDog.Create;
    rMock.Instance.TakeOwner( oOther );
    Assert.WillRaise( procedure
      begin
        rMock.Verify
      end, EMockVerificationException, 'A different owner matched' );
    rMock.Instance.TakeOwner( oSame );
    Assert.WillNotRaiseAny( procedure
      begin
        rMock.Verify
      end, 'An equal owner did not match' );
  finally
    oExpected.Free;
    oSame.Free;
    oOther.Free;
  end;
end;

procedure TReviewTests.AreSameFieldsThat_Object_Fields_Of_Different_Classes_Differ;
begin
  var rMock         := TMock<IRvCalc>.Create;
  var oWithDog      := TRvOwner.Create;
  var oWithCat      := TRvOwner.Create;
  try
    oWithDog.Pet    := TRvDog.Create;
    oWithDog.Pet.Legs := 4;
    oWithCat.Pet    := TRvCat.Create;
    oWithCat.Pet.Legs := 4;
    rMock.Setup.Expect.Never.When.TakeOwner( It0.AreSameFieldsThat<TRvOwner>( oWithDog ) );
    rMock.Instance.TakeOwner( oWithCat );
    Assert.WillNotRaiseAny( procedure
      begin
        rMock.Verify
      end, 'A cat matched a dog with as many legs' );
  finally
    oWithDog.Free;
    oWithCat.Free;
  end;
end;

procedure TReviewTests.Class_Mock_Of_Interfaced_Class_Owns_Its_Instance;
begin
  var rMock         := TMock<TRvInterfaced>.Create;
  rMock.Setup.WillReturn( 3 ).When.Value;
  begin
    //The code under test takes an interface reference and releases it: the last one, as the mock holds none
    var intfPing: IRvPing := rMock.Instance;
    intfPing.Ping;
  end;
  Assert.AreEqual( 3, rMock.Instance.Value, 'The instance was freed by the release' );
  //The mock now frees the instance once: a double free raised here
end;

procedure TReviewTests.Matcher_From_Failed_When_Does_Not_Attach_To_Next_Setup;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc', 0 );
  Assert.WillRaise(
    procedure
    begin
      rMock.Setup.WillReturn( 1 ).When.Calc2( It0.IsAny<Integer>, RaisingArgument );
    end, ERvArgument );

  rMock.Setup.WillReturn( 2 ).When.Calc( 5 );
  Assert.AreEqual( 0, rMock.Instance.Calc( 7 ), 'The literal setup picked up the failed setup''s IsAny' );
  Assert.AreEqual( 2, rMock.Instance.Calc( 5 ) );
end;

procedure TReviewTests.Call_On_Other_Mock_In_When_Arguments_Keeps_Matchers;
begin
  var rOther        := TMock<IRvCalc>.Create;
  rOther.Setup.WillReturn( 4 ).When.Calc( 1 );
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc2', 0 );

  rMock.Setup.WillReturn( 9 ).When.Calc2( It0.IsAny<Integer>, It1.IsEqualTo<Integer>( rOther.Instance.Calc( 1 ) ) );

  Assert.AreEqual( 9, rMock.Instance.Calc2( 123, 4 ) );
  Assert.AreEqual( 0, rMock.Instance.Calc2( 123, 5 ) );
end;

procedure TReviewTests.WillRaise_When_Raises_For_Any_Arguments_WillRaiseWhen_Only_For_Matching;
begin
  var rAlways       := TMock<IRvCalc>.Create;
  rAlways.Setup.WillRaise( ERvArgument ).When.Calc( 3 );
  Assert.WillRaise( procedure
    begin
      rAlways.Instance.Calc( 1 )
    end, ERvArgument );

  var rWhen         := TMock<IRvCalc>.Create;
  rWhen.Setup.WillReturnDefault( 'Calc', 0 );
  rWhen.Setup.WillRaiseWhen( ERvArgument ).When.Calc( 3 );
  Assert.WillRaise( procedure
    begin
      rWhen.Instance.Calc( 3 )
    end, ERvArgument );
  Assert.AreEqual( 0, rWhen.Instance.Calc( 1 ) );
end;

procedure TReviewTests.Concurrent_Calls_Are_All_Counted;
const
  THREADS           = 4;
  CALLS             = 10000;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc', 0 );
  rMock.Setup.Expect.Exactly( 'Calc', THREADS * CALLS );
  var intfCalc      := rMock.Instance;
  var iFailures     := 0;

  var oThreads: TArray<TThread>;
  SetLength( oThreads, THREADS );
  for var iI := 0 to THREADS - 1 do
  begin
    oThreads[ iI ]  := TThread.CreateAnonymousThread(
      procedure
      begin
        try
          for var iJ := 1 to CALLS do
            intfCalc.Calc( iJ );
        except
          TInterlocked.Increment( iFailures );
        end;
      end );
    oThreads[ iI ].FreeOnTerminate := False;
  end;
  try
    for var oThread in oThreads do
      oThread.Start;
    for var oThread in oThreads do
      oThread.WaitFor;
  finally
    for var oThread in oThreads do
      oThread.Free;
  end;

  Assert.AreEqual( 0, iFailures, 'A call raised' );
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Verify
    end, 'Calls were lost' );
end;

procedure TReviewTests.AllowRedefine_Set_After_First_Setup_Applies;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturn( 1 ).When.Calc( 1 );
  rMock.Setup.AllowRedefineBehaviorDefinitions := True;
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Setup.WillReturn( 2 ).When.Calc( 1 )
    end );
  Assert.AreEqual( 2, rMock.Instance.Calc( 1 ) );
end;

procedure TReviewTests.BehaviorMustBeDefined_Set_After_First_Call_Applies;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Instance.Ping;
  rMock.Setup.BehaviorMustBeDefined := True;
  Assert.WillRaise( procedure
    begin
      rMock.Instance.Ping
    end, EMockException );
end;

procedure TReviewTests.BehaviorMustBeDefined_Enforced_With_AutoMocker;
begin
  var rContainer    := TAutoMockContainer.Create;
  var rMock         := rContainer.Mock<IRvCalc>;
  rMock.Setup.BehaviorMustBeDefined := True;
  Assert.WillRaise( procedure
    begin
      rMock.Instance.Ping
    end, EMockException );
end;

procedure TReviewTests.Overloads_Do_Not_Share_Literal_Setups;
begin
  var rMock         := TMock<IRvOverloads>.Create;
  rMock.Setup.WillReturnDefault( 'Foo', 0 );
  rMock.Setup.WillReturn( 5 ).When.Foo( 1 );
  rMock.Setup.Expect.Once.When.Foo( 1 );

  Assert.AreEqual( 0, rMock.Instance.Foo( True ), 'Foo(Boolean) answered from the Foo(Integer) setup' );
  Assert.AreEqual( 5, rMock.Instance.Foo( 1 ) );
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Verify
    end, 'Foo(True) was counted as Foo(1)' );
end;

procedure TReviewTests.Setup_By_Name_Refuses_Unknown_Method;
begin
  var rMock         := TMock<IRvCalc>.Create;
  Assert.WillRaise( procedure
    begin
      rMock.Setup.Expect.Never( 'Calk' )
    end, EMockSetupException );
  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillReturnDefault( 'Calk', 0 )
    end, EMockSetupException );
  //Any casing of a real name is accepted
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Setup.Expect.Never( 'calc' )
    end );
end;

procedure TReviewTests.IsEqualTo_Record_Compares_Contents;
var
  rExpected, rActual: TRvRec;
begin
  rExpected.Name    := 'ab';
  rExpected.Num     := 1;
  //Equal text in a different string
  rActual.Name      := Copy( 'xab', 2, 2 );
  rActual.Num       := 1;

  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.Expect.Once.When.TakeRec( It0.IsEqualTo<TRvRec>( rExpected ) );
  rMock.Instance.TakeRec( rActual );
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Verify
    end );
end;

procedure TReviewTests.Class_Mock_Runs_Matcher_Once_Per_Call_And_Not_During_Setup;
begin
  var iCount        := 0;
  var rMock         := TMock<TRvVirtual>.Create;
  rMock.Setup.WillReturn( 7 ).When.Calc( It0.Matches<Integer>(
    function( AValue: Integer ): Boolean
    begin
      Inc( iCount );
      Result        := True;
    end ) );

  iCount            := 0;
  rMock.Setup.WillReturn( 8 ).When.Calc( 5 );
  Assert.AreEqual( 0, iCount, 'The matcher ran during a setup' );

  Assert.AreEqual( 7, rMock.Instance.Calc( 1 ) );
  Assert.AreEqual( 1, iCount, 'The matcher did not run exactly once for one call' );
end;

procedure TReviewTests.Setup_By_Name_Reports_Pending_When_Setup;
begin
  var rMock         := TMock<IRvCalc>.Create;
  var intfPending   := rMock.Setup.WillReturn( 1 );
  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillReturnDefault( 'Calc', 0 )
    end, EMockSetupException );
  intfPending       := nil;
end;

procedure TReviewTests.PatchMethodReturnType_Refuses_Unknown_Method;
begin
  Assert.WillRaise(
    procedure
    begin
      PatchMethodReturnType( TypeInfo( IRvCalc ), 'NoSuchMethod', TypeInfo( Integer ) );
    end, EArgumentException );
end;

procedure TReviewTests.Abandoned_Setup_Message_Names_TObject_Methods;
begin
  var rMock         := TMock<TRvVirtual>.Create;
  var sMessage      := '';
  try
    //In a procedure of its own, so the statement's temporary references are released, and the abandonment
    //reported, before the handler; in the test method itself they would be released only at its end
    TProc(
      procedure
      begin
        rMock.Setup.WillReturn( 'x' ).When.ToString;
      end )( );
  except
    on E: EMockSetupException do
      sMessage      := E.Message;
  end;
  Assert.Contains( sMessage, 'TObject' );
end;

procedure TReviewTests.NaN_Argument_Matches_NaN;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Ratio', 0 );
  rMock.Setup.WillReturn( 3 ).When.Ratio( NaN );
  Assert.AreEqual( 3, rMock.Instance.Ratio( NaN ) );
  Assert.AreEqual( 0, rMock.Instance.Ratio( 1.5 ) );
end;

procedure TReviewTests.CompareValue_Method_Pointers_Are_Antisymmetric;
begin
  var oFirst        := TStringList.Create;
  var oSecond       := TStringList.Create;
  try
    //The same method of two instances: equal code, different data
    var pA: TNotifyEvent := nil;
    var pB: TNotifyEvent := nil;
    TMethod( pA ).Code := @TStringList.Sort;
    TMethod( pA ).Data := oFirst;
    TMethod( pB ).Code := @TStringList.Sort;
    TMethod( pB ).Data := oSecond;
    var rLeft       := TValue.From<TNotifyEvent>( pA );
    var rRight      := TValue.From<TNotifyEvent>( pB );

    var iForward    := CompareValue( rLeft, rRight );
    var iBackward   := CompareValue( rRight, rLeft );
    Assert.AreNotEqual( 0, iForward );
    Assert.AreEqual( -iForward, iBackward );
    Assert.AreEqual( 0, CompareValue( rLeft, rLeft ) );
  finally
    oFirst.Free;
    oSecond.Free;
  end;
end;

procedure TReviewTests.WillRaise_Runs_The_Exception_Class_Constructor;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillRaise( ERvCustom, 'custom' ).When.Ping;
  var iCode         := 0;
  var sMessage      := '';
  try
    rMock.Instance.Ping;
  except
    on E: ERvCustom do
    begin
      iCode         := E.Code;
      sMessage      := E.Message;
    end;
  end;
  Assert.AreEqual( 42, iCode );
  Assert.AreEqual( 'custom', sMessage );
end;

procedure TReviewTests.WillRaise_Refuses_Nil_Exception_Class;
begin
  var rMock         := TMock<IRvCalc>.Create;
  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillRaise( nil ).When.Ping
    end, EMockSetupException );
  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillRaiseWhen( nil ).When.Calc( 1 )
    end, EMockSetupException );
  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillRaise( 'Ping', nil )
    end, EMockSetupException );
end;

procedure TReviewTests.Verify_Report_Is_Clear;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.Expect.Once( 'Ping' );
  rMock.Setup.Expect.Once.When.Name( '' );
  var sMessage      := '';
  try
    rMock.Verify;
  except
    on E: EMockVerificationException do
      sMessage      := E.Message;
  end;
  Assert.IsFalse( sMessage.StartsWith( sLineBreak ), 'The report begins with a blank line' );
  Assert.Contains( sMessage, 'IRvCalc', 'The report does not name the mocked type' );
  Assert.Contains( sMessage, '( '''' )', 'The empty string argument is not quoted' );
  Assert.IsTrue( Pos( 'Name', sMessage ) < Pos( 'Ping', sMessage ), 'Methods are not listed in name order' );
end;

procedure TReviewTests.WillExecute_Capturing_Its_Mock_Is_Released_By_Free;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc2', 5 );
  rMock.Setup.WillExecute(
    function( const AArgs: TArray<TValue>; const AReturnType: TRttiType ): TValue
    begin
      //Captures rMock: the closure now holds the mock, which holds the closure
      Result        := rMock.Instance.Calc2( 1, 2 );
    end ).When.Calc( 1 );
  Assert.AreEqual( 5, rMock.Instance.Calc( 1 ) );
  //Breaks the cycle; without it the leak check reports this test
  rMock.Free;
end;

procedure TReviewTests.Negative_Matcher_Index_Is_A_Setup_Error;
begin
  var rMock         := TMock<IRvCalc>.Create;
  Assert.WillRaise(
    procedure
    begin
      rMock.Setup.WillReturn( 1 ).When.Calc( It( -1 ).IsAny<Integer> );
    end, EMockSetupException );
end;

procedure TReviewTests.Variant_String_Does_Not_Match_Number;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Vary', 0 );
  rMock.Setup.WillReturn( 1 ).When.Vary( '1' );
  Assert.AreEqual( 0, rMock.Instance.Vary( 1 ), 'The number 1 matched the text 1' );
  Assert.AreEqual( 1, rMock.Instance.Vary( '1' ) );
end;

procedure TReviewTests.Record_Equality_Uses_The_Overload_For_The_Record;
var
  rLeft, rRight     : TRvOpRec;
begin
  rLeft.Value       := 3;
  rRight.Value      := 3;
  Assert.AreEqual( 0, CompareValue( TValue.From<TRvOpRec>( rLeft ), TValue.From<TRvOpRec>( rRight ) ) );
  rRight.Value      := 4;
  Assert.AreNotEqual( 0, CompareValue( TValue.From<TRvOpRec>( rLeft ), TValue.From<TRvOpRec>( rRight ) ) );
end;

procedure TReviewTests.AreSameFieldsThat_Matches_A_Class_Mock_Instance;
begin
  var rMock         := TMock<IRvCalc>.Create;
  var rMocked       := TMock<TRvMocked>.Create;
  var oExpected     := TRvMocked.Create;
  try
    rMock.Setup.Expect.Once.When.TakeMocked( It0.AreSameFieldsThat<TRvMocked>( oExpected ) );
    rMock.Instance.TakeMocked( rMocked.Instance );
    Assert.WillNotRaiseAny( procedure
      begin
        rMock.Verify
      end, 'The mock''s instance was taken for another class' );
  finally
    oExpected.Free;
  end;
end;

procedure TReviewTests.WillExecute_Runs_Outside_The_Shared_Lock;
begin
  var oStarted      := TEvent.Create( nil, True, False, '' );
  var oGo           := TEvent.Create( nil, True, False, '' );
  var oDone         := TEvent.Create( nil, True, False, '' );
  var oWorker: TThread := nil;
  var oOther: TThread := nil;
  try
    var rWaiting    := TMock<IRvCalc>.Create;
    rWaiting.Setup.WillExecute(
      function( const AArgs: TArray<TValue>; const AReturnType: TRttiType ): TValue
      begin
        oStarted.SetEvent;
        oGo.WaitFor( 5000 );
        Result      := 1;
      end ).When.Calc( 1 );
    var rOther      := TMock<IRvCalc>.Create;
    var intfWaiting := rWaiting.Instance;
    var intfOther   := rOther.Instance;

    oWorker         := TThread.CreateAnonymousThread( procedure
      begin
        intfWaiting.Calc( 1 )
      end );
    oWorker.FreeOnTerminate := False;
    oWorker.Start;
    Assert.AreEqual( wrSignaled, oStarted.WaitFor( 5000 ), 'The WillExecute function never started' );

    oOther          := TThread.CreateAnonymousThread(
      procedure
      begin
        intfOther.Ping;
        oDone.SetEvent;
      end );
    oOther.FreeOnTerminate := False;
    oOther.Start;
    var eWait       := oDone.WaitFor( 2000 );

    //Released either way, so a red run ends rather than hangs
    oGo.SetEvent;
    oWorker.WaitFor;
    oOther.WaitFor;
    Assert.AreEqual( wrSignaled, eWait, 'A call on another mock waited for a running WillExecute function' );
  finally
    oGo.SetEvent;
    oWorker.Free;
    oOther.Free;
    oStarted.Free;
    oGo.Free;
    oDone.Free;
  end;
end;

procedure TReviewTests.Call_From_Other_Thread_Does_Not_Complete_A_Pending_Setup;
begin
  var rMock         := TMock<IRvCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc', 0 );
  var intfCalc      := rMock.Instance;
  var iOtherResult  := -1;

  //The setup is begun and held: its When call has not come yet
  var intfPending   := rMock.Setup.WillReturn( 5 );

  var oOther        := TThread.CreateAnonymousThread( procedure
    begin
      iOtherResult  := intfCalc.Calc( 1 )
    end );
  oOther.FreeOnTerminate := False;
  try
    oOther.Start;
    oOther.WaitFor;
  finally
    oOther.Free;
  end;

  intfPending.When.Calc( 2 );
  intfPending       := nil;

  Assert.AreEqual( 0, iOtherResult, 'The other thread''s call did not get the default' );
  Assert.AreEqual( 5, intfCalc.Calc( 2 ), 'The setup was completed by the other thread''s call' );
  Assert.AreEqual( 0, intfCalc.Calc( 1 ), 'The other thread''s arguments were taken as the setup''s' );
end;

initialization
  TDUnitX.RegisterTestFixture( TReviewTests );

end.

