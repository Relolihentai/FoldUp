using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

[Serializable]
public class BloomParticleData
{
    public float size;
    public Vector3 position;
    public Vector3 rotation;
    public Color color;
}
public class BloodManager : MonoBehaviour
{
    public const int CAPACITY = 2000;

    private static Transform _bloodRoot;
    private static int _bloodIndex;
    private static ParticleSystem _bloodParticleSystem;
    private static readonly BloomParticleData[] _data = new BloomParticleData[CAPACITY];
    private static readonly ParticleSystem.Particle[] _particles = new ParticleSystem.Particle[CAPACITY];

    private void Awake()
    {
        _bloodRoot = transform;
        _bloodParticleSystem = GetComponent<ParticleSystem>();
        for (int i = 0; i < CAPACITY; i++)
        {
            _data[i] = new BloomParticleData();
        }
    }

    public static void OnParticleHit(ParticleCollisionEvent @event, float size, Color color)
    {
        Debug.Log("SetData");
        SetBloodParticleData(@event, size, color);
    }

    private static void SetBloodParticleData(ParticleCollisionEvent @event, float size, Color color)
    {
        if (_bloodIndex >= CAPACITY) _bloodIndex = 0;
        BloomParticleData data = BloodManager._data[_bloodIndex];
        Vector3 euler = Quaternion.LookRotation(-@event.normal).eulerAngles;
        euler.z = Random.Range(0, 360);
        data.position = @event.intersection;
        data.rotation = euler;
        data.size = size;
        data.color = color;

        _bloodIndex++;  
    }

    public static void DisplayBloomParticles()
    {
        for (int i = 0, l = _data.Length; i < l; i++) {
            BloomParticleData data = BloodManager._data[i];
            _particles[i].position = data.position;
            _particles[i].rotation3D = data.rotation;
            _particles[i].startSize = data.size;
            _particles[i].startColor = data.color;
        }
		
        _bloodParticleSystem.SetParticles(_particles, CAPACITY);
    }
}
