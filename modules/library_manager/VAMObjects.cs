#nullable enable
using Godot;
using Godot.Collections;

using System;
using System.IO;
using System.IO.Compression;
using System.Collections.Generic;
using System.Text.Json;
using Array = Godot.Collections.Array;

public abstract class VAMObjects
{
    private readonly VAMItemList _items = [];
    private readonly SortedList<string,List<int>> _filters = [];
    private readonly VAMCategoryManager _categoryManager;
        
    protected string? _debug_file = null;

    protected VAMObjects( string categoriesSubFolder )
    {
        _categoryManager = new VAMCategoryManager( categoriesSubFolder );
        
        _categoryManager.LoadAll( );
    }

    public void AddItem( VAMItem item )
    {
        _items.Add( item );
        
    }
    public void AddItemToFilter( string filter,int itemID )
    {
        if( string.IsNullOrEmpty( filter ) )
            return;
        if( !_filters.ContainsKey( filter ))
            _filters.Add( filter,[] );
        var filterItems = _filters[filter];
        if( !filterItems.Contains( itemID  ))
            filterItems.Add( itemID );

        SortedList<string,List<string>> categories = [];
        foreach( string key in _filters.Keys )
        {
            var ids = _filters[key];

            foreach( var id in ids )
            {
                string uid = _items[id].UID;

                categories.TryAdd( key,[] );
                categories[key].Add( uid );
            }
        }
        _categoryManager.SaveAll( categories );
    }
    public void RemoveItemFromFilter( string filter,int itemID )
    {
        if( _filters.TryGetValue( filter,out var ids ) )
        {
            if( ids.Contains( itemID ) )
                ids.Remove( itemID );
        }
    }

    public void AddEntry( string archive,ZipArchiveEntry entry )
    {
        var new_item = new VAMItem( )
        {
            ID = _items.Count,
            UID = GenerateUID( archive,entry ),
            Archive = archive,
            Title = entry.Name.Replace( ".vam","" ),
            Folder = entry.FullName.Replace( entry.Name,"" ),
            BaseFile = entry.FullName,
            BinaryFile = entry.FullName.Replace( ".vam",".vab" ),
            DetailsFile = entry.FullName.Replace( ".vam",".vaj" ),
            PreviewImageFile = entry.FullName.Replace( ".vam",".jpg" ),
        }; 
        _items.Add( new_item );

        List<string> categories = _categoryManager.GetUIDCategories( new_item.UID );
        foreach( var category in categories )
        {
            AddItemToFilter( category,new_item.ID );
        }
    }

    public VAMItem? GetItem( int itemID )
    {
        if( itemID >= 0 && itemID < _items.Count )
            return _items[itemID];
        return null;
    }

    public int GetItemID( string filter,int index )
    {
        if( string.IsNullOrEmpty( filter ))
            return index;
        if( _filters.TryGetValue( filter,out var filterItems ) && index >= 0 && index < filterItems.Count )
            return filterItems[index];
        return -1;
    }
    
    public int GetCount( string filter = "" )
    {
        if( string.IsNullOrEmpty( filter ))
            return _items.Count;
        return _filters.TryGetValue( filter,out var filterItems ) ? filterItems.Count : 0;
    }

    public string GetTitle( int itemID )
    {
        if( itemID >= 0 && itemID < _items.Count )
            return _items[itemID].Title;
        return string.Empty;
    }
    public string GetJSON( int itemID )
    {
        if( itemID >= 0 && itemID < _items.Count )
            return _items[itemID].BaseJSON;
        return string.Empty;
    }

    public Image GetTextureImage( int itemID,string textureFile )
    {
        if( itemID >= 0 && itemID < _items.Count )
        {
            var hair = _items[itemID];
            string archive = hair.Archive;

            return LoadImage( archive,textureFile,true );
        }
        return new Image( );
    }
    public Texture2D GetPreviewImage( int itemID )
    {
        if( itemID >= 0 && itemID < _items.Count )
        {
            var hair = _items[itemID];
            try
            {
                var image = LoadImage( hair.Archive,hair.PreviewImageFile );

                return ImageTexture.CreateFromImage( image );
            }
            catch( Exception e )
            {
                GD.PushError( e.Message );
            }
        }
        return null;
    }

    public Dictionary GetMeshData( int itemID )
    {
        if( itemID >= 0 && itemID < _items.Count )
        {
            var item = _items[itemID];

            string UID = "";
            using( ZipArchive archive = ZipFile.OpenRead( item.Archive ) )
            {
                var entry = archive.GetEntry( item.BaseFile );
                if( entry != null )
                {
                    using( StreamReader reader = new StreamReader( entry.Open( ) ) )
                    {
                        var json = reader.ReadToEnd( );
                        using( JsonDocument doc = JsonDocument.Parse( json,new JsonDocumentOptions( ) { AllowTrailingCommas = true } ) )
                        {
                            var root = doc.RootElement;
                            
                            if( root.TryGetProperty( "uid",out var uid ) )
                                UID = uid.ToString( );
                        }
                    }
                }
            }
            string binaryFile = item.BinaryFile;  
            var data = new Dictionary
            {
                { "meshFile",binaryFile },
                { "meshData",LoadMeshData( item.Archive,binaryFile ) },
                { "materials",LoadMaterials( item.Archive,item.DetailsFile,item.Folder,UID )}
            };
            return data;
        }
        return new Dictionary( );
    }
    
    private Dictionary LoadMeshData( string archiveFile,string filename )
    {
        var data = new Dictionary( );
        try
        {
            GD.Print( filename );
            using( ZipArchive archive = ZipFile.OpenRead( archiveFile ) )
            {
                TraceArchiveFile( archiveFile,filename );

                var entry = archive.GetEntry( filename );
                if( entry != null )
                {
#if DEBUG
                    if( _debug_file != null )
                        entry.ExtractToFile( $"/mnt/data/Projects/Godot/library/{_debug_file}.vab",true );
#endif
                    using( BinaryReader reader = new BinaryReader( entry.Open( ) ) )
                    {
                        LoadMeshData( reader,data );
                    }
                }
            }
        }
        catch( Exception e )
        {
            GD.PushError( e.Message );
        }
        return data;

    }
    private Dictionary LoadMaterials( string archiveFile,string filename,string folder,string UID )
    {
        var data = new Dictionary( );
        using( ZipArchive archive = ZipFile.OpenRead( archiveFile ) )
        {
            var entry = archive.GetEntry( filename );
            if( entry != null )
            {
                using( StreamReader reader = new StreamReader( entry.Open( ) ) )
                {
                    var json = reader.ReadToEnd( );
                    using( JsonDocument doc = JsonDocument.Parse( json,new JsonDocumentOptions( ) { AllowTrailingCommas = true } ) )
                    {
                        LoadMaterials( doc.RootElement,folder,UID,data );
                    }
                }
            }
        }
        return data;
    }

    protected abstract void LoadMeshData( BinaryReader reader,Dictionary data );
    protected abstract void LoadMaterials( JsonElement root,string folder,string UID,Dictionary data );
    
    #region Helpers
    protected string GenerateUID( string archive,ZipArchiveEntry entry )
    {
        var folders = entry.FullName.Split( "/" );
        if( folders.Length > 2 )
            return $"{folders[^2]}:{folders[^1]}".Replace( ".vam","" );
        return string.Empty;;
    }

    protected Image LoadImage( string archiveFile,string filename,bool trace = false )
    {
        var image = new Image( );
        try
        {
            //GD.Print( "archiveFile: " + archiveFile );
            using( ZipArchive archive = ZipFile.OpenRead( archiveFile ) )
            {
                if( trace )
                    TraceArchiveFile( archiveFile,filename );
				
                var entry = archive.GetEntry( filename );
                if( entry != null )
                {
                    //GD.Print( "StreamReader" );
                    using( StreamReader reader = new StreamReader( entry.Open( ) ) )
                    {
                        byte[] data = new byte[entry.Length];

                        //GD.Print( "Legth: " + data.Length );
                        reader.BaseStream.ReadExactly( data,0,(int)entry.Length );

                        if( filename.EndsWith( ".jpg" ) )
                        {
                            //GD.Print( "LoadJpgFromBuffer" );
                            image.LoadJpgFromBuffer( data );
                        }
                        else if( filename.EndsWith( ".png" ))
                        {
                            //GD.Print( "LoadPngFromBuffer" );
                            image.LoadPngFromBuffer( data );
                        }                    }
                }
            }
        }
        catch( Exception e )
        {
            GD.PushError( e.Message );
        }
        return image;
    }

    protected void SkipStrings( BinaryReader reader,int howMany = 0 )
    {
        if( howMany == 0 )
            howMany = reader.ReadInt32( );
        for( int i = 0; i < howMany; i++ )
        {
            //byte l = reader.ReadByte( );
            var s = reader.ReadString( );
            //GD.Print( s );
        }
    }
    protected void SkipInts( BinaryReader reader,int record_length )
    {
        var count = reader.ReadInt32( );
        for( int i = 0; i < count; i++ )
        {
            for( int n = 0; n < record_length; n++ )
                reader.ReadInt32( );
        }
    }

    protected string LoadString( BinaryReader reader )
    {
        return reader.ReadString( );
    }
    protected void LoadVertices( BinaryReader reader,Dictionary data,string name )
    {
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
        data[name] = vertices;
    }
    protected void LoadSurfaces( BinaryReader reader,Dictionary data,string name )
    {
        var indicesCount = reader.ReadInt32( );
        if( indicesCount is < 0 or > 65535 )
        {
            GD.PrintErr( "LoadClothMeshData: too many indices" );
            return;
        }
        var surfaces = new Surfaces( );
        for( int i = 0; i < indicesCount; i++ )
        {
            var material = reader.ReadInt32( );
            var idxs = reader.ReadInt32( );

            var c = reader.ReadInt32( );
            var d = reader.ReadInt32( );
            var e = reader.ReadInt32( );
            int f = 0;

            switch( idxs )
            {
                case 4:
                    f = reader.ReadInt32( );
                    break;
                case 5:
                    reader.ReadInt32( );
                    break;
            }
            surfaces.AddVector( material,new Vector3I( c,e,d ) );

            if( idxs == 4 )
                surfaces.AddVector( material,new Vector3I( f,e,c ) );
        }
        for( int i = 0; i < indicesCount; i++ )
        {
            reader.ReadInt32( );
            var idxs = reader.ReadInt32( );

            reader.ReadInt32( );
            reader.ReadInt32( );
            reader.ReadInt32( );

            switch( idxs )
            {
                case 4:
                case 5:
                    reader.ReadInt32( );
                    break;
            }
        }
        data[name] = surfaces.GetSurfaces( );
    }
    protected void LoadUVs( BinaryReader reader,int verticesCount,Dictionary data,string name )
    {
        var uvsCount = reader.ReadInt32( );
        if( uvsCount is < 0 or > 65535 )
        {
            GD.PrintErr( "LoadClothMeshData: too many uvs" );
            return;
        }
        var uvs = new Vector2[uvsCount];
        for( int i = 0; i < verticesCount; i++ )
        {
            uvs[i] = new Vector2( reader.ReadSingle( ),1 - reader.ReadSingle( ) );
        }
        for( int i = verticesCount; i < uvsCount; i++ )
        {
            uvs[i] = new Vector2( reader.ReadSingle( ),1 - reader.ReadSingle( ) );
        }
        data[name] = uvs;
    }
    #endregion

    #region Debug
    private static List<string> __files = [];

    private void TraceArchiveFile( string archiveFile,string filename )
    {
#if DEBUG
        string s = archiveFile;
        if( !__files.Contains( s ) )
        {
            __files.Add( s );
			
            GD.PrintS( "Loaded from archive:",archiveFile );
        }
#endif
    }
    #endregion
}

public class VAMItem
{
    public int ID { get; init; }
    public string UID  { get; init; }
    public string Archive  { get; init; }
    
    public string Title  { get; init; }
    public string Folder  { get; init; }
    public string BaseFile  { get; init; }
    public string BinaryFile  { get; init; }
    public string DetailsFile  { get; init; }
    public string BaseJSON  { get; init; }
    public string PreviewImageFile  { get; init; }
}

public class VAMItemList : List<VAMItem>
{
    
}

public class Surfaces
{
    private readonly List<List<Vector3I>> _surfaces = [];

    public void AddVector( int surface,Vector3I vector )
    {
        for( int i = _surfaces.Count; i <= surface; i++ )
            _surfaces.Add( [] );
        _surfaces[surface].Add( vector );
    }

    public Array GetSurfaces( )
    {
        var surfs = new Array( );
        foreach( var surf in _surfaces )
        {
            var data = new int[surf.Count*3];
            for( int i = 0; i < surf.Count; i++ )
            {
                data[i*3] = surf[i].X;
                data[i*3+1] = surf[i].Y;
                data[i*3+2] = surf[i].Z;
            }
            surfs.Add( data );
        }
        return surfs;
    }
}