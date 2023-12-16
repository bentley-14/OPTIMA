%% 
tic
% Selection
[file,path] = uigetfile('*.svs');
drg_whole = imread([path,file]);
selection = readPoints(drg_whole,2);
drg = drg_whole(selection(2,1):selection(2,2),selection(1,1):selection(1,2),1:3);
drg_number = input("DRG_?: "); % Select DRG Number

%Preprocessing
grayim = rgb2gray(drg); % Grayscale imakge

noisereduc = imgaussfilt(grayim,2.5); % Reduce Noise in Image

noisereduc_con = adapthisteq(noisereduc); % Adjust Contrast

sharpened = locallapfilt(noisereduc_con, 0.4, 0.6); % Sharpen Borders

sharpened_expos = imadd(sharpened,-50); % Brighten Image

% Three Edge Filters with different threshold values and sensitivities
BW1 = edge(sharpened_expos, 'canny',[0.01 0.35]);
[centers, radii] = imfindcircles(BW1,[13 100],'ObjectPolarity','bright');

BW2 = edge(rgb2gray(drg),'canny',[0.01 0.2],1);
[centers2, radii2] = imfindcircles(BW2,[13 100],'ObjectPolarity','bright', "EdgeThreshold",0.26, "Sensitivity",0.855);

BW3 = edge(sharpened_expos,'canny',[0.01 0.35]);
[centers3, radii3] = imfindcircles(BW3,[13 100],'ObjectPolarity','bright', "EdgeThreshold",0.25, "Sensitivity",0.865);

centers3 = [centers3; centers2];
radii3 = [radii3; radii2];

% [centers, radii] = imfindcircles(BW2,[13 100],'ObjectPolarity','bright');
% [centers2, radii2] = imfindcircles(BW2,[13 100],'ObjectPolarity','bright', "EdgeThreshold",0.26, "Sensitivity",0.855);
% [centers3, radii3] = imfindcircles(BW2,[13 100],'ObjectPolarity','bright', "EdgeThreshold",0.26, "Sensitivity",0.86);
% 
% figure(7)
% imshow(drg);
% hold on
% viscircles(centers,radii, 'EdgeColor','b');
% hold off
% 
% figure(8)
% imshow(drg);
% hold on
% viscircles(centers2,radii2, 'EdgeColor','r');
% hold off
% 
% figure(9)
% imshow(drg);
% hold on
% viscircles(centers3,radii3, 'EdgeColor','g');
% hold off

% Compare all different centers found in lower threshold filters to select
% unique values
diff_cent = centers3(~all(ismembertol(centers3, centers, .01, 'ByRows', true), 2),:);
diff_rad = radii3(~all(ismembertol(centers3, centers, .01, 'ByRows', true), 2));

% Visually Vote on which circles are neurons and which are not
index = [];

for i=1:length(diff_cent)
    imshow(drg)
    hold on
    viscircles(diff_cent(i,:),diff_rad(i), 'EdgeColor','r');
    decision = waitforbuttonpress;
    if decision == 0
        index = [index; 1];
    else
        index = [index; 0];
    end
end

%close(1);

% Logically index cells that were chosen as yes
y_diff_cent = diff_cent(logical(index),:);
y_diff_rad = diff_rad(logical(index));

% Concatenate high threshold selections with voting procedure selections
total_cent = [centers; y_diff_cent];
total_rad = [radii; y_diff_rad];

% Display Figure with occluded neurons
figure(2)
imshow(drg);
hold on
scatter(total_cent(:, 1), total_cent(:, 2), (total_rad).^2, 'filled', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'w');
scattered = gcf;
hold off

exportgraphics(scattered,'scattered.tiff','Resolution',1000)
scattered2 = imread("scattered.tiff");
pts=readPoints(scattered2,100);
pts = transpose(pts);
figure(3)
imshow(scattered2)
hold on
scatter(pts(:,1),pts(:,2),100,'filled','MarkerFaceColor','w','MarkerEdgeColor','w');
hold off

toc

% Save File 
savefile = input("Would you like to save this image?: Y/N ");
if savefile == "Y"
    f = gcf;
    outputPath = fullfile('occluded_'+ drg_number + '.tiff');
    exportgraphics(f,outputPath,'Resolution',1000)
    delete('scattered.tiff')
    close all
    clear
else
    close all;
    delete('scattered.tiff')
    clear
end