function shiftinfo = ShiftToCenter(motor_obj, im_obj,  toflip, flip_axis, method_for_centering, micron_per_pixel, estimated_motor_angle, max_shift_no)
% Move the motor to center the chiplet until the next required shift is below a certain threshold
    shiftinfo.shifted = false;
    shift_no = 1;
    previous_shift = [0, 0, 0];
    orig_pos = motor_obj.position;
    while shift_no <= max_shift_no
        image_orig = im_obj.snapImage();
        image = FlipImage(image_orig, toflip, flip_axis);
        shift = GetShiftToCenter(image, method_for_centering, micron_per_pixel, estimated_motor_angle);
        position = motor_obj.position;
        target_pos = shift + position;
        
        total_shift = target_pos - orig_pos;
        
        if norm(total_shift) > 0.03
            shift = GetShiftToCenter(image, 'centroid', micron_per_pixel, estimated_motor_angle);
            position = motor_obj.position;
            target_pos = shift + position;
        
            total_shift = target_pos - orig_pos;
        end
        delta_shift = shift - previous_shift;
        if norm(total_shift) > 0.03
            target_pos = orig_pos;
            delta_shift = [0, 0, 0];
        end
%         position = motor_obj.position;
%         target_pos = shift + position;
%         motor_obj.moveto(target_pos);
        if norm(delta_shift) <= 0.002          
            shiftinfo.shifted = true;
            shiftinfo.shiftno = shift_no;
            break
        else
            motor_obj.moveto(target_pos);
            previous_shift = shift;
        end
        shift_no = shift_no + 1;     
    end
    
    if shift_no == max_shift_no
        shiftinfo.max_shift_not_reached = true;
    else
        shiftinfo.max_shift_not_reached = false;
    end
    shiftinfo.shifted = true;
    shiftinfo.shiftno = shift_no;
end

