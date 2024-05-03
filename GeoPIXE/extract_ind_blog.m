function det_data = extract_ind_blog(blogdir)
% script to extract, from blog files within a sequnce of directories,
% histograms from individual detectors, and place into matlab array.
%
% tag 34 (maia_events_1) commences with exactly 3 PA events
%npts = 41;
%base_path = '../../../raw/maia_cca_2/scan_009';
det_data = zeros(384, 4096);
seg_files = dir(blogdir);
seg_files = seg_files(3:end);
if isempty(seg_files)
    fprintf('Error: no seg files found in blogdir\n');
    exit
end
abort = 0;
ctr = 0;
for seg_file = 1:1%length(seg_files)
    infname = [blogdir '/' seg_files(seg_file).name];
    fprintf([infname '\n']);
    infid = fopen(infname, 'r', 'b');

    index =0;
    while ~feof(infid) % && (index < 200)
        % Literal 0xaa = 170
        head1 = fread(infid, 1,'*uint8');
        if head1 ~= 170
            fprintf('seg = %d, head1 = %u8 ... Abort\n');
            abort = 1;
            break
        elseif feof(infid)
            break
        end
        %fwrite(outfid, head1, 'uint8');
        
        tag = fread(infid, 1,'*uint16');
        %fwrite(outfid, tag, 'uint16', 0, 'b');
        
        head2 = fread(infid, 1,'*uint8');
        %fwrite(outfid, head2, 'uint8', 0, 'b');
        
        len = fread(infid, 1,'*uint16');
        %fwrite(outfid, len, 'uint16',0,  'b');
        
        a = fread(infid, 1,'*uint16');
        %fwrite(outfid, a, 'uint16', 0, 'b');
        
        a = fread(infid, 6,'*uint32');
        %fwrite(outfid, a, 'uint32', 0, 'b');
        
        % End Header
        % Read payload
        payloadbytes = len;
        % if tag = 34, then read events
        
        if tag == 34
            %fprintf('Found event tag\n');
            for k = 1:3
                pe = fread(infid, 1,'*uint32');
            end
            payloadbytes = payloadbytes - 12;
            while payloadbytes > 0
                event = fread(infid, 1,'*uint32');
                payloadbytes = payloadbytes - 4;
                id_bit = bitand(bitshift(event, -31), 1);
                if id_bit == 1
                    continue
                end
                detN = uint16(bitand(bitshift(event, -22), 511));
                timeADC = uint16(bitand(bitshift(event, -12), 1023));
                energyADC = uint16(bitand(event, 4095));
                det_data(detN+1, energyADC+1) = ...
                    det_data(detN+1, energyADC+1)+1;
                
                 ctr = ctr+1;
            end
        else % tag ~= 34
             
            % Copy remaining payload
            if feof(infid) || isempty(payloadbytes) || payloadbytes< 0
                fprintf('Breaking due to strangeness\n');
                abort  = 1;
                break
            end
            a = fread(infid, payloadbytes,'*uint8');
        end
%         fprintf('Block Read: head1 = %d, tag = %d, head2 = %d, len = %d paysum = %d\n', ...
%             head1, tag, head2, len, sum(a));
         
        index = index + 1;
%         if index > 30
%             break
%         end
    end
  
    fprintf('%s done, read %d data blocks, %d photons\n', ...
        infname, index, ctr);
    fclose(infid);
    if abort == 1
        fprintf('Abort during %s\n', infname);
        break
    end
end

