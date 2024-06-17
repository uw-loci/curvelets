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

import com.google.gson.*;

import java.lang.reflect.Type;
import java.util.ArrayList;


/**
 * Abstract class representing a distribution over the real numbers with fixed bounds {@code lowerBound} and {@code
 * upperBound}.
 */
abstract class Distribution {

    /**
     * Determines the context for the JSON deserialization of a {@code Distribution} based on the {@code "type"} field.
     */
    static class Deserializer implements JsonDeserializer<Distribution> {

        @Override
        public Distribution deserialize(JsonElement element, Type type, JsonDeserializationContext context)
                throws JsonParseException {
            JsonObject object = element.getAsJsonObject();
            String className = object.get("type").getAsString();
            switch (className) {
                case Gaussian.typename:
                    return context.deserialize(element, Gaussian.class);
                case Uniform.typename:
                    return context.deserialize(element, Uniform.class);
                case PiecewiseLinear.typename:
                    return context.deserialize(element, PiecewiseLinear.class);
                default:
                    throw new JsonParseException("Unknown distribution typename: " + className);
            }
        }
    }

    /**
     * Includes the {@code getType} string with the output JSON.
     */
    static class Serializer implements JsonSerializer<Distribution> {

        @Override
        public JsonElement serialize(Distribution distribution, Type type, JsonSerializationContext context) {
            JsonElement output = context.serialize(distribution);
            output.getAsJsonObject().addProperty("type", distribution.getType());
            return output;
        }
    }

    /* lowerBound and upperBound are tagged as transient (non-serializable), because modifying them outside the source
     * can result in undefined behavior. */

    // The minimum possible for values sampled from this distribution
    transient double lowerBound;

    // The maximum possible fro values sampled from this distribution
    transient double upperBound;


    /**
     * @return A deep copy of this object
     */
    public abstract Object clone();

    /**
     * @param lowerBound The lower bound for this distribution
     * @param upperBound The upper bound for this distribution
     */
    @SuppressWarnings("SameParameterValue")
    void setBounds(double lowerBound, double upperBound) {
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
    }

    /**
     * @return The type of the distribution (e.g. "Gaussian" or "Uniform")
     */
    abstract String getType();

    /**
     * @return A string representation of this distribution for displaying to the user
     */
    abstract String getString();

    /**
     * @return A random value sampled from this distribution
     */
    abstract double sample();

    /**
     * This isn't part of the constructor because Distribution objects are often constructed during their
     * deserialization from JSON and the JSON representation doesn't contain names.
     */
    abstract void setNames();

    /**
     * Not part of the constructor for the same reason as setNames().
     */
    abstract void setHints();

    /**
     * Verify that this distribution is valid and doesn't violate the lower/upper bounds (if applicable).
     *
     * @throws IllegalArgumentException If the verification fails
     */
    abstract void verify() throws IllegalArgumentException;
}

/**
 * A normal/Gaussian distribution with some mean and standard deviation. The mean is not required to lie within the
 * range {@code (lowerBound, upperBound)} - if it doesn't we just sample from one of the tails.
 */
class Gaussian extends Distribution {

    // The mean/peak of the normal distribution
    Param<Double> mean = new Param<>();

    // The standard deviation of the normal distribution
    Param<Double> sigma = new Param<>();

    // To see whether a distribution is Gaussian use distribution.getType().equals(Gaussian.typename)
    transient static final String typename = "Gaussian";


    /**
     * @param lowerBound The lower bound for this distribution
     * @param upperBound The upper bound for this distribution
     */
    Gaussian(double lowerBound, double upperBound) {
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
        setNames();
        setHints();
    }

    /**
     * @return A deep copy of this object
     */
    public Object clone() {
        Gaussian clone = new Gaussian(this.lowerBound, this.upperBound);
        clone.mean.parse(this.mean.string(), Double::parseDouble);
        clone.sigma.parse(this.sigma.string(), Double::parseDouble);
        return clone;
    }

    /**
     * @return "Uniform"
     */
    public String getType() {
        return typename;
    }

    /**
     * @return The string "Gaussian: mean=val, sigma=val"
     */
    public String getString() {
        return String.format(getType() + ": \u03BC=%s, \u03C3=%s", mean.string(), sigma.string());
    }

    /**
     * Note that this may need to sample many times if the range {@code (lowerBound, upperBound)} is in one of the
     * extreme tails of the distribution.
     *
     * @return A value sampled from this distribution between lowerBound (inclusive) and upperBound (exclusive)
     */
    public double sample() {
        double val;
        do {
            val = RngUtility.rng.nextGaussian() * sigma.value() + mean.value();
        }
        while (val < lowerBound || val > upperBound);
        return val;
    }

    /**
     * See notes for {@code Distribution.setNames()}.
     */
    void setNames() {
        mean.setName("mean");
        sigma.setName("sigma");
    }

    /**
     * See notes for {@code Distribution.setHints()}.
     */
    void setHints() {
        mean.setHint("Mean of the Gaussian");
        sigma.setHint("Standard deviation of the Gaussian");
    }

    /**
     * See notes for {@code Distribution.verify()}.
     */
    void verify() {
        if (sigma.value() <= 0) {
            throw new IllegalArgumentException("Standard deviation " + sigma + " is not positive");
        }
    }
}

/**
 * A flat/uniform distribution with some min and max. If the min is less than {@code lowerBound} or the max is greater
 * than {@code upperBound} they are automatically adjusted when {@code sample} is called.
 */
class Uniform extends Distribution {

    // The minimum of the uniform distribution
    Param<Double> min = new Param<>();

    // The maximum of the uniform distribution
    Param<Double> max = new Param<>();

    // To see whether a distribution is uniform use distribution.getType().equals(Uniform.typename)
    transient static final String typename = "Uniform";


    /**
     * @param lowerBound The lower bound for this distribution
     * @param upperBound The upper bound for this distribution
     */
    Uniform(double lowerBound, double upperBound) {
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
        setNames();
        setHints();
    }

    /**
     * @return A deep copy of this object
     */
    public Object clone() {
        Uniform clone = new Uniform(this.lowerBound, this.upperBound);
        clone.min.parse(this.min.string(), Double::parseDouble);
        clone.max.parse(this.max.string(), Double::parseDouble);
        return clone;
    }

    /**
     * @return "Uniform"
     */
    public String getType() {
        return typename;
    }

    /**
     * @return The string "Uniform: min-max"
     */
    public String getString() {
        return String.format(getType() + ": %s-%s", min.string(), max.string());
    }

    /**
     * @return A value between Math.max(lowerBound, min) inclusive and Math.min(upperBound, max) exclusive
     */
    public double sample() {
        double trimMin = Math.max(lowerBound, min.value());
        double trimMax = Math.min(upperBound, max.value());
        return RngUtility.nextDouble(trimMin, trimMax);
    }

    /**
     * See notes for {@code Distribution.setNames()}.
     */
    void setNames() {
        min.setName("minimum");
        max.setName("maximum");
    }

    /**
     * See notes for {@code Distribution.setHints()}.
     */
    void setHints() {
        min.setHint("Minimum of the uniform distribution (inclusive)");
        max.setHint("Maximum of the uniform distribution (inclusive)");
    }

    /**
     * See notes for {@code Distribution.verify()}.
     */
    void verify() {
        if (min.value() > max.value()) {
            throw new IllegalArgumentException(
                    "Uniform distribution minimum " + min.value() + " exceeds maximum " + max.value());
        } else if (min.value() > upperBound) {
            throw new IllegalArgumentException(
                    "Uniform distribution minimum " + min.value() + " exceeds upper bound " + upperBound);
        } else if (max.value() < lowerBound) {
            throw new IllegalArgumentException(
                    "Uniform distribution maximum" + max.value() + " is less than lower bound " + lowerBound);
        }
    }
}

/**
 * A piecewise linear distribution defined by a set of x, y points. A histogram can be represented as a piecewise linear
 * distribution by only changing either x or y between adjacent pairs of points. The probability before the first
 * x-coordinate and after the last x-coordinate is zero.
 */
class PiecewiseLinear extends Distribution {

    // The x, y points comprising the distribution (not normalized to have unit integral)
    private ArrayList<double[]> distribution = new ArrayList<>();

    // To see whether a distribution is PiecewiseLinear use distribution.getType().equals(PiecewiseLinear.typename)
    transient static final String typename = "Piecewise Linear";


    /**
     * @param lowerBound The lower bound for this distribution
     * @param upperBound The upper bound for this distribution
     */
    PiecewiseLinear(double lowerBound, double upperBound) {
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
        setNames();
        setHints();
    }

    /**
     * @return A deep copy of this object
     */
    public Object clone() {
        PiecewiseLinear clone = new PiecewiseLinear(this.lowerBound, this.upperBound);
        clone.distribution = new ArrayList<>(this.distribution);
        return clone;
    }

    /**
     * @return "Piecewise Linear"
     */
    public String getType() {
        return typename;
    }

    /**
     * @return "Piecewise Linear" (this may be changed at a later point to include more specific information)
     */
    public String getString() {
        return "Piecewise linear";
    }

    /**
     * @return A value sampled from the piecewise linear distribution. The tails (beyond the minimum and maximum
     * specified x values) have zero probability density.
     */
    public double sample() {
        double integral = 0.0;
        for (int i = 0; i < distribution.size() - 1; i++) {
            double[] p1 = distribution.get(i);
            double[] p2 = distribution.get(i + 1);
            integral += 0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0]);
        }
        ArrayList<double[]> normalized = new ArrayList<>();
        for (double[] point : distribution) {
            normalized.add(new double[]{point[0], point[1] / integral});
        }

        // Corresponds to the index of the x-value we've last integrated to
        int i = 0;
        double cdf = 0.0;
        double rand = RngUtility.rng.nextDouble();
        double cdfPrev = 0.0;
        for (; i < normalized.size() - 1 && cdf < rand; i++) {
            cdfPrev = cdf;

            // Add the area under this section of the curve
            double[] p1 = normalized.get(i);
            double[] p2 = normalized.get(i + 1);
            cdf += 0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0]);
        }

        // This is the integral of the distribution from i to our output x
        double cdfRemain = rand - cdfPrev;

        if (i == 0) {
            return normalized.get(0)[0];
        } else if (i == normalized.size()) {
            return normalized.get(normalized.size() - 1)[0];
        }

        double[] p1 = normalized.get(i - 1);
        double[] p2 = normalized.get(i);
        double x1 = p1[0];
        double y1 = p1[1];
        double x2 = p2[0];
        double y2 = p2[1];

        double m = (y2 - y1) / (x2 - x1);
        double a = 0.5 * m;
        double b = y1 - m * x1;
        double c = 0.5 * m * x1 * x1 - y1 * x1 - cdfRemain;

        // Solve quadratic
        double b4ac = b * b - 4 * a * c;
        if (b4ac < 0) {
            throw new ArithmeticException("Sampling failure (no real quadratic roots)");
        } else {
            double root0 = (-b + Math.sqrt(b4ac)) / (2 * a);
            double root1 = (-b - Math.sqrt(b4ac)) / (2 * a);
            if (root0 >= x1 && root1 <= x2) {
                return x1;
            } else {
                return x2;
            }
        }
    }

    /**
     * This is empty since the {@code distribution} member doesn't correspond directly to a GUI field.
     */
    void setNames() {
    }

    /**
     * This is empty since the {@code distribution} member doesn't correspond directly to a GUI field.
     */
    void setHints() {
    }

    /**
     * See notes for {@code Distribution.verify()}.
     */
    void verify() {
        double lastX = Double.NEGATIVE_INFINITY;
        for (double[] point : distribution) {
            if (point[0] < lastX) {
                throw new IllegalArgumentException("Piecewise linear x-coordinates out of order (" + lastX + ", " + point[0] + ")");
            }
            lastX = point[0];
            if (point[1] < 0) {
                throw new IllegalArgumentException("Negative piecewise linear probability " + point[1]);
            }
        }
        if (distribution.get(0)[0] < lowerBound) {
            throw new IllegalArgumentException(
                    "Piecewise linear distribution extends below lower bound of " + lowerBound);
        }
        if (distribution.get(distribution.size() - 1)[0] > upperBound) {
            throw new IllegalArgumentException(
                    "Piecewise linear distribution extends above upper bound of " + upperBound);
        }
    }

    /**
     * @return A string containing comma-separated x values for this distribution
     */
    String getXString() {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < distribution.size(); i++) {
            builder.append(distribution.get(i)[0]);
            if (i < distribution.size() - 1) {
                builder.append(',');
            }
        }
        return builder.toString();
    }

    /**
     * @return A string containing comma-separated y values for this distribution
     */
    String getYString() {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < distribution.size(); i++) {
            builder.append(distribution.get(i)[1]);
            if (i < distribution.size() - 1) {
                builder.append(',');
            }
        }
        return builder.toString();
    }

    /**
     * Takes two strings from the GUI and parses them into the {@code distribution} member.
     *
     * @param xString A string of comma-separated x-values (e.g. "1.0, 2.0, 5.5")
     * @param yString A string of comma-separated y-values (e.g. "0.6, 0.3, 0.3")
     * @throws IllegalArgumentException If the strings can't be parsed to a valid, in-bounds distribution
     */
    void parseXYValues(String xString, String yString) throws IllegalArgumentException {
        String[] xTokens = xString.split(",");
        String[] yTokens = yString.split(",");
        if (xTokens.length != yTokens.length) {
            throw new IllegalArgumentException("Number of x points and y points must be equal");
        }
        if (xTokens.length == 0) {
            throw new IllegalArgumentException("Must have a nonzero number of points in distribution");
        }
        distribution = new ArrayList<>();
        for (int i = 0; i < xTokens.length; i++) {
            double[] point = new double[2];
            try {
                point[0] = Double.parseDouble(xTokens[i]);
            } catch (Exception e) {
                throw new IllegalArgumentException("Invalid x-coordinate \"" + xTokens[i] + "\"");
            }
            try {
                point[1] = Double.parseDouble(yTokens[i]);
            } catch (Exception e) {
                throw new IllegalArgumentException("Invalid y-coordinate \"" + yTokens[i] + "\"");
            }
            distribution.add(point);
        }
    }
}