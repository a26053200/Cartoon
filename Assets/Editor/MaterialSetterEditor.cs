using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace URPToon
{
    /// <summary>
    /// <para>Class Introduce </para>
    /// <para>Author: zhengnan </para>
    /// <para>Create: 2021年09月24日 星期五 22:38 </para>
    /// </summary>
    [CustomEditor(typeof(MaterialSetter))]
    public class MaterialSetterEditor : Editor
    {
        private MaterialSetter _materialSetter;

        private void OnEnable()
        {
            _materialSetter = target as MaterialSetter;
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            if (GUILayout.Button("Set"))
            {
                MeshRenderer[] renderers = _materialSetter.gameObject.GetComponentsInChildren<MeshRenderer>(true);
                for (int i = 0; i < renderers.Length; i++)
                {
                    Material[] materials = renderers[i].sharedMaterials;
                    Material[] newMats = new  Material[materials.Length];
                    for (int j = 0; j < materials.Length; j++)
                    {
                        string matPath = _materialSetter._materialFolder + materials[j].name + ".mat";
                        if (File.Exists(matPath))
                        {
                            newMats[j] = AssetDatabase.LoadAssetAtPath<Material>(matPath);
                        }
                    }
                    renderers[i].sharedMaterials = newMats;
                }
            }
        }
    }
}