unit Delphi.Mocks.Tests.OpenArrayIntf;

interface

uses
  DUnitX.TestFramework;

type
  {$M+}
  /// <summary>Tests mocking methods that take arrays.</summary>
  [TestFixture]
  TestIOpenArray = class
  published
    /// <summary>Proves a setup on an open array parameter followed by another parameter matches the call and
    /// returns its value.</summary>
    [Ignore('BUG: System.Rtti TInvokeInfo.LoadArguments caches an open array''s type info in the shared FParams and reads it freed on later calls; open arrays reach the mock without elements')]
    procedure TestMyMethodDynamicArray;
    /// <summary>Proves a setup on a typed dynamic array parameter matches the call and returns its value.
    /// </summary>
    procedure TestMyMethodTypedArray;
    /// <summary>Proves setups kept for open arrays of different contents each match only their own contents, and
    /// a call with other contents falls to the default.  A setup keeps the call's argument past the call, when the
    /// RTL has freed the open array's type information; read from freed memory it matched nothing.</summary>
    [Ignore('BUG: System.Rtti TInvokeInfo.LoadArguments caches an open array''s type info in the shared FParams and reads it freed on later calls; open arrays reach the mock without elements')]
    procedure TestOpenArraySetupsMatchByContents;
    /// <summary>Proves expectations kept for open arrays of different contents are told apart when defined, are
    /// not met by a call with other contents and are met by calls with their own ( the expectation path keeps its
    /// own copy of the arguments ).</summary>
    [Ignore('BUG: System.Rtti TInvokeInfo.LoadArguments caches an open array''s type info in the shared FParams and reads it freed on later calls; open arrays reach the mock without elements')]
    procedure TestOpenArrayExpectationMatchesByContents;
    /// <summary>Proves setups and an expectation kept for a static array argument match by contents: the kept copy
    /// is a TArray&lt;TValue&gt; of the elements ( DetachedArgValue ), compared element by element with the call's
    /// static array.  The open array tests cannot run while the System.Rtti defect stands; this covers that path.
    /// </summary>
    procedure TestStaticArraySetupsAndExpectationMatchByContents;
  end;
  {$M-}

  /// <summary>A typed dynamic array.</summary>
  TMyArray = array of Integer;

  {$M+}
  /// <summary>An interface taking an open array and another parameter.</summary>
  IDynamicArray = interface
    // This crashes: One open array + one more parameter. Only the open array works.
    /// <summary>Takes an open array.</summary>
    /// <param name="MyArray">The array.</param>
    /// <param name="Number">A number.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function MyMethod(MyArray: array of Integer; Number: Integer): Integer;
  end;

  /// <summary>An interface taking a typed dynamic array.</summary>
  ITypedArray = interface
    /// <summary>Takes a typed array.</summary>
    /// <param name="MyArray">The array.</param>
    /// <param name="Number">A number.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function MyMethod(MyArray: TMyArray; Number: Integer): Integer;

  end;
  {$M-}

  /// <summary>A static array of two integers.</summary>
  TIntPair = array[0..1] of Integer;

  {$M+}
  /// <summary>An interface taking a static array.</summary>
  IStaticArray = interface
    /// <summary>Takes a static array.</summary>
    /// <param name="APair">The array.</param>
    /// <returns>Whatever the mock is set up to return.</returns>
    function MyMethod(const APair: TIntPair): Integer;
  end;
  {$M-}

implementation

uses
  Delphi.Mocks;

procedure TestIOpenArray.TestMyMethodDynamicArray;
var
  Mock: TMock<IDynamicArray>;
  Intf: IDynamicArray;
  returnValue: integer;
begin
  Mock := TMock<IDynamicArray>.Create;

  Mock.Setup.WillReturn(3).When.MyMethod([123], 1);

  Intf := Mock;

  // in XE6 there was only an access violation, when using the Method inside the "Assert.AreEqual" method
  // Using a local variable fixed this AV
  returnValue := Intf.MyMethod([123], 1);
  Assert.AreEqual(3, returnValue);
end;

procedure TestIOpenArray.TestMyMethodTypedArray;
var
  Mock: TMock<ITypedArray>;
  Intf: ITypedArray;
  MyArray: TMyArray;
begin
  Mock := TMock<ITypedArray>.Create;

  // Setup our typed array
  SetLength(MyArray, 1);
  MyArray[0] := 123;

  Mock.Setup.WillReturn(2).When.MyMethod(MyArray, 1);

  Intf := Mock;

  // This works! yay :D
  Assert.AreEqual(2, Intf.MyMethod(MyArray, 1));
end;

procedure TestIOpenArray.TestOpenArraySetupsMatchByContents;
var
  Mock: TMock<IDynamicArray>;
  Intf: IDynamicArray;
begin
  Mock := TMock<IDynamicArray>.Create;
  Mock.Setup.WillReturnDefault('MyMethod', 0);
  Mock.Setup.WillReturn(10).When.MyMethod([1, 2], 1);
  Mock.Setup.WillReturn(20).When.MyMethod([3], 1);
  Intf := Mock;

  var lFirst := Intf.MyMethod([1, 2], 1);
  var lSecond := Intf.MyMethod([3], 1);
  var lOther := Intf.MyMethod([1, 3], 1);
  Assert.AreEqual(10, lFirst, '[1, 2]');
  Assert.AreEqual(20, lSecond, '[3]');
  Assert.AreEqual(0, lOther, '[1, 3] matches no setup');
end;

procedure TestIOpenArray.TestOpenArrayExpectationMatchesByContents;
var
  Mock: TMock<IDynamicArray>;
  Intf: IDynamicArray;
begin
  Mock := TMock<IDynamicArray>.Create;
  Mock.Setup.WillReturnDefault('MyMethod', 0);
  Mock.Setup.Expect.Once.When.MyMethod([5, 6], 2);
  Mock.Setup.Expect.Once.When.MyMethod([7], 2);
  Intf := Mock;

  Intf.MyMethod([5], 2);
  Assert.WillRaise(
    procedure
    begin
      Mock.Verify;
    end, EMockVerificationException, 'a call with other contents met the expectation');

  Intf.MyMethod([5, 6], 2);
  Intf.MyMethod([7], 2);
  Assert.WillNotRaise(
    procedure
    begin
      Mock.Verify;
    end, EMockVerificationException, 'the calls with the same contents did not meet the expectations');
end;

function MakePair(AFirst, ASecond: Integer): TIntPair;
begin
  Result[0] := AFirst;
  Result[1] := ASecond;
end;

procedure TestIOpenArray.TestStaticArraySetupsAndExpectationMatchByContents;
var
  Mock: TMock<IStaticArray>;
  Intf: IStaticArray;
begin
  Mock := TMock<IStaticArray>.Create;
  Mock.Setup.WillReturnDefault('MyMethod', 0);
  Mock.Setup.WillReturn(10).When.MyMethod(MakePair(1, 2));
  Mock.Setup.WillReturn(20).When.MyMethod(MakePair(3, 4));
  Mock.Setup.Expect.Once.When.MyMethod(MakePair(3, 4));
  Intf := Mock;

  var lFirst := Intf.MyMethod(MakePair(1, 2));
  var lOther := Intf.MyMethod(MakePair(1, 4));
  Assert.AreEqual(10, lFirst, '[1, 2]');
  Assert.AreEqual(0, lOther, '[1, 4] matches no setup');
  Assert.WillRaise(
    procedure
    begin
      Mock.Verify;
    end, EMockVerificationException, 'the expectation on [3, 4] was met with no such call');

  var lSecond := Intf.MyMethod(MakePair(3, 4));
  Assert.AreEqual(20, lSecond, '[3, 4]');
  Assert.WillNotRaise(
    procedure
    begin
      Mock.Verify;
    end, EMockVerificationException, 'the call with [3, 4] did not meet the expectation');
end;

initialization
  TDUnitX.RegisterTestFixture(TestIOpenArray);
end.
