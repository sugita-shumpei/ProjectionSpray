using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PointLightComponent : MonoBehaviour
{
    static MaterialPropertyBlock mpb;

    public Renderer targetRenderer;
    public float intensity = 1.0f;
    public Color color = Color.white;
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
        
        targetRenderer.GetPropertyBlock(mpb);
        mpb.SetVector("_LitPos",transform.position);
        mpb.SetFloat("_Intensity",intensity);
        mpb.SetColor("_LitCol",color);
        targetRenderer.SetPropertyBlock(mpb);
    }
    private void OnDrawGizmos()
    {
        Gizmos.color = color;
        Gizmos.DrawWireSphere(transform.position,intensity);
    }
}
