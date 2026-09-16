%% eDrives Embed

function [isd,isq]= Park_Clarke_Current(ia,ic,theta)

%initial condition fot theta

if isempty(theta)
theta=0;
end

%Park-Clarke transform
  
  isd = cos(theta)*ia+sin(theta)*(-sqrt(3)/3*ia-2*sqrt(3)/3*ic);
  
  isq = -sin(theta)*ia+cos(theta)*(-sqrt(3)/3*ia-2*sqrt(3)/3*ic);

end 
