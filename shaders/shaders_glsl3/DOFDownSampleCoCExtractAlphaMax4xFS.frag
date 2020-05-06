#version 150

struct Params
{
    vec4 TextureSize;
    vec4 Params1;
    vec4 Params2;
    vec4 Params3;
    vec4 Params4;
    vec4 Params5;
    vec4 Params6;
    vec4 Bloom;
};

uniform vec4 CB1[8];
uniform sampler2D iChannel0Texture;

in vec2 VARYING0;
out float _entryPointOutput;

void main()
{
    vec2 f0 = CB1[0].zw * (2.0 * CB1[1].x);
    vec2 f1 = CB1[0].zw * CB1[1].x;
    _entryPointOutput = max(texture(iChannel0Texture, VARYING0).w, max(max(texture(iChannel0Texture, VARYING0 + f0).w, texture(iChannel0Texture, VARYING0 + f1).w), max(texture(iChannel0Texture, VARYING0 - f1).w, texture(iChannel0Texture, VARYING0 - f0).w)));
}

//$$iChannel0Texture=s0