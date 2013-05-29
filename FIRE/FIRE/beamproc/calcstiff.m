function[stiff X F] = calcstiff(p)
%CALCSTIFF - calculates stiffness of network, given network structure p
%using teh linear FEA model

if isempty(p)
    stiff = 0;
    return
end

%solve network
    [Ulx Ula]  = solve_linear_red(p);
    Ulx        = full(Ulx);
    Ula        = full(Ula);
    u          = m2v([Ulx; Ula]);
    
%calculate energy (in N/m^2) in entire structure
    K = linelement_glob(p);    
    energy = .5*u'*K*u; %N/(micron^2)
    vol = prod(max(p.X0)-min(p.X0)); %micron^3
    E  = 2*energy/vol/(p.strain)^2; %N/(micron^2)
    stiff = E*1e12; %N/m^2
    
%calculate change in positions and internal energies
    if nargout > 1
        X = p.X0 + Ulx;
        F = calcenergy_glob(p,Ulx,Ula);
    end