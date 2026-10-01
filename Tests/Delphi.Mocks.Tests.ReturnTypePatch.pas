unit Delphi.Mocks.Tests.ReturnTypePatch;

{ GITLAK addition (2026-10-02). Delphi.Mocks.ReturnTypePatch reaches into the private layout of
  System.Rtti's TRttiIntfMethod through a shadow class, so an Embarcadero change to that layout
  would break it silently. These tests make such a break a red test instead. }

interface

uses
  DUnitX.TestFramework,
  Delphi.Mocks.ReturnTypePatch;

type
  /// <summary>An enumeration with explicit ordinals, which the compiler gives no type information, so a
  /// method returning it carries a nil return type in its RTTI - the case the patch exists for.</summary>
  TGappedEnum = ( geFirst = 1, geSecond = 5 );

  {$M+}
  /// <summary>Subject interface: each method returns a type without type information, so each needs
  /// the patch, and each is patched by a different route.</summary>
  IReturnTypePatchSubject = interface
    ['{80A7E8CF-B4E1-4FAD-88EC-3D8FA999D445}']
    /// <summary>Never patched; proves the premise that the return type is missing.</summary>
    /// <returns>Unused; the method is never called.</returns>
    function Untouched : TGappedEnum;
    /// <summary>Patched by name, and carries parameters so the patch has to walk past them.</summary>
    /// <param name="AName">Present only to make the parameter walk non-trivial.</param>
    /// <param name="AValue">Present only to make the parameter walk non-trivial.</param>
    /// <returns>Unused; the method is never called.</returns>
    function ByName( const AName : string; AValue : Integer ) : TGappedEnum;
    /// <summary>Patched through the attribute route.</summary>
    /// <returns>Unused; the method is never called.</returns>
    [ReturnTypePatch( TypeInfo( Integer ) )]
    function ByAttribute : TGappedEnum;
  end;
  {$M-}

  {$M+}
  /// <summary>Tests that PatchMethodReturnType still writes where System.Rtti reads.</summary>
  [TestFixture]
  TReturnTypePatchTests = class
  published
    /// <summary>Proves the test input reaches the code: without the patch the compiler really does leave
    /// the return type nil. If this ever fails, the other tests no longer exercise the patch.</summary>
    procedure Untouched_Method_Has_No_Return_Type;
    /// <summary>Proves the by-name route makes RTTI report the patched type, and that walking past the
    /// parameters did not disturb them. A moved private field leaves ReturnType nil or wrong.</summary>
    procedure Patch_By_Name_Sets_Return_Type_And_Keeps_Parameters;
    /// <summary>Proves the attribute route reaches the same result.</summary>
    procedure Patch_By_Attribute_Sets_Return_Type;
  end;
  {$M-}

implementation

uses
  System.Rtti,
  System.TypInfo;

/// <summary>Finds one declared method of the subject interface.</summary>
/// <param name="AContext">Context that owns the returned method.</param>
/// <param name="AName">Method name.</param>
/// <returns>The method, or nil when it is not declared.</returns>
function FindSubjectMethod( const AContext : TRttiContext; const AName : string ) : TRttiMethod;
begin
  Result := nil;
  for var LMethod in AContext.GetType( TypeInfo( IReturnTypePatchSubject ) ).GetDeclaredMethods do
  begin
    if LMethod.Name = AName then
    begin
      Exit( LMethod );
    end;
  end;
end;

procedure TReturnTypePatchTests.Untouched_Method_Has_No_Return_Type;
begin
  var LContext := TRttiContext.Create;
  try
    var LMethod := FindSubjectMethod( LContext, 'Untouched' );
    Assert.IsNotNull( LMethod, 'Untouched not found' );
    Assert.IsNull( LMethod.ReturnType, 'The compiler now emits type information for a gapped enumeration' );
  finally
    LContext.Free;
  end;
end;

procedure TReturnTypePatchTests.Patch_By_Name_Sets_Return_Type_And_Keeps_Parameters;
begin
  PatchMethodReturnType( TypeInfo( IReturnTypePatchSubject ), 'ByName', TypeInfo( Integer ) );
  var LContext := TRttiContext.Create;
  try
    var LMethod := FindSubjectMethod( LContext, 'ByName' );
    Assert.IsNotNull( LMethod, 'ByName not found' );
    Assert.IsNotNull( LMethod.ReturnType, 'Patch left the return type nil' );
    Assert.IsTrue( LMethod.ReturnType.Handle = TypeInfo( Integer ), 'Return type is not the patched type' );
    var LParams := LMethod.GetParameters;
    Assert.AreEqual<Integer>( 2, Length( LParams ) );
    Assert.AreEqual( 'AName', LParams[0].Name );
    Assert.AreEqual( 'AValue', LParams[1].Name );
    Assert.IsTrue( LParams[1].ParamType.Handle = TypeInfo( Integer ), 'Parameter type was disturbed' );
    Assert.IsNull( FindSubjectMethod( LContext, 'Untouched' ).ReturnType, 'Patch reached a method it was not asked to' );
  finally
    LContext.Free;
  end;
end;

procedure TReturnTypePatchTests.Patch_By_Attribute_Sets_Return_Type;
begin
  PatchMethodReturnType( TypeInfo( IReturnTypePatchSubject ) );
  var LContext := TRttiContext.Create;
  try
    var LMethod := FindSubjectMethod( LContext, 'ByAttribute' );
    Assert.IsNotNull( LMethod, 'ByAttribute not found' );
    Assert.IsNotNull( LMethod.ReturnType, 'Patch left the return type nil' );
    Assert.IsTrue( LMethod.ReturnType.Handle = TypeInfo( Integer ), 'Return type is not the patched type' );
  finally
    LContext.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture( TReturnTypePatchTests );

end.
