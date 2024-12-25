using System;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Collider2D))]
public class Tile : MonoBehaviour
{
    [Serializable]
    public class AdjoinTile : IComparable<AdjoinTile>
    {
        public Tile tile;
        public Vector2 position;
        public float rotation;
        
        public float angle => Mathf.Atan2(position.y, position.x);
        
        public int CompareTo(AdjoinTile other) => angle.CompareTo(other.angle);
    }

    public List<AdjoinTile> adjoinTiles;
    
    public Renderer meshRenderer;

    public float size = 1;
    public Vector2Int textureSize = new Vector2Int(1024, 1024);

    private int layerGameActivated;
    private int layerGameDeactivated;

    public new Transform transform { get; private set; }
    private Vector2 originPosition;
    private float originRotation;
    
    public Collider2D trigger { get; private set; }
    
    public new Camera camera { get; private set; }
    public RenderTexture renderTexture { get; private set; }

    private void Awake()
    {
        layerGameActivated = LayerMask.NameToLayer("GameActivated");
        layerGameDeactivated = LayerMask.NameToLayer("GameDeactivated");

        transform = GetComponent<Transform>();
        originPosition = transform.position;
        originRotation = transform.rotation.eulerAngles.z;

        trigger = GetComponent<Collider2D>();
        trigger.isTrigger = true;

        if (meshRenderer is not null) {
            GameObject cameraGameObject = new GameObject("Camera" + gameObject.name);
            Transform cameraTransform = cameraGameObject.transform;
            cameraTransform.SetParent(transform);
            cameraTransform.localPosition = Vector3.back;

            camera = cameraGameObject.AddComponent<Camera>();
            camera.cullingMask = 1 << layerGameDeactivated;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.clear;
            camera.orthographic = true;
            camera.orthographicSize = size / 2;
        
            renderTexture = RenderTexture.GetTemporary(textureSize.x, textureSize.y);
            camera.targetTexture = renderTexture;

            Material material = new Material(meshRenderer.material);
            material.mainTexture = renderTexture;
            meshRenderer.material = material;
        }
        
        adjoinTiles.Sort();
    }

    private void LateUpdate()
    {
        if (gameObject.layer == layerGameDeactivated)
        {
            transform.position = originPosition;
            transform.rotation = Quaternion.Euler(0, 0, originRotation);
            camera.cullingMask = 1 << layerGameDeactivated;
        }
        else camera.cullingMask = 1 << layerGameActivated;
    }

    public void Activate()
    {
        SetLayer(transform, layerGameActivated);
        foreach (AdjoinTile adjoinTile in adjoinTiles)
        {
            SetLayer(adjoinTile.tile.transform, layerGameActivated);
            adjoinTile.tile.transform.position = transform.TransformPoint(adjoinTile.position);
            adjoinTile.tile.transform.rotation =
                Quaternion.Euler(0, 0, transform.rotation.eulerAngles.z + adjoinTile.rotation);
        }
    }

    public void Deactivate()
    {
        SetLayer(transform, layerGameDeactivated);
        foreach (AdjoinTile adjoinTile in adjoinTiles)
            SetLayer(adjoinTile.tile.transform, layerGameDeactivated);
    }

    private void SetLayer(Transform trans, int layer)
    {
        trans.gameObject.layer = layer;
        for (int i = 0; i < trans.childCount; i ++) SetLayer(trans.GetChild(i), layer);
    }
}
