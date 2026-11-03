// Assembly-CSharp, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null
// DAZSkinWrapStore
using System;
using System.IO;

public bool LoadFromBinaryReader(BinaryReader binReader)
{
	try
	{
		string text = binReader.ReadString();
		if (text != "DAZSkinWrapStore")
		{
			SuperController.LogError("Binary file corrupted. Tried to read DAZSkinWrapStore in wrong section");
			return false;
		}
		string text2 = binReader.ReadString();
		if (text2 != "1.0")
		{
			SuperController.LogError("DAZSkinWrapStore schema " + text2 + " is not compatible with this version of software");
			return false;
		}
		int num = binReader.ReadInt32();
		wrapVertices = new SkinWrapVert[num];
		for (int i = 0; i < num; i++)
		{
			wrapVertices[i] = default;
			wrapVertices[i].closestTriangle = binReader.ReadInt32();
			wrapVertices[i].Vertex1 = binReader.ReadInt32();
			wrapVertices[i].Vertex2 = binReader.ReadInt32();
			wrapVertices[i].Vertex3 = binReader.ReadInt32();
			wrapVertices[i].surfaceNormalProjection = binReader.ReadSingle();
			wrapVertices[i].surfaceTangent1Projection = binReader.ReadSingle();
			wrapVertices[i].surfaceTangent2Projection = binReader.ReadSingle();
			wrapVertices[i].surfaceNormalWrapNormalDot = binReader.ReadSingle();
			wrapVertices[i].surfaceTangent1WrapNormalDot = binReader.ReadSingle();
			wrapVertices[i].surfaceTangent2WrapNormalDot = binReader.ReadSingle();
		}
	}
	catch (Exception ex)
	{
		SuperController.LogError("Error while loading DAZSkinWrapStore from binary reader " + ex);
		return false;
	}
	return true;
}
