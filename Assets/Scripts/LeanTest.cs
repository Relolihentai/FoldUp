using System.Collections;
using System.Collections.Generic;
using Lean.Touch;
using UnityEngine;

public class LeanTest : MonoBehaviour
{
    public void LeanDebug(LeanFinger finger)
    {
        Debug.Log("finger position : " + finger.LastScreenPosition);
    }
}
