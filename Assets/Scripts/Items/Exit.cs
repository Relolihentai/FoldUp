using UnityEngine;

public class Exit : MonoBehaviour
{
    private bool triggered = false;

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (triggered) return;
        if (!other.CompareTag("Player")) return;
        if (transform.up.y < 0.95f) return;
        triggered = true;
        GameManager.instance.NextLevel();
    }
}
