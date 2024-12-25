using System;
using UnityEngine;

[RequireComponent(typeof(Animator))]
public class AnimatedCamera : MonoBehaviour
{
    private Animator animator;

    private void Awake()
    {
        animator = GetComponent<Animator>();
    }

    public void StartAnimation()
    {
        GameManager.instance.cameraController.cameraState = CameraController.CameraState.Animated;
        animator.SetInteger("Index", GameManager.instance.levelIndex);
        animator.SetTrigger("Trigger");
    }

    public void SwitchLevel()
    {
        GameManager.instance.LoadLevel(GameManager.instance.levelIndex + 1);
    }

    public void StopAnimation()
    {
        GameManager.instance.cameraController.cameraState = CameraController.CameraState.Following;
    }
}
