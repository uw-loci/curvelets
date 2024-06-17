package syntheticfibergenerator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.awt.image.BufferedImage;
import java.util.Random;

import static org.junit.jupiter.api.Assertions.*;


class FiberImageTest {

    private static final int N_LOOPS = 20;
    private static final double DELTA = 1e-6;


    /**
     * Fix the random seed so we get consistent tests.
     */
    @BeforeEach
    void setUp() {
        RngUtility.rng = new Random(1);
    }

    @Test
    void testAlignment() {
        for (int i = 0; i < N_LOOPS; i++) {
            FiberImage.Params params = randomParams();
            FiberImage image = new FiberImage(params);
            image.generateFibers();
            assertEquals(params.alignment.value(), TestUtility.alignment(image, params), DELTA);
        }
    }

    @Test
    void testMeanAngle() {
        for (int i = 0; i < N_LOOPS; i++) {
            FiberImage.Params params = randomParams();
            FiberImage image = new FiberImage(params);
            image.generateFibers();
            assertEquals(params.meanAngle.value(), TestUtility.meanAngle(image, params), DELTA);
        }
    }

    @Test
    void testImageProperties() {
        for (int i = 0; i < N_LOOPS; i++) {
            FiberImage.Params params = randomParams();
            FiberImage image = new FiberImage(params);
            image.generateFibers();
            image.drawFibers();
            assertEquals((int) params.imageWidth.value(), image.getImage().getWidth());
            assertEquals((int) params.imageHeight.value(), image.getImage().getHeight());
        }
    }


    @Test
    void testDownSample() {
        for (int i = 0; i < N_LOOPS; i++) {
            FiberImage.Params params = randomParams();
            FiberImage image = new FiberImage(params);
            image.generateFibers();
            image.drawFibers();
            image.applyEffects();
            BufferedImage buffImage = image.getImage();
            assertEquals(params.imageWidth.value() * params.downSample.value(), buffImage.getWidth(), 1.0);
            assertEquals(params.imageHeight.value() * params.downSample.value(), buffImage.getHeight(), 1.0);
        }
    }

    /**
     * TODO: Choose the bounds on values more systematically
     */
    private static FiberImage.Params randomParams() {
        FiberImage.Params params = new FiberImage.Params();
        try {
            // Generate at least 2 fibers because alignment for a single fiber is always 1.0
            params.nFibers = TestUtility.fromValue(RngUtility.nextInt(2, 100), Integer::parseInt);
            params.segmentLength = TestUtility.fromValue(RngUtility.nextDouble(0.1, 100.0), Double::parseDouble);
            params.alignment = TestUtility.fromValue(RngUtility.nextDouble(0.0, 1.0), Double::parseDouble);
            params.meanAngle = TestUtility.fromValue(RngUtility.nextDouble(0.0, 180.0), Double::parseDouble);
            params.widthChange = TestUtility.fromValue(RngUtility.nextDouble(0.0, 10.0), Double::parseDouble);
            params.imageWidth = TestUtility.fromValue(RngUtility.nextInt(8, 1024), Integer::parseInt);
            params.imageHeight = TestUtility.fromValue(RngUtility.nextInt(8, 1024), Integer::parseInt);
            params.imageBuffer = TestUtility.fromValue(RngUtility.nextInt(0, 32), Integer::parseInt);
            Uniform length = new Uniform(params.length.lowerBound, params.length.upperBound);
            length.min = TestUtility.fromValue(RngUtility.nextDouble(0.1, 1000.0), Double::parseDouble);
            length.max = TestUtility.fromValue(RngUtility.nextDouble(length.min.value(), 1000.0), Double::parseDouble);
            params.length = length;
            Uniform width = new Uniform(params.width.lowerBound, params.width.upperBound);
            width.min = TestUtility.fromValue(RngUtility.nextDouble(0.1, 5.0), Double::parseDouble);
            width.max = TestUtility.fromValue(RngUtility.nextDouble(width.min.value(), 5.0), Double::parseDouble);
            params.width = width;
            Uniform straightness = new Uniform(params.straightness.lowerBound, params.straightness.upperBound);
            straightness.min = TestUtility.fromValue(RngUtility.nextDouble(0.0, 1.0), Double::parseDouble);
            straightness.max = TestUtility.fromValue(RngUtility.nextDouble(straightness.min.value(), 1.0), Double::parseDouble);
            params.straightness = straightness;
            params.downSample.use = true;
            params.downSample.parse(Double.toString(RngUtility.nextDouble(0.01, 20.0)), Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        params.setNames();
        params.setHints();
        return params;
    }
}
