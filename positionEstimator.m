function [x, y, newModelParameters] = positionEstimator(test_data, modelParameters)

%% first use the first 320ms to estimate reaching angle

spikeCount = zeros(98,1);

if length(test_data.spikes) <= 320
    % find number of spikes
    for i = 1:98
        number_of_spikes = length(find(test_data.spikes(i,1:320)==1));
        spikeCount(i) = number_of_spikes;
    end

% find most predicted direcion and set it as hand direction/reaching angle
    direction = mode(predict(modelParameters.knnModel,spikeCount'));
    
else
    % use value that was found prevously
    direction = modelParameters.direction;
end

%% predict movement

% current time window
tmin = length(test_data.spikes)-20;
tmax = length(test_data.spikes);

% find firing rate of test data
firingRate = zeros(98,1);
for i = 1:98
    number_of_spikes = length(find(test_data.spikes(i,tmin:tmax)==1));
    firingRate(i) = number_of_spikes/(20*0.001);
end

% estimate velocity
velocity_x = firingRate'*modelParameters.beta(direction).reachingAngle(:,1);
velocity_y = firingRate'*modelParameters.beta(direction).reachingAngle(:,2);

%% output

if length(test_data.spikes) <= 320
    x = test_data.startHandPos(1);
    y = test_data.startHandPos(2);
else
    % previous position + velocity * 20ms (to get position)
    x = test_data.decodedHandPos(1,length(test_data.decodedHandPos(1,:))) + velocity_x*(20*0.001);
    y = test_data.decodedHandPos(2,length(test_data.decodedHandPos(2,:))) + velocity_y*(20*0.001);
end

newModelParameters.beta = modelParameters.beta;
newModelParameters.knnModel = modelParameters.knnModel;
newModelParameters.direction = direction;

end