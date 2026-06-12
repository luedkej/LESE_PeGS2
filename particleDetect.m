%Updated to first release version of PeGS2 by Carmen Lee 29/9/24
% Written for PeGS 2.0 by Kerstin Nordstrom 8/24 
%Adapted from Carmen Lee's adaptation of Jonathan Kollmer's PeGS 1.0
%

% # particleDetect
% 
% 
% **i/o**
% The input of this module are experimental images. It is assumed that the image is RGB, the particles are detected using the green channel and the green channel contains the force information. 
% 
% **i** 
% N input images
% 
% 
% **o** 
% The output are N txt files in the format:
% *Centers text files: X Y radius edge
% *Params text file: parameters used in circle finding, et al
% 
% **parameters**
% The user set parameters are held inside of the structure <pdParams> in the main function (PeGSModular) and as <p> in the particleDetect function. The fields self populate if not set by the user with default values (done in the function paramsSetUp). The parameters are
% - `boundaryType` : shape of the boundary holding the particles, this is for identifying edge particles
% - `radiusRange`: an array consisting of the lower and upper radius bounds for the particles (pixels)
% - `dtol` : the distance tolerance (pixels) between the edge of the particle and the wall to be assigned as as edge
% - `sensitivity` : the sensitivity to for circle finding. Higher sensitivity == find more circles
% - `edgeThresh` : to assign what is the edge of an object in the image (note: not the same edge as the edge flag, and this is set inside the main function after the image has been loaded)
% 
% **notes**
% If the polariscope is set up for being in transmission rather than reflection, imfindcircles might work better if you set 'ObjectPolarity' to 'dark' rather than 'bright'
% 


function out = particleDetect(fileParams, pdParams, verbose)
%fileParams = directories and image name pattern
%pdParams = parameters for particle detect

%% FILE MANAGEMENT


    if ~exist(fullfile(fileParams.topDir, fileParams.particleDir) , 'dir')
        mkdir(fullfile(fileParams.topDir, fileParams.particleDir))
    end

    
    if verbose
        disp('starting particleDetect() to find all particle centroids and save results in particleDir')
    end

%% Set up for parameters is found in the function below
    pdParams = paramsSetUp(pdParams); %see below for defaults for params




%% ── Main loop over images ────────────────────────────────────────────────
    images  = dir(fullfile(fileParams.topDir, fileParams.imgDir, fileParams.imgReg));
    nFrames = length(images);

    for frame = 1:nFrames
    
        im      = imread(fullfile(images(frame).folder, images(frame).name));
        red     = im(:,:,1);   % photoelastic (force) channel
        green   = im(:,:,2);   % particle shape channel
        blue    = im(:,:,3);   % unused (background)
        
    
        % Suppress green bleed-through (same correction as original PeGS2)
        % green = imsubtract(green, green * 0.05);
        
        % imwrite(green, 'green_test.png');

        %imwrite(red, 'red.png');

        %imwrite(blue, 'blue.png');


        bw_test = green > 15;
        % imwrite(bw_test, 'bw_test.png');

        % ── Binarise ──────────────────────────────────────────────────────────
        switch lower(pdParams.threshMethod)
            case 'adaptive'
                T  = adaptthresh(green, pdParams.adaptSens, ...
                                'ForegroundPolarity', 'bright', ...
                                'NeighborhoodSize',   2*floor(pdParams.adaptNeighbourhood/2)+1);
                bw = imbinarize(green, T);
            case 'otsu'
                bw = imbinarize(green);   % Otsu global threshold
            case 'green_twopass'
            % Coarse pass: Otsu to get approximate particle blobs
            bw_coarse = imfill(imbinarize(channel), 'holes');
            bw_coarse = bwareaopen(bw_coarse, round(pi * pdParams.radiusRange(1)^2 / 4));
            % Dilate coarse mask to capture dark stress-free edge band
            se_d = strel('disk', round(pdParams.radiusRange(2) * 0.15));
            mask = imdilate(bw_coarse, se_d);
            % Fine pass: adaptive threshold, restricted to mask region
            T  = adaptthresh(channel, pdParams.adaptSens, ...
                'ForegroundPolarity', 'bright', ...
                'NeighborhoodSize', 2*floor(pdParams.adaptNeighbourhood/2)+1);
            bw = imbinarize(channel, T);
            bw = (bw | bw_coarse) & mask;   % union inside dilated region
            otherwise
                error('Unknown threshMethod: %s', pdParams.threshMethod);
        end

        % imwrite(bw, 'bw_0.png');
    
        % ── Morphological cleaning ────────────────────────────────────────────
        % Remove small noise blobs (area < pi*rmin^2 / 2 as conservative limit)
        minArea = pi * pdParams.radiusRange(1)^2 / 2;
        bw      = bwareaopen(bw, round(minArea));
    
        % imwrite(bw, 'bw_1.png');

        if pdParams.fillHoles
            bw = imfill(bw, 'holes');
        end
        
        % imwrite(bw, 'bw_2.png');

        % ── Measure blob properties ───────────────────────────────────────────
        stats = regionprops(bw_test, ...
            'Centroid', ...
            'MajorAxisLength', ...
            'MinorAxisLength', ...
            'Orientation', ...
            'Solidity', ...
            'Area', ...
            'BoundingBox');
    
        % ── Filter blobs by radius range and solidity ────────────────────────
        keep = false(numel(stats), 1);
        for k = 1:numel(stats)
            r_eff = (stats(k).MajorAxisLength + stats(k).MinorAxisLength) / 4;
            if r_eff >= pdParams.radiusRange(1) && ...
            r_eff <= pdParams.radiusRange(2) && ...
            stats(k).Solidity >= pdParams.minSolidity
                keep(k) = true;
            end
        end
        stats = stats(keep);

        nParticles = numel(stats);
    
        if nParticles == 0
            warning('Frame %d (%s): no particles found — check radiusRange and threshold.', ...
                frame, images(frame).name);
        end
    
        % ── Collect results ───────────────────────────────────────────────────
        centers = zeros(nParticles, 2);
        radii   = zeros(nParticles, 1);
        a_semi  = zeros(nParticles, 1);   % semi-major axis (pixels)
        b_semi  = zeros(nParticles, 1);   % semi-minor axis (pixels)
        orient  = zeros(nParticles, 1);   % orientation (degrees)
    
        for k = 1:nParticles
            centers(k,:) = stats(k).Centroid;                           % [x, y]
            a_semi(k)    = stats(k).MajorAxisLength / 2;
            b_semi(k)    = stats(k).MinorAxisLength / 2;
            orient(k)    = stats(k).Orientation;
            %radii(k)     = (a_semi(k) + b_semi(k)) / 2;                % effective r
            radii(k)     = min(a_semi(k), b_semi(k));  % conservative r (for edge classification)
        end
    
        % ── Edge classification (identical logic to original) ─────────────────
        edges = zeros(nParticles, 1);
    
        if nParticles > 0 && strcmpi(pdParams.boundaryType, 'rectangle')
            lpos = min(centers(:,1) - radii);
            rpos = max(centers(:,1) + radii);
            upos = max(centers(:,2) + radii);
            bpos = min(centers(:,2) - radii);
    
            edges(centers(:,1) - radii <= lpos + pdParams.dtol)  = -1;  % left
            edges(centers(:,1) + radii >= rpos - pdParams.dtol)  =  1;  % right
            edges(centers(:,2) + radii >= upos - pdParams.dtol)  =  2;  % upper (bottom of image)
            edges(centers(:,2) - radii <= bpos + pdParams.dtol)  = -2;  % lower (top of image)
        end
    
        % ── Verbose: draw ellipses over image ─────────────────────────────────
        if verbose && nParticles > 0
            figure('Name', sprintf('Frame %d — ellipse fit', frame), 'NumberTitle', 'off');
            imshow(green);
            hold on;
    
            for k = 1:nParticles
                drawEllipse(centers(k,1), centers(k,2), a_semi(k), b_semi(k), orient(k), ...
                            'Color', 'cyan', 'LineWidth', 1.5);
    
                % Mark centre
                plot(centers(k,1), centers(k,2), '+', ...
                    'Color', 'yellow', 'MarkerSize', 10, 'LineWidth', 1.5);
    
                % Annotate with numerical values
                label = sprintf('(%.1f, %.1f)\nr=%.1f\na=%.1f b=%.1f\ne=%.2f', ...
                    centers(k,1), centers(k,2), radii(k), a_semi(k), b_semi(k), ...
                    sqrt(1 - (min(a_semi(k),b_semi(k)) / max(a_semi(k),b_semi(k)))^2));
    
                text(centers(k,1) + radii(k)*0.15, centers(k,2) - radii(k)*0.6, ...
                    label, 'Color', 'yellow', 'FontSize', 8, ...
                    'BackgroundColor', [0 0 0 0.4], 'Interpreter', 'none');
    
                % Edge flag
                edgeStr = edgeFlagString(edges(k));
                text(centers(k,1), centers(k,2) + radii(k)*0.7, edgeStr, ...
                    'Color', 'green', 'FontSize', 10, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center');
            end
    
            title(sprintf('%s  —  %d particle(s) detected', ...
                strrep(images(frame).name, '_', '\_'), nParticles));
            hold off;
            drawnow;
        end
    
        % ── Save image with overlays ───────────────────────────────────────────
        if verbose && nParticles > 0
            imfilename = ['EllipseFit_', images(frame).name];
            saveas(gcf, fullfile(fileParams.topDir, fileParams.particleDir, imfilename), 'jpg');
        end
    
        % ── Write centres text file (same format as original) ─────────────────
        particle     = [centers(:,1), centers(:,2), radii, edges];
        txtfilename  = [images(frame).name(1:end-4), '_centers.txt'];
        writematrix(particle, ...
            fullfile(fileParams.topDir, fileParams.particleDir, txtfilename), ...
            'delimiter', ',');
    
        % ── Print per-particle summary to command window ──────────────────────
        if verbose
            fprintf('\n  Frame %d / %d  —  %s\n', frame, nFrames, images(frame).name);
            fprintf('  %-4s  %-9s  %-9s  %-8s  %-8s  %-8s  %-8s  %-5s\n', ...
                '#', 'X (px)', 'Y (px)', 'r_eff', 'a (px)', 'b (px)', 'orient', 'edge');
            fprintf('  %s\n', repmat('-', 1, 62));
            for k = 1:nParticles
                fprintf('  %-4d  %-9.2f  %-9.2f  %-8.2f  %-8.2f  %-8.2f  %-8.1f  %s\n', ...
                    k, centers(k,1), centers(k,2), radii(k), ...
                    a_semi(k), b_semi(k), orient(k), edgeFlagString(edges(k)));
            end
        end
    
    end % end frame loop


%% ── Save parameters ──────────────────────────────────────────────────────
fields = fieldnames(pdParams);
for i = 1:length(fields)
    fileParams.(fields{i}) = pdParams.(fields{i});
end
fileParams.lastimagename = images(frame).name;
fileParams.time          = datetime('now');
 
fields = fieldnames(fileParams);
C      = struct2cell(fileParams);
pdCell = [fields C];
writecell(pdCell, ...
    fullfile(fileParams.topDir, fileParams.particleDir, 'particleDetect_params.txt'), ...
    'Delimiter', 'tab');
 
if verbose
    disp('done with particleDetect_ellipse()');
end
 
out = true;
end % end main function


%% ═══════════════════════════════════════════════════════════════════════
%  Helper: draw a rotated ellipse onto the current axes
%  cx, cy  : centre (pixels, image coords)
%  a, b    : semi-major and semi-minor axes (pixels)
%  phi_deg : orientation angle from regionprops (degrees, CCW from x-axis)
% ════════════════════════════════════════════════════════════════════════
function drawEllipse(cx, cy, a, b, phi_deg, varargin)
    t   = linspace(0, 2*pi, 360);
    phi = deg2rad(phi_deg);
 
    % Parametric ellipse, then rotate by phi
    xe = a * cos(t);
    ye = b * sin(t);
 
    xr = cx + xe * cos(phi) - ye * sin(phi);
    yr = cy - xe * sin(phi) - ye * cos(phi);  % minus: image y increases downward
 
    plot(xr, yr, varargin{:});
end


%% ═══════════════════════════════════════════════════════════════════════
%  Helper: human-readable edge flag
% ════════════════════════════════════════════════════════════════════════
function s = edgeFlagString(flag)
    switch flag
        case  0,  s = 'interior';
        case  1,  s = 'right';
        case -1,  s = 'left';
        case  2,  s = 'upper';
        case -2,  s = 'lower';
        otherwise, s = '?';
    end
end
 
 
%% 

%% defaults for particleDetectModule
function p = paramsSetUp(p)
%classify boundary type
if isfield(p,'boundaryType') == 0
    p.boundaryType = "rectangle";
end

%set radius range
if isfield(p,'radiusRange') == 0
    p.radiusRange = [1000 2000];
end


%classify edge particles with tolerance
if isfield(p,'dtol') == 0
    p.dtol = 10;
end


%sensitivity for Hough
if isfield(p,'sensitivity') == 0
    p.sensitivity = 0.945;
end

% Fill interior holes before fitting (recommended for fringe patterns)
if ~isfield(p, 'fillHoles')
    p.fillHoles = true;
end

% Minimum blob solidity to accept as a particle (0–1)
if ~isfield(p, 'minSolidity')
    p.minSolidity = 0.70;
end

% Thresholding strategy: 'adaptive' | 'otsu'
if ~isfield(p, 'threshMethod')
    p.threshMethod = 'adaptive';
end

% Sensitivity for adaptthresh (ignored when threshMethod is 'otsu')
if ~isfield(p, 'adaptSens')
    p.adaptSens = 0.55;
end

% Neighbourhood for adaptthresh (pixels). 
% Rule of thumb: ~2x expected particle diameter.
if ~isfield(p, 'adaptNeighbourhood')
    p.adaptNeighbourhood = 4000;   % must be odd; will be forced odd automatically
end

% Morphological closing radius (pixels) to bridge dark edge gaps.
% 0 = disabled.
if ~isfield(p, 'closingRadius')
    p.closingRadius = 7;
end

end