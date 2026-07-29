// Image (image) —  Water Surface Simulation by TinyTexel
// https://www.shadertoy.com/view/wl3cDj

// author: Mirko Salm (https://twitter.com/Mirko_Salm)

/*

A minimalist grid based water simulation that accounts for the dispersion relation of surface gravity waves.


My main contributions here are: 

    - two dispersion kernels (13 tabs in 1 pass / 30 tabs in 2 passes) with which the vertical acceleration of deep water can be computed
    - a blending scheme that locally morphs a deep water kernel into one that handles shallow water
    - a high quality rendering approach based on an efficient C2 continuous bicubic reconstruction of the water height field


Algorithm overview:

    Buffer A: water simulation (solves a simple second order partial differential equation using Verlet integration)
    Buffer B: horizontal pass of the high quality dispersion kernel (the complementing vertical pass is part of Buffer A)
    Buffer C: bicubic pre-filtering of the simulation result (computes smoothed partial derivatives + height field values at grid vertices)
    Image   : rendering using the pre-filtered water height field stored in Buffer C


Controls:

    left mouse (hold/click) - add water (hold shift key for individual droplets)
    space key  (hold)       - flatten/dampen water surface

    [1] - toggle terrain animation off/on
    [2] - toggle grid windowing off/on (off leads to waves being reflected at the borders of the grid)
    [3] - toggle mini map on/off (also shows if windowing is active)
    [4] - toggle wave field rendering style in mini map between |gradient|² and height value
    [5] - toggle rain drops off/on



▬▬▬ 0.Motivation and previous work ▬▬▬
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

Volumetric fluid simulations can achieve impressive and interesting results both visually as well as gameplay-wise.
However, in cases where we are only interested in a small subset of those possible results, a more minimalist approach might suffice.
A typical case could be a scene where objects interacting with a body of water are supposed to cause believable disturbances to its surface. 
If those disturbances are rather small than it can be reasonable to model them as deformations to a height field instead of to a volume.

Compared to volumetric models height field based fluid simulations are usually less memory and performance intensive while being easier to implement and maintain.
Naturally, this makes them an attractive choice in many cases.

As early as 1990 [1] described the idea of using a height field based water simulation in the context of computer graphics.
Where [1] proposed to use an implicit integration scheme to advance the simulation, [2] instead opted for a simple Verlet integrator; effectively trading stability for simplicity.
Another aspect in which [1] and [2] differed is that in an attempt to simulate deep instead of shallow water (as was done in [1]) [2] replaced the operator with 
which the vertical acceleration of the height field was computed. Source code of a practical implementation of that method can be found in [4].
In [5] the same author addressed the stability issue of the Verlet integrator by introducing an exponential solver.

The deep water operator introduced in [2] is rather computationally expensive as it is implemented via a non-separable 13x13 convolution kernel.
Also, no theoretical background on that operator is provided. Both of these concerns will be addressed here.

Before moving on it seems sensible to shortly motivate, from a phenomenological point of view, why we care about the difference of shallow and deep water.
For that purpose let us consider the idealized case of a single rain drop falling onto a perfectly flat water surface for which we ignore its surface tension. 
In both cases circular wavefronts begin to emitt from the point where the drop hits the surface.
In the case of shallow water we can actually only observe a single wavefront while in deep water multiple wavefronts of different wavelengths 
traveling at different velocities emerge. Replicating this dispersive behavior in deep water is one of the major challenges addressed here.

It is also important to note that for the type of waves considered here we are not interested in the absolute depth of the water but the wavelength-relative depth.
Therefore, an absolute water depth that may be considered "deep", i.e. larger than 0.5*λ, for some wave with a wavelength λ of ~1m, could easily count as "shallow", 
i.e. smaller than 0.05*λ, for, let's say, a tsunami wavefront.


abridged sources as a quick reference:

[1] - "Rapid, Stable Fluid Dynamics for Computer Graphics"
[2] - "Interactive Water Surfaces"
[3] - "Nonlocal diffusion and applications"
[4] - "Simulating Ocean Water"
[5] - "eWave: Using an Exponential Solver on the iWave Problem"


▬▬▬ 1.Basics and shallow water ▬▬▬
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 
A straightforward way to simulate an interactable water surface is to numerically solve the wave equation on a deformed height field [1]. The wave equation reads as follows:
( https://en.wikipedia.org/wiki/Wave_equation )

 ░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ░                         ░
   ∂²                      
   ―― h(x,y) = c ∇²h(x,y),   (Equation 1.1)
   ∂t²                     
 ░                         ░
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░
 
where
t is time,
h(x, y) is the water height at the coordiantes (x,y),
c is a constant, and
∇² is the spatial Laplace operator (sum of the second order partial derivatives, i.e. ∇²h(x, y) = ∂²h(x,y)/∂x² + ∂²h(x,y)/∂y²).

This equation tells us that the second derivative of the height field with respect to time (i.e. its vertical accelertion) is directly propotional to its Laplacian.

In [1] the authors show that the wave equation can indeed provide a reasonable approximation for shallow water if we set 

 ░░░░░░░░░░░░
 ░          ░
   c = g*D,   (Equation 1.2)
 ░          ░
 ░░░░░░░░░░░░
 
where 
g is the acceleration due to gravity and 
D is the water depth (D>0).

A minimalist implementation of a grid based simulation based on equation 1.1 can be broken down into two steps:
a. Compute the vertical acceleration of the height field using a discrete Laplace operator.
b. Update the value of the height field based on its vertical acceleration.


▬▬▬ Computing the Laplacian and the vertical acceleration ▬▬▬

On a regular grid the discrete Laplacian can be computed using one of the ubiquitous 3x3 Laplace kernels (see en.wikipedia.org/wiki/Discrete_Laplace_operator).
Unfortunately, their quality is insufficient for our use case and does not result in a reasonable behaviour when plugged into the simulation.
We can, however, quite easily build kernels of good quality by windowing the infinite impulse response (IIR) filter we get from computing the Laplacian of the 2d sinc filter:

 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ░                                                                       ░
                 ∂²             ∂²
   ∇²sinc(x,y) = ―― sinc(x,y) + ―― sinc(x,y)                                // the continuous IIR filter
                 ∂x²            ∂y²
                 
   wnd(x) = max(0, 1-x²)²                                                   // the windowing function (falls off to 0 at x = 1)
   
                 ∂²
   _lapKern[x] = ―― sinc(x) * wnd(x/(radius+1))                             // the unnormalized discrete FIR kernel in 1d (x ∈ int && |x| <= radius)
                 ∂x²                                                        // square brackets are used to denote that only integer arguments are allowed
   
   lapKern[x] = x!=0 ? _lapKern[x] : _lapKern[0] - sum_all_tabs(_lapKern)   // the re-normalized 1d kernel, i.e. sum_all_tabs(lapKern) == 0
   
   lapKern[x,y] = s*(lapKern[x] + lapKern[y])                               // the final 2d kernel; 
 ░                                                                        ░ // s is a constant that scales lapKern's frequency response so as to better match that of ∇²sinc
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░


As we can see, the resulting 2d filter is the sum of two 1d filters that compute the second order partial derivatives in the x and y directions, respectively.
As a result the number of tabs scales linearly with the filter radius making it feasible to use filters with relatively wide footprints.
However, a filter with radius=4 already produces good results:

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  
 ▒                                                                              ▒
   float lapKern[5] = float[5](3.14, -1.848826, 0.353877, -0.091300, 0.016249);   // the associated 2d filter has 18 tabs = (radius*2+1) + (radius*2+1)
 ▒                                                                              ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  
 
Note that we work with a negated Laplacian kernel here, i.e. s < 0. The reasons for doing so is that it will later help to streamline the generalization of the operator.
A consequence of negating the kernel is that we need to alter equation 1.2 slightly: 

 ▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒           ▒
   c = -g*D.   (equation 1.2b)
 ▒           ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒
 
We can now compute the vertical acceleration A at a given grid vertex with coordinates (x,y) as

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                                 ▒
   A[x,y] = -g*D[x,y] * convolve(h[x,y], lapKern).   (equation 1.3)
 ▒                                                 ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒


▬▬▬ Updating the height field ▬▬▬

Given the vertical acceleration we can use a basic Verlet integrator to update our height field:
( https://en.wikipedia.org/wiki/Verlet_integration#Verlet_integration_(without_velocities) )

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                                 ▒
   h₀[x,y] = (2*h₋₁[x,y] - h₋₂[x,y]) + A[x,y]*Δt²,   (equation 1.4)
 ▒                                                 ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

where
h₀  is the height field state after the current time step,
h₋₁ is the previous height field state,
h₋₂ is the height field state preceding h₋₁,
A   is the vertical acceleration at the previous time step, and
Δt  is the duration of the time step (assumed to be constant).

The derivation shown on Wikipedia uses finite differences. 
A different approach to derive equation 1.4 is to perform a quadratic extrapolation using h₋₁, A, and h₋₂ to determine the parameters of the curve:
   
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░                                             ░
   quadratic(t) = a + b*t + c*t²,
   
                    ∂² 
   quadratic''(t) = ―― quadratic(t) = 2c
                    ∂t²
                     
   solve
       h₋₁ = quadratic  (-1*Δt)
       A   = quadratic''(-1*Δt)
       h₋₂ = quadratic  (-2*Δt)
   for a, b, and c.
   
   h₀ = quadratic(0) = (2*h₋₁ - h₋₂) + A*Δt² □ 
 ░                                             ░
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 
At this point we have all we need to build a simple simulation for shallow water.

The approach outlined so far is very similar to the one described in [2].
One difference is that [2] adds a friction parameter α to the integration scheme resulting in the following expression:

 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ░                                                ░
            1            
   h₀ = ―――――――――― ((2 + α Δt)*h₋₁ - h₋₂ + A*Δt²).  (equation 1.5)
         1 + α Δt
 ░                                                ░
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

The addition of friction helps to smooth out some of the high frequency noise that the Laplacian kernel produces.
A similarly, if not even more, effective approach in that regard is to apply a subtle exponential smoothing to the height field state buffer:
( https://en.wikipedia.org/wiki/Exponential_smoothing )

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                           ▒
   h₀'  = h₋₁*(1-w) + h₀ *w,   (equation 1.6)
   h₋₁' = h₋₂*(1-w) + h₋₁*w,
 ▒                           ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 
where w = 1 - exp(-Δt*β) with β >= 0 being a damping constant.

However, both approaches do not substantially improve the stability of the explicit integration scheme. 
Even just extending the integrator to support variable time steps can lead to the simulation becoming increasingly unstable over time.
These instabilities can manifest themselves for instance in the form of coherent wavefronts dispersing into multiple ones, additional wavefronts 
being spawned that travel in wrong directions, or, in the worst case, the whole simulation blowing up and corrupting the entire state buffer in a heartbeat.
Stable solvers for partial differential equations do of course exist (see [5] for one example specifically tailored to the problem at hand), 
but they generally come at the cost of a lot of additional complexity.


The most substantial aspect in which the approach presented in [2] differs from the one described so far is the choice of the convolution kernel.
The reason for that is that [2] attempts to simulate deep instead of shallow water. In deep water the wavelength-to-speed relation is quite different. 
To account for that [2] proposes to use a kernel that implements the half-Laplacian [3] instead of the common Laplacian.
The reasoning behind that choice is detailed in the following section.



▬▬▬ 2.Intermediate depths and deep water ▬▬▬
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

The velocity of water waves depends on a variety of factors like their wavelengths, gravity, surface tension, and water depth.
For waves that are large enough that the effects of surface tension are negligible, i.e. so called surface gravity waves, 
this dependency can be described by the following dispersion relation
( https://en.wikipedia.org/wiki/Dispersion_(water_waves) )

 ░░░░░░░░░░░░░░░░░░░░░░░
 ░                     ░
   ω² = g*k*tanh(k*D),   (equation 2.1)
 ░                     ░
 ░░░░░░░░░░░░░░░░░░░░░░░

where
ω is the angular velocity of the wave,
g is the acceleration due to gravity,
k is the wavenumber (k = 2π/λ; λ being the wavelength),
D is the water depth (D>0), and
tanh is the hyperbolic tangent (tanh(x) = 2/(1 + exp(-2x)) - 1), which is a sigmoid curve ranging from -1 to 1 on the interval (-inf, +inf).

In shallow water, i.e. when D < 0.05*λ, equation 2.1 reduces to

 ░░░░░░░░░░░░░░░░
 ░              ░
   ω² ≈ g*D*k².   (equation 2.2)
 ░              ░
 ░░░░░░░░░░░░░░░░

In deep water, i.e. when D > 0.5*λ, we get

 ░░░░░░░░░░░░░░░
 ░             ░
   ω² ≈ g*|k|.   (equation 2.3)
 ░             ░
 ░░░░░░░░░░░░░░░
 

In an effort to generalize the shallow water model from the previous chapter let us first consider how the dispersion relation 
can be used to relate the vertical acceleration of an individual sine wave to its function value:

        wave(x,t) =     s*sin(k*x - ω*t), (Equation 2.4a)
 
     ∂²
 A = ―― wave(x,t) = -ω²*s*sin(k*x - ω*t), (equation 2.4b)
     ∂t²
 
              ░░░░░░░░░░░░░░░░░░░░░░
              ░                    ░
  it follows    A = -ω²*wave(x,t).        (equation 2.5)
              ░                    ░
              ░░░░░░░░░░░░░░░░░░░░░░
 
where
s is the amplitude,
k is the wavenumber (k = 2π/λ),
ω is the angular velocity,
t is time, and
A is the vertical acceleration.

Let us now consider the height field that represents our water surface as a superposition, i.e. a sum, of an arbitrary number of sine waves.
For the purpose of computing the vertical acceleration of that height field we simply apply equation 2.5 to each of those sine waves individually.
Proceeding in this manner is justified by linearity and can be formally expressed via the Fourier transform as
( https://en.wikipedia.org/wiki/Fourier_transform )

 ░░░░░░░░░░░░░░░░░░░░
 ░                  ░
   A = ℱ⁻¹(-ω²*ℱh),   (equation 2.6)
 ░                  ░
 ░░░░░░░░░░░░░░░░░░░░
 
where
 ℱ⁻¹ is the inverse Fourier transform,
 ℱ   is the forward Fourier transform, and
 h   is the height field representing the water surface.

While equation 2.6 may look complicated, its practical implications are actually rather tame.
To compute A in our shallow water model we use a convolution kernel that approximates a negative Laplacian (remember that we flipped the sign of the operator (see Equation 1.2b)).
The frequency response of the (negative) Laplacian is a radially symmetric, bi-variate paraboloid:

 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ░                                         ░
   -∇²h(x,y) = ℱ⁻¹((kᵪ²+kᵧ²)*(ℱh)(kᵪ,kᵧ)).   (equation 2.7)
 ░                                         ░
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 
In the generalized model we simply replace this filter with one that has a frequency response that is equal to equation 2.1, i.e. the more general version of dispersion relation.
It is straightforward to show that inserting the shallow water dispersion relation, i.e. equation 2.2, into equation 2.6 gives us a result that is consistent with our work so far:
 
 A = ℱ⁻¹(-(g*D*k²)*ℱh) 
 
   = g*D*ℱ⁻¹(-k²*ℱh)  // g and D do not depend on the wavenumber so they can be moved out of the inverse Fourier transform
            
   = g*D*∇²h
   
   =-g*D*(-∇²)h. 
            
Doing the same but with the deep water dispersion relation gives us:

 A = ℱ⁻¹(-(g*|k|)*ℱh) 
 
   = -g*ℱ⁻¹(|k|*ℱh) 
             ______   
   = -g*ℱ⁻¹(√-(-k²)*ℱh) 
         ___
   = -g*√-∇²h. 
                                                          ___
The square root of the Laplacian, or half-Laplacian [3], √-∇² does, at least for our purposes, nothing more than denote an operator that when applied to
a function convolves it with a linear filter that has a frequency response equal to |k| (in contrast to the frequency resonse of the negative Laplacian, which is k²).
(The half-Laplacian is a special case of the fractional Laplacian [3], for which it is convention to defined it based on the negative Laplacian: (-∇²)ˢ with s ∈ (0,1).)
The frequency response of the half-Laplacian in 2d is a radially symmetric, bi-variate (upside down) cone:

 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ░  ___               _______              ░
   √-∇²h(x,y) = ℱ⁻¹(√kᵪ²+kᵧ²*(ℱh)(kᵪ,kᵧ)).   (equation 2.8)
 ░                                         ░
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 
Likewise, we can define the operator based on equation 2.1 as [3]

 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ░  ___      ___                  _______       _______                 ░
   √-∇²tanh(√-∇²*D)h(x,y) = ℱ⁻¹(√kᵪ²+kᵧ²*tanh(√kᵪ²+kᵧ²*D)*(ℱh)(kᵪ,kᵧ)).   (equation 2.9)
 ░                                                                      ░
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 
Putting it all together the ground-truth version of our generalized model computes the vertical acceleration of the height field as [4]

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒           ___      ___          ▒
   A = -g * √-∇²tanh(√-∇²*D)h(x,y)   (equation 2.10)
 ▒                                 ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 
 
What complicates implementing equation 2.10 is the dependency of the filter kernel on the water depth D.
For the shallow water model this dependency reduced to a vertical scaling by D.
But in the general case the way the shape of the kernel changes with D is less straightforward.
Basically, the shape of the frequency response of the kernel at intermediate depths is a cone with a bulge instead of a sharp tip at its center.
How large this bulge is depends on D. For shallow water this bulge grows so large that it covers all relevant frequency ranges and can be approximated by a paraboloid scaled by D.
For deep water, on the other hand, it shrinks so much that we can simply omit it and assume the spectrum to be a perfect cone with a sharp apex.

[4] proposes to pre-compute a whole array of filter kernels for different values of D and than interpolate between them at runtime based on the local water depth.
However, no reasonably sized FIR filter kernel can faithfully reproduce the desired asymptotic frequency response for deep water, i.e. |k|.
The reason for that is that windowing the IIR filter blurs out its frequency response.
This effect is quite prominent around the DC, i.e. at k=0, where the spectrum has a C¹ discontinuity (the apex of the cone shape).
As a consequence a kernel of practical size typically resembles the ground-truth at D~1 more so than it does for the originally intended D->∞.

Alternatively, we could implement equation 2.9 directly using fast Fourier transforms (FFTs). This would get us an accurate frequency response but at the cost of performance.
Other downsides of this approach would be a substantial increase in implementation complexity and reduced flexibility.
This is because when using FFTs we would need to simulate the entire grid at each time step while using spatial FIR kernels allows us to selectively 
compute A where it is required (after all, large parts of the grid might be masked out due to geomtry replacing the water in these regions).

Therefore, we will stick to the spatial FIR filter based implementation approach here and simply accept that as a consequence we are not able to accurately handle D>1.

In an attempt to support variable water depths with minimal effort we simply interpolate between a shallow and a deep water kernel.
The shallow water kernel is already given by the discrete Laplacian filter described in section 1.
In order to complete the picture we still need a discrete FIR kernel for deep water and
a blending scheme that combines the two kernels in a way that results in a sensible approximation of equation 2.10.


▬▬▬ Deep water dispersion kernels ▬▬▬

Similar to the shallow water kernel, the shape of the deep water kernel in frequency space is not particularly complex.
However, the additional square root operation that turns the paraboloid into a cone does complicate the computation of the spatial kernel shape considerably [3].
Luckily in our case the computation of the kernel is not performance critical so we can brute force the problem numerically by 
peforming an approximate inverse Fourier transform of the brick-wall filtered half-Laplacian to determine the tab weights of the discrete filter.
The resulting weights are windowed using max(0, 1-(x²+y²))², which is just a radially symmetric variant of the window we used in section 1.
Lastly the windowed kernel is renormalized and empricially scaled to match the ground-truth reference.
As discussed before no reasonably large FIR filter can actually approximate the half-Laplacian, i.e. asymptotic deep water kernel, well.
Therefore we use the general model with D=1 as the reference that we try to match when scaling the kernel.
By not already using the general model with D=1 for the computation of the original tab weights we end up with a
compromise between the kernel we would ideally like to approximate and the one that we can actually still decently replicate in practice.

Computing a 5x5 and a 15x15 kernel with this approach results in the following weights (one quadrant):

 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ░                                                                ░  
   float hLapKern[9] = float[9]( 2.25    , -0.509315,  0.023306, 
                                -0.509315, -0.070842, -0.002754,    (kern5x5)
                                 0.023306, -0.002754, -0.000141);
 ░                                                                ░  
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
        
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░      
 ░                                                                                                                         ░
   float hLapKern[64] = float[64]( 2.32    , -0.472083,  0.050161, -0.030779,  0.009510, -0.005206,  0.001515, -0.000381, 
                                  -0.472083, -0.083063, -0.008956, -0.005801, -0.000604, -0.000797, -0.000027, -0.000047,  
                                   0.050161, -0.008956, -0.006594, -0.002202, -0.001030, -0.000306, -0.000111, -0.000012, 
                                  -0.030779, -0.005801, -0.002202, -0.001290, -0.000496, -0.000210, -0.000049, -0.000004,    (kern15x15)
                                   0.009511, -0.000604, -0.001030, -0.000496, -0.000259, -0.000084, -0.000018,  0.      , 
                                  -0.005206, -0.000797, -0.000306, -0.000210, -0.000084, -0.000025, -0.000001,  0.      , 
                                   0.001515, -0.000027, -0.000111, -0.000049, -0.000018, -0.000001,  0.      ,  0.      , 
                                  -0.000381, -0.000047, -0.000012, -0.000004,  0.      ,  0.      ,  0.      ,  0.      );        
 ░                                                                                                                         ░
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░


When comparing the simulation behaviors resulting from these two kernels it becomes clear that kern5x5 provides only a poor approximation of kern15x15.
And that while, judging from its frequency response, even Kernel15x15 itself is only a decent approximation for D=1. 
The two takeaways here are that on the one hand using a compact kernel we can not expect to get much more out of it than a rough scetch of the wave behavior in deep water.
And on the other hand, if we do aim to achieve even just a decent approximation of the ground-truth behavior at reasonable 
computational costs we need a more efficient way to compute the half-Laplacian.


--- Compact deep water kernels ---

Considering our modest expectations regarding the simulation quality achieveable by small kernels like kern5x5 
it seems worth exploring how far further we can reduce the number of used filter tabs without sacrificing even more quality.

The two important optimization criteria we need to balance here are the isotropy of the spectral response and 
its shape in the upper frequency range (the lower range is a lost case for small kernels anyway).
The construction approach outlined in the following attempts to streamline this balancing act.

First, we construct a high-pass filter kernel with optimized radial symmetry in frequency space (by optimizing the tab weights explicitly via least squares). 
Its frequency response will be naturally bell curve shaped (since FIR filters tend towards a shoulder/toe when approaching Nyquist).
We then blend this kernel with a discrete Laplacian, which has a paraboloid shaped frequency response, to match the reference spectrum as well as possible.
Since both kernels individually already feature decently isotropic spectra any kernel resulting from a weighted sum of the two does as well.

A possible result using a 13 taps kernel with a diamond shaped footprint has the following weights (one quadrant; including 0-weights):

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                                                ▒
   float hLapKern[9] = float[9]( 2.093378, -0.329871, -0.026409,
                                -0.329871, -0.167064,  0.      ,    (kern13)
                                -0.026409,  0.      ,  0.      ); 
 ▒                                                                ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 
The choice to use a diamond shaped footprint is motivated by the fact that by using a 3x3 footprint we can already construct a reasonably isotropic spectrum 
for the high-pass kernel while the quality of the blended in Laplace kernel benefits from a slightly larger radius. 
Adding another 8 tabs in the main directions so an even wider Laplace kernel can be used results in the following 21 tabs kernel (one quadrant; including 0-weights):   

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                                                                      ▒
   float hLapKern[25] = float[25]( 2.269921, -0.450589, 0.017898, -0.010277, 0.003477, 
                                  -0.450589, -0.127990, 0.      ,  0.      , 0.      , 
                                   0.017898,  0.      , 0.      ,  0.      , 0.      ,    (kern21)
                                  -0.010277,  0.      , 0.      ,  0.      , 0.      , 
                                   0.003477,  0.      , 0.      ,  0.      , 0.      );     
 ▒                                                                                      ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

The difference in quality between kern13 and kern21 becomes only really noticeable once we end up dynamically 
fading out the high-pass kernel contribution in shallow water (see the "Blending shallow and deep water kernels" section).


--- A high quality deep water kernel ---

The idea of blending multiple kernels together can also be used to construct a (comparatively) high quality half-Laplacian kernel with a wider footprint.
We achieve this by replacing the single compact high-pass kernel used previously with two larger separable kernels.
Having, in addition to the discrete Laplacian, two instead of just one high-pass filtering results available gives us 
another degree of freedom for optimizing the spectral response of the filter.
The disantvantage of this approach over the compact kernels described previously is that in order to be efficient we need to perform the convolution in two passes.
Doing so increases implementation complexity as well as causing a not insignificant performance overhead due to the necessary round trip through global memory.
The following kernels and pseudo code demonstrate a possible implementation of this idea:

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                                                                                                                               ▒
   float lowKern3[4] = float[4](5.0/16.0, 15.0/64.0, 3.0/32.0, 1.0/64.0);   
    
   float lowKern7[8] = float[8](429.0/2048.0, 3003.0/16384.0, 1001.0/8192.0, 1001.0/16384.0, 91.0/4096.0, 91.0/16384.0, 7.0/8192.0, 1.0/16384.0);   
    
   float lapKern7[8] = float[8](3.22, -1.933599, 0.438458, -0.163745, 0.070153, -0.02964, 0.01061, -0.002237);   
 ▒                                                                                                                                               ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                                           ▒
   h' = (convolveX(h₋₁, lowKern3), 
         convolveX(h₋₁, lowKern7), 
                   h₋₁           , 
         convolveX(h₋₁, lapKern7))
   
   lowpass3  = convolveY(h'.x, lowKern3)
   lowpass7  = convolveY(h'.y, lowKern7)
   laplacian = convolveY(h'.z, lapKern7) + h'.w
   
   highpass = h'.z - lerp(lowpass3, lowpass7 , 0.772)
   halfLaplacian =   lerp(highpass, laplacian, 0.190)*1.255;    (kernHQ)
   
   A = -g * halfLaplacian
 ▒                                                           ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  

(An isolated implementation of this pseudo code can be found here: https://www.shadertoy.com/view/wtGyzK (also shows a plot of the spectral response of the kernel).)

The resulting kernel kernHQ is a reasonable approximation for the ground-truth kernel at D=2. 
This means that we, in addition to performance, also improved the quality of the simulation when compared to the results achieved with kern15x15.

Looking at the simulation results we can see that, in comparison to the compact kernels, the high quality kernel produces a less stiff wave propagation behavior   
due to the increased relative speed of the lower frequency waves. That behavior can, however, become somewhat less apparent the more chaotic the wave field becomes.

(Side note: the deep water kernel proposed in [2] is the half-Laplacian of a Gaussian (which is not explicitly stated in the article). 
I managed to derive the analytical form from the numerical one presented there, but failed (in multiple attempts) to achieve useful results using that kernel. 
Using the half-Laplacian of a Gaussian instead of a sinc function leads to incorrect dispersion behavior in the high ends. 
For example, in the case of a water drop hitting a flat surface this leads to high frequency oscillations being emitted from the point of impact for a long time.
I suspect that the author might have compensated this erroneous behavior by additionally damping the integration.)


▬▬▬ Blending shallow and deep water dispersion kernels ▬▬▬

With a shallow and a deep water kernel at hand we can now dynamically blend between the two in an attempt to approximate the wave propagation behavior at intermediate depths.
The reference operator we try to match is the one based on the intermediate depth dispersion relation for surface gravity waves (equations 2.1 and 2.10):

 shallow (D < 0.05*λ)               intermediate                   deep (D > 0.5*λ)
 ░░░░░░░░░░░░░░░░░░░░░     ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒      ░░░░░░░░░░░░░░░░░░░░░
 ░                   ░     ▒           ___      ___      ▒      ░             ___   ░
   A = -g * D*(-∇²)h  🠈🠊   A = -g * √-∇²tanh(√-∇²*D)h    🠈🠊    A = -g * (√-∇²)h 
 ░                   ░     ▒                             ▒      ░                   ░
 ░░░░░░░░░░░░░░░░░░░░░     ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒      ░░░░░░░░░░░░░░░░░░░░░
 
For now let us assume that if D>1 using the deep water kernel without further modifications is already optimal. This means we concern ourselfs only with the interval D ∈ [0,1].
Under this assumption a reasonable choice for a straightforward blending approach is:

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                            ▒
   kern = (shallowKern*(1-w) + deepKern*w)*D,   (equation 2.11)
 ▒                                            ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 
with w = ξ(D), where ξ(D) is a transfer function that optimizes the blending behaviour.

A good approximation to a possible least-squares optimization result for this transfer function is

 ░░░░░░░░░░░░░░░░░░░░
 ░                  ░
            13 D²
   ξ(D) = ――――――――.   (equation 2.12)
          4 + 9 D²
 ░                  ░
 ░░░░░░░░░░░░░░░░░░░░
 
The way the kernel stops morphing as D approaches 1 can be a bit abrupt, though.       
To mitigate this we can slightly dampen the blending behavior by adapting the coefficients as follows

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                  ▒
            7 D²
   ξ(D) = ――――――――.   (equation 2.13)
          2 + 5 D²
 ▒                  ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 
If we chose to use the high quality deep water kernel we need account for the fact that kernHQ approximates D=2 instead of D=1 (as was our initial assumption here).
It is however relatively straightforward to do so by only slightly modifying how the highpass filtering contribution is computed:
 
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                                                       ▒
   highpass = h'.z - lerp(lowpass3, lowpass7, 0.772*D2),
 ▒                                                       ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 
where D2 = min(max(0, D-1), 1) (i.e. we linearly blend in the lowpass7 contribution as D approaches 2 after passing 1).

An animated spectrum plot of the resulting kernel can be found here: https://www.shadertoy.com/view/WtcfzN (also allows to plot kern13).

One complication with equation 2.11 is that scaling the vertical acceleration by D leads to erroneous simulation 
behavior along shorelines (shorelines emitting high frequency waves) if the features of the obstacle height map are not aligned with the main axes of the grid. 
Oversampling the [0,1]-clamped D value does help, but not substantially.
Oversampling the whole simulation step using high quality reconstructions when sampling both the water state buffer as well as the obstacle height field would likely
resolve the issue, but is impractical in many cases. An easy and effective way to mitigate the problem is to linearly remap D so it does not completely fall off to 0:

 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ▒                   ▒
   D' = D*(1-σ) + σ,   (equation 2.14)
 ▒                   ▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ 
 
where σ is a remapping constant.
 
Doing so sacrifices simulation accuracy while still retaining the non-linear character of the overall behavior.


▬▬▬ 3.Rendering ▬▬▬
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

There are two primary issues we face when it comes to rendering the water surface. First our height field likely contains a significant amount of 
high frequency noise caused by the contributions of the Laplacian kernels (even by those baked into the deep water kernels).
And second, we need an efficient way to compute high quality normals since the shading of water is typically characterized by specular reflections
of which the quality is quite susceptible to C2 discontinuities and, especially inconvenient for us, to high frequency noise.

Fortunately both of those concerns can be accounted for by performing a C2 continuous bicubic reconstruction using an aggressive filter during the pre-filtering pass.
A demo of the technique can be found here: www.shadertoy.com/view/WtsBDH ("Bicubic C2 cont. Interpolation").
And the derivation is documented here:     www.shadertoy.com/view/3tfBzX ("Cubic Reconstruction").

What this approach boils down to is that in a pre-filtering pass we reconstruct the height field exactly at its vertices using a C2 continuous bicubic filter kernel
to evaluate the function value plus a number of partial derivatives of the filter-associated continuous height field.
By storing the filtered derivatives alongside the filtered value we are able to efficiently evaluate the continuous height field
using only the data stored at the vertices of the local 2x2 neighborhood of any given evaluation point.
Different to the demo linked above we don't use the interpolating kernel here but a generalization of the bicubic B-spline that uses 
additional side lobes (resulting in a 5x5 kernel). We set the side lobes weight so that the frequency response of the filter falls off to 0 at the Nyquist frequency.
This filters out virtually all of the noisy frequency content and does so in a highly radially symmetric fashion.


▬▬▬ 4.Conclusion ▬▬▬
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

Implementing a height field based water simulation is comparatively straightforward. 
However, the choice of the dispersion kernel used to compute the vertical acceleration of the height field can be surprisingly nuanced.
Here we proposed a number of shallow and deep water dispersion kernels that offer different performance-quality tradeoffs.
In addition, we presented a novel approach that locally performs a water depth dependent blending between a given shallow and a deep water kernel.
Finally, we showed how the rendering of the resulting height field can benefit from using a C2 continuous reconstruction and how to implemented it efficiently.

An interesting extention to the algorithm at hand would be a phase shift filter that computes the horizontal offsets necessary for turning the sinusoidal wave field
into one that is composed of Gerstner waves. [4] shows how to do just that using FFTs. However, an implementation based on spatial FIR filters might be more practical.


▬▬▬ Sources ▬▬▬
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 
[1] - Kass, Michael, and Gavin Miller. "Rapid, stable fluid dynamics for computer graphics." 
      Proceedings of the 17th annual conference on Computer graphics and interactive techniques. 1990.
      pdf: https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.89.1204&rep=rep1&type=pdf

[2] - Jerry Tessendorf, “Interactive Water Surfaces,” 
      Game Programming Gems 4 , ed. Andrew Kirmse, Charles River Media, (2004).
      pdf: http://people.clemson.edu/~jtessen/papers_files/Interactive_Water_Surfaces.pdf
      
[3] - Bucur, Claudia, and Enrico Valdinoci. "Nonlocal diffusion and applications." 
      Vol. 20. Cham: Springer, 2016.
      pdf: https://www.researchgate.net/publication/275669247_Nonlocal_Diffusion_and_Applications

[4] - Tessendorf, Jerry. "Simulating ocean water." 
      Simulating nature: realistic and interactive techniques. SIGGRAPH 1.2 (2001): 5.
      pdf: https://www.researchgate.net/publication/264839743_Simulating_Ocean_Water
      
[5] - Tessendorf, Jerry. "eWave: Using an Exponential Solver on the iWave Problem." 
      Technical Note (2014).      
      pdf: https://people.cs.clemson.edu/~jtessen/reports/papers_files/ewavealgorithm.pdf
      
      
      
Related:

  Simulation
- https://www.shadertoy.com/view/wtGyzK | "half-Laplacian"                     (plot of the half-Laplacian kernel)
- https://www.shadertoy.com/view/WtcfzN | "Gravity Waves Dispersion Kernel"    (plot of the frequency response of the depth dependent dispersion kernel)

  Rendering
- https://www.shadertoy.com/view/3tfBzX | "Cubic Reconstruction"               (derivation of the bicubic reconstruction scheme)
- https://www.shadertoy.com/view/wlsBz2 | "C2-interpolating cubic Kernel"      (plot + background info on the kernel used to compute the derivatives)

*/





// CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
// To the extent possible under law, Mirko Salm has waived all copyrights and related or neighboring rights to this work.

// CUBIC AND BICUBIC RECONSTRUCTION KERNELS ============================================================================================

float kern_v(float x) { return 1.0-x*x*(3.0-2.0*abs(x)); }
float kern_d(float x) { float o = abs(x)-1.0; return x*(o*o); }

float kern_vD1(float x) { return x*(abs(x)*6.0-6.0); }
float kern_dD1(float x) { return (abs(x)-1.0)*(abs(x)*3.0-1.0); }

float kern_vD2(float x) { return abs(x) * 12.0 - 6.0; }
float kern_dD2(float x) { return x * 6.0 + (x > 0.0 ? -4.0 : 4.0); }


vec4 kern(vec2 p)
{
    return vec4(kern_d(p.x) * kern_v(p.y),
                kern_v(p.x) * kern_d(p.y),
                kern_d(p.x) * kern_d(p.y),
                kern_v(p.x) * kern_v(p.y));
}

mat4 kern4x4(vec2 p)
{
    vec2 v   = vec2(kern_v  (p.x), kern_v  (p.y));
    vec2 d   = vec2(kern_d  (p.x), kern_d  (p.y));
    
    vec2 vD1 = vec2(kern_vD1(p.x), kern_vD1(p.y));
    vec2 dD1 = vec2(kern_dD1(p.x), kern_dD1(p.y));
    
    mat4 m = mat4
    (
        /*   kernDx       |  kernDy       |  kernDxy        |  kern    */
        vec4(dD1.x * v.y  ,  d.x * vD1.y  ,  dD1.x * vD1.y  ,  d.x * v.y),
        vec4(vD1.x * d.y  ,  v.x * dD1.y  ,  vD1.x * dD1.y  ,  v.x * d.y),
        vec4(dD1.x * d.y  ,  d.x * dD1.y  ,  dD1.x * dD1.y  ,  d.x * d.y),
        vec4(vD1.x * v.y  ,  v.x * vD1.y  ,  vD1.x * vD1.y  ,  v.x * v.y)
    );
    
    return m;
}

void kern4x4(vec2 p, out mat4 mA, out mat4 mB)
{
    vec2 v   = vec2(kern_v  (p.x), kern_v  (p.y));
    vec2 d   = vec2(kern_d  (p.x), kern_d  (p.y));
    
    vec2 vD1 = vec2(kern_vD1(p.x), kern_vD1(p.y));
    vec2 dD1 = vec2(kern_dD1(p.x), kern_dD1(p.y));
    
    vec2 vD2 = vec2(kern_vD2(p.x), kern_vD2(p.y));
    vec2 dD2 = vec2(kern_dD2(p.x), kern_dD2(p.y));
    
    mA = mat4
    (
        /*   kernDx       |  kernDy       |  kernDxy        |  kern    */
        vec4(dD1.x * v.y  ,  d.x * vD1.y  ,  dD1.x * vD1.y  ,  d.x * v.y),
        vec4(vD1.x * d.y  ,  v.x * dD1.y  ,  vD1.x * dD1.y  ,  v.x * d.y),
        vec4(dD1.x * d.y  ,  d.x * dD1.y  ,  dD1.x * dD1.y  ,  d.x * d.y),
        vec4(vD1.x * v.y  ,  v.x * vD1.y  ,  vD1.x * vD1.y  ,  v.x * v.y)
    );

    mB = mat4
    (
        /*   kernDxx      |  kernDyy      |  kernDxxy       |  kernDxyy    */
        vec4(dD2.x * v.y  ,  d.x * vD2.y  ,  dD2.x * vD1.y  ,  dD1.x * vD2.y),
        vec4(vD2.x * d.y  ,  v.x * dD2.y  ,  vD2.x * dD1.y  ,  vD1.x * dD2.y),
        vec4(dD2.x * d.y  ,  d.x * dD2.y  ,  dD2.x * dD1.y  ,  dD1.x * dD2.y),
        vec4(vD2.x * v.y  ,  v.x * vD2.y  ,  vD2.x * vD1.y  ,  vD1.x * vD2.y)
    );
}


// BICUBIC SAMPLING ROUTINES =============================================================================================================

// this is the most basic version which only evaluates the function value
float SampleBicubic(sampler2D channel, vec2 uv)
{
    uv -= vec2(0.5);
    
    vec2 uvi = floor(uv);
    vec2 uvf = uv - uvi;

    ivec2 uv0 = ivec2(uvi);
    
    float r = 0.0;
    for(int j = 0; j < 2; ++j)
    for(int i = 0; i < 2; ++i)
    {
        vec4 c = texelFetch(channel, uv0 + ivec2(i, j), 0);
        
        vec2 l = uvf;
        
        if(i != 0) l.x -= 1.0;
        if(j != 0) l.y -= 1.0;
        
        r += dot(c, kern(l));
    }
    
	return r;
}

// ... this version also outputs derivatives (used here to compute normals)
vec4 SampleBicubic2(sampler2D channel, vec2 uv)
{
    uv -= vec2(0.5);
    
    vec2 uvi = floor(uv);
    vec2 uvf = uv - uvi;

    ivec2 uv0 = ivec2(uvi);
    
    vec4 r = vec4(0.0);
    for(int j = 0; j < 2; ++j)
    for(int i = 0; i < 2; ++i)
    {
        vec4 c = texelFetch(channel, uv0 + ivec2(i, j), 0);
        
        vec2 l = uvf;
        
        if(i != 0) l.x -= 1.0;
        if(j != 0) l.y -= 1.0;
        
        r += kern4x4(l) * c;
    }
    
    // r = vec4(df/dx, df/dy, ddf/dxy, f)
	return r;
}

// ... this version also outputs higher order derivatives (only used to debug C2 continuity here)
vec4 SampleBicubic3(sampler2D channel, vec2 uv, out vec4 d2)
{
    uv -= vec2(0.5);
    
    vec2 uvi = floor(uv);
    vec2 uvf = uv - uvi;

    ivec2 uv0 = ivec2(uvi);
    
    d2 = vec4(0.0);
    vec4 r = vec4(0.0);
    for(int j = 0; j < 2; ++j)
    for(int i = 0; i < 2; ++i)
    {
        vec4 c = texelFetch(channel, uv0 + ivec2(i, j), 0);
        
        vec2 l = uvf;
        
        if(i != 0) l.x -= 1.0;
        if(j != 0) l.y -= 1.0;
        
        mat4 mA, mB;
        kern4x4(l, /*out*/ mA, mB);
        
        r  += mA * c;
        d2 += mB * c;
    }
    
    // r  = vec4(  df/dx,   df/dy,  ddf/dxy ,         f)
    // d2 = vec4(ddf/dxx, ddf/dyy, dddf/dxxy, dddf/dxyy)
	return r;
}


// IMAGE ==========================================================================================================================

float ReadKey(int keyCode) {return texelFetch(iChannel2, ivec2(keyCode, 0), 0).x;}
float ReadKeyToggle(int keyCode) {return texelFetch(iChannel2, ivec2(keyCode, 2), 0).x;}

void mainImage( out vec4 fragColor, in vec2 uv0 )
{    
    #if 0
    fragColor = texelFetch(iChannel1, ivec2(uv0-0.5), 0);
    return;
    #endif

    bool isTerrainAnimated = ReadKeyToggle(KEY_N1) == 0.0;

   #if 1
    // mini map
    bool doShowWaveField = ReadKeyToggle(KEY_N3) != 0.0;
   
    if(doShowWaveField)
    if(uv0.x < GridSize && uv0.y < GridSize)
    {
        vec3 col = vec3(1.0) - normalize(vec3(texelFetch(iChannel0, ivec2(uv0 - 0.5), 0).xy, .01)).z;
        
        float d = EvalTerrainHeight(uv0, isTerrainAnimated ? iTime : 0.0);
        
        bool doShowHeightField = ReadKeyToggle(KEY_N4) != 0.0;
        if(doShowHeightField) col = (texelFetch(iChannel0, ivec2(uv0 - 0.5), 0).www * 1.0 + 0.5);
        
        col *= col;

        float l = -min(d, 0.0)*3.;
        col = mix(vec3(0.125, 0.125, 1.0 ), col, 1.0-(exp2(-(l*2.0 + l*l*1.0))));
        col = mix(col, vec3(1.0  , 0.0  , 0.25), smoothstep(-0.05, 0.0, d));

        bool isGridWindowSharp = ReadKeyToggle(KEY_N2) != 0.0;
        if(isGridWindowSharp && (uv0.x == 0.5 || uv0.y == 0.5 || uv0.x == GridSize-0.5 || uv0.y == GridSize-0.5)) col = vec3(0.0, 1.0, 1.0); 

        fragColor = vec4(sqrt(clamp01(col.rgb)), 0.0);
        return;
    }
   #endif
 
    vec3 col;
    
    vec2 uv = uv0;
    vec2 tc = uv0 / iResolution.xx;
    
   #if 0
    if(uv0.x >= iResolution.x*0.5)
    uv.x -= iResolution.x*0.5;
   #endif
    
    col = vec3(texture(iChannel0, uv0/iResolution.xy*0.125).r);
    
    
    vec2 uv2 = PatchUVfromScreenUV(uv0.xy, iResolution.xy);

    float time = isTerrainAnimated ? iTime : 0.0;

    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 L = normalize(vec3(1.0, 1.0, 1.0));
    vec3 L2 = normalize(vec3(-1.0, -1.0, 2.0));
    vec3 H = normalize(L + V);


    vec3 terrN;
    {
        float s = 1.0/128.0;
        
        float hx0 = EvalTerrainHeight(uv2 - vec2(s, 0.0), time);
        float hx1 = EvalTerrainHeight(uv2 + vec2(s, 0.0), time);
        float hy0 = EvalTerrainHeight(uv2 - vec2(0.0, s), time);
        float hy1 = EvalTerrainHeight(uv2 + vec2(0.0, s), time);
        
        vec2 dxy = vec2(hx1 - hx0, hy1 - hy0) / (2.0 * s);
        
        terrN = normalize(vec3(-dxy, 0.03));
    }
    
    vec3 terrCol = clamp01(dot(terrN, L))*(1.0/(1.0+1.0*(1.0-clamp01(dot(terrN, H)))))*vec3(1.0)*0.05;


    vec4 d2;
    vec4 h = SampleBicubic3(iChannel0, uv2, d2);// sample water surface
    
    float nscale = 32.0;
    vec3 N = normalize(vec3(-h.xy * nscale, 1.0));
    
    vec3 R = 2.0*dot(V, N)*N - V;

    float ct = clamp01(dot(N, L));
    float ct2 = dot(N, L) * 0.5 + 0.5;
    
    float d = h.w - EvalTerrainHeight(uv2-N.xy*4.0, time);
    
    float waterMask = smoothstep(-0.01, 0.01, d);
    
    // diffuse
    float v =  clamp01(ct2+0.15);
    v = 1.0-v;
    v = cubic(v);
    
    col = exp(-(v * 12.0 + 5.) * vec3(0.05, 0.3, 1.))*1.4;
    //col *= mix(0.25, 1.0, clamp01(dot(terrN, L)+0.5));

    float l = max(0.0, d);
    col = mix(terrCol, col, (1.0-exp2(-(l*2.0 + l*l*1.0))));
    col += vec3(0.0, 0.25, 1.0)*0.1;
    
    // specular
    float c = 1.0 - (dot(R, L)*0.5+0.5);
    float c2 = 1.0 - (dot(R, L2)*0.5+0.5);
    float spec = 0.0;
    spec += smoothstep(0.9, 0.99, dot(R, L))*0.5; 
    float spec0 = spec;
    spec += smoothstep(0.7, 0.9, dot(R, L))*0.125; 
    spec += smoothstep(0.8, 0.9, dot(R, L2))*0.02; 
    spec += smoothstep(0.95, 0.99, N.z)*0.02; 
    spec += exp2(-32.0*(c))*0.25;
    
    col += vec3(1.0) * spec * waterMask;
    
    col = GammaEncode(clamp01(col));
    
    fragColor = vec4(col, 0.0);
}

























