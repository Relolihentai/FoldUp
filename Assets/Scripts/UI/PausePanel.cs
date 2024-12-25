using UnityEngine;
using UnityEngine.UI;

public class PausePanel : MonoBehaviour
{
    public Image backgroundImage;
    public RectTransform[] contentTransforms;
    
    public float animationSpeed = 1;
    [Range(0, 1)] public float unitAnimationRatio = 0.4f;

    public bool shown
    {
        get => _shown;
        set
        {
            if (_shown == value) return;
            _shown = value;
            isPlayingAnimation = true;
            gameObject.SetActive(true);
        }
    }

    private bool _shown = false;

    private bool isPlayingAnimation = false;
    private float animationProcess = 0;

    private void Awake()
    {
        Color color = backgroundImage.color;
        color.a = 0;
        backgroundImage.color = color;
        foreach (RectTransform contentTransform in contentTransforms)
        {
            contentTransform.anchorMin = new Vector2(-0.5f, contentTransform.anchorMin.y);
            contentTransform.anchorMax = new Vector2(-0.5f, contentTransform.anchorMax.y);
        }
        gameObject.SetActive(false);
    }
    
    private void Update()
    {
        if (!isPlayingAnimation) return;
        if (shown)
        {
            animationProcess += animationSpeed * Time.deltaTime;
            if (animationProcess > 1)
            {
                animationProcess = 1;
                isPlayingAnimation = false;
            }
        }
        else
        {
            animationProcess -= animationSpeed * Time.deltaTime;
            if (animationProcess < 0)
            {
                animationProcess = 0;
                isPlayingAnimation = false;
                gameObject.SetActive(false);
            }
        }
        
        Color color = backgroundImage.color;
        color.a = Smooth(animationProcess) * 0.6f;
        backgroundImage.color = color;
        
        for (int i = 0; i < contentTransforms.Length; i++)
        {
            RectTransform contentTransform = contentTransforms[i];
            float localProcess = animationProcess - (1 - unitAnimationRatio) * i / contentTransforms.Length;
            localProcess /= unitAnimationRatio;
            if (localProcess < 0) localProcess = 0;
            if (localProcess > 1) localProcess = 1;
            localProcess = HalfSmooth(localProcess);
            contentTransform.anchorMin = new Vector2(1.5f - localProcess, contentTransform.anchorMin.y);
            contentTransform.anchorMax = new Vector2(1.5f - localProcess, contentTransform.anchorMax.y);
        }
    }

    private float HalfSmooth(float x) => Smooth((x + 1) / 2) * 2 - 1;
    private float Smooth(float x) => ((6 * x - 15) * x + 10) * x * x * x;

    public void SkipAnimation()
    {
        animationProcess = shown ? 1 : 0;
        Update();
    }

    public void OnResumeButtonPressed()
    {
        GameManager.instance.paused = false;
    }

    public void OnResetButtonPressed()
    {
        GameManager.instance.ReloadLevel();
    }

    public void OnExitButtonPressed()
    {
        GameManager.instance.uiManager.titlePanel.shown = true;
        Invoke(nameof(UnloadLevel), 1 / GameManager.instance.uiManager.titlePanel.animationSpeed);
    }

    private void UnloadLevel()
    {
        GameManager.instance.UnloadLevel();
        SkipAnimation();
    }
}
