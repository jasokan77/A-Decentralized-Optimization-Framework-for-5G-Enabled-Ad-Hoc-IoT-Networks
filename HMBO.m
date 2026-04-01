function [bestFitness, bestSolution] = HMBO(ObjFunc, dim, popSize, maxIter)
 % Initialization
 pop = rand(popSize, dim);
 fitness = arrayfun(@(i) ObjFunc(pop(i,:)), 1:popSize);
 [bestFitness, bestIdx] = min(fitness);
 bestSolution = pop(bestIdx, :);
 for t = 1:maxIter
 %Sort Population
 [fitness, sortIdx] = sort(fitness);
 pop = pop(sortIdx, :);
 %Separate into Subpopulations 
 NP1 = ceil(popSize * 0.4); % ratio
 %Migration Operation 
 for i = 1:NP1
 % Migration logic to generate offspring (Equation 7)
 r = rand; % (0 < r < 1) (Equation 8)
 pop(i,:) = pop(i,:) + r * (bestSolution - pop(i,:));
 end
 %Butterfly Adjusting Operator )
 for j = (NP1+1):popSize
 % Adjustment logic to update positions (Equation 7)
 p = rand; % (0 < p < 1) (Equation 8)
 pop(j,:) = pop(j,:) + p * rand() * (bestSolution - pop(j,:));
 end
 %Hybrid Enhancement (e.g., Mutation)
 for i = 1:popSize
 if rand < 0.1
 pop(i,:) = rand(1,dim);
 end
 end
 %Greedy Selection
 new_fitness = arrayfun(@(i) ObjFunc(pop(i,:)), 1:popSize);
 for i = 1:popSize
 if new_fitness(i) < fitness(i)
 fitness(i) = new_fitness(i);
 else
 pop(i,:) = pop(sortIdx(i), :);
 end
 end
 %Update Best (Equation 9)
 [bestFitness, bestIdx] = min(fitness);
 bestSolution = pop(bestIdx, :);
 end
end