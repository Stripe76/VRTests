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

struct Swap {
    u32 a;
    u32 b;
    u32 c;
};

struct Skinning {
    u32 a;
    u32 b;
    u32 c;
    u32 d;
    float fa;
    float fb;
    float fc;
    float fd;
    float fe;
    float ff;
};

struct MaterialHeader{
    PascalString name[3];
    u32 fixed;
    u32 index;
};

struct ExtraData{
    PascalString geometry_header[2];
   
    u32 geo_data_count;
    u32 geometries[geo_data_count];
    
    u32 boh1_count;
    Vertex3 bohs1[boh1_count];
    
    u32 boh2_count;
    u32 bohs2[boh2_count];    
};

struct FileLayout {
    PascalString header[8];
    
    u32 vertices_count;
    Vertex3 vertices[vertices_count];
    
    u32 str_count;
    PascalString idx_header[str_count];
    
    u32 idx_count;
    MeshFace indices1[idx_count];
    MeshFace indices2[idx_count];
    
    u32 uv_count;
    Vertex2 uvs[uv_count];
    
    u32 swap_count;
    Swap swaps[swap_count];
    
    PascalString header2[5];
    
    u32 skin_count;
    Skinning skins[skin_count];
   
    MaterialHeader material_header[max_material_id+1];
   
    u8 ext_data_count;    
    ExtraData extra_data[ext_data_count];
    
    u8 end;
};

FileLayout file @ 0x00;