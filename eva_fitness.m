function fitness = eva_fitness(node_info, relay, power, codebook)% Fitness function (Equation 6)
 alpha = 0.5;
 beta = 0.5;
 energy_consumption = 0.1; % Assume a fixed energy consumption for simplicity
 reliability = node_info.SINR / (node_info.SINR + 1);
fitness = alpha * (energy_consumption / node_info.ResidualEnergy) + beta * (1 / reliability);
end