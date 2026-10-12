unit Delphi.Mocks.Tests.TValue;

interface

uses
  DUnitX.TestFramework;

type
  {$M+}
  /// <summary>Tests the TValue kind tests the comparison helpers branch on.</summary>
  TValueTests = class
  published
    /// <summary>Proves IsRecord is True for a record only, not a string, object or interface.</summary>
    procedure Test_IsRecord;
    /// <summary>Proves IsArray is True for a dynamic array and not for a string.</summary>
    procedure Test_IsArray;
  end;
  {$M-}

implementation

uses
  Delphi.Mocks.Helpers, System.Rtti;

{ TValueTests }

type
  /// <summary>A record.</summary>
  TMyRec = record
    /// <summary>A field.</summary>
    Value: String;
  end;

procedure TValueTests.Test_IsArray;
begin
  Assert.IsFalse(TValue.From<string>('test').IsArray);
  Assert.IsTrue(TValue.From<TArray<string>>(['a', 'b']).IsArray);
end;

procedure TValueTests.Test_IsRecord;
var
  r: TMyRec;
  o: TObject;
  i: IInterface;
begin
  o := TObject.Create;
  try
    Assert.IsFalse(TValue.From<string>('test').IsRecord);
    Assert.IsFalse(TValue.From<TObject>(o).IsRecord);
    Assert.IsFalse(TValue.From<IInterface>(i).IsRecord);
    Assert.IsTrue(TValue.From<TMyRec>(r).IsRecord);
  finally
    o.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TValueTests);
end.
