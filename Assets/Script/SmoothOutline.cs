using System.Collections.Generic;
using UnityEngine;
public class SmoothOutline : MonoBehaviour
{
    Mesh MeshNormalAverage(Mesh mesh)
    {
        //存储顶点和对应的索引
        Dictionary<Vector3, List<int>> map = new Dictionary<Vector3, List<int>>();
        for (int v = 0; v < mesh.vertexCount; ++v)
        {
            if (!map.ContainsKey(mesh.vertices[v]))
            {
                map.Add(mesh.vertices[v], new List<int>());
            }
            map[mesh.vertices[v]].Add(v);
        }
        
        Vector3[] normals = mesh.normals;
        Vector3 normal;
        foreach(var p in map)
        {
            normal = Vector3.zero;
            //根据顶点所有对应索引计算法线总方向
            foreach (var n in p.Value)
            {
                normal += mesh.normals[n];
            }
            //归一化
            normal /= p.Value.Count;
            foreach (var n in p.Value)
            {
                normals[n] = normal;
            }
        }
        //把平滑后的顶点法线信息存入切线信息
        var tangents = new Vector4[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            tangents[j] = new Vector4(normals[j].x, normals[j].y, normals[j].z, 0);
        }
        mesh.tangents= tangents;
        return mesh;
    }
    void Awake()
    {
        if (GetComponent<MeshFilter>())
        {
            Mesh tempMesh = (Mesh)Instantiate(GetComponent<MeshFilter>().sharedMesh);
            tempMesh=MeshNormalAverage(tempMesh);
            gameObject.GetComponent<MeshFilter>().sharedMesh = tempMesh;
        }
        if (GetComponent<SkinnedMeshRenderer>())
        {
            Mesh tempMesh = (Mesh)Instantiate(GetComponent<SkinnedMeshRenderer>().sharedMesh);
            tempMesh = MeshNormalAverage(tempMesh);
            gameObject.GetComponent<SkinnedMeshRenderer>().sharedMesh = tempMesh;
        }
    }
}