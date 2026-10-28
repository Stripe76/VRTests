using System.Collections.Generic;

namespace VRMate.modules.library_manager;

public class Cloth
{
    public int ID { get; init; }
    public string Archive  { get; init; }
    public string PersonJSON  { get; init; }
    
    public string Title  { get; init; }
    public string Folder  { get; init; }
    public string ClothFile  { get; init; }
    public string PreviewImageFile  { get; init; }
}

public class ClothList : List<Cloth>
{
    
}