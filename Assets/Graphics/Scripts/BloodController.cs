using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

public class BloodController : MonoBehaviour
{
    [Range(0f, 1f)] public float _decalRate = 1f;
    public float _minSize;
    public float _maxSize;
    public Gradient _colorGradient;

    private ParticleSystem _bloodParticleSystem;
    private readonly List<ParticleCollisionEvent> _collisionEvents = new List<ParticleCollisionEvent>(4);

    private void Awake()
    {
        _bloodParticleSystem = GetComponent<ParticleSystem>();
    }

    private void OnParticleCollision(GameObject other)
    {
        int count = _bloodParticleSystem.GetCollisionEvents(other, _collisionEvents);

        for (int i = 0; i < count; i++) {
            float r = Random.Range(0f, 1f);
            if (r <= _decalRate) BloodManager.OnParticleHit(_collisionEvents[i], Random.Range(_minSize, _maxSize), _colorGradient.Evaluate(r));
        }
		
        BloodManager.DisplayBloomParticles();
    }
}
