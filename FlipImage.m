function image = FlipImage(img_orig, toflip, flip_axis)
%   Flips the image about a given the flip_axis when toflip is set to true
%   img_file := .m file; 
%   toflip := boolean; 
%   flip_axis : = 1 or 2
%   returns flipped image 
    
    if toflip
        image = flip(img_orig, flip_axis);
    end
end

