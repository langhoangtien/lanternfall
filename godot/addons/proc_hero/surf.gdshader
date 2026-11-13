// Procedural surface material for ProcGeo meshes (port of SURF_* in src/10-kit.js).
// No textures: cloth weave, quilting, mail rings, leather creases, dented and rusty plate, fur, wood grain...
// are all computed from the rest position and the surface uv, so they stick to the skin while it animates.
// Vertex data: COLOR = base colour (linear), CUSTOM0 = (roughness, metalness, type, grime), CUSTOM1.xyz = rest position.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 flash_color : source_color = vec3(0.0);   // hit flash: set > 0 for a frame, fade it out
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;   // death dissolve
uniform float dissolve_height = 1.9;
uniform vec3 dissolve_color : source_color = vec3(1.0, 0.45, 0.1);
uniform float glow = 1.0;
uniform float dim = 1.0;
uniform bool surface_bump = true;                        // turn off on very weak phones

varying vec4 v_mat;
varying vec3 v_rest;

float h12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * .1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float h13(vec3 p3) { p3 = fract(p3 * .1031); p3 += dot(p3, p3.zyx + 31.32); return fract((p3.x + p3.y) * p3.z); }
float n2(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
	return mix(mix(h12(i), h12(i + vec2(1., 0.)), f.x), mix(h12(i + vec2(0., 1.)), h12(i + vec2(1., 1.)), f.x), f.y); }
float n3(vec3 p) { vec3 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
	return mix(mix(mix(h13(i), h13(i + vec3(1., 0., 0.)), f.x), mix(h13(i + vec3(0., 1., 0.)), h13(i + vec3(1., 1., 0.)), f.x), f.y),
	           mix(mix(h13(i + vec3(0., 0., 1.)), h13(i + vec3(1., 0., 1.)), f.x), mix(h13(i + vec3(0., 1., 1.)), h13(i + vec3(1., 1., 1.)), f.x), f.y), f.z); }
float fb3(vec3 p) { return .5 * n3(p) + .25 * n3(p * 2.03 + 7.1) + .125 * n3(p * 4.1 + 3.3); }

void vertex() {
	v_mat = CUSTOM0;
	v_rest = CUSTOM1.xyz;
}

void fragment() {
	float ty = v_mat.z;
	vec3 col = COLOR.rgb;
	float rough = v_mat.x, metal = v_mat.y, h = 0.;
	vec3 em = vec3(0.);
	vec2 uv = UV;
	vec3 rp = v_rest;
	float px = max(fwidth(uv.x), fwidth(uv.y));
	float big = fb3(rp * 9.), fine = n3(rp * 70.);
	if (dissolve > 0.) {
		float dz = (rp.y / dissolve_height) * .72 + n3(rp * 17.) * .28;
		float th = dissolve * 1.06;
		if (dz < th) discard;
		em += dissolve_color * smoothstep(.07, 0., dz - th) * 7.;
	}
	float mudK = 1.;
	if (ty < .5) { // skin
		col *= .82 + .36 * big; h = fine * .0006;
	} else if (ty < 1.5) { // cloth
		float f = smoothstep(.0016, .0006, px); float w = sin(uv.x * 1570.) * sin(uv.y * 1570.);
		float fold = n3(rp * vec3(26., 5., 26.));
		h = w * .0004 * f + big * .002 + fold * .006; col *= (.72 + .42 * big) * (1. + .14 * w * f) * (.8 + .4 * fold);
	} else if (ty < 2.5) { // quilted
		float q = abs(sin(uv.x * 98. + 1.5 * n3(rp * vec3(3., 9., 3.)))); float pil = pow(q, .7);
		h = pil * .0034 + fine * .0006 + n3(rp * vec3(30., 6., 30.)) * .004;
		col *= (.78 + .22 * pil) * (.74 + .44 * big); col *= 1. - .3 * smoothstep(.12, .0, q);
		float st = smoothstep(.75, 1., sin(uv.y * 900.)) * smoothstep(.2, .05, q); col *= 1. + .6 * st;
	} else if (ty < 3.5) { // mail
		float f = smoothstep(.0036, .0012, px);
		vec2 g = uv * 349.; float row = floor(g.y / 3.14159); g.x += mod(row, 2.) * 1.5708;
		float r = abs(sin(g.x)) * abs(sin(g.y));
		h = r * .0024 * f; col *= mix(.72, .3 + 1.0 * r, f) * (.75 + .5 * big);
		float gl = step(.9, h13(floor(rp * 240.))); rough = mix(rough, .22, gl * .7);
		float rust = smoothstep(.5, .75, fb3(rp * 13. + 1.7)); col = mix(col, vec3(.07, .036, .02), rust * .5); metal *= 1. - rust * .5;
	} else if (ty < 4.5) { // leather
		float cr = abs(n3(rp * vec3(60., 24., 60.)) - .5) * 2.; cr = smoothstep(.0, .22, cr); float fold = n3(rp * vec3(18., 7., 18.));
		h = fine * .0008 + cr * .0007 + fold * .004; col *= (.72 + .4 * big) * (.9 + .1 * cr) * (.85 + .3 * fold); rough -= .12 * fine;
	} else if (ty < 5.5) { // plate
		float sc = n3(rp * vec3(34., 260., 34.)), dent = n3(rp * 27.);
		h = dent * .0028 + sc * .0004;
		float rust = smoothstep(.46, .66, fb3(rp * 17. + 3.) + (v_mat.w - 1.) * .2 + v_mat.w * .12 * (1. - smoothstep(.2, 1.3, rp.y)));
		col *= .74 + .42 * sc; rough += (sc - .5) * .3 + (dent - .5) * .2;
		col = mix(col, vec3(.085, .042, .022) * (.5 + .9 * fine), rust * .88); metal *= 1. - rust * .85; rough = mix(rough, .93, rust);
		mudK = .7;
	} else if (ty < 6.5) { // fur
		float ff = smoothstep(.004, .0012, px); float s = mix(.5, n3(rp * vec3(210., 26., 210.)), ff), s2 = n3(rp * vec3(64., 11., 64.) + 9.), s3 = n3(rp * 19.);
		h = s * .003 * ff + s2 * .006 + s3 * .012; col *= (.36 + .5 * s2 + .4 * s * s) * (.55 + .9 * s3);
	} else if (ty < 7.5) { // wood
		float gr = n2(vec2(uv.x * 260., uv.y * 9.)), g2 = n2(vec2(uv.x * 60., uv.y * 3.) + 4.);
		h = gr * .0016; col *= .6 + .34 * gr + .26 * g2;
	} else if (ty < 8.5) { // stone
		float s = fb3(rp * 5.), s2 = fb3(rp * 23. + 5.), s3 = n3(rp * 90.);
		h = s * .03 + s2 * .01 + s3 * .0015; col *= .42 + .6 * s2 + .25 * s;
		float lich = smoothstep(.5, .6, fb3(rp * 3.7 + 11.)); col = mix(col, vec3(.035, .05, .025), lich * .7);
		float l2 = smoothstep(.64, .7, fb3(rp * 8.1 + 31.)); col = mix(col, vec3(.2, .2, .17), l2 * .4);
		mudK = .4;
	} else if (ty < 9.5) { // peat
		float rd = abs(n2(vec2(uv.x * 80., uv.y * 13.)) - .5) * 2., s2 = fb3(rp * 14.);
		h = rd * .008 + s2 * .008; col *= .45 + .5 * rd + .4 * s2;
	} else if (ty < 10.5) { // glow
		em += col * v_mat.w * glow; col *= .05; mudK = 0.;
	} else { // bone
		float gr = n2(vec2(uv.x * 150., uv.y * 18.)); h = gr * .001; col *= .7 + .3 * big + .12 * gr;
		float st = smoothstep(.5, .7, fb3(rp * 11.)); col = mix(col, col * vec3(.5, .42, .3), st * .7);
	}
	// mud and grime creep up from the ground
	if (mudK > 0. && ty < 9.5) {
		float mud = v_mat.w * mudK * (1. - smoothstep(.02, .62, rp.y + (big - .45) * .5));
		col = mix(col, vec3(.04, .032, .024) * (.7 + .6 * fine), mud * .8); rough = mix(rough, .95, mud); metal *= 1. - mud * .9;
	}
	ALBEDO = col * dim;
	ROUGHNESS = clamp(rough, .05, 1.);
	METALLIC = clamp(metal, 0., 1.);
	EMISSION = em + flash_color;
	// bump from the height field (screen-space derivatives, no tangents needed)
	if (surface_bump) {
		vec3 n = NORMAL;
		vec3 dp1 = dFdx(VERTEX), dp2 = dFdy(VERTEX);
		float dhx = dFdx(h), dhy = dFdy(h);
		vec3 r1 = cross(dp2, n), r2 = cross(n, dp1);
		float det = dot(dp1, r1);
		if (abs(det) > 1e-12) {
			vec3 gr = sign(det) * (dhx * r1 + dhy * r2);
			NORMAL = normalize(abs(det) * n - clamp(gr, -abs(det) * 2.5, abs(det) * 2.5));
		}
	}
}
