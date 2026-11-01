using Godot;
using Godot.Collections;

using System.IO;
using System.Text.Json;

namespace VRMate.modules.library_manager;

public class Clothes : VAMObjects
{
	public Clothes( )
	{
		_debug_file = "_current_cloth";
	}
	
	protected override void LoadMeshData( BinaryReader reader,Dictionary data )
	{
		SkipStrings( reader,8 );

		LoadVertices( reader,data,"vertices" );
		
		SkipStrings( reader );

		LoadSurfaces( reader,data,"surfaces" );

		int verticesCount = ((Vector3[])data["vertices"]).Length; 
		LoadUVs( reader,verticesCount,data,"uvs" );

		SkipInts( reader,3 );

		SkipStrings( reader,5 );

		var skinsCount = reader.ReadInt32( );
		var skinIndices = new int[skinsCount * 4];
		for( int i = 0; i < skinsCount; i++ )
		{
			var start = i * 4;
			skinIndices[start] = reader.ReadInt32( );
			skinIndices[start + 1] = reader.ReadInt32( );
			skinIndices[start + 2] = reader.ReadInt32( );
			skinIndices[start + 3] = reader.ReadInt32( );

			reader.ReadSingle( );
			reader.ReadSingle( );
			reader.ReadSingle( );
			reader.ReadSingle( );

			reader.ReadSingle( );
			reader.ReadSingle( );
		}
		data.Add( "skin_indices",skinIndices );

		var materialsID = new Array( );
		int surfacesCount = ((Array)data["surfaces"]).Count;
		for( int i = 0; i < surfacesCount; )
		{
			SkipStrings( reader,2 );

			string material = LoadString( reader )[1..];

			int count = reader.ReadInt32( ); // Boh
			for( int n = 0; n < count; n++ )
				materialsID.Add( material );
			reader.ReadInt32( ); // Index

			i += count;
		}
		data.Add( "materials_id",materialsID );
	}
	protected override void LoadMaterials( JsonElement root,string folder,string UID,Dictionary data )
	{
		if( root.TryGetProperty( "storables",out JsonElement storables ) )
		{
			foreach( JsonElement storable in storables.EnumerateArray( ) )
			{
				if( storable.TryGetProperty( "customTexture_MainTex",out JsonElement mainTex ) )
				{
					if( storable.TryGetProperty( "id",out JsonElement id ) )
					{
						var material = new Dictionary( );

						material.Add( "main_texture",folder + mainTex );
						
						if( storable.TryGetProperty( "customTexture_SpecTex",out JsonElement specText ) )
							material.Add( "specular_texture",folder + specText );
						if( storable.TryGetProperty( "customTexture_GlossTex",out JsonElement glossTex ) )
							material.Add( "gloss_texture",folder + glossTex );
						if( storable.TryGetProperty( "customTexture_AlphaTex",out JsonElement alphaTex ) )
							material.Add( "alpha_texture",folder + alphaTex );
						if( storable.TryGetProperty( "customTexture_BumpMap",out JsonElement bumpMap ) )
							material.Add( "bump_map_texture",folder + bumpMap );
						if( storable.TryGetProperty( "customTexture_DecalTex",out JsonElement decalTex ) )
							material.Add( "decal_texture",folder + decalTex );

						if( storable.TryGetProperty( "Diffuse Color",out JsonElement diffuseColor ) &&
						    diffuseColor.TryGetProperty( "h",out JsonElement h ) &&
						    diffuseColor.TryGetProperty( "s",out JsonElement s ) &&
						    diffuseColor.TryGetProperty( "v",out JsonElement v ) )
						{
							material.Add( "diffuse_color",Color.FromHsv( float.Parse( h.ToString( ) ),float.Parse( s.ToString( ) ),float.Parse( v.ToString( ) ) ) );
						}
						if( storable.TryGetProperty( "customTexture1TileX",out JsonElement tex1TileX ) )
							material.Add( "tile_x",float.Parse( tex1TileX.ToString(  ) ) );
						if( storable.TryGetProperty( "customTexture1TileY",out JsonElement tex1TileY ) )
							material.Add( "tile_y",float.Parse( tex1TileY.ToString(  ) ) );
						/*
						"customTexture_MainTex"
						"customTexture_SpecTex"
						"customTexture_GlossTex"
						"customTexture_AlphaTex"
						"customTexture_BumpMap"
						"customTexture_DecalTex"
				        "customTexture1TileX" : "15",
						"customTexture1TileY" : "15",
						*/
					    data.Add( id.ToString( ).Replace( UID,"" ),material );
					}
				}
			}
		}
	}
}
