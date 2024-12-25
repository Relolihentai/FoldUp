using UnityEngine;
using UnityEngine.UI;

public class TitlePanel : MonoBehaviour
{
    public Image backgroundImage;
    public RectTransform[] contentTransforms;
    public GameObject backgroundGameObject;
    public float animationSpeed = 1;
    [Range(0, 1)] public float transformAnimationRatio = 0.6f;
    [Range(0, 1)] public float unitAnimationRatio = 0.8f;

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

    private static readonly int displayRatioProperty = Shader.PropertyToID("_DisplayRatio");

    private void Awake()
    {
        backgroundImage.material.SetFloat(displayRatioProperty, 0);
        foreach (RectTransform contentTransform in contentTransforms)
        {
            contentTransform.anchorMin = new Vector2(-1, contentTransform.anchorMin.y);
            contentTransform.anchorMax = new Vector2(0, contentTransform.anchorMax.y);
        }
        
        Invoke(nameof(Show), 0.5f);
    }

    private void Show() => shown = true;
    
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
        
        backgroundImage.material.SetFloat(displayRatioProperty, HalfSmooth(animationProcess));
        if (animationProcess > 1 - transformAnimationRatio)
        {
            float transformProcess = 1 + (animationProcess - 1) / transformAnimationRatio;
            for (int i = 0; i < contentTransforms.Length; i++)
            {
                RectTransform contentTransform = contentTransforms[i];
                float localProcess = transformProcess - (1 - unitAnimationRatio) * i / contentTransforms.Length;
                localProcess /= unitAnimationRatio;
                if (localProcess < 0) localProcess = 0;
                if (localProcess > 1) localProcess = 1;
                localProcess = HalfSmooth(localProcess);
                contentTransform.anchorMin = new Vector2(localProcess - 1, contentTransform.anchorMin.y);
                contentTransform.anchorMax = new Vector2(localProcess, contentTransform.anchorMax.y);
            }
        } else {
            foreach (RectTransform contentTransform in contentTransforms)
            {
                contentTransform.anchorMin = new Vector2(-1, contentTransform.anchorMin.y);
                contentTransform.anchorMax = new Vector2(0, contentTransform.anchorMax.y);
            }
        }
    }

    private float HalfSmooth(float x) => Smooth((x + 1) / 2) * 2 - 1;
    private float Smooth(float x) => ((6 * x - 15) * x + 10) * x * x * x;

    public void SkipAnimation()
    {
        animationProcess = shown ? 1 : 0;
        Update();
    }

    public void OnContinueButtonPressed()
    {
        backgroundGameObject.SetActive(false);
        shown = false;
    }

    public void OnNewGameButtonPressed()
    {
        backgroundGameObject.SetActive(false);
        shown = false;
        GameManager.instance.NewGame();
    }

    public void OnOptionButtonPressed()
    {
        
    }

    public void OnExitButtonPressed()
    {
        backgroundGameObject.SetActive(true);
        shown = false;
        Invoke(nameof(Exit), 1 / animationSpeed);
    }

    private void Exit()
    {
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#else
    Application.Quit();
#endif
    }

    public void OnMainPanelButtonPressed()
    {
        GameManager.instance.uiManager.titlePanel.shown = true;
        Invoke(nameof(HideInstantly), 1 / GameManager.instance.uiManager.titlePanel.animationSpeed);
    }

    private void HideInstantly()
    {
        shown = false;
        SkipAnimation();
    }
}
