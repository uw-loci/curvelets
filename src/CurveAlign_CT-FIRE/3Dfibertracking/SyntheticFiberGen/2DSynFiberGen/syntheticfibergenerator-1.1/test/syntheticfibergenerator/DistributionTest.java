package syntheticfibergenerator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Random;

import static org.junit.jupiter.api.Assertions.*;


class DistributionTest {

    private static final int N_LOOPS = 100;


    /**
     * Fix the random seed so we get consistent tests.
     */
    @BeforeEach
    void setUp() {
        RngUtility.rng = new Random(1);
    }

    @Test
    void testGaussianSample() {
        Gaussian gaussian = new Gaussian(1.0, 5.0);
        try {
            gaussian.mean.parse("2.0", Double::parseDouble);
            gaussian.sigma.parse("3.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        for (int i = 0; i < N_LOOPS; i++) {
            double value = gaussian.sample();
            assertTrue(value >= 1.0 && value <= 5.0);
        }
    }

    @Test
    void testGaussianInvalidMean() {
        Gaussian gaussian = new Gaussian(1.0, 5.0);
        try {
            gaussian.mean.parse("-1.0", Double::parseDouble);
            gaussian.sigma.parse("3.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        for (int i = 0; i < N_LOOPS; i++) {
            double value = gaussian.sample();
            assertTrue(value >= 1.0 && value <= 5.0);
        }
    }

    @Test
    void testGaussianValidationError() {
        Gaussian gaussian = new Gaussian(1.0, 5.0);
        try {
            gaussian.mean.parse("2.0", Double::parseDouble);
            gaussian.sigma.parse("-3.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, gaussian::verify);
    }

    @Test
    void testUniformSample() {
        Uniform uniform = new Uniform(-10.0, 17.0);
        try {
            uniform.min.parse("-8.0", Double::parseDouble);
            uniform.max.parse("12.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        for (int i = 0; i < N_LOOPS; i++) {
            double value = uniform.sample();
            assertTrue(value >= -8.0 && value < 12.0);
        }
    }

    @Test
    void testUniformTrim() {
        Uniform uniform = new Uniform(-10.0, 17.0);
        try {
            uniform.min.parse("-15.0", Double::parseDouble);
            uniform.max.parse("17.5", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        for (int i = 0; i < N_LOOPS; i++) {
            double value = uniform.sample();
            assertTrue(value >= -10.0 && value < 17.0);
        }
    }

    @Test
    void testUniformValidationError() {
        Uniform uniform = new Uniform(-10.0, 17.0);
        try {
            uniform.min.parse("3.0", Double::parseDouble);
            uniform.max.parse("-1.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, uniform::verify);
        try {
            uniform.min.parse("18.0", Double::parseDouble);
            uniform.max.parse("19.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, uniform::verify);
        try {
            uniform.min.parse("-12.0", Double::parseDouble);
            uniform.max.parse("-11.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, uniform::verify);
    }

    @Test
    void testPiecewiseLinearSample() {
        PiecewiseLinear piecewiseLinear = new PiecewiseLinear(5.0, 100.0);
        try {
            piecewiseLinear.parseXYValues("6.0, 7.0, 8.0, 10.0, 90.0, 95.0", "1.0, 2.0, 1.0, 0.0, 0.0, 1.0");
        } catch (Exception e) {
            fail(e.getMessage());
        }
        for (int i = 0; i < N_LOOPS; i++) {
            double value = piecewiseLinear.sample();
            assertTrue(value >= 6.0);
            assertTrue(value <= 95.0);
            assertTrue(value <= 10.0 || value >= 90.0);
        }
    }

    @Test
    void testPiecewiseLinearParseError() {
        PiecewiseLinear piecewiseLinear = new PiecewiseLinear(5.0, 100.0);
        assertThrows(IllegalArgumentException.class, () ->
                piecewiseLinear.parseXYValues("6.0, 7.0, 8.0", "1.0, 2.0"));
        assertThrows(IllegalArgumentException.class, () ->
                piecewiseLinear.parseXYValues("", ""));
        assertThrows(IllegalArgumentException.class, () ->
                piecewiseLinear.parseXYValues("6.0, foo, 8.0", "1.0, 2.0, 1.0"));
        assertThrows(IllegalArgumentException.class, () ->
                piecewiseLinear.parseXYValues("6.0, 7.0, 8.0", "1.0, foo, 1.0"));
    }

    @Test
    void testPiecewiseLinearValidationError() {
        PiecewiseLinear piecewiseLinear = new PiecewiseLinear(5.0, 100.0);
        try {
            piecewiseLinear.parseXYValues("6.0, 8.0, 7.0", "1.0, 2.0, 1.0");
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, piecewiseLinear::verify);
        try {
            piecewiseLinear.parseXYValues("6.0, 7.0, 8.0", "1.0, 2.0, -1.0");
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, piecewiseLinear::verify);
        try {
            piecewiseLinear.parseXYValues("4.0, 7.0, 8.0", "1.0, 2.0, 1.0");
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, piecewiseLinear::verify);
        try {
            piecewiseLinear.parseXYValues("6.0, 7.0, 101.0", "1.0, 2.0, 1.0");
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertThrows(IllegalArgumentException.class, piecewiseLinear::verify);
    }
}
