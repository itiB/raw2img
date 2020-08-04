% example to imshow image taken by iPhone or iPad ... in DNG(RAW) Format

file = 'Image/sample1.dng';

% not work, needs to decomplessed by adobeDNGconverter
% file = 'Image/sample1_jpeg_compressed.dng';

image = dng2img(file);

imagesc(uint8(image), [0 255])