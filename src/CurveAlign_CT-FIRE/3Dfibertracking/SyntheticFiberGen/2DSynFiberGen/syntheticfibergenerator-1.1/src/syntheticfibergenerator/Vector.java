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

import org.apache.commons.math3.geometry.euclidean.twod.Vector2D;


/**
 * An extension of the Apache Math Commons Vector2D class with added methods. Instances of this class are immutable (due
 * to the implementation of Vector2D)
 */
public class Vector extends Vector2D {

    /**
     * Default constructor; sets the x and y coordinates to zero.
     */
    Vector() {
        super(0.0, 0.0);
    }

    /**
     * @param x The x-component of the vector
     * @param y The y-component of the vector
     */
    Vector(double x, double y) {
        super(x, y);
    }

    private Vector(Vector2D vec) {
        this(vec.getX(), vec.getY());
    }

    /**
     * Wrapper for {@code Vector2D.normalize()} which returns a {@code Vector}.
     *
     * @return A unit vector with the same direction as this vector
     */
    public Vector normalize() {
        return new Vector(super.normalize());
    }

    /**
     * Wrapper for {@code Vector2D.scalarMultiply} which returns a {@code Vector}.
     *
     * @param scalar The scalar by which this vector should be multiplied
     * @return A vector pointing in the same direction as this vector but scaled by the specified factor
     */
    public Vector scalarMultiply(double scalar) {
        return new Vector(super.scalarMultiply(scalar));
    }

    /**
     * Wrapper for {@code Vector2D.add} which returns a {@code Vector}.
     *
     * @param other The vector which should be added to this vector
     * @return The sum of this vector and {@code other}
     */
    Vector add(Vector2D other) {
        return new Vector(super.add(other));
    }

    Vector subtract(Vector2D other) {
        return new Vector(super.subtract(other));
    }

    /**
     * The behavior for a zero or NaN vector is given in the {@code Math.atan2} specification.
     *
     * @return The angle in radians of this with respect to the positive x-axis (in the range -pi to pi)
     */
    double theta() {
        return Math.atan2(getY(), getX());
    }

    /**
     * @param other The vector whose angle with this vector we want to find
     * @return The angle in radians between this vector and {@code other} (in the range -pi to pi)
     */
    double angleWith(Vector other) {
        if (this.isZero() || other.isZero()) {
            throw new ArithmeticException("Cannot compute angle between vectors if one is zero");
        }
        double cos = this.normalize().dotProduct(other.normalize());
        cos = Math.min(+1, cos);
        cos = Math.max(-1, cos);
        return Math.acos(cos);
    }

    /**
     * Rotates this vector counter-clockwise by the angle {@code oldXAxis.theta()}, transforming from the coordinate
     * system where {@code oldXAxis} is the x-axis to an un-rotated frame.
     *
     * @param oldXAxis The x-axis of the current, rotated frame
     * @return A de-rotated version of this vector
     */
    Vector unRotate(Vector oldXAxis) {
        if (oldXAxis.isZero()) {
            throw new ArithmeticException("New x-axis must be nonzero");
        }
        oldXAxis = oldXAxis.normalize();
        Vector newYAxis = new Vector(-oldXAxis.getY(), oldXAxis.getX());
        Vector xRotated = oldXAxis.scalarMultiply(getX());
        Vector yRotated = newYAxis.scalarMultiply(getY());
        return xRotated.add(yRotated);
    }

    /**
     * @return True if the x and y components are both zero
     */
    private boolean isZero() {
        return getX() == 0 && getY() == 0;
    }
}
