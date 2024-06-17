package syntheticfibergenerator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;

import static org.junit.jupiter.api.Assertions.*;


class RngUtilityTest {

    private static final int N_LOOPS = 100;
    private static final double DELTA = 1e-6;


    /**
     * Fix the random seed so we get consistent tests.
     */
    @BeforeEach
    void setUp() {
        RngUtility.rng.setSeed(1);
    }

    @Test
    void testRandomPoint() {
        double xMin = -10.0;
        double xMax = 356.2;
        double yMin = 500.3;
        double yMax = 988.1;
        for (int i = 0; i < N_LOOPS; i++) {
            Vector point = RngUtility.nextPoint(xMin, xMax, yMin, yMax);
            assertTrue(point.getX() >= xMin && point.getX() < xMax);
            assertTrue(point.getY() >= yMin && point.getY() < yMax);
        }
    }

    @Test
    void testRandomPointInverted() {
        double xMin = 356.2;
        double xMax = -10.0;
        double yMin = 500.3;
        double yMax = 988.1;
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.nextPoint(xMin, xMax, yMin, yMax));
    }

    @Test
    void testRandomPointZeroHeight() {
        double xMin = -10.0;
        double xMax = 356.2;
        double y = 500.3;
        for (int i = 0; i < N_LOOPS; i++) {
            Vector point = RngUtility.nextPoint(xMin, xMax, y, y);
            assertEquals(y, point.getY());
            assertTrue(point.getX() >= xMin && point.getX() < xMax);
        }
    }

    @Test
    void testRandomPointZeroVolume() {
        double x = -10.0;
        double y = 500.3;
        for (int i = 0; i < N_LOOPS; i++) {
            Vector point = RngUtility.nextPoint(x, x, y, y);
            assertEquals(x, point.getX());
            assertEquals(y, point.getY());
        }
    }

    @Test
    void testRandomDouble() {
        double min = 3.14;
        double max = 18.2;
        for (int i = 0; i < N_LOOPS; i++) {
            double val = RngUtility.nextDouble(min, max);
            assertTrue(val >= min && val < max);
        }
    }

    @Test
    void testRandomDoubleInverted() {
        double min = 18.2;
        double max = 3.14;
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.nextDouble(min, max));
    }

    @Test
    void testRandomDoubleZeroWidth() {
        double val = 18.2;
        for (int i = 0; i < 100; i++) {
            assertEquals(val, RngUtility.nextDouble(val, val));
        }
    }

    @Test
    void testRandomInt() {
        int min = 17;
        int max = 312;
        for (int i = 0; i < N_LOOPS; i++) {
            int val = RngUtility.nextInt(min, max);
            assertTrue(val >= min && val < max);
        }
    }

    @Test
    void testRandomIntInverted() {
        int min = 312;
        int max = 17;
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.nextInt(min, max));
    }

    @Test
    void testRandomIntZeroWidth() {
        int val = 312;
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.nextInt(val, val));
    }

    @Test
    void testRandomChain() {
        int nSteps = 23;
        double stepSize = 7.0;
        Vector start = new Vector(0.0, 0.0);
        Vector end = new Vector(-1, 1).normalize().scalarMultiply(0.7 * nSteps * stepSize);
        ArrayList<Vector> chain = RngUtility.randomChain(start, end, nSteps, stepSize);
        assertEquals(start, chain.get(0));
        assertEquals(end, chain.get(chain.size() - 1));
        Vector prev = chain.get(0);
        for (int i = 1; i < chain.size(); i++) {
            Vector current = chain.get(i);
            assertEquals(stepSize, current.subtract(prev).getNorm(), DELTA);
            prev = current;
        }
    }

    @Test
    void testRandomChainExceptions() {
        int nSteps = 23;
        double stepSize = 7.0;
        Vector start = new Vector(0.0, 0.0);
        Vector end = new Vector(-1, 1).normalize().scalarMultiply(0.7 * nSteps * stepSize);
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.randomChain(start, end, 0, stepSize));
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.randomChain(start, end, -10, stepSize));
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.randomChain(start, end, nSteps, 0.0));
        assertThrows(IllegalArgumentException.class, () ->
                RngUtility.randomChain(start, end, nSteps, -7.0));
    }

    @Test
    void testRandomChainNonexistent() {
        int nSteps = 23;
        double stepSize = 7.0;
        Vector start = new Vector(0.0, 0.0);
        Vector end = new Vector(-1, 1).normalize().scalarMultiply(1.1 * nSteps * stepSize);
        assertThrows(ArithmeticException.class, () ->
                RngUtility.randomChain(start, end, nSteps, stepSize));
    }
}
