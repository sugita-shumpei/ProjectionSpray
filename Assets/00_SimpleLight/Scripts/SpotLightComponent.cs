using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SpotLightComponent : MonoBehaviour
{
    static MaterialPropertyBlock mpb;

    public Renderer targetRenderer;
    public float intensity = 1.0f;
    public Color color = Color.white;
    [Range(0.01f,90.0f)] public float angle = 30.0f;//Spotライトの口径, 広いほど広い範囲まで広がる
    public float range = 10f;//Lightの影響が及ぶ距離
    public Texture cookie;//SpotLightの効果がどのようにかかるかを示す, 例えば
    // Start is called before the first frame update
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        if (targetRenderer == null)
            return;
        if (mpb == null)
            mpb = new MaterialPropertyBlock();
        //Matrix4x4.Perspective(angle,aspect,zNear,zFar)
        var projMatrix = Matrix4x4.Perspective(angle,1.0f,0.0f,range);
        var worldToLightMatrix = transform.worldToLocalMatrix;
        targetRenderer.GetPropertyBlock(mpb);
        mpb.SetVector("_LitPos",transform.position);
        mpb.SetFloat("_Intensity",intensity);
        mpb.SetColor("_LitCol",color);
        mpb.SetMatrix("_WorldToLitMatrix",worldToLightMatrix);
        mpb.SetMatrix("_ProjMatrix",projMatrix);
        mpb.SetTexture("_Cookie",cookie);
        targetRenderer.SetPropertyBlock(mpb);
    }
    private void OnDrawGizmos()
    {
        Gizmos.color = color;
        Gizmos.DrawWireSphere(transform.position,intensity);
    }
}
