using System;
using UnityEngine;
using UnityEngine.Serialization;

public class LevelManager : MonoBehaviour
{
    public PlayerController player;
    [SerializeField] private Tile _currentTile;
    public Transform meshTransform;

    public float positionWeight = 0.2f;
    public float verticalWeight = 0.3f;
    public float horizontalWeight = 0.6f;
    public bool allowManualCamera = true;
    
    public new Transform transform { get; private set; }

    public Tile currentTile
    {
        get => _currentTile;
        private set
        {
            if (value == _currentTile) return;
            if (_currentTile is not null) _currentTile.Deactivate();
            _currentTile = value;
            if (value is not null) value.Activate();
        }
    }

    private void Awake()
    {
        transform = GetComponent<Transform>();
    }

    private void Start()
    {
        currentTile.Activate();
    }

    private void Update()
    {
        Vector2 position = player.transform.position;
        if (currentTile.trigger.OverlapPoint(position)) return;
        foreach (Tile.AdjoinTile adjoinTile in currentTile.adjoinTiles)
        {
            if (adjoinTile.tile.trigger.OverlapPoint(position)) {
                currentTile = adjoinTile.tile;
                break;
            }
        }
    }
}
