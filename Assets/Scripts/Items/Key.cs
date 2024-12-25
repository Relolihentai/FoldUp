using UnityEngine;

public class Key : MonoBehaviour
{
    public GameObject[] gates;
    
    private void OnTriggerEnter2D(Collider2D other)
    {
        foreach (GameObject gate in gates)
            gate.SetActive(false);
        gameObject.SetActive(false);
    }
}
