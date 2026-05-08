using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text.Json;
using System.Threading.Tasks;
using Godot.Collections;
using VRMate.modules.library_manager;
using Array = Godot.Collections.Array;

[GlobalClass]
public partial class LibraryManager : Node
{
    private readonly string _sceneFolder = Path.Combine( "Saves","scene" ); 

    private readonly LooksList _looks = [];
    
    private string _libraryFolder;
    
    public void LoadData( string folder )
    {
        _libraryFolder = folder;
        
        if( Directory.Exists( folder ))
        {
            var files = Directory.EnumerateFiles( folder,"*.var" );
            foreach( var file in files )
            {
                try
                {
                    using( ZipArchive archive = ZipFile.OpenRead( file ) )
                    {
                        foreach( var entry in archive.Entries )
                        {
                            //GD.Print( entry.FullName );
                            if( entry.FullName.StartsWith( _sceneFolder,StringComparison.OrdinalIgnoreCase ) &&
                                entry.FullName.EndsWith( ".json",StringComparison.OrdinalIgnoreCase ) )
                            {
                                AddScene( file,entry );

                                //if( _looks.Count > 0 )
                                {
                                    //  GD.Print( _looks );
                                    //return;
                                }
                            }
                        }
                    }
                }
                catch( Exception e )
                {
                    GD.PushError( file + ": " + e.Message );
                }
            }
            //GD.Print( _looks );
        }
    }
    public void LoadDataAsync( string folder )
    {
        Task.Run( ( ) => LoadData( folder ) );
    }

    public int Looks_GetCount( )
    {
        return _looks.Count;
    }

    public string Looks_GetTitle( int lookID )
    {
        if( lookID >= 0 && lookID < _looks.Count )
            return _looks[lookID].Title;
        return string.Empty;
    }
    
    /*
    public string Looks_GetScene( int lookID )
    {
        if( lookID >= 0 && lookID < _looks.Count )
        {
            var look = _looks[lookID];

            //GD.Print( "Scene file: "+look.SceneFile );
            return LoadJSONFile( look.Archive,look.SceneFile );
        }
        return string.Empty;
    }
    */
    public string Looks_GetPerson( int lookID )
    {
        if( lookID >= 0 && lookID < _looks.Count )
            return _looks[lookID].Person;
        return string.Empty;
    }

    public Dictionary Looks_GetTextures( int lookID )
    {
        if( lookID >= 0 && lookID < _looks.Count )
        {
            var look = _looks[lookID];

            using( JsonDocument doc = JsonDocument.Parse( look.Person,new JsonDocumentOptions( ) { AllowTrailingCommas = true } ) )
            {
                //GD.Print( "JsonDocument" );
                if( doc.RootElement.TryGetProperty( "storables",out JsonElement storables ) )
                {
                    //GD.Print( "storables" );
                    foreach( JsonElement storable in storables.EnumerateArray( ) )
                    {
                        //GD.Print( "storable" );
                        if( storable.TryGetProperty( "id",out JsonElement textures ) && textures.ValueEquals( "textures" ) )
                        {
                            var data = new Dictionary( );
                            
                            foreach( JsonProperty texture in storable.EnumerateObject( ) )
                            {
                                if( !texture.Name.Equals( "id" ) )
                                    data.Add( texture.Name,texture.Value.ToString( ) );
                            }
                            return data;
                        }
                    }
                }
            }
        }
        return new Dictionary( );
    }
    public Image Looks_GetTextureImage( int lookID,string textureFile )
    {
        if( lookID >= 0 && lookID < _looks.Count )
        {
            var look = _looks[lookID];
            string archive = look.Archive;

            //"RenVR.Samantha_(HUB)_.latest:/Custom/Atom/Person/Textures/Samantha (REN)/FaceD (C).jpg",
            if( textureFile.StartsWith( "SELF:" ) )
            {
                textureFile = textureFile.Replace( "SELF:/","" );
            }
            else
            {
                var split = textureFile.Split( ":" );
                if( split.Length == 2 )
                {
                    if( split[0].Contains( ".latest" ) )
                        archive = Path.Combine( _libraryFolder,GetLatestPackage( _libraryFolder,split[0].Replace( ".latest","" ) ) );
                    else
                        archive = Path.Combine( _libraryFolder,split[0].Replace( ".latest",".1.var" ) );
                    textureFile = split[1].Substring( 1 );
                }
                //GD.Print(archive + " " + textureFile);
            }
            return LoadImage( archive,textureFile );
        }
        return new Image( );
    }

    public Array Looks_GetMorphs( int lookID )
    {
        if( lookID >= 0 && lookID < _looks.Count )
        {
            var look = _looks[lookID];

            using( JsonDocument doc = JsonDocument.Parse( look.Person,new JsonDocumentOptions( ) { AllowTrailingCommas = true } ) )
            {
                //GD.Print( "JsonDocument" );
                if( doc.RootElement.TryGetProperty( "storables",out JsonElement storables ) )
                {
                    //GD.Print( "storables" );
                    foreach( JsonElement storable in storables.EnumerateArray( ) )
                    {
                        //GD.Print( "storable" );
                        if( storable.TryGetProperty( "id",out JsonElement geometry ) && geometry.ValueEquals( "geometry" ) )
                        {
                            //GD.Print( "geometry" );
                            if( storable.TryGetProperty( "morphs",out JsonElement morphs ) )
                            {
                                //GD.Print( "morphs" );
                                var morphsData = new Array( ); 
                                foreach( JsonElement morph in morphs.EnumerateArray( ) )
                                {
                                    if( morph.TryGetProperty( "uid",out JsonElement uid ) && uid.ToString( ).StartsWith( "SELF:" ) )
                                    {
                                        var uidValue = uid.ToString( )[6..];
                                        string binaryFile = uidValue.Replace( ".vmi",".vmb" );

                                        float value = 0.0f;
                                        if( morph.TryGetProperty( "value",out JsonElement valueElement ) )
                                            float.TryParse( valueElement.ToString( ),out value );
                                        
                                        var data = new Dictionary
                                        {
                                            { "type",uidValue.Contains( "genitalia" ) ? "genitalia" : "body" },
                                            { "value",value },
                                            { "bonesFile",uidValue },
                                            { "bonesData",LoadBonesMorphs( look.Archive,uidValue ) },
                                            { "meshFile",binaryFile },
                                            { "meshData",LoadMeshMorphs( look.Archive,binaryFile ) },
                                        };
                                        morphsData.Add( data );
                                    }
                                }
                                return morphsData;
                            }
                        }
                    }
                }
            }
        }
        return new Array( );
    }
    
    public Texture2D Looks_GetPreviewImage( int lookID )
    {
        if( lookID >= 0 && lookID < _looks.Count )
        {
            var look = _looks[lookID];
            try
            {
                var image = LoadImage( look.Archive,look.PreviewImageFile );

                return ImageTexture.CreateFromImage( image );
            }
            catch( Exception e )
            {
                GD.PushError( e.Message );
            }
        }
        return null;
    }
    
    private void AddScene( string archive,ZipArchiveEntry entry )
    {
        try
        {
            using( StreamReader reader = new StreamReader( entry.Open( ) ) )
            {
                var json = reader.ReadToEnd( );
                using( JsonDocument doc = JsonDocument.Parse( json,new JsonDocumentOptions(  ){ AllowTrailingCommas = true } ))
                {
                    var root = doc.RootElement;
                    JsonElement atoms = root.GetProperty( "atoms" );
                    foreach( JsonElement atom in atoms.EnumerateArray( ) )
                    {
                        if( atom.TryGetProperty( "type",out JsonElement typeElement ) && typeElement.ValueEquals( "Person" ) )
                        {
                            JsonElement storables = atom.GetProperty( "storables" );
                            foreach( JsonElement storable in storables.EnumerateArray( ) )
                            {
                                if( storable.TryGetProperty( "id",out JsonElement idElement ) && idElement.ValueEquals( "geometry" ) )
                                {
                                    //GD.Print( "-- Person: " + name );
                                    _looks.Add( new Looks
                                    {
                                        ID = _looks.Count,
                                        Archive = archive,
                                        Person = atom.ToString( ), 
                                        Title = entry.Name.Replace( ".json","" ),
                                        SceneFile = entry.FullName,
                                        PreviewImageFile = entry.FullName.Replace( ".json",".jpg" )
                                    } );
                                }
                            }
                        }
                    }
                }
            }
        }
        catch( Exception e )
        {
            GD.PushError( e.Message );
        }
    }

    private Image LoadImage( string archiveFile,string filename )
    {
        var image = new Image( );
        try
        {
            //GD.Print( "archiveFile: " + archiveFile );
            using( ZipArchive archive = ZipFile.OpenRead( archiveFile ) )
            {
                //GD.Print( "filename: " + filename );
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

    private Array LoadMeshMorphs( string archiveFile,string filename )
    {
        var data = new Array( );
        try
        {
            using( ZipArchive archive = ZipFile.OpenRead( archiveFile ) )
            {
                var entry = archive.GetEntry( filename );
                if( entry != null )
                {
                    using( BinaryReader reader = new BinaryReader( entry.Open( ) ) )
                    {
                        int count = reader.ReadInt32( );
                        for( int i = 0; i < count; i++ )
                        {
                            int id = reader.ReadInt32( );
                            float x = -reader.ReadSingle( );
                            float y = reader.ReadSingle( );
                            float z = reader.ReadSingle( );
                            
                            data.Add( new Dictionary
                            {
                                {"id", id},
                                {"delta", new Vector3( x,y,z )}
                            } );
                        }
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
    private Dictionary LoadBonesMorphs( string archiveFile,string filename )
    {
        var data = new Dictionary( );
        try
        {
            //GD.Print( "LoadJSONFile" );
            using( JsonDocument doc = LoadJSONFile( archiveFile,filename ) )
            {
                //GD.Print( "TryGetProperty" );
                if( doc.RootElement.TryGetProperty( "formulas",out JsonElement formulas ) )
                {
                    //GD.Print( "formulas" );
                    foreach( JsonElement formula in formulas.EnumerateArray( ) )
                    {
                        if( formula.TryGetProperty( "target",out JsonElement target ) )
                        {
                            string boneName = target.ToString( );
                            if( !data.ContainsKey( boneName ) )
                                data[boneName] = new Array( );

                            if( formula.TryGetProperty( "targetType",out JsonElement type ) && 
                                formula.TryGetProperty( "multiplier",out JsonElement multiplier ) &&
                                float.TryParse( multiplier.ToString( ),out var value ) )
                            {
                                ((Array)data[boneName]).Add( new Dictionary { { type.ToString( ),value * 0.2f } } );
                            }
                        }
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
    
    private JsonDocument LoadJSONFile( string archiveFile,string filename )
    {
        try
        {
            using( ZipArchive archive = ZipFile.OpenRead( archiveFile ) )
            {
                var entry = archive.GetEntry( filename );
                if( entry != null )
                {
                    using( StreamReader reader = new StreamReader( entry.Open( ) ) )
                    {
                        return JsonDocument.Parse( reader.ReadToEnd( ),new JsonDocumentOptions( ) { AllowTrailingCommas = true } );
                    }
                }
            }
        }
        catch( Exception e )
        {
            GD.PushError( e.Message );
        }
        return JsonDocument.Parse( "{\"Error\":\"\"}" );
    }

    private string GetLatestPackage( string libraryFolder,string packageName )
    {
        packageName = packageName + ".";
        string filter = packageName + "*.var";

        //GD.Print( packageName );
        if( Directory.Exists( libraryFolder ) )
        {
            var files = Directory.EnumerateFiles( libraryFolder,filter );

            string latestPackage = "";
            foreach( var file in files )
            {
                string filename = Path.GetFileName( file ); 
                if( filename.StartsWith( packageName ) && string.Compare( file,latestPackage,StringComparison.Ordinal ) > 0 )
                {
                    latestPackage = file;
                }
            }
            return latestPackage;
        }
        return string.Empty;
    }

    private bool TryGetJSONElements( JsonElement root,string path,out List<JsonElement> elements)
    {
        int index = path.Find( '/' ); 
        if( index < 0 )
        {
            
        }
        else
        {
            string property = path.Left( index );
            if( root.ValueKind == JsonValueKind.Array )
            {
                path = path[(index + 1)..];

                foreach( JsonElement element in root.EnumerateArray( ) )
                {
                    if( TryGetJSONElements( element,path,out elements ) )
                    {
                        
                    }
                }
            }
            else
            {
                path = path.Substring( index + 1 );

                if( root.TryGetProperty( property,out JsonElement element ) )
                {
                    //if( element.ValueKind ==  )

                }
            }
        }
        elements = [];
            
        return false;
    }
}
