function [imName,brightness] = GetImageBrightness()

% Created 8/19/13 by DJ.

disp('Calculating...')

homedir = cd;
cd('/Users/dave/Documents/Data/EEG_TAG/101_samesize_resized');
categories = {'car_side','grand_piano','laptop','schooner'};
nImages = 50;
% Luma: Y = 0.2126 R + 0.7152 G + 0.0722 B
% RGBtoLuma = [0.2126 0.7152 0.0722];

for i=1:numel(categories)
    fprintf('category %s...\n',categories{i});
    for j=1:nImages
        imName{i,j} = sprintf('category_%s_filename_image_%04.f.jpg',categories{i},j);
        foo = imread(imName{i,j});
        if size(foo,3)>1
            foo = rgb2gray(foo);
        end
        brightness(i,j) = mean(foo(:));
    end
end

disp('Plotting...')

% Plot hist
subplot(1,2,1);
imagesc(brightness)
set(gca,'ytick',1:4,'yticklabel',categories);
xlabel('Image #');
title('Mean Image Brightness')
colormap gray

% Plot extreme images
for i=1:numel(categories)
    [lumMin,imMin] = min(brightness(i,:));    
    foo = imread(imName{i,imMin});
    subplot(numel(categories),4,(i-1)*4+3);
%     if size(foo,3)>1
%         foo = rgb2gray(foo);
%     end
    imagesc(foo);
    axis square
    title(show_symbols(sprintf('%s %d, brightness = %g',categories{i},imMin,lumMin)));
    set(gca,'xtick',[]','ytick',[]);
    
    [lumMax,imMax] = max(brightness(i,:));
    foo = imread(imName{i,imMax});
    subplot(numel(categories),4,(i-1)*4+4);
%     if size(foo,3)>1
%         foo = rgb2gray(foo);
%     end
    imagesc(foo);
    axis square
    title(show_symbols(sprintf('%s %d, brightness = %g',categories{i},imMax,lumMax)));
    set(gca,'xtick',[]','ytick',[]);
end

cd(homedir)
disp('Done!')