function chip_center = FindCenter(image, isBW, method)
% Find the chiplet center
% isBW := Boolean, true if input image is binary
% method := {'centroid', 'intersection'}
% Returns the coordinate of the chiplet center  
%     figure
%     imshow(image, [])
    if ~isBW
        BW_edge = edge(image, 'Canny', 0.3);
    else
        BW_edge = image;
    end

    se = strel('rectangle', [30, 30]);
    BW_dilate = imdilate(BW_edge, se);

    BW2 = bwareafilt(BW_dilate,1);
%     imshow(BW2,[])

    stats = regionprops(BW2, 'Extrema');
%     hold on    
%     scatter(stats.Extrema(:,1), stats.Extrema(:,2), 'green', 'd', 'filled')
    if strcmp(method, 'intersection')
        %   Obtain four corner points for center estimation
        point1 = (stats.Extrema(1, :) + stats.Extrema(2, :))/2;
        point2 = (stats.Extrema(3, :) + stats.Extrema(4, :))/2;
        point3 = (stats.Extrema(5, :) + stats.Extrema(6, :))/2;
        point4 = (stats.Extrema(7, :) + stats.Extrema(8, :))/2;
        points = [point1; point2; point3; point4];    
%         hold on
%         scatter(points(:,1), points(:,2), 'filled')
        m1 = (points(3, 2) - points(1, 2)) / (points(3, 1) - points(1, 1));
        m2 = (points(4, 2) - points(2, 2)) / (points(4, 1) - points(2, 1));
        c1 = points(1, 2) - m1 * points(1, 1);
        c2 = points(2, 2) - m2 * points(2, 1);
        center_x = (c2 - c1) / (m1 -m2);
        center_y = m1 * center_x + c1;
        chip_center = [center_x, center_y];        
    elseif strcmp(method, 'centroid')
        chip_center = [mean(stats.Extrema(:, 1)), mean(stats.Extrema(:, 2))];
    else
        error('Method for centering is not recognised!')
    end
%     hold on
%     scatter(chip_center(1), chip_center(2), 'filled')
end

