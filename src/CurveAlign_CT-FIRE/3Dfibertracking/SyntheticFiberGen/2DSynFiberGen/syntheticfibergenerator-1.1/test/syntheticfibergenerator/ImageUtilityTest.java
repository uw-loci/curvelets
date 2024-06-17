package syntheticfibergenerator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.awt.*;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.awt.image.Raster;

import static org.junit.jupiter.api.Assertions.*;


class ImageUtilityTest {

    private BufferedImage image;

    private static final int FALLOFF = 64;


    /**
     * Creates a non-empty image by drawing some text and shapes.
     */
    @BeforeEach
    void setUp() {
        image = new BufferedImage(1024, 1024, BufferedImage.TYPE_BYTE_GRAY);
        Graphics graphics = image.getGraphics();
        graphics.drawString("Hello, world!", 100, 100);
        graphics.drawOval(512, 512, 100, 100);
        graphics.drawLine(10, 1014, 1014, 10);
    }

    @Test
    void testDistanceFunction() {
        assertTrue(TestUtility.sizeTypeMatch(ImageUtility.distanceFunction(image, FALLOFF), image));
    }

    /**
     * Because pixel value is background distance * falloff with maximum 255, a falloff of 1000 will set background
     * pixels to 0 and all others to 255.
     */
    @Test
    void testHighFalloff() {
        assertTrue(TestUtility.pixelWiseEqual(image, ImageUtility.distanceFunction(image, 1000)));
    }

    @Test
    void testInvalidImage() {
        BufferedImage badImage = new BufferedImage(256, 256, BufferedImage.TYPE_INT_ARGB);
        assertThrows(IllegalArgumentException.class, () ->
                ImageUtility.distanceFunction(badImage, FALLOFF));
    }

    @Test
    void testGaussianBlur() {
        assertTrue(TestUtility.sizeTypeMatch(image, ImageUtility.gaussianBlur(image, 8)));
    }

    @Test
    void testScale() {
        for (double scale = 0.01; scale <= 20.0; scale *= 2) {
            BufferedImage output = ImageUtility.scale(image, scale, AffineTransformOp.TYPE_BILINEAR);
            assertEquals(image.getWidth() * scale, output.getWidth(), 1.0);
            assertEquals(image.getHeight() * scale, output.getHeight(), 1.0);
            assertEquals(image.getType(), output.getType());
        }
    }

    @Test
    void testCap() {
        int max = 50;
        BufferedImage capped = ImageUtility.cap(image, max);
        Raster oldRaster = image.getRaster();
        Raster newRaster = capped.getRaster();
        for (int y = 0; y < capped.getHeight(); y++) {
            for (int x = 0; x < capped.getWidth(); x++) {
                int iOld = getPixel(oldRaster, x, y);
                int iNew = getPixel(newRaster, x, y);
                if (iOld > max) {
                    assertEquals(max, iNew);
                } else {
                    assertEquals(iOld, iNew);
                }
            }
        }
    }

    @Test
    void testNormalize() {
        int max = 75;
        BufferedImage normalized = ImageUtility.normalize(image, max);
        Raster raster = normalized.getRaster();
        int actualMax = 0;
        for (int y = 0; y < image.getHeight(); y++) {
            for (int x = 0; x < image.getWidth(); x++) {
                actualMax = Math.max(actualMax, getPixel(raster, x, y));
            }
        }
        assertEquals(max, actualMax);
    }

    private static int getPixel(Raster raster, int x, int y) {
        int[] pixel = new int[1];
        raster.getPixel(x, y, pixel);
        return pixel[0];
    }
}
