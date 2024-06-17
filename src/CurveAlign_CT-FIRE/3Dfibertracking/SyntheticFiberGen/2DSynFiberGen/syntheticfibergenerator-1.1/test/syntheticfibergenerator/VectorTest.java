package syntheticfibergenerator;

import org.apache.commons.math3.exception.MathArithmeticException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;


class VectorTest {

    private static final int N_LOOPS = 100;
    private static final double DELTA = 1e-6;

    private static final double MIN_NORM = 1e-6;
    private static final double MAX_NORM = 1e6;

    private static final double MIN_VAL = -1e6;
    private static final double MAX_VAL = 1e6;


    /**
     * Fix the random seed so we get consistent tests.
     */
    @BeforeEach
    void setUp() {
        RngUtility.rng.setSeed(1);
    }

    @Test
    void testNormalize() {
        for (int i = 0; i < N_LOOPS; i++) {
            Vector vec = TestUtility.fromAngle(RngUtility.nextDouble(0.0, 2.0 * Math.PI));
            vec = vec.scalarMultiply(RngUtility.nextDouble(MIN_NORM, MAX_NORM));
            assertEquals(1.0, vec.normalize().getNorm(), DELTA);
        }
    }

    @Test
    void testNormalizeZero() {
        assertThrows(MathArithmeticException.class, () ->
                new Vector(0.0, 0.0).normalize());
    }

    @Test
    void testScalarMultiply() {
        for (int i = 0; i < N_LOOPS; i++) {
            Vector vec = TestUtility.fromAngle(RngUtility.nextDouble(0.0, 2.0 * Math.PI));
            double norm = RngUtility.nextDouble(MIN_NORM, MAX_NORM);
            assertEquals(norm * vec.getX(), vec.scalarMultiply(norm).getX(), DELTA);
            assertEquals(norm * vec.getY(), vec.scalarMultiply(norm).getY(), DELTA);
        }
    }

    @Test
    void testAdd() {
        for (int i = 0; i < N_LOOPS; i++) {
            Vector vec1 = RngUtility.nextPoint(MIN_VAL, MAX_VAL, MIN_VAL, MAX_VAL);
            Vector vec2 = RngUtility.nextPoint(MIN_VAL, MAX_VAL, MIN_VAL, MAX_VAL);
            Vector sum = vec1.add(vec2);
            assertEquals(vec1.getX() + vec2.getX(), sum.getX(), DELTA);
            assertEquals(vec1.getY() + vec2.getY(), sum.getY(), DELTA);
        }
    }

    @Test
    void testSubtract() {
        for (int i = 0; i < N_LOOPS; i++) {
            Vector vec1 = RngUtility.nextPoint(MIN_VAL, MAX_VAL, MIN_VAL, MAX_VAL);
            Vector vec2 = RngUtility.nextPoint(MIN_VAL, MAX_VAL, MIN_VAL, MAX_VAL);
            Vector diff = vec1.subtract(vec2);
            assertEquals(vec1.getX() - vec2.getX(), diff.getX(), DELTA);
            assertEquals(vec1.getY() - vec2.getY(), diff.getY(), DELTA);
        }
    }

    @Test
    void testTheta() {
        for (int i = 0; i < N_LOOPS; i++) {
            double angle = RngUtility.nextDouble(-Math.PI, Math.PI);
            double norm = RngUtility.nextDouble(MIN_NORM, MAX_NORM);
            Vector vec = TestUtility.fromAngle(angle).scalarMultiply(norm);
            assertEquals(angle, vec.theta(), DELTA);
        }
    }

    @Test
    void testAngleWith() {
        for (int i = 0; i < N_LOOPS; i++) {
            double angle1 = RngUtility.nextDouble(0, Math.PI);
            double angle2 = RngUtility.nextDouble(0, Math.PI);
            Vector vec1 = TestUtility.fromAngle(angle1);
            Vector vec2 = TestUtility.fromAngle(angle2);
            assertEquals(Math.abs(angle2 - angle1), vec1.angleWith(vec2), DELTA);
        }
    }

    @Test
    void testAngleWithZero() {
        Vector vec = new Vector(1.0, 0.0);
        assertThrows(ArithmeticException.class, () ->
                vec.angleWith(new Vector(0.0, 0.0)));
    }

    @Test
    void testRotate() {
        Vector vec = new Vector(1, 0);
        vec = vec.unRotate(new Vector(0, 1));
        assertEquals(new Vector(0, 1), vec);
    }

    @Test
    void testRotateZeroAxis() {
        Vector vec = new Vector(1.0, 0.0);
        assertThrows(ArithmeticException.class, () ->
                vec.unRotate(new Vector(0.0, 0.0)));
    }
}
