using System;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public float mouseSensitive = 0.01f;
    public float wheelSensitive = 0.1f;

    public float followingSpeed = 3;
    public float transitionSpeed = 1;

    public Vector3 playerPositionOffset = new Vector3(0, 0.125f, 0);

    public enum CameraState
    {
        Following, Manual, Animated
    }

    public CameraState cameraState = CameraState.Following;

    public Vector3 levelPosition;
    public Quaternion levelRotation;
    public Transform animatedTransform;
    [Range(0, 1)] public float interpolation = 0;
    
    private new Transform transform;

    public float dist;
    private float theta, phi;
    private Vector3 direction;
    private Vector3 up;

    private Vector2 prevMousePosition;

    private void Awake()
    {
        transform = GetComponent<Transform>();

        direction = -transform.forward;
        up = transform.up;
    }

    private bool GetKey;

    public void SetGetKeyTrue()
    {
        GetKey = true;
    }
    private void Update()
    {
        LevelManager level = GameManager.instance.level;
        if (level is not null)
        {
            Tile tile = level.currentTile;
            Transform meshTransform = tile.meshRenderer.transform;

            // 刷新摄像机参数
            Vector3 localDirection = meshTransform.InverseTransformDirection(direction);
            localDirection = tile.transform.TransformDirection(localDirection);
            theta = Mathf.Atan2(localDirection.z, localDirection.x);
            phi = Mathf.Asin(localDirection.y / dist);

            // 计算追踪摄像机位置
            CalcFollowingCamera(out Vector3 targetPosition, out Vector3 targetDirection, out Vector3 targetUp);

            // 当按下任意按键时，开始追踪玩家
            //if (Input.anyKeyDown && cameraState == CameraState.Manual) cameraState = CameraState.Following;
            if (GetKey && cameraState == CameraState.Manual) cameraState = CameraState.Following;

            if (level.allowManualCamera && cameraState != CameraState.Animated)
            {
                // 使用鼠标滚轮控制距离
                dist *= Mathf.Exp(-wheelSensitive * Input.mouseScrollDelta.y);

                // 按下鼠标左键时，移动自由摄像机，停止追踪玩家
                if (Input.GetMouseButtonDown(0)) prevMousePosition = Input.mousePosition;
                if (Input.GetMouseButton(0))
                {
                    cameraState = CameraState.Manual;
                    UpdateManualCamera(out localDirection);
                    direction = localDirection * dist;
                }
            }

            // 平滑追踪
            float t = Mathf.Pow(10, -followingSpeed * Time.deltaTime);
            switch (cameraState)
            {
                case CameraState.Following:
                    direction = dist * Vector3.Lerp(targetDirection, direction.normalized, t).normalized;
                    up = Vector3.Lerp(targetUp, up, t).normalized;
                    break;
                case CameraState.Manual:
                    up = Vector3.Lerp(targetUp, up, t).normalized;
                    break;
                case CameraState.Animated:
                    direction = targetDirection;
                    up = targetUp;
                    break;
            }
            levelPosition = direction.normalized * dist + targetPosition;
            levelRotation = Quaternion.LookRotation(-direction, up);
        }

        if (cameraState == CameraState.Animated)
        {
            interpolation += transitionSpeed * Time.deltaTime;
            if (interpolation > 1) interpolation = 1;
        }
        else
        {
            interpolation -= transitionSpeed * Time.deltaTime;
            if (interpolation < 0) interpolation = 0;
        }

        float smoothedInterpolation = Smooth(interpolation);
        transform.position = Vector3.Lerp(levelPosition, animatedTransform.position, smoothedInterpolation);
        transform.rotation = Quaternion.Lerp(levelRotation, animatedTransform.rotation, smoothedInterpolation);
    }

    private float Smooth(float x) => ((6 * x - 15) * x + 10) * x * x * x;

    // 计算追踪摄像机位置
    private void CalcFollowingCamera(out Vector3 targetPosition, out Vector3 targetDirection, out Vector3 targetUp)
    {
        LevelManager level = GameManager.instance.level;
        
        PlayerController player = level.player;
        Tile tile = level.currentTile;
        Vector3 playerPosition = tile.transform.InverseTransformPoint(player.transform.position + playerPositionOffset);
        Vector3 playerUp = tile.transform.InverseTransformDirection(player.transform.up);
        Transform meshTransform = tile.meshRenderer.transform;

        Vector3 playerWorldPosition = meshTransform.TransformPoint(playerPosition);
        Vector3 targetLevelPosition = level.positionWeight * level.meshTransform.InverseTransformPoint(playerWorldPosition);
        targetPosition = level.meshTransform.TransformPoint(targetLevelPosition);

        Vector3 normalDirection = -meshTransform.forward;
        Vector3 adjoinDirection = normalDirection;
        if (tile.adjoinTiles.Count != 0)
        {
            float playerAngle = Mathf.Atan2(playerPosition.y, playerPosition.x);
            Tile.AdjoinTile tileAlpha = tile.adjoinTiles[^1];
            Tile.AdjoinTile tileBeta = tile.adjoinTiles[0];
            for (int i = 0; i < tile.adjoinTiles.Count; i++)
            {
                if (playerAngle > tile.adjoinTiles[i].angle) continue;
                if (i == 0) break;
                tileAlpha = tile.adjoinTiles[i - 1];
                tileBeta = tile.adjoinTiles[i];
                break;
            }

            float x = playerPosition.x, y = playerPosition.y;
            float xa = tileAlpha.position.x, ya = tileAlpha.position.y;
            float xb = tileBeta.position.x, yb = tileBeta.position.y;

            float alpha = ((x - xb) * yb - (y - yb) * xb) / ((xa - xb) * yb - (ya - yb) * xb);
            float beta = (-x * ya + y * xa) / (-xb * ya + yb * xa);

            Vector3 directionAlpha = -tileAlpha.tile.meshRenderer.transform.forward;
            Vector3 directionBeta = -tileBeta.tile.meshRenderer.transform.forward;

            adjoinDirection = (alpha * directionAlpha + beta * directionBeta + (1 - alpha - beta) * adjoinDirection)
                .normalized;
        }

        Vector3 meshUp = meshTransform.up, meshRight = meshTransform.right;
        Vector3 adjoinVerticalDirection = Vector3.Dot(adjoinDirection, meshUp) * meshUp;
        Vector3 adjoinHorizontalDirection = Vector3.Dot(adjoinDirection, meshRight) * meshRight;

        targetDirection = (normalDirection + level.verticalWeight * adjoinVerticalDirection +
                           level.horizontalWeight * adjoinHorizontalDirection).normalized;
        targetUp = meshTransform.TransformDirection(playerUp);
    }
    
    // 更新自由摄像机位置
    private void UpdateManualCamera(out Vector3 localDirection)
    {
        LevelManager level = GameManager.instance.level;
        Tile tile = level.currentTile;
        Transform meshTransform = tile.meshRenderer.transform;
        
        Vector2 delta = (Vector2)Input.mousePosition - prevMousePosition;
        theta -= delta.x * mouseSensitive;
        phi -= delta.y * mouseSensitive;
        if (theta > Mathf.PI) theta -= 2 * Mathf.PI;
        if (theta < -Mathf.PI) theta += 2 * Mathf.PI;
        if (phi > Mathf.PI / 2 - 0.01f) phi = Mathf.PI / 2 - 0.01f;
        if (phi < -Mathf.PI / 2 + 0.01f) phi = -Mathf.PI / 2 + 0.01f;
        prevMousePosition = Input.mousePosition;

        localDirection = new Vector3(Mathf.Cos(phi) * Mathf.Cos(theta), Mathf.Sin(phi),
            Mathf.Cos(phi) * Mathf.Sin(theta));
        localDirection = tile.transform.InverseTransformDirection(localDirection);
        localDirection = meshTransform.TransformDirection(localDirection);
    }
}
