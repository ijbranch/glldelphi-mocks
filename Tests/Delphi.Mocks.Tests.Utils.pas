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

unit Delphi.Mocks.Tests.Utils;

interface
uses
  DUnitX.TestFramework,
  Rtti,
  Delphi.Mocks.Helpers;

type
  //Testing TValue helper methods in TValueHelper
  {$M+}
  /// <summary>Tests the TValue comparison helpers that decide whether a mocked call's arguments match a setup,
  /// and the RTTI method tests the proxies rely on.</summary>
  [TestFixture]
  TTestTValue = class
  published
    /// <summary>Proves one interface reference compares equal to itself, so an interface argument can match.
    /// </summary>
    procedure Test_TValue_Equals_Interfaces;
    /// <summary>Proves two different objects' interfaces compare unequal.</summary>
    procedure Test_TValue_NotEquals_Interfaces;
    /// <summary>Proves two separately built strings with the same text compare equal.</summary>
    procedure Test_TValue_Equals_Strings;
    /// <summary>Proves strings with different text compare unequal.</summary>
    procedure Test_TValue_NotEquals_Strings;

    /// <summary>Proves a GUID compares equal to a copy of itself.</summary>
    procedure Test_TValue_Equals_SameGuid_Instance;
    /// <summary>Proves two GUIDs parsed separately from the same text compare equal, and that a GUID differing only
    /// in its last byte does not, so every byte is compared.</summary>
    procedure Test_TValue_Equals_DifferentGuid_Instance;
    /// <summary>Proves different GUIDs compare unequal.</summary>
    procedure Test_TValue_NotEquals_Guid;

    /// <summary>Proves IsAbstract tells an abstract method from a normal or virtual one, which decides whether a
    /// class mock runs the real method.</summary>
    procedure Test_TRttiMethod_IsAbstract;
    /// <summary>Proves IsVirtual tells a virtual method from a static one, which decides whether a class mock can
    /// intercept it.</summary>
    procedure Test_TRttiMethod_IsVirtual;

    /// <summary>Proves records with an = operator compare equal through it, with strings built at run time so the
    /// compiler cannot merge them.</summary>
    procedure Test_CompareValue_RecordEquals;
    /// <summary>Proves records with an = operator compare unequal through it.</summary>
    procedure Test_CompareValue_RecordNotEquals;
    /// <summary>Proves records without an = operator compare field by field: different contents unequal, equal
    /// contents built at run time equal. They used to compare equal whatever they held.</summary>
    procedure Test_CompareValue_RecordNoEqualsOperator;

    /// <summary>Proves arrays with the same elements compare equal.</summary>
    procedure Test_CompareValue_ArrayEquals;
    /// <summary>Proves arrays differing in length compare unequal in either order.</summary>
    procedure Test_CompareValue_ArrayNotEquals;

    /// <summary>Proves objects compare equal through their Equals override.</summary>
    procedure Test_CompareValue_ObjectEquals;
    /// <summary>Proves objects whose Equals says they differ compare unequal.</summary>
    procedure Test_CompareValue_ObjectNotEquals;
  end;
  {$M-}

implementation

uses
  SysUtils;

type
  /// <summary>A class with a normal, an abstract and a virtual method, compared by its value.</summary>
  TMyClass = class
  private
    /// <summary>The value Equals compares.</summary>
    FValue: Integer;
  public
    /// <summary>A static method.</summary>
    procedure NormalMethod;
    /// <summary>An abstract method.</summary>
    procedure AbstractMethod; virtual; abstract;
    /// <summary>A virtual method.</summary>
    procedure VirtualMethod; virtual;

    /// <summary>Creates the object.</summary>
    /// <param name="AValue">The value Equals compares.</param>
    constructor Create(AValue: Integer);

    /// <summary>Compares by value.</summary>
    /// <param name="AItem">The other object.</param>
    /// <returns>True when AItem is a TMyClass with the same value.</returns>
    function Equals(AItem: TObject): Boolean; override;
  end;

  /// <summary>GITLAK: the instantiable form of TMyClass, so the comparison tests no longer construct a class
  /// that still has an abstract method (W1020); TMyClass itself stays abstract for the RTTI tests.</summary>
  TMyConcreteClass = class(TMyClass)
  public
    /// <summary>Does nothing; exists only to make the class concrete.</summary>
    procedure AbstractMethod; override;
  end;

  /// <summary>A record with an = operator.</summary>
  TMyRec = record
    /// <summary>The compared value.</summary>
    Value: String;

    /// <summary>Compares by Value.</summary>
    /// <param name="a">The first record.</param>
    /// <param name="b">The second record.</param>
    /// <returns>True when the values are equal.</returns>
    class operator Equal(a, b: TMyRec): Boolean;
  end;

  /// <summary>A record without an = operator.</summary>
  TMySimpleRec = record
    /// <summary>The compared value.</summary>
    Value: String;
  end;

{ TTestTValue }

procedure TTestTValue.Test_TValue_Equals_Interfaces;
var
  i1,i2 : IInterface;
  v1, v2 : TValue;
begin
  i1 := TInterfacedObject.Create;
  i2 := i1;
  v1 := TValue.From<IInterface>(i1);
  v2 := TValue.From<IInterface>(i2);

  Assert.IsTrue(v1.Equals(v2));
end;

procedure TTestTValue.Test_TValue_Equals_Strings;
var
  s1,s2 : string;
  v1, v2 : TValue;
begin
  s1 := 'hello';
  s2 := 'hel';
  s2 := s2 + 'lo';
  v1 := s1;
  v2 := s2;
  Assert.IsTrue(v1.Equals(v2));
end;

procedure TTestTValue.Test_TValue_Equals_SameGuid_Instance;
var
  s1,s2 : TGUID;
  v1, v2 : TValue;
begin
  s1 := StringToGUID( '{2933052C-79D0-48C9-86D3-8FF29416033C}' );
  s2 := s1;
  v1 := TValue.From<TGUID>( s1 );
  v2 := TValue.From<TGUID>( s2 );
  Assert.IsTrue(v1.Equals(v2));
end;

procedure TTestTValue.Test_CompareValue_ArrayEquals;
var
  a1, a2: TArray<string>;
begin
  a1 := [];
  a2 := [];
  Assert.AreEqual(0, CompareValue(TValue.From(a1), TValue.From(a2)));

  a1 := ['a', 'b'];
  a2 := ['a', 'b'];
  Assert.AreEqual(0, CompareValue(TValue.From(a1), TValue.From(a2)));
end;

procedure TTestTValue.Test_CompareValue_ArrayNotEquals;
var
  a1, a2: TArray<string>;
begin
  a1 := ['a'];
  a2 := ['a', 'b'];
  Assert.AreNotEqual(0, CompareValue(TValue.From(a1), TValue.From(a2)));

  a1 := ['a', 'b'];
  a2 := ['a'];
  Assert.AreNotEqual(0, CompareValue(TValue.From(a1), TValue.From(a2)));

  a1 := [];
  a2 := ['a'];
  Assert.AreNotEqual(0, CompareValue(TValue.From(a1), TValue.From(a2)));

  a1 := ['a'];
  a2 := [];
  Assert.AreNotEqual(0, CompareValue(TValue.From(a1), TValue.From(a2)));
end;

procedure TTestTValue.Test_CompareValue_ObjectEquals;
var
  o1, o2: TMyClass;
begin
  o1 := TMyConcreteClass.Create(1);
  o2 := TMyConcreteClass.Create(1);
  try
    Assert.AreEqual(0, CompareValue(TValue.From<TMyClass>(o1), TValue.From<TMyClass>(o1)));
    Assert.AreEqual(0, CompareValue(TValue.From<TMyClass>(o2), TValue.From<TMyClass>(o2)));
    Assert.AreEqual(0, CompareValue(TValue.From<TMyClass>(o1), TValue.From<TMyClass>(o2)));
  finally
    o1.Free;
    o2.Free;
  end;
end;

procedure TTestTValue.Test_CompareValue_ObjectNotEquals;
var
  o1, o2: TMyClass;
begin
  o1 := TMyConcreteClass.Create(1);
  o2 := TMyConcreteClass.Create(2);
  try
    Assert.AreEqual(0, CompareValue(TValue.From<TMyClass>(o1), TValue.From<TMyClass>(o1)));
    Assert.AreEqual(0, CompareValue(TValue.From<TMyClass>(o2), TValue.From<TMyClass>(o2)));
    Assert.AreNotEqual(0, CompareValue(TValue.From<TMyClass>(o1), TValue.From<TMyClass>(o2)));
  finally
    o1.Free;
    o2.Free;
  end;
end;

procedure TTestTValue.Test_CompareValue_RecordEquals;
var
  r1, r2: TMyRec;
begin
  r1.Value := 'test';
  r2.Value := 'te';
  r2.Value := r2.Value + 'st';

  Assert.AreEqual(0, CompareValue(TValue.From(r1), TValue.From(r2)));
end;

procedure TTestTValue.Test_CompareValue_RecordNoEqualsOperator;
var
  r1, r2: TMySimpleRec;
begin
  r1.Value := 'test';
  r2.Value := 'test1';

  Assert.AreNotEqual(0, CompareValue(TValue.From(r1), TValue.From(r2)), 'Different contents must not compare equal');

  r2.Value := 'te';
  r2.Value := r2.Value + 'st';
  Assert.AreEqual(0, CompareValue(TValue.From(r1), TValue.From(r2)), 'Equal contents must compare equal');
end;

procedure TTestTValue.Test_CompareValue_RecordNotEquals;
var
  r1, r2: TMyRec;
begin
  r1.Value := 'test';
  r2.Value := 'test1';

  Assert.AreNotEqual(0, CompareValue(TValue.From(r1), TValue.From(r2)));
end;

procedure TTestTValue.Test_TRttiMethod_IsAbstract;
var
  LCtx: TRttiContext;
begin
  Assert.IsFalse(LCtx.GetType(TMyClass).GetMethod('NormalMethod').IsAbstract);
  Assert.IsTrue(LCtx.GetType(TMyClass).GetMethod('AbstractMethod').IsAbstract);
  Assert.IsFalse(LCtx.GetType(TMyClass).GetMethod('VirtualMethod').IsAbstract);
end;

procedure TTestTValue.Test_TRttiMethod_IsVirtual;
var
  LCtx: TRttiContext;
begin
  Assert.IsFalse(LCtx.GetType(TMyClass).GetMethod('NormalMethod').IsVirtual);
  Assert.IsTrue(LCtx.GetType(TMyClass).GetMethod('AbstractMethod').IsVirtual);
  Assert.IsTrue(LCtx.GetType(TMyClass).GetMethod('VirtualMethod').IsVirtual);
end;

procedure TTestTValue.Test_TValue_Equals_DifferentGuid_Instance;
var
  s1,s2 : TGUID;
  v1, v2 : TValue;
begin
  s1 := StringToGUID( '{2933052C-79D0-48C9-86D3-8FF29416033C}' );
  s2 := StringToGUID( '{2933052C-79D0-48C9-86D3-8FF29416033C}' );
  v1 := TValue.From<TGUID>( s1 );
  v2 := TValue.From<TGUID>( s2 );
  Assert.IsTrue(v1.Equals(v2));

  s2.D4[7] := s2.D4[7] xor 1;
  v2 := TValue.From<TGUID>( s2 );
  Assert.IsFalse(v1.Equals(v2), 'A GUID differing in its last byte must not compare equal');
end;

procedure TTestTValue.Test_TValue_NotEquals_Guid;
var
  s1,s2 : TGUID;
  v1, v2 : TValue;
begin
  s1 := StringToGUID( '{2933052C-79D0-48C9-86D3-8FF294160000}' );
  s2 := StringToGUID( '{2933052C-79D0-48C9-86D3-8FF29416FFFF}' );
  v1 := TValue.From<TGUID>( s1 );
  v2 := TValue.From<TGUID>( s2 );
  Assert.IsFalse(v1.Equals(v2));
end;

procedure TTestTValue.Test_TValue_NotEquals_Interfaces;
var
  i1,i2 : IInterface;
  v1, v2 : TValue;
begin
  i1 := TInterfacedObject.Create;
  i2 := TInterfacedObject.Create;
  v1 := TValue.From<IInterface>(i1);
  v2 := TValue.From<IInterface>(i2);
  Assert.IsFalse(v1.Equals(v2));
end;

procedure TTestTValue.Test_TValue_NotEquals_Strings;
var
  s1,s2 : string;
  v1, v2 : TValue;
begin
  s1 := 'hello';
  s2 := 'goodbye';
  v1 := s1;
  v2 := s2;
  Assert.IsFalse(v1.Equals(v2));
end;

{ TMyClass }

constructor TMyClass.Create(AValue: Integer);
begin
  FValue := AValue;
end;

function TMyClass.Equals(AItem: TObject): Boolean;
begin
  Result := AItem is TMyClass;
  if Result then
    Result := TMyClass(AItem).FValue = Self.FValue;
end;

procedure TMyClass.NormalMethod;
begin
  //No op
end;

procedure TMyClass.VirtualMethod;
begin
  //No op
end;

{ TMyConcreteClass }

procedure TMyConcreteClass.AbstractMethod;
begin
  //No op
end;

{ TMyRec }

class operator TMyRec.Equal(a, b: TMyRec): Boolean;
begin
  Result := a.Value = b.Value;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTValue);

end.
