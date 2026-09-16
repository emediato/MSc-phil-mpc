function Vabc= Inv_Park_Clarke_Voltage(vsd,vsq,theta)

  if isempty(theta)
      theta=0;
  end
  
  T_clarke = [1 0;
             -1/2 sqrt(3)/2;
             -1/2 -sqrt(3)/2];
  
  T_park_inv = [cos(theta) -sin(theta);
                sin(theta) cos(theta)];
  
  T = T_clarke*T_park_inv;
  
  Vabc = T*[vsd;vsq];

end
