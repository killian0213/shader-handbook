// Buffer D (buffer) — Anisotropic surface reconstruct by michael0884
// https://www.shadertoy.com/view/csdfD2

#undef R


#define GAMMA 5.8284271247
#define C_STAR 0.9238795325
#define S_STAR 0.3826834323
#define SVD_EPS 0.0000001

vec2 approx_givens_quat(float s_pp, float s_pq, float s_qq) {
    float c_h = 2.0 * (s_pp - s_qq);
    float s_h2 = s_pq * s_pq;
    float c_h2 = c_h * c_h;
    if (GAMMA * s_h2 < c_h2) {
        float omega = 1.0f / sqrt(s_h2 + c_h2);
        return vec2(omega * c_h, omega * s_pq);
    }
    return vec2(C_STAR, S_STAR);
}

// the quaternion is stored in vec4 like so:
// (c, s * vec3) meaning that .x = c
mat3 quat_to_mat3(vec4 quat) {
    float qx2 = quat.y * quat.y;
    float qy2 = quat.z * quat.z;
    float qz2 = quat.w * quat.w;
    float qwqx = quat.x * quat.y;
    float qwqy = quat.x * quat.z;
    float qwqz = quat.x * quat.w;
    float qxqy = quat.y * quat.z;
    float qxqz = quat.y * quat.w;
    float qyqz = quat.z * quat.w;

    return mat3(1.0f - 2.0f * (qy2 + qz2), 2.0f * (qxqy + qwqz), 2.0f * (qxqz - qwqy),
        2.0f * (qxqy - qwqz), 1.0f - 2.0f * (qx2 + qz2), 2.0f * (qyqz + qwqx),
        2.0f * (qxqz + qwqy), 2.0f * (qyqz - qwqx), 1.0f - 2.0f * (qx2 + qy2));
}

mat3 symmetric_eigenanalysis(mat3 A) {
    mat3 S = transpose(A) * A;
    // jacobi iteration
    mat3 q = mat3(1.0f);
    for (int i = 0; i < 5; i++) {
        vec2 ch_sh = approx_givens_quat(S[0].x, S[0].y, S[1].y);
        vec4 ch_sh_quat = vec4(ch_sh.x, 0, 0, ch_sh.y);
        mat3 q_mat = quat_to_mat3(ch_sh_quat);
        S = transpose(q_mat) * S * q_mat;
        q = q * q_mat;

        ch_sh = approx_givens_quat(S[0].x, S[0].z, S[2].z);
        ch_sh_quat = vec4(ch_sh.x, 0, -ch_sh.y, 0);
        q_mat = quat_to_mat3(ch_sh_quat);
        S = transpose(q_mat) * S * q_mat;
        q = q * q_mat;

        ch_sh = approx_givens_quat(S[1].y, S[1].z, S[2].z);
        ch_sh_quat = vec4(ch_sh.x, ch_sh.y, 0, 0);
        q_mat = quat_to_mat3(ch_sh_quat);
        S = transpose(q_mat) * S * q_mat;
        q = q * q_mat;

    }
    return q;
}

vec2 approx_qr_givens_quat(float a0, float a1) {
    float rho = sqrt(a0 * a0 + a1 * a1);
    float s_h = a1;
    float max_rho_eps = rho;
    if (rho <= SVD_EPS) {
        s_h = 0.0;
        max_rho_eps = SVD_EPS;
    }
    float c_h = max_rho_eps + a0;
    if (a0 < 0.0) {
        float temp = c_h - 2.0 * a0;
        c_h = s_h;
        s_h = temp;
    }
    float omega = 1.0f / sqrt(c_h * c_h + s_h * s_h);
    return vec2(omega * c_h, omega * s_h);
}

struct QR_mats {
    mat3 Q;
    mat3 R;
};

QR_mats qr_decomp(mat3 B) {
    QR_mats qr_decomp_result;
    mat3 R;
    // 1 0
    // (ch, 0, 0, sh)
    vec2 ch_sh10 = approx_qr_givens_quat(B[0].x, B[0].y);
    mat3 Q10 = quat_to_mat3(vec4(ch_sh10.x, 0, 0, ch_sh10.y));
    R = transpose(Q10) * B;

    // 2 0
    // (ch, 0, -sh, 0)
    vec2 ch_sh20 = approx_qr_givens_quat(R[0].x, R[0].z);
    mat3 Q20 = quat_to_mat3(vec4(ch_sh20.x, 0, -ch_sh20.y, 0));
    R = transpose(Q20) * R;

    // 2 1
    // (ch, sh, 0, 0)
    vec2 ch_sh21 = approx_qr_givens_quat(R[1].y, R[1].z);
    mat3 Q21 = quat_to_mat3(vec4(ch_sh21.x, ch_sh21.y, 0, 0));
    R = transpose(Q21) * R;

    qr_decomp_result.R = R;

    qr_decomp_result.Q = Q10 * Q20 * Q21;
    return qr_decomp_result;
}

struct SVD_mats {
    mat3 U;
    mat3 Sigma;
    mat3 V;
};

SVD_mats svd(mat3 A) {
    SVD_mats svd_result;
    svd_result.V = symmetric_eigenanalysis(A);

    mat3 B = A * svd_result.V;

    // sort singular values
    float rho0 = dot(B[0], B[0]);
    float rho1 = dot(B[1], B[1]);
    float rho2 = dot(B[2], B[2]);
    if (rho0 < rho1) {
        vec3 temp = B[1];
        B[1] = -B[0];
        B[0] = temp;
        temp = svd_result.V[1];
        svd_result.V[1] = -svd_result.V[0];
        svd_result.V[0] = temp;
        float temp_rho = rho0;
        rho0 = rho1;
        rho1 = temp_rho;
    }
    if (rho0 < rho2) {
        vec3 temp = B[2];
        B[2] = -B[0];
        B[0] = temp;
        temp = svd_result.V[2];
        svd_result.V[2] = -svd_result.V[0];
        svd_result.V[0] = temp;
        rho2 = rho0;
    }
    if (rho1 < rho2) {
        vec3 temp = B[2];
        B[2] = -B[1];
        B[1] = temp;
        temp = svd_result.V[2];
        svd_result.V[2] = -svd_result.V[1];
        svd_result.V[1] = temp;
    }

    QR_mats QR = qr_decomp(B);
    svd_result.U = QR.Q;
    svd_result.Sigma = QR.R;
    return svd_result;
}

struct UP_mats {
    mat3 U;
    mat3 P;
};

UP_mats SVD_to_polar(SVD_mats B) {
    UP_mats polar;
    polar.P = B.V * B.Sigma * transpose(B.V);
    polar.U = B.U * transpose(B.V);
    return polar;
}

UP_mats polar_decomp(mat3 A) {
    SVD_mats B = svd(A);
    UP_mats polar;
    polar.P = B.V * B.Sigma * transpose(B.V);
    polar.U = B.U * transpose(B.V);
    return polar;
}

vec3 safeDiv(vec3 a, vec3 b) {
    return sign(b) * a / (abs(b) + 1e-4);
}

vec3 safeDiv(vec3 a, float b)
{
    return sign(b)* a / (abs(b) + 1e-4);
}

vec4 quaternion(vec3 axis, float angle) {
    return vec4(axis * sin(angle * 0.5), cos(angle * 0.5));
}

vec4 qmul(vec4 a, vec4 b) {
    return vec4(a.w * b.xyz + b.w * a.xyz + cross(a.xyz, b.xyz), a.w * b.w - dot(a.xyz, b.xyz));
}

mat3 unit(float a) {
    return mat3(a, 0, 0, 0, a, 0, 0, 0, a);
}

mat3 q2m(vec4 q) {
    vec3 a = vec3(-1, 1, 1);
    vec3 u = q.zyz * a * q.w, v = q.xyx * a.xxy * q.w;
    mat3 m = mat3(0, u.x, u.y, u.z, 0, v.x, v.y, v.z, 0) + unit(0.5) + outerProduct(q.xyz, q.xyz) * (1.0 - unit(1.0));
    q *= q;
    m -= mat3(q.y + q.z, 0, 0, 0, q.x + q.z, 0, 0, 0, q.x + q.y);
    return m * 2.0;
}

vec4 m2q(mat3 m) {
    vec4 q;
    q.w = sqrt(max(0.0, 1.0 + m[0][0] + m[1][1] + m[2][2])) / 2.0;
    q.x = sqrt(max(0.0, 1.0 + m[0][0] - m[1][1] - m[2][2])) / 2.0;
    q.y = sqrt(max(0.0, 1.0 - m[0][0] + m[1][1] - m[2][2])) / 2.0;
    q.z = sqrt(max(0.0, 1.0 - m[0][0] - m[1][1] + m[2][2])) / 2.0;

    q.x = abs(q.x) * sign(m[2][1] - m[1][2]);
    q.y = abs(q.y) * sign(m[0][2] - m[2][0]);
    q.z = abs(q.z) * sign(m[1][0] - m[0][1]);
    
    return q;
}

float KernelW(float r, float d)
{
    return (r>d)?0.0:(1.0 - cub(r/d));
}


void UpdateC(inout mat3 C, vec4 pos, Particle p, inout float N)
{
    if(p.mass == 0u) return;
    
	vec3 dx = pos.xyz - p.pos;
    float d = length(dx);
    float mass = float(p.mass);
    float K = mass * KernelW(d, 3.0);
    if(K>0.0) N++;
	C += outerProduct(dx, dx) * K;
}

void UpdatePos(inout vec4 pos, Particle a, Particle p)
{
    if(a.mass == 0u || p.mass == 0u) return;

    vec3 dx = a.pos - p.pos;
    float d = length(dx);
    float mass = float(p.mass);
    float K = mass * KernelW(d, 3.0);
    
	pos += K * vec4(p.pos, 1.0);
}

#define kr 4.0
#define ks 1400.0
#define kn 0.5
#define Ne 6.0

vec3 FixScale(vec3 scale, float N)
{
    if(N <= Ne) return kn*vec3(1.0);
    scale.y = max(scale.y, scale.x/kr);
    scale.z = max(scale.z, scale.x/kr);
    return ks*scale;
}

Covariance GetCovariance(mat3 C, float N) {
    Covariance cov;

    SVD_mats svd = svd(C);
    //get rotaion
    cov.q = m2q(svd.U);
    //get scale
    cov.s = vec3(svd.Sigma[0][0], svd.Sigma[1][1], svd.Sigma[2][2]);
    //normalize scale
    cov.s = FixScale(cov.s, N);
    cov.s /= cov.s.x;
    //invert scale
    //cov.s = 1.0/cov.s;
    return cov;
    
}
//compute particle SPH densities
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    InitGrid(iResolution.xy);
    fragCoord = floor(fragCoord);
    vec3 pos = dim3from2(fragCoord);
    
    Particle p0, p1, pV;
    pV.pos = pos + 0.5;
    
    //load the particles
    vec4 packed = LOAD3D(ch0, pos);
    unpackParticles(packed, pos, p0, p1);
    
    if(p0.mass > 0u || p1.mass >0u)
    {
        vec4 x0 = vec4(0.00001);
        vec4 x1 = x0;
        float N0 = 0.0;
        float N1 = 0.0;
        range(i, -1, 1) range(j, -1, 1) range(k, -1, 1)
        {
            vec3 pos1 = pos + vec3(i, j, k);
            Particle p0_, p1_;
            unpackParticles(LOAD3D(ch0, pos1), pos1, p0_, p1_);
         
            UpdatePos(x0, p0, p0_);
            UpdatePos(x1, p1, p0_);
            UpdatePos(x0, p0, p1_);
            UpdatePos(x1, p1, p1_);
        }
    
        mat3 C0 = mat3(0.0);
        mat3 C1 = C0;
        x0 = x0/x0.w;
        x1 = x1/x1.w;

        range(i, -2, 2) range(j, -2, 2) range(k, -2, 2)
        {
            if(i == 0 && j == 0 && k == 0) continue;
            vec3 pos1 = pos + vec3(i, j, k);
            Particle p0_, p1_;
            unpackParticles(LOAD3D(ch0, pos1), pos1, p0_, p1_);

            UpdateC(C0, x0, p0_, N0);
            UpdateC(C1, x1, p0_, N1);
            UpdateC(C0, x0, p1_, N0);
            UpdateC(C1, x1, p1_, N1);
        }

        UpdateC(C1, x1, p0, N1);
        UpdateC(C0, x0, p1, N0);
    

        Covariance Cov0 = GetCovariance(C0, N0);
        Covariance Cov1 = GetCovariance(C1, N1);

        fragColor = packCovariance(Cov0, Cov1);
    }
}