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
            GD.PushWarning( "LoadHairMeshData mesh count > 1" );

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
                    vertices[v] = new Vector3( -reader.ReadSingle( ),reader.ReadSingle( ),reader.ReadSingle( ) );
                }
                strands.Add( vertices );
            }
        }
        data.Add( "strands",strands );
    }
    protected override void LoadMaterials( JsonElement root,string folder,string UID,Dictionary data )
    {
	    if( root.TryGetProperty( "storables",out JsonElement storables ) )
	    {
		    foreach( JsonElement storable in storables.EnumerateArray( ) )
		    {
			    if( storable.TryGetProperty( "rootColor",out JsonElement rootColor ) )
			    {
				    if( storable.TryGetProperty( "id",out JsonElement id ) )
				    {
					    var material = new Dictionary( );

					    {
						    if( rootColor.TryGetProperty( "h",out JsonElement h ) &&
						        rootColor.TryGetProperty( "s",out JsonElement s ) &&
						        rootColor.TryGetProperty( "v",out JsonElement v ) )
						    {
							    material.Add( "root_color",Color.FromHsv( float.Parse( h.ToString( ) ),float.Parse( s.ToString( ) ),float.Parse( v.ToString( ) ) ) );
						    }
					    }
					    if( storable.TryGetProperty( "tipColor",out JsonElement tipColor ) )
					    {
						    if( tipColor.TryGetProperty( "h",out JsonElement h ) &&
						        tipColor.TryGetProperty( "s",out JsonElement s ) &&
						        tipColor.TryGetProperty( "v",out JsonElement v ) )
						    {
							    material.Add( "tip_color",Color.FromHsv( float.Parse( h.ToString( ) ),float.Parse( s.ToString( ) ),float.Parse( v.ToString( ) ) ) );
						    }
					    }
					    data.Add( id.ToString( ).Replace( UID,"" ),material );
				    }
			    }
		    }
	    }
    }
}
