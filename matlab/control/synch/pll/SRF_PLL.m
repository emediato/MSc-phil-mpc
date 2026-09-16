function [theta_hat,omega_hat,ed,eq] = ...
    SRF_PLL(e_alpha,e_beta,Ts)

persistent theta omega
persistent integral_eq

if isempty(theta)

    theta       = 0;
    omega       = 0;
    integral_eq = 0;

end

%% PLL Gains

Kp = 100;
Ki = 5000;

%% Park Transform

ed =  cos(theta)*e_alpha + sin(theta)*e_beta;

eq = -sin(theta)*e_alpha + cos(theta)*e_beta;

%% PI Controller

integral_eq = integral_eq + Ki*eq*Ts;

omega = Kp*eq + integral_eq;

%% Integrator (VCO)

theta = theta + omega*Ts;

%% Wrap Angle

theta = mod(theta,2*pi);

%% Outputs

theta_hat = theta;
omega_hat = omega;

end
