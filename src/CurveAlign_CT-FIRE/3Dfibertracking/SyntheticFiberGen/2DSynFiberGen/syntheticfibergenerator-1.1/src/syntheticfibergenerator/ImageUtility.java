/*
 * Written for the Laboratory for Optical and Computational Instrumentation, UW-Madison
 *
 * Author: Matthew Dutson
 * Email: dutson@wisc.edu, mattdutson@icloud.com
 * GitHub: https://github.com/uw-loci/syntheticfibergenerator
 *
 * Copyright (c) 2019, Board of Regents of the University of Wisconsin-Madison
 */

package syntheticfibergenerator;

import java.awt.*;
import java.awt.geom.AffineTransform;
import java.awt.image.*;


class ImageUtility {

    // Used to maximize efficiency of the backgroundDist function
    private static final int DIST_SEARCH_STEP = 4;


    /**
     * Applies a distance filter to the input image. Each pixel's value is equal to {@code falloff} times the 2-norm
     * distance to the closest background pixel.
     *
     * @param image   An 8-bit grey scale image
     * @param falloff Determines the intensity of the distance function (see above)
     * @return An 8-bit grey scale image with the distance filter applied
     */
    static BufferedImage distanceFunction(BufferedImage image, double falloff) {
        if (image.getType() != BufferedImage.TYPE_BYTE_GRAY) {
            throw new IllegalArgumentException("Image must be TYPE_BYTE_GRAY");
        }
        BufferedImage output = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        Raster inRaster = image.getRaster();
        WritableRaster outRaster = output.getRaster();
        for (int y = 0; y < output.getHeight(); y++) {
            for (int x = 0; x < output.getWidth(); x++) {
                if (getPixel(inRaster, x, y) == 0) {
                    setPixel(outRaster, x, y, 0);
                    continue;
                }
                double minDist = backgroundDist(inRaster, x, y);
                int outValue = 255;
                if (minDist > 0) {
                    outValue = Math.min(255, (int) (minDist * falloff));
                }
                setPixel(outRaster, x, y, outValue);
            }
        }
        return output;
    }

    /**
     * Applies a Gaussian blur to the input image. Let {@code a = Math.ceil(radius)}, if {@code a} is even, the kernel
     * is a square matrix of size {@code a*a}. If {@code a} is odd, the kernel is a square matrix of size {@code
     * (a-1)*(a-1)}. The radius of the Gaussian function is equal to {@code radius/3}.
     *
     * @param image  The image to blur
     * @param radius The size of the Gaussian kernel (see above)
     * @return A blurred copy of the input image
     */
    static BufferedImage gaussianBlur(BufferedImage image, double radius) {
        Kernel kernel = gaussianKernel(radius);
        ConvolveOp op = new ConvolveOp(kernel, ConvolveOp.EDGE_ZERO_FILL, null);
        int pad = kernel.getWidth() / 2;
        BufferedImage padded = zeroPad(image, pad);
        BufferedImage output = new BufferedImage(image.getWidth(), image.getHeight(), image.getType());
        op.filter(padded, output);
        return output;
    }

    /**
     * Scales the height and width of the input image by some factor.
     *
     * @param image             The image to scale
     * @param ratio             The ratio of the output size to the input size
     * @param interpolationType The interpolation method to use
     * @return A scaled copy of the input image
     */
    static BufferedImage scale(BufferedImage image, double ratio, int interpolationType) {
        AffineTransform transform = new AffineTransform();
        transform.scale(ratio, ratio);
        AffineTransformOp scaleOp = new AffineTransformOp(transform, interpolationType);
        BufferedImage output = scaleOp.createCompatibleDestImage(image, image.getColorModel());
        scaleOp.filter(image, output);
        return output;
    }

    /**
     * Caps the intensity of the input image by a certain value.
     *
     * @param image An 8-bit grey scale image
     * @param max   The maximum intensity, inclusive, on a scale 0-255
     * @return An intensity-capped copy of the input image
     */
    static BufferedImage cap(BufferedImage image, int max) {
        if (image.getType() != BufferedImage.TYPE_BYTE_GRAY) {
            throw new IllegalArgumentException("Image must be TYPE_BYTE_GRAY");
        }
        BufferedImage output = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        Raster inRaster = image.getRaster();
        WritableRaster outRaster = output.getRaster();
        for (int y = 0; y < output.getHeight(); y++) {
            for (int x = 0; x < output.getWidth(); x++) {
                int value = getPixel(inRaster, x, y);
                setPixel(outRaster, x, y, value > max ? max : value);
            }
        }
        return output;
    }

    /**
     * Normalizes the intensity of the input image with a given max.
     *
     * @param image An 8-bit grey scale image
     * @param max   The maximum intensity, inclusive, on a scale 0-255
     * @return A normalized copy of the input image
     */
    static BufferedImage normalize(BufferedImage image, int max) {
        if (image.getType() != BufferedImage.TYPE_BYTE_GRAY) {
            throw new IllegalArgumentException("Image must be TYPE_BYTE_GRAY");
        }
        int currentMax = 0;
        Raster inRaster = image.getRaster();
        for (int y = 0; y < image.getHeight(); y++) {
            for (int x = 0; x < image.getWidth(); x++) {
                currentMax = Math.max(currentMax, getPixel(inRaster, x, y));
            }
        }
        BufferedImage output = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        WritableRaster outRaster = output.getRaster();
        for (int y = 0; y < output.getHeight(); y++) {
            for (int x = 0; x < output.getWidth(); x++) {
                int value = getPixel(inRaster, x, y);
                setPixel(outRaster, x, y, value * max / currentMax);
            }
        }
        return output;
    }

    /**
     * A helper for {@code distanceFunction}.
     *
     * @param raster A {@code Raster} obtained from the source image
     * @param x      Pixel's x-coordinate
     * @param y      Pixel's y-coordinate
     * @return The distance between the specified pixel and the closest background pixel.
     */
    private static double backgroundDist(Raster raster, int x, int y) {
        int rMax = (int) Math.sqrt(MiscUtility.sq(raster.getWidth()) + MiscUtility.sq(raster.getHeight())) + 1;
        boolean found = false;
        double minDist = Double.POSITIVE_INFINITY;
        for (int r = DIST_SEARCH_STEP; r < rMax && !found; r += DIST_SEARCH_STEP) {
            int xMin = Math.max(0, x - r);
            int xMax = Math.min(raster.getWidth(), x + r);
            int yMin = Math.max(0, y - r);
            int yMax = Math.min(raster.getHeight(), y + r);
            for (int yIn = yMin; yIn < yMax; yIn++) {
                for (int xIn = xMin; xIn < xMax; xIn++) {
                    if (getPixel(raster, xIn, yIn) > 0) {
                        continue;
                    }
                    double dist = Math.sqrt(MiscUtility.sq(xIn - x) + MiscUtility.sq(yIn - y));
                    if (dist <= r && dist < minDist) {
                        found = true;
                        minDist = dist;
                    }
                }
            }
        }
        return minDist;
    }

    /**
     * Wrapper used to get the intensity value of a grey scale pixel.
     *
     * @param raster The image
     * @param x      Pixel's x-coordinate
     * @param y      Pixel's y-coordinate
     * @return A value in the range 0-255 representing the intensity of the specified pixel
     */
    private static int getPixel(Raster raster, int x, int y) {
        int[] pixel = new int[1];
        raster.getPixel(x, y, pixel);
        return pixel[0];
    }

    /**
     * Wrapper used to set the intensity value of a grey scale pixel.
     *
     * @param raster The image
     * @param x      Pixel's x-coordinate
     * @param y      Pixel's y-coordinate
     * @param value  Desired value for the pixel in the range 0-255
     */
    private static void setPixel(WritableRaster raster, int x, int y, int value) {
        int[] pixel = {value};
        raster.setPixel(x, y, pixel);
    }

    /**
     * Constructs a Gaussian kernel of the specified size. See notes for {@code gaussianBlur}.
     *
     * @param radius The size of the Gaussian kernel
     * @return A Gaussian kernel with the specified size
     */
    private static Kernel gaussianKernel(double radius) {
        double sigma = radius / 3.0;
        int size = (int) Math.ceil(radius);
        size -= size % 2 - 1;
        float[] weightMatrix = new float[MiscUtility.sq(size)];
        int center = size / 2;
        double normConst = 0.0;
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                double gauss = Math.exp(
                        -(MiscUtility.sq(i - center) + MiscUtility.sq(j - center)) / (2 * MiscUtility.sq(sigma)));
                weightMatrix[i + j * size] = (float) gauss;
                normConst += gauss;
            }
        }
        for (int i = 0; i < weightMatrix.length; i++) {
            weightMatrix[i] /= normConst;
        }
        return new Kernel(size, size, weightMatrix);
    }

    /**
     * Pads an image with a zero border (typically to prepare for a convolution).
     *
     * @param image The image to pad
     * @param pad   The size in pixels of the border
     * @return A padded copy of the input image
     */
    private static BufferedImage zeroPad(BufferedImage image, int pad) {
        int width = image.getWidth() + pad * 2;
        int height = image.getHeight() + pad * 2;
        BufferedImage output = new BufferedImage(width, height, image.getType());
        Graphics2D graphics = output.createGraphics();
        graphics.drawImage(image, pad, pad, null);
        return output;
    }
}
