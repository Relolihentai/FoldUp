using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestDissolve : MonoBehaviour
{
    public Material _dissolve_white_start;
    public Material _dissolve_white_0;
    public Material _dissolve_red_0;
    private float _threshold;
    private float _threshold_0;

    private void Start()
    {
        /*_threshold = 30f;
        _threshold_0 = -80f;*/
        LevelDissolveAPI.instance.LevelDissolve(LevelIndex.zero);
    }

    private void Update()
    {
        /*_threshold -= Time.deltaTime * 5;
        _dissolve_white_start.SetFloat("_DissolveThreshold", _threshold);
        if (_threshold + 40 < 1f)
        {
            _threshold_0 += Time.deltaTime * 7;
        }
        _dissolve_white_0.SetFloat("_DissolveThreshold", _threshold_0);
        _dissolve_red_0.SetFloat("_DissolveThreshold", _threshold_0);*/
    }
}
