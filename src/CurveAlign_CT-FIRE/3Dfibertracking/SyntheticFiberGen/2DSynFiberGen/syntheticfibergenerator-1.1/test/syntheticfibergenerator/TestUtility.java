package syntheticfibergenerator;

import org.apache.commons.math3.util.MathUtils;

import java.awt.image.BufferedImage;
import java.util.ArrayList;


class TestUtility {

    static double alignment(FiberImage image, FiberImage.Params params) {
        return complexMean(image, params).getNorm();
    }

    static double meanAngle(FiberImage image, FiberImage.Params params) {
        double angle = MathUtils.normalizeAngle(-complexMean(image, params).theta() / 2.0, Math.PI) * 180.0 / Math.PI;
        return angle > 180.0 ? angle - 180.0 : angle;
    }

    static <T extends Comparable <T>> Param<T> fromValue(T value, Param.Parser<T> parser) {
        Param<T> param = new Param<>();
        param.parse(value.toString(), parser);
        return param;
    }

    static double angleChangeSum(Fiber fiber) {
        ArrayList<Vector> deltas = MiscUtility.toDeltas(fiber.getPoints());
        double sum = 0.0;
        for (int i = 0; i < deltas.size() - 1; i++) {
            sum += deltas.get(i).angleWith(deltas.get(i + 1));
        }
        return sum;
    }

    static boolean sizeTypeMatch(BufferedImage expected, BufferedImage actual) {
        return  expected.getWidth() == actual.getWidth() &&
                expected.getHeight() == actual.getHeight() &&
                expected.getType() == actual.getType();
    }

    static boolean pixelWiseEqual(BufferedImage expected, BufferedImage actual) {
        if (!sizeTypeMatch(expected, actual)) {
            return false;
        }
        for (int y = 0; y < expected.getHeight(); y++) {
            for (int x = 0; x < expected.getWidth(); x++) {
                if (expected.getRGB(x, y) != actual.getRGB(x, y)) {
                    return false;
                }
            }
        }
        return true;
    }

    static boolean elementWiseEqual(ArrayList<Vector> expected, ArrayList<Vector> actual, double delta) {
        if (expected.size() != actual.size()) {
            return false;
        }
        for (int i = 0; i < expected.size(); i++) {
            if (!TestUtility.vectorsEquals(expected.get(i), actual.get(i), delta)) {
                return false;
            }
        }
        return true;
    }

    static Vector fromAngle(double angle) {
        return new Vector(Math.cos(angle), Math.sin(angle));
    }

    static boolean vectorsEquals(Vector expected, Vector actual, double delta) {
        return valuesEqual(expected.getX(), actual.getX(), delta) && valuesEqual(expected.getY(), actual.getY(), delta);
    }

    private static Vector complexMean(FiberImage image, FiberImage.Params params) {
        Vector sum = new Vector();
        for (Fiber fiber : image) {
            double theta = fiber.getDirection().theta();
            Vector direction = new Vector(Math.cos(2.0 * theta), Math.sin(2.0 * theta));
            sum = sum.add(direction);
        }
        return sum.scalarMultiply(1.0 / params.nFibers.value());
    }

    private static boolean valuesEqual(double expected, double actual, double delta) {
        return Math.abs(expected - actual) <= delta;
    }
}
