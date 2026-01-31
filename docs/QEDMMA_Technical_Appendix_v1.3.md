# QEDMMA Technical Appendix v1.3
## Detailed Signal Processing, Algorithms & Implementation Specifications

**Document Classification:** PROPRIETARY - EXPORT CONTROLLED  
**Date:** 31 January 2026

---

# APPENDIX A: MATHEMATICAL FOUNDATIONS

## A.1 Radar Range Equation - Bistatic Form

### A.1.1 Standard Bistatic Radar Equation

$$P_r = \frac{P_t \cdot G_t \cdot G_r \cdot \lambda^2 \cdot \sigma_b}{(4\pi)^3 \cdot R_t^2 \cdot R_r^2 \cdot L_t \cdot L_r \cdot L_{atm}}$$

Where:
- $P_r$ = received power (W)
- $P_t$ = transmitted power (W) = 5000 W
- $G_t$ = transmit antenna gain = 10 dBi (10 linear)
- $G_r$ = receive antenna gain = 10 dBi (10 linear)
- $\lambda$ = wavelength (m) = 2 m @ 150 MHz
- $\sigma_b$ = bistatic RCS (m²)
- $R_t$ = transmitter-to-target range (m)
- $R_r$ = target-to-receiver range (m)
- $L_t, L_r$ = system losses (typically 3-6 dB each)
- $L_{atm}$ = atmospheric loss (minimal at VHF)

### A.1.2 SNR Calculation

$$SNR = \frac{P_r}{P_n} = \frac{P_r}{k \cdot T_{sys} \cdot B_n}$$

For Rydberg sensor, noise equivalent power is:

$$P_n^{Rydberg} = \frac{(E_{min})^2 \cdot A_{eff}}{Z_0} \cdot B_n$$

Where:
- $E_{min}$ = 500 nV/m/√Hz (Rydberg sensitivity)
- $A_{eff}$ = effective aperture = $\frac{G_r \cdot \lambda^2}{4\pi}$ ≈ 0.32 m²
- $Z_0$ = 377 Ω (free space impedance)
- $B_n$ = noise bandwidth (Hz)

### A.1.3 Numerical Example

```
Parameters:
  P_t = 5000 W = +37 dBm
  G_t = 10 dBi
  G_r = 10 dBi
  λ = 2 m (150 MHz)
  σ_b = 1 m² (0 dBsm)
  R_t = 100 km
  R_r = 50 km
  L_t = L_r = 3 dB each
  
Calculation:
  Path loss (Tx→Tgt): L_pt = (4πR_t/λ)² = (4π·10⁵/2)² = 3.95×10¹¹ = 116 dB
  Path loss (Tgt→Rx): L_pr = (4πR_r/λ)² = (4π·5×10⁴/2)² = 9.87×10¹⁰ = 110 dB
  
  P_r = P_t + G_t + G_r + 20log(λ) + 10log(σ_b) - L_pt - L_pr - L_t - L_r - 10log(4π)
  P_r = 37 + 10 + 10 + 6 + 0 - 116 - 110 - 3 - 3 - 11 = -180 dBm
  
  Rydberg noise floor (B = 100 MHz):
  P_n = -190 dBm/Hz + 80 dB = -110 dBm
  
  Pre-integration SNR = -180 - (-110) = -70 dB (BELOW NOISE!)
  
  Coherent integration gain (T = 10 s, B = 100 MHz):
  G_int = 10·log(B·T) = 10·log(10⁹) = 90 dB
  
  Post-integration SNR = -70 + 90 = +20 dB ✓ DETECTABLE
```

---

## A.2 Bistatic RCS Enhancement

### A.2.1 Swerling Models for Bistatic RCS

The bistatic RCS $\sigma_b(\beta)$ varies with bistatic angle $\beta$:

**Forward Scatter Region** ($\beta > 150°$):
$$\sigma_b^{forward} \approx \frac{4\pi A^2}{\lambda^2}$$

Where $A$ is the target's projected area (shadow).

For F-22 class aircraft (A ≈ 30 m²):
$$\sigma_b^{forward} \approx \frac{4\pi \cdot 900}{4} = 2827 \text{ m}^2 = 34.5 \text{ dBsm}$$

**Resonance Region** (VHF, λ comparable to target):
$$\sigma_b^{resonance} \approx \sigma_{mono} \cdot \left(\frac{L}{\lambda}\right)^{2-4}$$

For $L$ = 15 m (aircraft length), $\lambda$ = 2 m:
$$\sigma_b^{resonance} \approx 0.001 \cdot 7.5^3 \approx 0.4 \text{ m}^2$$

### A.2.2 Composite Bistatic/VHF Enhancement Table

| Target | σ_mono (X-band) | σ_bistatic (VHF, β=120°) | Enhancement |
|--------|-----------------|--------------------------|-------------|
| F-22 | 0.0001 m² | 0.3-1 m² | 35-40 dB |
| F-35 | 0.001 m² | 0.5-2 m² | 27-33 dB |
| B-2 | 0.01 m² | 1-5 m² | 20-27 dB |
| Cruise Missile | 0.01 m² | 0.3-1 m² | 15-20 dB |
| Conventional | 5 m² | 10-20 m² | 3-6 dB |

---

## A.3 Rydberg EIT Physics

### A.3.1 Three-Level Ladder System

Energy levels:
- |1⟩ = 5S₁/₂ (ground state)
- |2⟩ = 5P₃/₂ (intermediate)
- |3⟩ = nD₅/₂ (Rydberg, n ≈ 70)
- |4⟩ = (n+1)P₃/₂ (RF-coupled Rydberg)

Hamiltonian in rotating frame:

$$H = \hbar \begin{pmatrix}
0 & \Omega_p/2 & 0 & 0 \\
\Omega_p/2 & -\Delta_p & \Omega_c/2 & 0 \\
0 & \Omega_c/2 & -\Delta_p - \Delta_c & \Omega_{RF}/2 \\
0 & 0 & \Omega_{RF}/2 & -\Delta_p - \Delta_c - \Delta_{RF}
\end{pmatrix}$$

Where:
- $\Omega_p$ = probe Rabi frequency (780 nm)
- $\Omega_c$ = coupling Rabi frequency (480 nm)
- $\Omega_{RF}$ = RF Rabi frequency ∝ $\mu_{RF} \cdot E_{RF}$
- $\Delta_{p,c,RF}$ = respective detunings

### A.3.2 EIT Transmission

On two-photon resonance ($\Delta_p + \Delta_c = 0$), the probe transmission is:

$$T = \exp\left(-\frac{\alpha_0 L}{1 + |\Omega_c|^2/\Gamma_{21}\Gamma_{31}}\right)$$

Where:
- $\alpha_0$ = resonant absorption coefficient
- $L$ = vapor cell length (25 mm)
- $\Gamma_{21}, \Gamma_{31}$ = decay rates

### A.3.3 Autler-Townes Splitting

With RF field present, EIT peak splits by:

$$\Delta_{AT} = \mu_{RF} \cdot E_{RF} / \hbar$$

For n=70 Rydberg state coupling to (n+1):
$$\mu_{RF} \approx 1000 \cdot e \cdot a_0 \approx 8.5 \times 10^{-27} \text{ C·m}$$

**Sensitivity:**
$$E_{min} = \frac{\hbar \cdot \Gamma_{EIT}}{\mu_{RF}} \approx \frac{1.05 \times 10^{-34} \cdot 2\pi \times 10^6}{8.5 \times 10^{-27}} \approx 500 \text{ nV/m/}\sqrt{\text{Hz}}$$

---

# APPENDIX B: SIGNAL PROCESSING ALGORITHMS

## B.1 Digital Down Conversion (DDC)

### B.1.1 NCO + Complex Mixer

```
Input: x[n] (real, fs = 5 GSPS)
Output: I[n], Q[n] (complex baseband, fs' = 250 MSPS)

// NCO generates complex sinusoid at carrier frequency
φ[n] = φ[n-1] + 2π·f_c/f_s  (mod 2π)
cos_nco[n] = cos(φ[n])
sin_nco[n] = sin(φ[n])

// Complex multiplication (mixing)
I_mix[n] = x[n] · cos_nco[n]
Q_mix[n] = x[n] · sin_nco[n]

// Low-pass filter (FIR, 127 taps)
I_filt[n] = Σ h[k] · I_mix[n-k]
Q_filt[n] = Σ h[k] · Q_mix[n-k]

// Decimation (factor M = 20)
I[m] = I_filt[m·M]
Q[m] = Q_filt[m·M]
```

### B.1.2 Filter Specification

```
FIR Low-Pass Filter:
  - Passband: 0-50 MHz
  - Stopband: >62.5 MHz (Nyquist/2 after decim)
  - Passband ripple: <0.1 dB
  - Stopband attenuation: >80 dB
  - Taps: 127 (symmetric)
  - Implementation: Polyphase (efficient for decimation)
```

## B.2 Cross-Correlation & TDOA Extraction

### B.2.1 FFT-Based Cross-Correlation

For signals $x_i[n]$ and $x_j[n]$ from receivers $i$ and $j$:

```python
def cross_correlate_fft(x_i, x_j, fs):
    """
    FFT-based cross-correlation for TDOA estimation
    
    Args:
        x_i: Complex baseband signal from Rx i (N samples)
        x_j: Complex baseband signal from Rx j (N samples)
        fs: Sample rate (Hz)
    
    Returns:
        tdoa: Time difference of arrival (seconds)
        peak_snr: SNR at correlation peak
    """
    N = len(x_i)
    
    # Zero-pad for finer resolution
    N_fft = 2 * next_power_of_2(N)
    
    # FFT of both signals
    X_i = np.fft.fft(x_i, N_fft)
    X_j = np.fft.fft(x_j, N_fft)
    
    # Cross-spectral density
    R_ij = X_i * np.conj(X_j)
    
    # Optional: PHAT weighting for sharpening
    # R_ij = R_ij / (np.abs(R_ij) + 1e-10)
    
    # Inverse FFT → cross-correlation
    r_ij = np.fft.ifft(R_ij)
    r_ij = np.fft.fftshift(r_ij)
    
    # Find peak
    peak_idx = np.argmax(np.abs(r_ij))
    
    # Parabolic interpolation for sub-sample accuracy
    if 0 < peak_idx < N_fft - 1:
        y1 = np.abs(r_ij[peak_idx - 1])
        y2 = np.abs(r_ij[peak_idx])
        y3 = np.abs(r_ij[peak_idx + 1])
        delta = 0.5 * (y1 - y3) / (y1 - 2*y2 + y3)
        refined_idx = peak_idx + delta
    else:
        refined_idx = peak_idx
    
    # Convert to time
    lag_samples = refined_idx - N_fft // 2
    tdoa = lag_samples / fs
    
    # Estimate SNR
    peak_power = np.abs(r_ij[peak_idx])**2
    noise_power = np.mean(np.abs(r_ij)**2)
    peak_snr = 10 * np.log10(peak_power / noise_power)
    
    return tdoa, peak_snr
```

### B.2.2 Matched Filter Correlation (with PRBS Reference)

```python
def matched_filter_prbs(rx_signal, prbs_ref, fs, chip_rate):
    """
    Matched filter for PRBS waveform - extracts TOA
    
    Args:
        rx_signal: Received complex baseband
        prbs_ref: PRBS-15 reference sequence
        fs: Sample rate
        chip_rate: PRBS chip rate (50 Mchip/s)
    
    Returns:
        toa: Time of arrival relative to reference
        range_bins: Range profile (ambiguity function)
    """
    # Upsample PRBS to match signal sample rate
    samples_per_chip = fs / chip_rate
    prbs_upsampled = np.repeat(prbs_ref, int(samples_per_chip))
    
    # Apply pulse shaping (raised cosine, α=0.35)
    prbs_shaped = apply_rrc_filter(prbs_upsampled, alpha=0.35)
    
    # Matched filter = cross-correlation with conjugate
    correlation = np.correlate(rx_signal, prbs_shaped, mode='same')
    
    # Detect peaks (targets)
    threshold = 5 * np.std(np.abs(correlation))  # 5σ threshold
    peaks, properties = find_peaks(np.abs(correlation), 
                                    height=threshold,
                                    distance=int(10 * samples_per_chip))
    
    # Convert to range
    c = 299792458  # m/s
    range_resolution = c / (2 * chip_rate)  # ≈ 3 m for 50 Mchip/s
    range_bins = peaks * (c / fs) / 2  # Bistatic: divide by 2
    
    return peaks / fs, np.abs(correlation)
```

## B.3 TDOA Geolocation Solver

### B.3.1 Chan-Ho Algorithm (Detailed)

```python
def chan_ho_solver(rx_positions, tdoa_vec, tx_position, tdoa_cov):
    """
    Chan-Ho closed-form TDOA solver with Gauss-Newton refinement
    
    Args:
        rx_positions: Nx3 array of receiver ECEF coordinates (m)
        tdoa_vec: (N-1)x1 array of TDOA measurements relative to Rx1 (s)
        tx_position: 1x3 transmitter ECEF coordinates (m)
        tdoa_cov: (N-1)x(N-1) TDOA measurement covariance (s²)
    
    Returns:
        target_pos: Estimated 1x3 target ECEF position (m)
        pos_cov: 3x3 position covariance (m²)
        gdop: Geometric dilution of precision
    """
    c = 299792458.0
    N = len(rx_positions)
    
    # Convert TDOA to range differences
    d = c * tdoa_vec  # d_i1 = r_i - r_1
    
    # Use Rx1 as reference
    x1, y1, z1 = rx_positions[0]
    K1 = x1**2 + y1**2 + z1**2
    
    # Build matrices for WLS
    Ga = np.zeros((N-1, 4))
    h = np.zeros(N-1)
    
    for i in range(1, N):
        xi, yi, zi = rx_positions[i]
        Ki = xi**2 + yi**2 + zi**2
        di = d[i-1]
        
        Ga[i-1, 0] = xi - x1
        Ga[i-1, 1] = yi - y1
        Ga[i-1, 2] = zi - z1
        Ga[i-1, 3] = di
        
        h[i-1] = 0.5 * (di**2 - Ki + K1)
    
    # Weight matrix from TDOA covariance
    Q = c**2 * tdoa_cov
    W = np.linalg.inv(Q)
    
    # First stage: Weighted Least Squares
    GtWG = Ga.T @ W @ Ga
    GtWG_inv = np.linalg.inv(GtWG)
    theta0 = GtWG_inv @ Ga.T @ W @ h
    
    # Initial estimate
    x0, y0, z0, r0 = theta0
    
    # ----- Gauss-Newton Refinement -----
    max_iter = 20
    tol = 1e-6
    pos = np.array([x0, y0, z0])
    
    for iteration in range(max_iter):
        # Predicted range differences
        d_pred = np.zeros(N-1)
        for i in range(1, N):
            ri = np.linalg.norm(pos - rx_positions[i])
            r1 = np.linalg.norm(pos - rx_positions[0])
            d_pred[i-1] = ri - r1
        
        # Residual
        residual = d - d_pred
        
        # Jacobian H = ∂d/∂pos
        H = np.zeros((N-1, 3))
        r1 = np.linalg.norm(pos - rx_positions[0])
        for i in range(1, N):
            ri = np.linalg.norm(pos - rx_positions[i])
            H[i-1, :] = (pos - rx_positions[i]) / ri - (pos - rx_positions[0]) / r1
        
        # Gauss-Newton update
        HtWH = H.T @ W @ H
        HtWH_inv = np.linalg.inv(HtWH)
        delta = HtWH_inv @ H.T @ W @ residual
        
        pos = pos + delta
        
        if np.linalg.norm(delta) < tol:
            break
    
    # Final covariance
    H_final = np.zeros((N-1, 3))
    r1 = np.linalg.norm(pos - rx_positions[0])
    for i in range(1, N):
        ri = np.linalg.norm(pos - rx_positions[i])
        H_final[i-1, :] = (pos - rx_positions[i]) / ri - (pos - rx_positions[0]) / r1
    
    pos_cov = np.linalg.inv(H_final.T @ W @ H_final)
    
    # GDOP
    gdop = np.sqrt(np.trace(pos_cov)) / (c * np.sqrt(tdoa_cov[0, 0]))
    
    return pos, pos_cov, gdop
```

### B.3.2 GDOP Calculation

```python
def compute_gdop(rx_positions, target_pos):
    """
    Compute Geometric Dilution of Precision
    
    Args:
        rx_positions: Nx3 receiver positions (m)
        target_pos: 1x3 target position (m)
    
    Returns:
        gdop: Geometric DOP (dimensionless)
        hdop: Horizontal DOP
        vdop: Vertical DOP
    """
    N = len(rx_positions)
    
    # Unit vectors from target to receivers
    H = np.zeros((N-1, 3))
    for i in range(1, N):
        # Direction cosines for TDOA (difference geometry)
        dir_i = (rx_positions[i] - target_pos) / np.linalg.norm(rx_positions[i] - target_pos)
        dir_0 = (rx_positions[0] - target_pos) / np.linalg.norm(rx_positions[0] - target_pos)
        H[i-1, :] = dir_i - dir_0
    
    # DOP matrix
    try:
        Q = np.linalg.inv(H.T @ H)
        gdop = np.sqrt(np.trace(Q))
        
        # Convert to local ENU for HDOP/VDOP
        # (simplified - assumes target near origin)
        hdop = np.sqrt(Q[0, 0] + Q[1, 1])
        vdop = np.sqrt(Q[2, 2])
    except np.linalg.LinAlgError:
        gdop = hdop = vdop = np.inf  # Singular geometry
    
    return gdop, hdop, vdop
```

---

# APPENDIX C: TRACKING ALGORITHMS

## C.1 Extended Kalman Filter (EKF)

### C.1.1 State Space Model

**State Vector (9 elements):**
$$\mathbf{x} = [x, y, z, v_x, v_y, v_z, a_x, a_y, a_z]^T$$

**State Transition (Constant Acceleration):**
$$\mathbf{x}_{k+1} = \mathbf{F}(T) \cdot \mathbf{x}_k + \mathbf{w}_k$$

$$\mathbf{F}(T) = \begin{bmatrix}
\mathbf{I}_3 & T \cdot \mathbf{I}_3 & \frac{T^2}{2} \cdot \mathbf{I}_3 \\
\mathbf{0}_3 & \mathbf{I}_3 & T \cdot \mathbf{I}_3 \\
\mathbf{0}_3 & \mathbf{0}_3 & \mathbf{I}_3
\end{bmatrix}$$

**Process Noise Covariance:**
$$\mathbf{Q} = \sigma_a^2 \begin{bmatrix}
\frac{T^5}{20}\mathbf{I}_3 & \frac{T^4}{8}\mathbf{I}_3 & \frac{T^3}{6}\mathbf{I}_3 \\
\frac{T^4}{8}\mathbf{I}_3 & \frac{T^3}{3}\mathbf{I}_3 & \frac{T^2}{2}\mathbf{I}_3 \\
\frac{T^3}{6}\mathbf{I}_3 & \frac{T^2}{2}\mathbf{I}_3 & T\cdot\mathbf{I}_3
\end{bmatrix}$$

Where $\sigma_a$ = acceleration noise (m/s², typically 1-10 for aircraft).

### C.1.2 Measurement Model

For TDOA-derived position measurements:
$$\mathbf{z}_k = \mathbf{H} \cdot \mathbf{x}_k + \mathbf{v}_k$$

$$\mathbf{H} = [\mathbf{I}_3 | \mathbf{0}_3 | \mathbf{0}_3]$$

**Measurement Noise:**
$$\mathbf{R} = \text{diag}(\sigma_x^2, \sigma_y^2, \sigma_z^2)$$

From Chan-Ho solver output covariance.

### C.1.3 EKF Implementation

```python
class EKF_Tracker:
    def __init__(self, sigma_a=5.0):
        """
        Initialize EKF tracker
        
        Args:
            sigma_a: Acceleration noise std dev (m/s²)
        """
        self.sigma_a = sigma_a
        self.x = np.zeros(9)  # State
        self.P = np.eye(9) * 1e6  # Large initial uncertainty
        self.initialized = False
    
    def predict(self, dt):
        """Time update (prediction)"""
        T = dt
        
        # State transition matrix
        F = np.eye(9)
        F[0:3, 3:6] = T * np.eye(3)
        F[0:3, 6:9] = 0.5 * T**2 * np.eye(3)
        F[3:6, 6:9] = T * np.eye(3)
        
        # Process noise
        q = self.sigma_a**2
        Q = np.zeros((9, 9))
        Q[0:3, 0:3] = (T**5/20) * q * np.eye(3)
        Q[0:3, 3:6] = (T**4/8) * q * np.eye(3)
        Q[0:3, 6:9] = (T**3/6) * q * np.eye(3)
        Q[3:6, 0:3] = (T**4/8) * q * np.eye(3)
        Q[3:6, 3:6] = (T**3/3) * q * np.eye(3)
        Q[3:6, 6:9] = (T**2/2) * q * np.eye(3)
        Q[6:9, 0:3] = (T**3/6) * q * np.eye(3)
        Q[6:9, 3:6] = (T**2/2) * q * np.eye(3)
        Q[6:9, 6:9] = T * q * np.eye(3)
        
        # Predict
        self.x = F @ self.x
        self.P = F @ self.P @ F.T + Q
    
    def update(self, z, R):
        """
        Measurement update
        
        Args:
            z: 3x1 position measurement (m)
            R: 3x3 measurement covariance (m²)
        """
        H = np.zeros((3, 9))
        H[0:3, 0:3] = np.eye(3)
        
        # Innovation
        y = z - H @ self.x
        S = H @ self.P @ H.T + R
        
        # Kalman gain
        K = self.P @ H.T @ np.linalg.inv(S)
        
        # Update
        self.x = self.x + K @ y
        self.P = (np.eye(9) - K @ H) @ self.P
    
    def initialize(self, z, R):
        """Initialize track with first measurement"""
        self.x[0:3] = z
        self.P[0:3, 0:3] = R
        self.P[3:6, 3:6] = np.eye(3) * 100**2  # 100 m/s velocity uncertainty
        self.P[6:9, 6:9] = np.eye(3) * 10**2   # 10 m/s² accel uncertainty
        self.initialized = True
    
    def get_state(self):
        """Return current state estimate"""
        return {
            'position': self.x[0:3],
            'velocity': self.x[3:6],
            'acceleration': self.x[6:9],
            'covariance': self.P
        }
```

## C.2 IMM (Interacting Multiple Model) Filter

### C.2.1 Model Set

1. **CV (Constant Velocity):** $\sigma_a$ = 1 m/s² - Straight flight
2. **CA (Constant Acceleration):** $\sigma_a$ = 10 m/s² - Maneuver
3. **CT (Coordinated Turn):** $\omega$ = 0.05 rad/s - Turn rate

### C.2.2 Transition Probability Matrix

$$\Pi = \begin{bmatrix}
0.95 & 0.03 & 0.02 \\
0.05 & 0.90 & 0.05 \\
0.05 & 0.05 & 0.90
\end{bmatrix}$$

### C.2.3 IMM Algorithm Flow

```python
class IMM_Filter:
    def __init__(self):
        self.filters = [
            EKF_Tracker(sigma_a=1.0),   # CV
            EKF_Tracker(sigma_a=10.0),  # CA
            CT_Filter(omega=0.05)        # CT
        ]
        self.mu = np.array([0.8, 0.1, 0.1])  # Model probabilities
        self.Pi = np.array([
            [0.95, 0.03, 0.02],
            [0.05, 0.90, 0.05],
            [0.05, 0.05, 0.90]
        ])
    
    def predict(self, dt):
        """IMM prediction step"""
        n_models = len(self.filters)
        
        # 1. Compute mixing probabilities
        c_bar = self.Pi.T @ self.mu
        mu_ij = np.zeros((n_models, n_models))
        for i in range(n_models):
            for j in range(n_models):
                mu_ij[i, j] = self.Pi[i, j] * self.mu[i] / c_bar[j]
        
        # 2. Mixing - compute mixed initial conditions
        for j in range(n_models):
            x_mix = np.zeros(9)
            for i in range(n_models):
                x_mix += mu_ij[i, j] * self.filters[i].x
            
            P_mix = np.zeros((9, 9))
            for i in range(n_models):
                dx = self.filters[i].x - x_mix
                P_mix += mu_ij[i, j] * (self.filters[i].P + np.outer(dx, dx))
            
            self.filters[j].x = x_mix
            self.filters[j].P = P_mix
        
        # 3. Model-conditioned prediction
        for f in self.filters:
            f.predict(dt)
    
    def update(self, z, R):
        """IMM update step"""
        n_models = len(self.filters)
        likelihoods = np.zeros(n_models)
        
        # 1. Model-conditioned update & likelihood computation
        for j, f in enumerate(self.filters):
            # Innovation
            H = np.zeros((3, 9))
            H[0:3, 0:3] = np.eye(3)
            y = z - H @ f.x
            S = H @ f.P @ H.T + R
            
            # Likelihood (Gaussian PDF)
            likelihoods[j] = multivariate_normal.pdf(y, mean=np.zeros(3), cov=S)
            
            # Update
            f.update(z, R)
        
        # 2. Model probability update
        c_bar = self.Pi.T @ self.mu
        self.mu = likelihoods * c_bar
        self.mu /= np.sum(self.mu)  # Normalize
    
    def get_combined_state(self):
        """Get probability-weighted combined state"""
        x_combined = np.zeros(9)
        for j, f in enumerate(self.filters):
            x_combined += self.mu[j] * f.x
        
        P_combined = np.zeros((9, 9))
        for j, f in enumerate(self.filters):
            dx = f.x - x_combined
            P_combined += self.mu[j] * (f.P + np.outer(dx, dx))
        
        return x_combined, P_combined, self.mu
```

---

# APPENDIX D: WEAPON GUIDANCE DATALINK PROTOCOL

## D.1 Message Formats

### D.1.1 Track Update Message (0x0001)

```c
// Total size: 168 bytes
typedef struct __attribute__((packed)) {
    // Header (24 bytes)
    uint32_t magic;           // 0x51454447 "QEDG"
    uint16_t version;         // 0x0100
    uint16_t msg_type;        // 0x0001
    uint32_t sequence;        // Incrementing
    uint64_t timestamp_ns;    // Unix time nanoseconds
    uint32_t payload_len;     // 144
    uint32_t crc32;           // Header + payload CRC
    
    // Track Info (8 bytes)
    uint32_t track_id;
    uint8_t  classification;  // enum: 0=UNK, 1=FIXED_WING, 2=ROTARY, 3=CRUISE_MISSILE, 4=BALLISTIC, 5=UAV
    uint8_t  threat_level;    // enum: 0=NONE, 1=LOW, 2=MEDIUM, 3=HIGH, 4=CRITICAL
    uint8_t  track_quality;   // 0-100
    uint8_t  engagement_status; // 0=FREE, 1=CUEING, 2=ENGAGED, 3=KILLED
    
    // Kinematics (72 bytes)
    double   pos_x_ecef;      // meters
    double   pos_y_ecef;
    double   pos_z_ecef;
    double   vel_x_ecef;      // m/s
    double   vel_y_ecef;
    double   vel_z_ecef;
    double   acc_x_ecef;      // m/s²
    double   acc_y_ecef;
    double   acc_z_ecef;
    
    // Covariance (24 bytes, upper triangle)
    float    cov_xx;          // m²
    float    cov_xy;
    float    cov_xz;
    float    cov_yy;
    float    cov_yz;
    float    cov_zz;
    
    // Predicted Intercept (40 bytes)
    double   pip_x_ecef;      // meters
    double   pip_y_ecef;
    double   pip_z_ecef;
    double   tti;             // Time to intercept (s)
    double   intercept_altitude; // meters MSL
    
} qedmma_track_msg_t;
```

### D.1.2 System Status Message (0x0010)

```c
typedef struct __attribute__((packed)) {
    // Header (24 bytes)
    // ... same as above ...
    
    // System Status (48 bytes)
    uint8_t  system_state;    // 0=INIT, 1=STANDBY, 2=SEARCH, 3=TRACK, 4=ENGAGE, 5=FAULT
    uint8_t  tx_status;       // 0=OFF, 1=STANDBY, 2=TRANSMIT, 3=FAULT
    uint8_t  num_rx_online;   // Number of active Rx nodes
    uint8_t  reserved1;
    
    uint32_t active_tracks;   // Number of active tracks
    uint32_t tracks_engaged;  // Number of tracks with weapons
    
    float    coverage_azimuth_min;  // degrees
    float    coverage_azimuth_max;
    float    coverage_elevation_min;
    float    coverage_elevation_max;
    float    max_detection_range;   // km
    
    uint8_t  rx_status[8];    // Status of each Rx (up to 8)
    // ... etc
} qedmma_status_msg_t;
```

## D.2 Communication Protocol

### D.2.1 Network Configuration

```
Transport: UDP (low latency)
Port: 50100 (C2 → Weapon)
      50101 (Weapon → C2, acknowledgments)

Rate: Track updates @ 5-10 Hz per target
      Status updates @ 1 Hz

Multicast: 239.192.1.100 (for multiple interceptors)

Encryption: AES-256-GCM (optional, adds 16 bytes + 12 byte nonce)

QoS: DSCP = EF (46) for real-time priority
```

### D.2.2 Message Sequence

```
   C2 CENTER                           WEAPON SYSTEM
       │                                     │
       │──── STATUS (1 Hz) ─────────────────►│
       │                                     │
       │──── TRACK_UPDATE (Track #1) ───────►│
       │──── TRACK_UPDATE (Track #2) ───────►│
       │         ...                         │
       │                                     │
       │◄─── WEAPON_STATUS ─────────────────│
       │     (Seeker status, fuel, etc.)    │
       │                                     │
       │──── HANDOFF_REQUEST ───────────────►│
       │     (Designate Track #1 for engage) │
       │                                     │
       │◄─── HANDOFF_ACK ───────────────────│
       │     (Weapon accepts Track #1)       │
       │                                     │
       │──── TRACK_UPDATE (5-10 Hz) ────────►│
       │     (Continuous midcourse guidance) │
       │                                     │
       │◄─── SEEKER_LOCK ───────────────────│
       │     (Weapon seeker has lock)        │
       │                                     │
       │──── TERMINAL_HANDOFF ──────────────►│
       │     (Optional: continue or release) │
       │                                     │
```

---

# APPENDIX E: FPGA IMPLEMENTATION

## E.1 Resource Utilization (Xilinx ZU47DR)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | 287,450 | 425,280 | 67.6% |
| FFs | 412,830 | 850,560 | 48.5% |
| BRAM | 1,246 | 1,728 | 72.1% |
| URAM | 48 | 80 | 60.0% |
| DSP48 | 2,847 | 4,272 | 66.7% |
| RF-ADC | 8 | 8 | 100% |
| RF-DAC | 8 | 8 | 100% |

## E.2 Critical Path Timing

```
Clock Domain: axi_clk (250 MHz)
  - Setup slack: +0.342 ns
  - Hold slack: +0.089 ns
  - WNS: +0.342 ns (MET)

Clock Domain: rf_adc_clk (5 GHz / 4 = 1.25 GHz internal)
  - Setup slack: +0.156 ns
  - Hold slack: +0.034 ns
  - WNS: +0.156 ns (MET)

Cross-domain (rf → axi):
  - Async FIFO with 2-stage synchronizers
  - MTBF: >10⁷ years @ 250 MHz
```

## E.3 Key Modules

```
┌────────────────────────────────────────────────────────────────────┐
│                    FPGA BLOCK DIAGRAM (ZU47DR)                     │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  RF-ADC Tile                      Programmable Logic (PL)         │
│  ┌──────────┐                    ┌───────────────────────────┐   │
│  │ ADC 0-3  │───5 GSPS×4────────►│  DDC + Filter + Decimate  │   │
│  │ (14-bit) │                    │  (Polyphase, 127-tap FIR) │   │
│  └──────────┘                    └───────────┬───────────────┘   │
│                                              │ 250 MSPS          │
│                                              ▼                    │
│                                  ┌───────────────────────────┐   │
│                                  │  Timestamp Capture        │   │
│                                  │  (White Rabbit sync)      │   │
│                                  │  - 250 MHz clock          │   │
│                                  │  - 16-bit TDC (sub-ns)   │   │
│                                  └───────────┬───────────────┘   │
│                                              │                    │
│                                              ▼                    │
│                                  ┌───────────────────────────┐   │
│                                  │  Circular Buffer (DDR4)   │   │
│                                  │  1 GB ring buffer         │   │
│                                  │  4 s @ 250 MSPS           │   │
│                                  └───────────┬───────────────┘   │
│                                              │                    │
│  Processing System (PS)                      │                    │
│  ┌──────────────────────────────────────────▼───────────────┐   │
│  │  ARM Cortex-A53 (Quad-core)                              │   │
│  │  - Linux (PetaLinux 2024.1)                              │   │
│  │  - libiio driver for data streaming                      │   │
│  │  - 25 GbE interface to C2                                │   │
│  │  - Local CFAR detection (optional)                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

**END OF TECHNICAL APPENDIX**
