function inCurvs_mod = group6(inCurvs)

% group6.m
inCurvs_mod = inCurvs;
for i = 1:length(inCurvs)    
    % Rotate all angles to be from 0 to 180 deg (curvelets have no
    % direction, so we just need 0 to 180, not 0 to 360)
    inCurvs_mod(i).angle = mod(180+inCurvs(i).angle,180);
end

end


