function mifFileWrite(fname, data, dataRad, num)
% function mifFileWrite(fname, data, dataRad, num)
%
% fname     - file name
% data      - data, fi object
% dataRad   - data radix ('BIN', 'HEX', 'UNS', 'DEC' (with sign))
%              ( 'DEC' - doesnt correct work in my Modelsim, use 'UNS' )
% num       - number of elements in mif-file (if required function will add zeros or cut elements)

% specify default radix
adrRad = 'UNS'; % for address radix
if (nargin < 3)
    dataRad = 'HEX';            
end

% specify number of elements
if (nargin > 3)
    if (num > length(data)) % adding zeros
        data(end + 1 : num) = 0;
    else                    % cutting
        data = data(1 : num);
    end
else
    num = length(data);
end

% format string, number of zeros in address
fmt = ['%0', num2str(length(num2str(num))), 'd'];
% data string
ds = cell(1, num);
switch dataRad
    case 'BIN'
        for i = 1 : num
            t = data(i);
            ds{i} = t.bin;
        end
    case 'HEX'
        for i = 1 : num
            t = data(i);
            ds{i} = t.hex;
        end
    case 'UNS'
        for i = 1 : num
            t = data(i);
            ds{i} = t.dec;
        end
    case 'DEC'
        error('DEC data radix is not corrected working in Modelsim.');
%         for i = 1 : num
%             t = data(i);
%             ds{ i } = num2str( t.int, '%i' );
%         end
    otherwise
        error('Not correct data radix!');
end
% file header
fileID = fopen(fname, 'wt');
fprintf(fileID, ['DEPTH = ' num2str(num) ';\n']);
fprintf(fileID, ['WIDTH = ' num2str(data.WordLength) ';\n']);
fprintf(fileID, ['ADDRESS_RADIX = ' adrRad ';\n']);
fprintf(fileID, ['DATA_RADIX = ' dataRad ';\n']);
fprintf(fileID, 'CONTENT\n');
fprintf(fileID, 'BEGIN\n');

for i = 1 : num
    fprintf(fileID, fmt, i - 1);  % address
    fprintf(fileID, ' : ');
    fprintf(fileID, ds{i}); % word
    fprintf(fileID, ';\n');
end

% end of file
fprintf(fileID, 'END;');
fclose(fileID);