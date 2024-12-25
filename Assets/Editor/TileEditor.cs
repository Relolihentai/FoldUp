using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(Tile))]
public class TileEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("GetAdjoinTilesTransform"))
        {
            Tile tile = (Tile)target;
            Transform tileTransform = tile.GetComponent<Transform>();
            for (int i = 0; i < tile.adjoinTiles.Count; i++)
            {
                Transform adjoinTransform = tile.adjoinTiles[i].tile.GetComponent<Transform>();
                tile.adjoinTiles[i].position = adjoinTransform.position - tileTransform.position;
                tile.adjoinTiles[i].rotation = adjoinTransform.eulerAngles.z - tileTransform.eulerAngles.z;
            }
        }
    }
}
