using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class BoxLevelGenerator : MonoBehaviour
{
    public Vector3 scale = Vector3.one;
    public int pixelsPerUnit = 256;
    
    public Sprite[] sprites = new Sprite[3];
    public Mesh[] meshes = new Mesh[3];

    private Vector3Int pixels;
    
#if UNITY_EDITOR
    public void Generate()
    {
        pixels = new Vector3Int((int)(scale.x * pixelsPerUnit), (int)(scale.y * pixelsPerUnit),
            (int)(scale.z * pixelsPerUnit));
    
        // sprites[0] = GenerateSprite(pixels.z, pixels.y);
        // sprites[1] = GenerateSprite(pixels.x, pixels.z);
        // sprites[2] = GenerateSprite(pixels.x, pixels.y);
        //
        // meshes[0] = GenerateMesh(scale.z, scale.y);
        // meshes[1] = GenerateMesh(scale.x, scale.z);
        // meshes[2] = GenerateMesh(scale.x, scale.y);
        
        // AssetDatabase.CreateAsset(sprites[0], "Assets/Textures/Generated/" + gameObject.name + "_0.sprite");
        // AssetDatabase.CreateAsset(sprites[1], "Assets/Textures/Generated/" + gameObject.name + "_1.sprite");
        // AssetDatabase.CreateAsset(sprites[2], "Assets/Textures/Generated/" + gameObject.name + "_2.sprite");
        // AssetDatabase.CreateAsset(meshes[0], "Assets/Meshes/Generated/" + gameObject.name + "_0.mesh");
        // AssetDatabase.CreateAsset(meshes[1], "Assets/Meshes/Generated/" + gameObject.name + "_1.mesh");
        // AssetDatabase.CreateAsset(meshes[2], "Assets/Meshes/Generated/" + gameObject.name + "_2.mesh");
        // AssetDatabase.SaveAssets();

        Transform tileTransform = transform.Find("Tiles");
        Transform meshTransform = transform.Find("Meshes");
        Transform trans;
        
        trans = tileTransform.Find("TileLeft");
        trans.position = new Vector3(-(scale.x + scale.z) / 2, 0, 0);
        InitializeTileObject(trans, 2, 1);
        trans = meshTransform.Find("MeshLeft");
        trans.position = new Vector3(-scale.x / 2, 0, 0);
        trans.GetComponent<MeshFilter>().sharedMesh = meshes[0];

        trans = tileTransform.Find("TileFront");
        InitializeTileObject(trans, 0, 1);
        trans = meshTransform.Find("MeshFront");
        trans.position = new Vector3(0, 0, -scale.z / 2);
        trans.GetComponent<MeshFilter>().sharedMesh = meshes[2];
        
        trans = tileTransform.Find("TileRight");
        trans.position = new Vector3((scale.x + scale.z) / 2, 0, 0);
        InitializeTileObject(trans, 2, 1);
        trans = meshTransform.Find("MeshRight");
        trans.position = new Vector3(scale.x / 2, 0, 0);
        trans.GetComponent<MeshFilter>().sharedMesh = meshes[0];
        
        trans = tileTransform.Find("TileBack");
        trans.position = new Vector3(scale.x + scale.z, 0, 0);
        InitializeTileObject(trans, 0, 1);
        trans = meshTransform.Find("MeshBack");
        trans.position = new Vector3(0, 0, scale.z / 2);
        trans.GetComponent<MeshFilter>().sharedMesh = meshes[2];
        
        trans = tileTransform.Find("TileDown");
        trans.position = new Vector3(0, -(scale.y + scale.z) / 2, 0);
        InitializeTileObject(trans, 0, 2);
        trans = meshTransform.Find("MeshDown");
        trans.position = new Vector3(0, -scale.y / 2, 0);
        trans.GetComponent<MeshFilter>().sharedMesh = meshes[1];
        
        trans = tileTransform.Find("TileUp");
        trans.position = new Vector3(0, (scale.y + scale.z) / 2, 0);
        InitializeTileObject(trans, 0, 2);
        trans = meshTransform.Find("MeshUp");
        trans.position = new Vector3(0, scale.y / 2, 0);
        trans.GetComponent<MeshFilter>().sharedMesh = meshes[1];
        
        Debug.Log("Generation Finished");
        
        EditorUtility.SetDirty(this);
        AssetDatabase.Refresh();
    }

    private Sprite GenerateSprite(int w, int h)
    {
        Texture2D texture = new Texture2D(w, h);
        Color[] colors = new Color[w * h];
        for (int i = 0; i < colors.Length; i++) colors[i] = Color.white;
        texture.SetPixels(colors);
        Sprite sprite = Sprite.Create(texture, new Rect(0, 0, w, h), new Vector2(0.5f, 0.5f), pixelsPerUnit);
        return sprite;
    }

    private Mesh GenerateMesh(float w, float h)
    {
        Mesh mesh = new Mesh();
        mesh.vertices = new Vector3[]
        {
            new Vector3(-0.5f * w, -0.5f * h, 0),
            new Vector3(-0.5f * w,  0.5f * h, 0),
            new Vector3( 0.5f * w, -0.5f * h, 0),
            new Vector3( 0.5f * w,  0.5f * h, 0)
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
        return mesh;
    }
    
    private void InitializeTileObject(Transform trans, int x, int y)
    {
        int z = 3 - x - y;
        trans.GetComponent<SpriteRenderer>().sprite = sprites[z];
        trans.GetComponent<SpriteMask>().sprite = sprites[z];
        trans.GetComponent<BoxCollider2D>().size = new Vector2(scale[x], scale[y]);
        Tile tile = trans.GetComponent<Tile>();
        tile.adjoinTiles[0].position.x = -(scale[x] + scale[z]) / 2;
        tile.adjoinTiles[1].position.x =  (scale[x] + scale[z]) / 2;
        tile.adjoinTiles[2].position.y = -(scale[y] + scale[z]) / 2;
        tile.adjoinTiles[3].position.y =  (scale[y] + scale[z]) / 2;
        tile.size = scale[y];
        tile.textureSize = new Vector2Int(pixels[x], pixels[y]);
    }
#endif
}

#if UNITY_EDITOR
[CustomEditor(typeof(BoxLevelGenerator))]
public class BoxLevelGeneratorEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("Generate")) ((BoxLevelGenerator)target).Generate();
    }
}
#endif