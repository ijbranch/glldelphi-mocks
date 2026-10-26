unit Delphi.Mocks.Example.ProjectSaveCheckVisitor;

interface

type
  {$M+}
  IVisitor = interface;

  /// <summary>Something a visitor can visit.</summary>
  IElement = interface
    ['{A2F4744E-7ED3-4DE3-B1E4-5D6C256ACBF0}']
    /// <summary>Accepts a visitor.</summary>
    /// <param name="AVisitor">The visitor.</param>
    procedure Accept(const AVisitor : IVisitor);
  end;

  /// <summary>Visits elements.</summary>
  IVisitor = interface
    ['{0D150F9C-909A-413E-B29E-4B869C6BC309}']
    /// <summary>Visits an element.</summary>
    /// <param name="AElement">The element.</param>
    procedure Visit(const AElement : IElement);
  end;

  /// <summary>A project that can be saved.</summary>
  IProject = interface
    ['{807AF964-E937-4A8A-A3D2-34074EF66EE8}']
    /// <summary>Saves the project.</summary>
    procedure Save;
    /// <summary>Whether the project has unsaved changes.</summary>
    /// <returns>True when it has.</returns>
    function IsDirty : boolean;
  end;

  /// <summary>An element that is not a project.</summary>
  TElement = class(TInterfacedObject, IElement)
  public
    /// <summary>Accepts a visitor; does nothing.</summary>
    /// <param name="AVisitor">The visitor.</param>
    procedure Accept(const AVisitor : IVisitor);
  end;

  /// <summary>An element that is a project, always dirty.</summary>
  TProject = class(TInterfacedObject, IProject, IElement)
  protected
    /// <summary>Always True.</summary>
    /// <returns>True.</returns>
    function IsDirty : boolean;
    /// <summary>Has the visitor visit this project.</summary>
    /// <param name="AVisitor">The visitor.</param>
    procedure Accept(const AVisitor : IVisitor);
  public
    /// <summary>Does nothing.</summary>
    procedure Save;
  end;

  /// <summary>The code under test: a visitor that saves a visited project if it is dirty.</summary>
  TProjectSaveCheck = class(TInterfacedObject, IVisitor)
  public
    /// <summary>Saves the element if it is a dirty project.</summary>
    /// <param name="AElement">The element.</param>
    /// <exception cref="Exception">The element is not an IProject.</exception>
    procedure Visit(const AElement : IElement);
  end;
  {$M-}

implementation

uses
  System.SysUtils;

{ TProjectSaveCheckVisitor }

procedure TProjectSaveCheck.Visit(const AElement: IElement);
var
  project : IProject;
begin
  if not Supports(AElement, IProject, project) then
    raise Exception.Create('Element passed to Visit was not a IProject.');

  if project.IsDirty then
    project.Save;
end;

{ TProject }

procedure TProject.Accept(const AVisitor: IVisitor);
begin
  AVisitor.Visit(Self);
end;

function TProject.IsDirty: boolean;
begin
  Result := True;
end;

procedure TProject.Save;
begin
end;

{ TElement }

procedure TElement.Accept(const AVisitor: IVisitor);
begin

end;


end.
