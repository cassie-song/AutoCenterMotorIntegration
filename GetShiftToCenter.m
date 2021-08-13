function shift = GetShiftToCenter(image, method_for_centering, micron_per_pixel, motor_angle)
    %   this function calculates the required shift to center the chiplet
    %   required inputs are:
    %   method_for_centering := one from the list {'centroid', 'intersection'}
    %   micron_per_pixel := float, the scale bar, about 0.08 for images taken with 1000 pixel and 100 times lens
    %   motor_angle := float, estimated angle (radian) of motor movement relative to the image axes
    chip_center = FindCenter(image, false, method_for_centering);

    %   calculate new x/y coordinates
    image_center = [fix(length(image)/2), fix(length(image)/2)];
    centroid_to_center = (image_center - chip_center) * micron_per_pixel; % converts the vector unit from pixels to microns

    theta = motor_angle; % estimated angle of motor movement relative to the image axes
    %   solve simultaneous equation for shift in x and y direction along the motor
    delta_x = centroid_to_center(1) * cos(theta) - centroid_to_center(2) * sin(theta);
    delta_y = -1 * centroid_to_center(1) * sin(theta) - centroid_to_center(2) * cos(theta);
    shift = [delta_x, -1 * delta_y, 0] / 1000;
end