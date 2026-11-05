using Godot;
using System.IO;
using System.Collections.Generic;

public class VAMCategoryManager
{
    private readonly string _directoryPath;

    private readonly Dictionary<string,List<string>> _categoriesUIDs = new( );

    public VAMCategoryManager( string subFolder )
    {
        string baseUserPath = ProjectSettings.GlobalizePath( "user://" );

        _directoryPath = Path.Combine( baseUserPath,"categories",subFolder );
    }

    public void LoadAll( )
    {
        _categoriesUIDs.Clear( );

        if( Directory.Exists( _directoryPath ) )
        {
            string[] files = Directory.GetFiles( _directoryPath,"*.txt" );

            foreach( string filePath in files )
            {
                string categoryName = Path.GetFileNameWithoutExtension( filePath );

                if( _categoriesUIDs.TryAdd( categoryName,[] ) )
                {
                    var category = _categoriesUIDs[categoryName];
                    
                    using var reader = new StreamReader( filePath );
                    while( reader.ReadLine( ) is { } line )
                    {
                        category.Add( line.Trim( ) );
                    }
                }
            }
        }
    }

    public List<string> GetUIDCategories( string uid )
    {
        var categories = new List<string>( );
        foreach( var k in _categoriesUIDs.Keys )
        {
            var category = _categoriesUIDs[k];
            if( category.Contains( uid ))
                categories.Add( k );
        }
        return categories;
    }

    public void SaveAll( SortedList<string,List<string>> filters )
    {
        if( !Directory.Exists( _directoryPath ) )
        {
            Directory.CreateDirectory( _directoryPath );
        }
        foreach( var filter in filters )
        {
            if( string.IsNullOrEmpty( filter.Key ) || filter.Value.Count == 0 )
                continue;

            string filePath = Path.Combine( _directoryPath,$"{filter.Key}.txt" );

            using var writer = new StreamWriter( filePath,false );
            foreach( string uid in filter.Value )
            {
                writer.WriteLine( uid );
            }
        }
    }
}