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

unit Delphi.Mocks.Examples.Factory;

interface

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  Delphi.Mocks;

type
  {$M+}
  /// <summary>Opens files and writes lines to them.</summary>
  IFileService = interface
    ['{3BDAC049-F291-46CB-95A8-B177E3485752}']
    /// <summary>Opens a file for appending.</summary>
    /// <param name="AFilename">The file.</param>
    /// <returns>A handle, or 0 on failure.</returns>
    function OpenForAppend(const AFilename : string) : THandle;
    /// <summary>Writes a line.</summary>
    /// <param name="AHandle">The file's handle.</param>
    /// <param name="ALine">The line.</param>
    /// <returns>True on success.</returns>
    function WriteLineTo(const AHandle : THandle; const ALine : string) : boolean;
  end;

  /// <summary>Application-wide services.</summary>
  IApplicationInfo = interface
    ['{43C0AE45-F57F-4620-A902-35CEAB370BC1}']
    /// <summary>Getter of FileService.</summary>
    /// <returns>The file service.</returns>
    function GetFileService : IFileService;
    /// <summary>The file service.</summary>
    property FileService : IFileService read GetFileService;
  end;

  /// <summary>One line of a log.</summary>
  ILogLine = interface
    ['{B230FBB5-EE90-4208-90A4-FF09274BD767}']
    /// <summary>The line, formatted for output.</summary>
    /// <returns>The text.</returns>
    function FormattedLine : string;
  end;

  /// <summary>A list of log lines.</summary>
  ILogLines = interface
    ['{0CAF05DA-6828-4651-8431-F4E6815AF1C0}']
    /// <summary>Getter of Count.</summary>
    /// <returns>The number of lines.</returns>
    function GetCount : Cardinal;
    /// <summary>Getter of Line.</summary>
    /// <param name="ALine">The zero-based index.</param>
    /// <returns>The line.</returns>
    function GetLine(const ALine: Cardinal) : ILogLine;

    /// <summary>The lines, by zero-based index.</summary>
    property Line[const ALine : Cardinal] : ILogLine read GetLine;
    /// <summary>The number of lines.</summary>
    property Count : Cardinal read GetCount;
  end;

  /// <summary>Receives and keeps log messages.</summary>
  ILogReceiver = interface
    ['{0EE8E9EC-0B2E-4052-827D-5EAF26AB08BC}']
    /// <summary>Returns the messages above a level.</summary>
    /// <param name="ALogLevel">The level they must exceed.</param>
    /// <returns>The lines.</returns>
    function GetLogsAbove(const ALogLevel : Integer) : ILogLines;
    /// <summary>Logs a message.</summary>
    /// <param name="AMessage">The message.</param>
    /// <param name="ALogLevel">Its level.</param>
    /// <returns>True when logged.</returns>
    function Log(const AMessage: string; const ALogLevel : Integer) : boolean;
  end;

  /// <summary>A message for a channel.</summary>
  IMessage = interface
    ['{9955A5F2-3BC3-43DA-81FC-AD16E02BC93F}']
  end;

  /// <summary>Sends messages.</summary>
  IMessageChannel = interface
    ['{B2F9B8B0-93DD-4886-8141-CD043C32A9F1}']
    /// <summary>Sends a message.</summary>
    /// <param name="AMessage">The message.</param>
    /// <returns>True when sent.</returns>
    function SendMessage(const AMessage : IMessage) : boolean;
  end;

  /// <summary>The services an application component is given.</summary>
  ICoreService = interface
    ['{48584DC8-C425-4F6C-8FC5-438F04A90052}']
    /// <summary>Getter of LogReciever.</summary>
    /// <returns>The log receiver.</returns>
    function GetLogReciever : ILogReceiver;
    /// <summary>Getter of Application.</summary>
    /// <returns>The application information.</returns>
    function GetApplication : IApplicationInfo;
    /// <summary>Getter of AppMessageChannel.</summary>
    /// <returns>The message channel.</returns>
    function GetAppMessageChannel : IMessageChannel;

    /// <summary>The application information.</summary>
    property Application : IApplicationInfo read GetApplication;
    /// <summary>The log receiver.</summary>
    property LogReciever : ILogReceiver read GetLogReciever;
    /// <summary>The message channel.</summary>
    property AppMessageChannel : IMessageChannel read GetAppMessageChannel;
  end;

  /// <summary>Exports a log to a file.</summary>
  ILogExporter = interface
    ['{037C6F9F-CA6A-4DE9-863C-0E3DC265B49B}']
    /// <summary>Writes the log's lines at or above a level to a file.</summary>
    /// <param name="AMinLogLevel">The lowest level exported.</param>
    /// <param name="AFilename">The file.</param>
    /// <returns>0 on success.</returns>
    function ExportLog(const AMinLogLevel : Integer; const AFilename: TFilename) : integer;
  end;

  /// <summary>The code under test: it uses several services to export a log.</summary>
  TLogExporter = class(TInterfacedObject, ILogExporter)
  private
    /// <summary>The log receiver.</summary>
    FLogReciever : ILogReceiver;
    /// <summary>The application information.</summary>
    FApplication : IApplicationInfo;
  public
    /// <summary>Creates the exporter.</summary>
    /// <param name="AServices">The services it uses.</param>
    constructor Create(const AServices : ICoreService);
    /// <summary>Releases the services.</summary>
    destructor Destroy; override;
    /// <summary>Writes the log's lines at or above a level to a file.</summary>
    /// <param name="AMinLogLevel">The lowest level exported.</param>
    /// <param name="AFilename">The file.</param>
    /// <returns>0 on success.</returns>
    /// <exception cref="Exception">The file service gave no handle.</exception>
    function ExportLog(const AMinLogLevel : Integer; const AFilename: TFilename) : integer;
  end;
  {$M-}

  {$M+}
  /// <summary>Demonstrates building a web of mocks with TAutoMockContainer, and creating a T from its type info.
  /// </summary>
  TExample_MockFactoryTests = class
  published
    /// <summary>Mocks every service TLogExporter needs, exports a two-line log, and verifies both lines were
    /// written.</summary>
    /// <exception cref="EMockVerificationException">The lines were not written as expected.</exception>
    procedure Implement_Multiple_Interfaces;
    /// <summary>Creates a class instance and an interface mock from type info alone.</summary>
    /// <exception cref="Exception">The demonstration did not behave as described.</exception>
    procedure Create_T_From_TypeInfo;
  end;
  {$M-}

  /// <summary>Something created from type info.</summary>
  IFakeGeneric = interface
    ['{682057B0-E265-45F1-ABF7-12A25683AF63}']
    /// <summary>Returns what was created.</summary>
    /// <returns>The instance, or an empty value when nothing could be created.</returns>
    function Value : TValue;
  end;

  /// <summary>Creates an instance of a type from its type info: a class through its parameterless constructor,
  /// an interface as a mock. It owns what it creates.</summary>
  TFakeGeneric = class(TInterfacedObject, IFakeGeneric)
  private
    /// <summary>The created instance.</summary>
    FValue : TValue;
    /// <summary>The container that keeps an interface mock alive.</summary>
    FContainer : TAutoMockContainer;
  public
    /// <summary>Creates the instance.</summary>
    /// <param name="ATypeInfo">The type.</param>
    constructor Create(const ATypeInfo : PTypeInfo);
    /// <summary>Frees a created object; an interface mock goes with the container.</summary>
    destructor Destroy; override;

    /// <summary>Returns what was created.</summary>
    /// <returns>The instance, or an empty value when nothing could be created.</returns>
    function Value : TValue;
  end;

  /// <summary>A typed view of TFakeGeneric.</summary>
  IFakeGeneric<T> = interface
    ['{87853316-A14D-4BC6-9124-D947662243F0}']
    /// <summary>Returns what was created.</summary>
    /// <returns>The instance.</returns>
    function Value : T;
  end;

  /// <summary>A typed view of TFakeGeneric.</summary>
  TFakeGeneric<T> = class(TInterfacedObject, IFakeGeneric<T>)
  private
    /// <summary>The untyped creator.</summary>
    FFakeGeneric : IFakeGeneric;
  public
    /// <summary>Creates an instance of T.</summary>
    constructor Create;
    /// <summary>Releases the creator, and with it the instance.</summary>
    destructor Destroy; override;

    /// <summary>Returns the instance.</summary>
    /// <returns>The instance.</returns>
    /// <exception cref="EInvalidCast">No instance could be created.</exception>
    function Value : T;
  end;

implementation

{ TLogExporter }

constructor TLogExporter.Create(const AServices: ICoreService);
begin
  inherited Create;

  FLogReciever := AServices.LogReciever;
  FApplication := AServices.Application;
end;

destructor TLogExporter.Destroy;
begin
  FLogReciever := nil;
  FApplication := nil;

  inherited;
end;

function TLogExporter.ExportLog(const AMinLogLevel : Integer; const AFilename: TFilename) : integer;
var
  fileService : IFileService;
  fileHandle: THandle;
  logs: ILogLines;
  iLine: Integer;
begin
  //Very simplistic ExportLog function which uses a number of other services to
  //get its job done. The logic is simplistic, but the implementation over uses
  //services to show the power of AutoMocking, and the Factory.

  fileService := FApplication.FileService;

  //Create or open requested file.
  fileHandle := fileService.OpenForAppend(AFilename);

  //Make sure the got a valid handle from the file serice.
  if fileHandle = 0 then
    raise Exception.CreateFmt('The fileservice failed to return a handle for [%s]', [AFilename]);

  //Get the log from the log receiver for the passed in min log level.
  logs := FLogReciever.GetLogsAbove(AMinLogLevel - 1);

  //Write each line out with the formatting from the log.
  for iLine := 0 to Integer(logs.Count) - 1 do
    fileService.WriteLineTo(fileHandle, logs.Line[iLine].FormattedLine);

  result := 0;
end;

{ TExample_MockFactoryTests }

procedure TExample_MockFactoryTests.Create_T_From_TypeInfo;
var
  fakeExporter : IFakeGeneric<TLogExporter>;
  fakeLine : IFakeGeneric<ILogLine>;
begin
  fakeExporter := TFakeGeneric<TLogExporter>.Create;
  if fakeExporter.Value.ClassName <> 'TLogExporter' then
    raise Exception.Create('Factory: the created object is not a TLogExporter');

  fakeLine := TFakeGeneric<ILogLine>.Create;
  if fakeLine.Value = nil then
    raise Exception.Create('Factory: no ILogLine mock was created');

  WriteLn('Factory: created a ' + fakeExporter.Value.ClassName + ' and an ILogLine mock from type info.');
end;

procedure TExample_MockFactoryTests.Implement_Multiple_Interfaces;
var
  container : TAutoMockContainer;
  mockCoreService : TMock<ICoreService>;
  mockApplication : TMock<IApplicationInfo>;
  mockFileService : TMock<IFileService>;
  mockLogReceiver : TMock<ILogReceiver>;
  mockLogLines : TMock<ILogLines>;
  mockLogLine : TMock<ILogLine>;
  logExporterSUT : ILogExporter;
begin
  //CREATE - every service TLogExporter needs, from one container that keeps them alive.
  container := TAutoMockContainer.Create;
  mockCoreService := container.Mock<ICoreService>;
  mockApplication := container.Mock<IApplicationInfo>;
  mockFileService := container.Mock<IFileService>;
  mockLogReceiver := container.Mock<ILogReceiver>;
  mockLogLines := container.Mock<ILogLines>;
  mockLogLine := container.Mock<ILogLine>;

  //SETUP - wire the services together, and describe a two-line log.
  mockCoreService.Setup.WillReturn(TValue.From<IApplicationInfo>(mockApplication.Instance)).When.GetApplication;
  mockCoreService.Setup.WillReturn(TValue.From<ILogReceiver>(mockLogReceiver.Instance)).When.GetLogReciever;
  mockApplication.Setup.WillReturn(TValue.From<IFileService>(mockFileService.Instance)).When.GetFileService;
  mockFileService.Setup.WillReturn(TValue.From<THandle>(42)).When.OpenForAppend('export.log');
  mockFileService.Setup.WillReturn(True).When.WriteLineTo(It0.IsAny<THandle>, It1.IsAny<string>);
  mockLogReceiver.Setup.WillReturn(TValue.From<ILogLines>(mockLogLines.Instance)).When.GetLogsAbove(1);
  mockLogLines.Setup.WillReturn(TValue.From<Cardinal>(2)).When.GetCount;
  mockLogLines.Setup.WillReturn(TValue.From<ILogLine>(mockLogLine.Instance)).When.GetLine(It0.IsAny<Cardinal>);
  mockLogLine.Setup.WillReturn('a log line').When.FormattedLine;

  //EXPECT - both lines written to the handle the file service gave.
  mockFileService.Setup.Expect.Exactly(2).When.WriteLineTo(42, 'a log line');

  //TEST - export everything at level 2 and above.
  logExporterSUT := TLogExporter.Create(mockCoreService);
  logExporterSUT.ExportLog(2, 'export.log');

  //VERIFY
  mockFileService.Verify('ExportLog should write each log line once');
  WriteLn('Factory: ExportLog wrote both log lines through the mocked services.');
end;

{ TFakeGeneric }

constructor TFakeGeneric.Create(const ATypeInfo: PTypeInfo);
var
  ctx: TRttiContext;
  rType: TRttiType;
  AMethCreate: TRttiMethod;
  intf: IInterface;
begin
  ctx := TRttiContext.Create;
  rType := ctx.GetType(ATypeInfo);

  //An interface has no constructor; FValue stayed empty and Value failed. Mock it instead.
  if ATypeInfo^.Kind = tkInterface then
  begin
    FContainer := TAutoMockContainer.Create;
    intf := FContainer.Mock(ATypeInfo).ProxyInterface;
    TValue.Make(@intf, ATypeInfo, FValue);
    Exit;
  end;

  for AMethCreate in rType.GetMethods do
  begin
    //A parameterless constructor only. GetMethods lists inherited methods too, so for a class
    //whose own constructor takes parameters this is TObject.Create, which bypasses it.
    if (AMethCreate.IsConstructor) and (Length(AMethCreate.GetParameters) = 0) then
    begin
      FValue := AMethCreate.Invoke(rType.AsInstance.MetaclassType, []);
      Exit;
    end;
  end;
end;

destructor TFakeGeneric.Destroy;
begin
  //The object was created here and nothing else owns it; it used to leak.
  if FValue.IsObject then
    FValue.AsObject.Free;
  FValue := TValue.Empty;
  inherited;
end;

function TFakeGeneric.Value: TValue;
begin
  Result := FValue;
end;

{ TFakeGeneric<T> }

constructor TFakeGeneric<T>.Create;
begin
  FFakeGeneric := TFakeGeneric.Create(TypeInfo(T));
end;

destructor TFakeGeneric<T>.Destroy;
begin
  FFakeGeneric := nil;
  inherited;
end;

function TFakeGeneric<T>.Value: T;
begin
  Result := FFakeGeneric.Value.AsType<T>;
end;


end.
