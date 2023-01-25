#!/usr/local/bin/python3
import sys

def FFT(image):
    import numpy
    import imageio
    image = imageio.imread(image)
    fft = numpy.fft.fft2(image)
    imageio.imwrite('{image}_fft.png', numpy.abs(fft))
    return fft


if __name__ == '__main__':
    FFT(sys.argv[1])