package syntheticfibergenerator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;

import static org.junit.jupiter.api.Assertions.*;


class MiscUtilityTest {

    private static final double DELTA = 1e-6;

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
    void testGuiName() {
        Param<Integer> testParam = new Param<>();
        testParam.setName("ordinary name");
        assertEquals("Ordinary name:", MiscUtility.guiName(testParam));
    }

    @Test
    void testEmptyGuiName() {
        Param<Integer> testParam = new Param<>();
        testParam.setName("");
        assertEquals(":", MiscUtility.guiName(testParam));
    }

    @Test
    void testNonAlphaGuiName() {
        Param<Integer> testParam = new Param<>();
        testParam.setName("$other name");
        assertEquals("$other name:", MiscUtility.guiName(testParam));
    }

    @Test
    void testToFromDeltas() {
        ArrayList<Vector> points = new ArrayList<>();
        int nPoints = 100;
        for (int i = 0; i < nPoints; i++) {
            points.add(RngUtility.nextPoint(MIN_VAL, MAX_VAL, MIN_VAL, MAX_VAL));
        }
        ArrayList<Vector> recon = MiscUtility.fromDeltas(MiscUtility.toDeltas(points), points.get(0));
        assertTrue(TestUtility.elementWiseEqual(points, recon, DELTA));
    }

    @Test
    void testEmptyToDeltas() {
        ArrayList<Vector> points = new ArrayList<>();
        ArrayList<Vector> deltas = MiscUtility.toDeltas(points);
        assertTrue(deltas.isEmpty());
    }

    @Test
    void testEmptyFromDeltas() {
        ArrayList<Vector> deltas = new ArrayList<>();
        Vector start = new Vector(-1.0, 2.0);
        ArrayList<Vector> points = MiscUtility.fromDeltas(deltas, start);
        assertEquals(1, points.size());
        assertEquals(start, points.get(0));
    }


}
