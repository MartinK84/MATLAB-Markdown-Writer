function [Frame, Bounds] = getFrameMinimal(handle, border)
    if (nargin < 2)
        border = 0;
    end

    % get screenshot
    img = getframe(handle);
    
    % get mask
    colorSum = sum(double(img.cdata),3);
    
    % projections
    projX = sum(colorSum,1);
    projY = sum(colorSum,2);
    
    % find index where projections change    
    left = find(diff(projX) ~= 0, 1);
    top = find(diff(projY) ~= 0, 1);
    right = length(projX) - find(diff(flip(projX)) ~= 0, 1);
    bottom = length(projY) - find(diff(flip(projY)) ~= 0, 1);    
    
    left = max(1, left - border);
    top = max(1, top - border);
    right = min(size(img.cdata,2), right + border);
    bottom = min(size(img.cdata,1), bottom + border);
    
    Bounds = [left,top,right,bottom];
    
    % return minimal frame
    Frame = img.cdata(top:bottom, left:right, :);
end