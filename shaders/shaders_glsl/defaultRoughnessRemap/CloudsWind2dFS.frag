#version 110
#extension GL_ARB_shader_texture_lod : require

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <RayFrame.h>
const float f0[48] = float[](15.71790981292724609375, 12.89408969879150390625, 7.7199840545654296875, 5.107762813568115234375, 3.9570920467376708984375, 3.1285419464111328125, 2.467976093292236328125, 1.94060599803924560546875, 1.519268035888671875, 1.1720600128173828125, 0.9068109989166259765625, 0.696639001369476318359375, 0.53097999095916748046875, 0.4037419855594635009765625, 0.3046739995479583740234375, 0.230042994022369384765625, 0.1724649965763092041015625, 0.12898500263690948486328125, 0.096061997115612030029296875, 0.07203499972820281982421875, 0.0546710006892681121826171875, 0.0418930016458034515380859375, 0.0329019986093044281005859375, 0.0265490002930164337158203125, 0.022500999271869659423828125, 0.02016899921000003814697265625, 0.01880300045013427734375, 0.01828599907457828521728515625, 0.01808599941432476043701171875, 0.02294900082051753997802734375, 0.02805699966847896575927734375, 0.0330980010330677032470703125, 0.033073000609874725341796875, 0.03599999845027923583984375, 0.051086999475955963134765625, 0.108067996799945831298828125, 0.17280800640583038330078125, 0.2078000009059906005859375, 0.13236899673938751220703125, 0.111766003072261810302734375, 0.110400997102260589599609375, 0.10523100197315216064453125, 0.104189001023769378662109375, 0.108497999608516693115234375, 0.12747399508953094482421875, 0.2075670063495635986328125, 0.3197790086269378662109375, 0.4679400026798248291015625);

#include <CloudsParams.h>
uniform vec4 CB0[53];
uniform vec4 CB4[1];
uniform vec4 CB5[5];
uniform sampler2D CloudsDistanceFieldTexture;
uniform sampler2D DetailTexTexture;

void main()
{
    vec2 f1 = CB4[0].zw * ((gl_FragCoord.xy * CB4[0].xy) - vec2(1.0));
    vec3 f2 = normalize(((CB0[4].xyz * f1.x) + (CB0[5].xyz * f1.y)) - CB0[6].xyz);
    if (f2.y < 0.0)
    {
        discard;
    }
    vec3 f3 = CB0[7].xyz * 0.00028000000747852027416229248046875;
    vec3 f4 = f3;
    f4.y = f3.y + 971.0;
    float f5 = dot(f2, f4);
    float f6 = 2.0 * f5;
    vec2 f7 = (vec2(f5 * (-2.0)) + sqrt(vec2(f6 * f6) - ((vec2(dot(f4, f4)) - vec2(948676.0, 953552.25)) * 4.0))) * 0.5;
    float f8 = f7.x;
    float f9 = dot(CB0[11].xyz, f2);
    float f10 = (0.5 + (0.5 * f9)) * 46.5;
    int f11 = int(f10);
    vec3 f12 = f3 + (f2 * f8);
    f12.y = 0.0;
    vec2 f13 = (f12 + CB5[0].xyz).xz;
    float f14 = f8 * 0.0588235296308994293212890625;
    vec4 f15 = texture2DLod(CloudsDistanceFieldTexture, vec4(f13 * vec2(0.03125), 0.0, f14).xy, f14);
    float f16 = f15.x;
    float f17 = 0.001000000047497451305389404296875 + CB5[4].y;
    float f18 = 0.550000011920928955078125 * CB5[2].x;
    float f19 = 0.180000007152557373046875 * CB5[4].x;
    float f20 = f16 + ((((15.0 * (f16 - f18)) * CB5[4].x) + f19) * texture2DLod(DetailTexTexture, vec4(f13 * f17, 0.0, f14).xy, f14).x);
    bool f21 = f20 < CB5[2].x;
    float f22;
    vec4 f23;
    if (f21)
    {
        float f24 = CB5[2].x - f20;
        vec2 f25 = f13 - (CB0[11].xyz.xz * 0.5);
        float f26 = f7.y * 0.0588235296308994293212890625;
        vec4 f27 = texture2DLod(CloudsDistanceFieldTexture, vec4(f25 * vec2(0.03125), 0.0, f26).xy, f26);
        float f28 = f27.x;
        float f29 = clamp(CB5[2].x - clamp(f28 + ((((15.0 * (f28 - f18)) * CB5[4].x) + f19) * texture2DLod(DetailTexTexture, vec4(f25 * f17, 0.0, f26).xy, f26).x), 0.0, 1.0), 0.0, 1.0);
        float f30 = 0.5 * f24;
        vec3 f31 = f2 * f2;
        bvec3 f32 = lessThan(f2, vec3(0.0));
        vec3 f33 = vec3(f32.x ? f31.x : vec3(0.0).x, f32.y ? f31.y : vec3(0.0).y, f32.z ? f31.z : vec3(0.0).z);
        vec3 f34 = f31 - f33;
        float f35 = f34.x;
        float f36 = f34.y;
        float f37 = f34.z;
        float f38 = f33.x;
        float f39 = f33.y;
        float f40 = f33.z;
        vec3 f41 = (max(mix(vec3(0.1500000059604644775390625 + (f24 * 0.1500000059604644775390625)), mix(CB0[26].xyz, CB0[25].xyz, vec3(f30)), vec3(clamp(exp2(CB0[11].y), 0.0, 1.0))) * (((((((CB0[35].xyz * f35) + (CB0[37].xyz * f36)) + (CB0[39].xyz * f37)) + (CB0[36].xyz * f38)) + (CB0[38].xyz * f39)) + (CB0[40].xyz * f40)) + (((((((CB0[29].xyz * f35) + (CB0[31].xyz * f36)) + (CB0[33].xyz * f37)) + (CB0[30].xyz * f38)) + (CB0[32].xyz * f39)) + (CB0[34].xyz * f40)) * 1.0)), CB0[28].xyz + CB0[27].xyz) + ((CB0[10].xyz * (((((0.2899999916553497314453125 * exp2(f29 * (-9.19999980926513671875))) + (f24 * 0.1689999997615814208984375)) * 0.93599998950958251953125) + ((f29 * 2.400000095367431640625) * f30)) * (0.100000001490116119384765625 + clamp(1.0 - (2.125 * f29), 0.0, 1.0)))) * 2.099999904632568359375)) * CB5[3].xyz;
        float f42 = pow(exp2((-1.44269502162933349609375) * (((50.0 * CB5[2].y) * clamp(1.0 + (0.001000000047497451305389404296875 * (6000.0 - CB0[7].y)), 0.0, 1.0)) * f24)), 0.3300000131130218505859375);
        vec4 f43 = vec4(0.0);
        f43.x = f41.x;
        vec4 f44 = f43;
        f44.y = f41.y;
        vec4 f45 = f44;
        f45.z = f41.z;
        vec3 f46 = f45.xyz + (((((((CB0[10].xyz * clamp(1.0 - (f29 * 1.2799999713897705078125), 0.0, 1.0)) * 2.0) * clamp(-f9, 0.0, 1.0)) * (mix(f0[f11], f0[f11 + 1], fract(f10)) * 0.125)) * (1.0 - f42)) * exp2(0.10999999940395355224609375 - (f29 * 2.2400000095367431640625))) * CB5[3].xyz);
        vec4 f47 = f45;
        f47.x = f46.x;
        vec4 f48 = f47;
        f48.y = f46.y;
        vec4 f49 = f48;
        f49.z = f46.z;
        f23 = f49;
        f22 = f42;
    }
    else
    {
        f23 = vec4(0.0);
        f22 = 1.0;
    }
    if (!(f21 ? true : false))
    {
        discard;
    }
    float f50 = pow(max(exp2((CB0[13].z * 3.5714285373687744140625) * (f8 * f8)), 9.9999997473787516355514526367188e-05), 0.125);
    vec3 f51 = mix(CB0[14].xyz, f23.xyz, vec3(f50));
    vec4 f52 = f23;
    f52.x = f51.x;
    vec4 f53 = f52;
    f53.y = f51.y;
    vec4 f54 = f53;
    f54.z = f51.z;
    float f55 = 1.0 - f22;
    vec4 f56 = f54;
    f56.w = f55;
    vec4 f57 = f56;
    f57.w = f55 * max(f50, CB0[13].y);
    gl_FragData[0] = f57;
}

//$$CloudsDistanceFieldTexture=s0
//$$DetailTexTexture=s2
