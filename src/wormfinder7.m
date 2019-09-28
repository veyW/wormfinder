%%%%%%%%%%%%%%%%
%%%WORMFINDER%%%
%%%%%%%%%%%%%%%%

%This script is designed to detect worms of different stages (brightfield
%images of liquid cultures in 96 well plates) and return their body area and length. 
function wf = wormfinder7(mypath)
%specify directory with images
path_to_images=mypath;
%path_to_images='C:/Users/Olga/Desktop/Code/images/MATRIX/48H_MAT1/';
files = dir(strcat(path_to_images, '/*.png'));

%make output directories if none exists
if ~exist(strcat(path_to_images, '/results'),'dir') mkdir(strcat(path_to_images, '/results')); end
if ~exist(strcat(path_to_images, '/results_txt'),'dir') mkdir(strcat(path_to_images, '/results_txt')); end
dir2 = strcat(path_to_images, '/results');
dir3 = strcat(path_to_images, '/results_txt');


for file = files'
    
message = sprintf('Analyzing image %s ...', file.name)

full_path = fullfile(path_to_images, file.name);

image_w=imread(full_path);
%image_w=imread('C:/Users/Olga/Desktop/Code/images/plate12/1/scan_Plate_TM_p00_0_A01f00d0.png');

%modify this line for monochrome image
image_gray=rgb2gray(image_w);
%image_gray=image_w;

%mask the image based on V hsv component
minValue=0;
maxValue=0.35;
%modify this line for monochrome image
%v = mat2gray(image_w(:,:,2));
v = mat2gray(image_w);
valueMask = v > minValue & v < maxValue;

%close holes in the mask
se = strel('disk',50);
valueMask = imdilate(valueMask, se);
se = strel('disk',50);
valueMask = imdilate(valueMask, se);
%imshow(valueMask);
%pick the largest object in the mask
%valueMask = bwareafilt(valueMask, 1, 'largest');
valueMask = imerode(valueMask, se);
valueMask = imerode(valueMask, se);
valueMask = imerode(valueMask, se);
valueMask=imcomplement(valueMask);
valueMask = bwareafilt(valueMask, 1, 'largest');
valueMask=imfill(valueMask, 'holes');
%imshow(valueMask);
%apply mask to the gray image
image_m=immultiply(image_gray, valueMask);


%segment worms by texture filter
E = entropyfilt(image_m);
Eim = mat2gray(E);
%threshold
bw = im2bw(Eim,0.7);

bwm = bwareaopen(bw, 100);
bwm(imcomplement(valueMask))=255;
se90 = strel('line', 3, 90);
se0 = strel('line', 3, 0);
BWsdil = imdilate(bwm, [se90 se0]);
%figure, imshow(BWsdil), title('dilated gradient mask');
bw1=BWsdil-bwareaopen(BWsdil, 100000);
%imshow(bw1);

BWdfill = imfill(bw1, 'holes');
%figure, imshow(BWdfill);
seD = strel('diamond',1);
BWfinal = imerode(BWdfill,[se90 se0]);
BWfinal = imerode(BWfinal,[se90 se0]);
BWfinal=im2bw(BWfinal);
BWfinal=bwareaopen(BWfinal, 500);
%remove boundary objects
BWfinal=imclearborder(BWfinal);
%figure, imshow(BWfinal), title('segmented image');

skeletons=bwmorph(BWfinal, 'thin', Inf);

skeletons_pruned = bwmorph(skeletons, 'spur', 15);
%skeletons_pruned = bwmorph(skeletons_pruned, 'spur');

[labels, num_labels] = bwlabel(skeletons_pruned);

full_path1 = fullfile(dir2, sprintf('%s_skeletons.jpg', file.name));
imwrite(skeletons_pruned, full_path1,'jpg', 'Quality', 100);
%imshow(x);
%hold on;
j=[];
for i = 1:num_labels
    %// Find the ith object mask
    mask = labels == i;
    %// Find if worm has branching points
    br=bwmorph(mask,'branchpoints');
    br = sum(br(:));
     %// If area is less than a threshold
    %// don't process this object
    if br > 0
        continue;
    end
    %cut-off for minimal skeleton length
    if bwarea(mask)<20
        continue;
    end
        j=[j i];
end


%subtr=imsubtract(BWfinal, skeletons_pruned);
%remove branching worms
[lab, num_lab] = bwlabel(BWfinal);
%straight_skels = ismember(labels, j);
straight = ismember(lab, j);

[labeledImage, num_image] = bwlabel(straight);     % Label each blob so we can make measurements of it

skelExport = regionprops(bwmorph(labeledImage, 'thin', Inf), 'Area');
% Let's assign each blob a different color to visually show the user the distinct blobs.
coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
% coloredLabels is an RGB image.  We could have applied a colormap instead (but only with R2014b and later)
%imshow(coloredLabels);
% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
blobMeasurements = regionprops(labeledImage, 'all');
numberOfBlobs = size(blobMeasurements, 1);
blobExport = regionprops(labeledImage, 'Area', 'Perimeter', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength');
skelExport = regionprops(bwmorph(labeledImage, 'thin', Inf), 'Area');

% Plot the borders of all the worms on the original grayscale image using the coordinates returned by bwboundaries.
%{
imshow(image_m);
axis image;
hold on;
boundaries = bwboundaries(straight);
numberOfBoundaries = size(boundaries, 1);
for k = 1 : numberOfBoundaries
	thisBoundary = boundaries{k};
	plot(thisBoundary(:,2), thisBoundary(:,1), 'g', 'LineWidth', 2);
end
hold off;
%}

%filter objects by shape (eccentricity) and size
allBlobEcc = [blobMeasurements.Eccentricity];
allBlobAreas = [blobMeasurements.Area];
%do not change this parameter for photos with levamizole circular worms
allowableEccIndexes = (allBlobEcc >= 0.8) ;
%500-2000
%1500-3500
%allowableAreaIndexes = (allBlobAreas > 2000) & (allBlobAreas <5000);
med = median(allBlobAreas);
md=mad(allBlobAreas, 1);
med_length = median([skelExport.Area]);
%ratio = [blobExport.Area]./[skelExport.Area];
%allowableAreaIndexes = (allBlobAreas > med-md*2) & (allBlobAreas < med+md*2) & (ratio<20);
allowableAreaIndexes = (allBlobAreas > med/10)& (allBlobAreas <= med*10);
%allowableAreaIndexes = (allBlobAreas >= med/2) & (allBlobAreas <= med*2);
%get actual indexes
keeperIndexes = find(allowableEccIndexes & allowableAreaIndexes);
% Extract only those blobs that meet our criteria (image)
keeperBlobsImage = ismember(labeledImage, keeperIndexes);
% Re-label with only the keeper blobs kept.
labeledDimeImage = bwlabel(keeperBlobsImage, 8);  % Label each blob so we can make measurements of it
coloredDimeLabels = label2rgb (labeledDimeImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
%imshow(coloredDimeLabels, []);
full_path1 = fullfile(dir2, sprintf('%s_segmentation2.jpg', file.name));
imwrite(coloredDimeLabels, full_path1,'jpg', 'Quality', 100);

%{
axis image;

imshow(image_m);
axis image;
hold on;
boundaries = bwboundaries(straight);
boundaries = boundaries(keeperIndexes);
numberOfBoundaries = size(boundaries, 1);
for k = 1 : numberOfBoundaries
	thisBoundary = boundaries{k};
	plot(thisBoundary(:,2), thisBoundary(:,1), 'g', 'LineWidth', 2);
end
hold off;
%}

%write the outline of identified objects
%draw perimeter
BWoutline = imdilate(bwperim(labeledDimeImage), strel('disk', 1));
Segout = image_m;
Segout(BWoutline) = 0;
%imshow(Segout);
%write segmentation image
full_path1 = fullfile(dir2, sprintf('%s_segmentation.jpg', file.name));
imwrite(Segout, full_path1,'jpg', 'Quality', 100);

%export
blobExport1 = blobExport(keeperIndexes);
skelExport1 = skelExport(keeperIndexes);
[blobExport1(:).Length] = deal(skelExport1.Area);
%[blobExport1(:).Ratio] = deal([ratio']);
%writetable(struct2table(blobExport1), 'text.txt', 'Delimiter', '\t');

%%%%
%OUTPUT
full_path2 = fullfile(dir3, sprintf('%s.txt', file.name));
%dlmwrite(full_path2, struct2cell(blobExport1), '-append', 'delimiter', '\t' );
if ~isempty(blobExport1) 
writetable(struct2table(blobExport1),full_path2,'Delimiter','\t','WriteRowNames',true);
end
%dlmwrite(full_path2, struct2table(blobExport1),'delimiter', '\t');
%clear all;

end
message='All done!'
end