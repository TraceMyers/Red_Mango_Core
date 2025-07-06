
Color2f :: struct {
    r: float32;
    g: float32;

#place r;
    vec2: Vector2 = ---;

#place r;
    component: [2]float = ---;
}

Color3f :: struct {
    r: float32;
    g: float32;
    b: float32;

#place r;
    rg: Color2f = ---;
#place g;
    gb: Color2f = ---;

#place r;
    vec3: Vector3 = ---;

#place r;
    component: [3]float = ---;
}

Color4f :: struct {
    r: float32;
    g: float32;
    b: float32;
    a: float32 = 1.0;

#place r;
    rgb: Color3f = ---;
#place r;
    rg: Color2f = ---;
#place g;
    gb: Color2f = ---;
#place b;
    ba: Color2f = ---;

#place r;
    vec4: Vector4 = ---;
#place r;
    vec3: Vector3 = ---;

#place r;
    component: [4]float = ---;
}

Color4b :: struct {
    r: u8 #align 4; // should align to 4 bytes so this struct can be read as a u32;
    g: u8;
    b: u8;
    a: u8 = 255;

#place r;
    bytes: [4]u8 = ---;
#place r;
    _u32: u32 = ---;
}

to_color4b :: inline (color4f: Color4f) -> Color4b {
    byte_color: Color4b = ---;
    byte_color.r = alter_cast(color4f.r, u8, true);
    byte_color.g = alter_cast(color4f.g, u8, true);
    byte_color.b = alter_cast(color4f.b, u8, true);
    byte_color.a = alter_cast(color4f.a, u8, true);
    return byte_color;
}

to_color4f :: inline (color4b: Color4b) -> Color4f {
    float_color: Color4f = ---;
    float_color.r = alter_cast(color4b.r, float, true);
    float_color.g = alter_cast(color4b.g, float, true);
    float_color.b = alter_cast(color4b.b, float, true);
    float_color.a = alter_cast(color4b.a, float, true);
    return float_color;
}