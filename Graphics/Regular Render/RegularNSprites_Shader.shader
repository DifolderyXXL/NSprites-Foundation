﻿// To access properties data shader uses StructuredBuffer<T> down below

// If you use EachUpdate mode then just access _bufferName[instanceID] (instanceID may be named differently)

// If you use Reactive / Static mode then for such properties you firstly need to obtain instance provided by NSprites system
// to do that you need to access _propertyPointers[instanceID] and use it like it is your actual instance id, so
// any Reactive / Static properties should be accessed like:
// int pointer = _propertyPointers[instanceID];
// float propertyValue _propertyNameBuffer[pointer]; // float type is here just for example

// NOTE: some graphics API have problems with how NSprites updates Reactive / Static properties, if you encountered such situation,
// then try to use only EachUpdate mode and access buffers like it described in first section

Shader "Universal Render Pipeline/2D/SimpleSpriteShaderCustom"
{
    Properties
    {
        _MainTex("_MainTex", 2D) = "white" {}
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    CBUFFER_END
    ENDHLSL

    SubShader
    {
        Tags {"Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" "Queue" = "AlphaTest" "RenderType" = "TransparentCutout"}
            ZTest LEqual    //Default
            // ZTest Less | Greater | GEqual | Equal | NotEqual | Always
            ZWrite On       //Default
            Cull Off

            HLSLPROGRAM
            #pragma vertex UnlitVertex
            #pragma fragment UnlitFragment

            #pragma target 4.5
            //#pragma exclude_renderers gles gles3 glcore
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup

            struct Attributes
            {
                float3 positionOS   : POSITION;
                float2 uv			: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4  positionCS		: SV_POSITION;
                float2	uv				: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
            StructuredBuffer<int> _propertyPointers;
            StructuredBuffer<float4> _uvTilingAndOffsetBuffer;
            StructuredBuffer<float4> _uvAtlasBuffer;
            StructuredBuffer<int2> _sortingDataBuffer; // x layer, y sorting index
            StructuredBuffer<float4x4> _positionBuffer;
            StructuredBuffer<float2> _pivotBuffer;
            StructuredBuffer<float2> _heightWidthBuffer;
            StructuredBuffer<int2> _flipBuffer;
            StructuredBuffer<float4> _colorBuffer;
            
#endif

            // if you use this shader outside from NSprites-Foundation package please make sure you set this global variable
            // x - per-layer offset
            // y - per-sorting-index offset
            float4 _sortingGlobalData;

            float4x4 offset_matrix(const float2 input, const float2 scale)
            {
                return float4x4(
                    scale.x,0,0,scale.x * -input.x,
                    0,scale.y,0,scale.y * -input.y,
                    0,0,1,0,
                    0,0,0,1
                );
            }

            void setup()
            {
#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
                int propertyIndex = _propertyPointers[unity_InstanceID];
                float4x4 transform = _positionBuffer[propertyIndex];
                float2 pivot = _pivotBuffer[propertyIndex];
                float2 scale = _heightWidthBuffer[propertyIndex];
                unity_ObjectToWorld = mul(transform, offset_matrix(pivot, scale));
#endif
            }

            float2 TilingAndOffset(float2 UV, float2 Tiling, float2 Offset)
            {
                return UV * Tiling + Offset;
            }

            float RemapInternal(float value, float fromMin, float fromMax, float toMin, float toMax)
            {
                return toMin + (value - fromMin) * (toMax - toMin) / (fromMax - fromMin);
            }
            
            Varyings UnlitVertex(Attributes attributes, uint instanceID : SV_InstanceID)
            {
                Varyings varyings = (Varyings)0;

#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
                int propertyIndex = _propertyPointers[instanceID];
                float4 uvTilingAndOffset = _uvTilingAndOffsetBuffer[propertyIndex];
                int2 sortingData = _sortingDataBuffer[propertyIndex];
                int2 flipValue = _flipBuffer[propertyIndex];
#else
                float4 uvTilingAndOffset = float4(1, 1, 0, 0);
                int2 sortingData = int2(0, 0);
                int2 flipValue = int2(0, 0);
#endif

                UNITY_SETUP_INSTANCE_ID(attributes);
                UNITY_TRANSFER_INSTANCE_ID(attributes, varyings);

                // flip x/y UVs for mirroring texture
                attributes.uv.x = flipValue.x >= 0 ? attributes.uv.x : (1.0 - attributes.uv.x);
                attributes.uv.y = flipValue.y >= 0 ? attributes.uv.y : (1.0 - attributes.uv.y);

                // change SV_Position to sort instances on screen without changing theirs matrix depth value
                float4 mvp3 = mul (UNITY_MATRIX_MVP, float4(0,0,0,1));
                float2 screenClipSpacePos = mvp3.xy / mvp3.w;
                varyings.positionCS = TransformObjectToHClip(attributes.positionOS);
                
                // here to sort [0..1] to SV_POSITION.z
                // result value should account layer + sorint index + screen pos
                varyings.positionCS.z =
                    sortingData.x * _sortingGlobalData.x                                                                                // layer offset
                    + sortingData.y * _sortingGlobalData.y                                                                              // sorting index offset
                    + _sortingGlobalData.y * saturate(RemapInternal(screenClipSpacePos.y, -1, 1, 0, 1));  // screen y pos offset

                // tiling and offset UV
                varyings.uv = TilingAndOffset(attributes.uv, uvTilingAndOffset.xy, uvTilingAndOffset.zw);

                return varyings;
            }

            
            float4 UnlitFragment(Varyings varyings, uint instanceID : SV_InstanceID) : SV_Target
            {
#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
                int propertyIndex = _propertyPointers[instanceID];
                float4 uvAtlas = _uvAtlasBuffer[propertyIndex];
                float4 color = _colorBuffer[propertyIndex];
#else
                float4 uvAtlas = float4(1, 1, 0, 0);
                float4 color = float4(1,0,0,1);
#endif

                
                // finally frac UV and locate texture on atlas, now our UV is inside actual texture bounds (repeated)
                varyings.uv = TilingAndOffset(frac(varyings.uv), uvAtlas.xy, uvAtlas.zw);

                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, varyings.uv);
                clip(texColor.w - 0.5);
                
                return texColor * color;
            }
            ENDHLSL
        }
    }

    Fallback "Sprites/Default"
}
