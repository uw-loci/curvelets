package syntheticfibergenerator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.Random;

import static org.junit.jupiter.api.Assertions.*;


class FiberTest {

    private static final int N_LOOPS = 50;
    private static final double DELTA = 1e-6;

    private static final int SMOOTH = 10;
    private static final int MAX_SPLINE = 20;


    /**
     * Fix the random seed so we get consistent tests.
     */
    @BeforeEach
    void setUp() {
        RngUtility.rng = new Random(1);
    }

    @Test
    void testIterator() {
        Fiber.Params params = randomParams();
        Fiber fiber = new Fiber(params);
        fiber.generate();
        Iterator<Fiber.Segment> iterator = fiber.iterator();
        for (int i = 0; i < params.nSegments; i++) {
            assertTrue(iterator.hasNext());
            iterator.next();
        }
        assertFalse(iterator.hasNext());
    }

    @Test
    void testPointGeneration() {
        for (int i = 0; i < N_LOOPS; i++) {
            Fiber.Params params = randomParams();
            Fiber fiber = new Fiber(params);
            fiber.generate();
            Vector prevEnd = params.start;
            for (Fiber.Segment segment : fiber) {
                assertEquals(params.segmentLength, segment.start.distance(segment.end), DELTA);
                assertEquals(prevEnd, segment.start);
                prevEnd = segment.end;
            }
            assertEquals(params.end, prevEnd);
        }
    }

    @Test
    void testWidthGeneration() {
        for (int i = 0; i < N_LOOPS; i++) {
            Fiber.Params params = randomParams();
            Fiber fiber = new Fiber(params);
            fiber.generate();
            Iterator<Fiber.Segment> iterator = fiber.iterator();
            Fiber.Segment first = iterator.next();
            assertEquals(params.startWidth, first.width);
            double prevWidth = params.startWidth;
            for (Fiber.Segment segment : fiber) {
                assertTrue(Math.abs(segment.width - prevWidth) <= params.widthChange);
                assertTrue(segment.width >= 0.0);
                prevWidth = segment.width;
            }
        }
    }

    @Test
    void testBubbleSmooth() {
        for (int i = 0; i < N_LOOPS; i++) {
            Fiber fiber = new Fiber(randomParams());
            fiber.generate();
            double oldSum = TestUtility.angleChangeSum(fiber);
            for (int j = 0; j < SMOOTH; j++) {
                fiber.bubbleSmooth(1);
                double newSum = TestUtility.angleChangeSum(fiber);
                assertTrue(newSum <= oldSum + DELTA);
                oldSum = newSum;
            }
        }
    }

    @Test
    void testSwapSmooth() {
        for (int i = 0; i < N_LOOPS; i++) {
            Fiber fiber = new Fiber(randomParams());
            fiber.generate();
            double oldSum = TestUtility.angleChangeSum(fiber);
            for (int j = 0; j < SMOOTH; j++) {
                fiber.swapSmooth(1);
                double newSum = TestUtility.angleChangeSum(fiber);
                assertTrue(newSum <= oldSum + DELTA);
                oldSum = newSum;
            }
        }
    }

    @Test
    void testSplineSmooth() {
        for (int i = 0; i < N_LOOPS; i++) {
            int smoothRatio = 1 + RngUtility.rng.nextInt(MAX_SPLINE);
            Fiber fiber = new Fiber(randomParams());
            fiber.generate();
            ArrayList<Vector> oldPoints = fiber.getPoints();
            fiber.splineSmooth(smoothRatio);
            ArrayList<Vector> newPoints = fiber.getPoints();
            assertEquals((oldPoints.size() - 1) * smoothRatio + 1, newPoints.size());
            for (int j = 0; j < newPoints.size(); j++) {
                if (i % smoothRatio == 0) {
                    assertTrue(TestUtility.vectorsEquals(newPoints.get(i), oldPoints.get(i / smoothRatio), DELTA));
                }
            }
        }
    }

    /**
     * TODO: Choose the bounds on values more systematically
     */
    private static Fiber.Params randomParams() {
        Fiber.Params params = new Fiber.Params();
        params.segmentLength = RngUtility.nextDouble(0.1, 100.0);
        params.widthChange = RngUtility.nextDouble(0.0, 10.0);
        params.nSegments = (int) RngUtility.nextDouble(1.0, 1000.0);
        params.startWidth = RngUtility.nextDouble(0.1, 5.0);
        params.straightness = RngUtility.nextDouble(0.0, 1.0);
        params.start = new Vector();
        double angle = RngUtility.nextDouble(0.0, 2 * Math.PI);
        params.start = new Vector();
        double length = params.segmentLength * params.nSegments * params.straightness;
        params.end = new Vector(Math.cos(angle), Math.sin(angle)).scalarMultiply(length);
        return params;
    }
}
