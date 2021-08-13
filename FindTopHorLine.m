function top_line_info = FindTopHorLine(BW, hor_angle_range, expected_hor_position)
% Find the angle of rotation in degrees and identify the top horizontal line (top_ine)
% BW := binary image
% hor_angle_range := (array) the expected range for the inclination angle of the chiplet, in degrees
% expected_hor_position := one of the list {'top', 'bottom'}

    [H,theta,rho] = hough(BW);
    P = houghpeaks(H, 20, 'threshold', ceil(0.1 * max(H(:))));
    lines = houghlines(BW, theta, rho, P, 'FillGap', 20, 'MinLength', 150);
%     figure
%     imshow(BW,[])

    hor_lines = {};
    n_lines = 1;
    top_y_pos = length(BW)/2;
    for k = 1:length(lines)
       xy = [lines(k).point1; lines(k).point2];
%        hold on
%        plot(xy(:, 1), xy(:, 2), 'LineWidth',2,'Color','blue')
       
       angle = 180 / pi * atan(abs((lines(k).point1(2) - lines(k).point2(2))/(lines(k).point1(1) - lines(k).point2(1))));

       if angle <= max(hor_angle_range) && angle >= min(hor_angle_range)
           hor_lines{n_lines} = xy;       
           n_lines = n_lines + 1;
           
           if strcmp(expected_hor_position, 'top')
               if lines(k).point1(2) < length(BW)/2 && lines(k).point1(2) < top_y_pos
                   top_line_info.top_line = xy;
                   top_line_info.top_line_angle = angle;
                   top_y_pos = lines(k).point1(2);
               end
           elseif strcmp(expected_hor_position, 'bottom')
               if lines(k).point1(2) > length(BW)/2 && lines(k).point1(2) > top_y_pos
                   top_line_info.top_line = xy;
                   top_line_info.top_line_angle = angle;
                   top_y_pos = lines(k).point1(2);
               end
           else
               error('Expected Horizontal Line Position Not Recognised')
           end
       end   
    end
    
%     plot(top_line_info.top_line(:, 1), top_line_info.top_line(:, 2),'LineWidth', 2, 'Color', 'red')
end

