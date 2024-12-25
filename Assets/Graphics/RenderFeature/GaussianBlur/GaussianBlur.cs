using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;
public class GaussianBlur : ScriptableRendererFeature
{
    class GaussianBlurRenderPass : ScriptableRenderPass
    {
        private static readonly string render_tag = "Render GaussianBlur";
        //临时索引 用于创建临时的rendertexture
        static readonly int TempTargetId0 = Shader.PropertyToID("_TempTargetColorTint0");
        static readonly int TempTargetId1 = Shader.PropertyToID("_TempTargetColorTint1");
        private GaussianBlurSettings _gaussianSettings;
        
        //filter
        /*private RenderQueueRange _renderQueueRange;     //渲染队列
        private FilteringSettings _filteringSettings;   //渲染过滤
        private RenderStateBlock _renderStateBlock;     //渲染状态
        private SortingCriteria _sortingCriteria;       //渲染顺序*/

        public GaussianBlurRenderPass(GaussianBlurSettings settings)
        {
            this._gaussianSettings = settings;
            this.renderPassEvent = this._gaussianSettings.RenderPassEvent;
        }
        
        //用于定义CommandBuffer并执行
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (_gaussianSettings.GaussianBlurMaterial == null)
            {
                Debug.LogError("GaussianBlur RenderPass '_GaussianBlurMaterial' is null");
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(render_tag);
            //定义cmd
            Render(cmd, ref renderingData);
            //执行cmd
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
        //类似OnRenderIamge
        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var source = renderingData.cameraData.renderer.cameraColorTarget;
            int destination0 = TempTargetId0;
            int destination1 = TempTargetId1;
            ref var cameraData = ref renderingData.cameraData;
            var data = cameraData.cameraTargetDescriptor;
            var width = data.width / _gaussianSettings.downSample;
            var height = data.height / _gaussianSettings.downSample;
            // 先存到临时的地方
            cmd.GetTemporaryRT(destination0, width, height, 0, FilterMode.Trilinear, RenderTextureFormat.ARGB32);
            cmd.Blit(source, destination0);
            for (int i = 0; i < _gaussianSettings.iterations; ++i)
            {
                _gaussianSettings.GaussianBlurMaterial.SetFloat("_BlurSize", 1.0f + i * _gaussianSettings.blurSpread);
                //cmd.SetGlobalFloat("_BlurSize", 1.0f + i * _gaussianSettings.blurSpread.value);
                // 第一轮
                cmd.GetTemporaryRT(destination1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                cmd.Blit(destination0, destination1, _gaussianSettings.GaussianBlurMaterial, 0);
                cmd.ReleaseTemporaryRT(destination0);
                // 第二轮
                cmd.GetTemporaryRT(destination0, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
                cmd.Blit(destination1, destination0, _gaussianSettings.GaussianBlurMaterial, 1);
                cmd.ReleaseTemporaryRT(destination1);
            }
            cmd.Blit(destination0, source);
            cmd.ReleaseTemporaryRT(TempTargetId0);
        }
    }
    
    
    //RenderFeature
    [System.Serializable]
    public class GaussianBlurSettings
    {
        public Material GaussianBlurMaterial;
        public RenderPassEvent RenderPassEvent;

        [Range(0, 4)] public int iterations;
        [Range(0.2f, 3.0f)] public float blurSpread;
        [Range(1, 8)] public int downSample;
    }
    public GaussianBlurSettings _Settings;
    GaussianBlurRenderPass _gaussianBlurRenderPass;
    public override void Create()
    {
        _gaussianBlurRenderPass = new GaussianBlurRenderPass(_Settings);
    }

    //压入pass
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //排队执行pass
        //可排多个pass
        renderer.EnqueuePass(_gaussianBlurRenderPass);
    }
}


