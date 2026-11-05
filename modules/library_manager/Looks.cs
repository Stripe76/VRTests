using System.IO;
using System.Text.Json;
using Godot.Collections;

public class Looks : VAMObjects
{
    public Looks( ) : base( "" )
    {
        
    }
    
    protected override void LoadMeshData( BinaryReader reader,Dictionary data )
    {
        throw new System.NotImplementedException( );
    }
    protected override void LoadMaterials( JsonElement root,string folder,string UID,Dictionary data )
    {
        throw new System.NotImplementedException( );
    }
}
