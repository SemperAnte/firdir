% finite-impulse response filter, direct implementation
clc; clear; close all;
addpath( 'func' );

fpathRtl = '..\rtl\'; % for rom context - mif file
fpathSim = '..\sim\';
fpathModelsim  = 'D:\CADS\Modelsim10_1c\win32\modelsim.exe';

FIR_ORDER  = 511;  % number of coef - 1
COEF_WDT   = 18;   % coef of fir width [-1 1)
DIN_WDT    = 16;   % input data width [-1 1)
ACC_WDT    = -1;   % accumulator width (calc later)
DOUT_WDT   = 16;   % output data width [-1 1)
DOUT_SHIFT = 1;    % output data left shift with saturate

% function from fda tool -> File -> 
% Generate Matlab Code ->  Filter Design Function
Hd = fdafunc;
FIR_ORDER = length( Hd.Numerator ) - 1;

% or manual description
% Fs = 192e3;     % Sampling Frequency
% Fc = 12e3;      % Cutoff Frequency
% flag = 'scale'; % Sampling Flag
% win = hamming(FIR_ORDER+1);
% b  = fir1(FIR_ORDER, Fc/(Fs/2), 'low', win, flag);
% Hd = dfilt.dffir(b);

% set the arithmetic property.
set( Hd, 'Arithmetic',        'fixed', ...
         'CoeffWordLength',   COEF_WDT, ...
         'CoeffAutoScale',    false, ...
         'NumFracLength',     COEF_WDT - 1, ...
         'Signed',            true, ...
         'InputWordLength',   DIN_WDT, ...
         'inputFracLength',   DIN_WDT - 1, ...
         'FilterInternals',  'SpecifyPrecision', ...
         'ProductWordLength', DIN_WDT + 1, ...
         'ProductFracLength', DIN_WDT - 1, ...
         'RoundMode',         'Floor', ...
         'OverflowMode',      'Wrap' );
normalize( Hd );
coef = fi( Hd.Numerator, ... % coefficients
           Hd.Signed, Hd.CoeffWordLength, Hd.NumFracLength );
Hd.AccumFracLength = DIN_WDT - 1;
Hd.AccumWordLength = DIN_WDT + ceil( log2( sum( abs( double( coef ) ) ) + 1 ) );
Hd.OutputWordLength = Hd.AccumWordLength; % saturate at the end
Hd.OutputFracLength = Hd.AccumFracLength;
ACC_WDT = Hd.AccumWordLength;
assert( ACC_WDT - DOUT_SHIFT >= DOUT_WDT, 'ACC_WDT - DOUT_SHIFT >= DOUT_WDT' ); 
%fvtool(Hd);
fprintf( 'FIR_ORDER  = %i\n', FIR_ORDER  );
fprintf( 'COEF_WDT   = %i\n', COEF_WDT   );
fprintf( 'DIN_WDT    = %i\n', DIN_WDT    );
fprintf( 'ACC_WDT    = %i\n', ACC_WDT    );
fprintf( 'DOUT_WDT   = %i\n', DOUT_WDT   );
fprintf( 'DOUT_SHIFT = %i\n', DOUT_SHIFT );
disp(Hd);

% create file with parameters
% file with parms
fileID = fopen( [ fpathSim 'parms.vh' ], 'wt' );
fprintf( fileID, '// Automatically generated with Matlab, dont edit\n' );
fprintf( fileID, 'localparam int FIR_ORDER  = %i,\n', FIR_ORDER  );
fprintf( fileID, '               COEF_WDT   = %i,\n', COEF_WDT   );
fprintf( fileID, '               DIN_WDT    = %i,\n', DIN_WDT    );
fprintf( fileID, '               ACC_WDT    = %i,\n', ACC_WDT    );
fprintf( fileID, '               DOUT_WDT   = %i,\n', DOUT_WDT   );
fprintf( fileID, '               DOUT_SHIFT = %i;\n', DOUT_SHIFT );
fclose( fileID );
% create altera mif-file with coefficients
mifFileWrite( [ fpathRtl 'romcoef.mif' ], coef, 'HEX', length( coef ) );

% input test data
L  = 1e4;   % number of points
Fs = 96e3;  % sampling frequency
%din = randn( 1, L ); din = din / max( abs( din ) );        % white noise
din = sin( 2 * pi * ( 1 : L ) * 1e3 / Fs );                 % sine
%din = square( 2 * pi * ( 1 : L ) * 1e3 / Fs );             % square    
%din = chirp( ( 1 : L ) / Fs, 1e3, L / Fs, 4e3, 'linear' ); % chirp
%din = zeros( 1, L ); din( 10 ) = 1;                        % delta
din = sfi( din, DIN_WDT, DIN_WDT - 1 );
txtFileWrite( [ fpathSim 'din.txt' ], din, 'DEC' );

% filter data by matlab
% calc in matlab
doutMat = filter( Hd, din );
doutMat.OverflowAction = 'Saturate';
doutMat = bitshift( doutMat, DOUT_SHIFT ); % shift
doutMat = sfi( doutMat, DOUT_WDT, DOUT_WDT - ( Hd.AccumWordLength - Hd.AccumFracLength ) );
doutMat = reinterpretcast( doutMat, numerictype( 1, DOUT_WDT, DOUT_WDT - 1 ) );
plot( doutMat );

%% autorun Modelsim
if ( exist( [ fpathSim 'flag.txt' ], 'file' ) )
     delete( [ fpathSim 'flag.txt' ] );
end;
status = system( [ fpathModelsim ' -do ' fpathSim 'auto.do' ] );
pause on;
while ( ~exist( [ fpathSim 'flag.txt' ], 'file' ) ) % wait for flag file
    pause( 1 );
end;
%% % read data from testbench
NT = numerictype( 1, doutMat.WordLength, doutMat.FractionLength );
doutHdl = txtFileRead( [ fpathSim 'dout.txt' ], NT, 'DEC' );

if ( length( doutMat ) == length( doutHdl ) )
    fprintf( 'length is equal = %i\n', length( doutMat ) );
    x = 1 : length( doutMat );    
elseif ( length( doutMat ) > length( doutHdl ) )
    fprintf( 'length isnt equal, matlab = %i, hdl = %i\n', ...
        length( doutMat ), length( doutHdl ) );
    x = 1 : length( doutHdl );
else
    fprintf( 'length isnt equal, matlab = %i, hdl = %i\n', ...
    length( doutMat ), length( doutHdl ) );
    x = 1 : length( doutMat );
end;

fprintf( 'num of errors : %i\n', sum( doutMat( x ) ~= doutHdl( x ) ) );
if ( true )
    figure;
    plot( x, doutMat( x ), x, doutHdl( x ) );
    title( 'filter outputs' );
    legend( 'matlab', 'hdl' );
    grid on;    
end