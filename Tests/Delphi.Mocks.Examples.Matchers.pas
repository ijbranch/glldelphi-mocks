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

unit Delphi.Mocks.Examples.Matchers;

interface

{$I 'Delphi.Mocks.inc'}

uses
  DUnitX.TestFramework, System.Generics.Defaults;

type
  /// <summary>An object with a public field and a public property, for the AreSame matchers.</summary>
  TObjectToTest = class
  private
    /// <summary>Backs PropertyToTest.</summary>
    FPropertyToTest: Integer;
  public
    /// <summary>A public field the AreSameFields matchers compare.</summary>
    FieldToTest: Integer;

    /// <summary>A public property the AreSameProperties matchers compare.</summary>
    property PropertyToTest: Integer read FPropertyToTest write FPropertyToTest;
  end;

  /// <summary>One descendant of TObjectToTest.</summary>
  TAnotherObject = class(TObjectToTest);

  /// <summary>Another descendant of TObjectToTest, unrelated to TAnotherObject.</summary>
  TAndAnotherObject = class(TObjectToTest);

  /// <summary>A record with an = operator and a hand-made equality comparer.</summary>
  TRecordToTest = record
  private
    /// <summary>The compared value.</summary>
    internalValue: String;
  public
    /// <summary>Makes a record from a string.</summary>
    /// <param name="s">The value.</param>
    /// <returns>The record.</returns>
    class operator Implicit(const s: String): TRecordToTest;
    /// <summary>Compares by value.</summary>
    /// <param name="mine">The first record.</param>
    /// <param name="other">The second record.</param>
    /// <returns>True when the values are equal.</returns>
    class operator Equal(mine, other: TRecordToTest): Boolean;

    /// <summary>Returns a comparer that uses the = operator.</summary>
    /// <returns>The comparer.</returns>
    class function EqualityComparer: IEqualityComparer<TRecordToTest>; static;
  end;

  {$M+}
  /// <summary>An interface with two- and four-parameter functions.</summary>
  IInterfaceToTest = interface
    ['{2AB032A9-ED5B-4FDC-904B-E3F1B2C78978}']
    /// <summary>A two-parameter function.</summary>
    /// <param name="A">An integer.</param>
    /// <param name="B">A Boolean.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function TakesTwoParams(const A: integer; const B: boolean) : integer;
    /// <summary>A four-parameter function.</summary>
    /// <param name="A">A string.</param>
    /// <param name="B">A Boolean.</param>
    /// <param name="C">An integer.</param>
    /// <param name="D">A string.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function TakesFourParams(const A: string; const B: boolean; const C: integer; const D: string) : integer;
  end;

  /// <summary>An empty interface.</summary>
  ILoan = interface
  end;

  /// <summary>An enumeration to match on.</summary>
  TEnumerator = (Value1, Value2, Value3);

  /// <summary>An interface taking an enumeration or an integer.</summary>
  IInterfaceToTestWithEnumerator = interface
    ['{45799970-833E-4419-A683-24E07AD742C2}']
    /// <summary>Takes an enumeration.</summary>
    /// <param name="Enumerator">The value.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function AnyFuntionWithEnumerator(Enumerator: TEnumerator): Integer;
    /// <summary>Takes an integer.</summary>
    /// <param name="Value">The value.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function AnyFuntionWithInteger(Value: Integer): Integer;
  end;

  /// <summary>An interface taking an object. It shared IInterfaceToTestWithEnumerator's GUID, so a QueryInterface
  /// for either could return the other; it now has its own.</summary>
  IInterfaceToTestWithObjects = interface
    ['{7D1F3A52-6C0B-4E8E-9B47-2A5D0C81F6E3}']
    /// <summary>Takes an object.</summary>
    /// <param name="AObject">The object.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function AnyFuntionWithObject(AObject: TObjectToTest): Integer;
  end;
  {$M-}

  {$M+}
  /// <summary>Tests setups made with It0..It9 matchers, through a mock.</summary>
  [TestFixture]
  TExample_MatchersTests = class
  published
    /// <summary>Proves IsEqualTo and IsAny matchers select the right setup across several overlapping setups.
    /// </summary>
    [Test]
    procedure Match_parameter_values;
    /// <summary>Proves IsEqualTo matches enumeration values exactly.</summary>
    [Test]
    procedure Match_parameter_with_enumerators;
    /// <summary>Proves IsEqualTo setups on different integers stay separate.</summary>
    [Test]
    procedure Match_parameter_with_diferent_values;
    /// <summary>Proves the AreSame matchers match distinct objects with equal members, and nil only with nil.
    /// </summary>
    [Test]
    procedure Match_parameter_with_objects;
    /// <summary>Proves IsIn and IsNotIn reject what they should, so a setup does not answer for arguments it
    /// excludes.</summary>
    [Test]
    procedure Match_parameter_rejected_by_IsIn_and_IsNotIn;
  end;
  {$M-}

  /// <summary>Tests the matchers It registers for records.</summary>
  [TestFixture]
  TItRecTests = class
    /// <summary>Proves the record matchers accept and reject through a supplied equality comparer.</summary>
    [Test]
    procedure Record_with_equality_comparer;
    /// <summary>Proves the record matchers use the record's = operator when no comparer is given. The values are
    /// built at run time, so a bytewise compare of the string pointers would fail: only the operator passes.
    /// </summary>
    [Test]
    procedure Record_with_operator_overloaded_comparer;
  end;

  /// <summary>Tests the matchers It registers for classes.</summary>
  [TestFixture]
  TItClassTests = class
    /// <summary>Proves IsAny&lt;T&gt; for a class rejects an instance of a sibling class.</summary>
    [Test]
    procedure Class_descendant_matches_on_exact_type;
  end;

implementation

uses
  Rtti,
  SysUtils,
  TypInfo,
  Delphi.Mocks,
  System.Hash,
  Delphi.Mocks.ParamMatcher;

/// <summary>Builds a fresh copy of a string on the heap, so it shares no storage with a literal.</summary>
/// <param name="S">The text.</param>
/// <returns>A new string with the same text.</returns>
function RunTime(const S: string): string;
begin
  Result := Copy(S, 1, Length(S));
  UniqueString(Result);
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

  mockCredit.Setup.WillReturn(1).When.TakesFourParams(It0.IsAny<string>(), It1.IsEqualTo<boolean>(false), It2.IsEqualTo<integer>(1),
    It3.IsEqualTo<string>('hello'));

  Assert.AreEqual(6, mockCredit.Instance.TakesTwoParams(1, true));
  Assert.AreEqual(12, mockCredit.Instance.TakesTwoParams(2, true));
  Assert.AreEqual(8, mockCredit.Instance.TakesTwoParams(1, false));

  Assert.AreEqual(1, mockCredit.Instance.TakesFourParams('asdfasfasdf', false, 1, 'hello'));
  Assert.AreEqual(1, mockCredit.Instance.TakesFourParams('asdfjkljklsdfjf', false, 1, 'hello'));
end;

{ TScorer }

procedure TExample_MatchersTests.Match_parameter_with_diferent_values;
var
  Mock: TMock<IInterfaceToTestWithEnumerator>;

begin
  Mock := TMock<IInterfaceToTestWithEnumerator>.Create;

  Mock.Setup.WillReturn(-1).When.AnyFuntionWithInteger(It0.IsEqualTo(0));
  Mock.Setup.WillReturn(10).When.AnyFuntionWithInteger(It0.IsEqualTo(1));
  Mock.Setup.WillReturn(20).When.AnyFuntionWithInteger(It0.IsEqualTo(2));
  Mock.Setup.WillReturn(30).When.AnyFuntionWithInteger(It0.IsEqualTo(3));

  Assert.AreEqual(-1, Mock.Instance.AnyFuntionWithInteger(0));
  Assert.AreEqual(10, Mock.Instance.AnyFuntionWithInteger(1));
  Assert.AreEqual(20, Mock.Instance.AnyFuntionWithInteger(2));
  Assert.AreEqual(30, Mock.Instance.AnyFuntionWithInteger(3));
end;

procedure TExample_MatchersTests.Match_parameter_with_enumerators;
var
  Mock: TMock<IInterfaceToTestWithEnumerator>;

begin
  Mock := TMock<IInterfaceToTestWithEnumerator>.Create;

  Mock.Setup.WillReturn(10).When.AnyFuntionWithEnumerator(It0.IsEqualTo(Value1));
  Mock.Setup.WillReturn(20).When.AnyFuntionWithEnumerator(It0.IsEqualTo(Value2));
  Mock.Setup.WillReturn(30).When.AnyFuntionWithEnumerator(It0.IsEqualTo(Value3));

  Assert.AreEqual(10, Mock.Instance.AnyFuntionWithEnumerator(Value1));
  Assert.AreEqual(20, Mock.Instance.AnyFuntionWithEnumerator(Value2));
  Assert.AreEqual(30, Mock.Instance.AnyFuntionWithEnumerator(Value3));
end;

procedure TExample_MatchersTests.Match_parameter_with_objects;
var
  Mock: TMock<IInterfaceToTestWithObjects>;

  Object1,
  Object2,
  Object3,
  ObjectToCompare1,
  ObjectToCompare2,
  ObjectToCompare3: TObjectToTest;

begin
  Mock := TMock<IInterfaceToTestWithObjects>.Create;
  Object1 := nil;
  Object2 := nil;
  Object3 := nil;
  ObjectToCompare1 := nil;
  ObjectToCompare2 := nil;
  ObjectToCompare3 := nil;
  try
    Object1 := TObjectToTest.Create;
    Object1.FieldToTest := 10;
    Object1.PropertyToTest := 20;
    Object2 := TObjectToTest.Create;
    Object2.FieldToTest := 30;
    Object2.PropertyToTest := 40;
    Object3 := TObjectToTest.Create;
    Object3.FieldToTest := 50;
    Object3.PropertyToTest := 60;
    ObjectToCompare1 := TObjectToTest.Create;
    ObjectToCompare1.FieldToTest := 10;
    ObjectToCompare1.PropertyToTest := 20;
    ObjectToCompare2 := TObjectToTest.Create;
    ObjectToCompare2.FieldToTest := 30;
    ObjectToCompare2.PropertyToTest := 40;
    ObjectToCompare3 := TObjectToTest.Create;
    ObjectToCompare3.FieldToTest := 50;
    ObjectToCompare3.PropertyToTest := 60;

    Mock.Setup.WillReturn(10).When.AnyFuntionWithObject(It0.AreSameFieldsThat<TObjectToTest>(nil));
    Mock.Setup.WillReturn(20).When.AnyFuntionWithObject(It0.AreSameFieldsThat(Object1));
    Mock.Setup.WillReturn(30).When.AnyFuntionWithObject(It0.AreSamePropertiesThat(Object2));
    Mock.Setup.WillReturn(40).When.AnyFuntionWithObject(It0.AreSameFieldsAndPropertiedThat(Object3));

    Assert.AreEqual(10, Mock.Instance.AnyFuntionWithObject(nil));
    Assert.AreEqual(20, Mock.Instance.AnyFuntionWithObject(ObjectToCompare1));
    Assert.AreEqual(30, Mock.Instance.AnyFuntionWithObject(ObjectToCompare2));
    Assert.AreEqual(40, Mock.Instance.AnyFuntionWithObject(ObjectToCompare3));
  finally
    //These leaked: six objects per run.
    Object1.Free;
    Object2.Free;
    Object3.Free;
    ObjectToCompare1.Free;
    ObjectToCompare2.Free;
    ObjectToCompare3.Free;
  end;
end;

procedure TExample_MatchersTests.Match_parameter_rejected_by_IsIn_and_IsNotIn;
var
  Mock: TMock<IInterfaceToTestWithEnumerator>;
begin
  Mock := TMock<IInterfaceToTestWithEnumerator>.Create;
  Mock.Setup.WillReturnDefault('AnyFuntionWithInteger', 0);
  Mock.Setup.WillReturnDefault('AnyFuntionWithEnumerator', 0);

  Mock.Setup.WillReturn(1).When.AnyFuntionWithInteger(It0.IsIn<Integer>([10, 20]));
  Mock.Setup.WillReturn(2).When.AnyFuntionWithEnumerator(It0.IsNotIn<TEnumerator>([Value1, Value2]));

  Assert.AreEqual(1, Mock.Instance.AnyFuntionWithInteger(20));
  Assert.AreEqual(0, Mock.Instance.AnyFuntionWithInteger(30), 'IsIn must reject a value outside the list');
  Assert.AreEqual(2, Mock.Instance.AnyFuntionWithEnumerator(Value3));
  Assert.AreEqual(0, Mock.Instance.AnyFuntionWithEnumerator(Value1), 'IsNotIn must reject a value in the list');
end;

{ TRecordToTest }

class operator TRecordToTest.Equal(mine, other: TRecordToTest): Boolean;
begin
  Result := mine.internalValue = other.internalValue;
end;

class function TRecordToTest.EqualityComparer: IEqualityComparer<TRecordToTest>;
begin
  Result := TEqualityComparer<TRecordToTest>.Construct(
    function(const Left, Right: TRecordToTest): Boolean
    begin
      Result := Left = Right;
    end,
    function(const Value: TRecordToTest): Integer
    begin
      Result := THashBobJenkins.GetHashValue(PChar(Value.internalValue)^, SizeOf(Char) * Length(Value.internalValue), 0);
    end);
end;

class operator TRecordToTest.Implicit(const s: String): TRecordToTest;
begin
  Result.internalValue := s;
end;

{ TItRecTests }

procedure TItRecTests.Record_with_equality_comparer;
var
  LMatchers: TArray<IMatcher>;
begin
  Assert.AreEqual<NativeInt>(0, Length(TMatcherFactory.GetMatchers()), 'No matcher may be pending from an earlier test');

  It(0).IsEqualTo<TRecordToTest>('test1', TRecordToTest.EqualityComparer);
  It(1).IsIn<TRecordToTest>(['test1', 'test2'], TRecordToTest.EqualityComparer);
  It(2).IsNotIn<TRecordToTest>(['test1', 'test3'], TRecordToTest.EqualityComparer);
  It(3).IsNotNil<TRecordToTest>;

  LMatchers := TMatcherFactory.GetMatchers();
  Assert.AreEqual<NativeInt>(4, Length(LMatchers));

  Assert.IsTrue(LMatchers[0].Match(TValue.From<TRecordToTest>(RunTime('test1'))));
  Assert.IsFalse(LMatchers[0].Match(TValue.From<TRecordToTest>(RunTime('test2'))));
  Assert.IsTrue(LMatchers[1].Match(TValue.From<TRecordToTest>(RunTime('test2'))));
  Assert.IsFalse(LMatchers[1].Match(TValue.From<TRecordToTest>(RunTime('test3'))));
  Assert.IsTrue(LMatchers[2].Match(TValue.From<TRecordToTest>(RunTime('test2'))));
  Assert.IsFalse(LMatchers[2].Match(TValue.From<TRecordToTest>(RunTime('test3'))));
  Assert.IsTrue(LMatchers[3].Match(TValue.From<TRecordToTest>(RunTime('test3'))));
end;

procedure TItRecTests.Record_with_operator_overloaded_comparer;
var
  LMatchers: TArray<IMatcher>;
begin
  Assert.AreEqual<NativeInt>(0, Length(TMatcherFactory.GetMatchers()), 'No matcher may be pending from an earlier test');

  It(0).IsEqualTo<TRecordToTest>(RunTime('test1'));
  It(1).IsIn<TRecordToTest>([RunTime('test1'), RunTime('test2')]);
  It(2).IsNotIn<TRecordToTest>([RunTime('test1'), RunTime('test3')]);
  It(3).IsNotNil<TRecordToTest>;

  LMatchers := TMatcherFactory.GetMatchers();
  Assert.AreEqual<NativeInt>(4, Length(LMatchers));

  Assert.IsTrue(LMatchers[0].Match(TValue.From<TRecordToTest>(RunTime('test1'))));
  Assert.IsFalse(LMatchers[0].Match(TValue.From<TRecordToTest>(RunTime('test2'))));
  Assert.IsTrue(LMatchers[1].Match(TValue.From<TRecordToTest>(RunTime('test2'))));
  Assert.IsFalse(LMatchers[1].Match(TValue.From<TRecordToTest>(RunTime('test3'))));
  Assert.IsTrue(LMatchers[2].Match(TValue.From<TRecordToTest>(RunTime('test2'))));
  Assert.IsFalse(LMatchers[2].Match(TValue.From<TRecordToTest>(RunTime('test1'))));
  Assert.IsTrue(LMatchers[3].Match(TValue.From<TRecordToTest>(RunTime('test3'))));
end;

{ TItClassTests }

procedure TItClassTests.Class_descendant_matches_on_exact_type;
var
  LMatchers: TArray<IMatcher>;
  LAnotherObject: TAnotherObject;
  LAndAnotherObject: TAndAnotherObject;
begin
  Assert.AreEqual<NativeInt>(0, Length(TMatcherFactory.GetMatchers()), 'No matcher may be pending from an earlier test');

  It(0).IsAny<TAnotherObject>();
  It(1).IsAny<TAndAnotherObject>();

  LMatchers := TMatcherFactory.GetMatchers();
  Assert.AreEqual<NativeInt>(2, Length(LMatchers));

  LAnotherObject := TAnotherObject.Create;
  LAndAnotherObject := TAndAnotherObject.Create;
  try
    Assert.IsTrue(LMatchers[0].Match(TValue.From<TAnotherObject>(LAnotherObject)));
    Assert.IsTrue(LMatchers[1].Match(TValue.From<TAndAnotherObject>(LAndAnotherObject)));

    Assert.IsFalse(LMatchers[1].Match(TValue.From<TAndAnotherObject>(TAndAnotherObject(LAnotherObject))));
  finally
    LAnotherObject.Free;
    LAndAnotherObject.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TExample_MatchersTests);
  TDUnitX.RegisterTestFixture(TItRecTests);
  TDUnitX.RegisterTestFixture(TItClassTests);

end.
