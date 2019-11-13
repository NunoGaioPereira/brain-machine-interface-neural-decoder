function [modelParameters] = positionEstimatorTraining(training_data)

%% Find firing rates

spike_rate = [];
firingRates = [];
xVelArray = [];
yVelArray = [];

trainingData = struct([]);
velocity = struct([]);

dt = 10; % bin size

for k = 1:8
    for i = 1:98
        for n = 1:length(training_data)
            for t = 300:dt:550-dt
                
                % find the firing rates of one neural unit for one trial
                number_of_spikes = length(find(training_data(n,k).spikes(i,t:t+dt)==1));
                spike_rate = cat(2, spike_rate, number_of_spikes/(dt*0.001));
                
                % find the velocity of the hand movement
                % (needs calculating just once for each trial)
                if i==1
                    x_low = training_data(n,k).handPos(1,t);
                    x_high = training_data(n,k).handPos(1,t+dt);
                    
                    y_low = training_data(n,k).handPos(2,t);
                    y_high = training_data(n,k).handPos(2,t+dt);
                    
                    x_vel = (x_high - x_low) / (dt*0.001);
                    y_vel = (y_high - y_low) / (dt*0.001);
                    xVelArray = cat(2, xVelArray, x_vel);
                    yVelArray = cat(2, yVelArray, y_vel);
                end
                
            end
            
            % store firing rate of one neural unit for every trial in one array
            firingRates = cat(2, firingRates, spike_rate);
            spike_rate = [];
            
        end
        
        trainingData(i,k).firingRates = firingRates;
        velocity(k).x = xVelArray;
        velocity(k).y = yVelArray;
        
        firingRates = [];
        
    end
    xVelArray = [];
    yVelArray = [];
end

%% Linear Regression
% used to predict velocity
beta = struct([]);

for k=1:8
    
    vel = [velocity(k).x; velocity(k).y];
    firingRate = [];
    for i=1:98
    firingRate = cat(1, firingRate, trainingData(i,k).firingRates);
    end
    
    beta(k).reachingAngle = lsqminnorm(firingRate',vel');
    
end

%% KNN Classifier
% used to predict the reaching angle from the first 320ms

spikes = [];
reachingAngle = [];
spikeCount = zeros(length(training_data),98);

for k = 1:8
    for i = 1:98
        for n = 1:length(training_data)
                number_of_spikes = length(find(training_data(n,k).spikes(i,1:320)==1));
                spikeCount(n,i) = number_of_spikes;
        end
    end
    spikes = cat(1, spikes, spikeCount);
    reaching_angle(1:length(training_data)) = k;
    reachingAngle = cat(2, reachingAngle, reaching_angle);
    
end

knn = fitcknn(spikes,reachingAngle);


modelParameters = struct('beta',beta,'knnModel',knn); 

end