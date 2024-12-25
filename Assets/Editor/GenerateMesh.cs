using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class GenerateMesh : MonoBehaviour
{
    [MenuItem("Tools/GenerateMesh")]
    public static void Generate()
    {
        for (int w = 8; w <= 8; w++)
        for (int h = 8; h <= 8; h++)
            GenerateRect(w, h);
        Debug.Log("Generation Finished");
    }

    private static void GenerateRect(int w, int h)
    {
        Mesh mesh = new Mesh();
        mesh.vertices = new Vector3[]
        {
            new Vector3(-0.5f * w / 4, -0.5f * h / 4, 0),
            new Vector3(-0.5f * w / 4,  0.5f * h / 4, 0),
            new Vector3( 0.5f * w / 4, -0.5f * h / 4, 0),
            new Vector3( 0.5f * w / 4,  0.5f * h / 4, 0)
        };
        mesh.uv = new Vector2[]
        {
            new Vector2(0, 0),
            new Vector2(0, 1),
            new Vector2(1, 0),
            new Vector2(1, 1)
        };
        mesh.triangles = new int[]
        {
            0, 1, 3,
            0, 3, 2
        };
        mesh.RecalculateNormals();
        AssetDatabase.CreateAsset(mesh, "Assets/Meshes/Rect" + w + "x" + h + ".mesh");
        AssetDatabase.SaveAssets();
    }
}
