% input is the post-rotated image and the expected type of label, i.e.
% cSep/w/d, and the scale for image enlarging
function [numbers, max_simval] = IdentifyNumber(region, type, scale)

    % determine the size of normalised image according to the length of the label
    img_size = size(region);

    threshold = 0.5; % aspect ratio threshold for differentiating number with different lengths

    if strcmp(type, 'd')
        if 21/7 - img_size(2)/img_size(1) > threshold
            height = 7;
            width = 13;
        elseif abs(img_size(2)/img_size(1) - 21/7) < threshold
            height = 7;
            width = 21;
        end
    elseif strcmp(type, 'w')
        height = 7;
        width = 21;
    elseif strcmp(type, 'cSep')
        if abs(img_size(2)/img_size(1) - 5/7) < threshold
            height = 7;
            width = 5;
        elseif img_size(2)/img_size(1) - 5/7 > threshold
            height = 7;
            width = 21;
        end
    end

    img2 = imresize(region,[height*scale width*scale]); % resize image
    imgGray = img2; % change to gray scale image

    matrices = gen_matrices({type}, scale); % generate the full set of reference matrices

    % select the label that agrees most well with the image
    index = 0;
    max_simval = -0.5;
    % simval_list = [];
    % threshold = 0.01;
    str_list = gen_str_list(type);
    for i = 1: length(matrices)
        matrix = matrices{i,1};
        ref_matrix = im2uint8(matrices{i,1});
        if size(imgGray) == size(ref_matrix)
            simval = ssim(double(imgGray), double(ref_matrix));
            simval_list(i) = simval; 
            if simval > max_simval
                
                max_simval = simval;
                index = i;
                disp(strcat('A similar character recognized as ', ' ', str_list(index), ' with structural similarity of ', ' ', num2str(simval)))

    %             n_selected = n_selected + 1;
    %             index(n_selected) = i;        
    %             simval_list(n_selected) = simval;       
%                 figure
%                 imshowpair(double(imgGray), ref_matrix,'montage');
            end    
        end
    end
     str_list = gen_str_list(type);
     numbers = str_list(index);
end

%%
function elements = get_elements(str)
    % - Store the matrices for numbers
    % 0 is black, 1 is white
    number_0 = [1 0 0 0 1; 0 1 1 1 0; 0 1 1 0 0; 0 1 0 1 0; 0 0 1 1 0; 0 1 1 1 0; 1 0 0 0 1];
    number_1 = [1 1 0 1 1; 1 0 0 1 1; 1 1 0 1 1; 1 1 0 1 1; 1 1 0 1 1; 1 1 0 1 1; 1 0 0 0 1];
    number_2 = [1 0 0 0 1; 0 1 1 1 0; 1 1 1 1 0; 1 1 1 0 1; 1 0 0 1 1; 0 1 1 1 1; 0 0 0 0 0];
    number_3 = [0 0 0 0 1; 1 1 1 1 0; 1 1 1 1 0; 1 0 0 0 1; 1 1 1 1 0; 1 1 1 1 0; 0 0 0 0 1];
    number_4 = [1 1 0 0 1; 1 0 1 0 1; 1 0 1 0 1; 0 1 1 0 1; 0 0 0 0 0; 1 1 1 0 1; 1 1 1 0 1];
    number_5 = [0 0 0 0 0; 0 1 1 1 1; 0 1 1 1 1; 0 0 0 0 1; 1 1 1 1 0; 1 1 1 1 0; 0 0 0 0 1];
    number_6 = [1 0 0 0 1; 0 1 1 1 1; 0 1 1 1 1; 0 0 0 0 1; 0 1 1 1 0; 0 1 1 1 0; 1 0 0 0 1];
    number_7 = [0 0 0 0 0; 1 1 1 1 0; 1 1 1 1 0; 1 1 1 0 1; 1 1 0 1 1; 1 1 0 1 1; 1 1 0 1 1];
    number_8 = [1 0 0 0 1; 0 1 1 1 0; 0 1 1 1 0; 1 0 0 0 1; 0 1 1 1 0; 0 1 1 1 0; 1 0 0 0 1];
    number_9 = [1 0 0 0 1; 0 1 1 1 0; 0 1 1 1 0; 1 0 0 0 0; 1 1 1 1 0; 1 1 1 1 0; 1 0 0 0 1];
    dot = [1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 0 1 1];
    if strcmp(str, 'cSep 2.5')
        elements = {number_2; dot; number_5};
    elseif strcmp(str, 'cSep 3')
        elements = {number_3};
    elseif strcmp(str, 'cSep 3.5')
        elements = {number_3; dot; number_5};
    elseif strcmp(str, 'w = 240')
        elements = {number_2; number_4; number_0};
    elseif strcmp(str, 'w = 245')
        elements = {number_2; number_4; number_5};
    elseif strcmp(str, 'w = 250')
        elements = {number_2; number_5; number_0};
    elseif strcmp(str, 'w = 255')
        elements = {number_2; number_5; number_5};
    elseif strcmp(str, 'w = 260')
        elements = {number_2; number_6; number_0};
    elseif strcmp(str, 'w = 265')
        elements = {number_2; number_6; number_5};
    elseif strcmp(str, 'w = 270')
        elements = {number_2; number_7; number_0};
    elseif strcmp(str, 'w = 275')
        elements = {number_2; number_7; number_5};
    elseif strcmp(str, 'w = 280')
        elements = {number_2; number_8; number_0};
    elseif strcmp(str, 'd = 80')
        elements = {number_8; number_0};
    elseif strcmp(str, 'd = 86')
        elements = {number_8; number_6};
    elseif strcmp(str, 'd = 92')
        elements = {number_9; number_2};
    elseif strcmp(str, 'd = 98')
        elements = {number_9; number_8};
    elseif strcmp(str, 'd = 104')
        elements = {number_1; number_0; number_4};
    elseif strcmp(str, 'd = 110')
        elements = {number_1; number_1; number_0};
    elseif strcmp(str, 'd = 116')
        elements = {number_1; number_1; number_6};
    elseif strcmp(str, 'd = 122')
        elements = {number_1; number_2; number_2};
    elseif strcmp(str, 'd = 128')
        elements = {number_1; number_2; number_8};
    end
end

function str_list = gen_str_list(STR)
    if strcmp(STR, 'cSep')
        str_list = {'cSep 2.5'; 'cSep 3'; 'cSep 3.5'};
    elseif strcmp(STR, 'w')
        str_list = {'w = 240'; 'w = 245'; 'w = 250'; 'w = 255'; 'w = 260'; 'w = 265'; 'w = 270'; 'w = 275'; 'w = 280'};
    elseif strcmp(STR, 'd')
        str_list = {'d = 80'; 'd = 86'; 'd = 92'; 'd = 98'; 'd = 104'; 'd = 110'; 'd = 116'; 'd = 122'; 'd = 128'};
    end
end

function matrices = gen_matrices(STR, scale)
    str_list = gen_str_list(STR);
    matrices = cell(length(str_list),1);
    for i = 1:length(str_list)
        elements = get_elements(str_list{i});
        matrices{i} = imresize(gen_matrix(elements), scale);
    end
end

function matrix = gen_matrix(elements)
    matrix = [];
    space = true(7, 3);
    for i = 1:length(elements)
        if i == 1
            matrix = elements{i};
        else
            matrix = horzcat(matrix,space,elements{i});
        end
    end
end


