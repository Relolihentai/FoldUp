using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager instance;
    
    public UIManager uiManager;

    public CameraController cameraController;
    public AnimatedCamera animatedCamera;

    public GameObject[] levelObjects;
    public Transform[] levelTransforms;

    public int levelIndex = -1;
    public LevelManager level;

    private float startTime;

    public bool paused
    {
        get => _paused;
        set
        {
            if (_paused == value) return;
            _paused = value;
            if (value) Pause();
            else Resume();
        }
    }
    private bool _paused = false;
    private Vector2 playerVelocity;

    private void Awake()
    {
        instance = this;
    }
    
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.R) && level is not null && !paused) ReloadLevel();
        if (Input.GetKeyDown(KeyCode.Escape) && level is not null) paused = !paused;
    }

    private void Pause()
    {
        Rigidbody2D playerRigidbody = level.player.rigidbody;
        playerVelocity = playerRigidbody.velocity;
        playerRigidbody.velocity = Vector2.zero;
        playerRigidbody.gravityScale = 0;
        uiManager.pausePanel.shown = true;
    }

    private void Resume()
    {
        Rigidbody2D playerRigidbody = level.player.rigidbody;
        playerRigidbody.velocity = playerVelocity;
        playerRigidbody.gravityScale = 1;
        uiManager.pausePanel.shown = false;
    }

    public void ReloadLevel() => LoadLevel(levelIndex);
    public void UnloadLevel() => LoadLevel(-1);

    public void NewGame()
    {
        cameraController.dist = 10;
        LoadLevel(0, false);
        startTime = Time.time;
    }
    
    public void NextLevel()
    {
        if (levelIndex + 1 < levelObjects.Length)
        {
            animatedCamera.StartAnimation();
        }
        else
        {
            Invoke(nameof(UnloadLevel), 1 / uiManager.endPanel.animationSpeed);
            uiManager.endPanel.shown = true;
            int playTime = (int)(Time.time - startTime);
            uiManager.endPanel.timeText.text = "游玩时间  " + playTime / 60 + ":" + playTime % 60;
        }
    }

    public void LoadLevel(int index, bool animated = true)
    {
        if (level is not null) Destroy(level.gameObject);
        levelIndex = index;
        paused = false;
        if (index != -1)
        {
            level = Instantiate(levelObjects[index]).GetComponent<LevelManager>();
            level.meshTransform.position = levelTransforms[index].position;
        }
        else level = null;
    }
}
