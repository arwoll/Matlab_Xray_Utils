function success = write_tiff_fp(im, full_fname, varargin)

success = 0;
if nargin>2 && strcmp(varargin{1},'force')
    force_write = 1;
else 
    force_write = 0;
end
if ~force_write && exist(full_fname, 'file')
    fprintf('Oops -- file %s found -- Abort. Append ''force'' arg to force write\n', full_fname);
    return
end

if isa(im, 'single')
    bps = 32;
elseif isa(im, 'double')
    bps = 64;
else
    fprintf('Unrecognized image type -- abort\n')
    return
end
tagstruct.ImageLength=size(im, 1);
tagstruct.ImageWidth=size(im, 2);
tagstruct.BitsPerSample = bps;
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.SamplesPerPixel=1;
tagstruct.RowsPerStrip = 1;
tagstruct.SubFileType = Tiff.SubFileType.Default;
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
%tagstruct.Orientation = Tiff.Orientation.BottomLeft;
tagstruct.Compression = Tiff.Compression.None;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software='MATLAB';
thistiff = Tiff(full_fname, 'w');
thistiff.setTag(tagstruct)
thistiff.write(im);
thistiff.close();
success = 1;
