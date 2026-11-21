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

unit Delphi.Mocks.Tests.Regression;

{ GITLAK addition (2026-10-13). One test per defect fixed in the 2026-10-13 review. Each one
  failed against the code before the fix; this unit compiles against the original public API,
  so it can be built against the old source to prove that. Tests that need an API the fix
  introduced are in Delphi.Mocks.Tests.RegressionNewApi. }

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  Delphi.Mocks;

type
  /// <summary>The exception the regression mocks are told to raise.</summary>
  ERegression = class( Exception );

{$M+}
  /// <summary>The interface most regression tests mock.</summary>
  IRegCalc = interface
    [ '{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A11}' ]
    /// <summary>A one-argument function.</summary>
    /// <param name="a">The argument.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function Calc( a: Integer ): Integer;
    /// <summary>A two-argument function.</summary>
    /// <param name="a">The first argument.</param>
    /// <param name="b">The second argument.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function Calc2( a, b: Integer ): Integer;
    /// <summary>Returns an object.</summary>
    /// <returns>Whatever the mock is set up to return.</returns>
    function GetObj: TObject;
    /// <summary>Returns another object.</summary>
    /// <returns>Whatever the mock is set up to return.</returns>
    function GetObj2: TObject;
    /// <summary>A procedure.</summary>
    procedure Ping;
    /// <summary>Another procedure.</summary>
    procedure Pong;
  end;

  /// <summary>An interface a mock implements with Implement.</summary>
  IRegA = interface
    [ '{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A12}' ]
    /// <summary>A procedure.</summary>
    procedure A;
  end;

  /// <summary>A second interface a mock implements with Implement.</summary>
  IRegB = interface
    [ '{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A13}' ]
    /// <summary>A procedure.</summary>
    procedure B;
  end;

  /// <summary>An interface whose function returns another interface, for auto mocking.</summary>
  IRegFactory = interface
    [ '{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A14}' ]
    /// <summary>Returns an IRegA.</summary>
    /// <returns>An auto mock of IRegA.</returns>
    function Make: IRegA;
  end;

  /// <summary>A class with a concrete virtual function that records being run.</summary>
  TRegClass = class
  private
    /// <summary>Set when the real Real runs.</summary>
    FRealCalled: Boolean;
  public
    /// <summary>The real implementation.</summary>
    /// <returns>Always 1.</returns>
    function Real: Integer; virtual;
    /// <summary>Whether the real Real has run.</summary>
    property RealCalled: Boolean read FRealCalled;
  end;

  /// <summary>A class whose destructor and BeforeDestruction leave observable marks.</summary>
  TRegDestroy = class
  public
    /// <summary>Set by the destructor.</summary>
    class var Destroyed: Boolean;
      /// <summary>Set by BeforeDestruction.</summary>
    class var BeforeDestructionRan: Boolean;
      /// <summary>A virtual function, so the class has something a stub can intercept.</summary>
      /// <returns>Always 1.</returns>
    function Dummy: Integer; virtual;
    /// <summary>Records that it ran.</summary>
    procedure BeforeDestruction; override;
    /// <summary>Records that it ran.</summary>
    destructor Destroy; override;
  end;
{$M-}

  /// <summary>An object implementing two interfaces, for the COM identity test.</summary>
  TRegBoth = class( TInterfacedObject, IRegA, IRegB )
  public
    /// <summary>Does nothing.</summary>
    procedure A;
    /// <summary>Does nothing.</summary>
    procedure B;
  end;

  /// <summary>An object with a method, for method-pointer comparison.</summary>
  TRegHandler = class
  public
    /// <summary>Does nothing.</summary>
    /// <param name="Sender">Unused.</param>
    procedure Handle( Sender: TObject );
  end;

  /// <summary>A record without an = operator.</summary>
  TRegRec = record
    /// <summary>A number.</summary>
    X: Integer;
    /// <summary>A string.</summary>
    S: string;
  end;

  /// <summary>An enumeration for the set type.</summary>
  TRegEnum = ( reA, reB, reC );
  /// <summary>A set type.</summary>
  TRegSet = set of TRegEnum;

{$M+}
  /// <summary>Regression tests for the defects fixed in the 2026-10-13 review.</summary>
  [ TestFixture ]
  TRegressionTests = class
  published
    /// <summary>Proves a WillRaiseWhen raises only for its own arguments, and with the caller's message. It used to
    /// raise 'Raised by Mock' for every call, even where a WillReturn applied.</summary>
    procedure WillRaiseWhen_Fires_Only_For_Matching_Args_With_User_Message;
    /// <summary>Proves a specific WillReturn defined after a general IsAny one is allowed and wins for its
    /// argument. Setup used to match the IsAny matcher against the new setup's placeholder and refuse it as
    /// "already defines".</summary>
    procedure Specific_WillReturn_After_IsAny_Is_Defined_And_Wins;
    /// <summary>Proves an IsAny WillReturn defined after a specific one is allowed, and, being newest, wins.
    /// </summary>
    procedure IsAny_WillReturn_After_Specific_Is_Defined_And_Wins;
    /// <summary>Proves IsInRange accepts values inside the range, bounds included, and rejects those outside. It
    /// used to register no matcher at all.</summary>
    procedure IsInRange_Matches_Inside_And_Rejects_Outside;
    /// <summary>Proves records without an = operator compare by their fields. They used to compare equal whatever
    /// they held.</summary>
    procedure Records_Without_Equality_Operator_Compare_By_Fields;
    /// <summary>Proves sets, pointers, method pointers, class references and OleVariants compare by value. Each
    /// used to fall through to "equal".</summary>
    procedure Sets_Pointers_Methods_ClassRefs_OleVariants_Compare_By_Value;
    /// <summary>Proves a method pointer compares equal to itself. The RTL counts method pointers as managed, so
    /// leaving them to the byte comparison (which refuses managed types) made identical events unequal; they
    /// are now compared by code and instance.</summary>
    [ Test ]
    procedure Identical_Method_Pointers_Compare_Equal;
    /// <summary>Proves comparing Variants that cannot be compared answers "unequal" instead of raising out of
    /// argument matching.</summary>
    procedure Incomparable_Variants_Do_Not_Raise;
    /// <summary>Proves floats compare exactly. A Win64 tolerance used to make 1.0 equal its next-but-one Double.
    /// </summary>
    procedure Floats_Compare_Exactly;
    /// <summary>Proves strings compare ordinally. The locale-aware compare ignored a soft hyphen.</summary>
    procedure Strings_Compare_Ordinally;
    /// <summary>Proves two interfaces of one object compare equal by COM identity, and different objects do not.
    /// They used to be compared as raw pointers.</summary>
    procedure Interfaces_Compare_By_COM_Identity;
    /// <summary>Proves a behaviour setup with a matcher gap (It1 without It0) raises EMockSetupException at setup.
    /// It used to pass setup and raise an access violation on the first call.</summary>
    procedure Matcher_Gap_In_Behaviour_Setup_Raises_EMockSetupException;
    /// <summary>Proves the same for an expectation setup, which used to check nothing and ignore the literal.
    /// </summary>
    procedure Matcher_Gap_In_Expectation_Setup_Raises_EMockSetupException;
    /// <summary>Proves using It0 twice raises EMockSetupException, and that the next setup is clean. The second
    /// matcher used to be inserted, shifting the others along.</summary>
    procedure Duplicate_Matcher_Index_Raises_And_Next_Setup_Is_Clean;
    /// <summary>Proves an It expression evaluated in an ordinary call does not attach itself to the next setup.
    /// </summary>
    procedure Matcher_From_Ordinary_Call_Does_Not_Leak_Into_Next_Setup;
    /// <summary>Proves Expect.OnceWhen and Expect.Once on the same method coexist and are both verified. Once used
    /// to collide with OnceWhen as "already defines".</summary>
    procedure OnceWhen_And_Once_Coexist;
    /// <summary>Proves Between with its maximum below its minimum raises EMockSetupException instead of making an
    /// expectation that can never be met.</summary>
    procedure Between_With_Max_Below_Min_Raises;
    /// <summary>Proves WillReturnDefault on a concrete virtual method of a class mock is returned and the real
    /// method does not run. The real method used to run and the default was ignored.</summary>
    procedure WillReturnDefault_On_Concrete_Virtual_Method_Of_Class_Mock_Is_Returned;
    /// <summary>Proves a nil object is an acceptable default. TValue.IsEmpty is True for nil, so it used to raise
    /// "no default return value".</summary>
    procedure WillReturnDefault_With_Nil_Object_Is_Returned;
    /// <summary>Proves ResetCalls reaches an interface added with Implement, so VerifyAll fails again after it.
    /// </summary>
    procedure ResetCalls_Resets_Implemented_Interface;
    /// <summary>Proves Expect.Clear reaches an interface added with Implement.</summary>
    procedure Clear_Clears_Implemented_Interface;
    /// <summary>Proves a mocked instance kept after its mock is freed raises EMockException when called, and
    /// answers a query for another interface without an access violation. Both used to run in freed memory.
    /// </summary>
    procedure Instance_Used_After_Mock_Freed_Raises_EMockException;
    /// <summary>Proves TMock.Free twice is harmless and any other use after Free raises EMockException.</summary>
    procedure TMock_Free_Twice_Is_Harmless_And_Use_After_Free_Raises;
    /// <summary>Proves an uncreated or freed TStub raises EMockException rather than an access violation.
    /// </summary>
    procedure TStub_Uncreated_Or_Freed_Raises_EMockException;
    /// <summary>Proves WillReturnNil does not leave nil allowed for the next WillReturn: a nil value without
    /// AllowNil is refused as before.</summary>
    procedure WillReturnNil_Does_Not_Leak_Into_Next_WillReturn;
    /// <summary>Proves unmet-expectation reports give the actual count, and show matchers as matchers rather than
    /// as the placeholder values passed to When.</summary>
    procedure Expectation_Reports_Give_Count_And_Matchers;
    /// <summary>Proves a stub of a class runs its overridden BeforeDestruction and destructor when freed. An
    /// overridden BeforeDestruction used to be intercepted like any virtual method and skipped.</summary>
    procedure Stub_Of_Class_Runs_Overridden_Destructor;
    /// <summary>Proves Expect.Before(...).When is met in order and fails VerifyAll out of order.</summary>
    procedure Before_When_Met_In_Order_And_Not_Out_Of_Order;
    /// <summary>Proves Expect.After(...).When is met in order and fails VerifyAll out of order.</summary>
    procedure After_When_Met_In_Order_And_Not_Out_Of_Order;
    /// <summary>Proves the non-When Before overload is met in order and fails out of order, or when the other
    /// method is never called.</summary>
    procedure Before_By_Name_Met_In_Order_And_Not_Out_Of_Order;
    /// <summary>Proves an auto-mocked interface return value is a usable instance of that interface, the same one
    /// on every call. It used to be the IProxy, returned in the interface's place.</summary>
    procedure AutoMock_Interface_Return_Value_Is_Usable_And_Stable;
    /// <summary>Proves a TAutoMockContainer used before Create raises EMockException rather than an access
    /// violation.</summary>
    procedure AutoMockContainer_Used_Before_Create_Raises_EMockException;
    /// <summary>Proves MethodKindToStr with an unknown kind raises Exception naming the number. A %s for an Integer
    /// made it raise EConvertError instead.</summary>
    procedure MethodKindToStr_Unknown_Kind_Raises_Exception_With_Number;
    /// <summary>Proves PatchMethodReturnType refuses a class method with EArgumentException instead of treating it
    /// as an interface method's RTTI.</summary>
    procedure PatchMethodReturnType_On_Class_Method_Raises_EArgumentException;
  end;
{$M-}

implementation

uses
  System.Rtti,
  System.TypInfo,
  System.Variants,
  Delphi.Mocks.Helpers,
  Delphi.Mocks.Proxy,
  Delphi.Mocks.ReturnTypePatch;

{ TRegClass }

function TRegClass.Real: Integer;
begin
  FRealCalled       := True;
  Result            := 1;
end;

{ TRegDestroy }

procedure TRegDestroy.BeforeDestruction;
begin
  BeforeDestructionRan := True;
  inherited;
end;

destructor TRegDestroy.Destroy;
begin
  Destroyed         := True;
  inherited;
end;

function TRegDestroy.Dummy: Integer;
begin
  Result            := 1;
end;

{ TRegBoth }

procedure TRegBoth.A;
begin
end;

procedure TRegBoth.B;
begin
end;

{ TRegHandler }

procedure TRegHandler.Handle( Sender: TObject );
begin
end;

{ TRegressionTests }

procedure TRegressionTests.WillRaiseWhen_Fires_Only_For_Matching_Args_With_User_Message;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillRaiseWhen( ERegression, 'boom' ).When.Calc( 1 );
  rMock.Setup.WillReturn( 5 ).When.Calc( 2 );

  Assert.AreEqual( 5, rMock.Instance.Calc( 2 ), 'A WillRaiseWhen for 1 must not fire for 2' );
  Assert.WillRaiseWithMessage( procedure
    begin
      rMock.Instance.Calc( 1 )
    end, ERegression, 'boom' );
end;

procedure TRegressionTests.Specific_WillReturn_After_IsAny_Is_Defined_And_Wins;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillReturn( 0 ).When.Calc( It0.IsAny<Integer> );
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Setup.WillReturn( 1 ).When.Calc( 3 )
    end );

  Assert.AreEqual( 1, rMock.Instance.Calc( 3 ) );
  Assert.AreEqual( 0, rMock.Instance.Calc( 4 ) );
end;

procedure TRegressionTests.IsAny_WillReturn_After_Specific_Is_Defined_And_Wins;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillReturn( 1 ).When.Calc( 3 );
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Setup.WillReturn( 0 ).When.Calc( It0.IsAny<Integer> )
    end );

  Assert.AreEqual( 0, rMock.Instance.Calc( 4 ) );
  Assert.AreEqual( 0, rMock.Instance.Calc( 3 ), 'The most recent definition wins where they overlap' );
end;

procedure TRegressionTests.IsInRange_Matches_Inside_And_Rejects_Outside;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc', -1 );
  rMock.Setup.WillReturn( 1 ).When.Calc( It0.IsInRange<Integer>( 5, 10 ) );

  Assert.AreEqual( 1, rMock.Instance.Calc( 5 ) );
  Assert.AreEqual( 1, rMock.Instance.Calc( 7 ) );
  Assert.AreEqual( 1, rMock.Instance.Calc( 10 ) );
  Assert.AreEqual( -1, rMock.Instance.Calc( 4 ) );
  Assert.AreEqual( -1, rMock.Instance.Calc( 11 ) );
  Assert.AreEqual( -1, rMock.Instance.Calc( 0 ) );
end;

procedure TRegressionTests.Records_Without_Equality_Operator_Compare_By_Fields;
var
  rR1, rR2          : TRegRec;
begin
  rR1.X             := 1;
  rR1.S             := 'a';
  rR2.X             := 1;
  rR2.S             := 'b';
  Assert.AreNotEqual( 0, CompareValue( TValue.From<TRegRec>( rR1 ), TValue.From<TRegRec>( rR2 ) ) );

  rR2.S             := 'A';
  rR2.S             := LowerCase( rR2.S );
  Assert.AreEqual( 0, CompareValue( TValue.From<TRegRec>( rR1 ), TValue.From<TRegRec>( rR2 ) ) );

  rR2.X             := 2;
  Assert.AreNotEqual( 0, CompareValue( TValue.From<TRegRec>( rR1 ), TValue.From<TRegRec>( rR2 ) ) );
end;

procedure TRegressionTests.Sets_Pointers_Methods_ClassRefs_OleVariants_Compare_By_Value;
var
  iX, iY            : Integer;
  oH1, oH2          : TRegHandler;
  pE1, pE2          : TNotifyEvent;
begin
  Assert.AreNotEqual( 0, CompareValue( TValue.From<TRegSet>( [ reA ] ), TValue.From<TRegSet>( [ reB ] ) ), 'sets' );
  Assert.AreEqual( 0, CompareValue( TValue.From<TRegSet>( [ reA, reC ] ), TValue.From<TRegSet>( [ reA, reC ] ) ), 'equal sets' );

  iX                := 0;
  iY                := 0;
  Assert.AreNotEqual( 0, CompareValue( TValue.From<Pointer>( @iX ), TValue.From<Pointer>( @iY ) ), 'pointers' );
  Assert.AreEqual( 0, CompareValue( TValue.From<Pointer>( @iX ), TValue.From<Pointer>( @iX ) ), 'equal pointers' );

  oH1               := TRegHandler.Create;
  oH2               := TRegHandler.Create;
  try
    pE1             := oH1.Handle;
    pE2             := oH2.Handle;
    Assert.AreNotEqual( 0, CompareValue( TValue.From<TNotifyEvent>( pE1 ), TValue.From<TNotifyEvent>( pE2 ) ), 'method pointers' );
  finally
    oH1.Free;
    oH2.Free;
  end;

  Assert.AreNotEqual( 0, CompareValue( TValue.From<TClass>( TObject ), TValue.From<TClass>( TList ) ), 'class references' );
  Assert.AreEqual( 0, CompareValue( TValue.From<TClass>( TList ), TValue.From<TClass>( TList ) ), 'equal class references' );

  Assert.AreNotEqual( 0, CompareValue( TValue.From<OleVariant>( OleVariant( 1 ) ), TValue.From<OleVariant>( OleVariant( 2 ) ) ), 'OleVariants' );
  Assert.AreEqual( 0, CompareValue( TValue.From<OleVariant>( OleVariant( 1 ) ), TValue.From<OleVariant>( OleVariant( 1 ) ) ), 'equal OleVariants' );
end;

procedure TRegressionTests.Identical_Method_Pointers_Compare_Equal;
var
  pE1, pE2          : TNotifyEvent;
begin
  var oH: TRegHandler := TRegHandler.Create;
  try
    pE1             := oH.Handle;
    pE2             := oH.Handle;
    Assert.AreEqual( 0, CompareValue( TValue.From<TNotifyEvent>( pE1 ), TValue.From<TNotifyEvent>( pE2 ) ) );
  finally
    oH.Free;
  end;
end;

procedure TRegressionTests.Incomparable_Variants_Do_Not_Raise;
begin
  var iResult: Integer := 0;
  Assert.WillNotRaiseAny( procedure
    begin
      iResult       := CompareValue( TValue.From<Variant>( Variant( 'abc' ) ), TValue.From<Variant>( Variant( 1 ) ) );
    end );
  Assert.AreNotEqual( 0, iResult );
end;

procedure TRegressionTests.Floats_Compare_Exactly;
var
  fD1, fD2          : Double;
begin
  fD1               := 1.0;
  fD2               := fD1 + 5E-16;
  Assert.IsTrue( fD1 <> fD2, 'Premise: the two Doubles differ' );
  Assert.AreNotEqual( 0, CompareValue( TValue.From<Double>( fD1 ), TValue.From<Double>( fD2 ) ) );
  Assert.AreEqual( 0, CompareValue( TValue.From<Double>( fD1 ), TValue.From<Double>( 1.0 ) ) );
end;

procedure TRegressionTests.Strings_Compare_Ordinally;
var
  sS1, sS2          : string;
begin
  sS1               := 'ab';
  sS2               := 'a' + #$00AD + 'b';
  Assert.AreNotEqual( 0, CompareValue( TValue.From<string>( sS1 ), TValue.From<string>( sS2 ) ) );
  Assert.AreNotEqual( 0, CompareValue( TValue.From<string>( 'abc' ), TValue.From<string>( 'ABC' ) ), 'Case matters' );
end;

procedure TRegressionTests.Interfaces_Compare_By_COM_Identity;
begin
  var intfA: IRegA  := TRegBoth.Create;
  var intfB: IRegB  := intfA as IRegB;
  var intfOther: IRegA := TRegBoth.Create;

  Assert.AreEqual( 0, CompareValue( TValue.From<IRegA>( intfA ), TValue.From<IRegB>( intfB ) ), 'Two interfaces of one object' );
  Assert.AreNotEqual( 0, CompareValue( TValue.From<IRegA>( intfA ), TValue.From<IRegA>( intfOther ) ), 'Two objects' );
end;

procedure TRegressionTests.Matcher_Gap_In_Behaviour_Setup_Raises_EMockSetupException;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillReturn( 1 ).When.Calc2( 5, It1.IsAny<Integer> );
    end, EMockSetupException );
end;

procedure TRegressionTests.Matcher_Gap_In_Expectation_Setup_Raises_EMockSetupException;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  Assert.WillRaise( procedure
    begin
      rMock.Setup.Expect.Once.When.Calc2( 5, It1.IsAny<Integer> );
    end, EMockSetupException );
end;

procedure TRegressionTests.Duplicate_Matcher_Index_Raises_And_Next_Setup_Is_Clean;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillReturn( 1 ).When.Calc2( It0.IsAny<Integer>, It0.IsAny<Integer> );
    end, EMockSetupException );

  rMock.Setup.WillReturn( 2 ).When.Calc( It0.IsAny<Integer> );
  Assert.AreEqual( 2, rMock.Instance.Calc( 9 ) );
end;

procedure TRegressionTests.Matcher_From_Ordinary_Call_Does_Not_Leak_Into_Next_Setup;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc', 0 );
  rMock.Setup.WillReturnDefault( 'Calc2', -1 );

  //An It expression outside a When: a mistake, which must not affect what follows.
  rMock.Instance.Calc( It0.IsAny<Integer> );

  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Setup.WillReturn( 7 ).When.Calc2( 3, 4 )
    end );
  Assert.AreEqual( 7, rMock.Instance.Calc2( 3, 4 ) );
  Assert.AreEqual( -1, rMock.Instance.Calc2( 1, 1 ), 'The literal setup must not have picked up an IsAny' );
end;

procedure TRegressionTests.OnceWhen_And_Once_Coexist;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillReturnDefault( 'Calc', 0 );
  rMock.Setup.Expect.Once.When.Calc( 1 );
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Setup.Expect.Once( 'Calc' )
    end );

  rMock.Instance.Calc( 1 );
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Verify
    end );
  rMock.Instance.Calc( 2 );
  Assert.WillRaise( procedure
    begin
      rMock.Verify
    end, EMockVerificationException );
end;

procedure TRegressionTests.Between_With_Max_Below_Min_Raises;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  Assert.WillRaise( procedure
    begin
      rMock.Setup.Expect.Between( 'Calc', 5, 2 )
    end, EMockSetupException );
end;

procedure TRegressionTests.WillReturnDefault_On_Concrete_Virtual_Method_Of_Class_Mock_Is_Returned;
begin
  var rMock: TMock<TRegClass> := TMock<TRegClass>.Create;
  rMock.Setup.WillReturnDefault( 'Real', 42 );

  Assert.AreEqual( 42, rMock.Instance.Real );
  Assert.IsFalse( rMock.Instance.RealCalled, 'The real method must not run' );
end;

procedure TRegressionTests.WillReturnDefault_With_Nil_Object_Is_Returned;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillReturnDefault( 'GetObj', TValue.From<TObject>( nil ) );

  var oObj: TObject := TObject( 1 );
  Assert.WillNotRaiseAny( procedure
    begin
      oObj          := rMock.Instance.GetObj
    end );
  Assert.IsNull( oObj );
end;

procedure TRegressionTests.ResetCalls_Resets_Implemented_Interface;
begin
  var rMock: TMock<IRegA> := TMock<IRegA>.Create;
  rMock.Implement<IRegB>;
  rMock.Setup<IRegB>.Expect.Once.When.B;
  rMock.Instance<IRegB>.B;
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.VerifyAll
    end );

  rMock.ResetCalls;
  Assert.WillRaise( procedure
    begin
      rMock.VerifyAll
    end, EMockVerificationException );
end;

procedure TRegressionTests.Clear_Clears_Implemented_Interface;
begin
  var rMock: TMock<IRegA> := TMock<IRegA>.Create;
  rMock.Implement<IRegB>;
  rMock.Setup<IRegB>.Expect.Once.When.B;
  Assert.WillRaise( procedure
    begin
      rMock.VerifyAll
    end, EMockVerificationException );

  rMock.Setup.Expect.Clear;
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.VerifyAll
    end );
end;

procedure TRegressionTests.Instance_Used_After_Mock_Freed_Raises_EMockException;
var
  intfQueried       : IRegB;
begin
  var rMock: TMock<IRegA> := TMock<IRegA>.Create;
  var intfKept: IRegA := rMock.Instance;
  rMock.Free;

  Assert.WillRaise( procedure
    begin
      intfKept.A
    end, EMockException );

  var bSupported: Boolean := True;
  Assert.WillNotRaiseAny( procedure
    begin
      bSupported    := Supports( intfKept, IRegB, intfQueried )
    end );
  Assert.IsFalse( bSupported );
end;

procedure TRegressionTests.TMock_Free_Twice_Is_Harmless_And_Use_After_Free_Raises;
begin
  var rMock: TMock<IRegA> := TMock<IRegA>.Create;
  rMock.Free;
  Assert.WillNotRaiseAny( procedure
    begin
      rMock.Free
    end );
  Assert.WillRaise( procedure
    begin
      rMock.Instance
    end, EMockException );
  Assert.WillRaise( procedure
    begin
      rMock.Setup
    end, EMockException );
end;

procedure TRegressionTests.TStub_Uncreated_Or_Freed_Raises_EMockException;
var
  rUncreated        : TStub<IRegA>;
begin
  Assert.WillRaise( procedure
    begin
      rUncreated.Setup
    end, EMockException );

  var rFreed: TStub<IRegA> := TStub<IRegA>.Create;
  rFreed.Free;
  Assert.WillRaise( procedure
    begin
      rFreed.Instance
    end, EMockException );
end;

procedure TRegressionTests.WillReturnNil_Does_Not_Leak_Into_Next_WillReturn;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.WillReturnNil.When.GetObj;
  Assert.IsNull( rMock.Instance.GetObj );

  Assert.WillRaise( procedure
    begin
      rMock.Setup.WillReturn( TValue.From<TObject>( nil ) ).When.GetObj2;
    end, EMockSetupException );
end;

procedure TRegressionTests.Expectation_Reports_Give_Count_And_Matchers;
begin
  var rMock: TMock<IRegCalc> := TMock<IRegCalc>.Create;
  rMock.Setup.Expect.AtLeastOnce( 'Ping' );
  rMock.Setup.Expect.Once.When.Calc( It0.IsAny<Integer> );

  var sReport: string := rMock.CheckExpectations;
  Assert.Contains( sReport, 'At Least Once - Was 0', False );
  Assert.Contains( sReport, '<matcher>', False );
end;

procedure TRegressionTests.Stub_Of_Class_Runs_Overridden_Destructor;
begin
  TRegDestroy.Destroyed := False;
  TRegDestroy.BeforeDestructionRan := False;
  var rStub: TStub<TRegDestroy> := TStub<TRegDestroy>.Create;
  Assert.AreEqual( 0, rStub.Instance.Dummy, 'Premise: the stub intercepts its virtual methods' );
  rStub.Free;
  Assert.IsTrue( TRegDestroy.BeforeDestructionRan, 'The overridden BeforeDestruction must run' );
  Assert.IsTrue( TRegDestroy.Destroyed, 'The overridden destructor must run' );
end;

procedure TRegressionTests.Before_When_Met_In_Order_And_Not_Out_Of_Order;
var
  rInOrder, rOutOfOrder: TMock<IRegCalc>;
begin
  rInOrder          := TMock<IRegCalc>.Create;
  rInOrder.Setup.Expect.Before( 'Pong' ).When.Ping;
  rInOrder.Instance.Ping;
  rInOrder.Instance.Pong;
  Assert.WillNotRaiseAny( procedure
    begin
      rInOrder.Verify
    end );

  rOutOfOrder       := TMock<IRegCalc>.Create;
  rOutOfOrder.Setup.Expect.Before( 'Pong' ).When.Ping;
  rOutOfOrder.Instance.Pong;
  rOutOfOrder.Instance.Ping;
  Assert.WillRaise( procedure
    begin
      rOutOfOrder.Verify
    end, EMockVerificationException );
end;

procedure TRegressionTests.After_When_Met_In_Order_And_Not_Out_Of_Order;
var
  rInOrder, rOutOfOrder: TMock<IRegCalc>;
begin
  rInOrder          := TMock<IRegCalc>.Create;
  rInOrder.Setup.Expect.After( 'Ping' ).When.Pong;
  rInOrder.Instance.Ping;
  rInOrder.Instance.Pong;
  Assert.WillNotRaiseAny( procedure
    begin
      rInOrder.Verify
    end );

  rOutOfOrder       := TMock<IRegCalc>.Create;
  rOutOfOrder.Setup.Expect.After( 'Ping' ).When.Pong;
  rOutOfOrder.Instance.Pong;
  rOutOfOrder.Instance.Ping;
  Assert.WillRaise( procedure
    begin
      rOutOfOrder.Verify
    end, EMockVerificationException );
end;

procedure TRegressionTests.Before_By_Name_Met_In_Order_And_Not_Out_Of_Order;
var
  rInOrder, rOutOfOrder, rNeverOther: TMock<IRegCalc>;
begin
  rInOrder          := TMock<IRegCalc>.Create;
  rInOrder.Setup.Expect.Before( 'Ping', 'Pong' );
  rInOrder.Instance.Ping;
  rInOrder.Instance.Pong;
  Assert.WillNotRaiseAny( procedure
    begin
      rInOrder.Verify
    end );

  rOutOfOrder       := TMock<IRegCalc>.Create;
  rOutOfOrder.Setup.Expect.Before( 'Ping', 'Pong' );
  rOutOfOrder.Instance.Pong;
  rOutOfOrder.Instance.Ping;
  Assert.WillRaise( procedure
    begin
      rOutOfOrder.Verify
    end, EMockVerificationException );

  rNeverOther       := TMock<IRegCalc>.Create;
  rNeverOther.Setup.Expect.Before( 'Ping', 'Pong' );
  rNeverOther.Instance.Ping;
  Assert.WillRaise( procedure
    begin
      rNeverOther.Verify
    end, EMockVerificationException );
end;

procedure TRegressionTests.AutoMock_Interface_Return_Value_Is_Usable_And_Stable;
var
  intfFirst, intfSecond: IRegA;
begin
  var rContainer: TAutoMockContainer := TAutoMockContainer.Create;
  var rFactory: TMock<IRegFactory> := rContainer.Mock<IRegFactory>;

  intfFirst         := rFactory.Instance.Make;
  Assert.IsNotNull( intfFirst );
  Assert.WillNotRaiseAny( procedure
    begin
      intfFirst.A
    end );
  intfSecond        := rFactory.Instance.Make;
  Assert.IsTrue( intfFirst = intfSecond, 'The same auto mock must be returned on every call' );
end;

procedure TRegressionTests.AutoMockContainer_Used_Before_Create_Raises_EMockException;
var
  rContainer        : TAutoMockContainer;
begin
  Assert.WillRaise( procedure
    begin
      rContainer.Mock<IRegA>
    end, EMockException );
end;

procedure TRegressionTests.MethodKindToStr_Unknown_Kind_Raises_Exception_With_Number;
begin
  var sMsg: string  := '';
  try
    MethodKindToStr( TMethodKind( 200 ) );
  except
    on E: Exception do
    begin
      Assert.IsTrue( E.ClassType = Exception, 'Expected Exception, got ' + E.ClassName );
      sMsg          := E.Message;
    end;
  end;
  Assert.Contains( sMsg, '200', False );
end;

procedure TRegressionTests.PatchMethodReturnType_On_Class_Method_Raises_EArgumentException;
begin
  var rContext: TRttiContext := TRttiContext.Create;
  var oMethod: TRttiMethod := rContext.GetType( TRegClass ).GetMethod( 'Real' );
  Assert.IsNotNull( oMethod, 'Premise: the method has RTTI' );
  Assert.WillRaise( procedure
    begin
      PatchMethodReturnType( oMethod, TypeInfo( Integer ) )
    end, EArgumentException );
end;

initialization
  TDUnitX.RegisterTestFixture( TRegressionTests );

end.

