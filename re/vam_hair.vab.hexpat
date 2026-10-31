import std.io;
import std.mem;

u32 max_material_id = 0;

fn setMaxMaterial(u32 value) {
    if(value > max_material_id)
        max_material_id = value;
};

struct PascalString {
    u8 length;
    char text[length];
};

struct Vertex2 {
     float u;
     float v;
};

struct Vertex3 {
     float x;
     float y;
     float z;
};

struct MeshFace {
    u32 material_id;
    u32 face_count;
    
    u32 indices[face_count]; 
    
    setMaxMaterial(material_id);
};

struct MaterialHeader{
    PascalString name[3];
    u32 fixed;
    u32 index;
};

struct Strand{
    u32 id;
    u32 vertices_count;
    
    Vertex3 vertices[vertices_count];
};

struct MeshData{
    PascalString scalp[3];
    
    u32 unknown1;
    u32 unknown2;
    u8 unknown3;
    
    u32 data_count;
    u8 data[data_count];

    u32 strands_count;    
    Strand strands[strands_count];

};

struct FileLayout {
    PascalString header[2];
    
    u8 count;
    MeshData mesh_header[count];
    
    u32 indices_count;
    u32 indices[indices_count];
    
    u32 uvs_count;
    u32 unknown1;
    float uvs[uvs_count*4];
    
    u32 unk_count;
    u32 unknowns1[unk_count];
    
    u32 end;
};

FileLayout file @ 0x00;