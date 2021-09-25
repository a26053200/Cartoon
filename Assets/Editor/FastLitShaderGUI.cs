using System;
using UnityEditor;
using UnityEngine;

namespace URPToon
{
    public class FastLitShaderGUI : BaseShaderGUI
    {
        #region Structs

        private struct Styles
        {
            // Foldouts
            public static readonly GUIContent BaseFold = new GUIContent("Base");
            public static readonly GUIContent PBRFold = new GUIContent("PBR");
            public static readonly GUIContent RimFold = new GUIContent("Rim");
            public static readonly GUIContent OutlineFold = new GUIContent("Outline");//Pass
            
            //CheckMark
            public static readonly string IsFace = "_IsFace";
        }
        
        private struct Keywords
        {
            public static readonly string _UseSpecularMode = "_UseSpecularMode";
            public static readonly string _UsePBRMap = "_UsePBRMap";
            public static readonly string _UseFade = "_UseFade";
            public static readonly string _UseCutoff = "_UseCutoff";
            public static readonly string _UseAlpha = "_UseAlpha";
            public static readonly string _ReceiveShadow = "_ReceiveShadow";
            public static readonly string _EnableAdvanced = "_EnableAdvanced";
            public static readonly string _UseSSS = "_UseSSS";
            public static readonly string _UseAnisotropic = "_UseAnisotropic";
            public static readonly string _UseRimLight = "_UseRimLight";
        }
        
        private struct PropertyNames
        {
            //Base
            public static readonly string BaseMap = "_BaseMap";
            public static readonly string BaseColor = "_BaseColor";
            public static readonly string BumpMap = "_BumpMap";
            public static readonly string MaskMap = "_MaskMap";
            public static readonly string MetallicGlossMap = "_MetallicGlossMap";
            public static readonly string SpecGlossMap = "_SpecGlossMap";
            
            //Cutoff
            public static readonly string Fade = "_Fade";
            
            //Cutoff
            public static readonly string Cutoff = "_Cutoff";
            
            //Alpha
            public static readonly string Alpha = "_Alpha";
            
            //Advanced
            public static readonly string Diffuse = "_Diffuse";
            public static readonly string Specular = "_Specular";
            public static readonly string Sheen = "_Sheen";
            public static readonly string SSAO = "_SSAO";
            public static readonly string ShadowAttenuation = "_ShadowAttenuation";
            
            //PBR
            public static readonly string Occlusion = "_Occlusion";
            public static readonly string Metallic = "_Metallic";
            public static readonly string SpecularColor = "_SpecularColor";
            public static readonly string Smoothness = "_Smoothness";
            
            //SSS
            public static readonly string Subsurface = "_Subsurface";
            public static readonly string SubsurfaceRange = "_SubsurfaceRange";
            public static readonly string SSSPower = "_SSSPower";
            public static readonly string SSSOffset = "_SSSOffset";
            public static readonly string SSSColor = "_SSSColor";
            public static readonly string CurveFactor = "_CurveFactor";
            public static readonly string SSSLUT = "_SSSLUT";
            
            //Anisotropic
            public static readonly string Anisotropic = "_Anisotropic";
            public static readonly string Gloss = "_Gloss";
            public static readonly string Shift = "_Shift";
            public static readonly string ShiftTex = "_ShiftTex";
            
            //Rim Light
            public static readonly string RimStrength = "_RimStrength";
            public static readonly string RimFresnelMask = "_RimFresnelMask";
            public static readonly string RimColor = "_RimColor";
            
            //Outline
            public static readonly string OutlineColor = "_OutlineColor";
            public static readonly string OutlineThickness = "_OutlineThickness";
            public static readonly string UseColor = "_UseColor";
        }

        #endregion

        
        #region Fields
        
        private bool _baseFoldOut;
        private bool _pbrFoldout;
        private bool _rimFoldout;
        private bool _outlineFoldout;
        
        private MaterialProperty _useSpecularModeProp;
        private MaterialProperty _usePBRMapProp;
        
        // Base
        private MaterialProperty _baseMapProp;
        private MaterialProperty _bumpMapProp;
        private MaterialProperty _maskMapProp;
        private MaterialProperty _metallicGlossMapProp;
        private MaterialProperty _specGlossMapProp;
        private MaterialProperty _baseColorProp;
        
        // Fade
        private MaterialProperty _useFadeProp;
        private MaterialProperty _fadeProp;
        
        // Cutoff
        private MaterialProperty _useCutoffProp;
        private MaterialProperty _cutoffProp;
        
        // Alpha
        private MaterialProperty _useAlphaProp;
        private MaterialProperty _alphaProp;
        
        // Advanced
        private MaterialProperty _enableAdvancedProp;
        private MaterialProperty _diffuseProp;
        private MaterialProperty _specularProp;
        private MaterialProperty _sheenProp;
        private MaterialProperty _SSAOProp;
        private MaterialProperty _shadowAttenuationProp;
        
        // PBR
        private MaterialProperty _receiveShadowProp;
        private MaterialProperty _occlusionProp;
        private MaterialProperty _specularColorProp;
        private MaterialProperty _metallicProp;
        private MaterialProperty _smoothnessProp;
        
        // SSS
        private MaterialProperty _useSSSProp;
        private MaterialProperty _subsurfaceProp;
        private MaterialProperty _subsurfaceRangeProp;
        private MaterialProperty _SSSPowerProp;
        private MaterialProperty _SSSOffsetProp;
        private MaterialProperty _SSSColorProp;
        private MaterialProperty _SSSLUTProp;
        private MaterialProperty _CurveFactorProp;
        
        // Anisotropic
        private MaterialProperty _useAnisotropicProp;
        private MaterialProperty _anisotropicProp;
        private MaterialProperty _glossProp;
        private MaterialProperty _shiftProp;
        private MaterialProperty _shiftTexProp;
        
        // Anisotropic
        private MaterialProperty _useRimLightProp;
        private MaterialProperty _rimStrengthProp;
        private MaterialProperty _rimFresnelMaskProp;
        private MaterialProperty _rimColorProp;
        
        #endregion
        
        protected override void OnShaderGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            _useSpecularModeProp = FindProperty(Keywords._UseSpecularMode, properties, false);
            _usePBRMapProp = FindProperty(Keywords._UsePBRMap, properties, false);
            
            //Foldout
            _baseFoldOut = GetFoldoutState(materialEditor, Styles.BaseFold.text);
            _pbrFoldout = GetFoldoutState(materialEditor, Styles.PBRFold.text);
            _rimFoldout = GetFoldoutState(materialEditor, Styles.RimFold.text);
            _outlineFoldout = GetFoldoutState(materialEditor, Styles.OutlineFold.text);
            
            // Base
            _baseMapProp = FindProperty(PropertyNames.BaseMap, properties, false);
            _bumpMapProp = FindProperty(PropertyNames.BumpMap, properties, false);
            _maskMapProp = FindProperty(PropertyNames.MaskMap, properties, false);
            _metallicGlossMapProp = FindProperty(PropertyNames.MetallicGlossMap, properties, false);
            _specGlossMapProp = FindProperty(PropertyNames.SpecGlossMap, properties, false);
            _baseColorProp = FindProperty(PropertyNames.BaseColor, properties, false);
            
            // Fade
            _useFadeProp = FindProperty(Keywords._UseFade, properties, false);
            _fadeProp = FindProperty(PropertyNames.Fade, properties, false);
            
            //Cutoff
            _useCutoffProp = FindProperty(Keywords._UseCutoff, properties, false);
            _cutoffProp = FindProperty(PropertyNames.Cutoff, properties, false);
            
            //Alpha
            _useAlphaProp = FindProperty(Keywords._UseAlpha, properties, false);
            _alphaProp = FindProperty(PropertyNames.Alpha, properties, false);
            
            //Advanced
            _enableAdvancedProp = FindProperty(Keywords._EnableAdvanced, properties, false);
            _diffuseProp = FindProperty(PropertyNames.Diffuse, properties, false);
            _specularProp = FindProperty(PropertyNames.Specular, properties, false);
            _sheenProp = FindProperty(PropertyNames.Sheen, properties, false);
            _SSAOProp = FindProperty(PropertyNames.SSAO, properties, false);
            _shadowAttenuationProp = FindProperty(PropertyNames.ShadowAttenuation, properties, false);
            
            //PBR
            _receiveShadowProp = FindProperty(Keywords._ReceiveShadow, properties, false);
            _occlusionProp = FindProperty(PropertyNames.Occlusion, properties, false);
            _metallicProp = FindProperty(PropertyNames.Metallic, properties, false);
            _specularColorProp = FindProperty(PropertyNames.SpecularColor, properties, false);
            _smoothnessProp = FindProperty(PropertyNames.Smoothness, properties, false);
            
            //SSS
            _useSSSProp = FindProperty(Keywords._UseSSS, properties, false);
            _subsurfaceProp = FindProperty(PropertyNames.Subsurface, properties, false);
            _subsurfaceRangeProp = FindProperty(PropertyNames.SubsurfaceRange, properties, false);
            _SSSPowerProp = FindProperty(PropertyNames.SSSPower, properties, false);
            _SSSOffsetProp = FindProperty(PropertyNames.SSSOffset, properties, false);
            _SSSColorProp = FindProperty(PropertyNames.SSSColor, properties, false);
            _CurveFactorProp = FindProperty(PropertyNames.CurveFactor, properties, false);
            _SSSLUTProp = FindProperty(PropertyNames.SSSLUT, properties, false);
            
            //Anisotropic
            _useAnisotropicProp = FindProperty(Keywords._UseAnisotropic, properties, false);
            _anisotropicProp = FindProperty(PropertyNames.Anisotropic, properties, false);
            _glossProp = FindProperty(PropertyNames.Gloss, properties, false);
            _shiftProp = FindProperty(PropertyNames.Shift, properties, false);
            _shiftTexProp = FindProperty(PropertyNames.ShiftTex, properties, false);
            
            //RimLight
            _useRimLightProp = FindProperty(Keywords._UseRimLight, properties, false);
            _rimStrengthProp = FindProperty(PropertyNames.RimStrength, properties, false);
            _rimFresnelMaskProp = FindProperty(PropertyNames.RimFresnelMask, properties, false);
            _rimColorProp = FindProperty(PropertyNames.RimColor, properties, false);
            
            DrawProperties();
        }

        #region Properties

        public override void MaterialChanged(Material material)
        {
            
        }
        
        private void DrawProperties()
        {
            DrawKeyword(Keywords._UseSpecularMode, _useSpecularModeProp);
            DrawKeyword(Keywords._UsePBRMap, _usePBRMapProp);
            
            //DrawFoldout(Styles.BaseFold.text, ref _baseFoldOut, DrawBaseProperties);
            DrawBaseProperties();
            //DrawFoldout(Styles.PBRFold.text, ref _pbrFoldout, DrawPBRProperties);
            DrawPBRProperties();
            DrawRimLightProperties();
        }
        
        private void DrawBaseProperties()
        {
            //Fade
            {
                if(BeginKeyWordGroup(Keywords._UseFade, _useFadeProp))
                {
                    DrawSliderProperty(_fadeProp);
                }
                EndKeyWordGroup();
            }
            
            //Cutoff
            {
                if(BeginKeyWordGroup(Keywords._UseCutoff, _useCutoffProp))
                {
                    DrawSliderProperty(_cutoffProp);
                }
                EndKeyWordGroup();
            }
            
            // Alpha
            {
                if(BeginKeyWordGroup(Keywords._UseAlpha, _useAlphaProp))
                {
                    DrawSliderProperty(_alphaProp);
                }
                EndKeyWordGroup();
            }
            //Base
            {
                DrawColorProperty(_baseColorProp);
                DrawTextureProperty(_baseMapProp);
                DrawTextureProperty(_bumpMapProp);
                if (IsKeywordEnable(_usePBRMapProp))
                {
                    DrawTextureProperty(_metallicGlossMapProp);
                    DrawTextureProperty(_specGlossMapProp);
                }
                else
                    DrawTextureProperty(_maskMapProp);
                
            }
        }
        
        private void DrawPBRProperties()
        {
            
            DrawKeyword(Keywords._ReceiveShadow, _receiveShadowProp);
            // Advanced
            {
                if(BeginKeyWordGroup(Keywords._EnableAdvanced, _enableAdvancedProp))
                {
                    DrawSliderProperty(_diffuseProp);
                    DrawSliderProperty(_specularProp);
                    DrawSliderProperty(_sheenProp);
                    DrawSliderProperty(_SSAOProp);
                    DrawSliderProperty(_shadowAttenuationProp);
                    EditorGUILayout.Space();
                }
                EndKeyWordGroup();
            }
            
            // PBR
            {
                DrawSliderProperty(_occlusionProp);
                
                if (IsKeywordEnable(_useSpecularModeProp))
                    DrawColorProperty(_specularColorProp);
                else
                    DrawSliderProperty(_metallicProp);
                
                DrawSliderProperty(_smoothnessProp);
            }
            
            EditorGUILayout.Space();
            // SSS
            {
                if(BeginKeyWordGroup(Keywords._UseSSS, _useSSSProp))
                {
                    DrawColorProperty(_SSSColorProp);
                    DrawSliderProperty(_subsurfaceProp);
                    DrawSliderProperty(_subsurfaceRangeProp);
                    DrawSliderProperty(_SSSPowerProp);
                    DrawSliderProperty(_SSSOffsetProp);
                    DrawSliderProperty(_CurveFactorProp);
                    DrawTextureProperty(_SSSLUTProp);
                    EditorGUILayout.Space();
                }
                EndKeyWordGroup();
            }
            
            // Anisotropic
            {
                if(BeginKeyWordGroup(Keywords._UseAnisotropic, _useAnisotropicProp))
                {
                    DrawTextureProperty(_shiftTexProp, null, false);
                    DrawSliderProperty(_anisotropicProp);
                    DrawSliderProperty(_glossProp);
                    DrawSliderProperty(_shiftProp);
                    EditorGUILayout.Space();
                }
                EndKeyWordGroup();
            }
        }

        private void DrawRimLightProperties()
        {
            if(BeginKeyWordGroup(Keywords._UseRimLight, _useRimLightProp))
            {
                DrawColorProperty(_rimColorProp);
                DrawSliderProperty(_rimFresnelMaskProp);
                DrawSliderProperty(_rimStrengthProp);
                EditorGUILayout.Space();
            }
            EndKeyWordGroup();
        }

        #endregion
    }
}