function rect_pos = getrect_interactive(fign, varargin)
%function h_rect = get_rect_roi(im) asks the user to interactively define
%      a rectangular ROI, and returns when done.
%    Interaction occurs in two steps: first the user refines the color
%    range of the image. Next, the user defines the ROI.
%    If included, varargin  is a position specifier of a previously-defined
%    ROI, to be used as the intitial position of the ROI
figure(2); clf; colormap(gray);
figure(fign);
done = 0;
while ~done
    fprintf('Draw and edit rectangle -- double click to plot\n');
    if ~exist('h_rect', 'var')
        if isempty(varargin)
            h_rect = imrect(gca);
        else
            h_rect = imrect(gca, varargin{:});
        end
        % The following fails because we cannot trigger on
        % mousebuttonrelease, so there are too many callbacks
        %addNewPositionCallback(h_rect, @(p) getrect_drawroi(p));
    end
    rect_pos = round(wait(h_rect));
    getrect_drawroi(rect_pos)
    yesno = input('Good (y to accept):', 's');
    if ~isempty(strfind(yesno, 'y')) || ~isempty(strfind(yesno, 'Y'))
        done = 1;
    end
end
h_rect.delete
end

function getrect_drawroi(rect_pos)
    rect_pos = round(rect_pos);
    x_roi = rect_pos(1):rect_pos(1)+rect_pos(3)-1;
    y_roi = rect_pos(2):rect_pos(2)+rect_pos(4)-1;
    foo = get(gca, 'Children');
    if length(foo) < 2
        return
    end
    % Better would be to find CData
    if isprop(foo(2), 'CData')
        im = foo(2).CData;
        im_roi = im(y_roi, x_roi);
        figure(2);
        imagesc(im_roi); axis equal tight;
        fprintf('ROI Max = %.2f, Mean = %.2f\n', max(im_roi(:)), mean(im_roi(:)))
    end
end
