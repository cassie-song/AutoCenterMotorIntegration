function opt_z_pos = AutoFocus(im_obj, motor_obj, orig_pos, z_scan_range, z_scan_step_size)
% Find the z position when the image is focused
    found = false;
    imgs = GetImagesInOneDir(im_obj, motor_obj, orig_pos, z_scan_range, z_scan_step_size);
    sharpness = FindMaxSharpness (imgs);
    for z_pos = flip(orig_pos(3) - z_scan_range/2 : z_scan_step_size : orig_pos(3) + z_scan_range/2, 2)
        motor_obj.moveto([orig_pos(1), orig_pos(2), z_pos])
        img = im_obj.snapImage();
        f = fft2(img);
        s = sum(sum(sqrt(imag(f).^2+real(f).^2)));
        if (sharpness - s)/10^10 < 0.2 
            opt_z_pos = z_pos;
            found = true;
            break
        end
    end
    if found == false
        error('Focus not found')
    end
end

function imgs = GetImagesInOneDir(im_obj, motor_obj, orig_pos, z_scan_range, z_scan_step_size)
    % Collect images for sharpness measurement
    orig_x = orig_pos(1);
    orig_y = orig_pos(2);
    orig_z = orig_pos(3);
    z_scan_bounds = [orig_z - z_scan_range/2, orig_z + z_scan_range/2];
    imgs = cell(fix(z_scan_range/z_scan_step_size), 1);
    n_img = 1;
    for z_pos = z_scan_bounds(1) : z_scan_step_size : z_scan_bounds(2)
        target_pos = [orig_x, orig_y, z_pos];
        motor_obj.moveto(target_pos)
        imgs{n_img} = im_obj.snapImage();
        n_img = n_img + 1;
    end
end

function sharpness = FindMaxSharpness (imgs)
% Find the maximum sharpness from a set of images
    s = zeros(1, length(imgs));
    for i = 1 : length(imgs)
        img = imgs{i};
        f = fft2(img);
        s(i) = sum(sum(sqrt(imag(f).^2+real(f).^2))); 
    end
    sharpness = max(s);
end

