function cfg_print = spm_cfg_print
    
% ---------------------------------------------------------------------
% print Printing
% ---------------------------------------------------------------------
opts         = cfg_menu;
opts.tag     = 'opts';
opts.name    = 'Printing Options';
opts.help    = {'Select the printing option you want.  The figure will be printed to a file named spm5*.*, in the current directory.  PostScript files will be appended to, but other files will have "page numbers" appended to them.'};
opts.labels = {
                'PostScript for black and white printers'
                'PostScript for colour printers'
                'Level 2 PostScript for black and white printers'
                'Level 2 PostScript for colour printers'
                'Encapsulated PostScript (EPSF)'
                'Encapsulated Colour PostScript (EPSF)'
                'Encapsulated Level 2 PostScript (EPSF)'
                'Encapsulated Level 2 Color PostScript (EPSF)'
                'Encapsulated                with TIFF preview'
                'Encapsulated Colour         with TIFF preview'
                'Encapsulated Level 2        with TIFF preview'
                'Encapsulated Level 2 Colour with TIFF preview'
                'HPGL compatible with Hewlett-Packard 7475A plotter'
                'Adobe Illustrator 88 compatible illustration file'
                'M-file (and Mat-file, if necessary)'
                'Baseline JPEG image'
                'TIFF with packbits compression'
                'Color image format'
}';
opts.values{1}.opt = {
                       '-dps'
                       '-append'
}';
opts.values{1}.append = logical(true);
opts.values{1}.ext = '.ps';
opts.values{2}.opt = {
                       '-dpsc'
                       '-append'
}';
opts.values{2}.append = logical(true);
opts.values{2}.ext = '.ps';
opts.values{3}.opt = {
                       '-dps2'
                       '-append'
}';
opts.values{3}.append = logical(true);
opts.values{3}.ext = '.ps';
opts.values{4}.opt = {
                       '-dpsc2'
                       '-append'
}';
opts.values{4}.append = logical(true);
opts.values{4}.ext = '.ps';
opts.values{5}.opt = {'-deps'};
opts.values{5}.append = logical(false);
opts.values{5}.ext = '.eps';
opts.values{6}.opt = {'-depsc'};
opts.values{6}.append = logical(false);
opts.values{6}.ext = '.eps';
opts.values{7}.opt = {'-deps2'};
opts.values{7}.append = logical(false);
opts.values{7}.ext = '.eps';
opts.values{8}.opt = {'-depsc2'};
opts.values{8}.append = logical(false);
opts.values{8}.ext = '.eps';
opts.values{9}.opt = {
                       '-deps'
                       '-tiff'
}';
opts.values{9}.append = logical(false);
opts.values{9}.ext = '.eps';
opts.values{10}.opt = {
                        '-depsc'
                        '-tiff'
}';
opts.values{10}.append = logical(false);
opts.values{10}.ext = '.eps';
opts.values{11}.opt = {
                        '-deps2'
                        '-tiff'
}';
opts.values{11}.append = logical(false);
opts.values{11}.ext = '.eps';
opts.values{12}.opt = {
                        '-depsc2'
                        '-tiff'
}';
opts.values{12}.append = logical(false);
opts.values{12}.ext = '.eps';
opts.values{13}.opt = {'-dhpgl'};
opts.values{13}.append = logical(false);
opts.values{13}.ext = '.hpgl';
opts.values{14}.opt = {'-dill'};
opts.values{14}.append = logical(false);
opts.values{14}.ext = '.ill';
opts.values{15}.opt = {'-dmfile'};
opts.values{15}.append = logical(false);
opts.values{15}.ext = '.m';
opts.values{16}.opt = {'-djpeg'};
opts.values{16}.append = logical(false);
opts.values{16}.ext = '.jpg';
opts.values{17}.opt = {'-dtiff'};
opts.values{17}.append = logical(false);
opts.values{17}.ext = '.tif';
opts.values{18}.opt = {'-dtiffnocompression'};
opts.values{18}.append = logical(false);
opts.values{18}.ext = '.tif';
opts.def = {@spm_get_defaults, 'ui.print'};

fname = cfg_entry;
fname.tag  = 'fname';
fname.name = 'Print Filename';
fname.strtype = 's';
fname.val  = {}; % explicitly unset this val
fname.help = {['Filename to print to. If this is set as a default - even ' ...
               'if it is set to an empty string - spm_print(''fname'') ' ...
               'will not print to file ''fname'', but to the standard SPM ' ...
               'print file.']};

cfg_print = cfg_exbranch;
cfg_print.tag = 'print';
cfg_print.name = 'Print';
cfg_print.val = {fname, opts};
cfg_print.prog = @spm_print;
cfg_print.help = {'Print the Graphics/Help window.'};