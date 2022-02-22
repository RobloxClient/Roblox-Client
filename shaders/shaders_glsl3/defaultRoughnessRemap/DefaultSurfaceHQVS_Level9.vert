#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <Instance.h>
const vec3 v0[16] = vec3[](vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0));
const vec3 v1[16] = vec3[](vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.699999988079071044921875, 0.699999988079071044921875), vec3(0.0, 0.699999988079071044921875, 0.699999988079071044921875), vec3(0.699999988079071044921875, 0.699999988079071044921875, 0.0), vec3(0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 0.0, -1.0), vec3(0.0, 0.0, 1.0));

uniform vec4 CB0[53];
uniform vec4 CB1[511];
in vec4 POSITION;
in vec4 NORMAL;
in vec4 TEXCOORD0;
in vec4 TEXCOORD2;
in vec4 COLOR0;
out vec2 VARYING0;
out vec2 VARYING1;
out vec4 VARYING2;
out vec4 VARYING3;
out vec4 VARYING4;
out vec4 VARYING5;
out vec4 VARYING6;
out vec4 VARYING7;
out float VARYING8;

void main()
{
    vec3 v2 = (TEXCOORD2.xyz * 0.0078740157186985015869140625) - vec3(1.0);
    int v3 = int(NORMAL.w);
    vec3 v4 = normalize(((NORMAL.xyz * 0.0078740157186985015869140625) - vec3(1.0)) / (CB1[gl_InstanceID * 7 + 3].xyz + vec3(0.001000000047497451305389404296875)));
    vec3 v5 = POSITION.xyz * CB1[gl_InstanceID * 7 + 3].xyz;
    vec4 v6 = POSITION;
    v6.x = v5.x;
    vec4 v7 = v6;
    v7.y = v5.y;
    vec4 v8 = v7;
    v8.z = v5.z;
    float v9 = dot(CB1[gl_InstanceID * 7 + 0], v8);
    float v10 = dot(CB1[gl_InstanceID * 7 + 1], v8);
    float v11 = dot(CB1[gl_InstanceID * 7 + 2], v8);
    vec3 v12 = vec3(v9, v10, v11);
    float v13 = dot(CB1[gl_InstanceID * 7 + 0].xyz, v4);
    float v14 = dot(CB1[gl_InstanceID * 7 + 1].xyz, v4);
    float v15 = dot(CB1[gl_InstanceID * 7 + 2].xyz, v4);
    vec2 v16 = vec2(0.0);
    v16.x = dot(CB1[gl_InstanceID * 7 + 5].xyz, v0[v3]);
    vec2 v17 = v16;
    v17.y = dot(CB1[gl_InstanceID * 7 + 5].xyz, v1[v3]);
    vec2 v18 = v17;
    v18.x = dot(CB1[gl_InstanceID * 7 + 3].xyz, v0[v3]);
    vec2 v19 = v18;
    v19.y = dot(CB1[gl_InstanceID * 7 + 3].xyz, v1[v3]);
    vec4 v20 = vec4(0.0);
    v20.w = sign(TEXCOORD2.w - 0.5);
    vec4 v21 = vec4(v9, v10, v11, 1.0) * mat4(CB0[0], CB0[1], CB0[2], CB0[3]);
    vec3 v22 = ((v12 + (vec3(v13, v14, v15) * 6.0)).yxz * CB0[16].xyz) + CB0[17].xyz;
    vec4 v23 = vec4(0.0);
    v23.x = v22.x;
    vec4 v24 = v23;
    v24.y = v22.y;
    vec4 v25 = v24;
    v25.z = v22.z;
    vec4 v26 = v25;
    v26.w = abs(CB1[gl_InstanceID * 7 + 3].w);
    vec4 v27 = vec4(v9, v10, v11, 0.0);
    v27.w = CB1[gl_InstanceID * 7 + 5].w;
    vec4 v28 = v20;
    v28.x = dot(CB1[gl_InstanceID * 7 + 0].xyz, v2);
    vec4 v29 = v28;
    v29.y = dot(CB1[gl_InstanceID * 7 + 1].xyz, v2);
    vec4 v30 = v29;
    v30.z = dot(CB1[gl_InstanceID * 7 + 2].xyz, v2);
    vec4 v31 = vec4(v13, v14, v15, 0.0);
    v31.w = 0.0;
    gl_Position = v21;
    VARYING0 = (TEXCOORD0.xy * v17) + CB1[gl_InstanceID * 7 + 6].xy;
    VARYING1 = TEXCOORD0.zw * v19;
    VARYING2 = CB1[gl_InstanceID * 7 + 4] * mix(COLOR0 * 0.0039215688593685626983642578125, vec4(1.0), vec4(max(sign(CB1[gl_InstanceID * 7 + 3].w), 0.0)));
    VARYING3 = v26;
    VARYING4 = vec4(CB0[7].xyz - v12, v21.w);
    VARYING5 = v31;
    VARYING6 = v30;
    VARYING7 = v27;
    VARYING8 = TEXCOORD2.w - 1.0;
}

