%% Instantiate motor and imaging objects, initialise motor
serialNo = '70177684';
% travel = [0 8];
motor_obj = motor();
motor_obj.connect(serialNo);
% motor_obj.home();
% motor_obj.moveto([3.945541, 4.389518, 4.821693]);
im_obj = Imaging.umanager.Camera.instance();
%% Define variables
toflip = true;
flip_axis = 1;
% Autofocus variable
z_scan_range = 0.05; % mm
z_scan_step_size = 0.001;
% shift to center variable
method_for_centering = 'intersection';
micron_per_pixel = 0.08;
estimated_motor_angle = pi / 4;
max_shift_no = 5;
% Character recognition
hor_angle_range = [0 45];
expected_hor_position = 'top';
scale = 50;

%% Move the stage to scan the entire sample
chip_sep = 0.063;
nrows = 8;
ncols = 2;
% results = cell(nrows, ncols);
imgs = cell(nrows, ncols);
for i = 1 : ncols
    if rem(i, 2) == 1
        rows_scan = 1 : nrows;
        scan_dir = 1;
    elseif rem(i, 2) == 0
        rows_scan = flip(1 : nrows, 2);
        scan_dir = -1;
    end
    for j = rows_scan
        orig_pos = motor_obj.position;
        disp(orig_pos)
        opt_z = AutoFocus(im_obj, motor_obj, orig_pos, z_scan_range, z_scan_step_size);
        shiftinfo = ShiftToCenter(motor_obj, im_obj, toflip, flip_axis, method_for_centering, micron_per_pixel, estimated_motor_angle, max_shift_no);
        current_pos = motor_obj.position;
        image_orig = im_obj.snapImage();
        image = FlipImage(image_orig, toflip, flip_axis);
        imgs{j, i} = image;
        try
            results{j, i} = ReadCharacter(image, hor_angle_range, expected_hor_position, scale, micron_per_pixel);
        catch
            results{j, i} = 'unsuccessful';
        end
        
        if (j ~= nrows && scan_dir == 1) || (j ~= 1 && scan_dir == -1)
            target_pos = [current_pos(1), current_pos(2) + chip_sep * scan_dir, current_pos(3)];
            motor_obj.moveto(target_pos)
        else
            disp('end of column reached')
        end
    end
    if i ~= ncols
        target_pos = [current_pos(1) + chip_sep, current_pos(2), current_pos(3)];
        motor_obj.moveto(target_pos)
    else
        disp('end of travel')
    end
    
end

save('scan_test0807_8_t_2_4.mat', 'imgs')
save('character_test0807_8_t_2_4.mat', 'results')

%% AutoFocus the image
orig_pos = motor_obj.position;
z_scan_range = 0.1; % mm
z_scan_step_size = 0.001;

opt_z = AutoFocus(im_obj, motor_obj, orig_pos, z_scan_range, z_scan_step_size);
%% Shift to center the image and recognise characters in image
shiftinfo = ShiftToCenter(motor_obj, im_obj, toflip, flip_axis, method_for_centering, micron_per_pixel, estimated_motor_angle, max_shift_no);

if shiftinfo.shifted && ~shiftinfo.max_shift_not_reached
    image_orig = im_obj.snapImage();
    image = FlipImage(image_orig, toflip, flip_axis);
    try
        results = ReadCharacter(image, hor_angle_range, expected_hor_position, scale, micron_per_pixel);
    catch
        results = 'unsuccessful';
    end
else 
    error('shift not successful')
end
%%
motor_obj.disconnect()
%%
clear
clc

