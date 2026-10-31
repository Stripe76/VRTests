#nullable enable
using Godot;
using Godot.Collections;

using System;
using System.IO;
using System.IO.Compression;
using System.Collections.Generic;
using System.Text.Json;

public abstract class VAMObjects
{
    private readonly VAMItemList _items = [];

    public void AddItem( VAMItem item )
    {
        _items.Add( item );
        
    }

    public void AddEntry( string archive,ZipArchiveEntry entry )
    {
        _items.Add( new VAMItem( )
        {
            ID = _items.Count,
            Archive = archive,
            Title = entry.Name.Replace( ".vaj","" ),
            Folder = entry.FullName.Replace( entry.Name,"" ),
            BaseFile = entry.FullName,
            PreviewImageFile = entry.FullName.Replace( ".vaj",".jpg" )
        } );
    }

    public VAMItem? GetItem( int itemID )
    {
        if( itemID >= 0 && itemID < _items.Count )
            return _items[itemID];
        return null;
    }
    
    public int GetCount( )
    {
        return _items.Count;
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

            string binaryFile = item.BaseFile.Replace( ".vaj",".vab" );  
            var data = new Dictionary
            {
                { "meshFile",binaryFile },
                { "meshData",LoadMeshData( item.Archive,binaryFile ) },
                { "materials",LoadMaterials( item.Archive,item.BaseFile,item.Folder )}
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

                    //entry.ExtractToFile( "/mnt/data/Projects/Godot/library/_current_hair.vab",true );
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
    private Dictionary LoadMaterials( string archiveFile,string filename,string folder )
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
                        LoadMaterials( doc.RootElement,folder,data );
                    }
                }
            }
        }
        return data;
    }

    protected abstract void LoadMeshData( BinaryReader reader,Dictionary data );
    protected abstract void LoadMaterials( JsonElement root,string folder,Dictionary data );
    
    #region Helpers
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
    public string Archive  { get; init; }
    
    public string Title  { get; init; }
    public string Folder  { get; init; }
    public string BaseFile  { get; init; }
    public string BaseJSON  { get; init; }
    public string PreviewImageFile  { get; init; }
}

public class VAMItemList : List<VAMItem>
{
    
}
