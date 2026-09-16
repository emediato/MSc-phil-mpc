function [e_alpha,e_beta] = BackEMFObserver( ...
            v_alpha,v_beta,...
            i_alpha,i_beta,...
            Rs,Ls,Ts)

persistent ialpha_old ibeta_old
persistent ealpha_f ebeta_f

if isempty(ialpha_old)

    ialpha_old = 0;
    ibeta_old  = 0;

    ealpha_f   = 0;
    ebeta_f    = 0;

end

dia = (i_alpha - ialpha_old)/Ts;
dib = (i_beta  - ibeta_old )/Ts;

e_alpha_raw = v_alpha - Rs*i_alpha - Ls*dia;
e_beta_raw  = v_beta  - Rs*i_beta  - Ls*dib;

fc = 300;

w = 2*pi*fc;

a = Ts*w/(1+Ts*w);

ealpha_f = ealpha_f + a*(e_alpha_raw-ealpha_f);
ebeta_f  = ebeta_f  + a*(e_beta_raw -ebeta_f);

e_alpha = ealpha_f;
e_beta  = ebeta_f;

ialpha_old = i_alpha;
ibeta_old  = i_beta;

end
