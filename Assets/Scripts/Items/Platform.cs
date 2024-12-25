using System;
using UnityEngine;
using UnityEngine.EventSystems;

[RequireComponent(typeof(PlatformEffector2D))]
public class Platform : MonoBehaviour
{
    private new Transform transform;
    private new Collider2D collider;
    private PlatformEffector2D platformEffector;

    private float prevRotation = 0;

    private void Awake()
    {
        transform = GetComponent<Transform>();
        collider = GetComponent<Collider2D>();
        platformEffector = GetComponent<PlatformEffector2D>();
    }

    public bool KeyS;
    public void SetKeyS(bool flag)
    {
        KeyS = flag;
    }
    private void Start()
    {
        EventTrigger KeyS_E = GameObject.Find("KeyS").GetComponent<EventTrigger>();
        EventTrigger.Entry entry3 = new EventTrigger.Entry();
        entry3.eventID = EventTriggerType.PointerDown;
        entry3.callback.AddListener((data) =>
        {
            SetKeyS(true);
        });
        EventTrigger.Entry entry33 = new EventTrigger.Entry();
        entry33.eventID = EventTriggerType.PointerUp;
        entry33.callback.AddListener((data) =>
        {
            SetKeyS(false);
        });
        KeyS_E.triggers.Add(entry3);
        KeyS_E.triggers.Add(entry33);
    }

    private void Update()
    {
        float rotation = transform.eulerAngles.z;
        if (Math.Abs(rotation - prevRotation) > 1e-5f)
        {
            platformEffector.rotationalOffset = -rotation;
            prevRotation = rotation;
        }

        // collider.enabled = !(Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow));
        collider.enabled = !(KeyS);
    }
}
