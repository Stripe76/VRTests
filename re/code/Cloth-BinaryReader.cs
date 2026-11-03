// Assembly-CSharp, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null
// GPUTools.Cloth.Scripts.Geometry.Data.ClothGeometryData
using System;
using System.Collections.Generic;
using System.IO;
using GPUTools.Cloth.Scripts.Types;
using UnityEngine;

public bool LoadFromBinaryReader(BinaryReader reader)
{
	try
	{
		string text = reader.ReadString();
		if (text != "ClothGeometryData")
		{
			Debug.LogError("Binary file corrupted. Tried to read ClothGeometryData in wrong section");
			return false;
		}
		string text2 = reader.ReadString();
		if (text2 != "1.0")
		{
			Debug.LogError("ClothGeometryData schema " + text2 + " is not compatible with this version of software");
			return false;
		}
		int num = reader.ReadInt32();
		AllTringles = new int[num];
		for (int i = 0; i < num; i++)
		{
			AllTringles[i] = reader.ReadInt32();
		}
		int num2 = reader.ReadInt32();
		Particles = new Vector3[num2];
		Vector3 vector = default;
		for (int j = 0; j < num2; j++)
		{
			vector.x = reader.ReadSingle();
			vector.y = reader.ReadSingle();
			vector.z = reader.ReadSingle();
			Particles[j] = vector;
		}
		int num3 = reader.ReadInt32();
		MeshToPhysicsVerticesMap = new int[num3];
		for (int k = 0; k < num3; k++)
		{
			MeshToPhysicsVerticesMap[k] = reader.ReadInt32();
		}
		int num4 = reader.ReadInt32();
		PhysicsToMeshVerticesMap = new int[num4];
		for (int l = 0; l < num4; l++)
		{
			PhysicsToMeshVerticesMap[l] = reader.ReadInt32();
		}
		int num5 = reader.ReadInt32();
		JointGroups = new List<Int2ListContainer>();
		for (int m = 0; m < num5; m++)
		{
			Int2ListContainer int2ListContainer = new Int2ListContainer();
			JointGroups.Add(int2ListContainer);
			int num6 = reader.ReadInt32();
			int2ListContainer.List = new List<Int2>();
			for (int n = 0; n < num6; n++)
			{
				Int2 item = new Int2
				{
					X = reader.ReadInt32(),
					Y = reader.ReadInt32()
				};
				int2ListContainer.List.Add(item);
			}
		}
		int num7 = reader.ReadInt32();
		StiffnessJointGroups = new List<Int2ListContainer>();
		for (int num8 = 0; num8 < num7; num8++)
		{
			Int2ListContainer int2ListContainer2 = new Int2ListContainer();
			StiffnessJointGroups.Add(int2ListContainer2);
			int num9 = reader.ReadInt32();
			int2ListContainer2.List = new List<Int2>();
			for (int num10 = 0; num10 < num9; num10++)
			{
				Int2 item2 = new Int2
				{
					X = reader.ReadInt32(),
					Y = reader.ReadInt32()
				};
				int2ListContainer2.List.Add(item2);
			}
		}
		int num11 = reader.ReadInt32();
		NearbyJointGroups = new List<Int2ListContainer>();
		for (int num12 = 0; num12 < num11; num12++)
		{
			Int2ListContainer int2ListContainer3 = new Int2ListContainer();
			NearbyJointGroups.Add(int2ListContainer3);
			int num13 = reader.ReadInt32();
			int2ListContainer3.List = new List<Int2>();
			for (int num14 = 0; num14 < num13; num14++)
			{
				Int2 item3 = new Int2
				{
					X = reader.ReadInt32(),
					Y = reader.ReadInt32()
				};
				int2ListContainer3.List.Add(item3);
			}
		}
		int num15 = reader.ReadInt32();
		ParticleToNeibor = new int[num15];
		for (int num16 = 0; num16 < num15; num16++)
		{
			ParticleToNeibor[num16] = reader.ReadInt32();
		}
		int num17 = reader.ReadInt32();
		ParticleToNeiborCounts = new int[num17];
		for (int num18 = 0; num18 < num17; num18++)
		{
			ParticleToNeiborCounts[num18] = reader.ReadInt32();
		}
		int num19 = reader.ReadInt32();
		ParticlesBlend = new float[num19];
		for (int num20 = 0; num20 < num19; num20++)
		{
			ParticlesBlend[num20] = reader.ReadSingle();
		}
		int num21 = reader.ReadInt32();
		ParticlesStrength = new float[num21];
		for (int num22 = 0; num22 < num21; num22++)
		{
			ParticlesStrength[num22] = reader.ReadSingle();
		}
	}
	catch (Exception ex)
	{
		Debug.LogError("Error while loading ClothGeometryData from binary reader " + ex);
		return false;
	}
	return true;
}
