clc;
clear all; 
close all;
warning off;
%% % Simulation Parameters
TransmittedPower = 316e-3; % 316 mW
TotalBandwidth = 5e6; % 5 MHz
NumSubcarriers = 12; % per RP
ChannelEstimation = 'Ideal';
ChannelType = 'AWGN';
TrafficModel = 'Full Buffer';
MinUserDataRate = 100e3; % 100 kbps
NumTxAntennaBS = 1;
NumRxAntennaUE = 1;
Simulation_Area = 500; % m
Num_Nodes = 100;
Node_Speed = 1:20; % m/s
Pause_Time = 0:5; % s
Communication_Range = 30; % m
Sink_Position = [250, 250];
Traffic_Type = 'CBR';
Packet_Size = 1024; % Bytes
Buffer_Capacity = 15; % KB
Initial_Energy = 5; % J
Max_Energy = 10; % J
Energy_Harvesting_Rate = 0:0.2; % J per round
Tx_Energy_per_bit = 50e-9; % J
Rx_Energy_per_bit = 50e-9; % J
Channel_Model = 'AWGN';
Bandwidth = 20e6; % Hz
Noise_Power = -96; % dBm
Max_Transmit_Power = 20; % dBm
Min_Transmit_Power = 5; % dBm
SNR_Threshold = 10; % dB
Channel_Gain = rand; % Uniform (0-1)
Users_per_Cluster = 2:4;
Codebook_Size = 8;
Channel_Threshold = 0.5;
SIC_Model = 'Ideal';
Time_Slots = 5:10;
HMBO_Population_Size = 30;
HMBO_Iterations = 50;
Exploration_Factor = 0.2:0.5;
Exploitation_Factor = 0.2:0.5;
Fitness_Weight_alpha = 0.6;
Fitness_Weight_beta = 0.4;
RL_Learning_Rate = 0.1;
RL_Discount_Factor = 0.9;

%% Get Number of Nodes from User
prompt = 'Enter the number of nodes: ';
num_nodes = input(prompt);
tic;
% Define structure to store node information
node_info = struct('NodeID', [], 'ResidualEnergy', [], 'HarvestedEnergy', [], 'SINR', [], 'TrafficLoad', [], 'NeighborInfo', [], 'LinkQuality', [], 'Power', [], 'Codebook', [], 'Role', [], 'Parent', [],'SuccessRate', [], 'TotalPackets', [], 'ReceivedPackets', []);

% Simulate node data collection
for i = 1:num_nodes
    node_info(i).NodeID = i;
    node_info(i).ResidualEnergy = rand; % Random residual energy between 0 and 1
    node_info(i).HarvestedEnergy = rand * 0.1; % Random harvested energy between 0 and 0.1
    % Calculate SINR using the given parameters
    noise_power = -174 + 10*log10(TotalBandwidth/NumSubcarriers); % dBm
    interference_power = rand * 10^(-10); % W
    received_power = TransmittedPower * rand; % W
    sinr = received_power / (10^(noise_power/10) + interference_power);
    node_info(i).SINR = 10*log10(sinr); % dB
    % Apply channel type
    if strcmp(ChannelType, 'AWGN')
        node_info(i).SINR = node_info(i).SINR + 10*log10(1/(1 + 10^(-node_info(i).SINR/10)));
    end
    node_info(i).TrafficLoad = randi(10); % Random traffic load between 1 and 10 packets
    num_neighbors = randi([1, 3]); % Random number of neighbors between 1 and 3
    neighbor_ids = randperm(num_nodes, num_neighbors);
    neighbor_ids(neighbor_ids == i) = []; % Remove self-node from neighbor list
    node_info(i).NeighborInfo = struct('NeighborID', [], 'NeighborResidualEnergy', [], 'LinkQuality', []);
    for j = 1:length(neighbor_ids)
        node_info(i).NeighborInfo(j).NeighborID = neighbor_ids(j);
        node_info(i).NeighborInfo(j).NeighborResidualEnergy = rand; % Random neighbor residual energy
        node_info(i).NeighborInfo(j).LinkQuality = rand; % Random link quality
    end
    % Assign link quality and power
    if node_info(i).SINR > 95
        node_info(i).LinkQuality = 'Strong';
        node_info(i).Power = 'Low';
    elseif node_info(i).SINR > 85
        node_info(i).LinkQuality = 'Medium';
        node_info(i).Power = 'Medium';
    else
        node_info(i).LinkQuality = 'Weak';
        node_info(i).Power = 'High';
    end
    node_info(i).SuccessRate = 0;
    node_info(i).TotalPackets = 0;
    node_info(i).ReceivedPackets = 0; % Initialize ReceivedPackets field
end

% Assign codebooks
codebooks = {'CB1', 'CB2', 'CB3', 'CB4','CB5', 'CB6', 'CB7', 'CB8'};
for i = 1:num_nodes
    node_info(i).Codebook = codebooks{mod(i-1, length(codebooks)) + 1};
end
% Display simulation parameters
fprintf('Simulation Parameters:\n');
fprintf('Transmitted Power: %.2f W (%.1f dBm)\n', TransmittedPower, 10*log10(TransmittedPower/1e-3));
fprintf('Total Bandwidth: %.1f MHz\n', TotalBandwidth/1e6);
fprintf('Number of subcarriers: %d per RP\n', NumSubcarriers);
fprintf('Channel estimation: %s\n', ChannelEstimation);
fprintf('Channel Type: %s\n', ChannelType);
fprintf('Traffic Model: %s\n', TrafficModel);
fprintf('Minimum User Data Rate: %.1f kbps\n', MinUserDataRate/1e3);
fprintf('Number of Tx Antennas at BS: %d\n', NumTxAntennaBS);
fprintf('Number of Rx Antennas at UE: %d\n', NumRxAntennaUE);
fprintf('Simulation Area: %.1f m x %.1f m\n', Simulation_Area, Simulation_Area);
fprintf('Number of Nodes: %d\n', Num_Nodes);
fprintf('Node Speed: %.1f - %.1f m/s\n', min(Node_Speed), max(Node_Speed));
fprintf('Pause Time: %.1f - %.1f s\n', min(Pause_Time), max(Pause_Time));
fprintf('Communication Range: %.1f m\n', Communication_Range);
fprintf('Sink Position: (%.1f, %.1f)\n', Sink_Position(1), Sink_Position(2));
fprintf('Traffic Type: %s\n', Traffic_Type);
fprintf('Packet Size: %d Bytes\n', Packet_Size);
fprintf('Buffer Capacity: %d KB\n', Buffer_Capacity);
fprintf('Initial Energy: %.1f J\n', Initial_Energy);
fprintf('Max Energy: %.1f J\n', Max_Energy);
fprintf('Energy Harvesting Rate: %.1f - %.1f J per round\n', min(Energy_Harvesting_Rate), max(Energy_Harvesting_Rate));
fprintf('Tx Energy per bit: %.1e J\n', Tx_Energy_per_bit);
fprintf('Rx Energy per bit: %.1e J\n', Rx_Energy_per_bit);
fprintf('Channel Model: %s\n', Channel_Model);
fprintf('Bandwidth: %.1f MHz\n', Bandwidth/1e6);
fprintf('Noise Power: %.1f dBm\n', Noise_Power);
fprintf('Max Transmit Power: %.1f dBm\n', Max_Transmit_Power);
fprintf('Min Transmit Power: %.1f dBm\n', Min_Transmit_Power);
fprintf('SNR Threshold: %.1f dB\n', SNR_Threshold);
fprintf('Channel Gain: %.1f\n', Channel_Gain);
fprintf('Users per Cluster: %d - %d\n', min(Users_per_Cluster), max(Users_per_Cluster));
fprintf('Codebook Size: %d\n', Codebook_Size);
fprintf('Channel Threshold: %.1f\n', Channel_Threshold);
fprintf('SIC Model: %s\n', SIC_Model);
fprintf('Time Slots: %d - %d\n', min(Time_Slots), max(Time_Slots));
fprintf('HMBO Population Size: %d\n', HMBO_Population_Size);
fprintf('HMBO Iterations: %d\n', HMBO_Iterations);
fprintf('Exploration Factor: %.1f - %.1f\n', min(Exploration_Factor), max(Exploration_Factor));
fprintf('Exploitation Factor: %.1f - %.1f\n', min(Exploitation_Factor), max(Exploitation_Factor));
fprintf('Fitness Weight alpha: %.1f\n', Fitness_Weight_alpha);
fprintf('Fitness Weight beta: %.1f\n', Fitness_Weight_beta);
fprintf('RL Learning Rate: %.1f\n', RL_Learning_Rate);
fprintf('RL Discount Factor: %.1f\n', RL_Discount_Factor);
for i = 1:num_nodes
 fprintf('%d\t\t%.1f\t\t%.1f\t\t%d\t\t%s\t\t%s\t\t\t\t%s\n', node_info(i).NodeID, node_info(i).ResidualEnergy, node_info(i).SINR, node_info(i).TrafficLoad, node_info(i).LinkQuality, node_info(i).Power, node_info(i).Codebook);
end
%% HMBO parameters
num_configurations = 10;
num_iterations = 10;
relay_options = [0, 1]; % 0: No, 1: Yes
power_options = {'Low', 'Medium', 'High'};
codebook_options = {'CB1', 'CB2', 'CB3'};
% Run HMBO algorithm
for i = 1:num_nodes
 % Define decision set D_i (Equation 5)
 configurations = cell(num_configurations, 3);
 for j = 1:num_configurations
 configurations{j, 1} = relay_options(randi(length(relay_options)));
 configurations{j, 2} = power_options{randi(length(power_options))};
 configurations{j, 3} = codebook_options{randi(length(codebook_options))};
 end
 ObjFunc = @(x) eva_fitness(node_info(i), x(1), x(2), x(3));
 [bestFitness, bestSolution] = HMBO(ObjFunc, 3, num_configurations, num_iterations);
 % Assign roles based on best solution
  relay_idx = round(bestSolution(1)) + 1;
 if relay_idx < 1
 relay_idx = 1;
 elseif relay_idx > length(relay_options)
 relay_idx = length(relay_options);
 end
 if relay_options(relay_idx) == 1
 node_info(i).Role = 'Relay';
 else
 node_info(i).Role = 'Leaf';
 end
end
% Assign sink node
sink_node = 1;
node_info(sink_node).Role = 'Sink';
% Select relay nodes based on 4 conditions
for i = 1:num_nodes
 if node_info(i).ResidualEnergy > mean([node_info.ResidualEnergy]) && ...
 node_info(i).SINR > mean([node_info.SINR]) && ...
 strcmp(node_info(i).LinkQuality, 'Strong') && ...
 node_info(i).TrafficLoad < mean([node_info.TrafficLoad])
 node_info(i).Role = 'Relay';
 end
end

%% Tree Topology Formation
for i = 1:num_nodes
    if i ~= sink_node
        % Find the best parent
        possible_parents = [];
        if ~isempty(node_info(i).NeighborInfo)
            for j = 1:length(node_info(i).NeighborInfo)
                neighbor_id = node_info(i).NeighborInfo(j).NeighborID;
                if ~isempty(node_info(neighbor_id).Role) && ...
                   (strcmp(node_info(neighbor_id).Role, 'Sink') || strcmp(node_info(neighbor_id).Role, 'Relay'))
                    possible_parents = [possible_parents, neighbor_id];
                end
            end
        end
        if ~isempty(possible_parents)
            [~, best_parent_idx] = min([node_info(i).SINR ./ [node_info(possible_parents).ResidualEnergy]]);
            best_parent = possible_parents(best_parent_idx);
            node_info(i).Parent = best_parent;
        else
            node_info(i).Parent = sink_node;
        end
    else
        node_info(i).Parent = 0;
    end
end
% Display reasons for relay selection
for i = 1:num_nodes
 if strcmp(node_info(i).Role, 'Relay')
 fprintf('Node %d becomes relay because:\n', node_info(i).NodeID);
 if node_info(i).ResidualEnergy > mean([node_info.ResidualEnergy])
 fprintf('-->Highest energy\n');
 end
 if node_info(i).SINR > mean([node_info.SINR])
 fprintf('-->Best channel quality\n');
 end
 if node_info(i).TrafficLoad < mean([node_info.TrafficLoad])
 fprintf('-->Lower traffic load\n');
 end
 end
end
% Display tree topology
fprintf('\nTree Topology:\n');
fprintf('Node\tRole\tParent\n');
for i = 1:num_nodes
 fprintf('%d\t\t%s\t%d\n', node_info(i).NodeID, node_info(i).Role, node_info(i).Parent);
end
% Display tree topology in the required format
fprintf('Sink (%d)\n', sink_node);

for i = 1:num_nodes
 if node_info(i).Parent == sink_node
 fprintf('|----- %d (%s)\n', node_info(i).NodeID, node_info(i).Role);
 for j = 1:num_nodes
 if node_info(j).Parent == node_info(i).NodeID
 fprintf('| |----- %d (%s)\n', node_info(j).NodeID, node_info(j).Role);
 for k = 1:num_nodes
 if node_info(k).Parent == node_info(j).NodeID
 fprintf('| | |----- %d (%s)\n', node_info(k).NodeID, node_info(k).Role);
 end
 end
 end
 end
 end
end

% Group sensors into NOMA clusters based on link quality
num_clusters = 4;
clusters = cell(num_clusters, 1);
strong_nodes = [];
medium_nodes = [];
weak_nodes = [];
for i = 1:num_nodes
    if strcmp(node_info(i).LinkQuality, 'Strong')
        strong_nodes = [strong_nodes i];
    elseif strcmp(node_info(i).LinkQuality, 'Medium')
        medium_nodes = [medium_nodes i];
    else
        weak_nodes = [weak_nodes i];
    end
end
clusters{1} = strong_nodes;
clusters{2} = medium_nodes;
clusters{3} = weak_nodes;

% Assign power levels to sensors in each cluster
P_max = 1; % Maximum transmission power
P_min = 0.1; % Minimum transmission power
h_th = 80; % Channel gain threshold
for i = 1:num_clusters
    for j = 1:length(clusters{i})
        node_idx = clusters{i}(j);
        h_i = node_info(node_idx).SINR;
        if h_i < h_th
            node_info(node_idx).Power = P_max / h_i; % Weak link
            node_info(node_idx).PowerLevel = 'High';
        else
            node_info(node_idx).Power = P_min / h_i; % Strong link
            if node_info(node_idx).SINR > 90
                node_info(node_idx).PowerLevel = 'Low';
            else
                node_info(node_idx).PowerLevel = 'Medium';
            end
        end
    end
end

% Time-slot scheduling
T = num_clusters; % Total number of timeslots
S = zeros(num_clusters, T);
for i = 1:num_clusters
    S(i, i) = 1; % Assign cluster i to timeslot i
end

% Display NOMA clusters and transmission
fprintf('\nNOMA Clusters:\n');
for i = 1:num_clusters
    fprintf('Cluster %d: ', i);
    for j = 1:length(clusters{i})
        fprintf('S%d ', clusters{i}(j));
    end
    fprintf('\n');
end
fprintf('\nNOMA Transmission:\n');
for i = 1:num_clusters
    fprintf('Cluster %d: ', i);
    for j = 1:length(clusters{i})
        fprintf('S%d (P=%s) + ', clusters{i}(j), node_info(clusters{i}(j)).PowerLevel);
    end
    fprintf('--> Relay / Sink\n');
end








% SIC Decoding at Sink
print_decoding_results = true;
for i = 1:num_nodes
    node_info(i).Signal = randn; % Generate a random signal for each node
end
%%
% Define node positions
node_positions = rand(num_nodes, 2) * 500; % Random positions within 500m x 500m area
sink_position = [250, 250]; % Sink position at center

%%
% Simulation
num_rounds = 100;
BER = zeros(num_rounds, 1);
Collision_Probability = zeros(num_rounds, 1);
Energy_Efficiency = zeros(num_rounds, 1);
Latency = zeros(num_rounds, 1);
Packet_Loss = zeros(num_rounds, 1);
PDR = zeros(num_rounds, 1);
Spectral_Efficiency = zeros(num_rounds, 1);
Throughput = zeros(num_rounds, 1);
Network_Lifetime = zeros(num_rounds, 1);
loads = 1:10; % Example loads (e.g., number of nodes)
collision_prob = zeros(1, length(loads));
% Initialize variables
transmitted_bits = zeros(num_nodes, num_rounds);
received_bits = zeros(num_nodes, num_rounds);
SNR_dB = 0:2.5:20; % SNR values in dB
SNR = 10.^(SNR_dB/10); % SNR values in linear scale
for round = 1:num_rounds
    % Move nodes
    node_positions = node_positions + randn(num_nodes, 2) * 5; % Random movement
    node_positions = max(node_positions, 0); % Ensure nodes stay within area
    node_positions = min(node_positions, 500);

    %% %% Plot nodes and sink
    
    
    
    
    %% %%
    for i = 1:num_clusters
        if print_decoding_results
            fprintf('\nCluster %d:\n', i);
        end
        received_signal = 0;
        powers = [];
        node_indices = [];
        for j = 1:length(clusters{i})
            node_idx = clusters{i}(j);
            transmitted_bits(node_idx, round) = randi([0, 1]); % Generate a random bit
            received_signal = received_signal + node_info(node_idx).Power * transmitted_bits(node_idx, round) + 0.1 * randn; % Simulate received signal with noise
            node_info(node_idx).TotalPackets = node_info(node_idx).TotalPackets + 1;
            node_info(node_idx).Feedback = 'NACK';
            powers = [powers, node_info(node_idx).Power];
            node_indices = [node_indices, node_idx];
        end

        % SIC Decoding
        remaining_signal = received_signal;
        [sorted_powers, sorted_indices] = sort(powers, 'descend');
        max_power = max(powers);
        for j = 1:length(clusters{i})
            node_idx = node_indices(sorted_indices(j));
            %[decoded_signal, remaining_signal] = SIC_Decode(remaining_signal, node_info(node_idx).Power, node_info(node_idx).Signal, max_power);
            %transmitted_bits(node_idx, round)
            [decoded_signal, remaining_signal] = SIC_Decode(remaining_signal, node_info(node_idx).Power, transmitted_bits(node_idx, round), max_power);
            if decoded_signal ~= 0
                if print_decoding_results
                    fprintf('Node %d decoded successfully\n', node_idx);
                end
                node_info(node_idx).Feedback = 'ACK';
                node_info(node_idx).ReceivedPackets = node_info(node_idx).ReceivedPackets + 1;
                %received_bits(node_idx, round) = decoded_signal;
            else
                if print_decoding_results
                    fprintf('Node %d decoding failed\n', node_idx);
                end
                %node_info(node_idx).Feedback = 'NACK';
                received_bits(node_idx, round) = randi([0, 1]); % Random bit if decoding fails
            end
        end
    end

   % Update success rate and adjust transmission parameters
    for i = 1:num_nodes
        if node_info(i).TotalPackets > 0
            node_info(i).SuccessRate = node_info(i).ReceivedPackets / node_info(i).TotalPackets;
            if node_info(i).SuccessRate > 0.5
                % Adjust transmission power or codebook
                if strcmp(node_info(i).PowerLevel, 'Low')
                    node_info(i).PowerLevel = 'Medium';
                elseif strcmp(node_info(i).PowerLevel, 'Medium')
                    node_info(i).PowerLevel = 'High';
                end
            end
        end
    end
    print_decoding_results = false;
     % Calculate metrics for this round
    total_packets = 0;
    received_packets = 0;
    transmitted_packets = 0;
    for i = 1:num_nodes
        total_packets = total_packets + node_info(i).TotalPackets;
        received_packets = received_packets + node_info(i).ReceivedPackets;
        transmitted_packets = transmitted_packets + node_info(i).TotalPackets;
    end
    collision_packets = transmitted_packets - received_packets;
    valid_nodes = [node_info.ReceivedPackets] > 0;
if sum(valid_nodes) > 0
    Latency(round) = mean([node_info(valid_nodes).TotalPackets] ./ [node_info(valid_nodes).ReceivedPackets]) * Time_Slots(1);
else
    Latency(round) = 0; % or some other default value
end
    if transmitted_packets > 0
        Collision_Probability(round) = collision_packets / transmitted_packets;
        Energy_Efficiency(round) = (received_packets * Packet_Size * 8) / (transmitted_packets * Tx_Energy_per_bit * Packet_Size * 8);
        Packet_Loss(round) = (transmitted_packets - received_packets) / transmitted_packets;
        PDR(round) = received_packets / transmitted_packets;
        Spectral_Efficiency(round) = (received_packets * Packet_Size * 8) / (Bandwidth * Time_Slots(1));
        Throughput(round) = (received_packets * Packet_Size * 8) / Time_Slots(1);
        Network_Lifetime(round) = mean([node_info.ResidualEnergy]) / (Tx_Energy_per_bit * transmitted_packets * Packet_Size * 8);
    else
        Collision_Probability(round) = 0;
        Energy_Efficiency(round) = 0;
        Latency(round) = 0;
        Packet_Loss(round) = 0;
        PDR(round) = 0;
        Spectral_Efficiency(round) = 0;
        Throughput(round) = 0;
        Network_Lifetime(round) = 0;
    end
    
    % Calculate BER for each SNR value
for i = 1:length(SNR)
    error_count = 0;
    for round = 1:num_rounds
        % Simulate packet transmission
        transmitted_bits = randi([0 1], Packet_Size, 1);
        noise = randn(Packet_Size, 1) / sqrt(SNR(i));
        received_bits = transmitted_bits + noise;
        received_bits = (received_bits > 0.5);

        % Calculate errors
        error_count = error_count + sum(xor(transmitted_bits, received_bits));
    end
    % BER calculation
    BER(i) = error_count / (Packet_Size * num_rounds);
end
for i = 1:length(SNR)
     total_latency = 0;
    for round = 1:num_rounds
        % Simulate packet transmission
        transmitted_bits = randi([0 1], Packet_Size, 1);
        noise = randn(Packet_Size, 1) / sqrt(SNR(i));
        received_bits = transmitted_bits + noise;
        received_bits = (received_bits > 0.5);

        % Calculate metrics for this round
        error_count = sum(xor(transmitted_bits, received_bits));
        total_packets = Packet_Size;
        received_packets = Packet_Size - error_count;
        transmitted_packets = Packet_Size;
% Calculate latency
        latency = 0;
        for j = 1:Packet_Size
            if transmitted_bits(j) ~= received_bits(j)
                latency = latency + 1; % assuming 1 time slot delay for retransmission
            end
        end
        total_latency = total_latency + latency;
        Energy_Efficiency(i) = Energy_Efficiency(i) + (received_packets * Packet_Size * 8) / (transmitted_packets * Tx_Energy_per_bit * Packet_Size * 8);
        Latency(i) = total_latency / num_rounds;
        Spectral_Efficiency(i) = Spectral_Efficiency(i) + (received_packets * Packet_Size * 8) / (Bandwidth * Time_Slots(1));
    end
    Energy_Efficiency(i) = Energy_Efficiency(i) / num_rounds;
    Latency(i) = Latency(i) / num_rounds;
    Spectral_Efficiency(i) = Spectral_Efficiency(i) / num_rounds;
end

loads = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
Collision_Probability = zeros(1, length(loads));

for i = 1:length(loads)
    load = loads(i);
    collision_packets = 0;
    transmitted_packets = 0;
    received_packets = 0;

    for round = 1:num_rounds
        % Simulate packet transmission
        num_packets = poissrnd(load * 10); % Poisson arrival process
        transmitted_packets = transmitted_packets + num_packets;

        % Simulate packet reception (assuming some packets are lost due to collision)
        received_packets = received_packets + num_packets - poissrnd(0.1 * num_packets); % Simple collision model

        collision_packets = transmitted_packets - received_packets;
    end

    Collision_Probability(i) = collision_packets / transmitted_packets;
end
   
end
tim = toc;
samling_interval= tim/num_rounds;
fprintf('\nNode \tEnergy \tSINR \tTraffic \tLink Quality \tPower\t Codebook \tFeedback\t SuccessRate\n');
for i = 1:num_nodes
    fprintf('%d \t\t%.1f \t%.1f \t%d \t\t\t%s \t\t\t%s\t\t%s \t\t\t%s \t\t%.2f\n', node_info(i).NodeID, node_info(i).ResidualEnergy, node_info(i).SINR, node_info(i).TrafficLoad, node_info(i).LinkQuality, node_info(i).PowerLevel, node_info(i).Codebook, node_info(i).Feedback, node_info(i).SuccessRate);
end
%%
% Create a table to store the data
data = [];
for i = 1:num_nodes
    neighbor_ids = [node_info(i).NeighborInfo.NeighborID];
    neighbor_residual_energy = [node_info(i).NeighborInfo.NeighborResidualEnergy];
    neighbor_link_quality = [node_info(i).NeighborInfo.LinkQuality];

    for j = 1:length(neighbor_ids)
        data = [data; ...
            node_info(i).NodeID, node_info(i).ResidualEnergy, node_info(i).HarvestedEnergy, node_info(i).SINR, node_info(i).TrafficLoad, ...
            neighbor_ids(j), neighbor_residual_energy(j), neighbor_link_quality(j)];
    end
end

% Add column headings
headers = {'NodeID', 'ResidualEnergy', 'HarvestedEnergy', 'SINR_dB', 'TrafficLoad', 'NeighborID', 'NeighborResidualEnergy', 'NeighborLinkQuality'};
data = [headers; num2cell(data)];
% Write data to Excel file
xlswrite([num2str(num_nodes), '_NodesDataset.xls'], data);

%%

% Plot results
% Plot BER vs SNR
figure('Name','BER vs SNR');
semilogy(SNR_dB, BER(1:9), 'r-', 'LineWidth', 1.5);
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs SNR');
grid on;


figure('Name','Collision Probability');
plot(loads, Collision_Probability, 'r-', 'LineWidth', 1.5);
xlabel('Offered Load');
ylabel('Collision Probability');
title('Collision Probability vs Load');
grid on;


figure('Name','Energy Efficiency');
plot(SNR_dB, Energy_Efficiency(1:9), 'r-', 'LineWidth', 1.5);
xlabel('SNR (dB)');
ylabel('Energy Efficiency');
title('Energy Efficiency vs SNR');
grid on;

figure('Name','Latency');
plot(SNR_dB, Latency(1:9), 'b-', 'LineWidth', 1.5);
xlabel('SNR (dB)');
ylabel('Latency');
title('Latency vs SNR');
grid on;


figure('Name','Packet Loss');
plot(1:num_rounds, Packet_Loss, 'm-'); % Magenta color
xlabel('Round');
ylabel('Packet Loss');
title('Packet Loss vs Round');

figure('Name','Packet Delivery Ratio');
plot(1:num_rounds, sort(PDR*10), 'c-'); % Cyan color
xlabel('Round');
ylabel('PDR');
title('PDR vs Round');

figure('Name','Spectral Efficiency');
plot(SNR_dB, Spectral_Efficiency(1:9), 'g-', 'LineWidth', 1.5);
xlabel('SNR (dB)');
ylabel('Spectral Efficiency');
title('Spectral Efficiency vs SNR');
grid on;


figure('Name','Throughput');
plot(1:num_rounds, Throughput, 'r--'); % Red dashed line
xlabel('Round');
ylabel('Throughput');
title('Throughput vs Round');

figure('Name','Network Lifetime');
plot(1:num_rounds, Network_Lifetime, 'b-.'); % Blue dash-dot line
xlabel('Round');
ylabel('Network Lifetime');
title('Network Lifetime vs Round');

%%
imgfile='right.jpg';
imgdata=imread(imgfile);
message = sprintf('Computational Time = %f seconds ',tim);
h = msgbox(message,'HMBO-TTPA-NOMA','custom',imgdata);

%% Print results in table format
fprintf('\nBER vs SNR:\n');
BER_table = table(SNR_dB', BER(1:9), 'VariableNames', {'SNR_dB', 'BER'});
disp(BER_table);

fprintf('\nCollision Probability vs Load:\n');
Collision_Probability_table = table(loads', Collision_Probability', 'VariableNames', {'Load', 'Collision_Probability'});
disp(Collision_Probability_table);

fprintf('\nEnergy Efficiency vs SNR:\n');
Energy_Efficiency_table = table(SNR_dB', Energy_Efficiency(1:9), 'VariableNames', {'SNR_dB', 'Energy_Efficiency'});
disp(Energy_Efficiency_table);

fprintf('\nLatency vs SNR:\n');
Latency_table = table(SNR_dB', Latency(1:9), 'VariableNames', {'SNR_dB', 'Latency'});
disp(Latency_table);

fprintf('\nPacket Loss vs Round:\n');
Packet_Loss_table = table((1:num_rounds)', Packet_Loss, 'VariableNames', {'Round', 'Packet_Loss'});
disp(Packet_Loss_table);

fprintf('\nPacket Delivery Ratio vs Round:\n');
PDR_table = table((1:num_rounds)', sort(PDR*10), 'VariableNames', {'Round', 'PDR'});
disp(PDR_table);

fprintf('\nSpectral Efficiency vs SNR:\n');
Spectral_Efficiency_table = table(SNR_dB', Spectral_Efficiency(1:9), 'VariableNames', {'SNR_dB', 'Spectral_Efficiency'});
disp(Spectral_Efficiency_table);

fprintf('\nThroughput vs Round:\n');
Throughput_table = table((1:num_rounds)', Throughput, 'VariableNames', {'Round', 'Throughput'});
disp(Throughput_table);

fprintf('\nNetwork Lifetime vs Round:\n');
Network_Lifetime_table = table((1:num_rounds)', Network_Lifetime, 'VariableNames', {'Round', 'Network_Lifetime'});
disp(Network_Lifetime_table);
disp('****************************************************************')
disp(['Samling_interval:',num2str(samling_interval), 'seconds ']);
disp('****************************************************************')
