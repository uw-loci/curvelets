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
import java.util.Random;


/**
 * A wrapper for a static Random object and associated utility methods.
 */
class RngUtility {

    // The static Random member
    static Random rng = new Random();


    /**
     * @param xMin The minimum x-value (inclusive)
     * @param xMax The maximum x-value (exclusive)
     * @param yMin The minimum y-value (inclusive)
     * @param yMax The maximum x-value (exclusive)
     * @return A random point ({@code Vector}) in 2D space within the specified bounds
     */
    static Vector nextPoint(double xMin, double xMax, double yMin, double yMax) {
        double x = nextDouble(xMin, xMax);
        double y = nextDouble(yMin, yMax);
        return new Vector(x, y);
    }

    /**
     * @param min The minimum value (inclusive)
     * @param max The maximum value (exclusive)
     * @return A random integer within the specified bounds
     * @throws IllegalArgumentException If {@code min >= max}
     */
    static int nextInt(int min, int max) {
        if (min > max) {
            throw new IllegalArgumentException("Random bounds are inverted");
        } else if (min == max) {
            throw new IllegalArgumentException("Random range must have nonzero size");
        }
        return min + rng.nextInt(max - min);
    }

    /**
     * Due to the behavior of {@code Random.nextDouble()}, {@code min} is inclusive but {@code max} is exclusive. In
     * practice this doesn't matter as the exact minimum value is only generated ~1/2^54 times.
     *
     * @param min The minimum value (inclusive)
     * @param max The maximum value (exclusive)
     * @return A random double within the specified bounds
     * @throws IllegalArgumentException If {@code min > max}
     */
    static double nextDouble(double min, double max) {
        if (min > max) {
            throw new IllegalArgumentException("Random bounds are inverted");
        }
        return min + rng.nextDouble() * (max - min);
    }

    /**
     * Constructs a 2D pseudo-random walk between the specified starting and ending points.
     *
     * @param start    The 2D starting point
     * @param end      The 2D ending point
     * @param nSteps   The number of steps in the walk
     * @param stepSize The distance (2-norm) covered by each step
     * @return The generated random chain
     * @throws ArithmeticException If no path exists (i.e. the distance between {@code start} and {@code end} is greater
     *                             than {@code nSteps*stepSize}
     */
    static ArrayList<Vector> randomChain(Vector start, Vector end, int nSteps, double stepSize)
            throws ArithmeticException {
        if (nSteps <= 0) {
            throw new IllegalArgumentException("Must have at least one step");
        }
        if (stepSize <= 0.0) {
            throw new IllegalArgumentException("Step size must be positive");
        }
        ArrayList<Vector> points = new ArrayList<>(Collections.nCopies(nSteps + 1, null));
        points.set(0, start);
        points.set(nSteps, end);
        randomChainRecursive(points, 0, nSteps, stepSize);
        return points;
    }

    /**
     * Recursive helper for {@code randomChain}.
     *
     * @param points   The data structure where points are being stored
     * @param iStart   The beginning of the current section of the path under consideration
     * @param iEnd     The end of the current section of the path under consideration
     * @param stepSize The distance (2-norm) covered by each step
     * @throws ArithmeticException If no path exists between the points at {@code iStart} and {@code iEnd}
     */
    private static void randomChainRecursive(ArrayList<Vector> points, int iStart, int iEnd, double stepSize)
            throws ArithmeticException {
        if (iEnd - iStart <= 1) {
            return;
        }

        int iBridge = (iStart + iEnd) / 2;
        Circle circle1 = new Circle(points.get(iStart), stepSize * (iBridge - iStart));
        Circle circle2 = new Circle(points.get(iEnd), stepSize * (iEnd - iBridge));
        Vector bridge;
        if (iBridge > iStart + 1 && iBridge < iEnd - 1) {
            bridge = Circle.diskDiskIntersect(circle1, circle2);
        } else if (iBridge == iStart + 1 && iBridge == iEnd - 1) {
            Vector[] intersects = Circle.circleCircleIntersect(circle1, circle2);
            bridge = RngUtility.rng.nextBoolean() ? intersects[0] : intersects[1];
        } else if (iBridge == iStart + 1) {
            bridge = Circle.diskCircleIntersect(circle2, circle1);
        } else {
            bridge = Circle.diskCircleIntersect(circle1, circle2);
        }
        points.set(iBridge, bridge);

        randomChainRecursive(points, iStart, iBridge, stepSize);
        randomChainRecursive(points, iBridge, iEnd, stepSize);
    }
}
