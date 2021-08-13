function results = ReadCharacter(image, hor_angle_range, expected_hor_position, scale, micron_per_pixel)
    BW = edge(image, 'Canny', 0.2);
    
    top_line_info_orig = FindTopHorLine(BW, hor_angle_range, expected_hor_position);
    
    BW_rot = imrotate(BW, top_line_info_orig.top_line_angle-90, 'crop');
    image_rot = imrotate(image, top_line_info_orig.top_line_angle-90, 'crop');
    
%     figure
%     imshow(BW_rot, [])      
    
    top_line_info_rot = FindTopHorLine(BW_rot, [0 5], 'top');   
    left_end_y = top_line_info_rot.top_line(1,2);
    image_2nd_rot = imrotate(image_rot, -1*top_line_info_rot.top_line_angle, 'crop');
    
    [left_bound, width] = FindBoxWidth(BW_rot, micron_per_pixel);
    
    h = 50;
    x = left_bound;
    y = left_end_y - h - 10;
    w = width;
    
%     h = 50;
%     x = fix(chip_center(1)) - 200;
%     y = left_end_y - h - 10;
%     w = 420;
 
    image_crop = image_2nd_rot(y:y+h, x:x+w);
    
%     figure
%     imshow(image_crop, [])
    
    % Step 2 find number region from entire cropped image
    img_size = size(image_crop);

    % find region in y direction
    mean_y = zeros(img_size(1),1);
    for i = 1 : img_size(1)
        mean_y(i) = mean(image_crop(i, :));
    end

    dip_y = min(mean_y);
    threshold_y = dip_y * 1.08; % value can be optimised
    grad_threshold_y = dip_y /img_size(1) * 0.4; % value can be optimised
    
%     figure
%     plot(mean_y)
%     xlabel('pixels along y direction')
%     ylabel('mean value')
%     
%     hold on 
%     yline(threshold_y)
%     
%     figure
%     plot(abs(gradient(mean_y)))
%     xlabel('pixels along y direction')
%     ylabel('absolute gradient')    
%     hold on 
%     yline(grad_threshold_y)


    for i = 2 : img_size(1)
        grad = mean_y(i - 1) - mean_y(i);
        val = mean_y(i);
        if mean_y(i) < threshold_y && grad > grad_threshold_y
            upper_bound = i-1;
            break
        end
    end

    for i = flip(1 : img_size(1) - 1)
        grad = mean_y(i + 1) - mean_y(i);
        if mean_y(i) < threshold_y &&  grad > grad_threshold_y
            lower_bound = i + 1;
            break
        end
    end
    
    % find region in x direction
    % identify gaps
    x = 1:img_size(2);
    mean_x = zeros(1,img_size(2));
    for i = 1 : img_size(2)
        mean_x(i) = mean(image_crop(upper_bound:lower_bound, i));
    end

    slope = polyfit(1:img_size(2), mean_x, 1);
    subt = x * slope(1);
    mean_x_sub = mean_x - subt;
    
%     figure
%     plot(mean_x_sub)
%     xlabel('pixels along x direction')
%     ylabel('mean value')
    
    peak_x = max(mean_x_sub);
    threshold = peak_x * 0.9;
    
%     hold on 
%     yline(threshold)
%     
%     figure
%     plot(abs(gradient(mean_x_sub)))
%     xlabel('pixels along x direction')
%     ylabel('absolute gradient')    

    grad_x = gradient(mean_x_sub);
    threshold_grad = peak_x / img_size(2) * 3.5;
%     hold on 
%     yline(threshold_grad)

    N_px = fix(img_size(2) * 0.05) ; % number of pixels for a gap
    
    gap_start_points = [];
    n_selected = 0;
    for i = 1 : img_size(2) - N_px
        abs_grad_mean = mean(abs(grad_x(i:i + N_px)));
        mean_x_Npx = mean(mean_x_sub(i : i + N_px));
        if all(mean_x_sub(i : i + N_px) > threshold) && abs_grad_mean < threshold_grad
            n_selected = n_selected + 1;
            gap_start_points(n_selected) = i;
        end
    end

    % identify word bounding boxes
    n = 1;
    word_left = [];
    word_right = [];

    for i = 1 : max(size(gap_start_points))-1
        if gap_start_points(i) ~= gap_start_points(i + 1) - 1
            if gap_start_points(i) + N_px < gap_start_points(i + 1)
                word_left(n) = gap_start_points(i) + N_px;
                word_right(n) = gap_start_points(i + 1);
                n = n + 1;
            end
        end
    end

    % identify if two numbers are only separated by a dot

    for i = 1 : max(size(word_left)) - 1
        word_length_1 = word_right(i) - word_left(i);
        gap = word_left(i + 1) - word_right(i);
        word_length_2 = word_right(i + 1) - word_left(i + 1);
        if word_length_1 < gap && word_length_2 < gap
            word_right(i) = [];
            word_left(i + 1) = [];
            break
        end
    end
    
%     figure
%     imshow(image_crop,[])

%     for i = 1 : max(size(word_left))
%         x = word_left(i);   
%         w = word_right(i) - word_left(i);
%         rectangle('Position',[x upper_bound w lower_bound - upper_bound], 'EdgeColor', 'red')
%     end
    
    % Select the region

    if max(size(word_left)) == 3
        img_cSep = image_crop(upper_bound : lower_bound, word_left(1) : word_right(1));
        % crop the image to obtain the numbers
        word_left(2) = word_left(2) + fix((word_right(2) - word_left(2))/37 * 16);
        img_w = image_crop(upper_bound : lower_bound, word_left(2): word_right(2));
        aspect_ratio = (word_right(3) - word_left(3))/(lower_bound - upper_bound);
        threshold = 0.7;
        if abs(aspect_ratio - 29/7) < threshold
            word_left(3) = word_left(3) + fix((word_right(3) - word_left(3))/29 * 16);
        elseif abs(aspect_ratio - 29/7) > threshold
            word_left(3) = word_left(3) + fix((word_right(3) - word_left(3))/37 * 16);
        end
        img_d = image_crop(upper_bound : lower_bound, word_left(3): word_right(3));
        img_set = {'cSep', img_cSep; 'w', img_w; 'd', img_d};
    else
        disp('something went wrong with identifying the words')
        results = NaN;
        return
    end
    
%     for i = 1 : max(size(word_left))
%         x = word_left(i);   
%         w = word_right(i) - word_left(i);
%         rectangle('Position',[x upper_bound w lower_bound - upper_bound], 'EdgeColor', 'red')
%     end
    
    % Step 3 recognise characters in post-rotated binary images
    
    % - Increase the number of pixels in the image by scale
    results = cell(3, 2);
    for i = 1 : max(size(word_left))
        type = img_set{i, 1};
        region = img_set{i, 2};
        [numbers, max_simval] = IdentifyNumber(region, type, scale);
        results{i, 1} = numbers;
        results{i, 2} = max_simval;
    end  
    
end

