using System.Collections.Generic;

namespace VRMate.modules.library_manager;

public class Looks
{
    public int ID { get; init; }
    public string Archive  { get; init; }
    public string PersonJSON  { get; init; }
    
    public string Title  { get; init; }
    public string SceneFile  { get; init; }
    public string PreviewImageFile  { get; init; }
}

public class LooksList : List<Looks>
{
    
}