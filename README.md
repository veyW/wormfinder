# Matlab script to regconize worm and estimate the worm size from image. 
*Authors: Olga Ponomoarova * 


## Description 
This script is designed to detect worms of different sizes and stages (brightfield images of cultures in 96 well plates), remove any overlapping animals, and return body area and length of individual wors. 

## Requirements

Please use Matlab version > R2017b.

## Test

Given an image of worm slide from microscope predict it locations, number of worms and size of worm. 

Input test data is present in the test/input_image directory

Resultant output are available in the test/output/result directory

## Run 
To run in Matlab interactive mode simply import main.m. Run 

```
wormfinder(path)
```
where, path is directory of input images


Once you get something working for your dataset, feel free to edit any part of the code to suit your own needs.

## Resources

- [Matlab documentation](https://www.mathworks.com/help/matlab/)
- [Image Segmentation Tutorial](https://www.mathworks.com/matlabcentral/fileexchange/25157-image-segmentation-tutorial)