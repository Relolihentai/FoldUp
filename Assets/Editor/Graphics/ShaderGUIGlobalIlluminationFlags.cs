using System.Collections;
using UnityEngine;
using UnityEditor;
using System;

public class ShaderGUIGlobalIlluminationFlags : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        EditorGUI.BeginChangeCheck();
        materialEditor.LightmapEmissionProperty();
        if (EditorGUI.EndChangeCheck())
        {
            foreach (var eachMaterial in materialEditor.targets)
            {
                Material material = eachMaterial as Material;
                material.globalIlluminationFlags &= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            }
        }
    }
}
