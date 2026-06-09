%PeGS2 vs measured force
% 
% p_CF95_1_5_1 = {0.2206; 24.7642; 2.5308; 1.9740; 72.4991; 1.9201; 0.7255; 
%     0.7049; 4.0739; 1.6668; 5.1198; 3.5901; 2.5226; 3.4775; 0.5651};
% 
% f_CF95_2_1   = readmatrix('G:\Meine Ablage\BA\Messungen-Stress-Opt.xlsx', 'Sheet', 'Static_Single_Particle', 'Range', 'T6:T20');
% f_CF95_1_5_1 = readmatrix('G:\Meine Ablage\BA\Messungen-Stress-Opt.xlsx', 'Sheet', 'Static_Single_Particle', 'Range', 'Z6:Z20');
% f_CF95_1_1   = readmatrix('G:\Meine Ablage\BA\Messungen-Stress-Opt.xlsx', 'Sheet', 'Static_Single_Particle', 'Range', 'AF6:AF20');
% 
% p_CF30_1_1 = [0.1234; 0.4417; 0.2237; 1.0005; 13.7107; 1.6527; 0.3773; ...
%   3.1331; 0.2970; 0.3366; 0.4177; 0.4125; 0.4046; 0.3733];


% 
% 1. Define the calculated force (y-axis data)
%% Clear Flex 95
%2 cm
p_CF95_2_1 = [0.0657; 1.1171; 0.7122; 1.2266; 0.7672; 1.6562; 0.9954; ...
    14.4045; 4.7538; 8.1638; 7.6814; 6.4535; 1.9113; 7.9824; 1.9822];
%1.5 cm
p_CF95_1_5_1 = [0.2206; 24.7642; 2.5308; 1.9740; 72.4991; 1.9201; 0.7255; ...
                0.7049; 4.0739; 1.6668; 5.1198; 3.5901; 2.5226; 3.4775; 0.5651];
%1 cm
p_CF95_1_1 = [0.0330; 0.2176; 0.4752; 0.7371; 4.0116; 0.8827; 22.0723;...
    2.9059; 3.7394; 0.8977; 1.0407; 10.4006; 1.6306; 1.0233; 1.5918];


% 2. Read the measured force (x-axis data) from your Excel file
f_CF95_2_1   = readmatrix('G:\Meine Ablage\BA\Messungen-Stress-Opt.xlsx', 'Sheet', 'Static_Single_Particle', 'Range', 'T6:T20');
f_CF95_1_5_1 = readmatrix('G:\Meine Ablage\BA\Messungen-Stress-Opt.xlsx', 'Sheet', 'Static_Single_Particle', 'Range', 'Z6:Z20');
f_CF95_1_1   = readmatrix('G:\Meine Ablage\BA\Messungen-Stress-Opt.xlsx', 'Sheet', 'Static_Single_Particle', 'Range', 'AF6:AF20');


% Define the Peach color [R, G, B]
peachColor = [1.00, 0.77, 0.58];

% Create the figure
figure('Color', 'w');
hold on;

% Plot the datasets with unfilled markers and peach contours
scatter(f_CF95_2_1, p_CF95_2_1, 80, 'Marker', 'o', ...
    'MarkerEdgeColor', peachColor, 'MarkerFaceColor', 'none', 'LineWidth', 1.5, 'DisplayName', 'Clear Flex 95 (2 cm)');

scatter(f_CF95_1_5_1, p_CF95_1_5_1, 80, 'Marker', 's', ...
    'MarkerEdgeColor', peachColor, 'MarkerFaceColor', 'none', 'LineWidth', 1.5, 'DisplayName', 'Clear Flex 95 (1.5 cm)');

scatter(f_CF95_1_1, p_CF95_1_1, 80, 'Marker', '^', ...
    'MarkerEdgeColor', peachColor, 'MarkerFaceColor', 'none', 'LineWidth', 1.5, 'DisplayName', 'Clear Flex 95 (1 cm)');

% Calculate limits to draw the identity line automatically
allData = [f_CF95_2_1; f_CF95_1_5_1; f_CF95_1_1; p_CF95_2_1; p_CF95_1_5_1; p_CF95_1_1];
minVal = min(allData, [], 'omitnan');
maxVal = max(allData, [], 'omitnan');

% Plot the identity line as a black pointed/dotted line (':k')
plot([minVal, maxVal], [minVal, maxVal], ':k', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Formatting the axes and labels
xlabel('Measured Force [N]');
ylabel('Calculated Force [N]');
%title('Measured vs. Calculated Force (Clear Flex 95)', 'Interpreter', 'latex');

% Add legend and grid
legend('Location', 'best', 'Interpreter', 'none');
%grid on;
box on;
xlim([0 15]);
ylim([0 75]);

% Forces a 1:1 aspect ratio so the identity line rests at exactly 45 degrees
%axis equal; 

hold off;