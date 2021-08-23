using System;
using UnityEditor;
using UnityEngine;

namespace URPToon
{
    public class BaseShaderGUI : ShaderGUI
    {
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
        }

        #region Drawers

        protected void DrawKeyword(MaterialEditor materialEditor, MaterialProperty materialProperty, string label)
        {
            Material material = materialEditor.target as Material;
            EditorGUI.BeginChangeCheck();
            materialEditor.ShaderProperty(materialProperty, GetDisplayShaderPropertyName(label));
            if (EditorGUI.EndChangeCheck())
                SetKeyword(material, materialProperty.name, material.GetFloat(materialProperty.name) == 1.0);
        }

        protected void DrawColorProperty(MaterialEditor materialEditor, MaterialProperty materialProperty, string label)
        {
            materialEditor.ColorProperty(materialProperty, GetDisplayShaderPropertyName(label));
        }

        protected void DrawSliderProperty(MaterialProperty materialProperty, string label, float leftValue,
            float rightValue)
        {
            EditorGUI.BeginChangeCheck();
            var newValue =
                EditorGUILayout.Slider(GetDisplayShaderPropertyName(label), materialProperty.floatValue, leftValue, rightValue);
            if (EditorGUI.EndChangeCheck())
                materialProperty.floatValue = newValue;
        }

        #endregion

        #region Utils
        protected string GetDisplayShaderPropertyName(string propertyName)
        {
            return propertyName.IndexOf("_", StringComparison.Ordinal) != -1 ? propertyName.Replace("_", "") : propertyName;
        }

        protected void SetKeyword(Material material, string keyword, bool value)
        {
            if (value)
                material.EnableKeyword(keyword);
            else
                material.DisableKeyword(keyword);
        }

        protected readonly string EditorPrefKey = "URPToonShaderGUI";

        protected bool GetFoldoutState(MaterialEditor materialEditor, string name)
        {
            // Get value from EditorPrefs
            return EditorPrefs.GetBool($"{EditorPrefKey}.{name + materialEditor.GetInstanceID()}");
        }

        protected void SetFoldoutState(MaterialEditor materialEditor, string name, bool field, bool value)
        {
            if (field == value)
                return;

            // Set value to EditorPrefs and field
            EditorPrefs.SetBool($"{EditorPrefKey}.{name + materialEditor.GetInstanceID()}", value);
        }

        #endregion
    }
}