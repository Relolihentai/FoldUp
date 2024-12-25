using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BloomRenderFeature : ScriptableRendererFeature
{
    class BloomRenderPass : ScriptableRenderPass
    {
        private static readonly string _bloomTag = "PostProcessing_Bloom";
        private static readonly int TempRT_0 = Shader.PropertyToID("bloomRT_0");
        private Material _bloomMaterial;
        public BloomRenderPass(BloomSettings Settings)
        {
            this.renderPassEvent = Settings.RenderPassEvent;
            this._bloomMaterial = Settings.BloomMaterial;
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(_bloomTag);
            context.ExecuteCommandBuffer(cmd);
            BloomRender(cmd, ref renderingData);
            CommandBufferPool.Release(cmd);
        }

        void BloomRender(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTargetIdentifier source = renderingData.cameraData.renderer.cameraColorTarget;
            ref var cameraData = ref renderingData.cameraData;
            var data = cameraData.cameraTargetDescriptor;
            var width = data.width;
            var height = data.height;
            cmd.GetTemporaryRT(TempRT_0, width, height, 0, FilterMode.Trilinear, RenderTextureFormat.ARGB32);
            cmd.Blit(source, TempRT_0, _bloomMaterial, 0);
            cmd.Blit(TempRT_0, source);
            cmd.ReleaseTemporaryRT(TempRT_0);
        }

    }
    [System.Serializable]
    public class BloomSettings
    {
        public RenderPassEvent RenderPassEvent;
        public Material BloomMaterial;
    }

    public BloomSettings _bloomSettings;
    BloomRenderPass _bloomRenderPass;
    public override void Create()
    {
        _bloomRenderPass = new BloomRenderPass(_bloomSettings);
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_bloomRenderPass);
    }
}


