

uint Hash_Wang(uint key) {
    key = (key ^ 61u) ^ (key >> 16u);
    key = key + (key << 3u);
    key = key ^ (key >> 4u);
    key = key * 0x27D4EB2Du;
    key = key ^ (key >> 15u);
    return key;
}

float UniformUintToFloat(uint u) {
    // IEEE-754: 2^-32 = 0x2F800000
    return float(u) * asfloat(0x2F800000u);
}

uint Random1u(inout uint state) {
    // Xorshift: slower than LCG better distribution for long sequences
    state ^= (state << 13u);
    state ^= (state >> 17u);
    state ^= (state << 5u);

    // LCG: faster than Xorshift, but poorer distribution for long sequences
    //const uint multiplier = 1664525u;
    //const uint increment  = 1013904223u;
    //state *= multiplier;
    //state += increment;

    return state;
}

float Random1f(inout uint state) {
    return UniformUintToFloat(Random1u(state));
}

float2 Random2f(inout uint state) {
    return float2(Random1f(state),Random1f(state));
}

float3 Random3f(inout uint state) {
    return float3(Random1f(state), Random1f(state), Random1f(state));
}

