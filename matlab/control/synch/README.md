### notes

###### adicionar PLF dpeois do observador

###### 1a etapa
##### Back-EMF Observer + atan2 for PMSM Sensorless Control

###### 2a etapa
##### Back-EMF Observer + SRF-PLL for PMSM Sensorless Control

## Signal Flow

```text
ia ib ic
 │
 ▼
Clarke
 │
 ▼
iα iβ
 │
 ▼

eα = vα - Rs·iα - Ls·diα/dt

eβ = vβ - Rs·iβ - Ls·diβ/dt

 │
 ▼
LPF COM fc = 300 Hz
 │
 ▼
êα êβ
 │
 ▼
atan2
 │
 ▼
θ̂
```

---

## Clarke Transformation

Convert the three-phase currents into the stationary αβ reference frame:

```math
i_\alpha = i_a
```

```math
i_\beta = -\frac{\sqrt{3}}{3}i_a-\frac{2\sqrt{3}}{3}i_c
```

---

## Back-EMF Observer

Using the PMSM stator voltage equations:

```math
e_\alpha = v_\alpha - R_s i_\alpha - L_s\frac{di_\alpha}{dt}
```

```math
e_\beta = v_\beta - R_s i_\beta - L_s\frac{di_\beta}{dt}
```

where:

- \(R_s\) = stator resistance
- \(L_s\) = stator inductance
- \(v_\alpha, v_\beta\) = stator voltages in αβ frame
- \(i_\alpha, i_\beta\) = stator currents in αβ frame

---

## Low-Pass Filter

To mitigate noise caused by the numerical differentiation:

```text
eα → LPF → êα

eβ → LPF → êβ
```

---

## Rotor Position Estimation

The estimated electrical angle is obtained from the estimated Back-EMF vector:

```math
\hat{\theta} = \operatorname{atan2}(\hat{e}_{\beta},\hat{e}_{\alpha})
```

or in MATLAB:

```matlab
theta_hat = atan2(e_beta_hat,e_alpha_hat);
```

where:

- \(\hat{e}_{\alpha}\) = filtered α-axis Back-EMF
- \(\hat{e}_{\beta}\) = filtered β-axis Back-EMF

---

## Expected Waveforms

### Estimated Back-EMF

```text
êα → sinusoidal

êβ → sinusoidal (90° shifted)
```

### Estimated Position

```text
θ̂ → electrical rotor angle
```

typically varying as:

```text
0 → 2π → 0 → 2π ...
```

---

## Next Evolution

After validating the observer with atan2:

```text
Back-EMF Observer
        +
      atan2
```

replace the angle extractor by:

```text
Back-EMF Observer
        +
      SRF-PLL
```

resulting in:

```text
Back-EMF Observer
        ↓
   êα , êβ
        ↓
     SRF-PLL
        ↓
    θ̂ , ω̂
```

which provides both estimated rotor position and estimated electrical speed for FOC or FCS-MPC applications.
