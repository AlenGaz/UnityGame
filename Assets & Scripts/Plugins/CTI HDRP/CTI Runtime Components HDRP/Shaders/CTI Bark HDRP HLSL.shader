/*
NOTES
- disable batching added
- custom dithering for shadow caster pass added
*/

Shader "CTI HDRP/Bark HLSL"
{
    Properties
    {
        [NoScaleOffset]_MainTex("Albedo (RGB) Smoothness (A)", 2D) = "white" {}
        [NoScaleOffset]_BumpSpecAOMap("Normal Map (GA) AO (B)", 2D) = "white" {}
        _NormalStrength("Normal Strength", Float) = 1
        _Smoothness("Smoothness", Range(0, 1)) = 1
        _WindMultipliers("Wind Multipliers", Vector) = (1, 1, 1, 0)
        [HideInInspector]_EmissionColor("Color", Color) = (1, 1, 1, 1)
        [HideInInspector]_RenderQueueType("Vector1", Float) = 1
        [HideInInspector]_StencilRef("Vector1", Int) = 0
        [HideInInspector]_StencilWriteMask("Vector1", Int) = 3
        [HideInInspector]_StencilRefDepth("Vector1", Int) = 0
        [HideInInspector]_StencilWriteMaskDepth("Vector1", Int) = 32
        [HideInInspector]_StencilRefMV("Vector1", Int) = 128
        [HideInInspector]_StencilWriteMaskMV("Vector1", Int) = 128
        [HideInInspector]_StencilRefDistortionVec("Vector1", Int) = 64
        [HideInInspector]_StencilWriteMaskDistortionVec("Vector1", Int) = 64
        [HideInInspector]_StencilWriteMaskGBuffer("Vector1", Int) = 3
        [HideInInspector]_StencilRefGBuffer("Vector1", Int) = 2
        [HideInInspector]_ZTestGBuffer("Vector1", Int) = 4
        [HideInInspector][ToggleUI]_RequireSplitLighting("Boolean", Float) = 0
        [HideInInspector][ToggleUI]_ReceivesSSR("Boolean", Float) = 0
        [HideInInspector]_SurfaceType("Vector1", Float) = 0
        [HideInInspector]_BlendMode("Vector1", Float) = 0
        [HideInInspector]_SrcBlend("Vector1", Float) = 1
        [HideInInspector]_DstBlend("Vector1", Float) = 0
        [HideInInspector]_AlphaSrcBlend("Vector1", Float) = 1
        [HideInInspector]_AlphaDstBlend("Vector1", Float) = 0
        [HideInInspector][ToggleUI]_ZWrite("Boolean", Float) = 0
        [HideInInspector]_CullMode("Vector1", Float) = 2
        [HideInInspector]_TransparentSortPriority("Vector1", Int) = 0
        [HideInInspector]_CullModeForward("Vector1", Float) = 2
        [HideInInspector][Enum(Front, 1, Back, 2)]_TransparentCullMode("Vector1", Float) = 2
        [HideInInspector]_ZTestDepthEqualForOpaque("Vector1", Int) = 4
        [HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)]_ZTestTransparent("Vector1", Float) = 4
        [HideInInspector][ToggleUI]_TransparentBackfaceEnable("Boolean", Float) = 0
        [HideInInspector][ToggleUI]_AlphaCutoffEnable("Boolean", Float) = 0
        [HideInInspector][ToggleUI]_UseShadowThreshold("Boolean", Float) = 0
        [HideInInspector][ToggleUI]_DoubleSidedEnable("Boolean", Float) = 0
        [HideInInspector][Enum(Flip, 0, Mirror, 1, None, 2)]_DoubleSidedNormalMode("Vector1", Float) = 2
        [HideInInspector]_DoubleSidedConstants("Vector4", Vector) = (1, 1, -1, 0)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="HDRenderPipeline"
            "RenderType"="HDLitShader"
            "Queue" = "Geometry"
        }
        
        Pass
        {
            // based on HDLitPass.template
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
        
            //-------------------------------------------------------------------------------------
            // Render Modes (Blend, Cull, ZTest, Stencil, etc)
            //-------------------------------------------------------------------------------------
            
            Cull [_CullMode]
            ZWrite On
            ZClip [_ZClip]
            ColorMask 0
        
            //-------------------------------------------------------------------------------------
            // End Render Modes
            //-------------------------------------------------------------------------------------
        
            HLSLPROGRAM
        
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //#pragma enable_d3d11_debug_symbols
        
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
        
            #pragma multi_compile _ LOD_FADE_CROSSFADE
        
            // #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _DOUBLESIDED_ON
            // #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
        
            //-------------------------------------------------------------------------------------
            // Variant Definitions (active field translations to HDRP defines)
            //-------------------------------------------------------------------------------------
            // #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING 1
            // #define _MATERIAL_FEATURE_TRANSMISSION 1
            // #define _MATERIAL_FEATURE_ANISOTROPY 1
            // #define _MATERIAL_FEATURE_IRIDESCENCE 1
            // #define _MATERIAL_FEATURE_SPECULAR_COLOR 1
            // #define _ENABLE_FOG_ON_TRANSPARENT 1
            #define _AMBIENT_OCCLUSION 1
            #define _SPECULAR_OCCLUSION_FROM_AO 1
            // #define _SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL 1
            // #define _SPECULAR_OCCLUSION_CUSTOM 1
            #define _ENERGY_CONSERVING_SPECULAR 1
            // #define _ENABLE_GEOMETRIC_SPECULAR_AA 1
            // #define _HAS_REFRACTION 1
            // #define _REFRACTION_PLANE 1
            // #define _REFRACTION_SPHERE 1
            // #define _DISABLE_DECALS 1
            #define _DISABLE_SSR 1
            // #define _ADD_PRECOMPUTED_VELOCITY
            // #define _WRITE_TRANSPARENT_MOTION_VECTOR 1
            // #define _DEPTHOFFSET_ON 1
            // #define _BLENDMODE_PRESERVE_SPECULAR_LIGHTING 1
        
            //-------------------------------------------------------------------------------------
            // End Variant Definitions
            //-------------------------------------------------------------------------------------
        
            #pragma vertex Vert
            #pragma fragment Frag
        
            // If we use subsurface scattering, enable output split lighting (for forward pass)
            #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
            #define OUTPUT_SPLIT_LIGHTING
            #endif
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
        
            // define FragInputs structure
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
        
            //-------------------------------------------------------------------------------------
            // Defines
            //-------------------------------------------------------------------------------------
                    #define SHADERPASS SHADERPASS_SHADOWS
                #define RAYTRACING_SHADER_GRAPH_HIGH
                // ACTIVE FIELDS:
                //   Material.Standard
                //   DisableSSR
                //   Specular.EnergyConserving
                //   SurfaceDescriptionInputs.TangentSpaceNormal
                //   VertexDescriptionInputs.VertexColor
                //   VertexDescriptionInputs.ObjectSpaceNormal
                //   VertexDescriptionInputs.ObjectSpaceTangent
                //   VertexDescriptionInputs.ObjectSpacePosition
                //   VertexDescriptionInputs.uv1
                //   VertexDescriptionInputs.uv2
                //   SurfaceDescription.Alpha
                //   features.modifyMesh
                //   VertexDescription.VertexPosition
                //   VertexDescription.VertexNormal
                //   VertexDescription.VertexTangent
                //   AttributesMesh.color
                //   AttributesMesh.normalOS
                //   AttributesMesh.tangentOS
                //   AttributesMesh.positionOS
                //   AttributesMesh.uv1
                //   AttributesMesh.uv2
                // Shared Graph Keywords
        
            // this translates the new dependency tracker into the old preprocessor definitions for the existing HDRP shader code
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            // #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            // #define ATTRIBUTES_NEED_TEXCOORD3
            #define ATTRIBUTES_NEED_COLOR
            // #define VARYINGS_NEED_POSITION_WS
            // #define VARYINGS_NEED_TANGENT_TO_WORLD
            // #define VARYINGS_NEED_TEXCOORD0
            // #define VARYINGS_NEED_TEXCOORD1
            // #define VARYINGS_NEED_TEXCOORD2
            // #define VARYINGS_NEED_TEXCOORD3
            // #define VARYINGS_NEED_COLOR
            // #define VARYINGS_NEED_CULLFACE
            #define HAVE_MESH_MODIFICATION
        
        // We need isFontFace when using double sided
        #if defined(_DOUBLESIDED_ON) && !defined(VARYINGS_NEED_CULLFACE)
            #define VARYINGS_NEED_CULLFACE
        #endif
        
            //-------------------------------------------------------------------------------------
            // End Defines
            //-------------------------------------------------------------------------------------
            
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
        
        #if (SHADERPASS == SHADERPASS_FORWARD)
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        
            #define HAS_LIGHTLOOP
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"
        #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDecalData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"
        
            // Used by SceneSelectionPass
            int _ObjectId;
            int _PassValue;
        
            //-------------------------------------------------------------------------------------
            // Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
            // Generated Type: AttributesMesh
            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL; // optional
                float4 tangentOS : TANGENT; // optional
                float4 uv1 : TEXCOORD1; // optional
                float4 uv2 : TEXCOORD2; // optional
                float4 color : COLOR; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            // Generated Type: VaryingsMeshToPS
            struct VaryingsMeshToPS
            {
                float4 positionCS : SV_Position;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif // defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            };
            
            // Generated Type: PackedVaryingsMeshToPS
            struct PackedVaryingsMeshToPS
            {
                float4 positionCS : SV_Position; // unpacked
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC; // unpacked
                #endif // conditional
            };
            
            // Packed Type: VaryingsMeshToPS
            PackedVaryingsMeshToPS PackVaryingsMeshToPS(VaryingsMeshToPS input)
            {
                PackedVaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToPS
            VaryingsMeshToPS UnpackVaryingsMeshToPS(PackedVaryingsMeshToPS input)
            {
                VaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            // Generated Type: VaryingsMeshToDS
            struct VaryingsMeshToDS
            {
                float3 positionRWS;
                float3 normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            
            // Generated Type: PackedVaryingsMeshToDS
            struct PackedVaryingsMeshToDS
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
            };
            
            // Packed Type: VaryingsMeshToDS
            PackedVaryingsMeshToDS PackVaryingsMeshToDS(VaryingsMeshToDS input)
            {
                PackedVaryingsMeshToDS output;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToDS
            VaryingsMeshToDS UnpackVaryingsMeshToDS(PackedVaryingsMeshToDS input)
            {
                VaryingsMeshToDS output;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            //-------------------------------------------------------------------------------------
            // End Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
        
            //-------------------------------------------------------------------------------------
            // Graph generated code
            //-------------------------------------------------------------------------------------
                    // Shared Graph Properties (uniform inputs)
                    CBUFFER_START(UnityPerMaterial)
                    float _NormalStrength; float _Smoothness;
                    float3 _WindMultipliers;
                    float4 _EmissionColor;
                    float _RenderQueueType;
                    float _StencilRef;
                    float _StencilWriteMask;
                    float _StencilRefDepth;
                    float _StencilWriteMaskDepth;
                    float _StencilRefMV;
                    float _StencilWriteMaskMV;
                    float _StencilRefDistortionVec;
                    float _StencilWriteMaskDistortionVec;
                    float _StencilWriteMaskGBuffer;
                    float _StencilRefGBuffer;
                    float _ZTestGBuffer;
                    float _RequireSplitLighting;
                    float _ReceivesSSR;
                    float _SurfaceType;
                    float _BlendMode;
                    float _SrcBlend;
                    float _DstBlend;
                    float _AlphaSrcBlend;
                    float _AlphaDstBlend;
                    float _ZWrite;
                    float _CullMode;
                    float _TransparentSortPriority;
                    float _CullModeForward;
                    float _TransparentCullMode;
                    float _ZTestDepthEqualForOpaque;
                    float _ZTestTransparent;
                    float _TransparentBackfaceEnable;
                    float _AlphaCutoffEnable;
                    float _UseShadowThreshold;
                    float _DoubleSidedEnable;
                    float _DoubleSidedNormalMode;
                    float4 _DoubleSidedConstants;
                    CBUFFER_END
                    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;
                    TEXTURE2D(_BumpSpecAOMap); SAMPLER(sampler_BumpSpecAOMap); float4 _BumpSpecAOMap_TexelSize;
                
                // Vertex Graph Inputs
                    struct VertexDescriptionInputs
                    {
                        float3 ObjectSpaceNormal; // optional
                        float3 ObjectSpaceTangent; // optional
                        float3 ObjectSpacePosition; // optional
                        float4 uv1; // optional
                        float4 uv2; // optional
                        float4 VertexColor; // optional
                    };
                // Vertex Graph Outputs
                    struct VertexDescription
                    {
                        float3 VertexPosition;
                        float3 VertexNormal;
                        float3 VertexTangent;
                    };
                    
                // Pixel Graph Inputs
                    struct SurfaceDescriptionInputs
                    {
                        float3 TangentSpaceNormal; // optional
                    };
                // Pixel Graph Outputs
                    struct SurfaceDescription
                    {
                        float Alpha;
                    };
                    
                // Shared Graph Node Functions
                
                    // dcd3c055367822a77956a73ac0a83c36
                    #include "/Includes/CTI_HDRP_Wind.hlsl"
                
                    struct Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8
                    {
                        float3 ObjectSpaceNormal;
                        float3 ObjectSpacePosition;
                        float4 VertexColor;
                        half4 uv1;
                        half4 uv2;
                    };
                
                    void SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(float Vector1_5B3F28E6, float Vector1_39544515, float Vector1_E70341A3, float Vector1_D355D6, float3 Vector3_D146D8D7, float Boolean_BA69BFA3, Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 IN, out float3 Position_1, out float3 Normal_2, out float ColorVariation_3)
                    {
                        float4 _UV_681BEC06_Out_0 = IN.uv1;
                        float4 _UV_5EAEC7D4_Out_0 = IN.uv2;
                        float _Property_66DDE654_Out_0 = Vector1_5B3F28E6;
                        float _Property_F63DDA84_Out_0 = Vector1_39544515;
                        float _Property_32CC05D1_Out_0 = Vector1_E70341A3;
                        float _Property_550822E2_Out_0 = Vector1_D355D6;
                        float3 _Property_9A8CF22B_Out_0 = Vector3_D146D8D7;
                        float _Property_7647AB6A_Out_0 = Boolean_BA69BFA3;
                        float3 _CustomFunction_4DA71B86_position1_10;
                        float3 _CustomFunction_4DA71B86_normal1_11;
                        float _CustomFunction_4DA71B86_color_12;
                        ApplyCTIWind_float(IN.ObjectSpacePosition, IN.VertexColor, (_UV_681BEC06_Out_0.xy), (_UV_5EAEC7D4_Out_0.xy), IN.ObjectSpaceNormal, _Property_66DDE654_Out_0, _Property_F63DDA84_Out_0, _Property_32CC05D1_Out_0, _Property_550822E2_Out_0, _Property_9A8CF22B_Out_0, _Property_7647AB6A_Out_0, _CustomFunction_4DA71B86_position1_10, _CustomFunction_4DA71B86_normal1_11, _CustomFunction_4DA71B86_color_12);
                        Position_1 = _CustomFunction_4DA71B86_position1_10;
                        Normal_2 = _CustomFunction_4DA71B86_normal1_11;
                        ColorVariation_3 = _CustomFunction_4DA71B86_color_12;
                    }
                
                // Vertex Graph Evaluation
                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        float3 _Property_EC5ABF14_Out_0 = _WindMultipliers;
                        Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 _CTIWind_89A09B02;
                        _CTIWind_89A09B02.ObjectSpaceNormal = IN.ObjectSpaceNormal;
                        _CTIWind_89A09B02.ObjectSpacePosition = IN.ObjectSpacePosition;
                        _CTIWind_89A09B02.VertexColor = IN.VertexColor;
                        _CTIWind_89A09B02.uv1 = IN.uv1;
                        _CTIWind_89A09B02.uv2 = IN.uv2;
                        float3 _CTIWind_89A09B02_Position_1;
                        float3 _CTIWind_89A09B02_Normal_2;
                        float _CTIWind_89A09B02_ColorVariation_3;
                        SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(0, 0, 0, 0, _Property_EC5ABF14_Out_0, 1, _CTIWind_89A09B02, _CTIWind_89A09B02_Position_1, _CTIWind_89A09B02_Normal_2, _CTIWind_89A09B02_ColorVariation_3);
                        description.VertexPosition = _CTIWind_89A09B02_Position_1;
                        description.VertexNormal = IN.ObjectSpaceNormal;
                        description.VertexTangent = IN.ObjectSpaceTangent;
                        return description;
                    }
                    
                // Pixel Graph Evaluation
                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        surface.Alpha = 1;
                        return surface;
                    }
                    
            //-------------------------------------------------------------------------------------
            // End graph generated code
            //-------------------------------------------------------------------------------------
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
            
            VertexDescriptionInputs AttributesMeshToVertexDescriptionInputs(AttributesMesh input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                // output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                // output.ViewSpaceNormal =             TransformWorldToViewDir(output.WorldSpaceNormal);
                // output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                output.ObjectSpaceTangent =          input.tangentOS.xyz;
                // output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
                // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                // output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
                // output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                output.ObjectSpacePosition =         input.positionOS;
                // output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                // output.ViewSpacePosition =           TransformWorldToView(output.WorldSpacePosition);
                // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(TransformObjectToWorld(input.positionOS));
                // output.WorldSpaceViewDirection =     GetWorldSpaceNormalizeViewDir(output.WorldSpacePosition);
                // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(output.WorldSpacePosition), _ProjectionParams.x);
                // output.uv0 =                         input.uv0;
                output.uv1 =                         input.uv1;
                output.uv2 =                         input.uv2;
                // output.uv3 =                         input.uv3;
                output.VertexColor =                 input.color;
            
                return output;
            }
            
            AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            {
                // build graph inputs
                VertexDescriptionInputs vertexDescriptionInputs = AttributesMeshToVertexDescriptionInputs(input);
                // Override time paramters with used one (This is required to correctly handle motion vector for vertex animation based on time)
                // vertexDescriptionInputs.TimeParameters = timeParameters;
            
                // evaluate vertex graph
                VertexDescription vertexDescription = VertexDescriptionFunction(vertexDescriptionInputs);
            
                // copy graph output to the results
                input.positionOS = vertexDescription.VertexPosition;
                input.normalOS = vertexDescription.VertexNormal;
                input.tangentOS.xyz = vertexDescription.VertexTangent;
            
                return input;
            }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
                FragInputs BuildFragInputs(VaryingsMeshToPS input)
                {
                    FragInputs output;
                    ZERO_INITIALIZE(FragInputs, output);
            
                    // Init to some default value to make the computer quiet (else it output 'divide by zero' warning even if value is not used).
                    // TODO: this is a really poor workaround, but the variable is used in a bunch of places
                    // to compute normals which are then passed on elsewhere to compute other values...
                    output.tangentToWorld = k_identity3x3;
                    output.positionSS = input.positionCS;       // input.positionCS is SV_Position
            
                    // output.positionRWS = input.positionRWS;
                    // output.tangentToWorld = BuildTangentToWorld(input.tangentWS, input.normalWS);
                    // output.texCoord0 = input.texCoord0;
                    // output.texCoord1 = input.texCoord1;
                    // output.texCoord2 = input.texCoord2;
                    // output.texCoord3 = input.texCoord3;
                    // output.color = input.color;
                    #if _DOUBLESIDED_ON && SHADER_STAGE_FRAGMENT
                    output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #elif SHADER_STAGE_FRAGMENT
                    // output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #endif // SHADER_STAGE_FRAGMENT
            
                    return output;
                }
            
                SurfaceDescriptionInputs FragInputsToSurfaceDescriptionInputs(FragInputs input, float3 viewWS)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                    // output.WorldSpaceNormal =            normalize(input.tangentToWorld[2].xyz);
                    // output.ObjectSpaceNormal =           mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M);           // transposed multiplication by inverse matrix to handle normal scale
                    // output.ViewSpaceNormal =             mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_I_V);         // transposed multiplication by inverse matrix to handle normal scale
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                    // output.WorldSpaceTangent =           input.tangentToWorld[0].xyz;
                    // output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
                    // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                    // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                    // output.WorldSpaceBiTangent =         input.tangentToWorld[1].xyz;
                    // output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
                    // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                    // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                    // output.WorldSpaceViewDirection =     normalize(viewWS);
                    // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                    // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                    // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                    // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    // output.WorldSpacePosition =          input.positionRWS;
                    // output.ObjectSpacePosition =         TransformWorldToObject(input.positionRWS);
                    // output.ViewSpacePosition =           TransformWorldToView(input.positionRWS);
                    // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                    // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionRWS);
                    // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionRWS), _ProjectionParams.x);
                    // output.uv0 =                         input.texCoord0;
                    // output.uv1 =                         input.texCoord1;
                    // output.uv2 =                         input.texCoord2;
                    // output.uv3 =                         input.texCoord3;
                    // output.VertexColor =                 input.color;
                    // output.FaceSign =                    input.isFrontFace;
                    // output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            
                    return output;
                }
            
                // existing HDRP code uses the combined function to go directly from packed to frag inputs
                FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    VaryingsMeshToPS unpacked= UnpackVaryingsMeshToPS(input);
                    return BuildFragInputs(unpacked);
                }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
            void BuildSurfaceData(FragInputs fragInputs, inout SurfaceDescription surfaceDescription, float3 V, PositionInputs posInput, out SurfaceData surfaceData, out float3 bentNormalWS)
            {
                // setup defaults -- these are used if the graph doesn't output a value
                ZERO_INITIALIZE(SurfaceData, surfaceData);
        
                // copy across graph values, if defined
                // surfaceData.baseColor =                 surfaceDescription.Albedo;
                // surfaceData.perceptualSmoothness =      surfaceDescription.Smoothness;
                // surfaceData.ambientOcclusion =          surfaceDescription.Occlusion;
                // surfaceData.specularOcclusion =         surfaceDescription.SpecularOcclusion;
                // surfaceData.metallic =                  surfaceDescription.Metallic;
                // surfaceData.subsurfaceMask =            surfaceDescription.SubsurfaceMask;
                // surfaceData.thickness =                 surfaceDescription.Thickness;
                // surfaceData.diffusionProfileHash =      asuint(surfaceDescription.DiffusionProfileHash);
                // surfaceData.specularColor =             surfaceDescription.Specular;
                // surfaceData.coatMask =                  surfaceDescription.CoatMask;
                // surfaceData.anisotropy =                surfaceDescription.Anisotropy;
                // surfaceData.iridescenceMask =           surfaceDescription.IridescenceMask;
                // surfaceData.iridescenceThickness =      surfaceDescription.IridescenceThickness;
        
        #ifdef _HAS_REFRACTION
                if (_EnableSSRefraction)
                {
                    // surfaceData.ior =                       surfaceDescription.RefractionIndex;
                    // surfaceData.transmittanceColor =        surfaceDescription.RefractionColor;
                    // surfaceData.atDistance =                surfaceDescription.RefractionDistance;
        
                    surfaceData.transmittanceMask = (1.0 - surfaceDescription.Alpha);
                    surfaceDescription.Alpha = 1.0;
                }
                else
                {
                    surfaceData.ior = 1.0;
                    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                    surfaceData.atDistance = 1.0;
                    surfaceData.transmittanceMask = 0.0;
                    surfaceDescription.Alpha = 1.0;
                }
        #else
                surfaceData.ior = 1.0;
                surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                surfaceData.atDistance = 1.0;
                surfaceData.transmittanceMask = 0.0;
        #endif
                
                // These static material feature allow compile time optimization
                surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
        #ifdef _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SUBSURFACE_SCATTERING;
        #endif
        #ifdef _MATERIAL_FEATURE_TRANSMISSION
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_TRANSMISSION;
        #endif
        #ifdef _MATERIAL_FEATURE_ANISOTROPY
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_ANISOTROPY;
        #endif
                // surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_CLEAR_COAT;
        
        #ifdef _MATERIAL_FEATURE_IRIDESCENCE
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_IRIDESCENCE;
        #endif
        #ifdef _MATERIAL_FEATURE_SPECULAR_COLOR
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SPECULAR_COLOR;
        #endif
        
        #if defined (_MATERIAL_FEATURE_SPECULAR_COLOR) && defined (_ENERGY_CONSERVING_SPECULAR)
                // Require to have setup baseColor
                // Reproduce the energy conservation done in legacy Unity. Not ideal but better for compatibility and users can unchek it
                surfaceData.baseColor *= (1.0 - Max3(surfaceData.specularColor.r, surfaceData.specularColor.g, surfaceData.specularColor.b));
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                // tangent-space normal
                float3 normalTS = float3(0.0f, 0.0f, 1.0f);
                // normalTS = surfaceDescription.Normal;
        
                // compute world space normal
                GetNormalWS(fragInputs, normalTS, surfaceData.normalWS, doubleSidedConstants);
        
                bentNormalWS = surfaceData.normalWS;
                // GetNormalWS(fragInputs, surfaceDescription.BentNormal, bentNormalWS, doubleSidedConstants);
        
                surfaceData.geomNormalWS = fragInputs.tangentToWorld[2];
        
                surfaceData.tangentWS = normalize(fragInputs.tangentToWorld[0].xyz);    // The tangent is not normalize in tangentToWorld for mikkt. TODO: Check if it expected that we normalize with Morten. Tag: SURFACE_GRADIENT
                // surfaceData.tangentWS = TransformTangentToWorld(surfaceDescription.Tangent, fragInputs.tangentToWorld);
                surfaceData.tangentWS = Orthonormalize(surfaceData.tangentWS, surfaceData.normalWS);
        
                // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
                // If user provide bent normal then we process a better term
        #if defined(_SPECULAR_OCCLUSION_CUSTOM)
                // Just use the value passed through via the slot (not active otherwise)
        #elif defined(_SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL)
                // If we have bent normal and ambient occlusion, process a specular occlusion
                surfaceData.specularOcclusion = GetSpecularOcclusionFromBentAO(V, bentNormalWS, surfaceData.normalWS, surfaceData.ambientOcclusion, PerceptualSmoothnessToPerceptualRoughness(surfaceData.perceptualSmoothness));
        #elif defined(_AMBIENT_OCCLUSION) && defined(_SPECULAR_OCCLUSION_FROM_AO)
                surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
        #else
                surfaceData.specularOcclusion = 1.0;
        #endif
        
        #if HAVE_DECALS
                if (_EnableDecals)
                {
                    DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, surfaceDescription.Alpha);
                    ApplyDecalToSurfaceData(decalSurfaceData, surfaceData);
                }
        #endif
        
        #ifdef _ENABLE_GEOMETRIC_SPECULAR_AA
                surfaceData.perceptualSmoothness = GeometricNormalFiltering(surfaceData.perceptualSmoothness, fragInputs.tangentToWorld[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif
        
        #ifdef DEBUG_DISPLAY
                if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
                {
                    // TODO: need to update mip info
                    surfaceData.metallic = 0;
                }
        
                // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
                // as it can modify attribute use for static lighting
                ApplyDebugToSurfaceData(fragInputs.tangentToWorld, surfaceData);
        #endif
            }
        
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
        #ifdef LOD_FADE_CROSSFADE // enable dithering LOD transition if user select CrossFade transition in LOD group
                uint3 fadeMaskSeed = asuint((int3)(V * _ScreenSize.xyx)); // Quantize V to _ScreenSize values
//                LODDitheringTransition(fadeMaskSeed, unity_LODFade.x);

                float4 clipPos = fragInputs.positionSS;
       //         clipPos.xy = (clipPos.xy + 1.0f) / 2.0f;

#if UNITY_UV_STARTS_AT_TOP
    // Our world space, view space, screen space and NDC space are Y-up.
    // Our clip space is flipped upside-down due to poor legacy Unity design.
    // The flip is baked into the projection matrix, so we only have to flip
    // manually when going from CS to NDC and back.
 //   clipPos.y = -clipPos.y;
#endif


                float2 screenPos = floor( clipPos.xy / clipPos.z * _ScreenParams.xy);
                // Interleaved Gradient Noise from http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare (slide 122)
                float3 magic = float3(0.06711056, 0.00583715, 52.9829189);
                float gradient = frac(magic.z * frac(dot(screenPos.xy, magic.xy)));
                //o.Specular *= (IN.AFSuv_MainTex.w + gradient > 1) ? 1 : 0;
            //    clip( 1 + (unity_LODFade.x)  - gradient);

clip( (unity_LODFade.x)  - gradient);




        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                ApplyDoubleSidedFlipOrMirror(fragInputs, doubleSidedConstants);
        
                SurfaceDescriptionInputs surfaceDescriptionInputs = FragInputsToSurfaceDescriptionInputs(fragInputs, V);
                SurfaceDescription surfaceDescription = SurfaceDescriptionFunction(surfaceDescriptionInputs);
        
                // Perform alpha test very early to save performance (a killed pixel will not sample textures)
                // TODO: split graph evaluation to grab just alpha dependencies first? tricky..
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPrepass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPostpass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow);
                
                // ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
        
                float3 bentNormalWS;
                BuildSurfaceData(fragInputs, surfaceDescription, V, posInput, surfaceData, bentNormalWS);
        
                // Builtin Data
                // For back lighting we use the oposite vertex normal 
                InitBuiltinData(posInput, surfaceDescription.Alpha, bentNormalWS, -fragInputs.tangentToWorld[2], fragInputs.texCoord1, fragInputs.texCoord2, builtinData);
        
                // override sampleBakedGI:
                // builtinData.bakeDiffuseLighting = surfaceDescription.BakedGI;
                // builtinData.backBakeDiffuseLighting = surfaceDescription.BakedBackGI;
        
                // builtinData.emissiveColor = surfaceDescription.Emission;
        
                // builtinData.depthOffset = surfaceDescription.DepthOffset;
        
        #if (SHADERPASS == SHADERPASS_DISTORTION)
                builtinData.distortion = surfaceDescription.Distortion;
                builtinData.distortionBlur = surfaceDescription.DistortionBlur;
        #else
                builtinData.distortion = float2(0.0, 0.0);
                builtinData.distortionBlur = 0.0;
        #endif
        
                PostInitBuiltinData(V, posInput, surfaceData, builtinData);
            }
        
            //-------------------------------------------------------------------------------------
            // Pass Includes
            //-------------------------------------------------------------------------------------
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"
            //-------------------------------------------------------------------------------------
            // End Pass Includes
            //-------------------------------------------------------------------------------------
        
            ENDHLSL
        }
        
        Pass
        {
            // based on HDLitPass.template
            Name "META"
            Tags { "LightMode" = "META" }
        
            //-------------------------------------------------------------------------------------
            // Render Modes (Blend, Cull, ZTest, Stencil, etc)
            //-------------------------------------------------------------------------------------
            
            Cull Off
        
            
            
            
            
            
            //-------------------------------------------------------------------------------------
            // End Render Modes
            //-------------------------------------------------------------------------------------
        
            HLSLPROGRAM
        
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //#pragma enable_d3d11_debug_symbols
        
            #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        
            #pragma multi_compile _ LOD_FADE_CROSSFADE
        
            // #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _DOUBLESIDED_ON
            // #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
        
            //-------------------------------------------------------------------------------------
            // Variant Definitions (active field translations to HDRP defines)
            //-------------------------------------------------------------------------------------
            // #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING 1
            // #define _MATERIAL_FEATURE_TRANSMISSION 1
            // #define _MATERIAL_FEATURE_ANISOTROPY 1
            // #define _MATERIAL_FEATURE_IRIDESCENCE 1
            // #define _MATERIAL_FEATURE_SPECULAR_COLOR 1
            // #define _ENABLE_FOG_ON_TRANSPARENT 1
            #define _AMBIENT_OCCLUSION 1
            // #define _SPECULAR_OCCLUSION_FROM_AO 1
            // #define _SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL 1
            // #define _SPECULAR_OCCLUSION_CUSTOM 1
            #define _ENERGY_CONSERVING_SPECULAR 1
            // #define _ENABLE_GEOMETRIC_SPECULAR_AA 1
            // #define _HAS_REFRACTION 1
            // #define _REFRACTION_PLANE 1
            // #define _REFRACTION_SPHERE 1
            // #define _DISABLE_DECALS 1
            #define _DISABLE_SSR 1
            // #define _ADD_PRECOMPUTED_VELOCITY
            // #define _WRITE_TRANSPARENT_MOTION_VECTOR 1
            // #define _DEPTHOFFSET_ON 1
            // #define _BLENDMODE_PRESERVE_SPECULAR_LIGHTING 1
        
            //-------------------------------------------------------------------------------------
            // End Variant Definitions
            //-------------------------------------------------------------------------------------
        
            #pragma vertex Vert
            #pragma fragment Frag
        
            // If we use subsurface scattering, enable output split lighting (for forward pass)
            #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
            #define OUTPUT_SPLIT_LIGHTING
            #endif
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
        
            // define FragInputs structure
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
        
            //-------------------------------------------------------------------------------------
            // Defines
            //-------------------------------------------------------------------------------------
                    #define SHADERPASS SHADERPASS_LIGHT_TRANSPORT
                #define RAYTRACING_SHADER_GRAPH_HIGH
                // ACTIVE FIELDS:
                //   Material.Standard
                //   DisableSSR
                //   Specular.EnergyConserving
                //   AmbientOcclusion
                //   SurfaceDescriptionInputs.VertexColor
                //   SurfaceDescriptionInputs.TangentSpaceNormal
                //   SurfaceDescriptionInputs.uv0
                //   VertexDescriptionInputs.ObjectSpaceNormal
                //   VertexDescriptionInputs.ObjectSpaceTangent
                //   SurfaceDescription.Albedo
                //   SurfaceDescription.Normal
                //   SurfaceDescription.BentNormal
                //   SurfaceDescription.CoatMask
                //   SurfaceDescription.Metallic
                //   SurfaceDescription.Emission
                //   SurfaceDescription.Smoothness
                //   SurfaceDescription.Occlusion
                //   SurfaceDescription.Alpha
                //   features.modifyMesh
                //   AttributesMesh.normalOS
                //   AttributesMesh.tangentOS
                //   AttributesMesh.uv0
                //   AttributesMesh.uv1
                //   AttributesMesh.color
                //   AttributesMesh.uv2
                //   FragInputs.color
                //   FragInputs.texCoord0
                //   VaryingsMeshToPS.color
                //   VaryingsMeshToPS.texCoord0
                // Shared Graph Keywords
        
            // this translates the new dependency tracker into the old preprocessor definitions for the existing HDRP shader code
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            // #define ATTRIBUTES_NEED_TEXCOORD3
            #define ATTRIBUTES_NEED_COLOR
            // #define VARYINGS_NEED_POSITION_WS
            // #define VARYINGS_NEED_TANGENT_TO_WORLD
            #define VARYINGS_NEED_TEXCOORD0
            // #define VARYINGS_NEED_TEXCOORD1
            // #define VARYINGS_NEED_TEXCOORD2
            // #define VARYINGS_NEED_TEXCOORD3
            #define VARYINGS_NEED_COLOR
            // #define VARYINGS_NEED_CULLFACE
            #define HAVE_MESH_MODIFICATION
        
        // We need isFontFace when using double sided
        #if defined(_DOUBLESIDED_ON) && !defined(VARYINGS_NEED_CULLFACE)
            #define VARYINGS_NEED_CULLFACE
        #endif
        
            //-------------------------------------------------------------------------------------
            // End Defines
            //-------------------------------------------------------------------------------------
            
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
        
        #if (SHADERPASS == SHADERPASS_FORWARD)
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        
            #define HAS_LIGHTLOOP
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"
        #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDecalData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"
        
            // Used by SceneSelectionPass
            int _ObjectId;
            int _PassValue;
        
            //-------------------------------------------------------------------------------------
            // Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
            // Generated Type: AttributesMesh
            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL; // optional
                float4 tangentOS : TANGENT; // optional
                float4 uv0 : TEXCOORD0; // optional
                float4 uv1 : TEXCOORD1; // optional
                float4 uv2 : TEXCOORD2; // optional
                float4 color : COLOR; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            // Generated Type: VaryingsMeshToPS
            struct VaryingsMeshToPS
            {
                float4 positionCS : SV_Position;
                float4 texCoord0; // optional
                float4 color; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif // defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            };
            
            // Generated Type: PackedVaryingsMeshToPS
            struct PackedVaryingsMeshToPS
            {
                float4 positionCS : SV_Position; // unpacked
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float4 interp00 : TEXCOORD0; // auto-packed
                float4 interp01 : TEXCOORD1; // auto-packed
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC; // unpacked
                #endif // conditional
            };
            
            // Packed Type: VaryingsMeshToPS
            PackedVaryingsMeshToPS PackVaryingsMeshToPS(VaryingsMeshToPS input)
            {
                PackedVaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.interp00.xyzw = input.texCoord0;
                output.interp01.xyzw = input.color;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToPS
            VaryingsMeshToPS UnpackVaryingsMeshToPS(PackedVaryingsMeshToPS input)
            {
                VaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.texCoord0 = input.interp00.xyzw;
                output.color = input.interp01.xyzw;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            // Generated Type: VaryingsMeshToDS
            struct VaryingsMeshToDS
            {
                float3 positionRWS;
                float3 normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            
            // Generated Type: PackedVaryingsMeshToDS
            struct PackedVaryingsMeshToDS
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
            };
            
            // Packed Type: VaryingsMeshToDS
            PackedVaryingsMeshToDS PackVaryingsMeshToDS(VaryingsMeshToDS input)
            {
                PackedVaryingsMeshToDS output;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToDS
            VaryingsMeshToDS UnpackVaryingsMeshToDS(PackedVaryingsMeshToDS input)
            {
                VaryingsMeshToDS output;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            //-------------------------------------------------------------------------------------
            // End Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
        
            //-------------------------------------------------------------------------------------
            // Graph generated code
            //-------------------------------------------------------------------------------------
                    // Shared Graph Properties (uniform inputs)
                    CBUFFER_START(UnityPerMaterial)
                    float _NormalStrength; float _Smoothness;
                    float3 _WindMultipliers;
                    float4 _EmissionColor;
                    float _RenderQueueType;
                    float _StencilRef;
                    float _StencilWriteMask;
                    float _StencilRefDepth;
                    float _StencilWriteMaskDepth;
                    float _StencilRefMV;
                    float _StencilWriteMaskMV;
                    float _StencilRefDistortionVec;
                    float _StencilWriteMaskDistortionVec;
                    float _StencilWriteMaskGBuffer;
                    float _StencilRefGBuffer;
                    float _ZTestGBuffer;
                    float _RequireSplitLighting;
                    float _ReceivesSSR;
                    float _SurfaceType;
                    float _BlendMode;
                    float _SrcBlend;
                    float _DstBlend;
                    float _AlphaSrcBlend;
                    float _AlphaDstBlend;
                    float _ZWrite;
                    float _CullMode;
                    float _TransparentSortPriority;
                    float _CullModeForward;
                    float _TransparentCullMode;
                    float _ZTestDepthEqualForOpaque;
                    float _ZTestTransparent;
                    float _TransparentBackfaceEnable;
                    float _AlphaCutoffEnable;
                    float _UseShadowThreshold;
                    float _DoubleSidedEnable;
                    float _DoubleSidedNormalMode;
                    float4 _DoubleSidedConstants;
                    CBUFFER_END
                    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;
                    TEXTURE2D(_BumpSpecAOMap); SAMPLER(sampler_BumpSpecAOMap); float4 _BumpSpecAOMap_TexelSize;
                    SAMPLER(_SampleTexture2D_1060DFD5_Sampler_3_Linear_Repeat);
                    SAMPLER(_SampleTexture2D_EC10A3ED_Sampler_3_Linear_Repeat);
                
                // Vertex Graph Inputs
                    struct VertexDescriptionInputs
                    {
                        float3 ObjectSpaceNormal; // optional
                        float3 ObjectSpaceTangent; // optional
                    };
                // Vertex Graph Outputs
                    struct VertexDescription
                    {
                    };
                    
                // Pixel Graph Inputs
                    struct SurfaceDescriptionInputs
                    {
                        float3 TangentSpaceNormal; // optional
                        float4 uv0; // optional
                        float4 VertexColor; // optional
                    };
                // Pixel Graph Outputs
                    struct SurfaceDescription
                    {
                        float3 Albedo;
                        float3 Normal;
                        float3 BentNormal;
                        float CoatMask;
                        float Metallic;
                        float3 Emission;
                        float Smoothness;
                        float Occlusion;
                        float Alpha;
                    };
                    
                // Shared Graph Node Functions
                
                    void UnpackCustomNormal_float(float4 normalSample, out float3 normalOut)
                    {
                        normalOut.xy = normalSample.ag;
                        normalOut.xy = normalOut.xy * 2 - 1;
                        normalOut.z = sqrt( 1 - dot(normalOut.xy , normalOut.xy ));
                    }
                
                    void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
                    {
                        Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
                    }
                
                    void Unity_Multiply_float (float A, float B, out float Out)
                    {
                        Out = A * B;
                    }
                
                // Vertex Graph Evaluation
                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        return description;
                    }
                    
                // Pixel Graph Evaluation
                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        float4 _SampleTexture2D_1060DFD5_RGBA_0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0.xy);
                        float _SampleTexture2D_1060DFD5_R_4 = _SampleTexture2D_1060DFD5_RGBA_0.r;
                        float _SampleTexture2D_1060DFD5_G_5 = _SampleTexture2D_1060DFD5_RGBA_0.g;
                        float _SampleTexture2D_1060DFD5_B_6 = _SampleTexture2D_1060DFD5_RGBA_0.b;
                        float _SampleTexture2D_1060DFD5_A_7 = _SampleTexture2D_1060DFD5_RGBA_0.a;
                        float4 _SampleTexture2D_EC10A3ED_RGBA_0 = SAMPLE_TEXTURE2D(_BumpSpecAOMap, sampler_BumpSpecAOMap, IN.uv0.xy);
                        float _SampleTexture2D_EC10A3ED_R_4 = _SampleTexture2D_EC10A3ED_RGBA_0.r;
                        float _SampleTexture2D_EC10A3ED_G_5 = _SampleTexture2D_EC10A3ED_RGBA_0.g;
                        float _SampleTexture2D_EC10A3ED_B_6 = _SampleTexture2D_EC10A3ED_RGBA_0.b;
                        float _SampleTexture2D_EC10A3ED_A_7 = _SampleTexture2D_EC10A3ED_RGBA_0.a;
                        float3 _CustomFunction_CF03AB98_normalOut_1;
                        UnpackCustomNormal_float(_SampleTexture2D_EC10A3ED_RGBA_0, _CustomFunction_CF03AB98_normalOut_1);
                        float _Property_C6B71BE6_Out_0 = _NormalStrength;
                        float3 _NormalStrength_AA429D2D_Out_2;
                        Unity_NormalStrength_float(_CustomFunction_CF03AB98_normalOut_1, _Property_C6B71BE6_Out_0, _NormalStrength_AA429D2D_Out_2);
                        float _Split_DDDB7F0B_R_1 = IN.VertexColor[0];
                        float _Split_DDDB7F0B_G_2 = IN.VertexColor[1];
                        float _Split_DDDB7F0B_B_3 = IN.VertexColor[2];
                        float _Split_DDDB7F0B_A_4 = IN.VertexColor[3];
                        float _Multiply_1C76B952_Out_2;
                        Unity_Multiply_float(_Split_DDDB7F0B_A_4, _SampleTexture2D_EC10A3ED_B_6, _Multiply_1C76B952_Out_2);
                        surface.Albedo = (_SampleTexture2D_1060DFD5_RGBA_0.xyz);
                        surface.Normal = _NormalStrength_AA429D2D_Out_2;
                        surface.BentNormal = IN.TangentSpaceNormal;
                        surface.CoatMask = 0;
                        surface.Metallic = 0;
                        surface.Emission = float3(0, 0, 0);
                        surface.Smoothness = _SampleTexture2D_1060DFD5_A_7 * _Smoothness;
                        surface.Occlusion = _Multiply_1C76B952_Out_2;
                        surface.Alpha = 1;
                        return surface;
                    }
                    
            //-------------------------------------------------------------------------------------
            // End graph generated code
            //-------------------------------------------------------------------------------------
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
            
            VertexDescriptionInputs AttributesMeshToVertexDescriptionInputs(AttributesMesh input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                // output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                // output.ViewSpaceNormal =             TransformWorldToViewDir(output.WorldSpaceNormal);
                // output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                output.ObjectSpaceTangent =          input.tangentOS;
                // output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
                // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                // output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
                // output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                // output.ObjectSpacePosition =         input.positionOS;
                // output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                // output.ViewSpacePosition =           TransformWorldToView(output.WorldSpacePosition);
                // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(TransformObjectToWorld(input.positionOS));
                // output.WorldSpaceViewDirection =     GetWorldSpaceNormalizeViewDir(output.WorldSpacePosition);
                // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(output.WorldSpacePosition), _ProjectionParams.x);
                // output.uv0 =                         input.uv0;
                // output.uv1 =                         input.uv1;
                // output.uv2 =                         input.uv2;
                // output.uv3 =                         input.uv3;
                // output.VertexColor =                 input.color;
            
                return output;
            }
            
            AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            {
                // build graph inputs
                VertexDescriptionInputs vertexDescriptionInputs = AttributesMeshToVertexDescriptionInputs(input);
                // Override time paramters with used one (This is required to correctly handle motion vector for vertex animation based on time)
                // vertexDescriptionInputs.TimeParameters = timeParameters;
            
                // evaluate vertex graph
                VertexDescription vertexDescription = VertexDescriptionFunction(vertexDescriptionInputs);
            
                // copy graph output to the results
                // input.positionOS = vertexDescription.VertexPosition;
                // input.normalOS = vertexDescription.VertexNormal;
                // input.tangentOS.xyz = vertexDescription.VertexTangent;
            
                return input;
            }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
                FragInputs BuildFragInputs(VaryingsMeshToPS input)
                {
                    FragInputs output;
                    ZERO_INITIALIZE(FragInputs, output);
            
                    // Init to some default value to make the computer quiet (else it output 'divide by zero' warning even if value is not used).
                    // TODO: this is a really poor workaround, but the variable is used in a bunch of places
                    // to compute normals which are then passed on elsewhere to compute other values...
                    output.tangentToWorld = k_identity3x3;
                    output.positionSS = input.positionCS;       // input.positionCS is SV_Position
            
                    // output.positionRWS = input.positionRWS;
                    // output.tangentToWorld = BuildTangentToWorld(input.tangentWS, input.normalWS);
                    output.texCoord0 = input.texCoord0;
                    // output.texCoord1 = input.texCoord1;
                    // output.texCoord2 = input.texCoord2;
                    // output.texCoord3 = input.texCoord3;
                    output.color = input.color;
                    #if _DOUBLESIDED_ON && SHADER_STAGE_FRAGMENT
                    output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #elif SHADER_STAGE_FRAGMENT
                    // output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #endif // SHADER_STAGE_FRAGMENT
            
                    return output;
                }
            
                SurfaceDescriptionInputs FragInputsToSurfaceDescriptionInputs(FragInputs input, float3 viewWS)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                    // output.WorldSpaceNormal =            normalize(input.tangentToWorld[2].xyz);
                    // output.ObjectSpaceNormal =           mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M);           // transposed multiplication by inverse matrix to handle normal scale
                    // output.ViewSpaceNormal =             mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_I_V);         // transposed multiplication by inverse matrix to handle normal scale
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                    // output.WorldSpaceTangent =           input.tangentToWorld[0].xyz;
                    // output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
                    // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                    // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                    // output.WorldSpaceBiTangent =         input.tangentToWorld[1].xyz;
                    // output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
                    // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                    // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                    // output.WorldSpaceViewDirection =     normalize(viewWS);
                    // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                    // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                    // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                    // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    // output.WorldSpacePosition =          input.positionRWS;
                    // output.ObjectSpacePosition =         TransformWorldToObject(input.positionRWS);
                    // output.ViewSpacePosition =           TransformWorldToView(input.positionRWS);
                    // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                    // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionRWS);
                    // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionRWS), _ProjectionParams.x);
                    output.uv0 =                         input.texCoord0;
                    // output.uv1 =                         input.texCoord1;
                    // output.uv2 =                         input.texCoord2;
                    // output.uv3 =                         input.texCoord3;
                    output.VertexColor =                 input.color;
                    // output.FaceSign =                    input.isFrontFace;
                    // output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            
                    return output;
                }
            
                // existing HDRP code uses the combined function to go directly from packed to frag inputs
                FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    VaryingsMeshToPS unpacked= UnpackVaryingsMeshToPS(input);
                    return BuildFragInputs(unpacked);
                }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
            void BuildSurfaceData(FragInputs fragInputs, inout SurfaceDescription surfaceDescription, float3 V, PositionInputs posInput, out SurfaceData surfaceData, out float3 bentNormalWS)
            {
                // setup defaults -- these are used if the graph doesn't output a value
                ZERO_INITIALIZE(SurfaceData, surfaceData);
        
                // copy across graph values, if defined
                surfaceData.baseColor =                 surfaceDescription.Albedo;
                surfaceData.perceptualSmoothness =      surfaceDescription.Smoothness;
                surfaceData.ambientOcclusion =          surfaceDescription.Occlusion;
                // surfaceData.specularOcclusion =         surfaceDescription.SpecularOcclusion;
                surfaceData.metallic =                  surfaceDescription.Metallic;
                // surfaceData.subsurfaceMask =            surfaceDescription.SubsurfaceMask;
                // surfaceData.thickness =                 surfaceDescription.Thickness;
                // surfaceData.diffusionProfileHash =      asuint(surfaceDescription.DiffusionProfileHash);
                // surfaceData.specularColor =             surfaceDescription.Specular;
                surfaceData.coatMask =                  surfaceDescription.CoatMask;
                // surfaceData.anisotropy =                surfaceDescription.Anisotropy;
                // surfaceData.iridescenceMask =           surfaceDescription.IridescenceMask;
                // surfaceData.iridescenceThickness =      surfaceDescription.IridescenceThickness;
        
        #ifdef _HAS_REFRACTION
                if (_EnableSSRefraction)
                {
                    // surfaceData.ior =                       surfaceDescription.RefractionIndex;
                    // surfaceData.transmittanceColor =        surfaceDescription.RefractionColor;
                    // surfaceData.atDistance =                surfaceDescription.RefractionDistance;
        
                    surfaceData.transmittanceMask = (1.0 - surfaceDescription.Alpha);
                    surfaceDescription.Alpha = 1.0;
                }
                else
                {
                    surfaceData.ior = 1.0;
                    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                    surfaceData.atDistance = 1.0;
                    surfaceData.transmittanceMask = 0.0;
                    surfaceDescription.Alpha = 1.0;
                }
        #else
                surfaceData.ior = 1.0;
                surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                surfaceData.atDistance = 1.0;
                surfaceData.transmittanceMask = 0.0;
        #endif
                
                // These static material feature allow compile time optimization
                surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
        #ifdef _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SUBSURFACE_SCATTERING;
        #endif
        #ifdef _MATERIAL_FEATURE_TRANSMISSION
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_TRANSMISSION;
        #endif
        #ifdef _MATERIAL_FEATURE_ANISOTROPY
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_ANISOTROPY;
        #endif
                // surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_CLEAR_COAT;
        
        #ifdef _MATERIAL_FEATURE_IRIDESCENCE
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_IRIDESCENCE;
        #endif
        #ifdef _MATERIAL_FEATURE_SPECULAR_COLOR
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SPECULAR_COLOR;
        #endif
        
        #if defined (_MATERIAL_FEATURE_SPECULAR_COLOR) && defined (_ENERGY_CONSERVING_SPECULAR)
                // Require to have setup baseColor
                // Reproduce the energy conservation done in legacy Unity. Not ideal but better for compatibility and users can unchek it
                surfaceData.baseColor *= (1.0 - Max3(surfaceData.specularColor.r, surfaceData.specularColor.g, surfaceData.specularColor.b));
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                // tangent-space normal
                float3 normalTS = float3(0.0f, 0.0f, 1.0f);
                normalTS = surfaceDescription.Normal;
        
                // compute world space normal
                GetNormalWS(fragInputs, normalTS, surfaceData.normalWS, doubleSidedConstants);
        
                bentNormalWS = surfaceData.normalWS;
                // GetNormalWS(fragInputs, surfaceDescription.BentNormal, bentNormalWS, doubleSidedConstants);
        
                surfaceData.geomNormalWS = fragInputs.tangentToWorld[2];
        
                surfaceData.tangentWS = normalize(fragInputs.tangentToWorld[0].xyz);    // The tangent is not normalize in tangentToWorld for mikkt. TODO: Check if it expected that we normalize with Morten. Tag: SURFACE_GRADIENT
                // surfaceData.tangentWS = TransformTangentToWorld(surfaceDescription.Tangent, fragInputs.tangentToWorld);
                surfaceData.tangentWS = Orthonormalize(surfaceData.tangentWS, surfaceData.normalWS);
        
                // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
                // If user provide bent normal then we process a better term
        #if defined(_SPECULAR_OCCLUSION_CUSTOM)
                // Just use the value passed through via the slot (not active otherwise)
        #elif defined(_SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL)
                // If we have bent normal and ambient occlusion, process a specular occlusion
                surfaceData.specularOcclusion = GetSpecularOcclusionFromBentAO(V, bentNormalWS, surfaceData.normalWS, surfaceData.ambientOcclusion, PerceptualSmoothnessToPerceptualRoughness(surfaceData.perceptualSmoothness));
        #elif defined(_AMBIENT_OCCLUSION) && defined(_SPECULAR_OCCLUSION_FROM_AO)
                surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
        #else
                surfaceData.specularOcclusion = 1.0;
        #endif
        
        #if HAVE_DECALS
                if (_EnableDecals)
                {
                    DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, surfaceDescription.Alpha);
                    ApplyDecalToSurfaceData(decalSurfaceData, surfaceData);
                }
        #endif
        
        #ifdef _ENABLE_GEOMETRIC_SPECULAR_AA
                surfaceData.perceptualSmoothness = GeometricNormalFiltering(surfaceData.perceptualSmoothness, fragInputs.tangentToWorld[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif
        
        #ifdef DEBUG_DISPLAY
                if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
                {
                    // TODO: need to update mip info
                    surfaceData.metallic = 0;
                }
        
                // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
                // as it can modify attribute use for static lighting
                ApplyDebugToSurfaceData(fragInputs.tangentToWorld, surfaceData);
        #endif
            }
        
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
        #ifdef LOD_FADE_CROSSFADE // enable dithering LOD transition if user select CrossFade transition in LOD group
                uint3 fadeMaskSeed = asuint((int3)(V * _ScreenSize.xyx)); // Quantize V to _ScreenSize values
                LODDitheringTransition(fadeMaskSeed, unity_LODFade.x);
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                ApplyDoubleSidedFlipOrMirror(fragInputs, doubleSidedConstants);
        
                SurfaceDescriptionInputs surfaceDescriptionInputs = FragInputsToSurfaceDescriptionInputs(fragInputs, V);
                SurfaceDescription surfaceDescription = SurfaceDescriptionFunction(surfaceDescriptionInputs);
        
                // Perform alpha test very early to save performance (a killed pixel will not sample textures)
                // TODO: split graph evaluation to grab just alpha dependencies first? tricky..
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPrepass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPostpass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow);
                
                // ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
        
                float3 bentNormalWS;
                BuildSurfaceData(fragInputs, surfaceDescription, V, posInput, surfaceData, bentNormalWS);
        
                // Builtin Data
                // For back lighting we use the oposite vertex normal 
                InitBuiltinData(posInput, surfaceDescription.Alpha, bentNormalWS, -fragInputs.tangentToWorld[2], fragInputs.texCoord1, fragInputs.texCoord2, builtinData);
        
                // override sampleBakedGI:
                // builtinData.bakeDiffuseLighting = surfaceDescription.BakedGI;
                // builtinData.backBakeDiffuseLighting = surfaceDescription.BakedBackGI;
        
                builtinData.emissiveColor = surfaceDescription.Emission;
        
                // builtinData.depthOffset = surfaceDescription.DepthOffset;
        
        #if (SHADERPASS == SHADERPASS_DISTORTION)
                builtinData.distortion = surfaceDescription.Distortion;
                builtinData.distortionBlur = surfaceDescription.DistortionBlur;
        #else
                builtinData.distortion = float2(0.0, 0.0);
                builtinData.distortionBlur = 0.0;
        #endif
        
                PostInitBuiltinData(V, posInput, surfaceData, builtinData);
            }
        
            //-------------------------------------------------------------------------------------
            // Pass Includes
            //-------------------------------------------------------------------------------------
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassLightTransport.hlsl"
            //-------------------------------------------------------------------------------------
            // End Pass Includes
            //-------------------------------------------------------------------------------------
        
            ENDHLSL
        }
        
        Pass
        {
            // based on HDLitPass.template
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }
        
            //-------------------------------------------------------------------------------------
            // Render Modes (Blend, Cull, ZTest, Stencil, etc)
            //-------------------------------------------------------------------------------------
            
            
            
            
            
            
            ColorMask 0
        
            //-------------------------------------------------------------------------------------
            // End Render Modes
            //-------------------------------------------------------------------------------------
        
            HLSLPROGRAM
        
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //#pragma enable_d3d11_debug_symbols
        
            #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        
            #pragma multi_compile _ LOD_FADE_CROSSFADE
        
            // #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _DOUBLESIDED_ON
            // #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
        
            //-------------------------------------------------------------------------------------
            // Variant Definitions (active field translations to HDRP defines)
            //-------------------------------------------------------------------------------------
            // #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING 1
            // #define _MATERIAL_FEATURE_TRANSMISSION 1
            // #define _MATERIAL_FEATURE_ANISOTROPY 1
            // #define _MATERIAL_FEATURE_IRIDESCENCE 1
            // #define _MATERIAL_FEATURE_SPECULAR_COLOR 1
            // #define _ENABLE_FOG_ON_TRANSPARENT 1
            #define _AMBIENT_OCCLUSION 1
            #define _SPECULAR_OCCLUSION_FROM_AO 1
            // #define _SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL 1
            // #define _SPECULAR_OCCLUSION_CUSTOM 1
            #define _ENERGY_CONSERVING_SPECULAR 1
            // #define _ENABLE_GEOMETRIC_SPECULAR_AA 1
            // #define _HAS_REFRACTION 1
            // #define _REFRACTION_PLANE 1
            // #define _REFRACTION_SPHERE 1
            // #define _DISABLE_DECALS 1
            #define _DISABLE_SSR 1
            // #define _ADD_PRECOMPUTED_VELOCITY
            // #define _WRITE_TRANSPARENT_MOTION_VECTOR 1
            // #define _DEPTHOFFSET_ON 1
            // #define _BLENDMODE_PRESERVE_SPECULAR_LIGHTING 1
        
            //-------------------------------------------------------------------------------------
            // End Variant Definitions
            //-------------------------------------------------------------------------------------
        
            #pragma vertex Vert
            #pragma fragment Frag
        
            // If we use subsurface scattering, enable output split lighting (for forward pass)
            #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
            #define OUTPUT_SPLIT_LIGHTING
            #endif
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
        
            // define FragInputs structure
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
        
            //-------------------------------------------------------------------------------------
            // Defines
            //-------------------------------------------------------------------------------------
                    #define SHADERPASS SHADERPASS_DEPTH_ONLY
                #define SCENESELECTIONPASS
                #pragma editor_sync_compilation
                #define RAYTRACING_SHADER_GRAPH_HIGH
                // ACTIVE FIELDS:
                //   Material.Standard
                //   DisableSSR
                //   Specular.EnergyConserving
                //   SurfaceDescriptionInputs.TangentSpaceNormal
                //   VertexDescriptionInputs.VertexColor
                //   VertexDescriptionInputs.ObjectSpaceNormal
                //   VertexDescriptionInputs.ObjectSpaceTangent
                //   VertexDescriptionInputs.ObjectSpacePosition
                //   VertexDescriptionInputs.uv1
                //   VertexDescriptionInputs.uv2
                //   SurfaceDescription.Alpha
                //   features.modifyMesh
                //   VertexDescription.VertexPosition
                //   VertexDescription.VertexNormal
                //   VertexDescription.VertexTangent
                //   AttributesMesh.color
                //   AttributesMesh.normalOS
                //   AttributesMesh.tangentOS
                //   AttributesMesh.positionOS
                //   AttributesMesh.uv1
                //   AttributesMesh.uv2
                // Shared Graph Keywords
        
            // this translates the new dependency tracker into the old preprocessor definitions for the existing HDRP shader code
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            // #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            // #define ATTRIBUTES_NEED_TEXCOORD3
            #define ATTRIBUTES_NEED_COLOR
            // #define VARYINGS_NEED_POSITION_WS
            // #define VARYINGS_NEED_TANGENT_TO_WORLD
            // #define VARYINGS_NEED_TEXCOORD0
            // #define VARYINGS_NEED_TEXCOORD1
            // #define VARYINGS_NEED_TEXCOORD2
            // #define VARYINGS_NEED_TEXCOORD3
            // #define VARYINGS_NEED_COLOR
            // #define VARYINGS_NEED_CULLFACE
            #define HAVE_MESH_MODIFICATION
        
        // We need isFontFace when using double sided
        #if defined(_DOUBLESIDED_ON) && !defined(VARYINGS_NEED_CULLFACE)
            #define VARYINGS_NEED_CULLFACE
        #endif
        
            //-------------------------------------------------------------------------------------
            // End Defines
            //-------------------------------------------------------------------------------------
            
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
        
        #if (SHADERPASS == SHADERPASS_FORWARD)
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        
            #define HAS_LIGHTLOOP
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"
        #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDecalData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"
        
            // Used by SceneSelectionPass
            int _ObjectId;
            int _PassValue;
        
            //-------------------------------------------------------------------------------------
            // Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
            // Generated Type: AttributesMesh
            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL; // optional
                float4 tangentOS : TANGENT; // optional
                float4 uv1 : TEXCOORD1; // optional
                float4 uv2 : TEXCOORD2; // optional
                float4 color : COLOR; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            // Generated Type: VaryingsMeshToPS
            struct VaryingsMeshToPS
            {
                float4 positionCS : SV_Position;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif // defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            };
            
            // Generated Type: PackedVaryingsMeshToPS
            struct PackedVaryingsMeshToPS
            {
                float4 positionCS : SV_Position; // unpacked
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC; // unpacked
                #endif // conditional
            };
            
            // Packed Type: VaryingsMeshToPS
            PackedVaryingsMeshToPS PackVaryingsMeshToPS(VaryingsMeshToPS input)
            {
                PackedVaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToPS
            VaryingsMeshToPS UnpackVaryingsMeshToPS(PackedVaryingsMeshToPS input)
            {
                VaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            // Generated Type: VaryingsMeshToDS
            struct VaryingsMeshToDS
            {
                float3 positionRWS;
                float3 normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            
            // Generated Type: PackedVaryingsMeshToDS
            struct PackedVaryingsMeshToDS
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
            };
            
            // Packed Type: VaryingsMeshToDS
            PackedVaryingsMeshToDS PackVaryingsMeshToDS(VaryingsMeshToDS input)
            {
                PackedVaryingsMeshToDS output;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToDS
            VaryingsMeshToDS UnpackVaryingsMeshToDS(PackedVaryingsMeshToDS input)
            {
                VaryingsMeshToDS output;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            //-------------------------------------------------------------------------------------
            // End Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
        
            //-------------------------------------------------------------------------------------
            // Graph generated code
            //-------------------------------------------------------------------------------------
                    // Shared Graph Properties (uniform inputs)
                    CBUFFER_START(UnityPerMaterial)
                    float _NormalStrength; float _Smoothness;
                    float3 _WindMultipliers;
                    float4 _EmissionColor;
                    float _RenderQueueType;
                    float _StencilRef;
                    float _StencilWriteMask;
                    float _StencilRefDepth;
                    float _StencilWriteMaskDepth;
                    float _StencilRefMV;
                    float _StencilWriteMaskMV;
                    float _StencilRefDistortionVec;
                    float _StencilWriteMaskDistortionVec;
                    float _StencilWriteMaskGBuffer;
                    float _StencilRefGBuffer;
                    float _ZTestGBuffer;
                    float _RequireSplitLighting;
                    float _ReceivesSSR;
                    float _SurfaceType;
                    float _BlendMode;
                    float _SrcBlend;
                    float _DstBlend;
                    float _AlphaSrcBlend;
                    float _AlphaDstBlend;
                    float _ZWrite;
                    float _CullMode;
                    float _TransparentSortPriority;
                    float _CullModeForward;
                    float _TransparentCullMode;
                    float _ZTestDepthEqualForOpaque;
                    float _ZTestTransparent;
                    float _TransparentBackfaceEnable;
                    float _AlphaCutoffEnable;
                    float _UseShadowThreshold;
                    float _DoubleSidedEnable;
                    float _DoubleSidedNormalMode;
                    float4 _DoubleSidedConstants;
                    CBUFFER_END
                    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;
                    TEXTURE2D(_BumpSpecAOMap); SAMPLER(sampler_BumpSpecAOMap); float4 _BumpSpecAOMap_TexelSize;
                
                // Vertex Graph Inputs
                    struct VertexDescriptionInputs
                    {
                        float3 ObjectSpaceNormal; // optional
                        float3 ObjectSpaceTangent; // optional
                        float3 ObjectSpacePosition; // optional
                        float4 uv1; // optional
                        float4 uv2; // optional
                        float4 VertexColor; // optional
                    };
                // Vertex Graph Outputs
                    struct VertexDescription
                    {
                        float3 VertexPosition;
                        float3 VertexNormal;
                        float3 VertexTangent;
                    };
                    
                // Pixel Graph Inputs
                    struct SurfaceDescriptionInputs
                    {
                        float3 TangentSpaceNormal; // optional
                    };
                // Pixel Graph Outputs
                    struct SurfaceDescription
                    {
                        float Alpha;
                    };
                    
                // Shared Graph Node Functions
                
                    // dcd3c055367822a77956a73ac0a83c36
                    #include "/Includes/CTI_HDRP_Wind.hlsl"
                
                    struct Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8
                    {
                        float3 ObjectSpaceNormal;
                        float3 ObjectSpacePosition;
                        float4 VertexColor;
                        half4 uv1;
                        half4 uv2;
                    };
                
                    void SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(float Vector1_5B3F28E6, float Vector1_39544515, float Vector1_E70341A3, float Vector1_D355D6, float3 Vector3_D146D8D7, float Boolean_BA69BFA3, Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 IN, out float3 Position_1, out float3 Normal_2, out float ColorVariation_3)
                    {
                        float4 _UV_681BEC06_Out_0 = IN.uv1;
                        float4 _UV_5EAEC7D4_Out_0 = IN.uv2;
                        float _Property_66DDE654_Out_0 = Vector1_5B3F28E6;
                        float _Property_F63DDA84_Out_0 = Vector1_39544515;
                        float _Property_32CC05D1_Out_0 = Vector1_E70341A3;
                        float _Property_550822E2_Out_0 = Vector1_D355D6;
                        float3 _Property_9A8CF22B_Out_0 = Vector3_D146D8D7;
                        float _Property_7647AB6A_Out_0 = Boolean_BA69BFA3;
                        float3 _CustomFunction_4DA71B86_position1_10;
                        float3 _CustomFunction_4DA71B86_normal1_11;
                        float _CustomFunction_4DA71B86_color_12;
                        ApplyCTIWind_float(IN.ObjectSpacePosition, IN.VertexColor, (_UV_681BEC06_Out_0.xy), (_UV_5EAEC7D4_Out_0.xy), IN.ObjectSpaceNormal, _Property_66DDE654_Out_0, _Property_F63DDA84_Out_0, _Property_32CC05D1_Out_0, _Property_550822E2_Out_0, _Property_9A8CF22B_Out_0, _Property_7647AB6A_Out_0, _CustomFunction_4DA71B86_position1_10, _CustomFunction_4DA71B86_normal1_11, _CustomFunction_4DA71B86_color_12);
                        Position_1 = _CustomFunction_4DA71B86_position1_10;
                        Normal_2 = _CustomFunction_4DA71B86_normal1_11;
                        ColorVariation_3 = _CustomFunction_4DA71B86_color_12;
                    }
                
                // Vertex Graph Evaluation
                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        float3 _Property_EC5ABF14_Out_0 = _WindMultipliers;
                        Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 _CTIWind_89A09B02;
                        _CTIWind_89A09B02.ObjectSpaceNormal = IN.ObjectSpaceNormal;
                        _CTIWind_89A09B02.ObjectSpacePosition = IN.ObjectSpacePosition;
                        _CTIWind_89A09B02.VertexColor = IN.VertexColor;
                        _CTIWind_89A09B02.uv1 = IN.uv1;
                        _CTIWind_89A09B02.uv2 = IN.uv2;
                        float3 _CTIWind_89A09B02_Position_1;
                        float3 _CTIWind_89A09B02_Normal_2;
                        float _CTIWind_89A09B02_ColorVariation_3;
                        SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(0, 0, 0, 0, _Property_EC5ABF14_Out_0, 1, _CTIWind_89A09B02, _CTIWind_89A09B02_Position_1, _CTIWind_89A09B02_Normal_2, _CTIWind_89A09B02_ColorVariation_3);
                        description.VertexPosition = _CTIWind_89A09B02_Position_1;
                        description.VertexNormal = IN.ObjectSpaceNormal;
                        description.VertexTangent = IN.ObjectSpaceTangent;
                        return description;
                    }
                    
                // Pixel Graph Evaluation
                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        surface.Alpha = 1;
                        return surface;
                    }
                    
            //-------------------------------------------------------------------------------------
            // End graph generated code
            //-------------------------------------------------------------------------------------
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
            
            VertexDescriptionInputs AttributesMeshToVertexDescriptionInputs(AttributesMesh input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                // output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                // output.ViewSpaceNormal =             TransformWorldToViewDir(output.WorldSpaceNormal);
                // output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                output.ObjectSpaceTangent =          input.tangentOS;
                // output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
                // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                // output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
                // output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                output.ObjectSpacePosition =         input.positionOS;
                // output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                // output.ViewSpacePosition =           TransformWorldToView(output.WorldSpacePosition);
                // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(TransformObjectToWorld(input.positionOS));
                // output.WorldSpaceViewDirection =     GetWorldSpaceNormalizeViewDir(output.WorldSpacePosition);
                // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(output.WorldSpacePosition), _ProjectionParams.x);
                // output.uv0 =                         input.uv0;
                output.uv1 =                         input.uv1;
                output.uv2 =                         input.uv2;
                // output.uv3 =                         input.uv3;
                output.VertexColor =                 input.color;
            
                return output;
            }
            
            AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            {
                // build graph inputs
                VertexDescriptionInputs vertexDescriptionInputs = AttributesMeshToVertexDescriptionInputs(input);
                // Override time paramters with used one (This is required to correctly handle motion vector for vertex animation based on time)
                // vertexDescriptionInputs.TimeParameters = timeParameters;
            
                // evaluate vertex graph
                VertexDescription vertexDescription = VertexDescriptionFunction(vertexDescriptionInputs);
            
                // copy graph output to the results
                input.positionOS = vertexDescription.VertexPosition;
                input.normalOS = vertexDescription.VertexNormal;
                input.tangentOS.xyz = vertexDescription.VertexTangent;
            
                return input;
            }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
                FragInputs BuildFragInputs(VaryingsMeshToPS input)
                {
                    FragInputs output;
                    ZERO_INITIALIZE(FragInputs, output);
            
                    // Init to some default value to make the computer quiet (else it output 'divide by zero' warning even if value is not used).
                    // TODO: this is a really poor workaround, but the variable is used in a bunch of places
                    // to compute normals which are then passed on elsewhere to compute other values...
                    output.tangentToWorld = k_identity3x3;
                    output.positionSS = input.positionCS;       // input.positionCS is SV_Position
            
                    // output.positionRWS = input.positionRWS;
                    // output.tangentToWorld = BuildTangentToWorld(input.tangentWS, input.normalWS);
                    // output.texCoord0 = input.texCoord0;
                    // output.texCoord1 = input.texCoord1;
                    // output.texCoord2 = input.texCoord2;
                    // output.texCoord3 = input.texCoord3;
                    // output.color = input.color;
                    #if _DOUBLESIDED_ON && SHADER_STAGE_FRAGMENT
                    output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #elif SHADER_STAGE_FRAGMENT
                    // output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #endif // SHADER_STAGE_FRAGMENT
            
                    return output;
                }
            
                SurfaceDescriptionInputs FragInputsToSurfaceDescriptionInputs(FragInputs input, float3 viewWS)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                    // output.WorldSpaceNormal =            normalize(input.tangentToWorld[2].xyz);
                    // output.ObjectSpaceNormal =           mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M);           // transposed multiplication by inverse matrix to handle normal scale
                    // output.ViewSpaceNormal =             mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_I_V);         // transposed multiplication by inverse matrix to handle normal scale
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                    // output.WorldSpaceTangent =           input.tangentToWorld[0].xyz;
                    // output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
                    // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                    // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                    // output.WorldSpaceBiTangent =         input.tangentToWorld[1].xyz;
                    // output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
                    // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                    // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                    // output.WorldSpaceViewDirection =     normalize(viewWS);
                    // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                    // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                    // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                    // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    // output.WorldSpacePosition =          input.positionRWS;
                    // output.ObjectSpacePosition =         TransformWorldToObject(input.positionRWS);
                    // output.ViewSpacePosition =           TransformWorldToView(input.positionRWS);
                    // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                    // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionRWS);
                    // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionRWS), _ProjectionParams.x);
                    // output.uv0 =                         input.texCoord0;
                    // output.uv1 =                         input.texCoord1;
                    // output.uv2 =                         input.texCoord2;
                    // output.uv3 =                         input.texCoord3;
                    // output.VertexColor =                 input.color;
                    // output.FaceSign =                    input.isFrontFace;
                    // output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            
                    return output;
                }
            
                // existing HDRP code uses the combined function to go directly from packed to frag inputs
                FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    VaryingsMeshToPS unpacked= UnpackVaryingsMeshToPS(input);
                    return BuildFragInputs(unpacked);
                }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
            void BuildSurfaceData(FragInputs fragInputs, inout SurfaceDescription surfaceDescription, float3 V, PositionInputs posInput, out SurfaceData surfaceData, out float3 bentNormalWS)
            {
                // setup defaults -- these are used if the graph doesn't output a value
                ZERO_INITIALIZE(SurfaceData, surfaceData);
        
                // copy across graph values, if defined
                // surfaceData.baseColor =                 surfaceDescription.Albedo;
                // surfaceData.perceptualSmoothness =      surfaceDescription.Smoothness;
                // surfaceData.ambientOcclusion =          surfaceDescription.Occlusion;
                // surfaceData.specularOcclusion =         surfaceDescription.SpecularOcclusion;
                // surfaceData.metallic =                  surfaceDescription.Metallic;
                // surfaceData.subsurfaceMask =            surfaceDescription.SubsurfaceMask;
                // surfaceData.thickness =                 surfaceDescription.Thickness;
                // surfaceData.diffusionProfileHash =      asuint(surfaceDescription.DiffusionProfileHash);
                // surfaceData.specularColor =             surfaceDescription.Specular;
                // surfaceData.coatMask =                  surfaceDescription.CoatMask;
                // surfaceData.anisotropy =                surfaceDescription.Anisotropy;
                // surfaceData.iridescenceMask =           surfaceDescription.IridescenceMask;
                // surfaceData.iridescenceThickness =      surfaceDescription.IridescenceThickness;
        
        #ifdef _HAS_REFRACTION
                if (_EnableSSRefraction)
                {
                    // surfaceData.ior =                       surfaceDescription.RefractionIndex;
                    // surfaceData.transmittanceColor =        surfaceDescription.RefractionColor;
                    // surfaceData.atDistance =                surfaceDescription.RefractionDistance;
        
                    surfaceData.transmittanceMask = (1.0 - surfaceDescription.Alpha);
                    surfaceDescription.Alpha = 1.0;
                }
                else
                {
                    surfaceData.ior = 1.0;
                    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                    surfaceData.atDistance = 1.0;
                    surfaceData.transmittanceMask = 0.0;
                    surfaceDescription.Alpha = 1.0;
                }
        #else
                surfaceData.ior = 1.0;
                surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                surfaceData.atDistance = 1.0;
                surfaceData.transmittanceMask = 0.0;
        #endif
                
                // These static material feature allow compile time optimization
                surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
        #ifdef _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SUBSURFACE_SCATTERING;
        #endif
        #ifdef _MATERIAL_FEATURE_TRANSMISSION
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_TRANSMISSION;
        #endif
        #ifdef _MATERIAL_FEATURE_ANISOTROPY
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_ANISOTROPY;
        #endif
                // surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_CLEAR_COAT;
        
        #ifdef _MATERIAL_FEATURE_IRIDESCENCE
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_IRIDESCENCE;
        #endif
        #ifdef _MATERIAL_FEATURE_SPECULAR_COLOR
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SPECULAR_COLOR;
        #endif
        
        #if defined (_MATERIAL_FEATURE_SPECULAR_COLOR) && defined (_ENERGY_CONSERVING_SPECULAR)
                // Require to have setup baseColor
                // Reproduce the energy conservation done in legacy Unity. Not ideal but better for compatibility and users can unchek it
                surfaceData.baseColor *= (1.0 - Max3(surfaceData.specularColor.r, surfaceData.specularColor.g, surfaceData.specularColor.b));
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                // tangent-space normal
                float3 normalTS = float3(0.0f, 0.0f, 1.0f);
                // normalTS = surfaceDescription.Normal;
        
                // compute world space normal
                GetNormalWS(fragInputs, normalTS, surfaceData.normalWS, doubleSidedConstants);
        
                bentNormalWS = surfaceData.normalWS;
                // GetNormalWS(fragInputs, surfaceDescription.BentNormal, bentNormalWS, doubleSidedConstants);
        
                surfaceData.geomNormalWS = fragInputs.tangentToWorld[2];
        
                surfaceData.tangentWS = normalize(fragInputs.tangentToWorld[0].xyz);    // The tangent is not normalize in tangentToWorld for mikkt. TODO: Check if it expected that we normalize with Morten. Tag: SURFACE_GRADIENT
                // surfaceData.tangentWS = TransformTangentToWorld(surfaceDescription.Tangent, fragInputs.tangentToWorld);
                surfaceData.tangentWS = Orthonormalize(surfaceData.tangentWS, surfaceData.normalWS);
        
                // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
                // If user provide bent normal then we process a better term
        #if defined(_SPECULAR_OCCLUSION_CUSTOM)
                // Just use the value passed through via the slot (not active otherwise)
        #elif defined(_SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL)
                // If we have bent normal and ambient occlusion, process a specular occlusion
                surfaceData.specularOcclusion = GetSpecularOcclusionFromBentAO(V, bentNormalWS, surfaceData.normalWS, surfaceData.ambientOcclusion, PerceptualSmoothnessToPerceptualRoughness(surfaceData.perceptualSmoothness));
        #elif defined(_AMBIENT_OCCLUSION) && defined(_SPECULAR_OCCLUSION_FROM_AO)
                surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
        #else
                surfaceData.specularOcclusion = 1.0;
        #endif
        
        #if HAVE_DECALS
                if (_EnableDecals)
                {
                    DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, surfaceDescription.Alpha);
                    ApplyDecalToSurfaceData(decalSurfaceData, surfaceData);
                }
        #endif
        
        #ifdef _ENABLE_GEOMETRIC_SPECULAR_AA
                surfaceData.perceptualSmoothness = GeometricNormalFiltering(surfaceData.perceptualSmoothness, fragInputs.tangentToWorld[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif
        
        #ifdef DEBUG_DISPLAY
                if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
                {
                    // TODO: need to update mip info
                    surfaceData.metallic = 0;
                }
        
                // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
                // as it can modify attribute use for static lighting
                ApplyDebugToSurfaceData(fragInputs.tangentToWorld, surfaceData);
        #endif
            }
        
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
        #ifdef LOD_FADE_CROSSFADE // enable dithering LOD transition if user select CrossFade transition in LOD group
                uint3 fadeMaskSeed = asuint((int3)(V * _ScreenSize.xyx)); // Quantize V to _ScreenSize values
                LODDitheringTransition(fadeMaskSeed, unity_LODFade.x);
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                ApplyDoubleSidedFlipOrMirror(fragInputs, doubleSidedConstants);
        
                SurfaceDescriptionInputs surfaceDescriptionInputs = FragInputsToSurfaceDescriptionInputs(fragInputs, V);
                SurfaceDescription surfaceDescription = SurfaceDescriptionFunction(surfaceDescriptionInputs);
        
                // Perform alpha test very early to save performance (a killed pixel will not sample textures)
                // TODO: split graph evaluation to grab just alpha dependencies first? tricky..
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPrepass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPostpass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow);
                
                // ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
        
                float3 bentNormalWS;
                BuildSurfaceData(fragInputs, surfaceDescription, V, posInput, surfaceData, bentNormalWS);
        
                // Builtin Data
                // For back lighting we use the oposite vertex normal 
                InitBuiltinData(posInput, surfaceDescription.Alpha, bentNormalWS, -fragInputs.tangentToWorld[2], fragInputs.texCoord1, fragInputs.texCoord2, builtinData);
        
                // override sampleBakedGI:
                // builtinData.bakeDiffuseLighting = surfaceDescription.BakedGI;
                // builtinData.backBakeDiffuseLighting = surfaceDescription.BakedBackGI;
        
                // builtinData.emissiveColor = surfaceDescription.Emission;
        
                // builtinData.depthOffset = surfaceDescription.DepthOffset;
        
        #if (SHADERPASS == SHADERPASS_DISTORTION)
                builtinData.distortion = surfaceDescription.Distortion;
                builtinData.distortionBlur = surfaceDescription.DistortionBlur;
        #else
                builtinData.distortion = float2(0.0, 0.0);
                builtinData.distortionBlur = 0.0;
        #endif
        
                PostInitBuiltinData(V, posInput, surfaceData, builtinData);
            }
        
            //-------------------------------------------------------------------------------------
            // Pass Includes
            //-------------------------------------------------------------------------------------
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"
            //-------------------------------------------------------------------------------------
            // End Pass Includes
            //-------------------------------------------------------------------------------------
        
            ENDHLSL
        }
        
        Pass
        {
            // based on HDLitPass.template
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
        
            //-------------------------------------------------------------------------------------
            // Render Modes (Blend, Cull, ZTest, Stencil, etc)
            //-------------------------------------------------------------------------------------
            
            Cull [_CullMode]
        
            
            ZWrite On
        
            
            // Stencil setup
        Stencil
        {
           WriteMask [_StencilWriteMaskDepth]
           Ref [_StencilRefDepth]
           Comp Always
           Pass Replace
        }
        
            
            //-------------------------------------------------------------------------------------
            // End Render Modes
            //-------------------------------------------------------------------------------------
        
            HLSLPROGRAM
        
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //#pragma enable_d3d11_debug_symbols
        
            #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        
            #pragma multi_compile _ LOD_FADE_CROSSFADE
        
            // #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _DOUBLESIDED_ON
            // #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
        
            //-------------------------------------------------------------------------------------
            // Variant Definitions (active field translations to HDRP defines)
            //-------------------------------------------------------------------------------------
            // #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING 1
            // #define _MATERIAL_FEATURE_TRANSMISSION 1
            // #define _MATERIAL_FEATURE_ANISOTROPY 1
            // #define _MATERIAL_FEATURE_IRIDESCENCE 1
            // #define _MATERIAL_FEATURE_SPECULAR_COLOR 1
            // #define _ENABLE_FOG_ON_TRANSPARENT 1
            #define _AMBIENT_OCCLUSION 1
            #define _SPECULAR_OCCLUSION_FROM_AO 1
            // #define _SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL 1
            // #define _SPECULAR_OCCLUSION_CUSTOM 1
            #define _ENERGY_CONSERVING_SPECULAR 1
            // #define _ENABLE_GEOMETRIC_SPECULAR_AA 1
            // #define _HAS_REFRACTION 1
            // #define _REFRACTION_PLANE 1
            // #define _REFRACTION_SPHERE 1
            // #define _DISABLE_DECALS 1
            #define _DISABLE_SSR 1
            // #define _ADD_PRECOMPUTED_VELOCITY
            // #define _WRITE_TRANSPARENT_MOTION_VECTOR 1
            // #define _DEPTHOFFSET_ON 1
            // #define _BLENDMODE_PRESERVE_SPECULAR_LIGHTING 1
        
            //-------------------------------------------------------------------------------------
            // End Variant Definitions
            //-------------------------------------------------------------------------------------
        
            #pragma vertex Vert
            #pragma fragment Frag
        
            // If we use subsurface scattering, enable output split lighting (for forward pass)
            #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
            #define OUTPUT_SPLIT_LIGHTING
            #endif
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
        
            // define FragInputs structure
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
        
            //-------------------------------------------------------------------------------------
            // Defines
            //-------------------------------------------------------------------------------------
                    #define SHADERPASS SHADERPASS_DEPTH_ONLY
                #pragma multi_compile _ WRITE_NORMAL_BUFFER
                #pragma multi_compile _ WRITE_MSAA_DEPTH
                #define RAYTRACING_SHADER_GRAPH_HIGH
                // ACTIVE FIELDS:
                //   Material.Standard
                //   DisableSSR
                //   Specular.EnergyConserving
                //   SurfaceDescriptionInputs.TangentSpaceNormal
                //   SurfaceDescriptionInputs.uv0
                //   VertexDescriptionInputs.VertexColor
                //   VertexDescriptionInputs.ObjectSpaceNormal
                //   VertexDescriptionInputs.ObjectSpaceTangent
                //   VertexDescriptionInputs.ObjectSpacePosition
                //   VertexDescriptionInputs.uv1
                //   VertexDescriptionInputs.uv2
                //   SurfaceDescription.Normal
                //   SurfaceDescription.Smoothness
                //   SurfaceDescription.Alpha
                //   features.modifyMesh
                //   VertexDescription.VertexPosition
                //   VertexDescription.VertexNormal
                //   VertexDescription.VertexTangent
                //   AttributesMesh.normalOS
                //   AttributesMesh.tangentOS
                //   AttributesMesh.uv0
                //   AttributesMesh.uv1
                //   AttributesMesh.color
                //   AttributesMesh.uv2
                //   AttributesMesh.uv3
                //   FragInputs.tangentToWorld
                //   FragInputs.positionRWS
                //   FragInputs.texCoord0
                //   FragInputs.texCoord1
                //   FragInputs.texCoord2
                //   FragInputs.texCoord3
                //   FragInputs.color
                //   AttributesMesh.positionOS
                //   VaryingsMeshToPS.tangentWS
                //   VaryingsMeshToPS.normalWS
                //   VaryingsMeshToPS.positionRWS
                //   VaryingsMeshToPS.texCoord0
                //   VaryingsMeshToPS.texCoord1
                //   VaryingsMeshToPS.texCoord2
                //   VaryingsMeshToPS.texCoord3
                //   VaryingsMeshToPS.color
                // Shared Graph Keywords
        
            // this translates the new dependency tracker into the old preprocessor definitions for the existing HDRP shader code
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define ATTRIBUTES_NEED_TEXCOORD3
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TANGENT_TO_WORLD
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_TEXCOORD1
            #define VARYINGS_NEED_TEXCOORD2
            #define VARYINGS_NEED_TEXCOORD3
            #define VARYINGS_NEED_COLOR
            // #define VARYINGS_NEED_CULLFACE
            #define HAVE_MESH_MODIFICATION
        
        // We need isFontFace when using double sided
        #if defined(_DOUBLESIDED_ON) && !defined(VARYINGS_NEED_CULLFACE)
            #define VARYINGS_NEED_CULLFACE
        #endif
        
            //-------------------------------------------------------------------------------------
            // End Defines
            //-------------------------------------------------------------------------------------
            
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
        
        #if (SHADERPASS == SHADERPASS_FORWARD)
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        
            #define HAS_LIGHTLOOP
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"
        #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDecalData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"
        
            // Used by SceneSelectionPass
            int _ObjectId;
            int _PassValue;
        
            //-------------------------------------------------------------------------------------
            // Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
            // Generated Type: AttributesMesh
            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL; // optional
                float4 tangentOS : TANGENT; // optional
                float4 uv0 : TEXCOORD0; // optional
                float4 uv1 : TEXCOORD1; // optional
                float4 uv2 : TEXCOORD2; // optional
                float4 uv3 : TEXCOORD3; // optional
                float4 color : COLOR; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            // Generated Type: VaryingsMeshToPS
            struct VaryingsMeshToPS
            {
                float4 positionCS : SV_Position;
                float3 positionRWS; // optional
                float3 normalWS; // optional
                float4 tangentWS; // optional
                float4 texCoord0; // optional
                float4 texCoord1; // optional
                float4 texCoord2; // optional
                float4 texCoord3; // optional
                float4 color; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif // defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            };
            
            // Generated Type: PackedVaryingsMeshToPS
            struct PackedVaryingsMeshToPS
            {
                float4 positionCS : SV_Position; // unpacked
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
                float4 interp02 : TEXCOORD2; // auto-packed
                float4 interp03 : TEXCOORD3; // auto-packed
                float4 interp04 : TEXCOORD4; // auto-packed
                float4 interp05 : TEXCOORD5; // auto-packed
                float4 interp06 : TEXCOORD6; // auto-packed
                float4 interp07 : TEXCOORD7; // auto-packed
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC; // unpacked
                #endif // conditional
            };
            
            // Packed Type: VaryingsMeshToPS
            PackedVaryingsMeshToPS PackVaryingsMeshToPS(VaryingsMeshToPS input)
            {
                PackedVaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                output.interp02.xyzw = input.tangentWS;
                output.interp03.xyzw = input.texCoord0;
                output.interp04.xyzw = input.texCoord1;
                output.interp05.xyzw = input.texCoord2;
                output.interp06.xyzw = input.texCoord3;
                output.interp07.xyzw = input.color;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToPS
            VaryingsMeshToPS UnpackVaryingsMeshToPS(PackedVaryingsMeshToPS input)
            {
                VaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                output.tangentWS = input.interp02.xyzw;
                output.texCoord0 = input.interp03.xyzw;
                output.texCoord1 = input.interp04.xyzw;
                output.texCoord2 = input.interp05.xyzw;
                output.texCoord3 = input.interp06.xyzw;
                output.color = input.interp07.xyzw;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            // Generated Type: VaryingsMeshToDS
            struct VaryingsMeshToDS
            {
                float3 positionRWS;
                float3 normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            
            // Generated Type: PackedVaryingsMeshToDS
            struct PackedVaryingsMeshToDS
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
            };
            
            // Packed Type: VaryingsMeshToDS
            PackedVaryingsMeshToDS PackVaryingsMeshToDS(VaryingsMeshToDS input)
            {
                PackedVaryingsMeshToDS output;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToDS
            VaryingsMeshToDS UnpackVaryingsMeshToDS(PackedVaryingsMeshToDS input)
            {
                VaryingsMeshToDS output;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            //-------------------------------------------------------------------------------------
            // End Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
        
            //-------------------------------------------------------------------------------------
            // Graph generated code
            //-------------------------------------------------------------------------------------
                    // Shared Graph Properties (uniform inputs)
                    CBUFFER_START(UnityPerMaterial)
                    float _NormalStrength; float _Smoothness;
                    float3 _WindMultipliers;
                    float4 _EmissionColor;
                    float _RenderQueueType;
                    float _StencilRef;
                    float _StencilWriteMask;
                    float _StencilRefDepth;
                    float _StencilWriteMaskDepth;
                    float _StencilRefMV;
                    float _StencilWriteMaskMV;
                    float _StencilRefDistortionVec;
                    float _StencilWriteMaskDistortionVec;
                    float _StencilWriteMaskGBuffer;
                    float _StencilRefGBuffer;
                    float _ZTestGBuffer;
                    float _RequireSplitLighting;
                    float _ReceivesSSR;
                    float _SurfaceType;
                    float _BlendMode;
                    float _SrcBlend;
                    float _DstBlend;
                    float _AlphaSrcBlend;
                    float _AlphaDstBlend;
                    float _ZWrite;
                    float _CullMode;
                    float _TransparentSortPriority;
                    float _CullModeForward;
                    float _TransparentCullMode;
                    float _ZTestDepthEqualForOpaque;
                    float _ZTestTransparent;
                    float _TransparentBackfaceEnable;
                    float _AlphaCutoffEnable;
                    float _UseShadowThreshold;
                    float _DoubleSidedEnable;
                    float _DoubleSidedNormalMode;
                    float4 _DoubleSidedConstants;
                    CBUFFER_END
                    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;
                    TEXTURE2D(_BumpSpecAOMap); SAMPLER(sampler_BumpSpecAOMap); float4 _BumpSpecAOMap_TexelSize;
                    SAMPLER(_SampleTexture2D_EC10A3ED_Sampler_3_Linear_Repeat);
                    SAMPLER(_SampleTexture2D_1060DFD5_Sampler_3_Linear_Repeat);
                
                // Vertex Graph Inputs
                    struct VertexDescriptionInputs
                    {
                        float3 ObjectSpaceNormal; // optional
                        float3 ObjectSpaceTangent; // optional
                        float3 ObjectSpacePosition; // optional
                        float4 uv1; // optional
                        float4 uv2; // optional
                        float4 VertexColor; // optional
                    };
                // Vertex Graph Outputs
                    struct VertexDescription
                    {
                        float3 VertexPosition;
                        float3 VertexNormal;
                        float3 VertexTangent;
                    };
                    
                // Pixel Graph Inputs
                    struct SurfaceDescriptionInputs
                    {
                        float3 TangentSpaceNormal; // optional
                        float4 uv0; // optional
                    };
                // Pixel Graph Outputs
                    struct SurfaceDescription
                    {
                        float3 Normal;
                        float Smoothness;
                        float Alpha;
                    };
                    
                // Shared Graph Node Functions
                
                    void UnpackCustomNormal_float(float4 normalSample, out float3 normalOut)
                    {
                        normalOut.xy = normalSample.ag;
                        normalOut.xy = normalOut.xy * 2 - 1;
                        normalOut.z = sqrt( 1 - dot(normalOut.xy , normalOut.xy ));
                    }
                
                    void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
                    {
                        Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
                    }
                
                    // dcd3c055367822a77956a73ac0a83c36
                    #include "/Includes/CTI_HDRP_Wind.hlsl"
                
                    struct Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8
                    {
                        float3 ObjectSpaceNormal;
                        float3 ObjectSpacePosition;
                        float4 VertexColor;
                        half4 uv1;
                        half4 uv2;
                    };
                
                    void SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(float Vector1_5B3F28E6, float Vector1_39544515, float Vector1_E70341A3, float Vector1_D355D6, float3 Vector3_D146D8D7, float Boolean_BA69BFA3, Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 IN, out float3 Position_1, out float3 Normal_2, out float ColorVariation_3)
                    {
                        float4 _UV_681BEC06_Out_0 = IN.uv1;
                        float4 _UV_5EAEC7D4_Out_0 = IN.uv2;
                        float _Property_66DDE654_Out_0 = Vector1_5B3F28E6;
                        float _Property_F63DDA84_Out_0 = Vector1_39544515;
                        float _Property_32CC05D1_Out_0 = Vector1_E70341A3;
                        float _Property_550822E2_Out_0 = Vector1_D355D6;
                        float3 _Property_9A8CF22B_Out_0 = Vector3_D146D8D7;
                        float _Property_7647AB6A_Out_0 = Boolean_BA69BFA3;
                        float3 _CustomFunction_4DA71B86_position1_10;
                        float3 _CustomFunction_4DA71B86_normal1_11;
                        float _CustomFunction_4DA71B86_color_12;
                        ApplyCTIWind_float(IN.ObjectSpacePosition, IN.VertexColor, (_UV_681BEC06_Out_0.xy), (_UV_5EAEC7D4_Out_0.xy), IN.ObjectSpaceNormal, _Property_66DDE654_Out_0, _Property_F63DDA84_Out_0, _Property_32CC05D1_Out_0, _Property_550822E2_Out_0, _Property_9A8CF22B_Out_0, _Property_7647AB6A_Out_0, _CustomFunction_4DA71B86_position1_10, _CustomFunction_4DA71B86_normal1_11, _CustomFunction_4DA71B86_color_12);
                        Position_1 = _CustomFunction_4DA71B86_position1_10;
                        Normal_2 = _CustomFunction_4DA71B86_normal1_11;
                        ColorVariation_3 = _CustomFunction_4DA71B86_color_12;
                    }
                
                // Vertex Graph Evaluation
                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        float3 _Property_EC5ABF14_Out_0 = _WindMultipliers;
                        Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 _CTIWind_89A09B02;
                        _CTIWind_89A09B02.ObjectSpaceNormal = IN.ObjectSpaceNormal;
                        _CTIWind_89A09B02.ObjectSpacePosition = IN.ObjectSpacePosition;
                        _CTIWind_89A09B02.VertexColor = IN.VertexColor;
                        _CTIWind_89A09B02.uv1 = IN.uv1;
                        _CTIWind_89A09B02.uv2 = IN.uv2;
                        float3 _CTIWind_89A09B02_Position_1;
                        float3 _CTIWind_89A09B02_Normal_2;
                        float _CTIWind_89A09B02_ColorVariation_3;
                        SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(0, 0, 0, 0, _Property_EC5ABF14_Out_0, 1, _CTIWind_89A09B02, _CTIWind_89A09B02_Position_1, _CTIWind_89A09B02_Normal_2, _CTIWind_89A09B02_ColorVariation_3);
                        description.VertexPosition = _CTIWind_89A09B02_Position_1;
                        description.VertexNormal = IN.ObjectSpaceNormal;
                        description.VertexTangent = IN.ObjectSpaceTangent;
                        return description;
                    }
                    
                // Pixel Graph Evaluation
                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        float4 _SampleTexture2D_EC10A3ED_RGBA_0 = SAMPLE_TEXTURE2D(_BumpSpecAOMap, sampler_BumpSpecAOMap, IN.uv0.xy);
                        float _SampleTexture2D_EC10A3ED_R_4 = _SampleTexture2D_EC10A3ED_RGBA_0.r;
                        float _SampleTexture2D_EC10A3ED_G_5 = _SampleTexture2D_EC10A3ED_RGBA_0.g;
                        float _SampleTexture2D_EC10A3ED_B_6 = _SampleTexture2D_EC10A3ED_RGBA_0.b;
                        float _SampleTexture2D_EC10A3ED_A_7 = _SampleTexture2D_EC10A3ED_RGBA_0.a;
                        float3 _CustomFunction_CF03AB98_normalOut_1;
                        UnpackCustomNormal_float(_SampleTexture2D_EC10A3ED_RGBA_0, _CustomFunction_CF03AB98_normalOut_1);
                        float _Property_C6B71BE6_Out_0 = _NormalStrength;
                        float3 _NormalStrength_AA429D2D_Out_2;
                        Unity_NormalStrength_float(_CustomFunction_CF03AB98_normalOut_1, _Property_C6B71BE6_Out_0, _NormalStrength_AA429D2D_Out_2);
                        float4 _SampleTexture2D_1060DFD5_RGBA_0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0.xy);
                        float _SampleTexture2D_1060DFD5_R_4 = _SampleTexture2D_1060DFD5_RGBA_0.r;
                        float _SampleTexture2D_1060DFD5_G_5 = _SampleTexture2D_1060DFD5_RGBA_0.g;
                        float _SampleTexture2D_1060DFD5_B_6 = _SampleTexture2D_1060DFD5_RGBA_0.b;
                        float _SampleTexture2D_1060DFD5_A_7 = _SampleTexture2D_1060DFD5_RGBA_0.a;
                        surface.Normal = _NormalStrength_AA429D2D_Out_2;
                        surface.Smoothness = _SampleTexture2D_1060DFD5_A_7 * _Smoothness;
                        surface.Alpha = 1;
                        return surface;
                    }
                    
            //-------------------------------------------------------------------------------------
            // End graph generated code
            //-------------------------------------------------------------------------------------
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
            
            VertexDescriptionInputs AttributesMeshToVertexDescriptionInputs(AttributesMesh input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                // output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                // output.ViewSpaceNormal =             TransformWorldToViewDir(output.WorldSpaceNormal);
                // output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                output.ObjectSpaceTangent =          input.tangentOS;
                // output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
                // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                // output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
                // output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                output.ObjectSpacePosition =         input.positionOS;
                // output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                // output.ViewSpacePosition =           TransformWorldToView(output.WorldSpacePosition);
                // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(TransformObjectToWorld(input.positionOS));
                // output.WorldSpaceViewDirection =     GetWorldSpaceNormalizeViewDir(output.WorldSpacePosition);
                // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(output.WorldSpacePosition), _ProjectionParams.x);
                // output.uv0 =                         input.uv0;
                output.uv1 =                         input.uv1;
                output.uv2 =                         input.uv2;
                // output.uv3 =                         input.uv3;
                output.VertexColor =                 input.color;
            
                return output;
            }
            
            AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            {
                // build graph inputs
                VertexDescriptionInputs vertexDescriptionInputs = AttributesMeshToVertexDescriptionInputs(input);
                // Override time paramters with used one (This is required to correctly handle motion vector for vertex animation based on time)
                // vertexDescriptionInputs.TimeParameters = timeParameters;
            
                // evaluate vertex graph
                VertexDescription vertexDescription = VertexDescriptionFunction(vertexDescriptionInputs);
            
                // copy graph output to the results
                input.positionOS = vertexDescription.VertexPosition;
                input.normalOS = vertexDescription.VertexNormal;
                input.tangentOS.xyz = vertexDescription.VertexTangent;
            
                return input;
            }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
                FragInputs BuildFragInputs(VaryingsMeshToPS input)
                {
                    FragInputs output;
                    ZERO_INITIALIZE(FragInputs, output);
            
                    // Init to some default value to make the computer quiet (else it output 'divide by zero' warning even if value is not used).
                    // TODO: this is a really poor workaround, but the variable is used in a bunch of places
                    // to compute normals which are then passed on elsewhere to compute other values...
                    output.tangentToWorld = k_identity3x3;
                    output.positionSS = input.positionCS;       // input.positionCS is SV_Position
            
                    output.positionRWS = input.positionRWS;
                    output.tangentToWorld = BuildTangentToWorld(input.tangentWS, input.normalWS);
                    output.texCoord0 = input.texCoord0;
                    output.texCoord1 = input.texCoord1;
                    output.texCoord2 = input.texCoord2;
                    output.texCoord3 = input.texCoord3;
                    output.color = input.color;
                    #if _DOUBLESIDED_ON && SHADER_STAGE_FRAGMENT
                    output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #elif SHADER_STAGE_FRAGMENT
                    // output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #endif // SHADER_STAGE_FRAGMENT
            
                    return output;
                }
            
                SurfaceDescriptionInputs FragInputsToSurfaceDescriptionInputs(FragInputs input, float3 viewWS)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                    // output.WorldSpaceNormal =            normalize(input.tangentToWorld[2].xyz);
                    // output.ObjectSpaceNormal =           mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M);           // transposed multiplication by inverse matrix to handle normal scale
                    // output.ViewSpaceNormal =             mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_I_V);         // transposed multiplication by inverse matrix to handle normal scale
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                    // output.WorldSpaceTangent =           input.tangentToWorld[0].xyz;
                    // output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
                    // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                    // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                    // output.WorldSpaceBiTangent =         input.tangentToWorld[1].xyz;
                    // output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
                    // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                    // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                    // output.WorldSpaceViewDirection =     normalize(viewWS);
                    // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                    // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                    // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                    // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    // output.WorldSpacePosition =          input.positionRWS;
                    // output.ObjectSpacePosition =         TransformWorldToObject(input.positionRWS);
                    // output.ViewSpacePosition =           TransformWorldToView(input.positionRWS);
                    // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                    // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionRWS);
                    // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionRWS), _ProjectionParams.x);
                    output.uv0 =                         input.texCoord0;
                    // output.uv1 =                         input.texCoord1;
                    // output.uv2 =                         input.texCoord2;
                    // output.uv3 =                         input.texCoord3;
                    // output.VertexColor =                 input.color;
                    // output.FaceSign =                    input.isFrontFace;
                    // output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            
                    return output;
                }
            
                // existing HDRP code uses the combined function to go directly from packed to frag inputs
                FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    VaryingsMeshToPS unpacked= UnpackVaryingsMeshToPS(input);
                    return BuildFragInputs(unpacked);
                }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
            void BuildSurfaceData(FragInputs fragInputs, inout SurfaceDescription surfaceDescription, float3 V, PositionInputs posInput, out SurfaceData surfaceData, out float3 bentNormalWS)
            {
                // setup defaults -- these are used if the graph doesn't output a value
                ZERO_INITIALIZE(SurfaceData, surfaceData);
        
                // copy across graph values, if defined
                // surfaceData.baseColor =                 surfaceDescription.Albedo;
                surfaceData.perceptualSmoothness =      surfaceDescription.Smoothness;
                // surfaceData.ambientOcclusion =          surfaceDescription.Occlusion;
                // surfaceData.specularOcclusion =         surfaceDescription.SpecularOcclusion;
                // surfaceData.metallic =                  surfaceDescription.Metallic;
                // surfaceData.subsurfaceMask =            surfaceDescription.SubsurfaceMask;
                // surfaceData.thickness =                 surfaceDescription.Thickness;
                // surfaceData.diffusionProfileHash =      asuint(surfaceDescription.DiffusionProfileHash);
                // surfaceData.specularColor =             surfaceDescription.Specular;
                // surfaceData.coatMask =                  surfaceDescription.CoatMask;
                // surfaceData.anisotropy =                surfaceDescription.Anisotropy;
                // surfaceData.iridescenceMask =           surfaceDescription.IridescenceMask;
                // surfaceData.iridescenceThickness =      surfaceDescription.IridescenceThickness;
        
        #ifdef _HAS_REFRACTION
                if (_EnableSSRefraction)
                {
                    // surfaceData.ior =                       surfaceDescription.RefractionIndex;
                    // surfaceData.transmittanceColor =        surfaceDescription.RefractionColor;
                    // surfaceData.atDistance =                surfaceDescription.RefractionDistance;
        
                    surfaceData.transmittanceMask = (1.0 - surfaceDescription.Alpha);
                    surfaceDescription.Alpha = 1.0;
                }
                else
                {
                    surfaceData.ior = 1.0;
                    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                    surfaceData.atDistance = 1.0;
                    surfaceData.transmittanceMask = 0.0;
                    surfaceDescription.Alpha = 1.0;
                }
        #else
                surfaceData.ior = 1.0;
                surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                surfaceData.atDistance = 1.0;
                surfaceData.transmittanceMask = 0.0;
        #endif
                
                // These static material feature allow compile time optimization
                surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
        #ifdef _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SUBSURFACE_SCATTERING;
        #endif
        #ifdef _MATERIAL_FEATURE_TRANSMISSION
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_TRANSMISSION;
        #endif
        #ifdef _MATERIAL_FEATURE_ANISOTROPY
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_ANISOTROPY;
        #endif
                // surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_CLEAR_COAT;
        
        #ifdef _MATERIAL_FEATURE_IRIDESCENCE
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_IRIDESCENCE;
        #endif
        #ifdef _MATERIAL_FEATURE_SPECULAR_COLOR
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SPECULAR_COLOR;
        #endif
        
        #if defined (_MATERIAL_FEATURE_SPECULAR_COLOR) && defined (_ENERGY_CONSERVING_SPECULAR)
                // Require to have setup baseColor
                // Reproduce the energy conservation done in legacy Unity. Not ideal but better for compatibility and users can unchek it
                surfaceData.baseColor *= (1.0 - Max3(surfaceData.specularColor.r, surfaceData.specularColor.g, surfaceData.specularColor.b));
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                // tangent-space normal
                float3 normalTS = float3(0.0f, 0.0f, 1.0f);
                normalTS = surfaceDescription.Normal;
        
                // compute world space normal
                GetNormalWS(fragInputs, normalTS, surfaceData.normalWS, doubleSidedConstants);
        
                bentNormalWS = surfaceData.normalWS;
                // GetNormalWS(fragInputs, surfaceDescription.BentNormal, bentNormalWS, doubleSidedConstants);
        
                surfaceData.geomNormalWS = fragInputs.tangentToWorld[2];
        
                surfaceData.tangentWS = normalize(fragInputs.tangentToWorld[0].xyz);    // The tangent is not normalize in tangentToWorld for mikkt. TODO: Check if it expected that we normalize with Morten. Tag: SURFACE_GRADIENT
                // surfaceData.tangentWS = TransformTangentToWorld(surfaceDescription.Tangent, fragInputs.tangentToWorld);
                surfaceData.tangentWS = Orthonormalize(surfaceData.tangentWS, surfaceData.normalWS);
        
                // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
                // If user provide bent normal then we process a better term
        #if defined(_SPECULAR_OCCLUSION_CUSTOM)
                // Just use the value passed through via the slot (not active otherwise)
        #elif defined(_SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL)
                // If we have bent normal and ambient occlusion, process a specular occlusion
                surfaceData.specularOcclusion = GetSpecularOcclusionFromBentAO(V, bentNormalWS, surfaceData.normalWS, surfaceData.ambientOcclusion, PerceptualSmoothnessToPerceptualRoughness(surfaceData.perceptualSmoothness));
        #elif defined(_AMBIENT_OCCLUSION) && defined(_SPECULAR_OCCLUSION_FROM_AO)
                surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
        #else
                surfaceData.specularOcclusion = 1.0;
        #endif
        
        #if HAVE_DECALS
                if (_EnableDecals)
                {
                    DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, surfaceDescription.Alpha);
                    ApplyDecalToSurfaceData(decalSurfaceData, surfaceData);
                }
        #endif
        
        #ifdef _ENABLE_GEOMETRIC_SPECULAR_AA
                surfaceData.perceptualSmoothness = GeometricNormalFiltering(surfaceData.perceptualSmoothness, fragInputs.tangentToWorld[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif
        
        #ifdef DEBUG_DISPLAY
                if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
                {
                    // TODO: need to update mip info
                    surfaceData.metallic = 0;
                }
        
                // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
                // as it can modify attribute use for static lighting
                ApplyDebugToSurfaceData(fragInputs.tangentToWorld, surfaceData);
        #endif
            }
        
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
        #ifdef LOD_FADE_CROSSFADE // enable dithering LOD transition if user select CrossFade transition in LOD group
                uint3 fadeMaskSeed = asuint((int3)(V * _ScreenSize.xyx)); // Quantize V to _ScreenSize values
                LODDitheringTransition(fadeMaskSeed, unity_LODFade.x);
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                ApplyDoubleSidedFlipOrMirror(fragInputs, doubleSidedConstants);
        
                SurfaceDescriptionInputs surfaceDescriptionInputs = FragInputsToSurfaceDescriptionInputs(fragInputs, V);
                SurfaceDescription surfaceDescription = SurfaceDescriptionFunction(surfaceDescriptionInputs);
        
                // Perform alpha test very early to save performance (a killed pixel will not sample textures)
                // TODO: split graph evaluation to grab just alpha dependencies first? tricky..
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPrepass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPostpass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow);
                
                // ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
        
                float3 bentNormalWS;
                BuildSurfaceData(fragInputs, surfaceDescription, V, posInput, surfaceData, bentNormalWS);
        
                // Builtin Data
                // For back lighting we use the oposite vertex normal 
                InitBuiltinData(posInput, surfaceDescription.Alpha, bentNormalWS, -fragInputs.tangentToWorld[2], fragInputs.texCoord1, fragInputs.texCoord2, builtinData);
        
                // override sampleBakedGI:
                // builtinData.bakeDiffuseLighting = surfaceDescription.BakedGI;
                // builtinData.backBakeDiffuseLighting = surfaceDescription.BakedBackGI;
        
                // builtinData.emissiveColor = surfaceDescription.Emission;
        
                // builtinData.depthOffset = surfaceDescription.DepthOffset;
        
        #if (SHADERPASS == SHADERPASS_DISTORTION)
                builtinData.distortion = surfaceDescription.Distortion;
                builtinData.distortionBlur = surfaceDescription.DistortionBlur;
        #else
                builtinData.distortion = float2(0.0, 0.0);
                builtinData.distortionBlur = 0.0;
        #endif
        
                PostInitBuiltinData(V, posInput, surfaceData, builtinData);
            }
        
            //-------------------------------------------------------------------------------------
            // Pass Includes
            //-------------------------------------------------------------------------------------
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"
            //-------------------------------------------------------------------------------------
            // End Pass Includes
            //-------------------------------------------------------------------------------------
        
            ENDHLSL
        }
        
        Pass
        {
            // based on HDLitPass.template
            Name "GBuffer"
            Tags { "LightMode" = "GBuffer" }
        
            //-------------------------------------------------------------------------------------
            // Render Modes (Blend, Cull, ZTest, Stencil, etc)
            //-------------------------------------------------------------------------------------
            
            Cull [_CullMode]
        
            ZTest [_ZTestGBuffer]
        
            
            
            // Stencil setup
        Stencil
        {
           WriteMask [_StencilWriteMaskGBuffer]
           Ref [_StencilRefGBuffer]
           Comp Always
           Pass Replace
        }
        
            
            //-------------------------------------------------------------------------------------
            // End Render Modes
            //-------------------------------------------------------------------------------------
        
            HLSLPROGRAM
        
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //#pragma enable_d3d11_debug_symbols
        
            #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        
            #pragma multi_compile _ LOD_FADE_CROSSFADE
        
            // #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _DOUBLESIDED_ON
            // #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
        
            //-------------------------------------------------------------------------------------
            // Variant Definitions (active field translations to HDRP defines)
            //-------------------------------------------------------------------------------------
            // #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING 1
            // #define _MATERIAL_FEATURE_TRANSMISSION 1
            // #define _MATERIAL_FEATURE_ANISOTROPY 1
            // #define _MATERIAL_FEATURE_IRIDESCENCE 1
            // #define _MATERIAL_FEATURE_SPECULAR_COLOR 1
            // #define _ENABLE_FOG_ON_TRANSPARENT 1
            #define _AMBIENT_OCCLUSION 1
            #define _SPECULAR_OCCLUSION_FROM_AO 1
            // #define _SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL 1
            // #define _SPECULAR_OCCLUSION_CUSTOM 1
            #define _ENERGY_CONSERVING_SPECULAR 1
            // #define _ENABLE_GEOMETRIC_SPECULAR_AA 1
            // #define _HAS_REFRACTION 1
            // #define _REFRACTION_PLANE 1
            // #define _REFRACTION_SPHERE 1
            // #define _DISABLE_DECALS 1
            #define _DISABLE_SSR 1
            // #define _ADD_PRECOMPUTED_VELOCITY
            // #define _WRITE_TRANSPARENT_MOTION_VECTOR 1
            // #define _DEPTHOFFSET_ON 1
            // #define _BLENDMODE_PRESERVE_SPECULAR_LIGHTING 1
        
            //-------------------------------------------------------------------------------------
            // End Variant Definitions
            //-------------------------------------------------------------------------------------
        
            #pragma vertex Vert
            #pragma fragment Frag
        
            // If we use subsurface scattering, enable output split lighting (for forward pass)
            #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
            #define OUTPUT_SPLIT_LIGHTING
            #endif
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
        
            // define FragInputs structure
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
        
            //-------------------------------------------------------------------------------------
            // Defines
            //-------------------------------------------------------------------------------------
                    #define SHADERPASS SHADERPASS_GBUFFER
                #pragma multi_compile _ DEBUG_DISPLAY
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ DYNAMICLIGHTMAP_ON
                #pragma multi_compile _ SHADOWS_SHADOWMASK
                #pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
                #pragma multi_compile _ LIGHT_LAYERS
                #define RAYTRACING_SHADER_GRAPH_HIGH
                // ACTIVE FIELDS:
                //   Material.Standard
                //   DisableSSR
                //   Specular.EnergyConserving
                //   AmbientOcclusion
                //   SurfaceDescriptionInputs.VertexColor
                //   SurfaceDescriptionInputs.TangentSpaceNormal
                //   SurfaceDescriptionInputs.uv0
                //   VertexDescriptionInputs.VertexColor
                //   VertexDescriptionInputs.ObjectSpaceNormal
                //   VertexDescriptionInputs.ObjectSpaceTangent
                //   VertexDescriptionInputs.ObjectSpacePosition
                //   VertexDescriptionInputs.uv1
                //   VertexDescriptionInputs.uv2
                //   SurfaceDescription.Albedo
                //   SurfaceDescription.Normal
                //   SurfaceDescription.BentNormal
                //   SurfaceDescription.CoatMask
                //   SurfaceDescription.Metallic
                //   SurfaceDescription.Emission
                //   SurfaceDescription.Smoothness
                //   SurfaceDescription.Occlusion
                //   SurfaceDescription.Alpha
                //   features.modifyMesh
                //   VertexDescription.VertexPosition
                //   VertexDescription.VertexNormal
                //   VertexDescription.VertexTangent
                //   FragInputs.tangentToWorld
                //   FragInputs.positionRWS
                //   FragInputs.texCoord1
                //   FragInputs.texCoord2
                //   FragInputs.color
                //   FragInputs.texCoord0
                //   AttributesMesh.color
                //   AttributesMesh.normalOS
                //   AttributesMesh.tangentOS
                //   AttributesMesh.positionOS
                //   AttributesMesh.uv1
                //   AttributesMesh.uv2
                //   VaryingsMeshToPS.tangentWS
                //   VaryingsMeshToPS.normalWS
                //   VaryingsMeshToPS.positionRWS
                //   VaryingsMeshToPS.texCoord1
                //   VaryingsMeshToPS.texCoord2
                //   VaryingsMeshToPS.color
                //   VaryingsMeshToPS.texCoord0
                //   AttributesMesh.uv0
                // Shared Graph Keywords
        
            // this translates the new dependency tracker into the old preprocessor definitions for the existing HDRP shader code
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            // #define ATTRIBUTES_NEED_TEXCOORD3
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TANGENT_TO_WORLD
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_TEXCOORD1
            #define VARYINGS_NEED_TEXCOORD2
            // #define VARYINGS_NEED_TEXCOORD3
            #define VARYINGS_NEED_COLOR
            // #define VARYINGS_NEED_CULLFACE
            #define HAVE_MESH_MODIFICATION
        
        // We need isFontFace when using double sided
        #if defined(_DOUBLESIDED_ON) && !defined(VARYINGS_NEED_CULLFACE)
            #define VARYINGS_NEED_CULLFACE
        #endif
        
            //-------------------------------------------------------------------------------------
            // End Defines
            //-------------------------------------------------------------------------------------
            
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
        
        #if (SHADERPASS == SHADERPASS_FORWARD)
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        
            #define HAS_LIGHTLOOP
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"
        #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDecalData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"
        
            // Used by SceneSelectionPass
            int _ObjectId;
            int _PassValue;
        
            //-------------------------------------------------------------------------------------
            // Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
            // Generated Type: AttributesMesh
            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL; // optional
                float4 tangentOS : TANGENT; // optional
                float4 uv0 : TEXCOORD0; // optional
                float4 uv1 : TEXCOORD1; // optional
                float4 uv2 : TEXCOORD2; // optional
                float4 color : COLOR; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            // Generated Type: VaryingsMeshToPS
            struct VaryingsMeshToPS
            {
                float4 positionCS : SV_Position;
                float3 positionRWS; // optional
                float3 normalWS; // optional
                float4 tangentWS; // optional
                float4 texCoord0; // optional
                float4 texCoord1; // optional
                float4 texCoord2; // optional
                float4 color; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif // defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            };
            
            // Generated Type: PackedVaryingsMeshToPS
            struct PackedVaryingsMeshToPS
            {
                float4 positionCS : SV_Position; // unpacked
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
                float4 interp02 : TEXCOORD2; // auto-packed
                float4 interp03 : TEXCOORD3; // auto-packed
                float4 interp04 : TEXCOORD4; // auto-packed
                float4 interp05 : TEXCOORD5; // auto-packed
                float4 interp06 : TEXCOORD6; // auto-packed
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC; // unpacked
                #endif // conditional
            };
            
            // Packed Type: VaryingsMeshToPS
            PackedVaryingsMeshToPS PackVaryingsMeshToPS(VaryingsMeshToPS input)
            {
                PackedVaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                output.interp02.xyzw = input.tangentWS;
                output.interp03.xyzw = input.texCoord0;
                output.interp04.xyzw = input.texCoord1;
                output.interp05.xyzw = input.texCoord2;
                output.interp06.xyzw = input.color;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToPS
            VaryingsMeshToPS UnpackVaryingsMeshToPS(PackedVaryingsMeshToPS input)
            {
                VaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                output.tangentWS = input.interp02.xyzw;
                output.texCoord0 = input.interp03.xyzw;
                output.texCoord1 = input.interp04.xyzw;
                output.texCoord2 = input.interp05.xyzw;
                output.color = input.interp06.xyzw;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            // Generated Type: VaryingsMeshToDS
            struct VaryingsMeshToDS
            {
                float3 positionRWS;
                float3 normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            
            // Generated Type: PackedVaryingsMeshToDS
            struct PackedVaryingsMeshToDS
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
            };
            
            // Packed Type: VaryingsMeshToDS
            PackedVaryingsMeshToDS PackVaryingsMeshToDS(VaryingsMeshToDS input)
            {
                PackedVaryingsMeshToDS output;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToDS
            VaryingsMeshToDS UnpackVaryingsMeshToDS(PackedVaryingsMeshToDS input)
            {
                VaryingsMeshToDS output;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            //-------------------------------------------------------------------------------------
            // End Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
        
            //-------------------------------------------------------------------------------------
            // Graph generated code
            //-------------------------------------------------------------------------------------
                    // Shared Graph Properties (uniform inputs)
                    CBUFFER_START(UnityPerMaterial)
                    float _NormalStrength; float _Smoothness;
                    float3 _WindMultipliers;
                    float4 _EmissionColor;
                    float _RenderQueueType;
                    float _StencilRef;
                    float _StencilWriteMask;
                    float _StencilRefDepth;
                    float _StencilWriteMaskDepth;
                    float _StencilRefMV;
                    float _StencilWriteMaskMV;
                    float _StencilRefDistortionVec;
                    float _StencilWriteMaskDistortionVec;
                    float _StencilWriteMaskGBuffer;
                    float _StencilRefGBuffer;
                    float _ZTestGBuffer;
                    float _RequireSplitLighting;
                    float _ReceivesSSR;
                    float _SurfaceType;
                    float _BlendMode;
                    float _SrcBlend;
                    float _DstBlend;
                    float _AlphaSrcBlend;
                    float _AlphaDstBlend;
                    float _ZWrite;
                    float _CullMode;
                    float _TransparentSortPriority;
                    float _CullModeForward;
                    float _TransparentCullMode;
                    float _ZTestDepthEqualForOpaque;
                    float _ZTestTransparent;
                    float _TransparentBackfaceEnable;
                    float _AlphaCutoffEnable;
                    float _UseShadowThreshold;
                    float _DoubleSidedEnable;
                    float _DoubleSidedNormalMode;
                    float4 _DoubleSidedConstants;
                    CBUFFER_END
                    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;
                    TEXTURE2D(_BumpSpecAOMap); SAMPLER(sampler_BumpSpecAOMap); float4 _BumpSpecAOMap_TexelSize;
                    SAMPLER(_SampleTexture2D_1060DFD5_Sampler_3_Linear_Repeat);
                    SAMPLER(_SampleTexture2D_EC10A3ED_Sampler_3_Linear_Repeat);
                
                // Vertex Graph Inputs
                    struct VertexDescriptionInputs
                    {
                        float3 ObjectSpaceNormal; // optional
                        float3 ObjectSpaceTangent; // optional
                        float3 ObjectSpacePosition; // optional
                        float4 uv1; // optional
                        float4 uv2; // optional
                        float4 VertexColor; // optional
                    };
                // Vertex Graph Outputs
                    struct VertexDescription
                    {
                        float3 VertexPosition;
                        float3 VertexNormal;
                        float3 VertexTangent;
                    };
                    
                // Pixel Graph Inputs
                    struct SurfaceDescriptionInputs
                    {
                        float3 TangentSpaceNormal; // optional
                        float4 uv0; // optional
                        float4 VertexColor; // optional
                    };
                // Pixel Graph Outputs
                    struct SurfaceDescription
                    {
                        float3 Albedo;
                        float3 Normal;
                        float3 BentNormal;
                        float CoatMask;
                        float Metallic;
                        float3 Emission;
                        float Smoothness;
                        float Occlusion;
                        float Alpha;
                    };
                    
                // Shared Graph Node Functions
                
                    void UnpackCustomNormal_float(float4 normalSample, out float3 normalOut)
                    {
                        normalOut.xy = normalSample.ag;
                        normalOut.xy = normalOut.xy * 2 - 1;
                        normalOut.z = sqrt( 1 - dot(normalOut.xy , normalOut.xy ));
                    }
                
                    void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
                    {
                        Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
                    }
                
                    void Unity_Multiply_float (float A, float B, out float Out)
                    {
                        Out = A * B;
                    }
                
                    // dcd3c055367822a77956a73ac0a83c36
                    #include "/Includes/CTI_HDRP_Wind.hlsl"
                
                    struct Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8
                    {
                        float3 ObjectSpaceNormal;
                        float3 ObjectSpacePosition;
                        float4 VertexColor;
                        half4 uv1;
                        half4 uv2;
                    };
                
                    void SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(float Vector1_5B3F28E6, float Vector1_39544515, float Vector1_E70341A3, float Vector1_D355D6, float3 Vector3_D146D8D7, float Boolean_BA69BFA3, Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 IN, out float3 Position_1, out float3 Normal_2, out float ColorVariation_3)
                    {
                        float4 _UV_681BEC06_Out_0 = IN.uv1;
                        float4 _UV_5EAEC7D4_Out_0 = IN.uv2;
                        float _Property_66DDE654_Out_0 = Vector1_5B3F28E6;
                        float _Property_F63DDA84_Out_0 = Vector1_39544515;
                        float _Property_32CC05D1_Out_0 = Vector1_E70341A3;
                        float _Property_550822E2_Out_0 = Vector1_D355D6;
                        float3 _Property_9A8CF22B_Out_0 = Vector3_D146D8D7;
                        float _Property_7647AB6A_Out_0 = Boolean_BA69BFA3;
                        float3 _CustomFunction_4DA71B86_position1_10;
                        float3 _CustomFunction_4DA71B86_normal1_11;
                        float _CustomFunction_4DA71B86_color_12;
                        ApplyCTIWind_float(IN.ObjectSpacePosition, IN.VertexColor, (_UV_681BEC06_Out_0.xy), (_UV_5EAEC7D4_Out_0.xy), IN.ObjectSpaceNormal, _Property_66DDE654_Out_0, _Property_F63DDA84_Out_0, _Property_32CC05D1_Out_0, _Property_550822E2_Out_0, _Property_9A8CF22B_Out_0, _Property_7647AB6A_Out_0, _CustomFunction_4DA71B86_position1_10, _CustomFunction_4DA71B86_normal1_11, _CustomFunction_4DA71B86_color_12);
                        Position_1 = _CustomFunction_4DA71B86_position1_10;
                        Normal_2 = _CustomFunction_4DA71B86_normal1_11;
                        ColorVariation_3 = _CustomFunction_4DA71B86_color_12;
                    }
                
                // Vertex Graph Evaluation
                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        float3 _Property_EC5ABF14_Out_0 = _WindMultipliers;
                        Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 _CTIWind_89A09B02;
                        _CTIWind_89A09B02.ObjectSpaceNormal = IN.ObjectSpaceNormal;
                        _CTIWind_89A09B02.ObjectSpacePosition = IN.ObjectSpacePosition;
                        _CTIWind_89A09B02.VertexColor = IN.VertexColor;
                        _CTIWind_89A09B02.uv1 = IN.uv1;
                        _CTIWind_89A09B02.uv2 = IN.uv2;
                        float3 _CTIWind_89A09B02_Position_1;
                        float3 _CTIWind_89A09B02_Normal_2;
                        float _CTIWind_89A09B02_ColorVariation_3;
                        SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(0, 0, 0, 0, _Property_EC5ABF14_Out_0, 1, _CTIWind_89A09B02, _CTIWind_89A09B02_Position_1, _CTIWind_89A09B02_Normal_2, _CTIWind_89A09B02_ColorVariation_3);
                        description.VertexPosition = _CTIWind_89A09B02_Position_1;
                        description.VertexNormal = IN.ObjectSpaceNormal;
                        description.VertexTangent = IN.ObjectSpaceTangent;
                        return description;
                    }
                    
                // Pixel Graph Evaluation
                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        float4 _SampleTexture2D_1060DFD5_RGBA_0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0.xy);
                        float _SampleTexture2D_1060DFD5_R_4 = _SampleTexture2D_1060DFD5_RGBA_0.r;
                        float _SampleTexture2D_1060DFD5_G_5 = _SampleTexture2D_1060DFD5_RGBA_0.g;
                        float _SampleTexture2D_1060DFD5_B_6 = _SampleTexture2D_1060DFD5_RGBA_0.b;
                        float _SampleTexture2D_1060DFD5_A_7 = _SampleTexture2D_1060DFD5_RGBA_0.a;
                        float4 _SampleTexture2D_EC10A3ED_RGBA_0 = SAMPLE_TEXTURE2D(_BumpSpecAOMap, sampler_BumpSpecAOMap, IN.uv0.xy);
                        float _SampleTexture2D_EC10A3ED_R_4 = _SampleTexture2D_EC10A3ED_RGBA_0.r;
                        float _SampleTexture2D_EC10A3ED_G_5 = _SampleTexture2D_EC10A3ED_RGBA_0.g;
                        float _SampleTexture2D_EC10A3ED_B_6 = _SampleTexture2D_EC10A3ED_RGBA_0.b;
                        float _SampleTexture2D_EC10A3ED_A_7 = _SampleTexture2D_EC10A3ED_RGBA_0.a;
                        float3 _CustomFunction_CF03AB98_normalOut_1;
                        UnpackCustomNormal_float(_SampleTexture2D_EC10A3ED_RGBA_0, _CustomFunction_CF03AB98_normalOut_1);
                        float _Property_C6B71BE6_Out_0 = _NormalStrength;
                        float3 _NormalStrength_AA429D2D_Out_2;
                        Unity_NormalStrength_float(_CustomFunction_CF03AB98_normalOut_1, _Property_C6B71BE6_Out_0, _NormalStrength_AA429D2D_Out_2);
                        float _Split_DDDB7F0B_R_1 = IN.VertexColor[0];
                        float _Split_DDDB7F0B_G_2 = IN.VertexColor[1];
                        float _Split_DDDB7F0B_B_3 = IN.VertexColor[2];
                        float _Split_DDDB7F0B_A_4 = IN.VertexColor[3];
                        float _Multiply_1C76B952_Out_2;
                        Unity_Multiply_float(_Split_DDDB7F0B_A_4, _SampleTexture2D_EC10A3ED_B_6, _Multiply_1C76B952_Out_2);
                        surface.Albedo = (_SampleTexture2D_1060DFD5_RGBA_0.xyz);
                        surface.Normal = _NormalStrength_AA429D2D_Out_2;
                        surface.BentNormal = IN.TangentSpaceNormal;
                        surface.CoatMask = 0;
                        surface.Metallic = 0;
                        surface.Emission = float3(0, 0, 0);
                        surface.Smoothness = _SampleTexture2D_1060DFD5_A_7 * _Smoothness;
                        surface.Occlusion = _Multiply_1C76B952_Out_2;
                        surface.Alpha = 1;
                        return surface;
                    }
                    
            //-------------------------------------------------------------------------------------
            // End graph generated code
            //-------------------------------------------------------------------------------------
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
            
            VertexDescriptionInputs AttributesMeshToVertexDescriptionInputs(AttributesMesh input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                // output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                // output.ViewSpaceNormal =             TransformWorldToViewDir(output.WorldSpaceNormal);
                // output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                output.ObjectSpaceTangent =          input.tangentOS;
                // output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
                // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                // output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
                // output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                output.ObjectSpacePosition =         input.positionOS;
                // output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                // output.ViewSpacePosition =           TransformWorldToView(output.WorldSpacePosition);
                // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(TransformObjectToWorld(input.positionOS));
                // output.WorldSpaceViewDirection =     GetWorldSpaceNormalizeViewDir(output.WorldSpacePosition);
                // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(output.WorldSpacePosition), _ProjectionParams.x);
                // output.uv0 =                         input.uv0;
                output.uv1 =                         input.uv1;
                output.uv2 =                         input.uv2;
                // output.uv3 =                         input.uv3;
                output.VertexColor =                 input.color;
            
                return output;
            }
            
            AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            {
                // build graph inputs
                VertexDescriptionInputs vertexDescriptionInputs = AttributesMeshToVertexDescriptionInputs(input);
                // Override time paramters with used one (This is required to correctly handle motion vector for vertex animation based on time)
                // vertexDescriptionInputs.TimeParameters = timeParameters;
            
                // evaluate vertex graph
                VertexDescription vertexDescription = VertexDescriptionFunction(vertexDescriptionInputs);
            
                // copy graph output to the results
                input.positionOS = vertexDescription.VertexPosition;
                input.normalOS = vertexDescription.VertexNormal;
                input.tangentOS.xyz = vertexDescription.VertexTangent;
            
                return input;
            }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
                FragInputs BuildFragInputs(VaryingsMeshToPS input)
                {
                    FragInputs output;
                    ZERO_INITIALIZE(FragInputs, output);
            
                    // Init to some default value to make the computer quiet (else it output 'divide by zero' warning even if value is not used).
                    // TODO: this is a really poor workaround, but the variable is used in a bunch of places
                    // to compute normals which are then passed on elsewhere to compute other values...
                    output.tangentToWorld = k_identity3x3;
                    output.positionSS = input.positionCS;       // input.positionCS is SV_Position
            
                    output.positionRWS = input.positionRWS;
                    output.tangentToWorld = BuildTangentToWorld(input.tangentWS, input.normalWS);
                    output.texCoord0 = input.texCoord0;
                    output.texCoord1 = input.texCoord1;
                    output.texCoord2 = input.texCoord2;
                    // output.texCoord3 = input.texCoord3;
                    output.color = input.color;
                    #if _DOUBLESIDED_ON && SHADER_STAGE_FRAGMENT
                    output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #elif SHADER_STAGE_FRAGMENT
                    // output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #endif // SHADER_STAGE_FRAGMENT
            
                    return output;
                }
            
                SurfaceDescriptionInputs FragInputsToSurfaceDescriptionInputs(FragInputs input, float3 viewWS)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                    // output.WorldSpaceNormal =            normalize(input.tangentToWorld[2].xyz);
                    // output.ObjectSpaceNormal =           mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M);           // transposed multiplication by inverse matrix to handle normal scale
                    // output.ViewSpaceNormal =             mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_I_V);         // transposed multiplication by inverse matrix to handle normal scale
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                    // output.WorldSpaceTangent =           input.tangentToWorld[0].xyz;
                    // output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
                    // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                    // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                    // output.WorldSpaceBiTangent =         input.tangentToWorld[1].xyz;
                    // output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
                    // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                    // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                    // output.WorldSpaceViewDirection =     normalize(viewWS);
                    // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                    // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                    // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                    // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    // output.WorldSpacePosition =          input.positionRWS;
                    // output.ObjectSpacePosition =         TransformWorldToObject(input.positionRWS);
                    // output.ViewSpacePosition =           TransformWorldToView(input.positionRWS);
                    // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                    // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionRWS);
                    // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionRWS), _ProjectionParams.x);
                    output.uv0 =                         input.texCoord0;
                    // output.uv1 =                         input.texCoord1;
                    // output.uv2 =                         input.texCoord2;
                    // output.uv3 =                         input.texCoord3;
                    output.VertexColor =                 input.color;
                    // output.FaceSign =                    input.isFrontFace;
                    // output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            
                    return output;
                }
            
                // existing HDRP code uses the combined function to go directly from packed to frag inputs
                FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    VaryingsMeshToPS unpacked= UnpackVaryingsMeshToPS(input);
                    return BuildFragInputs(unpacked);
                }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
            void BuildSurfaceData(FragInputs fragInputs, inout SurfaceDescription surfaceDescription, float3 V, PositionInputs posInput, out SurfaceData surfaceData, out float3 bentNormalWS)
            {
                // setup defaults -- these are used if the graph doesn't output a value
                ZERO_INITIALIZE(SurfaceData, surfaceData);
        
                // copy across graph values, if defined
                surfaceData.baseColor =                 surfaceDescription.Albedo;
                surfaceData.perceptualSmoothness =      surfaceDescription.Smoothness;
                surfaceData.ambientOcclusion =          surfaceDescription.Occlusion;
                // surfaceData.specularOcclusion =         surfaceDescription.SpecularOcclusion;
                surfaceData.metallic =                  surfaceDescription.Metallic;
                // surfaceData.subsurfaceMask =            surfaceDescription.SubsurfaceMask;
                // surfaceData.thickness =                 surfaceDescription.Thickness;
                // surfaceData.diffusionProfileHash =      asuint(surfaceDescription.DiffusionProfileHash);
                // surfaceData.specularColor =             surfaceDescription.Specular;
                surfaceData.coatMask =                  surfaceDescription.CoatMask;
                // surfaceData.anisotropy =                surfaceDescription.Anisotropy;
                // surfaceData.iridescenceMask =           surfaceDescription.IridescenceMask;
                // surfaceData.iridescenceThickness =      surfaceDescription.IridescenceThickness;
        
        #ifdef _HAS_REFRACTION
                if (_EnableSSRefraction)
                {
                    // surfaceData.ior =                       surfaceDescription.RefractionIndex;
                    // surfaceData.transmittanceColor =        surfaceDescription.RefractionColor;
                    // surfaceData.atDistance =                surfaceDescription.RefractionDistance;
        
                    surfaceData.transmittanceMask = (1.0 - surfaceDescription.Alpha);
                    surfaceDescription.Alpha = 1.0;
                }
                else
                {
                    surfaceData.ior = 1.0;
                    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                    surfaceData.atDistance = 1.0;
                    surfaceData.transmittanceMask = 0.0;
                    surfaceDescription.Alpha = 1.0;
                }
        #else
                surfaceData.ior = 1.0;
                surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                surfaceData.atDistance = 1.0;
                surfaceData.transmittanceMask = 0.0;
        #endif
                
                // These static material feature allow compile time optimization
                surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
        #ifdef _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SUBSURFACE_SCATTERING;
        #endif
        #ifdef _MATERIAL_FEATURE_TRANSMISSION
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_TRANSMISSION;
        #endif
        #ifdef _MATERIAL_FEATURE_ANISOTROPY
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_ANISOTROPY;
        #endif
                // surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_CLEAR_COAT;
        
        #ifdef _MATERIAL_FEATURE_IRIDESCENCE
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_IRIDESCENCE;
        #endif
        #ifdef _MATERIAL_FEATURE_SPECULAR_COLOR
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SPECULAR_COLOR;
        #endif
        
        #if defined (_MATERIAL_FEATURE_SPECULAR_COLOR) && defined (_ENERGY_CONSERVING_SPECULAR)
                // Require to have setup baseColor
                // Reproduce the energy conservation done in legacy Unity. Not ideal but better for compatibility and users can unchek it
                surfaceData.baseColor *= (1.0 - Max3(surfaceData.specularColor.r, surfaceData.specularColor.g, surfaceData.specularColor.b));
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                // tangent-space normal
                float3 normalTS = float3(0.0f, 0.0f, 1.0f);
                normalTS = surfaceDescription.Normal;
        
                // compute world space normal
                GetNormalWS(fragInputs, normalTS, surfaceData.normalWS, doubleSidedConstants);
        
                bentNormalWS = surfaceData.normalWS;
                // GetNormalWS(fragInputs, surfaceDescription.BentNormal, bentNormalWS, doubleSidedConstants);
        
                surfaceData.geomNormalWS = fragInputs.tangentToWorld[2];
        
                surfaceData.tangentWS = normalize(fragInputs.tangentToWorld[0].xyz);    // The tangent is not normalize in tangentToWorld for mikkt. TODO: Check if it expected that we normalize with Morten. Tag: SURFACE_GRADIENT
                // surfaceData.tangentWS = TransformTangentToWorld(surfaceDescription.Tangent, fragInputs.tangentToWorld);
                surfaceData.tangentWS = Orthonormalize(surfaceData.tangentWS, surfaceData.normalWS);
        
                // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
                // If user provide bent normal then we process a better term
        #if defined(_SPECULAR_OCCLUSION_CUSTOM)
                // Just use the value passed through via the slot (not active otherwise)
        #elif defined(_SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL)
                // If we have bent normal and ambient occlusion, process a specular occlusion
                surfaceData.specularOcclusion = GetSpecularOcclusionFromBentAO(V, bentNormalWS, surfaceData.normalWS, surfaceData.ambientOcclusion, PerceptualSmoothnessToPerceptualRoughness(surfaceData.perceptualSmoothness));
        #elif defined(_AMBIENT_OCCLUSION) && defined(_SPECULAR_OCCLUSION_FROM_AO)
                surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
        #else
                surfaceData.specularOcclusion = 1.0;
        #endif
        
        #if HAVE_DECALS
                if (_EnableDecals)
                {
                    DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, surfaceDescription.Alpha);
                    ApplyDecalToSurfaceData(decalSurfaceData, surfaceData);
                }
        #endif
        
        #ifdef _ENABLE_GEOMETRIC_SPECULAR_AA
                surfaceData.perceptualSmoothness = GeometricNormalFiltering(surfaceData.perceptualSmoothness, fragInputs.tangentToWorld[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif
        
        #ifdef DEBUG_DISPLAY
                if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
                {
                    // TODO: need to update mip info
                    surfaceData.metallic = 0;
                }
        
                // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
                // as it can modify attribute use for static lighting
                ApplyDebugToSurfaceData(fragInputs.tangentToWorld, surfaceData);
        #endif
            }
        
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
        #ifdef LOD_FADE_CROSSFADE // enable dithering LOD transition if user select CrossFade transition in LOD group
                uint3 fadeMaskSeed = asuint((int3)(V * _ScreenSize.xyx)); // Quantize V to _ScreenSize values
                LODDitheringTransition(fadeMaskSeed, unity_LODFade.x);
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                ApplyDoubleSidedFlipOrMirror(fragInputs, doubleSidedConstants);
        
                SurfaceDescriptionInputs surfaceDescriptionInputs = FragInputsToSurfaceDescriptionInputs(fragInputs, V);
                SurfaceDescription surfaceDescription = SurfaceDescriptionFunction(surfaceDescriptionInputs);
        
                // Perform alpha test very early to save performance (a killed pixel will not sample textures)
                // TODO: split graph evaluation to grab just alpha dependencies first? tricky..
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPrepass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPostpass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow);
                
                // ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
        
                float3 bentNormalWS;
                BuildSurfaceData(fragInputs, surfaceDescription, V, posInput, surfaceData, bentNormalWS);
        
                // Builtin Data
                // For back lighting we use the oposite vertex normal 
                InitBuiltinData(posInput, surfaceDescription.Alpha, bentNormalWS, -fragInputs.tangentToWorld[2], fragInputs.texCoord1, fragInputs.texCoord2, builtinData);
        
                // override sampleBakedGI:
                // builtinData.bakeDiffuseLighting = surfaceDescription.BakedGI;
                // builtinData.backBakeDiffuseLighting = surfaceDescription.BakedBackGI;
        
                builtinData.emissiveColor = surfaceDescription.Emission;
        
                // builtinData.depthOffset = surfaceDescription.DepthOffset;
        
        #if (SHADERPASS == SHADERPASS_DISTORTION)
                builtinData.distortion = surfaceDescription.Distortion;
                builtinData.distortionBlur = surfaceDescription.DistortionBlur;
        #else
                builtinData.distortion = float2(0.0, 0.0);
                builtinData.distortionBlur = 0.0;
        #endif
        
                PostInitBuiltinData(V, posInput, surfaceData, builtinData);
            }
        
            //-------------------------------------------------------------------------------------
            // Pass Includes
            //-------------------------------------------------------------------------------------
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassGBuffer.hlsl"
            //-------------------------------------------------------------------------------------
            // End Pass Includes
            //-------------------------------------------------------------------------------------
        
            ENDHLSL
        }
        
        Pass
        {
            // based on HDLitPass.template
            Name "MotionVectors"
            Tags { "LightMode" = "MotionVectors" }
        
            //-------------------------------------------------------------------------------------
            // Render Modes (Blend, Cull, ZTest, Stencil, etc)
            //-------------------------------------------------------------------------------------
            
            Cull [_CullMode]
        
            
            ZWrite On
        
            
            // Stencil setup
        Stencil
        {
           WriteMask [_StencilWriteMaskMV]
           Ref [_StencilRefMV]
           Comp Always
           Pass Replace
        }
        
            
            //-------------------------------------------------------------------------------------
            // End Render Modes
            //-------------------------------------------------------------------------------------
        
            HLSLPROGRAM
        
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //#pragma enable_d3d11_debug_symbols
        
            #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        
            #pragma multi_compile _ LOD_FADE_CROSSFADE
        
            // #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _DOUBLESIDED_ON
            // #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
        
            //-------------------------------------------------------------------------------------
            // Variant Definitions (active field translations to HDRP defines)
            //-------------------------------------------------------------------------------------
            // #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING 1
            // #define _MATERIAL_FEATURE_TRANSMISSION 1
            // #define _MATERIAL_FEATURE_ANISOTROPY 1
            // #define _MATERIAL_FEATURE_IRIDESCENCE 1
            // #define _MATERIAL_FEATURE_SPECULAR_COLOR 1
            // #define _ENABLE_FOG_ON_TRANSPARENT 1
            #define _AMBIENT_OCCLUSION 1
            #define _SPECULAR_OCCLUSION_FROM_AO 1
            // #define _SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL 1
            // #define _SPECULAR_OCCLUSION_CUSTOM 1
            #define _ENERGY_CONSERVING_SPECULAR 1
            // #define _ENABLE_GEOMETRIC_SPECULAR_AA 1
            // #define _HAS_REFRACTION 1
            // #define _REFRACTION_PLANE 1
            // #define _REFRACTION_SPHERE 1
            // #define _DISABLE_DECALS 1
            #define _DISABLE_SSR 1
            // #define _ADD_PRECOMPUTED_VELOCITY
            // #define _WRITE_TRANSPARENT_MOTION_VECTOR 1
            // #define _DEPTHOFFSET_ON 1
            // #define _BLENDMODE_PRESERVE_SPECULAR_LIGHTING 1
        
            //-------------------------------------------------------------------------------------
            // End Variant Definitions
            //-------------------------------------------------------------------------------------
        
            #pragma vertex Vert
            #pragma fragment Frag
        
            // If we use subsurface scattering, enable output split lighting (for forward pass)
            #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
            #define OUTPUT_SPLIT_LIGHTING
            #endif
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
        
            // define FragInputs structure
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
        
            //-------------------------------------------------------------------------------------
            // Defines
            //-------------------------------------------------------------------------------------
                    #define SHADERPASS SHADERPASS_MOTION_VECTORS
                #pragma multi_compile _ WRITE_NORMAL_BUFFER
                #pragma multi_compile _ WRITE_MSAA_DEPTH
                #define RAYTRACING_SHADER_GRAPH_HIGH
                // ACTIVE FIELDS:
                //   Material.Standard
                //   DisableSSR
                //   Specular.EnergyConserving
                //   SurfaceDescriptionInputs.TangentSpaceNormal
                //   SurfaceDescriptionInputs.uv0
                //   VertexDescriptionInputs.VertexColor
                //   VertexDescriptionInputs.ObjectSpaceNormal
                //   VertexDescriptionInputs.ObjectSpaceTangent
                //   VertexDescriptionInputs.ObjectSpacePosition
                //   VertexDescriptionInputs.uv1
                //   VertexDescriptionInputs.uv2
                //   SurfaceDescription.Normal
                //   SurfaceDescription.Smoothness
                //   SurfaceDescription.Alpha
                //   features.modifyMesh
                //   VertexDescription.VertexPosition
                //   VertexDescription.VertexNormal
                //   VertexDescription.VertexTangent
                //   AttributesMesh.normalOS
                //   AttributesMesh.tangentOS
                //   AttributesMesh.uv0
                //   AttributesMesh.uv1
                //   AttributesMesh.color
                //   AttributesMesh.uv2
                //   AttributesMesh.uv3
                //   FragInputs.tangentToWorld
                //   FragInputs.positionRWS
                //   FragInputs.texCoord0
                //   FragInputs.texCoord1
                //   FragInputs.texCoord2
                //   FragInputs.texCoord3
                //   FragInputs.color
                //   AttributesMesh.positionOS
                //   VaryingsMeshToPS.tangentWS
                //   VaryingsMeshToPS.normalWS
                //   VaryingsMeshToPS.positionRWS
                //   VaryingsMeshToPS.texCoord0
                //   VaryingsMeshToPS.texCoord1
                //   VaryingsMeshToPS.texCoord2
                //   VaryingsMeshToPS.texCoord3
                //   VaryingsMeshToPS.color
                // Shared Graph Keywords
        
            // this translates the new dependency tracker into the old preprocessor definitions for the existing HDRP shader code
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define ATTRIBUTES_NEED_TEXCOORD3
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TANGENT_TO_WORLD
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_TEXCOORD1
            #define VARYINGS_NEED_TEXCOORD2
            #define VARYINGS_NEED_TEXCOORD3
            #define VARYINGS_NEED_COLOR
            // #define VARYINGS_NEED_CULLFACE
            #define HAVE_MESH_MODIFICATION
        
        // We need isFontFace when using double sided
        #if defined(_DOUBLESIDED_ON) && !defined(VARYINGS_NEED_CULLFACE)
            #define VARYINGS_NEED_CULLFACE
        #endif
        
            //-------------------------------------------------------------------------------------
            // End Defines
            //-------------------------------------------------------------------------------------
            
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
        
        #if (SHADERPASS == SHADERPASS_FORWARD)
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        
            #define HAS_LIGHTLOOP
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"
        #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDecalData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"
        
            // Used by SceneSelectionPass
            int _ObjectId;
            int _PassValue;
        
            //-------------------------------------------------------------------------------------
            // Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
            // Generated Type: AttributesMesh
            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL; // optional
                float4 tangentOS : TANGENT; // optional
                float4 uv0 : TEXCOORD0; // optional
                float4 uv1 : TEXCOORD1; // optional
                float4 uv2 : TEXCOORD2; // optional
                float4 uv3 : TEXCOORD3; // optional
                float4 color : COLOR; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            // Generated Type: VaryingsMeshToPS
            struct VaryingsMeshToPS
            {
                float4 positionCS : SV_Position;
                float3 positionRWS; // optional
                float3 normalWS; // optional
                float4 tangentWS; // optional
                float4 texCoord0; // optional
                float4 texCoord1; // optional
                float4 texCoord2; // optional
                float4 texCoord3; // optional
                float4 color; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif // defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            };
            
            // Generated Type: PackedVaryingsMeshToPS
            struct PackedVaryingsMeshToPS
            {
                float4 positionCS : SV_Position; // unpacked
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
                float4 interp02 : TEXCOORD2; // auto-packed
                float4 interp03 : TEXCOORD3; // auto-packed
                float4 interp04 : TEXCOORD4; // auto-packed
                float4 interp05 : TEXCOORD5; // auto-packed
                float4 interp06 : TEXCOORD6; // auto-packed
                float4 interp07 : TEXCOORD7; // auto-packed
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC; // unpacked
                #endif // conditional
            };
            
            // Packed Type: VaryingsMeshToPS
            PackedVaryingsMeshToPS PackVaryingsMeshToPS(VaryingsMeshToPS input)
            {
                PackedVaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                output.interp02.xyzw = input.tangentWS;
                output.interp03.xyzw = input.texCoord0;
                output.interp04.xyzw = input.texCoord1;
                output.interp05.xyzw = input.texCoord2;
                output.interp06.xyzw = input.texCoord3;
                output.interp07.xyzw = input.color;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToPS
            VaryingsMeshToPS UnpackVaryingsMeshToPS(PackedVaryingsMeshToPS input)
            {
                VaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                output.tangentWS = input.interp02.xyzw;
                output.texCoord0 = input.interp03.xyzw;
                output.texCoord1 = input.interp04.xyzw;
                output.texCoord2 = input.interp05.xyzw;
                output.texCoord3 = input.interp06.xyzw;
                output.color = input.interp07.xyzw;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            // Generated Type: VaryingsMeshToDS
            struct VaryingsMeshToDS
            {
                float3 positionRWS;
                float3 normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            
            // Generated Type: PackedVaryingsMeshToDS
            struct PackedVaryingsMeshToDS
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
            };
            
            // Packed Type: VaryingsMeshToDS
            PackedVaryingsMeshToDS PackVaryingsMeshToDS(VaryingsMeshToDS input)
            {
                PackedVaryingsMeshToDS output;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToDS
            VaryingsMeshToDS UnpackVaryingsMeshToDS(PackedVaryingsMeshToDS input)
            {
                VaryingsMeshToDS output;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            //-------------------------------------------------------------------------------------
            // End Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
        
            //-------------------------------------------------------------------------------------
            // Graph generated code
            //-------------------------------------------------------------------------------------
                    // Shared Graph Properties (uniform inputs)
                    CBUFFER_START(UnityPerMaterial)
                    float _NormalStrength; float _Smoothness;
                    float3 _WindMultipliers;
                    float4 _EmissionColor;
                    float _RenderQueueType;
                    float _StencilRef;
                    float _StencilWriteMask;
                    float _StencilRefDepth;
                    float _StencilWriteMaskDepth;
                    float _StencilRefMV;
                    float _StencilWriteMaskMV;
                    float _StencilRefDistortionVec;
                    float _StencilWriteMaskDistortionVec;
                    float _StencilWriteMaskGBuffer;
                    float _StencilRefGBuffer;
                    float _ZTestGBuffer;
                    float _RequireSplitLighting;
                    float _ReceivesSSR;
                    float _SurfaceType;
                    float _BlendMode;
                    float _SrcBlend;
                    float _DstBlend;
                    float _AlphaSrcBlend;
                    float _AlphaDstBlend;
                    float _ZWrite;
                    float _CullMode;
                    float _TransparentSortPriority;
                    float _CullModeForward;
                    float _TransparentCullMode;
                    float _ZTestDepthEqualForOpaque;
                    float _ZTestTransparent;
                    float _TransparentBackfaceEnable;
                    float _AlphaCutoffEnable;
                    float _UseShadowThreshold;
                    float _DoubleSidedEnable;
                    float _DoubleSidedNormalMode;
                    float4 _DoubleSidedConstants;
                    CBUFFER_END
                    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;
                    TEXTURE2D(_BumpSpecAOMap); SAMPLER(sampler_BumpSpecAOMap); float4 _BumpSpecAOMap_TexelSize;
                    SAMPLER(_SampleTexture2D_EC10A3ED_Sampler_3_Linear_Repeat);
                    SAMPLER(_SampleTexture2D_1060DFD5_Sampler_3_Linear_Repeat);
                
                // Vertex Graph Inputs
                    struct VertexDescriptionInputs
                    {
                        float3 ObjectSpaceNormal; // optional
                        float3 ObjectSpaceTangent; // optional
                        float3 ObjectSpacePosition; // optional
                        float4 uv1; // optional
                        float4 uv2; // optional
                        float4 VertexColor; // optional
                    };
                // Vertex Graph Outputs
                    struct VertexDescription
                    {
                        float3 VertexPosition;
                        float3 VertexNormal;
                        float3 VertexTangent;
                    };
                    
                // Pixel Graph Inputs
                    struct SurfaceDescriptionInputs
                    {
                        float3 TangentSpaceNormal; // optional
                        float4 uv0; // optional
                    };
                // Pixel Graph Outputs
                    struct SurfaceDescription
                    {
                        float3 Normal;
                        float Smoothness;
                        float Alpha;
                    };
                    
                // Shared Graph Node Functions
                
                    void UnpackCustomNormal_float(float4 normalSample, out float3 normalOut)
                    {
                        normalOut.xy = normalSample.ag;
                        normalOut.xy = normalOut.xy * 2 - 1;
                        normalOut.z = sqrt( 1 - dot(normalOut.xy , normalOut.xy ));
                    }
                
                    void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
                    {
                        Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
                    }
                
                    // dcd3c055367822a77956a73ac0a83c36
                    #include "/Includes/CTI_HDRP_Wind.hlsl"
                
                    struct Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8
                    {
                        float3 ObjectSpaceNormal;
                        float3 ObjectSpacePosition;
                        float4 VertexColor;
                        half4 uv1;
                        half4 uv2;
                    };
                
                    void SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(float Vector1_5B3F28E6, float Vector1_39544515, float Vector1_E70341A3, float Vector1_D355D6, float3 Vector3_D146D8D7, float Boolean_BA69BFA3, Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 IN, out float3 Position_1, out float3 Normal_2, out float ColorVariation_3)
                    {
                        float4 _UV_681BEC06_Out_0 = IN.uv1;
                        float4 _UV_5EAEC7D4_Out_0 = IN.uv2;
                        float _Property_66DDE654_Out_0 = Vector1_5B3F28E6;
                        float _Property_F63DDA84_Out_0 = Vector1_39544515;
                        float _Property_32CC05D1_Out_0 = Vector1_E70341A3;
                        float _Property_550822E2_Out_0 = Vector1_D355D6;
                        float3 _Property_9A8CF22B_Out_0 = Vector3_D146D8D7;
                        float _Property_7647AB6A_Out_0 = Boolean_BA69BFA3;
                        float3 _CustomFunction_4DA71B86_position1_10;
                        float3 _CustomFunction_4DA71B86_normal1_11;
                        float _CustomFunction_4DA71B86_color_12;
                        ApplyCTIWind_float(IN.ObjectSpacePosition, IN.VertexColor, (_UV_681BEC06_Out_0.xy), (_UV_5EAEC7D4_Out_0.xy), IN.ObjectSpaceNormal, _Property_66DDE654_Out_0, _Property_F63DDA84_Out_0, _Property_32CC05D1_Out_0, _Property_550822E2_Out_0, _Property_9A8CF22B_Out_0, _Property_7647AB6A_Out_0, _CustomFunction_4DA71B86_position1_10, _CustomFunction_4DA71B86_normal1_11, _CustomFunction_4DA71B86_color_12);
                        Position_1 = _CustomFunction_4DA71B86_position1_10;
                        Normal_2 = _CustomFunction_4DA71B86_normal1_11;
                        ColorVariation_3 = _CustomFunction_4DA71B86_color_12;
                    }
                
                // Vertex Graph Evaluation
                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        float3 _Property_EC5ABF14_Out_0 = _WindMultipliers;
                        Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 _CTIWind_89A09B02;
                        _CTIWind_89A09B02.ObjectSpaceNormal = IN.ObjectSpaceNormal;
                        _CTIWind_89A09B02.ObjectSpacePosition = IN.ObjectSpacePosition;
                        _CTIWind_89A09B02.VertexColor = IN.VertexColor;
                        _CTIWind_89A09B02.uv1 = IN.uv1;
                        _CTIWind_89A09B02.uv2 = IN.uv2;
                        float3 _CTIWind_89A09B02_Position_1;
                        float3 _CTIWind_89A09B02_Normal_2;
                        float _CTIWind_89A09B02_ColorVariation_3;
                        SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(0, 0, 0, 0, _Property_EC5ABF14_Out_0, 1, _CTIWind_89A09B02, _CTIWind_89A09B02_Position_1, _CTIWind_89A09B02_Normal_2, _CTIWind_89A09B02_ColorVariation_3);
                        description.VertexPosition = _CTIWind_89A09B02_Position_1;
                        description.VertexNormal = IN.ObjectSpaceNormal;
                        description.VertexTangent = IN.ObjectSpaceTangent;
                        return description;
                    }
                    
                // Pixel Graph Evaluation
                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        float4 _SampleTexture2D_EC10A3ED_RGBA_0 = SAMPLE_TEXTURE2D(_BumpSpecAOMap, sampler_BumpSpecAOMap, IN.uv0.xy);
                        float _SampleTexture2D_EC10A3ED_R_4 = _SampleTexture2D_EC10A3ED_RGBA_0.r;
                        float _SampleTexture2D_EC10A3ED_G_5 = _SampleTexture2D_EC10A3ED_RGBA_0.g;
                        float _SampleTexture2D_EC10A3ED_B_6 = _SampleTexture2D_EC10A3ED_RGBA_0.b;
                        float _SampleTexture2D_EC10A3ED_A_7 = _SampleTexture2D_EC10A3ED_RGBA_0.a;
                        float3 _CustomFunction_CF03AB98_normalOut_1;
                        UnpackCustomNormal_float(_SampleTexture2D_EC10A3ED_RGBA_0, _CustomFunction_CF03AB98_normalOut_1);
                        float _Property_C6B71BE6_Out_0 = _NormalStrength;
                        float3 _NormalStrength_AA429D2D_Out_2;
                        Unity_NormalStrength_float(_CustomFunction_CF03AB98_normalOut_1, _Property_C6B71BE6_Out_0, _NormalStrength_AA429D2D_Out_2);
                        float4 _SampleTexture2D_1060DFD5_RGBA_0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0.xy);
                        float _SampleTexture2D_1060DFD5_R_4 = _SampleTexture2D_1060DFD5_RGBA_0.r;
                        float _SampleTexture2D_1060DFD5_G_5 = _SampleTexture2D_1060DFD5_RGBA_0.g;
                        float _SampleTexture2D_1060DFD5_B_6 = _SampleTexture2D_1060DFD5_RGBA_0.b;
                        float _SampleTexture2D_1060DFD5_A_7 = _SampleTexture2D_1060DFD5_RGBA_0.a;
                        surface.Normal = _NormalStrength_AA429D2D_Out_2;
                        surface.Smoothness = _SampleTexture2D_1060DFD5_A_7 * _Smoothness;
                        surface.Alpha = 1;
                        return surface;
                    }
                    
            //-------------------------------------------------------------------------------------
            // End graph generated code
            //-------------------------------------------------------------------------------------
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
            
            VertexDescriptionInputs AttributesMeshToVertexDescriptionInputs(AttributesMesh input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                // output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                // output.ViewSpaceNormal =             TransformWorldToViewDir(output.WorldSpaceNormal);
                // output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                output.ObjectSpaceTangent =          input.tangentOS;
                // output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
                // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                // output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
                // output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                output.ObjectSpacePosition =         input.positionOS;
                // output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                // output.ViewSpacePosition =           TransformWorldToView(output.WorldSpacePosition);
                // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(TransformObjectToWorld(input.positionOS));
                // output.WorldSpaceViewDirection =     GetWorldSpaceNormalizeViewDir(output.WorldSpacePosition);
                // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(output.WorldSpacePosition), _ProjectionParams.x);
                // output.uv0 =                         input.uv0;
                output.uv1 =                         input.uv1;
                output.uv2 =                         input.uv2;
                // output.uv3 =                         input.uv3;
                output.VertexColor =                 input.color;
            
                return output;
            }
            
            AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            {
                // build graph inputs
                VertexDescriptionInputs vertexDescriptionInputs = AttributesMeshToVertexDescriptionInputs(input);
                // Override time paramters with used one (This is required to correctly handle motion vector for vertex animation based on time)
                // vertexDescriptionInputs.TimeParameters = timeParameters;
            
                // evaluate vertex graph
                VertexDescription vertexDescription = VertexDescriptionFunction(vertexDescriptionInputs);
            
                // copy graph output to the results
                input.positionOS = vertexDescription.VertexPosition;
                input.normalOS = vertexDescription.VertexNormal;
                input.tangentOS.xyz = vertexDescription.VertexTangent;
            
                return input;
            }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
                FragInputs BuildFragInputs(VaryingsMeshToPS input)
                {
                    FragInputs output;
                    ZERO_INITIALIZE(FragInputs, output);
            
                    // Init to some default value to make the computer quiet (else it output 'divide by zero' warning even if value is not used).
                    // TODO: this is a really poor workaround, but the variable is used in a bunch of places
                    // to compute normals which are then passed on elsewhere to compute other values...
                    output.tangentToWorld = k_identity3x3;
                    output.positionSS = input.positionCS;       // input.positionCS is SV_Position
            
                    output.positionRWS = input.positionRWS;
                    output.tangentToWorld = BuildTangentToWorld(input.tangentWS, input.normalWS);
                    output.texCoord0 = input.texCoord0;
                    output.texCoord1 = input.texCoord1;
                    output.texCoord2 = input.texCoord2;
                    output.texCoord3 = input.texCoord3;
                    output.color = input.color;
                    #if _DOUBLESIDED_ON && SHADER_STAGE_FRAGMENT
                    output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #elif SHADER_STAGE_FRAGMENT
                    // output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #endif // SHADER_STAGE_FRAGMENT
            
                    return output;
                }
            
                SurfaceDescriptionInputs FragInputsToSurfaceDescriptionInputs(FragInputs input, float3 viewWS)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                    // output.WorldSpaceNormal =            normalize(input.tangentToWorld[2].xyz);
                    // output.ObjectSpaceNormal =           mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M);           // transposed multiplication by inverse matrix to handle normal scale
                    // output.ViewSpaceNormal =             mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_I_V);         // transposed multiplication by inverse matrix to handle normal scale
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                    // output.WorldSpaceTangent =           input.tangentToWorld[0].xyz;
                    // output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
                    // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                    // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                    // output.WorldSpaceBiTangent =         input.tangentToWorld[1].xyz;
                    // output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
                    // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                    // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                    // output.WorldSpaceViewDirection =     normalize(viewWS);
                    // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                    // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                    // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                    // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    // output.WorldSpacePosition =          input.positionRWS;
                    // output.ObjectSpacePosition =         TransformWorldToObject(input.positionRWS);
                    // output.ViewSpacePosition =           TransformWorldToView(input.positionRWS);
                    // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                    // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionRWS);
                    // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionRWS), _ProjectionParams.x);
                    output.uv0 =                         input.texCoord0;
                    // output.uv1 =                         input.texCoord1;
                    // output.uv2 =                         input.texCoord2;
                    // output.uv3 =                         input.texCoord3;
                    // output.VertexColor =                 input.color;
                    // output.FaceSign =                    input.isFrontFace;
                    // output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            
                    return output;
                }
            
                // existing HDRP code uses the combined function to go directly from packed to frag inputs
                FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    VaryingsMeshToPS unpacked= UnpackVaryingsMeshToPS(input);
                    return BuildFragInputs(unpacked);
                }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
            void BuildSurfaceData(FragInputs fragInputs, inout SurfaceDescription surfaceDescription, float3 V, PositionInputs posInput, out SurfaceData surfaceData, out float3 bentNormalWS)
            {
                // setup defaults -- these are used if the graph doesn't output a value
                ZERO_INITIALIZE(SurfaceData, surfaceData);
        
                // copy across graph values, if defined
                // surfaceData.baseColor =                 surfaceDescription.Albedo;
                surfaceData.perceptualSmoothness =      surfaceDescription.Smoothness;
                // surfaceData.ambientOcclusion =          surfaceDescription.Occlusion;
                // surfaceData.specularOcclusion =         surfaceDescription.SpecularOcclusion;
                // surfaceData.metallic =                  surfaceDescription.Metallic;
                // surfaceData.subsurfaceMask =            surfaceDescription.SubsurfaceMask;
                // surfaceData.thickness =                 surfaceDescription.Thickness;
                // surfaceData.diffusionProfileHash =      asuint(surfaceDescription.DiffusionProfileHash);
                // surfaceData.specularColor =             surfaceDescription.Specular;
                // surfaceData.coatMask =                  surfaceDescription.CoatMask;
                // surfaceData.anisotropy =                surfaceDescription.Anisotropy;
                // surfaceData.iridescenceMask =           surfaceDescription.IridescenceMask;
                // surfaceData.iridescenceThickness =      surfaceDescription.IridescenceThickness;
        
        #ifdef _HAS_REFRACTION
                if (_EnableSSRefraction)
                {
                    // surfaceData.ior =                       surfaceDescription.RefractionIndex;
                    // surfaceData.transmittanceColor =        surfaceDescription.RefractionColor;
                    // surfaceData.atDistance =                surfaceDescription.RefractionDistance;
        
                    surfaceData.transmittanceMask = (1.0 - surfaceDescription.Alpha);
                    surfaceDescription.Alpha = 1.0;
                }
                else
                {
                    surfaceData.ior = 1.0;
                    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                    surfaceData.atDistance = 1.0;
                    surfaceData.transmittanceMask = 0.0;
                    surfaceDescription.Alpha = 1.0;
                }
        #else
                surfaceData.ior = 1.0;
                surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                surfaceData.atDistance = 1.0;
                surfaceData.transmittanceMask = 0.0;
        #endif
                
                // These static material feature allow compile time optimization
                surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
        #ifdef _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SUBSURFACE_SCATTERING;
        #endif
        #ifdef _MATERIAL_FEATURE_TRANSMISSION
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_TRANSMISSION;
        #endif
        #ifdef _MATERIAL_FEATURE_ANISOTROPY
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_ANISOTROPY;
        #endif
                // surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_CLEAR_COAT;
        
        #ifdef _MATERIAL_FEATURE_IRIDESCENCE
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_IRIDESCENCE;
        #endif
        #ifdef _MATERIAL_FEATURE_SPECULAR_COLOR
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SPECULAR_COLOR;
        #endif
        
        #if defined (_MATERIAL_FEATURE_SPECULAR_COLOR) && defined (_ENERGY_CONSERVING_SPECULAR)
                // Require to have setup baseColor
                // Reproduce the energy conservation done in legacy Unity. Not ideal but better for compatibility and users can unchek it
                surfaceData.baseColor *= (1.0 - Max3(surfaceData.specularColor.r, surfaceData.specularColor.g, surfaceData.specularColor.b));
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                // tangent-space normal
                float3 normalTS = float3(0.0f, 0.0f, 1.0f);
                normalTS = surfaceDescription.Normal;
        
                // compute world space normal
                GetNormalWS(fragInputs, normalTS, surfaceData.normalWS, doubleSidedConstants);
        
                bentNormalWS = surfaceData.normalWS;
                // GetNormalWS(fragInputs, surfaceDescription.BentNormal, bentNormalWS, doubleSidedConstants);
        
                surfaceData.geomNormalWS = fragInputs.tangentToWorld[2];
        
                surfaceData.tangentWS = normalize(fragInputs.tangentToWorld[0].xyz);    // The tangent is not normalize in tangentToWorld for mikkt. TODO: Check if it expected that we normalize with Morten. Tag: SURFACE_GRADIENT
                // surfaceData.tangentWS = TransformTangentToWorld(surfaceDescription.Tangent, fragInputs.tangentToWorld);
                surfaceData.tangentWS = Orthonormalize(surfaceData.tangentWS, surfaceData.normalWS);
        
                // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
                // If user provide bent normal then we process a better term
        #if defined(_SPECULAR_OCCLUSION_CUSTOM)
                // Just use the value passed through via the slot (not active otherwise)
        #elif defined(_SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL)
                // If we have bent normal and ambient occlusion, process a specular occlusion
                surfaceData.specularOcclusion = GetSpecularOcclusionFromBentAO(V, bentNormalWS, surfaceData.normalWS, surfaceData.ambientOcclusion, PerceptualSmoothnessToPerceptualRoughness(surfaceData.perceptualSmoothness));
        #elif defined(_AMBIENT_OCCLUSION) && defined(_SPECULAR_OCCLUSION_FROM_AO)
                surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
        #else
                surfaceData.specularOcclusion = 1.0;
        #endif
        
        #if HAVE_DECALS
                if (_EnableDecals)
                {
                    DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, surfaceDescription.Alpha);
                    ApplyDecalToSurfaceData(decalSurfaceData, surfaceData);
                }
        #endif
        
        #ifdef _ENABLE_GEOMETRIC_SPECULAR_AA
                surfaceData.perceptualSmoothness = GeometricNormalFiltering(surfaceData.perceptualSmoothness, fragInputs.tangentToWorld[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif
        
        #ifdef DEBUG_DISPLAY
                if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
                {
                    // TODO: need to update mip info
                    surfaceData.metallic = 0;
                }
        
                // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
                // as it can modify attribute use for static lighting
                ApplyDebugToSurfaceData(fragInputs.tangentToWorld, surfaceData);
        #endif
            }
        
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
        #ifdef LOD_FADE_CROSSFADE // enable dithering LOD transition if user select CrossFade transition in LOD group
                uint3 fadeMaskSeed = asuint((int3)(V * _ScreenSize.xyx)); // Quantize V to _ScreenSize values
                LODDitheringTransition(fadeMaskSeed, unity_LODFade.x);
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                ApplyDoubleSidedFlipOrMirror(fragInputs, doubleSidedConstants);
        
                SurfaceDescriptionInputs surfaceDescriptionInputs = FragInputsToSurfaceDescriptionInputs(fragInputs, V);
                SurfaceDescription surfaceDescription = SurfaceDescriptionFunction(surfaceDescriptionInputs);
        
                // Perform alpha test very early to save performance (a killed pixel will not sample textures)
                // TODO: split graph evaluation to grab just alpha dependencies first? tricky..
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPrepass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPostpass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow);
                
                // ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
        
                float3 bentNormalWS;
                BuildSurfaceData(fragInputs, surfaceDescription, V, posInput, surfaceData, bentNormalWS);
        
                // Builtin Data
                // For back lighting we use the oposite vertex normal 
                InitBuiltinData(posInput, surfaceDescription.Alpha, bentNormalWS, -fragInputs.tangentToWorld[2], fragInputs.texCoord1, fragInputs.texCoord2, builtinData);
        
                // override sampleBakedGI:
                // builtinData.bakeDiffuseLighting = surfaceDescription.BakedGI;
                // builtinData.backBakeDiffuseLighting = surfaceDescription.BakedBackGI;
        
                // builtinData.emissiveColor = surfaceDescription.Emission;
        
                // builtinData.depthOffset = surfaceDescription.DepthOffset;
        
        #if (SHADERPASS == SHADERPASS_DISTORTION)
                builtinData.distortion = surfaceDescription.Distortion;
                builtinData.distortionBlur = surfaceDescription.DistortionBlur;
        #else
                builtinData.distortion = float2(0.0, 0.0);
                builtinData.distortionBlur = 0.0;
        #endif
        
                PostInitBuiltinData(V, posInput, surfaceData, builtinData);
            }
        
            //-------------------------------------------------------------------------------------
            // Pass Includes
            //-------------------------------------------------------------------------------------
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassMotionVectors.hlsl"
            //-------------------------------------------------------------------------------------
            // End Pass Includes
            //-------------------------------------------------------------------------------------
        
            ENDHLSL
        }
        
        Pass
        {
            // based on HDLitPass.template
            Name "Forward"
            Tags { "LightMode" = "Forward" }
        
            //-------------------------------------------------------------------------------------
            // Render Modes (Blend, Cull, ZTest, Stencil, etc)
            //-------------------------------------------------------------------------------------
            Blend [_SrcBlend] [_DstBlend], [_AlphaSrcBlend] [_AlphaDstBlend]
        
            Cull [_CullModeForward]
        
            ZTest [_ZTestDepthEqualForOpaque]
        
            ZWrite [_ZWrite]
        
            
            // Stencil setup
        Stencil
        {
           WriteMask [_StencilWriteMask]
           Ref [_StencilRef]
           Comp Always
           Pass Replace
        }
        
            ColorMask [_ColorMaskTransparentVel] 1
        
            //-------------------------------------------------------------------------------------
            // End Render Modes
            //-------------------------------------------------------------------------------------
        
            HLSLPROGRAM
        
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //#pragma enable_d3d11_debug_symbols
        
            #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        
            #pragma multi_compile _ LOD_FADE_CROSSFADE
        
            // #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _DOUBLESIDED_ON
            // #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
        
            //-------------------------------------------------------------------------------------
            // Variant Definitions (active field translations to HDRP defines)
            //-------------------------------------------------------------------------------------
            // #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING 1
            // #define _MATERIAL_FEATURE_TRANSMISSION 1
            // #define _MATERIAL_FEATURE_ANISOTROPY 1
            // #define _MATERIAL_FEATURE_IRIDESCENCE 1
            // #define _MATERIAL_FEATURE_SPECULAR_COLOR 1
            // #define _ENABLE_FOG_ON_TRANSPARENT 1
            #define _AMBIENT_OCCLUSION 1
            #define _SPECULAR_OCCLUSION_FROM_AO 1
            // #define _SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL 1
            // #define _SPECULAR_OCCLUSION_CUSTOM 1
            #define _ENERGY_CONSERVING_SPECULAR 1
            // #define _ENABLE_GEOMETRIC_SPECULAR_AA 1
            // #define _HAS_REFRACTION 1
            // #define _REFRACTION_PLANE 1
            // #define _REFRACTION_SPHERE 1
            // #define _DISABLE_DECALS 1
            #define _DISABLE_SSR 1
            // #define _ADD_PRECOMPUTED_VELOCITY
            // #define _WRITE_TRANSPARENT_MOTION_VECTOR 1
            // #define _DEPTHOFFSET_ON 1
            // #define _BLENDMODE_PRESERVE_SPECULAR_LIGHTING 1
        
            //-------------------------------------------------------------------------------------
            // End Variant Definitions
            //-------------------------------------------------------------------------------------
        
            #pragma vertex Vert
            #pragma fragment Frag
        
            // If we use subsurface scattering, enable output split lighting (for forward pass)
            #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
            #define OUTPUT_SPLIT_LIGHTING
            #endif
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
        
            // define FragInputs structure
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
        
            //-------------------------------------------------------------------------------------
            // Defines
            //-------------------------------------------------------------------------------------
                    #define SHADERPASS SHADERPASS_FORWARD
                #pragma multi_compile _ DEBUG_DISPLAY
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ DYNAMICLIGHTMAP_ON
                #pragma multi_compile _ SHADOWS_SHADOWMASK
                #pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
                #pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST
                #pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH
                // ACTIVE FIELDS:
                //   Material.Standard
                //   DisableSSR
                //   Specular.EnergyConserving
                //   AmbientOcclusion
                //   SurfaceDescriptionInputs.VertexColor
                //   SurfaceDescriptionInputs.TangentSpaceNormal
                //   SurfaceDescriptionInputs.uv0
                //   VertexDescriptionInputs.VertexColor
                //   VertexDescriptionInputs.ObjectSpaceNormal
                //   VertexDescriptionInputs.ObjectSpaceTangent
                //   VertexDescriptionInputs.ObjectSpacePosition
                //   VertexDescriptionInputs.uv1
                //   VertexDescriptionInputs.uv2
                //   SurfaceDescription.Albedo
                //   SurfaceDescription.Normal
                //   SurfaceDescription.BentNormal
                //   SurfaceDescription.CoatMask
                //   SurfaceDescription.Metallic
                //   SurfaceDescription.Emission
                //   SurfaceDescription.Smoothness
                //   SurfaceDescription.Occlusion
                //   SurfaceDescription.Alpha
                //   features.modifyMesh
                //   VertexDescription.VertexPosition
                //   VertexDescription.VertexNormal
                //   VertexDescription.VertexTangent
                //   FragInputs.tangentToWorld
                //   FragInputs.positionRWS
                //   FragInputs.texCoord1
                //   FragInputs.texCoord2
                //   FragInputs.color
                //   FragInputs.texCoord0
                //   AttributesMesh.color
                //   AttributesMesh.normalOS
                //   AttributesMesh.tangentOS
                //   AttributesMesh.positionOS
                //   AttributesMesh.uv1
                //   AttributesMesh.uv2
                //   VaryingsMeshToPS.tangentWS
                //   VaryingsMeshToPS.normalWS
                //   VaryingsMeshToPS.positionRWS
                //   VaryingsMeshToPS.texCoord1
                //   VaryingsMeshToPS.texCoord2
                //   VaryingsMeshToPS.color
                //   VaryingsMeshToPS.texCoord0
                //   AttributesMesh.uv0
                // Shared Graph Keywords
        
            // this translates the new dependency tracker into the old preprocessor definitions for the existing HDRP shader code
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            // #define ATTRIBUTES_NEED_TEXCOORD3
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TANGENT_TO_WORLD
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_TEXCOORD1
            #define VARYINGS_NEED_TEXCOORD2
            // #define VARYINGS_NEED_TEXCOORD3
            #define VARYINGS_NEED_COLOR
            // #define VARYINGS_NEED_CULLFACE
            #define HAVE_MESH_MODIFICATION
        
        // We need isFontFace when using double sided
        #if defined(_DOUBLESIDED_ON) && !defined(VARYINGS_NEED_CULLFACE)
            #define VARYINGS_NEED_CULLFACE
        #endif
        
            //-------------------------------------------------------------------------------------
            // End Defines
            //-------------------------------------------------------------------------------------
            
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
        
        #if (SHADERPASS == SHADERPASS_FORWARD)
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        
            #define HAS_LIGHTLOOP
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"
        #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
        #endif
        
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDecalData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"
        
            // Used by SceneSelectionPass
            int _ObjectId;
            int _PassValue;
        
            //-------------------------------------------------------------------------------------
            // Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
            // Generated Type: AttributesMesh
            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL; // optional
                float4 tangentOS : TANGENT; // optional
                float4 uv0 : TEXCOORD0; // optional
                float4 uv1 : TEXCOORD1; // optional
                float4 uv2 : TEXCOORD2; // optional
                float4 color : COLOR; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            // Generated Type: VaryingsMeshToPS
            struct VaryingsMeshToPS
            {
                float4 positionCS : SV_Position;
                float3 positionRWS; // optional
                float3 normalWS; // optional
                float4 tangentWS; // optional
                float4 texCoord0; // optional
                float4 texCoord1; // optional
                float4 texCoord2; // optional
                float4 color; // optional
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif // defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            };
            
            // Generated Type: PackedVaryingsMeshToPS
            struct PackedVaryingsMeshToPS
            {
                float4 positionCS : SV_Position; // unpacked
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
                float4 interp02 : TEXCOORD2; // auto-packed
                float4 interp03 : TEXCOORD3; // auto-packed
                float4 interp04 : TEXCOORD4; // auto-packed
                float4 interp05 : TEXCOORD5; // auto-packed
                float4 interp06 : TEXCOORD6; // auto-packed
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC; // unpacked
                #endif // conditional
            };
            
            // Packed Type: VaryingsMeshToPS
            PackedVaryingsMeshToPS PackVaryingsMeshToPS(VaryingsMeshToPS input)
            {
                PackedVaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                output.interp02.xyzw = input.tangentWS;
                output.interp03.xyzw = input.texCoord0;
                output.interp04.xyzw = input.texCoord1;
                output.interp05.xyzw = input.texCoord2;
                output.interp06.xyzw = input.color;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToPS
            VaryingsMeshToPS UnpackVaryingsMeshToPS(PackedVaryingsMeshToPS input)
            {
                VaryingsMeshToPS output;
                output.positionCS = input.positionCS;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                output.tangentWS = input.interp02.xyzw;
                output.texCoord0 = input.interp03.xyzw;
                output.texCoord1 = input.interp04.xyzw;
                output.texCoord2 = input.interp05.xyzw;
                output.color = input.interp06.xyzw;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif // conditional
                return output;
            }
            // Generated Type: VaryingsMeshToDS
            struct VaryingsMeshToDS
            {
                float3 positionRWS;
                float3 normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif // UNITY_ANY_INSTANCING_ENABLED
            };
            
            // Generated Type: PackedVaryingsMeshToDS
            struct PackedVaryingsMeshToDS
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID; // unpacked
                #endif // conditional
                float3 interp00 : TEXCOORD0; // auto-packed
                float3 interp01 : TEXCOORD1; // auto-packed
            };
            
            // Packed Type: VaryingsMeshToDS
            PackedVaryingsMeshToDS PackVaryingsMeshToDS(VaryingsMeshToDS input)
            {
                PackedVaryingsMeshToDS output;
                output.interp00.xyz = input.positionRWS;
                output.interp01.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            
            // Unpacked Type: VaryingsMeshToDS
            VaryingsMeshToDS UnpackVaryingsMeshToDS(PackedVaryingsMeshToDS input)
            {
                VaryingsMeshToDS output;
                output.positionRWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif // conditional
                return output;
            }
            //-------------------------------------------------------------------------------------
            // End Interpolator Packing And Struct Declarations
            //-------------------------------------------------------------------------------------
        
            //-------------------------------------------------------------------------------------
            // Graph generated code
            //-------------------------------------------------------------------------------------
                    // Shared Graph Properties (uniform inputs)
                    CBUFFER_START(UnityPerMaterial)
                    float _NormalStrength; float _Smoothness;
                    float3 _WindMultipliers;
                    float4 _EmissionColor;
                    float _RenderQueueType;
                    float _StencilRef;
                    float _StencilWriteMask;
                    float _StencilRefDepth;
                    float _StencilWriteMaskDepth;
                    float _StencilRefMV;
                    float _StencilWriteMaskMV;
                    float _StencilRefDistortionVec;
                    float _StencilWriteMaskDistortionVec;
                    float _StencilWriteMaskGBuffer;
                    float _StencilRefGBuffer;
                    float _ZTestGBuffer;
                    float _RequireSplitLighting;
                    float _ReceivesSSR;
                    float _SurfaceType;
                    float _BlendMode;
                    float _SrcBlend;
                    float _DstBlend;
                    float _AlphaSrcBlend;
                    float _AlphaDstBlend;
                    float _ZWrite;
                    float _CullMode;
                    float _TransparentSortPriority;
                    float _CullModeForward;
                    float _TransparentCullMode;
                    float _ZTestDepthEqualForOpaque;
                    float _ZTestTransparent;
                    float _TransparentBackfaceEnable;
                    float _AlphaCutoffEnable;
                    float _UseShadowThreshold;
                    float _DoubleSidedEnable;
                    float _DoubleSidedNormalMode;
                    float4 _DoubleSidedConstants;
                    CBUFFER_END
                    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_TexelSize;
                    TEXTURE2D(_BumpSpecAOMap); SAMPLER(sampler_BumpSpecAOMap); float4 _BumpSpecAOMap_TexelSize;
                    SAMPLER(_SampleTexture2D_1060DFD5_Sampler_3_Linear_Repeat);
                    SAMPLER(_SampleTexture2D_EC10A3ED_Sampler_3_Linear_Repeat);
                
                // Vertex Graph Inputs
                    struct VertexDescriptionInputs
                    {
                        float3 ObjectSpaceNormal; // optional
                        float3 ObjectSpaceTangent; // optional
                        float3 ObjectSpacePosition; // optional
                        float4 uv1; // optional
                        float4 uv2; // optional
                        float4 VertexColor; // optional
                    };
                // Vertex Graph Outputs
                    struct VertexDescription
                    {
                        float3 VertexPosition;
                        float3 VertexNormal;
                        float3 VertexTangent;
                    };
                    
                // Pixel Graph Inputs
                    struct SurfaceDescriptionInputs
                    {
                        float3 TangentSpaceNormal; // optional
                        float4 uv0; // optional
                        float4 VertexColor; // optional
                    };
                // Pixel Graph Outputs
                    struct SurfaceDescription
                    {
                        float3 Albedo;
                        float3 Normal;
                        float3 BentNormal;
                        float CoatMask;
                        float Metallic;
                        float3 Emission;
                        float Smoothness;
                        float Occlusion;
                        float Alpha;
                    };
                    
                // Shared Graph Node Functions
                
                    void UnpackCustomNormal_float(float4 normalSample, out float3 normalOut)
                    {
                        normalOut.xy = normalSample.ag;
                        normalOut.xy = normalOut.xy * 2 - 1;
                        normalOut.z = sqrt( 1 - dot(normalOut.xy , normalOut.xy ));
                    }
                
                    void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
                    {
                        Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
                    }
                
                    void Unity_Multiply_float (float A, float B, out float Out)
                    {
                        Out = A * B;
                    }
                
                    // dcd3c055367822a77956a73ac0a83c36
                    #include "/Includes/CTI_HDRP_Wind.hlsl"
                
                    struct Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8
                    {
                        float3 ObjectSpaceNormal;
                        float3 ObjectSpacePosition;
                        float4 VertexColor;
                        half4 uv1;
                        half4 uv2;
                    };
                
                    void SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(float Vector1_5B3F28E6, float Vector1_39544515, float Vector1_E70341A3, float Vector1_D355D6, float3 Vector3_D146D8D7, float Boolean_BA69BFA3, Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 IN, out float3 Position_1, out float3 Normal_2, out float ColorVariation_3)
                    {
                        float4 _UV_681BEC06_Out_0 = IN.uv1;
                        float4 _UV_5EAEC7D4_Out_0 = IN.uv2;
                        float _Property_66DDE654_Out_0 = Vector1_5B3F28E6;
                        float _Property_F63DDA84_Out_0 = Vector1_39544515;
                        float _Property_32CC05D1_Out_0 = Vector1_E70341A3;
                        float _Property_550822E2_Out_0 = Vector1_D355D6;
                        float3 _Property_9A8CF22B_Out_0 = Vector3_D146D8D7;
                        float _Property_7647AB6A_Out_0 = Boolean_BA69BFA3;
                        float3 _CustomFunction_4DA71B86_position1_10;
                        float3 _CustomFunction_4DA71B86_normal1_11;
                        float _CustomFunction_4DA71B86_color_12;
                        ApplyCTIWind_float(IN.ObjectSpacePosition, IN.VertexColor, (_UV_681BEC06_Out_0.xy), (_UV_5EAEC7D4_Out_0.xy), IN.ObjectSpaceNormal, _Property_66DDE654_Out_0, _Property_F63DDA84_Out_0, _Property_32CC05D1_Out_0, _Property_550822E2_Out_0, _Property_9A8CF22B_Out_0, _Property_7647AB6A_Out_0, _CustomFunction_4DA71B86_position1_10, _CustomFunction_4DA71B86_normal1_11, _CustomFunction_4DA71B86_color_12);
                        Position_1 = _CustomFunction_4DA71B86_position1_10;
                        Normal_2 = _CustomFunction_4DA71B86_normal1_11;
                        ColorVariation_3 = _CustomFunction_4DA71B86_color_12;
                    }
                
                // Vertex Graph Evaluation
                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        float3 _Property_EC5ABF14_Out_0 = _WindMultipliers;
                        Bindings_CTIWind_be4b42ff01448e24c8441bba8b2aceb8 _CTIWind_89A09B02;
                        _CTIWind_89A09B02.ObjectSpaceNormal = IN.ObjectSpaceNormal;
                        _CTIWind_89A09B02.ObjectSpacePosition = IN.ObjectSpacePosition;
                        _CTIWind_89A09B02.VertexColor = IN.VertexColor;
                        _CTIWind_89A09B02.uv1 = IN.uv1;
                        _CTIWind_89A09B02.uv2 = IN.uv2;
                        float3 _CTIWind_89A09B02_Position_1;
                        float3 _CTIWind_89A09B02_Normal_2;
                        float _CTIWind_89A09B02_ColorVariation_3;
                        SG_CTIWind_be4b42ff01448e24c8441bba8b2aceb8(0, 0, 0, 0, _Property_EC5ABF14_Out_0, 1, _CTIWind_89A09B02, _CTIWind_89A09B02_Position_1, _CTIWind_89A09B02_Normal_2, _CTIWind_89A09B02_ColorVariation_3);
                        description.VertexPosition = _CTIWind_89A09B02_Position_1;
                        description.VertexNormal = IN.ObjectSpaceNormal;
                        description.VertexTangent = IN.ObjectSpaceTangent;
                        return description;
                    }
                    
                // Pixel Graph Evaluation
                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        float4 _SampleTexture2D_1060DFD5_RGBA_0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0.xy);
                        float _SampleTexture2D_1060DFD5_R_4 = _SampleTexture2D_1060DFD5_RGBA_0.r;
                        float _SampleTexture2D_1060DFD5_G_5 = _SampleTexture2D_1060DFD5_RGBA_0.g;
                        float _SampleTexture2D_1060DFD5_B_6 = _SampleTexture2D_1060DFD5_RGBA_0.b;
                        float _SampleTexture2D_1060DFD5_A_7 = _SampleTexture2D_1060DFD5_RGBA_0.a;
                        float4 _SampleTexture2D_EC10A3ED_RGBA_0 = SAMPLE_TEXTURE2D(_BumpSpecAOMap, sampler_BumpSpecAOMap, IN.uv0.xy);
                        float _SampleTexture2D_EC10A3ED_R_4 = _SampleTexture2D_EC10A3ED_RGBA_0.r;
                        float _SampleTexture2D_EC10A3ED_G_5 = _SampleTexture2D_EC10A3ED_RGBA_0.g;
                        float _SampleTexture2D_EC10A3ED_B_6 = _SampleTexture2D_EC10A3ED_RGBA_0.b;
                        float _SampleTexture2D_EC10A3ED_A_7 = _SampleTexture2D_EC10A3ED_RGBA_0.a;
                        float3 _CustomFunction_CF03AB98_normalOut_1;
                        UnpackCustomNormal_float(_SampleTexture2D_EC10A3ED_RGBA_0, _CustomFunction_CF03AB98_normalOut_1);
                        float _Property_C6B71BE6_Out_0 = _NormalStrength;
                        float3 _NormalStrength_AA429D2D_Out_2;
                        Unity_NormalStrength_float(_CustomFunction_CF03AB98_normalOut_1, _Property_C6B71BE6_Out_0, _NormalStrength_AA429D2D_Out_2);
                        float _Split_DDDB7F0B_R_1 = IN.VertexColor[0];
                        float _Split_DDDB7F0B_G_2 = IN.VertexColor[1];
                        float _Split_DDDB7F0B_B_3 = IN.VertexColor[2];
                        float _Split_DDDB7F0B_A_4 = IN.VertexColor[3];
                        float _Multiply_1C76B952_Out_2;
                        Unity_Multiply_float(_Split_DDDB7F0B_A_4, _SampleTexture2D_EC10A3ED_B_6, _Multiply_1C76B952_Out_2);
                        surface.Albedo = (_SampleTexture2D_1060DFD5_RGBA_0.xyz);
                        surface.Normal = _NormalStrength_AA429D2D_Out_2;
                        surface.BentNormal = IN.TangentSpaceNormal;
                        surface.CoatMask = 0;
                        surface.Metallic = 0;
                        surface.Emission = float3(0, 0, 0);
                        surface.Smoothness = _SampleTexture2D_1060DFD5_A_7 * _Smoothness;
                        surface.Occlusion = _Multiply_1C76B952_Out_2;
                        surface.Alpha = 1;
                        return surface;
                    }
                    
            //-------------------------------------------------------------------------------------
            // End graph generated code
            //-------------------------------------------------------------------------------------
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
            
            VertexDescriptionInputs AttributesMeshToVertexDescriptionInputs(AttributesMesh input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                // output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                // output.ViewSpaceNormal =             TransformWorldToViewDir(output.WorldSpaceNormal);
                // output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                output.ObjectSpaceTangent =          input.tangentOS;
                // output.WorldSpaceTangent =           TransformObjectToWorldDir(input.tangentOS.xyz);
                // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                // output.ObjectSpaceBiTangent =        normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f) * GetOddNegativeScale());
                // output.WorldSpaceBiTangent =         TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                output.ObjectSpacePosition =         input.positionOS;
                // output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                // output.ViewSpacePosition =           TransformWorldToView(output.WorldSpacePosition);
                // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(TransformObjectToWorld(input.positionOS));
                // output.WorldSpaceViewDirection =     GetWorldSpaceNormalizeViewDir(output.WorldSpacePosition);
                // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(output.WorldSpacePosition), _ProjectionParams.x);
                // output.uv0 =                         input.uv0;
                output.uv1 =                         input.uv1;
                output.uv2 =                         input.uv2;
                // output.uv3 =                         input.uv3;
                output.VertexColor =                 input.color;
            
                return output;
            }
            
            AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            {
                // build graph inputs
                VertexDescriptionInputs vertexDescriptionInputs = AttributesMeshToVertexDescriptionInputs(input);
                // Override time paramters with used one (This is required to correctly handle motion vector for vertex animation based on time)
                // vertexDescriptionInputs.TimeParameters = timeParameters;
            
                // evaluate vertex graph
                VertexDescription vertexDescription = VertexDescriptionFunction(vertexDescriptionInputs);
            
                // copy graph output to the results
                input.positionOS = vertexDescription.VertexPosition;
                input.normalOS = vertexDescription.VertexNormal;
                input.tangentOS.xyz = vertexDescription.VertexTangent;
            
                return input;
            }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : VertexAnimation.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
        //-------------------------------------------------------------------------------------
            // TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
                FragInputs BuildFragInputs(VaryingsMeshToPS input)
                {
                    FragInputs output;
                    ZERO_INITIALIZE(FragInputs, output);
            
                    // Init to some default value to make the computer quiet (else it output 'divide by zero' warning even if value is not used).
                    // TODO: this is a really poor workaround, but the variable is used in a bunch of places
                    // to compute normals which are then passed on elsewhere to compute other values...
                    output.tangentToWorld = k_identity3x3;
                    output.positionSS = input.positionCS;       // input.positionCS is SV_Position
            
                    output.positionRWS = input.positionRWS;
                    output.tangentToWorld = BuildTangentToWorld(input.tangentWS, input.normalWS);
                    output.texCoord0 = input.texCoord0;
                    output.texCoord1 = input.texCoord1;
                    output.texCoord2 = input.texCoord2;
                    // output.texCoord3 = input.texCoord3;
                    output.color = input.color;
                    #if _DOUBLESIDED_ON && SHADER_STAGE_FRAGMENT
                    output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #elif SHADER_STAGE_FRAGMENT
                    // output.isFrontFace = IS_FRONT_VFACE(input.cullFace, true, false);
                    #endif // SHADER_STAGE_FRAGMENT
            
                    return output;
                }
            
                SurfaceDescriptionInputs FragInputsToSurfaceDescriptionInputs(FragInputs input, float3 viewWS)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                    // output.WorldSpaceNormal =            normalize(input.tangentToWorld[2].xyz);
                    // output.ObjectSpaceNormal =           mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M);           // transposed multiplication by inverse matrix to handle normal scale
                    // output.ViewSpaceNormal =             mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_I_V);         // transposed multiplication by inverse matrix to handle normal scale
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                    // output.WorldSpaceTangent =           input.tangentToWorld[0].xyz;
                    // output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
                    // output.ViewSpaceTangent =            TransformWorldToViewDir(output.WorldSpaceTangent);
                    // output.TangentSpaceTangent =         float3(1.0f, 0.0f, 0.0f);
                    // output.WorldSpaceBiTangent =         input.tangentToWorld[1].xyz;
                    // output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
                    // output.ViewSpaceBiTangent =          TransformWorldToViewDir(output.WorldSpaceBiTangent);
                    // output.TangentSpaceBiTangent =       float3(0.0f, 1.0f, 0.0f);
                    // output.WorldSpaceViewDirection =     normalize(viewWS);
                    // output.ObjectSpaceViewDirection =    TransformWorldToObjectDir(output.WorldSpaceViewDirection);
                    // output.ViewSpaceViewDirection =      TransformWorldToViewDir(output.WorldSpaceViewDirection);
                    // float3x3 tangentSpaceTransform =     float3x3(output.WorldSpaceTangent,output.WorldSpaceBiTangent,output.WorldSpaceNormal);
                    // output.TangentSpaceViewDirection =   mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    // output.WorldSpacePosition =          input.positionRWS;
                    // output.ObjectSpacePosition =         TransformWorldToObject(input.positionRWS);
                    // output.ViewSpacePosition =           TransformWorldToView(input.positionRWS);
                    // output.TangentSpacePosition =        float3(0.0f, 0.0f, 0.0f);
                    // output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionRWS);
                    // output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionRWS), _ProjectionParams.x);
                    output.uv0 =                         input.texCoord0;
                    // output.uv1 =                         input.texCoord1;
                    // output.uv2 =                         input.texCoord2;
                    // output.uv3 =                         input.texCoord3;
                    output.VertexColor =                 input.color;
                    // output.FaceSign =                    input.isFrontFace;
                    // output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            
                    return output;
                }
            
                // existing HDRP code uses the combined function to go directly from packed to frag inputs
                FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    VaryingsMeshToPS unpacked= UnpackVaryingsMeshToPS(input);
                    return BuildFragInputs(unpacked);
                }
            
            //-------------------------------------------------------------------------------------
            // END TEMPLATE INCLUDE : SharedCode.template.hlsl
            //-------------------------------------------------------------------------------------
            
        
            void BuildSurfaceData(FragInputs fragInputs, inout SurfaceDescription surfaceDescription, float3 V, PositionInputs posInput, out SurfaceData surfaceData, out float3 bentNormalWS)
            {
                // setup defaults -- these are used if the graph doesn't output a value
                ZERO_INITIALIZE(SurfaceData, surfaceData);
        
                // copy across graph values, if defined
                surfaceData.baseColor =                 surfaceDescription.Albedo;
                surfaceData.perceptualSmoothness =      surfaceDescription.Smoothness;
                surfaceData.ambientOcclusion =          surfaceDescription.Occlusion;
                // surfaceData.specularOcclusion =         surfaceDescription.SpecularOcclusion;
                surfaceData.metallic =                  surfaceDescription.Metallic;
                // surfaceData.subsurfaceMask =            surfaceDescription.SubsurfaceMask;
                // surfaceData.thickness =                 surfaceDescription.Thickness;
                // surfaceData.diffusionProfileHash =      asuint(surfaceDescription.DiffusionProfileHash);
                // surfaceData.specularColor =             surfaceDescription.Specular;
                surfaceData.coatMask =                  surfaceDescription.CoatMask;
                // surfaceData.anisotropy =                surfaceDescription.Anisotropy;
                // surfaceData.iridescenceMask =           surfaceDescription.IridescenceMask;
                // surfaceData.iridescenceThickness =      surfaceDescription.IridescenceThickness;
        
        #ifdef _HAS_REFRACTION
                if (_EnableSSRefraction)
                {
                    // surfaceData.ior =                       surfaceDescription.RefractionIndex;
                    // surfaceData.transmittanceColor =        surfaceDescription.RefractionColor;
                    // surfaceData.atDistance =                surfaceDescription.RefractionDistance;
        
                    surfaceData.transmittanceMask = (1.0 - surfaceDescription.Alpha);
                    surfaceDescription.Alpha = 1.0;
                }
                else
                {
                    surfaceData.ior = 1.0;
                    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                    surfaceData.atDistance = 1.0;
                    surfaceData.transmittanceMask = 0.0;
                    surfaceDescription.Alpha = 1.0;
                }
        #else
                surfaceData.ior = 1.0;
                surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
                surfaceData.atDistance = 1.0;
                surfaceData.transmittanceMask = 0.0;
        #endif
                
                // These static material feature allow compile time optimization
                surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
        #ifdef _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SUBSURFACE_SCATTERING;
        #endif
        #ifdef _MATERIAL_FEATURE_TRANSMISSION
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_TRANSMISSION;
        #endif
        #ifdef _MATERIAL_FEATURE_ANISOTROPY
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_ANISOTROPY;
        #endif
                // surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_CLEAR_COAT;
        
        #ifdef _MATERIAL_FEATURE_IRIDESCENCE
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_IRIDESCENCE;
        #endif
        #ifdef _MATERIAL_FEATURE_SPECULAR_COLOR
                surfaceData.materialFeatures |= MATERIALFEATUREFLAGS_LIT_SPECULAR_COLOR;
        #endif
        
        #if defined (_MATERIAL_FEATURE_SPECULAR_COLOR) && defined (_ENERGY_CONSERVING_SPECULAR)
                // Require to have setup baseColor
                // Reproduce the energy conservation done in legacy Unity. Not ideal but better for compatibility and users can unchek it
                surfaceData.baseColor *= (1.0 - Max3(surfaceData.specularColor.r, surfaceData.specularColor.g, surfaceData.specularColor.b));
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                // tangent-space normal
                float3 normalTS = float3(0.0f, 0.0f, 1.0f);
                normalTS = surfaceDescription.Normal;
        
                // compute world space normal
                GetNormalWS(fragInputs, normalTS, surfaceData.normalWS, doubleSidedConstants);
        
                bentNormalWS = surfaceData.normalWS;
                // GetNormalWS(fragInputs, surfaceDescription.BentNormal, bentNormalWS, doubleSidedConstants);
        
                surfaceData.geomNormalWS = fragInputs.tangentToWorld[2];
        
                surfaceData.tangentWS = normalize(fragInputs.tangentToWorld[0].xyz);    // The tangent is not normalize in tangentToWorld for mikkt. TODO: Check if it expected that we normalize with Morten. Tag: SURFACE_GRADIENT
                // surfaceData.tangentWS = TransformTangentToWorld(surfaceDescription.Tangent, fragInputs.tangentToWorld);
                surfaceData.tangentWS = Orthonormalize(surfaceData.tangentWS, surfaceData.normalWS);
        
                // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
                // If user provide bent normal then we process a better term
        #if defined(_SPECULAR_OCCLUSION_CUSTOM)
                // Just use the value passed through via the slot (not active otherwise)
        #elif defined(_SPECULAR_OCCLUSION_FROM_AO_BENT_NORMAL)
                // If we have bent normal and ambient occlusion, process a specular occlusion
                surfaceData.specularOcclusion = GetSpecularOcclusionFromBentAO(V, bentNormalWS, surfaceData.normalWS, surfaceData.ambientOcclusion, PerceptualSmoothnessToPerceptualRoughness(surfaceData.perceptualSmoothness));
        #elif defined(_AMBIENT_OCCLUSION) && defined(_SPECULAR_OCCLUSION_FROM_AO)
                surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
        #else
                surfaceData.specularOcclusion = 1.0;
        #endif
        
        #if HAVE_DECALS
                if (_EnableDecals)
                {
                    DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, surfaceDescription.Alpha);
                    ApplyDecalToSurfaceData(decalSurfaceData, surfaceData);
                }
        #endif
        
        #ifdef _ENABLE_GEOMETRIC_SPECULAR_AA
                surfaceData.perceptualSmoothness = GeometricNormalFiltering(surfaceData.perceptualSmoothness, fragInputs.tangentToWorld[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif
        
        #ifdef DEBUG_DISPLAY
                if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
                {
                    // TODO: need to update mip info
                    surfaceData.metallic = 0;
                }
        
                // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
                // as it can modify attribute use for static lighting
                ApplyDebugToSurfaceData(fragInputs.tangentToWorld, surfaceData);
        #endif
            }
        
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
        #ifdef LOD_FADE_CROSSFADE // enable dithering LOD transition if user select CrossFade transition in LOD group
                uint3 fadeMaskSeed = asuint((int3)(V * _ScreenSize.xyx)); // Quantize V to _ScreenSize values
                LODDitheringTransition(fadeMaskSeed, unity_LODFade.x);
        #endif
        
        #ifdef _DOUBLESIDED_ON
            float3 doubleSidedConstants = _DoubleSidedConstants.xyz;
        #else
            float3 doubleSidedConstants = float3(1.0, 1.0, 1.0);
        #endif
        
                ApplyDoubleSidedFlipOrMirror(fragInputs, doubleSidedConstants);
        
                SurfaceDescriptionInputs surfaceDescriptionInputs = FragInputsToSurfaceDescriptionInputs(fragInputs, V);
                SurfaceDescription surfaceDescription = SurfaceDescriptionFunction(surfaceDescriptionInputs);
        
                // Perform alpha test very early to save performance (a killed pixel will not sample textures)
                // TODO: split graph evaluation to grab just alpha dependencies first? tricky..
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPrepass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdDepthPostpass);
                // DoAlphaTest(surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow);
                
                // ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
        
                float3 bentNormalWS;
                BuildSurfaceData(fragInputs, surfaceDescription, V, posInput, surfaceData, bentNormalWS);
        
                // Builtin Data
                // For back lighting we use the oposite vertex normal 
                InitBuiltinData(posInput, surfaceDescription.Alpha, bentNormalWS, -fragInputs.tangentToWorld[2], fragInputs.texCoord1, fragInputs.texCoord2, builtinData);
        
                // override sampleBakedGI:
                // builtinData.bakeDiffuseLighting = surfaceDescription.BakedGI;
                // builtinData.backBakeDiffuseLighting = surfaceDescription.BakedBackGI;
        
                builtinData.emissiveColor = surfaceDescription.Emission;
        
                // builtinData.depthOffset = surfaceDescription.DepthOffset;
        
        #if (SHADERPASS == SHADERPASS_DISTORTION)
                builtinData.distortion = surfaceDescription.Distortion;
                builtinData.distortionBlur = surfaceDescription.DistortionBlur;
        #else
                builtinData.distortion = float2(0.0, 0.0);
                builtinData.distortionBlur = 0.0;
        #endif
        
                PostInitBuiltinData(V, posInput, surfaceData, builtinData);
            }
        
            //-------------------------------------------------------------------------------------
            // Pass Includes
            //-------------------------------------------------------------------------------------
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassForward.hlsl"
            //-------------------------------------------------------------------------------------
            // End Pass Includes
            //-------------------------------------------------------------------------------------
        
            ENDHLSL
        }
        
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
    FallBack "Hidden/InternalErrorShader"
}
