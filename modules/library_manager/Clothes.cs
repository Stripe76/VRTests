using Godot;
using Godot.Collections;

using System.IO;
using System.Text.Json;

namespace VRMate.modules.library_manager;

public class Clothes : VAMObjects
{
	protected override void LoadMeshData( BinaryReader reader,Dictionary data )
	{
		SkipStrings( reader,8 );

		var verticesCount = reader.ReadInt32( );
		var vertices = new Vector3[verticesCount];

		if( verticesCount is < 0 or > 65535 )
		{
			GD.PrintErr( "LoadClothMeshData: too many vertices" );
			return;
		}
		for( int i = 0; i < verticesCount; i++ )
		{
			vertices[i] = new Vector3( -reader.ReadSingle( ),reader.ReadSingle( ),reader.ReadSingle( ) );
		}
		data.Add( "vertices",vertices );

		SkipStrings( reader );

		var indicesCount = reader.ReadInt32( );
		if( indicesCount is < 0 or > 65535 )
		{
			GD.PrintErr( "LoadClothMeshData: too many indices" );
			return;
		}
		var indices = new int[indicesCount * 6];
		for( int i = 0; i < indicesCount; i++ )
		{
			var material = reader.ReadInt32( );
			var idxs = reader.ReadInt32( );

			var c = reader.ReadInt32( );
			var d = reader.ReadInt32( );
			var e = reader.ReadInt32( );
			int f = 0;

			if( idxs == 4 )
				f = reader.ReadInt32( );
			if( idxs == 5 )
				reader.ReadInt32( );

			var start = i * 6;
			indices[start] = c;
			indices[start + 1] = e;
			indices[start + 2] = d;

			if( idxs == 4 )
			{
				indices[start + 3] = f;
				indices[start + 4] = e;
				indices[start + 5] = c;
			}
		}
		for( int i = 0; i < indicesCount; i++ )
		{
			reader.ReadInt32( );
			var idxs = reader.ReadInt32( );

			reader.ReadInt32( );
			reader.ReadInt32( );
			reader.ReadInt32( );

			if( idxs == 4 )
				reader.ReadInt32( );
			if( idxs == 5 )
				reader.ReadInt32( );
		}
		data.Add( "indices",indices );

		var uvsCount = reader.ReadInt32( );
		if( uvsCount is < 0 or > 65535 )
		{
			GD.PrintErr( "LoadClothMeshData: too many uvs" );
			return;
		}
		var uvs = new Vector2[indicesCount * 6];
		for( int i = 0; i < verticesCount; i++ )
		{
			uvs[i] = new Vector2( reader.ReadSingle( ),1 - reader.ReadSingle( ) );
		}
		for( int i = verticesCount; i < uvsCount; i++ )
		{
			uvs[i] = new Vector2( reader.ReadSingle( ),1 - reader.ReadSingle( ) );
		}
		data.Add( "uvs",uvs );

		var count = reader.ReadInt32( );
		for( int i = 0; i < count; i++ )
		{
			reader.ReadInt32( );
			reader.ReadInt32( );
			reader.ReadInt32( );
		}
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
	}
	protected override void LoadMaterials( JsonElement root,string folder,Dictionary data )
	{
		//GD.Print( "JsonDocument" );
		if( root.TryGetProperty( "storables",out JsonElement storables ) )
		{
			//GD.Print( "storables" );
			foreach( JsonElement storable in storables.EnumerateArray( ) )
			{
				//GD.Print( "storable" );
				if( storable.TryGetProperty( "hideMaterial",out JsonElement hideMaterial ) )
				{
					if( storable.TryGetProperty( "id",out JsonElement id ) )
					{
						var material = new Dictionary( );

						if( storable.TryGetProperty( "customTexture_MainTex",out JsonElement mainTex ) )
							material.Add( "main_tex",folder + mainTex );

						/*
						"customTexture_MainTex"
						"customTexture_SpecTex"
						"customTexture_GlossTex"
						"customTexture_AlphaTex"
						"customTexture_BumpMap"
						"customTexture_DecalTex"
						*/
						data.Add( id.ToString( ),material );
					}
				}
			}
		}
	}
}
