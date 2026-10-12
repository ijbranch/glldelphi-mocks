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

unit Delphi.Mocks.AutoMock;

interface

uses
  System.TypInfo,
  System.Generics.Collections,
  Delphi.Mocks,
  Delphi.Mocks.WeakReference;

type
  /// <summary>The auto mocker behind TAutoMockContainer: it keeps every mock it hands out alive for the container's
  /// lifetime. The mocks hold it only weakly, so the container and its mocks are all freed together.</summary>
  TAutoMock = class(TWeakReferencedObject, IAutoMock)
  private
    /// <summary>The mocks the container owns.</summary>
    FMocks : TList<IProxy>;
  public
    /// <summary>Creates and keeps a mock of an interface.</summary>
    /// <param name="ATypeInfo">The interface type.</param>
    /// <returns>The mock's proxy.</returns>
    /// <exception cref="EMockException">The type is not an interface.</exception>
    /// <exception cref="EMockNoRTTIException">The interface has no RTTI.</exception>
    function Mock(const ATypeInfo : PTypeInfo) : IProxy;
    /// <summary>Keeps a mock created elsewhere for the container's lifetime.</summary>
    /// <param name="ATypeName">The mocked type's name; not used.</param>
    /// <param name="AMock">The mock's proxy.</param>
    procedure Add(const ATypeName : string; const AMock: IProxy);
    /// <summary>Creates an empty auto mocker.</summary>
    constructor Create;
    /// <summary>Releases every mock.</summary>
    destructor Destroy; override;
  end;

implementation

uses
  Delphi.Mocks.Validation,
  Delphi.Mocks.Proxy.TypeInfo;

{ TAutoMock }

procedure TAutoMock.Add(const ATypeName : string; const AMock: IProxy);
begin
  FMocks.Add(AMock);
end;

constructor TAutoMock.Create;
begin
  inherited Create;
  FMocks := TList<IProxy>.Create;
end;

destructor TAutoMock.Destroy;
var
  I: Integer;
begin
  for I := 0 to FMocks.Count - 1 do
    FMocks[I] := nil;

  FMocks.Clear;
  FMocks.Free;

  inherited;
end;

function TAutoMock.Mock(const ATypeInfo : PTypeInfo) : IProxy;
var
  proxy: IProxy;
  proxyAsType: IProxy;
begin
  //Only interfaces: the type-info proxy has no instance to give a class, so a class got as far
  //as ProxyFromType and failed there with a misleading "no proxy" error.
  if ATypeInfo.Kind <> tkInterface then
    raise EMockException.Create(ATypeInfo.NameStr + ' is not an interface. Auto mocking supports interfaces only');

  //Raise exceptions if the mock doesn't meet the requirements.
  TMocksValidation.CheckMockType(ATypeInfo);

  //We create new mocks using ourself as the auto mocking reference
  proxy := TProxy.Create(ATypeInfo, Self, false);
  proxyAsType := proxy.ProxyFromType(ATypeInfo);

  FMocks.Add(proxy);

  //Push the proxy into the result we are returning. Every TProxy implements IProxy, so failing
  //here means an internal error rather than a user mistake.
  if proxyAsType.QueryInterface(GetTypeData(TypeInfo(IProxy)).Guid, result) <> 0 then
    raise EMockNoProxyException.Create('Error casting to interface ' + ATypeInfo.NameStr + ' , proxy does not appear to implement IProxy');
end;

end.
