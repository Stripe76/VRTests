using Godot;
using Godot.Collections;

using System.IO;
using System.Text.Json;

public class Hairs : VAMObjects
{
    protected override void LoadMeshData( BinaryReader reader,Dictionary data )
    {
        SkipStrings( reader,2 );

        var meshCount = reader.ReadByte( );

        if( meshCount != 1 )
            GD.PushWarning( "LoadHairMeshData meash count > 1" );

        SkipStrings( reader,3 );

        reader.ReadInt32( );
        reader.ReadInt32( );
        reader.ReadByte( );

        var dataCount = reader.ReadInt32( );
        for( int i = 0; i < dataCount; i++ )
            reader.ReadByte( );

        var strandsCount = reader.ReadInt32( );
        var strands = new Array( );
        for( int i = 0; i < strandsCount; i++ )
        {
            var strandID = reader.ReadInt32( );
            var verticesCount = reader.ReadInt32( );
            var vertices = new Vector3[verticesCount];

            if( verticesCount is < 0 or > 255 )
            {
                GD.PrintErr( "LoadHairMeshData: too many vertices" );
                return;
            }
            if( verticesCount > 0 )
            {
                for( int v = 0; v < verticesCount; v++ )
                {
                    vertices[v] = new Vector3( reader.ReadSingle( ),reader.ReadSingle( ),reader.ReadSingle( ) );
                }
                strands.Add( vertices );
            }
        }
        data.Add( "strands",strands );
    }
    protected override void LoadMaterials( JsonElement root,string folder,string UID,Dictionary data )
    {
    }
}
