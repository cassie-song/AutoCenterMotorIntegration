function [left_bound, width] = FindBoxWidth(BW_edge, micron_per_pixel)
% Find the box left bound and width
%     figure
%     imshow(BW_edge, [])

    se = strel('rectangle', [30, 30]);
    BW_dilate = imdilate(BW_edge, se);

    BW2 = bwareafilt(BW_dilate,1);
%     imshow(BW2,[])

    stats = regionprops(BW2, 'Extrema');
%     hold on    
%     scatter(stats.Extrema(:,1), stats.Extrema(:,2), 'green', 'd', 'filled')
    %   Obtain four corner points for center estimation
    point1 = (stats.Extrema(1, :) + stats.Extrema(2, :))/2;
    point2 = (stats.Extrema(3, :) + stats.Extrema(4, :))/2;
    point3 = (stats.Extrema(5, :) + stats.Extrema(6, :))/2;
    point4 = (stats.Extrema(7, :) + stats.Extrema(8, :))/2;
    points = [point1; point2; point3; point4];    
%     hold on
%     scatter(points(:,1), points(:,2), 'filled')
    
    chip_center = [mean(stats.Extrema(:, 1)), mean(stats.Extrema(:, 2))];
%     scatter(chip_center(1), chip_center(2), 'filled')
    x_difference = [];
    for i = 1 : 3
        for j = i : 4
            x_difference(end+1) = abs(points(i, 1) - points(j, 1));
        end
    end
    chip_width = max(x_difference);
    chip_width_micron = chip_width * micron_per_pixel;
    disp(chip_width_micron)
    
    if chip_width_micron - 39 > 10
        width = 500;
        left_bound = fix(chip_center(1)) - 300;
    elseif 39 - chip_width_micron > 4
        width = 420;
        left_bound = fix(chip_center(1)) - 120;
    else
        width = 420;
        left_bound = fix(chip_center(1)) - 200;
    end
end

