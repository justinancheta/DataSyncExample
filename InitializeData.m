%
% Generate some noisy crappy data to serve as an example, we will blackout
% a small portion as buffered data 
%



%% Input Options
    RealTime = (0:0.0002:100)';
    Amplitude = [1.00; 0.25; 0.01]; % Amplitude
    freq = [0.5; 0.1; 0.001]; % Hz
    cleanWorkspace = true;
    
    if cleanWorkspace
        clearvars -except RealTime Amplitude freq cleanWorkspace;
        close all;
        clc;
    end
    
% Set the RNG states 
% Example usage: 
%   s = rng;
%   s.Seed = 1;
%   a = rand(10);
%   rng(s)
%   b = rand(10);
%   rng(s)
%   c = rand(10);
%   a-b == a-c == b-c == 0 * zeros(10);
%
    
%% Generate Data
    s = rng;
    s.Seed = 1000;
    rng(s);    
    A = rand(numel(RealTime), 1) * 0.1;
    
    s.Seed = 1337;
    rng(s);
    B = rand(numel(RealTime), 1) * 0.01;
    
    s.Seed = 123;
    rng(s)
    C = rand(numel(RealTime), 1) * 0.001;
    
    RealData = Amplitude(1) .* sin(2*pi*freq(1)*RealTime) + A + ...
               Amplitude(2) .* sin(2*pi*freq(2)*RealTime) + B + ...
               Amplitude(3) .* sin(2*pi*freq(3)*RealTime) + C;
% This just makes it easier to allign data interactively most signals will
% be discretized anyways
    RealData = round(RealData, 4); 
    
    h1 = figure('Position',[240, 45, 1440 900]);
    hold on; grid on; legend('location','BestOutside');
    plot(RealTime, RealData,'DisplayName','Original Data')
    xlabel('Time');
    ylabel('Signal');
    
%% Generate a buffered window and remove data  
    tWindow = [10.468, 11.6894];
    indBuffer = and( RealTime <= tWindow(2), RealTime >= tWindow(1) );
    dataBuffer = RealData(indBuffer);
    timeBuffer = (0:numel(dataBuffer)-1) * 0.0002;
    
    tBadData = [10.468*1.1, 15.6894*0.8];
    indBadData = and( RealTime <= tBadData(2), RealTime >= tBadData(1) );
    BadData = RealData;
    BadData(indBadData) = 1;
    
% Set the axis 
    axis( [10 12 -1 2] );
    
% Clean up workspace to make this easier to work with the GUIDE toole
    clearvars -except h1 BadData dataBuffer RealData RealTime tBadData timeBuffer tWindow 
    
    ex1 = [RealTime, RealData];
    ex2 = [timeBuffer', dataBuffer];
    
%% 
    
    
    