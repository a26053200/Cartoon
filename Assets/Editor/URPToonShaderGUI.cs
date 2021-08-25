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
            public static readonly GUIContent BaseFold = new GUIContent("Base");
            public static readonly GUIContent CarToonFold = new GUIContent("Cartoon");
            public static readonly GUIContent RimFold = new GUIContent("Rim");
            public static readonly GUIContent OutlineFold = new GUIContent("Outline");//Pass
            
            //CheckMark
            public static readonly string IsFace = "_IsFace";
        }
        
        private struct PropertyNames
        {
            //Base
            public static readonly string BaseMap = "_BaseMap";
            public static readonly string BaseColor = "_BaseColor";
            
            //Cartoon
            public static readonly string BrightColor = "_BrightColor";
            public static readonly string MiddleColor = "_MiddleColor";
            public static readonly string DarkColor = "_DarkColor";
            public static readonly string CelShadeMidPoint = "_CelShadeMidPoint";
            public static readonly string CelShadeSmoothness = "_CelShadeSmoothness";
            public static readonly string IsFace = "_IsFace";
            public static readonly string HairShadowDistance = "_HairShadowDistance";
            public static readonly string HeightCorrectMax = "_HeightCorrectMax";
            public static readonly string HeightCorrectMin = "_HeightCorrectMin";
            
            //Rim
            public static readonly string EnableRim = "_EnableRim";
            public static readonly string RimColor = "_RimColor";
            public static readonly string RimSmoothness = "_RimSmoothness";
            public static readonly string RimStrength = "_RimStrength";
            
            //Outline
            public static readonly string OutlineColor = "_OutlineColor";
            public static readonly string OutlineThickness = "_OutlineThickness";
            public static readonly string UseColor = "_UseColor";
        }

        #endregion

        
        #region Fields

        private bool _outlineFoldout;
        private bool _baseFoldOut;
        private bool _cartoonFoldout;
        
        // Outline
        private MaterialProperty _baseMapProp;
        private MaterialProperty _baseColorProp;
        
        // Cartoon
        private MaterialProperty _brightColorProp;
        private MaterialProperty _middleColoProp;
        private MaterialProperty _darkColorProp;
        private MaterialProperty _celShadeMidPointProp;
        private MaterialProperty _celShadeSmoothnessProp;
        // Face and Hair
        private MaterialProperty _isFaceProp;
        private MaterialProperty _hairShadowDistanceProp;
        private MaterialProperty _heightCorrectMaxProp;
        private MaterialProperty _heightCorrectMinProp;
        
        // Rim
        private MaterialProperty _enableRim;
        private MaterialProperty _rimColorProp;
        private MaterialProperty _rimSmoothnessProp;
        private MaterialProperty _rimStrengthProp;
        
        // Outline Pass
        private MaterialProperty _outlineColorProp;
        private MaterialProperty _outlineThicknessProp;
        private MaterialProperty _useColorProp;
        
        
        
        
        #endregion
        
        protected override void OnShaderGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            //Foldout
            _baseFoldOut = GetFoldoutState(materialEditor, Styles.BaseFold.text);
            _cartoonFoldout = GetFoldoutState(materialEditor, Styles.CarToonFold.text);
            _outlineFoldout = GetFoldoutState(materialEditor, Styles.OutlineFold.text);
            
            //Base
            _baseMapProp = FindProperty(PropertyNames.BaseMap, properties, false);
            _baseColorProp = FindProperty(PropertyNames.BaseColor, properties, false);
            
            //Cartoon
            _brightColorProp = FindProperty(PropertyNames.BrightColor, properties, false);
            _middleColoProp = FindProperty(PropertyNames.MiddleColor, properties, false);
            _darkColorProp = FindProperty(PropertyNames.DarkColor, properties, false);
            _celShadeMidPointProp = FindProperty(PropertyNames.CelShadeMidPoint, properties, false);
            _celShadeSmoothnessProp = FindProperty(PropertyNames.CelShadeSmoothness, properties, false);
            _isFaceProp = FindProperty(PropertyNames.IsFace, properties, false);
            _hairShadowDistanceProp = FindProperty(PropertyNames.HairShadowDistance, properties, false);
            _heightCorrectMaxProp = FindProperty(PropertyNames.HeightCorrectMax, properties, false);
            _heightCorrectMinProp = FindProperty(PropertyNames.HeightCorrectMin, properties, false);
            
            //Rim
            _enableRim = FindProperty(PropertyNames.EnableRim, properties, false);
            _rimColorProp = FindProperty(PropertyNames.RimColor, properties, false);
            _rimSmoothnessProp = FindProperty(PropertyNames.RimSmoothness, properties, false);
            _rimStrengthProp = FindProperty(PropertyNames.RimStrength, properties, false);
            
            //Outline
            _outlineColorProp = FindProperty(PropertyNames.OutlineColor, properties, false);
            _outlineThicknessProp = FindProperty(PropertyNames.OutlineThickness, properties, false);
            _useColorProp = FindProperty(PropertyNames.UseColor, properties, false);
            
            DrawProperties(materialEditor);
        }

        #region Properties
        private void DrawProperties(MaterialEditor materialEditor)
        {
            //Base
            {
                DrawFoldout(Styles.BaseFold.text, ref _baseFoldOut, DrawBaseProperties);
            }
            
            //Cartoon
            {
                DrawFoldout(Styles.CarToonFold.text, ref _cartoonFoldout,DrawCartoonProperties);
            }
            
            // Outline
            if (HasPass("Outline"))
            {
                DrawFoldout(Styles.OutlineFold.text, ref _outlineFoldout, DrawOutlineProperties);
            }
        }
               
        private void DrawBaseProperties()
        {
            DrawTextureProperty(_baseMapProp);
            DrawColorProperty(_baseColorProp);
        }
        
        private void DrawCartoonProperties()
        {
            DrawColorProperty(_brightColorProp);
            DrawColorProperty(_middleColoProp);
            DrawColorProperty(_darkColorProp);
            DrawSliderProperty(_celShadeMidPointProp,0,1);
            DrawSliderProperty(_celShadeSmoothnessProp,0,1);

            BeginKeyWordGroup("_IS_FACE", _isFaceProp);
            {
                DrawFloat(_hairShadowDistanceProp);
                DrawFloat(_heightCorrectMaxProp);
                DrawFloat(_heightCorrectMinProp);
            }
            EndKeyWordGroup();

            BeginKeyWordGroup("ENABLE_RIM", _enableRim);
            {
                DrawColorProperty(_rimColorProp);
                DrawSliderProperty(_rimSmoothnessProp);
                DrawSliderProperty(_rimStrengthProp);
            }
            EndKeyWordGroup();
        }
        
        private void DrawOutlineProperties()
        {
            //DrawProperty(materialEditor, m_EnableOutlineProp, PropertyNames.EnableOutline);
            //if (m_EnableOutlineProp.floatValue == 1.0)
            {
                DrawColorProperty(_outlineColorProp);
                DrawSliderProperty(_outlineThicknessProp,0,5);
                DrawKeyword("_USE_VERTEX_COLOR", _useColorProp, PropertyNames.UseColor);
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