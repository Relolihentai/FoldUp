using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using DG.Tweening;
using UnityEngine;
using UnityEngine.VFX;

public enum LevelIndex
{
    start, zero, one, two, three, four
}
[Serializable]
public struct LevelEffect
{
    public LevelIndex levelIndex;
    public List<Effect> levelEffects;
}

[Serializable]
public struct Effect
{
    public Material material;
    public List<EffectRange> materialProperties;
    public VisualEffect visualEffect;
    public List<EffectRange> visualEffectProperties;
}

[Serializable]
public struct EffectRange
{
    public string propertyName;
    public float propertyStart;
    public float propertyEnd;
    public float duration;
    public float delay;
}

public class PropertyAccount
{
    public VisualEffect visualEffect;
    public EffectRange effectRange;
    public float propertyValue;
    public bool propertyFlag;
    public float delay;

    public void Update()
    {
        if (effectRange.duration == 0) propertyValue = effectRange.propertyEnd;
        else propertyValue += Time.deltaTime * ((effectRange.propertyEnd - effectRange.propertyStart) / effectRange.duration);
        visualEffect.SetFloat(effectRange.propertyName, propertyValue);
    }

    public void UpdateDelay()
    {
        delay -= Time.deltaTime;
    }

    public void Over()
    {
        propertyFlag = true;
    }
}
public class LevelDissolveAPI : MonoBehaviour
{
    public static LevelDissolveAPI instance;
    public List<LevelEffect> _levelEffects;
    private List<PropertyAccount> _propertyAccountList;

    public void LevelDissolve(LevelIndex levelIndex)
    {
        LevelEffect curLevelEffect = _levelEffects[(int)levelIndex];
        List<Effect> curLevelEffects = curLevelEffect.levelEffects;
        foreach (var effect in curLevelEffects)
        {
            if (effect.material)
            {
                foreach (var materialProperty in effect.materialProperties)
                {
                    effect.material.SetFloat(materialProperty.propertyName, materialProperty.propertyStart);
                    effect.material.DOFloat(materialProperty.propertyEnd, materialProperty.propertyName,
                        materialProperty.duration).SetDelay(materialProperty.delay);
                }
            }

            if (effect.visualEffect)
            {
                foreach (var visualEffectProperty in effect.visualEffectProperties)
                {
                    effect.visualEffect.SetFloat(visualEffectProperty.propertyName, visualEffectProperty.propertyStart);
                    RegisterProperty(effect.visualEffect, visualEffectProperty);
                }
            }
        }
    }

    public void RegisterProperty(VisualEffect visualEffect, EffectRange effectRange)
    {
        _propertyAccountList.Add(new PropertyAccount
        {
            visualEffect = visualEffect,
            propertyValue = effectRange.propertyStart,
            effectRange = effectRange,
            propertyFlag = false,
            delay = effectRange.delay
        });
    }

    private void Update()
    {
        if (_propertyAccountList.Count > 0)
        {
            foreach (var propertyAccount in _propertyAccountList.ToList())
            {
                if (!propertyAccount.propertyFlag)
                {
                    if (propertyAccount.delay > 0) propertyAccount.UpdateDelay();
                    else
                    {
                        if (Mathf.Abs(propertyAccount.propertyValue - propertyAccount.effectRange.propertyEnd) < 0.1f) propertyAccount.Over();
                        else propertyAccount.Update();
                    }
                }
                else _propertyAccountList.Remove(propertyAccount);
            }
        }
    }
    
    private void Awake()
    {
        instance = this;
        _propertyAccountList = new List<PropertyAccount>();
    }
}
