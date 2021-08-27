
using System;
using UnityEngine;

/// <summary>
/// <para>脸的朝向 </para>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年08月27日 星期五 16:08 </para>
/// </summary>
[ExecuteInEditMode]
public class FaceDirection : MonoBehaviour
{
    private Material[] _materials;
    private static readonly int FaceFront = Shader.PropertyToID("_FaceFront");
    private static readonly int FaceUp = Shader.PropertyToID("_FaceUp");
    private static readonly int FaceLeft = Shader.PropertyToID("_FaceLeft");
    private static readonly int FaceRight = Shader.PropertyToID("_FaceRight");
    private void Awake()
    {
        MeshRenderer meshRenderer = gameObject.GetComponent<MeshRenderer>();
        _materials = meshRenderer.sharedMaterials;
    }

    private void Update()
    {
        for (int i = 0; i < _materials.Length; i++)
        {
            Material mat = _materials[i];
            mat.SetVector(FaceFront, transform.forward);
            mat.SetVector(FaceUp, transform.up);
            var right = transform.right;
            mat.SetVector(FaceRight, right);
            mat.SetVector(FaceLeft, -right);
        }
    }
}
