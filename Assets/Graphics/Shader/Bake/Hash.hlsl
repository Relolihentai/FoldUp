#ifndef HASH_LIB
#define HASH_LIB

float hash11(float p)
{
    p = frac(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}
float hash2to1(float2 p)
{
    float3 p3  = frac(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}
float hash3to1(float3 p3)
{
    p3  = frac(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return frac((p3.x + p3.y) * p3.z);
}
float2 hash1to2(float p)
{
    float3 p3 = frac(float3(p,p,p) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx+p3.yz)*p3.zy);
}
float2 hash22(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return frac((p3.xx+p3.yz)*p3.zy);
}
float2 hash3to2(float3 p3)
{
    p3 = frac(p3 * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx+p3.yz)*p3.zy);
}
float3 hash1to3(float p)
{
    float3 p3 = frac(float3(p,p,p) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return frac((p3.xxy+p3.yzz)*p3.zyx); 
}
float3 hash2to3(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return frac((p3.xxy+p3.yzz)*p3.zyx);
}
float3 hash33(float3 p3)
{
    p3 = frac(p3 * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return frac((p3.xxy + p3.yxx)*p3.zyx);
}
float4 hash1to4(float p)
{
    float4 p4 = frac(float4(p,p,p,p) * float4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);
}
float4 hash2to4(float2 p)
{
    float4 p4 = frac(float4(p.xyxy) * float4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);
}
float4 hash3to4(float3 p)
{
    float4 p4 = frac(float4(p.xyzx)  * float4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);
}
float4 hash44(float4 p4)
{
    p4 = frac(p4  * float4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return frac((p4.xxyz+p4.yzzw)*p4.zywx);
}

float2 otherHash22(float2 param)
{
    return -1 + 2 * frac(sin(float2(dot(param, float2(152.123,125.127)), dot(param, float2(112.123,156.12)))) * 1000);
}

float3 otherHash33(float3 param)
{
    return -1 + 2 * frac(sin(float3(dot(param, float3(152.123, 125.127, 125.315)), dot(param, float3(112.123, 156.12, 169.156)), dot(param, float3(156.15, 147.2, 168.123)))) * 1000);
}
#endif