#ifndef NOISE_LIB
#define NOISE_LIB

#include "Hash.hlsl"

float valueNoise(float2 uv)
{
    float2 intPos = floor(uv); //uv晶格化, 取 uv 整数值，相当于晶格id
    float2 fracPos = frac(uv); //取 uv 小数值，相当于晶格内局部坐标，取值区间：(0,1)

    //二维插值权重，一个类似smoothStep的函数，叫Hermit插值函数，也叫S曲线：S(x) = -2 x^3 + 3 x^2
    //利用Hermit插值特性：可以在保证函数输出的基础上保证插值函数的导数在插值点上为0，这样就提供了平滑性
    float2 u = fracPos * fracPos * (3.0 - 2.0 * fracPos); 

    //四方取点，由于intPos是固定的，所以栅格化了（同一晶格内四点值相同，只是小数部分不同拿来插值）
    float va = hash2to1( intPos + float2(0.0, 0.0) );  //hash2to1 二维输入，映射到1维输出
    float vb = hash2to1( intPos + float2(1.0, 0.0) );
    float vc = hash2to1( intPos + float2(0.0, 1.0) );
    float vd = hash2to1( intPos + float2(1.0, 1.0) );

    //lerp的展开形式，完全可以用lerp(a,b,c)嵌套实现
    float k0 = va;
    float k1 = vb - va;
    float k2 = vc - va;
    float k4 = va - vb - vc + vd;
    float value = k0 + k1 * u.x + k2 * u.y + k4 * u.x * u.y;

    return value;
}

float perlinNoise(float2 uv)
{
    float2 intPos = floor(uv);
    float2 fracPos = frac(uv);

    float2 u = fracPos * fracPos * (3.0 - 2.0 * fracPos); 

    float2 ga = hash22(intPos + float2(0.0,0.0)); //四角hash向量
    float2 gb = hash22(intPos + float2(1.0,0.0));
    float2 gc = hash22(intPos + float2(0.0,1.0));
    float2 gd = hash22(intPos + float2(1.0,1.0));

    float va = dot(ga, fracPos - float2(0.0,0.0)); //方向向量、点积
    float vb = dot(gb, fracPos - float2(1.0,0.0));
    float vc = dot(gc, fracPos - float2(0.0,1.0));
    float vd = dot(gd, fracPos - float2(1.0,1.0));

    float value = va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * (va - vb - vc + vd); //插值

    return value;
}

float simpleNoise(float2 uv)
{
    //transform from triangle to quad
    const float K1 = 0.366025404; // (sqrt(3)-1)/2; //quad 转 2个正三角形 的公式参数
    //transform from quad to triangle
    const float K2 = 0.211324865; // (3 - sqrt(3))/6;

    float2 quadIntPos = floor(uv + (uv.x + uv.y)*K1);
    float2 vecFromA = uv - quadIntPos + (quadIntPos.x + quadIntPos.y) * K2;

    float IsLeftHalf = step(vecFromA.y,vecFromA.x);  //判断左右
    float2  quadVertexOffset = float2(IsLeftHalf,1.0 - IsLeftHalf);

    float2  vecFromB = vecFromA - quadVertexOffset + K2;
    float2  vecFromC = vecFromA - 1.0 + 2.0 * K2;

    //衰减计算
    float3  falloff = max(0.5 - float3(dot(vecFromA,vecFromA), dot(vecFromB,vecFromB), dot(vecFromC,vecFromC)), 0.0);

    float2 ga = hash22(quadIntPos + 0.0);
    float2 gb = hash22(quadIntPos + quadVertexOffset);
    float2 gc = hash22(quadIntPos + 1.0);

    float3 simplexGradient = float3(dot(vecFromA,ga), dot(vecFromB,gb), dot(vecFromC, gc));
    float3 n = falloff * falloff * falloff * falloff * simplexGradient;
    return dot(n, float3(70,70,70));
}

float voronoiNoise(float2 uv, float pixelThreshold)
{
    float dist = 1;
    float2 intPos = floor(uv);
    //float2 fracPos = frac(uv);
    //像素化
    float2 fracPos = floor(frac(uv) * pixelThreshold) / pixelThreshold;

    for(int x = -1; x <= 1; x++) //3x3九宫格采样
        {
            for(int y = -1; y <= 1; y++)
            {
                float2 offset = float2(x, y);
                float2 indexPoint = intPos + offset;
                //二方连续
                if (indexPoint.x >= 13) indexPoint.x -= 15;
                if (indexPoint.y >= 13) indexPoint.y -= 15;
                float2 points = otherHash22(indexPoint);
                float allThreshold = smoothstep(1, 150, pixelThreshold);
                points = sin(max(_Time.y * allThreshold * 2, _Time.y / 3) + 6.2831 * points) * 0.5 + 0.5;
                dist = min(dist, floor(length(offset + points - fracPos) * 5) / 5);
            }
        }
    return dist;
}

#endif