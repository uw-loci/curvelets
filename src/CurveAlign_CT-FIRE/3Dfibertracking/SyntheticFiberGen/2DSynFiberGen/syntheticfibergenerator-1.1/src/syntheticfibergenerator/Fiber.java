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

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;

import org.apache.commons.math3.analysis.interpolation.SplineInterpolator;
import org.apache.commons.math3.analysis.polynomials.PolynomialSplineFunction;


/**
 * Represents a fiber: a series of points in 2D space with a width between each pair of points.
 */
class Fiber implements Iterable<Fiber.Segment> {

    /**
     * The information needed to construct a fiber. These aren't wrapped as {@code Param} objects because they aren't
     * directly parsed from user input.
     */
    static class Params {

        double segmentLength;
        double widthChange;

        int nSegments;
        double startWidth;
        double straightness;

        Vector start;
        Vector end;
    }

    /**
     * A linear piece of a fiber (defined by two endpoints and the width between them).
     */
    static class Segment {

        // Segment starting point
        Vector start;

        // Segment ending point
        Vector end;

        // Segment width
        double width;


        /**
         * @param start The segment's starting point
         * @param end   The segment's ending point
         * @param width The width of the segment
         */
        Segment(Vector start, Vector end, double width) {
            this.start = start;
            this.end = end;
            this.width = width;
        }
    }

    /**
     * Allows for iteration over a fiber's segments.
     */
    class SegmentIterator implements Iterator<Segment> {

        // Index of the current segment
        int curr = 0;


        /**
         * @return A copy of the next segment if it exists; null otherwise
         */
        public Segment next() {
            if (hasNext()) {
                Segment output = new Segment(points.get(curr), points.get(curr + 1), widths.get(curr));
                curr++;
                return output;
            } else {
                return null;
            }
        }

        /**
         * @return {@code false} if the next call to {@code this.next()} will return null, {@code true} otherwise
         */
        public boolean hasNext() {
            return curr < points.size() - 1;
        }
    }


    // Parameters used to construct the fiber
    private Params params;

    // The points constituting the fiber
    private ArrayList<Vector> points;

    // Width between each pair of points (has length points.size() - 1)
    private ArrayList<Double> widths;


    /**
     * Note that this doesn't generate segments, it just instantiates the underlying data structures. {@code
     * generate()} should be called after this.
     */
    Fiber(Params params) {
        this.params = params;
        this.points = new ArrayList<>();
        this.widths = new ArrayList<>();
    }

    /**
     * @return An iterator over segments of this fiber
     */
    @Override
    public Iterator<Segment> iterator() {
        return new SegmentIterator();
    }

    /**
     * @return A copy of this fiber's points array
     */
    ArrayList<Vector> getPoints() {
        return new ArrayList<>(points);
    }

    /**
     * @return A unit vector pointing in the direction of this fiber
     */
    Vector getDirection() {
        return params.end.subtract(params.start).normalize();
    }

    /**
     * Randomly generates fiber segments based on the parameters passed to the constructor.
     *
     * @throws ArithmeticException If the distance between the endpoints is greater than the fiber length (beyond some
     *                             small allowed margin of error)
     */
    void generate() throws ArithmeticException {
        points = RngUtility.randomChain(params.start, params.end, params.nSegments, params.segmentLength);
        double width = params.startWidth;
        for (int i = 0; i < params.nSegments; i++) {
            widths.add(width);
            double variability = Math.min(Math.abs(width), params.widthChange);
            width += RngUtility.nextDouble(-variability, variability);
        }
    }

    /**
     * Attempts to minimize the sum of angles between adjacent segments by reordering them. Swaps adjacent segments if
     * doing so reduces the overall sum of angle changes. Note that the sequence of widths remains unchanged after a
     * call to this method - widths are not carried through a swap.
     *
     * @param passes The number of times to pass over the fiber
     */
    void bubbleSmooth(int passes) {
        ArrayList<Vector> deltas = MiscUtility.toDeltas(points);
        for (int i = 0; i < passes; i++) {
            for (int j = 0; j < deltas.size() - 1; j++) {
                trySwap(deltas, j, j + 1);
            }
        }
        points = MiscUtility.fromDeltas(deltas, points.get(0));
    }

    /**
     * Attempts to minimize the sum of angles between adjacent segments by reordering them. Swaps random pairs of
     * segments if doing so reduces the overall sum of angle changes. Note that the sequence of widths remains unchanged
     * after a call to this method - widths are not carried through a swap.
     *
     * @param ratio The average number of attempted swaps per segment
     */
    void swapSmooth(int ratio) {
        ArrayList<Vector> deltas = MiscUtility.toDeltas(points);
        for (int j = 0; j < ratio * deltas.size(); j++) {
            int u = RngUtility.rng.nextInt(deltas.size());
            int v = RngUtility.rng.nextInt(deltas.size());
            trySwap(deltas, u, v);
        }
        points = MiscUtility.fromDeltas(deltas, points.get(0));
    }

    /**
     * Makes the fiber appear smoother by adding interpolated points along each segment. No interpolation is done for
     * widths; they're simply copied from the original segment.
     *
     * @param splineRatio {@code 1-splineRatio} gives the number of interpolated points along each segment
     */
    void splineSmooth(int splineRatio) {
        if (params.nSegments <= 1) {
            return;
        }

        SplineInterpolator interpolator = new SplineInterpolator();
        double[] tPoints = new double[points.size()];
        double[] xPoints = new double[points.size()];
        double[] yPoints = new double[points.size()];
        for (int i = 0; i < points.size(); i++) {
            tPoints[i] = i;
            xPoints[i] = points.get(i).getX();
            yPoints[i] = points.get(i).getY();
        }
        @SuppressWarnings("SuspiciousNameCombination")
        PolynomialSplineFunction xFunc = interpolator.interpolate(tPoints, xPoints);
        PolynomialSplineFunction yFunc = interpolator.interpolate(tPoints, yPoints);

        ArrayList<Vector> newPoints = new ArrayList<>();
        ArrayList<Double> newWidths = new ArrayList<>();
        for (int i = 0; i < (points.size() - 1) * splineRatio + 1; i++) {
            if (i % splineRatio == 0) {
                newPoints.add(points.get(i / splineRatio));
            } else {
                double t = (double) i / splineRatio;
                newPoints.add(new Vector(xFunc.value(t), yFunc.value(t)));
            }
            if (i < (points.size() - 1) * splineRatio) {
                newWidths.add(widths.get(i / splineRatio));
            }
        }
        points = newPoints;
        widths = newWidths;
    }

    /**
     * A helper for {@code bubbleSmooth()} and {@code swapSmooth()} which swaps the segments at indices {@code u} and
     * {@code v} if doing so reduces the sum of angle changes.
     *
     * @param deltas A representation of the fiber as a sequence of direction vectors
     * @param u      First index for the swap
     * @param v      Second index for the swap
     */
    private static void trySwap(ArrayList<Vector> deltas, int u, int v) {
        double oldDiff = localDiffSum(deltas, u, v);
        Collections.swap(deltas, u, v);
        double newDiff = localDiffSum(deltas, u, v);
        if (newDiff > oldDiff) {
            Collections.swap(deltas, u, v);
        }
    }

    /**
     * A helper for {@code trySwap}.
     *
     * @param deltas A representation of the fiber as a sequence of direction vectors
     * @param u      First index around which angle changes should be added
     * @param v      Second index around which angle changes should be added
     * @return The sum of angle changes around the indices {@code u} and {@code v}
     */
    private static double localDiffSum(ArrayList<Vector> deltas, int u, int v) {
        int i1 = Math.min(u, v);
        int i2 = Math.max(u, v);
        if (i1 < 0 || i2 > deltas.size() - 1) {
            throw new ArrayIndexOutOfBoundsException("u and v must be within the array");
        }

        double sum = 0.0;
        if (i1 > 0) { // Don't do this if i1 is right against the beginning of the array
            sum += deltas.get(i1 - 1).angleWith(deltas.get(i1));
        }
        if (i1 < i2) { // If i1 < i2 then i1 + 1 <= deltas.size() - 1
            sum += deltas.get(i1).angleWith(deltas.get(i1 + 1));
        }
        if (i1 < i2 - 1) { // Prevent double-counting of the space between i1 and i2 if they're adjacent
            sum += deltas.get(i2 - 1).angleWith(deltas.get(i2));
        }
        if (i2 < deltas.size() - 1) { // Don't do this if i2 is right against the end of the array
            sum += deltas.get(i2).angleWith(deltas.get(i2 + 1));
        }
        return sum;
    }
}