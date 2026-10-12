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
  ERegression = class(Exception);

  {$M+}
  /// <summary>The interface most regression tests mock.</summary>
  IRegCalc = interface
    ['{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A11}']
    /// <summary>A one-argument function.</summary>
    /// <param name="a">The argument.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function Calc(a : Integer) : Integer;
    /// <summary>A two-argument function.</summary>
    /// <param name="a">The first argument.</param>
    /// <param name="b">The second argument.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function Calc2(a, b : Integer) : Integer;
    /// <summary>Returns an object.</summary>
    /// <returns>Whatever the mock is set up to return.</returns>
    function GetObj : TObject;
    /// <summary>Returns another object.</summary>
    /// <returns>Whatever the mock is set up to return.</returns>
    function GetObj2 : TObject;
    /// <summary>A procedure.</summary>
    procedure Ping;
    /// <summary>Another procedure.</summary>
    procedure Pong;
  end;

  /// <summary>An interface a mock implements with Implement.</summary>
  IRegA = interface
    ['{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A12}']
    /// <summary>A procedure.</summary>
    procedure A;
  end;

  /// <summary>A second interface a mock implements with Implement.</summary>
  IRegB = interface
    ['{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A13}']
    /// <summary>A procedure.</summary>
    procedure B;
  end;

  /// <summary>An interface whose function returns another interface, for auto mocking.</summary>
  IRegFactory = interface
    ['{3E1F7A20-5C4B-4D8A-9E2F-6B7C8D9E0A14}']
    /// <summary>Returns an IRegA.</summary>
    /// <returns>An auto mock of IRegA.</returns>
    function Make : IRegA;
  end;

  /// <summary>A class with a concrete virtual function that records being run.</summary>
  TRegClass = class
  private
    /// <summary>Set when the real Real runs.</summary>
    FRealCalled : Boolean;
  public
    /// <summary>The real implementation.</summary>
    /// <returns>Always 1.</returns>
    function Real : Integer; virtual;
    /// <summary>Whether the real Real has run.</summary>
    property RealCalled : Boolean read FRealCalled;
  end;

  /// <summary>A class whose destructor and BeforeDestruction leave observable marks.</summary>
  TRegDestroy = class
  public
    /// <summary>Set by the destructor.</summary>
    class var Destroyed : Boolean;
    /// <summary>Set by BeforeDestruction.</summary>
    class var BeforeDestructionRan : Boolean;
    /// <summary>A virtual function, so the class has something a stub can intercept.</summary>
    /// <returns>Always 1.</returns>
    function Dummy : Integer; virtual;
    /// <summary>Records that it ran.</summary>
    procedure BeforeDestruction; override;
    /// <summary>Records that it ran.</summary>
    destructor Destroy; override;
  end;
  {$M-}

  /// <summary>An object implementing two interfaces, for the COM identity test.</summary>
  TRegBoth = class(TInterfacedObject, IRegA, IRegB)
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
    procedure Handle(Sender : TObject);
  end;

  /// <summary>A record without an = operator.</summary>
  TRegRec = record
    /// <summary>A number.</summary>
    X : Integer;
    /// <summary>A string.</summary>
    S : string;
  end;

  /// <summary>An enumeration for the set type.</summary>
  TRegEnum = (reA, reB, reC);
  /// <summary>A set type.</summary>
  TRegSet = set of TRegEnum;

  {$M+}
  /// <summary>Regression tests for the defects fixed in the 2026-10-13 review.</summary>
  [TestFixture]
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
    [Test]
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
  FRealCalled := True;
  Result := 1;
end;

{ TRegDestroy }

procedure TRegDestroy.BeforeDestruction;
begin
  BeforeDestructionRan := True;
  inherited;
end;

destructor TRegDestroy.Destroy;
begin
  Destroyed := True;
  inherited;
end;

function TRegDestroy.Dummy: Integer;
begin
  Result := 1;
end;

{ TRegBoth }

procedure TRegBoth.A;
begin
end;

procedure TRegBoth.B;
begin
end;

{ TRegHandler }

procedure TRegHandler.Handle(Sender: TObject);
begin
end;

{ TRegressionTests }

procedure TRegressionTests.WillRaiseWhen_Fires_Only_For_Matching_Args_With_User_Message;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillRaiseWhen(ERegression, 'boom').When.Calc(1);
  mock.Setup.WillReturn(5).When.Calc(2);

  Assert.AreEqual(5, mock.Instance.Calc(2), 'A WillRaiseWhen for 1 must not fire for 2');
  Assert.WillRaiseWithMessage(procedure begin mock.Instance.Calc(1) end, ERegression, 'boom');
end;

procedure TRegressionTests.Specific_WillReturn_After_IsAny_Is_Defined_And_Wins;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillReturn(0).When.Calc(It0.IsAny<Integer>);
  Assert.WillNotRaiseAny(procedure begin mock.Setup.WillReturn(1).When.Calc(3) end);

  Assert.AreEqual(1, mock.Instance.Calc(3));
  Assert.AreEqual(0, mock.Instance.Calc(4));
end;

procedure TRegressionTests.IsAny_WillReturn_After_Specific_Is_Defined_And_Wins;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillReturn(1).When.Calc(3);
  Assert.WillNotRaiseAny(procedure begin mock.Setup.WillReturn(0).When.Calc(It0.IsAny<Integer>) end);

  Assert.AreEqual(0, mock.Instance.Calc(4));
  Assert.AreEqual(0, mock.Instance.Calc(3), 'The most recent definition wins where they overlap');
end;

procedure TRegressionTests.IsInRange_Matches_Inside_And_Rejects_Outside;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillReturnDefault('Calc', -1);
  mock.Setup.WillReturn(1).When.Calc(It0.IsInRange<Integer>(5, 10));

  Assert.AreEqual(1, mock.Instance.Calc(5));
  Assert.AreEqual(1, mock.Instance.Calc(7));
  Assert.AreEqual(1, mock.Instance.Calc(10));
  Assert.AreEqual(-1, mock.Instance.Calc(4));
  Assert.AreEqual(-1, mock.Instance.Calc(11));
  Assert.AreEqual(-1, mock.Instance.Calc(0));
end;

procedure TRegressionTests.Records_Without_Equality_Operator_Compare_By_Fields;
var
  r1, r2 : TRegRec;
begin
  r1.X := 1;
  r1.S := 'a';
  r2.X := 1;
  r2.S := 'b';
  Assert.AreNotEqual(0, CompareValue(TValue.From<TRegRec>(r1), TValue.From<TRegRec>(r2)));

  r2.S := 'A';
  r2.S := LowerCase(r2.S);
  Assert.AreEqual(0, CompareValue(TValue.From<TRegRec>(r1), TValue.From<TRegRec>(r2)));

  r2.X := 2;
  Assert.AreNotEqual(0, CompareValue(TValue.From<TRegRec>(r1), TValue.From<TRegRec>(r2)));
end;

procedure TRegressionTests.Sets_Pointers_Methods_ClassRefs_OleVariants_Compare_By_Value;
var
  x, y : Integer;
  h1, h2 : TRegHandler;
  e1, e2 : TNotifyEvent;
begin
  Assert.AreNotEqual(0, CompareValue(TValue.From<TRegSet>([reA]), TValue.From<TRegSet>([reB])), 'sets');
  Assert.AreEqual(0, CompareValue(TValue.From<TRegSet>([reA, reC]), TValue.From<TRegSet>([reA, reC])), 'equal sets');

  x := 0;
  y := 0;
  Assert.AreNotEqual(0, CompareValue(TValue.From<Pointer>(@x), TValue.From<Pointer>(@y)), 'pointers');
  Assert.AreEqual(0, CompareValue(TValue.From<Pointer>(@x), TValue.From<Pointer>(@x)), 'equal pointers');

  h1 := TRegHandler.Create;
  h2 := TRegHandler.Create;
  try
    e1 := h1.Handle;
    e2 := h2.Handle;
    Assert.AreNotEqual(0, CompareValue(TValue.From<TNotifyEvent>(e1), TValue.From<TNotifyEvent>(e2)), 'method pointers');
  finally
    h1.Free;
    h2.Free;
  end;

  Assert.AreNotEqual(0, CompareValue(TValue.From<TClass>(TObject), TValue.From<TClass>(TList)), 'class references');
  Assert.AreEqual(0, CompareValue(TValue.From<TClass>(TList), TValue.From<TClass>(TList)), 'equal class references');

  Assert.AreNotEqual(0, CompareValue(TValue.From<OleVariant>(OleVariant(1)), TValue.From<OleVariant>(OleVariant(2))), 'OleVariants');
  Assert.AreEqual(0, CompareValue(TValue.From<OleVariant>(OleVariant(1)), TValue.From<OleVariant>(OleVariant(1))), 'equal OleVariants');
end;

procedure TRegressionTests.Identical_Method_Pointers_Compare_Equal;
var
  h : TRegHandler;
  e1, e2 : TNotifyEvent;
begin
  h := TRegHandler.Create;
  try
    e1 := h.Handle;
    e2 := h.Handle;
    Assert.AreEqual(0, CompareValue(TValue.From<TNotifyEvent>(e1), TValue.From<TNotifyEvent>(e2)));
  finally
    h.Free;
  end;
end;

procedure TRegressionTests.Incomparable_Variants_Do_Not_Raise;
var
  result : Integer;
begin
  result := 0;
  Assert.WillNotRaiseAny(procedure
  begin
    result := CompareValue(TValue.From<Variant>(Variant('abc')), TValue.From<Variant>(Variant(1)));
  end);
  Assert.AreNotEqual(0, result);
end;

procedure TRegressionTests.Floats_Compare_Exactly;
var
  d1, d2 : Double;
begin
  d1 := 1.0;
  d2 := d1 + 5E-16;
  Assert.IsTrue(d1 <> d2, 'Premise: the two Doubles differ');
  Assert.AreNotEqual(0, CompareValue(TValue.From<Double>(d1), TValue.From<Double>(d2)));
  Assert.AreEqual(0, CompareValue(TValue.From<Double>(d1), TValue.From<Double>(1.0)));
end;

procedure TRegressionTests.Strings_Compare_Ordinally;
var
  s1, s2 : string;
begin
  s1 := 'ab';
  s2 := 'a' + #$00AD + 'b';
  Assert.AreNotEqual(0, CompareValue(TValue.From<string>(s1), TValue.From<string>(s2)));
  Assert.AreNotEqual(0, CompareValue(TValue.From<string>('abc'), TValue.From<string>('ABC')), 'Case matters');
end;

procedure TRegressionTests.Interfaces_Compare_By_COM_Identity;
var
  a : IRegA;
  b : IRegB;
  other : IRegA;
begin
  a := TRegBoth.Create;
  b := a as IRegB;
  other := TRegBoth.Create;

  Assert.AreEqual(0, CompareValue(TValue.From<IRegA>(a), TValue.From<IRegB>(b)), 'Two interfaces of one object');
  Assert.AreNotEqual(0, CompareValue(TValue.From<IRegA>(a), TValue.From<IRegA>(other)), 'Two objects');
end;

procedure TRegressionTests.Matcher_Gap_In_Behaviour_Setup_Raises_EMockSetupException;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  Assert.WillRaise(procedure
  begin
    mock.Setup.WillReturn(1).When.Calc2(5, It1.IsAny<Integer>);
  end, EMockSetupException);
end;

procedure TRegressionTests.Matcher_Gap_In_Expectation_Setup_Raises_EMockSetupException;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  Assert.WillRaise(procedure
  begin
    mock.Setup.Expect.Once.When.Calc2(5, It1.IsAny<Integer>);
  end, EMockSetupException);
end;

procedure TRegressionTests.Duplicate_Matcher_Index_Raises_And_Next_Setup_Is_Clean;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  Assert.WillRaise(procedure
  begin
    mock.Setup.WillReturn(1).When.Calc2(It0.IsAny<Integer>, It0.IsAny<Integer>);
  end, EMockSetupException);

  mock.Setup.WillReturn(2).When.Calc(It0.IsAny<Integer>);
  Assert.AreEqual(2, mock.Instance.Calc(9));
end;

procedure TRegressionTests.Matcher_From_Ordinary_Call_Does_Not_Leak_Into_Next_Setup;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillReturnDefault('Calc', 0);
  mock.Setup.WillReturnDefault('Calc2', -1);

  //An It expression outside a When: a mistake, which must not affect what follows.
  mock.Instance.Calc(It0.IsAny<Integer>);

  Assert.WillNotRaiseAny(procedure begin mock.Setup.WillReturn(7).When.Calc2(3, 4) end);
  Assert.AreEqual(7, mock.Instance.Calc2(3, 4));
  Assert.AreEqual(-1, mock.Instance.Calc2(1, 1), 'The literal setup must not have picked up an IsAny');
end;

procedure TRegressionTests.OnceWhen_And_Once_Coexist;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillReturnDefault('Calc', 0);
  mock.Setup.Expect.Once.When.Calc(1);
  Assert.WillNotRaiseAny(procedure begin mock.Setup.Expect.Once('Calc') end);

  mock.Instance.Calc(1);
  Assert.WillNotRaiseAny(procedure begin mock.Verify end);
  mock.Instance.Calc(2);
  Assert.WillRaise(procedure begin mock.Verify end, EMockVerificationException);
end;

procedure TRegressionTests.Between_With_Max_Below_Min_Raises;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  Assert.WillRaise(procedure begin mock.Setup.Expect.Between('Calc', 5, 2) end, EMockSetupException);
end;

procedure TRegressionTests.WillReturnDefault_On_Concrete_Virtual_Method_Of_Class_Mock_Is_Returned;
var
  mock : TMock<TRegClass>;
begin
  mock := TMock<TRegClass>.Create;
  mock.Setup.WillReturnDefault('Real', 42);

  Assert.AreEqual(42, mock.Instance.Real);
  Assert.IsFalse(mock.Instance.RealCalled, 'The real method must not run');
end;

procedure TRegressionTests.WillReturnDefault_With_Nil_Object_Is_Returned;
var
  mock : TMock<IRegCalc>;
  obj : TObject;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillReturnDefault('GetObj', TValue.From<TObject>(nil));

  obj := TObject(1);
  Assert.WillNotRaiseAny(procedure begin obj := mock.Instance.GetObj end);
  Assert.IsNull(obj);
end;

procedure TRegressionTests.ResetCalls_Resets_Implemented_Interface;
var
  mock : TMock<IRegA>;
begin
  mock := TMock<IRegA>.Create;
  mock.Implement<IRegB>;
  mock.Setup<IRegB>.Expect.Once.When.B;
  mock.Instance<IRegB>.B;
  Assert.WillNotRaiseAny(procedure begin mock.VerifyAll end);

  mock.ResetCalls;
  Assert.WillRaise(procedure begin mock.VerifyAll end, EMockVerificationException);
end;

procedure TRegressionTests.Clear_Clears_Implemented_Interface;
var
  mock : TMock<IRegA>;
begin
  mock := TMock<IRegA>.Create;
  mock.Implement<IRegB>;
  mock.Setup<IRegB>.Expect.Once.When.B;
  Assert.WillRaise(procedure begin mock.VerifyAll end, EMockVerificationException);

  mock.Setup.Expect.Clear;
  Assert.WillNotRaiseAny(procedure begin mock.VerifyAll end);
end;

procedure TRegressionTests.Instance_Used_After_Mock_Freed_Raises_EMockException;
var
  mock : TMock<IRegA>;
  kept : IRegA;
  queried : IRegB;
  supported : Boolean;
begin
  mock := TMock<IRegA>.Create;
  kept := mock.Instance;
  mock.Free;

  Assert.WillRaise(procedure begin kept.A end, EMockException);

  supported := True;
  Assert.WillNotRaiseAny(procedure begin supported := Supports(kept, IRegB, queried) end);
  Assert.IsFalse(supported);
end;

procedure TRegressionTests.TMock_Free_Twice_Is_Harmless_And_Use_After_Free_Raises;
var
  mock : TMock<IRegA>;
begin
  mock := TMock<IRegA>.Create;
  mock.Free;
  Assert.WillNotRaiseAny(procedure begin mock.Free end);
  Assert.WillRaise(procedure begin mock.Instance end, EMockException);
  Assert.WillRaise(procedure begin mock.Setup end, EMockException);
end;

procedure TRegressionTests.TStub_Uncreated_Or_Freed_Raises_EMockException;
var
  uncreated : TStub<IRegA>;
  freed : TStub<IRegA>;
begin
  Assert.WillRaise(procedure begin uncreated.Setup end, EMockException);

  freed := TStub<IRegA>.Create;
  freed.Free;
  Assert.WillRaise(procedure begin freed.Instance end, EMockException);
end;

procedure TRegressionTests.WillReturnNil_Does_Not_Leak_Into_Next_WillReturn;
var
  mock : TMock<IRegCalc>;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.WillReturnNil.When.GetObj;
  Assert.IsNull(mock.Instance.GetObj);

  Assert.WillRaise(procedure
  begin
    mock.Setup.WillReturn(TValue.From<TObject>(nil)).When.GetObj2;
  end, EMockSetupException);
end;

procedure TRegressionTests.Expectation_Reports_Give_Count_And_Matchers;
var
  mock : TMock<IRegCalc>;
  report : string;
begin
  mock := TMock<IRegCalc>.Create;
  mock.Setup.Expect.AtLeastOnce('Ping');
  mock.Setup.Expect.Once.When.Calc(It0.IsAny<Integer>);

  report := mock.CheckExpectations;
  Assert.Contains(report, 'At Least Once - Was 0', False);
  Assert.Contains(report, '<matcher>', False);
end;

procedure TRegressionTests.Stub_Of_Class_Runs_Overridden_Destructor;
var
  stub : TStub<TRegDestroy>;
begin
  TRegDestroy.Destroyed := False;
  TRegDestroy.BeforeDestructionRan := False;
  stub := TStub<TRegDestroy>.Create;
  Assert.AreEqual(0, stub.Instance.Dummy, 'Premise: the stub intercepts its virtual methods');
  stub.Free;
  Assert.IsTrue(TRegDestroy.BeforeDestructionRan, 'The overridden BeforeDestruction must run');
  Assert.IsTrue(TRegDestroy.Destroyed, 'The overridden destructor must run');
end;

procedure TRegressionTests.Before_When_Met_In_Order_And_Not_Out_Of_Order;
var
  inOrder, outOfOrder : TMock<IRegCalc>;
begin
  inOrder := TMock<IRegCalc>.Create;
  inOrder.Setup.Expect.Before('Pong').When.Ping;
  inOrder.Instance.Ping;
  inOrder.Instance.Pong;
  Assert.WillNotRaiseAny(procedure begin inOrder.Verify end);

  outOfOrder := TMock<IRegCalc>.Create;
  outOfOrder.Setup.Expect.Before('Pong').When.Ping;
  outOfOrder.Instance.Pong;
  outOfOrder.Instance.Ping;
  Assert.WillRaise(procedure begin outOfOrder.Verify end, EMockVerificationException);
end;

procedure TRegressionTests.After_When_Met_In_Order_And_Not_Out_Of_Order;
var
  inOrder, outOfOrder : TMock<IRegCalc>;
begin
  inOrder := TMock<IRegCalc>.Create;
  inOrder.Setup.Expect.After('Ping').When.Pong;
  inOrder.Instance.Ping;
  inOrder.Instance.Pong;
  Assert.WillNotRaiseAny(procedure begin inOrder.Verify end);

  outOfOrder := TMock<IRegCalc>.Create;
  outOfOrder.Setup.Expect.After('Ping').When.Pong;
  outOfOrder.Instance.Pong;
  outOfOrder.Instance.Ping;
  Assert.WillRaise(procedure begin outOfOrder.Verify end, EMockVerificationException);
end;

procedure TRegressionTests.Before_By_Name_Met_In_Order_And_Not_Out_Of_Order;
var
  inOrder, outOfOrder, neverOther : TMock<IRegCalc>;
begin
  inOrder := TMock<IRegCalc>.Create;
  inOrder.Setup.Expect.Before('Ping', 'Pong');
  inOrder.Instance.Ping;
  inOrder.Instance.Pong;
  Assert.WillNotRaiseAny(procedure begin inOrder.Verify end);

  outOfOrder := TMock<IRegCalc>.Create;
  outOfOrder.Setup.Expect.Before('Ping', 'Pong');
  outOfOrder.Instance.Pong;
  outOfOrder.Instance.Ping;
  Assert.WillRaise(procedure begin outOfOrder.Verify end, EMockVerificationException);

  neverOther := TMock<IRegCalc>.Create;
  neverOther.Setup.Expect.Before('Ping', 'Pong');
  neverOther.Instance.Ping;
  Assert.WillRaise(procedure begin neverOther.Verify end, EMockVerificationException);
end;

procedure TRegressionTests.AutoMock_Interface_Return_Value_Is_Usable_And_Stable;
var
  container : TAutoMockContainer;
  factory : TMock<IRegFactory>;
  first, second : IRegA;
begin
  container := TAutoMockContainer.Create;
  factory := container.Mock<IRegFactory>;

  first := factory.Instance.Make;
  Assert.IsNotNull(first);
  Assert.WillNotRaiseAny(procedure begin first.A end);
  second := factory.Instance.Make;
  Assert.IsTrue(first = second, 'The same auto mock must be returned on every call');
end;

procedure TRegressionTests.AutoMockContainer_Used_Before_Create_Raises_EMockException;
var
  container : TAutoMockContainer;
begin
  Assert.WillRaise(procedure begin container.Mock<IRegA> end, EMockException);
end;

procedure TRegressionTests.MethodKindToStr_Unknown_Kind_Raises_Exception_With_Number;
var
  msg : string;
begin
  msg := '';
  try
    MethodKindToStr(TMethodKind(200));
  except
    on E: Exception do
    begin
      Assert.IsTrue(E.ClassType = Exception, 'Expected Exception, got ' + E.ClassName);
      msg := E.Message;
    end;
  end;
  Assert.Contains(msg, '200', False);
end;

procedure TRegressionTests.PatchMethodReturnType_On_Class_Method_Raises_EArgumentException;
var
  context : TRttiContext;
  method : TRttiMethod;
begin
  context := TRttiContext.Create;
  method := context.GetType(TRegClass).GetMethod('Real');
  Assert.IsNotNull(method, 'Premise: the method has RTTI');
  Assert.WillRaise(procedure begin PatchMethodReturnType(method, TypeInfo(Integer)) end, EArgumentException);
end;

initialization
  TDUnitX.RegisterTestFixture(TRegressionTests);

end.
