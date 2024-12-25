using System;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class LevelGenerator : MonoBehaviour
{
    [Serializable]
    public struct TileData
    {
        public Vector2 size;
        public Sprite sprite;
        public Mesh mesh;
    }

    public GameObject tileTemplate;
    public GameObject meshTemplate;
    
    public float resolution = 1024;
    public List<TileData> tiles = new();

    public void Generate()
    {
        Transform levelTransform = transform;
        GameObject tileParentObject = new GameObject("Tiles");
        Transform tileParent = tileParentObject.transform;
        tileParent.parent = levelTransform;
        GameObject meshParentObject = new GameObject("Meshes");
        Transform meshParent = meshParentObject.transform;
        meshParent.parent = levelTransform;
        
        for (int i = 0; i < tiles.Count; i++)
        {
            TileData data = tiles[i];

            GameObject meshObject = Instantiate(meshTemplate);
            meshObject.name = "Mesh" + i;
            meshObject.transform.parent = meshParent;
            meshObject.GetComponent<MeshFilter>().sharedMesh = data.mesh;
            
            GameObject tileObject = Instantiate(tileTemplate);
            tileObject.name = "Tile" + i;
            tileObject.transform.parent = tileParent;
            tileObject.GetComponent<SpriteRenderer>().sprite = data.sprite;
            tileObject.GetComponent<SpriteMask>().sprite = data.sprite;
            tileObject.GetComponent<BoxCollider2D>().size = data.size;
            Tile tile = tileObject.GetComponent<Tile>();
            tile.size = data.size.y;
            tile.textureSize = new Vector2Int((int)(data.size.x * resolution), (int)(data.size.y * resolution));
            tile.meshRenderer = meshObject.GetComponent<MeshRenderer>();
        }
    }
}

#if UNITY_EDITOR
[CustomEditor(typeof(LevelGenerator))]
public class LevelGeneratorEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("Generate")) ((LevelGenerator)target).Generate();
    }
}
#endif
