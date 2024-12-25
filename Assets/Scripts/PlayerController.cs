using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PlayerController : MonoBehaviour
{
    public float moveSpeed = 2;
    public float jumpSpeed = 2;
    public float maxFallingSpeed = 3;
    public float jumpBeforeLand = 0.1f;
    public float jumpAfterFall = 0.1f;
    
    public new Transform transform { get; private set; }
    public new Collider2D collider { get; private set; }
    public new Rigidbody2D rigidbody { get; private set; }

    private float pressedJumpButton = -1;
    private float isTouchingGround = -1;

    private void Awake()
    {
        transform = GetComponent<Transform>();
        collider = GetComponent<Collider2D>();
        rigidbody = GetComponent<Rigidbody2D>();
    }

    private bool KeyW;
    private bool KeyA;
    private bool KeyD;
    public void SetKeyW(bool flag)
    {
        KeyW = flag;
    }
    public void SetKeyA(bool flag)
    {
        KeyA = flag;
    }
    
    public void SetKeyD(bool flag)
    {
        KeyD = flag;
    }

    private void Start()
    {
        EventTrigger KeyD_E = GameObject.Find("KeyD").GetComponent<EventTrigger>();
        EventTrigger KeyA_E = GameObject.Find("KeyA").GetComponent<EventTrigger>();
        EventTrigger KeyW_E = GameObject.Find("KeyW").GetComponent<EventTrigger>();
        
        
        EventTrigger.Entry entry0 = new EventTrigger.Entry();
        entry0.eventID = EventTriggerType.PointerDown;
        entry0.callback.AddListener((data) =>
        {
            SetKeyD(true);
        });
        EventTrigger.Entry entry00 = new EventTrigger.Entry();
        entry00.eventID = EventTriggerType.PointerUp;
        entry00.callback.AddListener((data) =>
        {
            SetKeyD(false);
        });
        
        EventTrigger.Entry entry1 = new EventTrigger.Entry();
        entry1.eventID = EventTriggerType.PointerDown;
        entry1.callback.AddListener((data) =>
        {
            SetKeyA(true);
        });
        EventTrigger.Entry entry11 = new EventTrigger.Entry();
        entry11.eventID = EventTriggerType.PointerUp;
        entry11.callback.AddListener((data) =>
        {
            SetKeyA(false);
        });
        
        EventTrigger.Entry entry2 = new EventTrigger.Entry();
        entry2.eventID = EventTriggerType.PointerDown;
        entry2.callback.AddListener((data) =>
        {
            SetKeyW(true);
        });
        EventTrigger.Entry entry22 = new EventTrigger.Entry();
        entry22.eventID = EventTriggerType.PointerUp;
        entry22.callback.AddListener((data) =>
        {
            SetKeyW(false);
        });
        
        
        
        KeyD_E.triggers.Add(entry0);
        KeyD_E.triggers.Add(entry00);
        KeyA_E.triggers.Add(entry1);
        KeyA_E.triggers.Add(entry11);
        KeyW_E.triggers.Add(entry2);
        KeyW_E.triggers.Add(entry22);
        
    }

    private void Update()
    {
        if (GameManager.instance.paused) return;
        
        Vector3 position = transform.position;

        Vector2 velocity = rigidbody.velocity;
        /*int dir = (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow) ? 1 : 0) -
                  (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow) ? 1 : 0);*/
        int dir = (KeyD || Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow) ? 1 : 0) -
                  (KeyA || Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow) ? 1 : 0);
        velocity.x = dir * moveSpeed;
        /*if (Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.UpArrow) || Input.GetKeyDown(KeyCode.W))
            pressedJumpButton = jumpBeforeLand;*/
        if (KeyW || Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.UpArrow) || Input.GetKeyDown(KeyCode.W))
            pressedJumpButton = jumpBeforeLand;
        if (Mathf.Abs(velocity.y) < 1e-5) isTouchingGround = jumpAfterFall;
        if (pressedJumpButton > 0 && isTouchingGround > 0)
        {
            velocity.y = jumpSpeed;
            pressedJumpButton = -1;
            isTouchingGround = -1;
        }

        if (velocity.y < -maxFallingSpeed) velocity.y = -maxFallingSpeed;
        rigidbody.velocity = velocity;

        transform.position = position;
        if (pressedJumpButton > 0) pressedJumpButton -= Time.deltaTime;
        if (isTouchingGround > 0) isTouchingGround -= Time.deltaTime;
    }
}
