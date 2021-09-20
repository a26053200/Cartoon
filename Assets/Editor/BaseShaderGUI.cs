using System;
using UnityEditor;
using UnityEngine;

namespace URPToon
{
    public abstract class BaseShaderGUI : ShaderGUI
    {
        public delegate void DrawPropertiesFun();

        protected MaterialEditor _materialEditor;
        protected MaterialProperty[] _properties;
        protected Material _material;
        protected bool drawEnable = true;

        protected bool _showVertexColor;
        protected string _originShaderName;
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            _materialEditor = materialEditor;
            _properties = properties;
            _material = _materialEditor.target as Material;
            
            SetDefaultGUIWidths();

            //OnVertexColor(materialEditor, properties);
            
            if (_showVertexColor)
            {
                
            }
            else
            {
                drawEnable = true;
                OnShaderGUI(materialEditor, properties);

                if (!drawEnable)
                    throw new Exception("You defined a BeginGroup, but there is no EndGroup!");
                DrawSpace();
                DrawSpace();
                _materialEditor.RenderQueueField();
                _materialEditor.EnableInstancingField();
                _materialEditor.DoubleSidedGIField();
            }
        }

        protected abstract void OnShaderGUI(MaterialEditor materialEditor, MaterialProperty[] properties);

        protected void OnVertexColor(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            if (GUILayout.Button(_showVertexColor?"Origin Shader":"Vertex Shader"))
            {
                _showVertexColor = !_showVertexColor;
                if (_showVertexColor)
                {
                    _originShaderName = _material.shader.name;
                    _material.shader = Shader.Find("LitToon/LitVertexColor");
                }
                else
                {
                    _material.shader = Shader.Find(_originShaderName);
                }
            }
        }

        protected void SetDefaultGUIWidths()
        {
            _materialEditor.SetDefaultGUIWidths();
        }

        #region Drawers

        protected void DrawSpace()
        {
            if (!drawEnable) return;
            EditorGUILayout.Space();
        }
        
        protected void DrawFoldout(string label, ref bool foldoutFlag, DrawPropertiesFun fun)
        {
            if (!drawEnable) return;
            var foldout = EditorGUILayout.BeginFoldoutHeaderGroup(foldoutFlag, label);
            if (foldout)
            {
                fun();
                EditorGUILayout.Space();
            }
            SetFoldoutState(_materialEditor, label, foldoutFlag, foldout);
            EditorGUILayout.EndFoldoutHeaderGroup();
        }
        
        protected void DrawKeywords(string label, ref bool foldoutFlag, DrawPropertiesFun fun)
        {
            if (!drawEnable) return;
            var foldout = EditorGUILayout.BeginFoldoutHeaderGroup(foldoutFlag, label);
            if (foldout)
            {
                fun();
                EditorGUILayout.Space();
            }
            SetFoldoutState(_materialEditor, label, foldoutFlag, foldout);
            EditorGUILayout.EndFoldoutHeaderGroup();
        }
        
        protected void DrawTextureProperty(MaterialProperty materialProperty, string label = null, bool scaleOffset = true)
        {
            if (!drawEnable || materialProperty == null) return;
            EditorGUI.BeginChangeCheck();
            var newTexture = _materialEditor.TextureProperty(materialProperty, label ?? materialProperty.displayName, scaleOffset);
            if (EditorGUI.EndChangeCheck())
                materialProperty.textureValue = newTexture;
        }
        
        protected void DrawTextureSingleLineProperty(MaterialProperty materialProperty, MaterialProperty materialProperty2, string label = null)
        {
            if (!drawEnable || materialProperty == null) return;
            _materialEditor.TexturePropertySingleLine(new GUIContent(label ?? materialProperty.displayName), materialProperty, materialProperty2);
        }
        
        protected void DrawTextureSingleLineProperty(MaterialProperty materialProperty, string label)
        {
            if (!drawEnable || materialProperty == null) return;
            _materialEditor.TexturePropertySingleLine(new GUIContent(label ?? materialProperty.displayName), materialProperty);
        }
        
        protected void DrawFloat( MaterialProperty materialProperty, string label = null)
        {
            if (!drawEnable || materialProperty == null) return;
            EditorGUI.BeginChangeCheck();
            var newFloatValue = _materialEditor.FloatProperty(materialProperty, label ?? materialProperty.displayName);
            if (EditorGUI.EndChangeCheck())
                materialProperty.floatValue = newFloatValue;
        }

        protected void DrawColorProperty(MaterialProperty materialProperty, string label = null)
        {
            if (!drawEnable || materialProperty == null) return;
            EditorGUI.BeginChangeCheck();
            var newColor = _materialEditor.ColorProperty(materialProperty, label ?? materialProperty.displayName);
            if (EditorGUI.EndChangeCheck())
                materialProperty.colorValue = newColor;
        }

        protected void DrawSliderProperty(MaterialProperty materialProperty, string label = null)
        {
            if (!drawEnable || materialProperty == null) return;
            EditorGUI.BeginChangeCheck();
            var newValue = _materialEditor.RangeProperty(materialProperty, label ?? materialProperty.displayName);
            if (EditorGUI.EndChangeCheck())
                materialProperty.floatValue = newValue;
        }
        
        protected bool DrawKeyword(string keyword, MaterialProperty materialProperty, string label = null)
        {
            if (!drawEnable || materialProperty == null) return false;
            EditorGUI.BeginChangeCheck();
            _materialEditor.ShaderProperty(materialProperty, label ?? materialProperty.displayName);
            bool enable = _material.GetFloat(materialProperty.name) == 1.0f;
            if (EditorGUI.EndChangeCheck())
                SetKeyword(_material, keyword, enable);
            return enable;
        }
        
        protected Boolean BeginKeyWordGroup(string keyword, MaterialProperty materialProperty)
        {
            if (materialProperty == null) return false;
            //EditorGUILayout.Space();
            drawEnable = DrawKeyword(keyword, materialProperty);
            if (drawEnable)
            {
                drawEnable = true;
                EditorGUI.indentLevel += 1;
            }
            return drawEnable;
        }
        
        protected void EndKeyWordGroup()
        {
            if (drawEnable)
                EditorGUI.indentLevel -= 1;
            drawEnable = true;
        }

        protected bool IsKeywordEnable(MaterialProperty materialProperty)
        {
           return _material.GetFloat(materialProperty.name) == 1.0f;
        }

        #endregion

        #region Utils
        
        protected bool HasPass(string passName)
        {
            return ((Material) _materialEditor.target).FindPass(passName) != -1;
        }
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