using System;
using UnityEditor;
using UnityEngine;

namespace URPToon
{
    public class URPToonShaderGUI : BaseShaderGUI
    {
        #region Structs

        private struct Styles
        {
            // Foldouts
            public static readonly GUIContent OutlineFold = new GUIContent("Outline");
            
            //CheckMark
            public static readonly string IsFace = "_IsFace";
        }
        
        private struct PropertyNames
        {
            //Outline
            public static readonly string EnableOutline = "_EnableOutline";
            public static readonly string OutlineColor = "_OutlineColor";
            public static readonly string OutlineThickness = "_OutlineThickness";
            public static readonly string UseColor = "_UseColor";
        }

        #endregion

        public delegate void DrawPropertiesFun(MaterialEditor materialEditor);
        #region Fields

        // Outline
        private bool m_OutlineFoldout;
        private MaterialProperty m_EnableOutlineProp;
        private MaterialProperty m_OutlineColorProp;
        private MaterialProperty m_OutlineThicknessProp;
        private MaterialProperty m_UseColorProp;
        // Properties
        private MaterialProperty m_IsFaseProp;
        
        #endregion
        
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            //base.OnGUI(materialEditor, properties);
            
            m_OutlineFoldout = GetFoldoutState(materialEditor, Styles.OutlineFold.text);
            
            //FindProperties
            m_IsFaseProp = FindProperty(Styles.IsFace, properties, false);
            
            //Outline
            m_EnableOutlineProp = FindProperty(PropertyNames.EnableOutline, properties, false);
            m_OutlineColorProp = FindProperty(PropertyNames.OutlineColor, properties, false);
            m_OutlineThicknessProp = FindProperty(PropertyNames.OutlineThickness, properties, false);
            m_UseColorProp = FindProperty(PropertyNames.UseColor, properties, false);
            
            EditorGUI.BeginChangeCheck();
            DrawProperties(materialEditor);
            if (EditorGUI.EndChangeCheck())
            {
                SetMaterialKeywords(materialEditor.target as Material);
            }
        }

        #region Properties
        private void DrawProperties(MaterialEditor materialEditor)
        {
            // Outline
            if (((Material) materialEditor.target).FindPass(Styles.OutlineFold.text) != -1)
            {
                var outlineFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_OutlineFoldout, Styles.OutlineFold);
                if (outlineFoldout)
                {
                    DrawOutlineProperties(materialEditor);
                    EditorGUILayout.Space();
                }
                SetFoldoutState(materialEditor, Styles.OutlineFold.text, m_OutlineFoldout, outlineFoldout);
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }

        private void DrawOutlineProperties(MaterialEditor materialEditor)
        {
            //DrawProperty(materialEditor, m_EnableOutlineProp, PropertyNames.EnableOutline);
            //if (m_EnableOutlineProp.floatValue == 1.0)
            {
                DrawColorProperty(materialEditor, m_OutlineColorProp, PropertyNames.OutlineColor);
                DrawSliderProperty(m_OutlineThicknessProp, PropertyNames.OutlineThickness,0,5);
                DrawKeyword(materialEditor, m_UseColorProp, PropertyNames.UseColor);
            }
        }
        
        #endregion
        
        #region Keywords
        private void SetMaterialKeywords(Material material)
        {
            // Reset
            material.shaderKeywords = null;

            // WorkflowMode
            if (material.HasProperty(Styles.IsFace))
            {
                SetKeyword(material,Styles.IsFace, material.GetFloat(Styles.IsFace) == 0);
            }

            //Outline
            //SetKeyword(material,"_USESMOOTHNORMAL", material.GetFloat(Names_IsFace) == 1.0);
            //material.SetShaderPassEnabled("Outline", material.GetFloat(Names_IsFace) == 1.0f);
        }
        #endregion
    }
}