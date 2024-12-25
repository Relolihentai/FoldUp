using System;
using UnityEngine;

public class KeyButtonAnimator : MonoBehaviour
{
    public KeyCode[] keys;
    public float animationSpeed = 5;

    private new Transform transform;

    private void Awake()
    {
        transform = GetComponent<Transform>();
    }

    private void Update()
    {
        bool pressed = false;
        foreach (KeyCode key in keys)
        {
            if (Input.GetKey(key))
            {
                pressed = true;
                break;
            }
        }

        Vector3 position = transform.localPosition;
        position.z = Mathf.Lerp(pressed ? 0.005f : -0.01f, position.z, Mathf.Pow(10, -animationSpeed * Time.deltaTime));
        transform.localPosition = position;
    }
}
