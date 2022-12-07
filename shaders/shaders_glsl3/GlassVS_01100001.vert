#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <InstanceData.h>
const vec3 v0[16] = vec3[](vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0));
const vec3 v1[16] = vec3[](vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.699999988079071044921875, 0.699999988079071044921875), vec3(0.0, 0.699999988079071044921875, 0.699999988079071044921875), vec3(0.699999988079071044921875, 0.699999988079071044921875, 0.0), vec3(0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 0.0, -1.0), vec3(0.0, 0.0, 1.0));

uniform vec4 CB0[58];
uniform vec4 CB1[511];
in vec4 POSITION;
in vec4 TEXCOORD1;
in vec4 TEXCOORD0;
in vec4 TEXCOORD2;
in vec4 COLOR0;
out vec2 VARYING0;
out vec3 VARYING1;
out vec4 VARYING2;
out vec4 VARYING3;
out vec4 VARYING4;
out vec4 VARYING5;
out vec4 VARYING6;
out vec4 VARYING7;

void main()
{
    int v2 = int(TEXCOORD1.z);
    vec3 v3 = normalize(((vec3(TEXCOORD1.xy, COLOR0.w) * 0.0078740157186985015869140625) - vec3(1.0)) / (CB1[gl_InstanceID * 7 + 3].xyz + vec3(0.001000000047497451305389404296875)));
    vec3 v4 = POSITION.xyz * CB1[gl_InstanceID * 7 + 3].xyz;
    vec4 v5 = POSITION;
    v5.x = v4.x;
    vec4 v6 = v5;
    v6.y = v4.y;
    vec4 v7 = v6;
    v7.z = v4.z;
    float v8 = dot(CB1[gl_InstanceID * 7 + 0], v7);
    float v9 = dot(CB1[gl_InstanceID * 7 + 1], v7);
    float v10 = dot(CB1[gl_InstanceID * 7 + 2], v7);
    vec3 v11 = vec3(v8, v9, v10);
    float v12 = dot(CB1[gl_InstanceID * 7 + 0].xyz, v3);
    float v13 = dot(CB1[gl_InstanceID * 7 + 1].xyz, v3);
    float v14 = dot(CB1[gl_InstanceID * 7 + 2].xyz, v3);
    vec3 v15 = vec3(v12, v13, v14);
    vec2 v16 = vec2(0.0);
    v16.x = dot(CB1[gl_InstanceID * 7 + 5].xyz, v0[v2]);
    vec2 v17 = v16;
    v17.y = dot(CB1[gl_InstanceID * 7 + 5].xyz, v1[v2]);
    vec2 v18 = (TEXCOORD0.xy * v17) + CB1[gl_InstanceID * 7 + 6].xy;
    vec4 v19 = CB1[gl_InstanceID * 7 + 4] * mix(vec4(COLOR0.xyz, TEXCOORD1.w) * 0.0039215688593685626983642578125, vec4(1.0), vec4(max(sign(CB1[gl_InstanceID * 7 + 3].w), 0.0)));
    vec3 v20 = CB0[11].xyz - v11;
    vec2 v21 = vec2(v18.x * 4.0, v18.y);
    bvec2 v22 = bvec2(abs(TEXCOORD2.w - 3.5) > 2.0);
    vec2 v23 = vec2(v22.x ? vec2(0.0).x : v21.x, v22.y ? vec2(0.0).y : v21.y);
    vec3 v24 = vec3(0.0);
    v24.z = TEXCOORD2.w - 2.0;
    vec3 v25 = -CB0[16].xyz;
    float v26 = dot(v15, v25);
    vec4 v27 = vec4(v8, v9, v10, 1.0);
    vec4 v28 = v27 * mat4(CB0[0], CB0[1], CB0[2], CB0[3]);
    vec3 v29 = v24;
    v29.x = v23.x;
    vec3 v30 = v29;
    v30.y = v23.y;
    vec3 v31 = ((v11 + (v15 * 6.0)).yxz * CB0[21].xyz) + CB0[22].xyz;
    vec4 v32 = vec4(0.0);
    v32.x = v31.x;
    vec4 v33 = v32;
    v33.y = v31.y;
    vec4 v34 = v33;
    v34.z = v31.z;
    vec4 v35 = v34;
    v35.w = abs(CB1[gl_InstanceID * 7 + 3].w);
    vec4 v36 = vec4(v20, v28.w);
    float v37 = v19.w * 2.0;
    float v38 = clamp(v37 - 1.0, 0.0, 1.0);
    float v39 = (clamp(2.0 - (dot(v15, normalize(v36.xyz)) * 3.0), 0.0, 1.0) * 0.300000011920928955078125) * clamp(v37, 0.0, 1.0);
    vec4 v40 = v19;
    v40.w = mix(v38, 1.0, v39);
    vec4 v41 = vec4(dot(CB0[25], v27), dot(CB0[26], v27), dot(CB0[27], v27), 0.0);
    v41.w = mix(CB1[gl_InstanceID * 7 + 5].w * v38, 1.0, v39);
    float v42 = CB1[gl_InstanceID * 7 + 6].z * 0.50359570980072021484375;
    float v43 = clamp(v26, 0.0, 1.0);
    vec3 v44 = (CB0[15].xyz * v43) + (CB0[17].xyz * clamp(-v26, 0.0, 1.0));
    vec4 v45 = vec4(0.0);
    v45.x = v44.x;
    vec4 v46 = v45;
    v46.y = v44.y;
    vec4 v47 = v46;
    v47.z = v44.z;
    vec4 v48 = v47;
    v48.w = (v43 * CB0[28].w) * (CB1[gl_InstanceID * 7 + 6].z * exp2((v42 * dot(v15, normalize(v25 + normalize(v20)))) - v42));
    gl_Position = v28;
    VARYING0 = v18;
    VARYING1 = v30;
    VARYING2 = v40;
    VARYING3 = v35;
    VARYING4 = v36;
    VARYING5 = vec4(v12, v13, v14, CB1[gl_InstanceID * 7 + 6].w);
    VARYING6 = v48;
    VARYING7 = v41;
}

