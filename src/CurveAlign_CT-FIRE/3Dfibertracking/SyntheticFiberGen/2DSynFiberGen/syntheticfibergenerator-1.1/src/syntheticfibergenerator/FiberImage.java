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

import org.apache.commons.math3.distribution.PoissonDistribution;

import java.awt.Color;
import java.awt.*;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.awt.image.WritableRaster;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Iterator;


/**
 * Represents an image containing multiple fibers.
 */
class FiberImage implements Iterable<Fiber> {

    /**
     * The information needed to construct a fiber image.
     */
    static class Params {

        Param<Integer> nFibers = new Param<>();
        Param<Double> segmentLength = new Param<>();
        Param<Double> alignment = new Param<>();
        Param<Double> meanAngle = new Param<>();
        Param<Double> widthChange = new Param<>();
        Param<Integer> imageWidth = new Param<>();
        Param<Integer> imageHeight = new Param<>();
        Param<Integer> imageBuffer = new Param<>();

        Distribution length = new Uniform(0.0, Double.POSITIVE_INFINITY);
        Distribution width = new Uniform(0.0, Double.POSITIVE_INFINITY);
        Distribution straightness = new Uniform(0.0, 1.0);

        Optional<Double> scale = new Optional<>();
        Optional<Double> downSample = new Optional<>();
        Optional<Double> blur = new Optional<>();
        Optional<Double> noise = new Optional<>();
        Optional<Double> distance = new Optional<>();
        Optional<Integer> cap = new Optional<>();
        Optional<Integer> normalize = new Optional<>();
        Optional<Integer> bubble = new Optional<>();
        Optional<Integer> swap = new Optional<>();
        Optional<Integer> spline = new Optional<>();


        /**
         * This isn't part of the constructor because FiberImage.Params objects are often constructed during their
         * deserialization from JSON and the JSON representation doesn't contain names.
         */
        void setNames() {
            nFibers.setName("number of fibers");
            segmentLength.setName("segment length");
            alignment.setName("alignment");
            meanAngle.setName("mean angle");
            widthChange.setName("width change");
            imageWidth.setName("image width");
            imageHeight.setName("image height");
            imageBuffer.setName("edge buffer");

            length.setNames();
            straightness.setNames();
            width.setNames();

            scale.setName("scale");
            downSample.setName("down sample");
            blur.setName("blur");
            noise.setName("noise");
            distance.setName("distance");
            cap.setName("cap");
            normalize.setName("normalize");
            bubble.setName("bubble");
            swap.setName("swap");
            spline.setName("spline");
        }

        /**
         * Not part of the constructor for the same reason as setNames().
         */
        void setHints() {
            nFibers.setHint("The number of fibers per image to generate");
            segmentLength.setHint("The length in pixels of fiber segments");
            alignment.setHint("A value between 0 and 1 indicating how close fibers are to the mean angle on average");
            meanAngle.setHint("The average fiber angle in degrees");
            widthChange.setHint("The maximum segment-to-segment width change of a fiber in pixels");
            imageWidth.setHint("The width of the saved image in pixels");
            imageHeight.setHint("The height of the saved image in pixels");
            imageBuffer.setHint("The size in pixels of the empty border around the edge of the image");

            length.setHints();
            straightness.setHints();
            width.setHints();

            scale.setHint("Check to draw a scale bar on the image; value is the number of pixels per micron");
            downSample.setHint("Check to enable down sampling; value is the ratio of final size to original size");
            blur.setHint("Check to enable Gaussian blurring; value is the radius of the blur in pixels");
            noise.setHint("Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)");
            distance.setHint("Check to apply a distance filter; value controls the sharpness of the intensity falloff");
            cap.setHint("Check to cap the intensity; value is the inclusive maximum on a scale of 0-255");
            normalize.setHint("Check to normalize the intensity; value is the inclusive maximum on a scale of 0-255");
            bubble.setHint("Check to apply \"bubble smoothing\"; value is the number of passes");
            swap.setHint("Check to apply \"swap smoothing\"; number of swaps is this value times number of segments");
            spline.setHint("Check to enable spline smoothing; value is the number of interpolated points per segment");
        }

        /**
         * Verifies that all parameters are within the correct bounds.
         *
         * @throws IllegalArgumentException If any parameters are out of bounds
         */
        void verify() throws IllegalArgumentException {
            nFibers.verify(0, Param::greater);
            segmentLength.verify(0.0, Param::greater);
            widthChange.verify(0.0, Param::greaterEq);
            alignment.verify(0.0, Param::greaterEq);
            alignment.verify(1.0, Param::lessEq);
            meanAngle.verify(0.0, Param::greaterEq);
            meanAngle.verify(180.0, Param::lessEq);

            imageWidth.verify(0, Param::greater);
            imageHeight.verify(0, Param::greater);
            imageBuffer.verify(0, Param::greater);

            length.verify();
            straightness.verify();
            width.verify();

            scale.verify(0.0, Param::greater);
            downSample.verify(0.0, Param::greater);
            blur.verify(0.0, Param::greater);
            noise.verify(0.0, Param::greater);
            distance.verify(0.0, Param::greater);
            cap.verify(0, Param::greaterEq);
            cap.verify(255, Param::lessEq);
            normalize.verify(0, Param::greaterEq);
            normalize.verify(255, Param::lessEq);
            bubble.verify(0, Param::greater);
            swap.verify(0, Param::greater);
            spline.verify(0, Param::greater);
        }
    }


    // Parameters used to construct the image
    private transient Params params;

    // A list of the fibers contained in the image
    private ArrayList<Fiber> fibers;

    // The image where fibers are drawn
    private transient BufferedImage image;

    // Visual properties of the scale bar
    private static final double TARGET_SCALE_SIZE = 0.2;
    private static final double CAP_RATIO = 0.01;
    private static final double BUFF_RATIO = 0.015;


    /**
     * Note that this doesn't generate fibers, it just instantiates the underlying data structures. {@code
     * FiberImage.generateFibers} should be called after this.
     */
    FiberImage(Params params) {
        this.params = params;
        this.fibers = new ArrayList<>(this.params.nFibers.value());
        this.image = new BufferedImage(
                params.imageWidth.value(), params.imageHeight.value(), BufferedImage.TYPE_BYTE_GRAY);
    }

    /**
     * @return An iterator over fibers in this image
     */
    @Override
    public Iterator<Fiber> iterator() {
        return fibers.iterator();
    }

    /**
     * Randomly generates fibers based on the parameters passed to the constructor.
     *
     * @throws ArithmeticException If generation fails due to non-intersection of circles - see {@code
     *                             Circle.circleCircleIntersect}
     */
    void generateFibers() throws ArithmeticException {
        ArrayList<Vector> directions = generateDirections();

        for (Vector direction : directions) {
            Fiber.Params fiberParams = new Fiber.Params();

            fiberParams.segmentLength = params.segmentLength.value();
            fiberParams.widthChange = params.widthChange.value();

            fiberParams.nSegments = (int) Math.round(params.length.sample() / params.segmentLength.value());
            fiberParams.nSegments = Math.max(1, fiberParams.nSegments);
            fiberParams.straightness = params.straightness.sample();
            fiberParams.startWidth = params.width.sample();

            double endDistance = fiberParams.nSegments * fiberParams.segmentLength * fiberParams.straightness;
            fiberParams.start = findFiberStart(endDistance, direction);
            fiberParams.end = fiberParams.start.add(direction.scalarMultiply(endDistance));

            Fiber fiber = new Fiber(fiberParams);
            fiber.generate();
            fibers.add(fiber);
        }
    }

    /**
     * Smooths each fiber according to the rules given in {@code params.bubble}, {@code params.swap}, and
     * {@code params.spline}.
     */
    void smooth() {
        for (Fiber fiber : fibers) {
            if (params.bubble.use) {
                fiber.bubbleSmooth(params.bubble.value());
            }
            if (params.swap.use) {
                fiber.swapSmooth(params.swap.value());
            }
            if (params.spline.use) {
                fiber.splineSmooth(params.spline.value());
            }
        }
    }

    /**
     * Draws fibers on a grey 8-bit image. Calling {@code getImage()} before {@code drawFibers()} will result in a black
     * image of the specified dimensions being returned.
     */
    void drawFibers() {
        Graphics2D graphics = image.createGraphics();
        graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_OFF);
        graphics.setColor(Color.WHITE);
        for (Fiber fiber : fibers) {
            for (Fiber.Segment segment : fiber) {
                graphics.setStroke(
                        new BasicStroke((float) segment.width, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
                graphics.drawLine(
                        (int) segment.start.getX(), (int) segment.start.getY(),
                        (int) segment.end.getX(), (int) segment.end.getY());
            }
        }
    }

    /**
     * Applies a distance filter, adds noise, blurs, draws a scale bar, and down samples (in that order) according to
     * the rules given in {@code params.distance}, {@code params.noise}, {@code params.blur}, {@code params.scale}, and
     * {@code params.downSample} respectively.
     */
    void applyEffects() {
        if (params.distance.use) {
            image = ImageUtility.distanceFunction(image, params.distance.value());
        }
        if (params.noise.use) {
            addNoise();
        }
        if (params.blur.use) {
            image = ImageUtility.gaussianBlur(image, params.blur.value());
        }
        if (params.scale.use) {
            drawScaleBar();
        }
        if (params.downSample.use) {
            image = ImageUtility.scale(image, params.downSample.value(), AffineTransformOp.TYPE_BILINEAR);
        }
        if (params.cap.use) {
            image = ImageUtility.cap(image, params.cap.value());
        }
        if (params.normalize.use) {
            image = ImageUtility.normalize(image, params.normalize.value());
        }
    }

    /**
     * @return A copy of the {@code BufferedImage} where fibers were drawn
     */
    BufferedImage getImage() {
        BufferedImage copy = new BufferedImage(image.getWidth(), image.getHeight(), image.getType());
        copy.getGraphics().drawImage(image, 0, 0, null);
        return copy;
    }

    /**
     * Generates a list of fiber direction vectors which collectively have the alignment and average angle set by
     * {@code params.alignment} and {@code params.meanAngle}.
     *
     * @return A list of unit vectors, each pointing in the direction of one of the fibers
     */
    private ArrayList<Vector> generateDirections() {
        double sumAngle = Math.toRadians(-params.meanAngle.value());
        Vector sumDirection = new Vector(Math.cos(sumAngle * 2.0), Math.sin(sumAngle * 2.0));
        Vector sum = sumDirection.scalarMultiply(params.alignment.value() * params.nFibers.value());

        ArrayList<Vector> chain = RngUtility.randomChain(new Vector(), sum, params.nFibers.value(), 1.0);
        ArrayList<Vector> directions = MiscUtility.toDeltas(chain);

        ArrayList<Vector> output = new ArrayList<>();
        for (Vector direction : directions) {
            double angle = direction.theta() / 2.0;
            output.add(new Vector(Math.cos(angle), Math.sin(angle)));
        }
        return output;
    }

    /**
     * Finds an optimal starting point for a fiber given the image dimensions and desired padding. If one dimension of
     * the fiber doesn't fit within the padded region we try placing it in the un-padded image. If it's still too large,
     * it's placed so that both endpoints are outside the display region (thus displaying the maximal amount of that
     * fiber).
     *
     * @param length    The length of the fiber
     * @param direction A unit vector pointing in the fiber's direction
     * @return The starting point for the fiber
     */
    private Vector findFiberStart(double length, Vector direction) {
        double xLength = direction.normalize().getX() * length;
        double yLength = direction.normalize().getY() * length;
        double x = findStart(xLength, params.imageWidth.value(), params.imageBuffer.value());
        double y = findStart(yLength, params.imageHeight.value(), params.imageBuffer.value());
        return new Vector(x, y);
    }

    /**
     * A helper to {@code findFiberStart} which finds the starting position of the fiber in one dimension (x or y).
     *
     * @param length    The length of the fiber in the chosen dimension
     * @param dimension The size of the image in the chosen dimension
     * @param buffer    The size of the buffer/padding in the chosen dimension
     * @return The starting point in the chosen dimension
     */
    private static double findStart(double length, int dimension, int buffer) {
        double min, max;
        buffer = (int) Math.max(length / 2, buffer);
        if (Math.abs(length) > dimension) {
            min = Math.min(dimension - length, dimension);
            max = Math.max(0, -length);
            return RngUtility.nextDouble(min, max);
        }
        if (Math.abs(length) > dimension - 2 * buffer) {
            buffer = 0;
        }
        min = Math.max(buffer, buffer - length);
        max = Math.min(dimension - buffer - length, dimension - buffer);
        return RngUtility.nextDouble(min, max);
    }

    /**
     * Draws a scale in the lower-left corner of the image. The scale's length is either a power of 10 or a half power
     * of 10 and its width is approximately {@code TARGET_SCALE_SIZE} percent of the image's width.
     */
    private void drawScaleBar() {

        // Determine the size in microns of the scale bar
        double targetSize = TARGET_SCALE_SIZE * image.getWidth() / params.scale.value();
        double floorPow = Math.floor(Math.log10(targetSize));
        double[] options = {Math.pow(10, floorPow), 5 * Math.pow(10, floorPow), Math.pow(10, floorPow + 1)};
        double bestSize = options[0];
        for (double size : options) {
            if (Math.abs(targetSize - size) < Math.abs(targetSize - bestSize)) {
                bestSize = size;
            }
        }

        // Format the scale label
        String label;
        if (Math.abs(Math.floor(Math.log10(bestSize))) <= 2) {
            label = new DecimalFormat("0.## \u00B5").format(bestSize);
        } else {
            label = String.format("%.1e \u00B5", bestSize);
        }

        // Determine pixel dimensions of the scale bar
        int capSize = (int) (CAP_RATIO * image.getHeight());
        int xBuff = (int) (BUFF_RATIO * image.getWidth());
        int yBuff = (int) (BUFF_RATIO * image.getHeight());
        int scaleHeight = image.getHeight() - yBuff - capSize;
        int scaleRight = xBuff + (int) (bestSize * params.scale.value());

        // Draw the scale bar and label
        Graphics2D graphics = image.createGraphics();
        graphics.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        graphics.drawLine(xBuff, scaleHeight, scaleRight, scaleHeight);
        graphics.drawLine(xBuff, scaleHeight + capSize, xBuff, scaleHeight - capSize);
        graphics.drawLine(scaleRight, scaleHeight + capSize, scaleRight, scaleHeight - capSize);
        graphics.drawString(label, xBuff, scaleHeight - capSize - yBuff);
    }

    /**
     * Adds Poisson-distributed noise to the image.
     */
    private void addNoise() {

        // Sequence of poisson seeds depends on the initial rng seed
        PoissonDistribution noise = new PoissonDistribution(params.noise.value());
        noise.reseedRandomGenerator(RngUtility.rng.nextInt());

        WritableRaster raster = image.getRaster();
        int[] pixel = new int[1];
        for (int y = 0; y < image.getHeight(); y++) {
            for (int x = 0; x < image.getWidth(); x++) {
                raster.getPixel(x, y, pixel);
                pixel[0] = Math.min(0xFF, pixel[0] + noise.sample());
                raster.setPixel(x, y, pixel);
            }
        }
    }
}
