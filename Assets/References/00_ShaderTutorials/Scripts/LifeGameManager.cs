using UnityEngine;

public class LifeGameManager : MonoBehaviour
{
    [SerializeField] Material initMaterial;
    [SerializeField] Material execMaterial;
    [SerializeField] Material showMaterial;

    [SerializeField] int isLaunched =  0;
    [SerializeField] RenderTexture[] rts;
    [SerializeField] Renderer targetRenderer;

    int curIdx = 0;
    int curFrameIdx = 0;
    // Start is called before the first frame update
    void Start()
    {
        Debug.Log(RenderTexture.active);
        rts = new RenderTexture[2];

        rts[0] = new RenderTexture(Camera.main.pixelWidth, Camera.main.pixelHeight, 16, RenderTextureFormat.BGRA32);
        rts[0].wrapMode = TextureWrapMode.Clamp;
        rts[0].filterMode = FilterMode.Point;
        rts[0].Create();

        rts[1] = new RenderTexture(Camera.main.pixelWidth, Camera.main.pixelHeight, 16, RenderTextureFormat.BGRA32);
        rts[1].wrapMode = TextureWrapMode.Clamp;
        rts[1].filterMode = FilterMode.Point;
        rts[1].Create();

        {
            var currentRT        = RenderTexture.active;
            RenderTexture.active = rts[0];
            GL.Clear(true, true, Color.black);
            RenderTexture.active = currentRT;
        }

        {
            var currentRT = RenderTexture.active;
            RenderTexture.active = rts[1];
            GL.Clear(true, true, Color.black);
            RenderTexture.active = currentRT;
        }
    }

    // Update is called once per frame
    void Update()
    {
        {
            var currentRT = RenderTexture.active;
            RenderTexture.active = rts[curIdx];
            GL.Clear(true, true, Color.black);
            RenderTexture.active = currentRT;
        }
        if (isLaunched == 0)
        {
            targetRenderer.material = initMaterial;
            initMaterial.mainTexture = rts[1 - curIdx];
        }
        else
        {
            if (curFrameIdx % 10 == 9)
            {
                targetRenderer.material = execMaterial;
                execMaterial.mainTexture = rts[1 - curIdx];
            }
            else
            {
                targetRenderer.material = showMaterial;
                showMaterial.mainTexture = rts[1 - curIdx];
            }
        }
        // Ç¢Ç¡ÇΩÇÒï`âÊèàóùÇé¿çs
        var curRenderTarget       = Camera.main.targetTexture;
        Camera.main.targetTexture = rts[curIdx];
        Camera.main.Render();
        Camera.main.targetTexture = curRenderTarget;
        // çƒï`âÊ
        targetRenderer.material   = showMaterial;
        showMaterial.mainTexture  = rts[curIdx];
        curIdx = 1 - curIdx;
        // 
        curFrameIdx++;
    }

    private void OnDestroy()
    {
        rts[0].Release();
        rts[1].Release();
    }
}
