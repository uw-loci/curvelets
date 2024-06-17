package syntheticfibergenerator;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;


class ParamTest {

    @Test
    void testNullValueString() {
        Param<Integer> param = new Param<>();
        assertEquals("", param.string());
    }

    @Test
    void testParseEmpty() {
        Param<Integer> param = new Param<>();
        assertThrows(IllegalArgumentException.class, () ->
                param.parse("", Integer::parseInt));
        assertThrows(IllegalArgumentException.class, () ->
                param.parse("  ", Integer::parseInt));
    }

    @Test
    void testParseInteger() {
        Param<Integer> param = new Param<>();
        try {
            param.parse("7", Integer::parseInt);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertEquals(7, (int) param.value());
        assertThrows(IllegalArgumentException.class, () ->
            param.parse("word", Integer::parseInt));
    }

    @Test
    void testParseDouble() {
        Param<Double> param = new Param<>();
        try {
            param.parse("7.23", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        assertEquals(7.23, (double) param.value());
        assertThrows(IllegalArgumentException.class, () ->
                param.parse("word", Double::parseDouble));
    }

    @Test
    void testVerifyLess() {
        Param<Double> param = new Param<>();
        try {
            param.parse("-12.7", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        param.verify(-12.0, Param::less);
        assertThrows(IllegalArgumentException.class, () ->
                param.verify(-13.0, Param::less));
    }

    @Test
    void testVerifyGreater() {
        Param<Double> param = new Param<>();
        try {
            param.parse("100.33", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        param.verify(100.32, Param::greater);
        assertThrows(IllegalArgumentException.class, () ->
                param.verify(100.33, Param::greater));
    }

    @Test
    void testVerifyLessEq() {
        Param<Double> param = new Param<>();
        try {
            param.parse("0.0", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        param.verify(1.0, Param::lessEq);
        param.verify(0.0, Param::lessEq);
        assertThrows(IllegalArgumentException.class, () ->
                param.verify(-0.1, Param::lessEq));
    }

    @Test
    void testVerifyGreaterEq() {
        Param<Double> param = new Param<>();
        try {
            param.parse("37.45", Double::parseDouble);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        param.verify(10.3, Param::greaterEq);
        param.verify(37.45, Param::greaterEq);
        assertThrows(IllegalArgumentException.class, () ->
                param.verify(38.45, Param::greaterEq));
    }

    @Test
    void testParseOptional() {
        Optional<Integer> optional = new Optional<>();
        optional.use = false;
        optional.parse("word", Integer::parseInt);
        assertEquals("", optional.string());
    }

    @Test
    void testVerifyOptional() {
        Optional<Double> optional = new Optional<>();
        optional.use = true;
        optional.parse("10.7", Double::parseDouble);
        optional.use = false;
        optional.verify(11.0, Param::less);
    }
}
