{smcl}
{* *! version v0.0.0.9000 09jul2019}{...}
{title:Title}

{phang}
{bf:bfmtoy} {hline 2} Simulate income distributions and draw biased samples to play with {help bfmcorr:{bf:bfmcorr}} and {help bfmcorr:{bf:postbfm}}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:bfmtoy}{cmd:,} {opt obs:(real)} {opt tru:e(numlist)} {opt theta:(numlist)} {opt mis:reporting(numlist)} {opt sam:ple(real)} {opt bin:s(int)} {opt nof:igure} {opt prep:are} [, {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Primary options}

{synopt:{opth obs:(real)}} Number of individual observations in the simulated income distribution; 
default is 5,000,000{p_end}

{synopt:{opth tru:e(numlist)}} Specifies parameters for the lognormal distribution
 from which the income distribution is simulated; both the mean and standard deviation
 must be defined; default values are 0 and 1 respectively{p_end}
 
{synopt:{opth theta:(numlist)}} Specifies parameters for the nonresponse bias; 
values for both the baseline response rate and the fractile {it:f} from which it starts
 decreasing must be specified; the baseline value corresponds to the flat response 
 rate that is assumed from the bottom of the distribution up to {it:f}; response 
 rates are assumed to be linearly decreasing with rank; they tend to 0 when income is
 infinite{p_end}
 
 {synopt:{opth mis:reporting(numlist)}} Specifies parameters for the misreported income bias; 
four parameters must be specified. The first pair define the probability of misreporting; 
these correspond to the baseline probability and the fractile {it:p} 
from which its starts increasing (default values are 0.2 and 0.8 respectively); 
 the probability of misreporting increases linearly with rank and tends to 1 with 
 infinite income. The second pair of parameters define the distribution of 
misreported income; it follows a lognormal distribution, which mean and standard 
deviation must be specified; default values are 0 and 1 respectively{p_end} 

{synopt:{opth sam:ple(real)}} Determines the size of the sample to be drawn from
 the simulated distribution; values must be higher than 0 and lower than 1; default 
 is 0.01, which draws a random sample containing 1% of observations in the simulated
 income distribution{p_end}
 
 {synopt:{opt prep:are}} Prepares the output data to be used as input for 
 {help bfmcorr:{bf:bfmcorr}}. The option must be declared applying {help bfmcorr:{bf:bfmcorr}}
 to simulated data
 
{syntab:Secondary options} 
 
{synopt:{opth bin:s(int)}} Specifies the number of bins for the histograms; default value is 60{p_end}


{synopt:{opth truncg:raph(real)}} Defines the maximum income level to be displayed 
when plotting histograms; default value is 15{p_end}

{synopt:{opt nof:igure}} Prevents the display of figures{p_end}

{synoptline}
{pstd}
The command changes the data in memory without any warning.
See {help bfmcorr} and {help postbfm} for the correction method.

{marker description}{...}
{title:Description}

{pstd}
{cmd:bfmtoy} simulates income distributions and draws biased samples from it to test survey adjustment methods.
 It enables users to introduce three types of biases affecting especially the top tail of the sample's
 distribution. These include nonresponse, misreporting and small sample bias.  

{title:Stored results}

{pstd}
{cmd:bfmtoy} stores the following in {bf:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(mat_sum_true)}}Summary results of the 'true' distibution, to be compared with the adjusted
data produced by {help bfmcorr:{bf:bfmcorr}}{p_end}

{marker reference}{...}
{title:Reference}

{pstd}
Blanchet, T., Flores, I. and Morgan, M. (2018). {browse "https://wid.world/document/the-weight-of-the-rich-improving-surveys-using-tax-data-wid-world-working-paper-2018-12/": The Weight of the Rich: Improving Surveys Using Tax Data}. WID.world Working Paper Series No. 2018/12.

{title:Contact}

{pstd}
If you have comments, suggestions, or experience any problem with this command, please contact
Thomas Blanchet ({browse "mailto:thomas.blanchet@wid.world?cc=ignacio.flores@psemail.eu&cc=marc.morgan@psemail.eu":thomas.blanchet@wid.world}),
Ignacio Flores ({browse "mailto:thomas.blanchet@wid.world?cc=ignacio.flores@psemail.eu&cc=marc.morgan@psemail.eu":ignacio.flores@psemail.eu}) and
Marc Morgan ({browse "mailto:thomas.blanchet@wid.world?cc=ignacio.flores@psemail.eu&cc=marc.morgan@psemail.eu":marc.morgan@psemail.eu}).

