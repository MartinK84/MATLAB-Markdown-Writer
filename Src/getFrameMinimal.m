function [Frame, Bounds] = getFrameMinimal(handle)
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
    Bounds = [left,top,right,bottom];
    
    % return minimal frame
    Frame = img.cdata(top:bottom, left:right, :);
end