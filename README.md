# bfmcorr

Stata command for survey data correction using tax data with the method described by Blanchet, Flores and Morgan in [“The Weight of the Rich: Improving Surveys Using Tax Data”, WID.world Working Paper 2018/12](https://wid.world/document/the-weight-of-the-rich-improving-surveys-using-tax-data-wid-world-working-paper-2018-12/).

## Installation

Users should install the package via `ssc` by typing:

```
ssc install bfmcorr
```

## Features

- reweight observations in the survey enforce consistency with the tax data, and replace observations at the top to increase precision.
- automatically determines the "merging point" between the tax and the survey data, and extrapolate the shape of the nonresponse function if the tax data does not cover a large enough part of the distribution.
- can maintain the survey representativeness in terms of other sociodemographic variables (age, gender, etc.)
- preserve survey microdata, including the household structure.
- can use tax data with different statistical units (households or individuals).
- can work with two different income variables: a comprehensive income variable assumes to drive nonresponse, and taxable income variable that corresponds to the tax data.
- provides several diagnostic tools to analyse the correction.

## Documentation

For technical details about the methodology, see the paper [“The Weight of the Rich: Improving Surveys Using Tax Data”, WID.world Working Paper 2018/12](https://wid.world/document/the-weight-of-the-rich-improving-surveys-using-tax-data-wid-world-working-paper-2018-12/).

For the description of the command, type `help bfmcorr`. For the description of postestimation tools, type `help postbfm`.

## Example

See the file `example.ado` for and example.